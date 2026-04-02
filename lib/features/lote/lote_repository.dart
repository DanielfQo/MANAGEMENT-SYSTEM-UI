import 'dart:io';
import 'package:management_system_ui/core/common_libs.dart';
import 'models/lote_model.dart';
import 'models/lote_response_model.dart';
import 'models/producto_model.dart';
import 'models/producto_catalogo_model.dart';
import 'models/stock_model.dart';

final loteRepositoryProvider = Provider((ref) {
  final dio = ref.watch(dioProvider);
  return LoteRepository(dio);
});

class LoteRepository {
  final Dio _dio;
  LoteRepository(this._dio);

  /// Obtener catálogo de productos
  Future<List<ProductoModel>> getProductos() async {
    try {
      final response = await _dio.get('inventory/productos/');

      final data = response.data;
      final List results;
      if (data is Map && data.containsKey('results')) {
        results = data['results'] as List;
      } else if (data is List) {
        results = data;
      } else {
        results = [];
      }

      return results
          .map((e) => ProductoModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      final msg = _extractErrorMessage(e);
      throw Exception(msg);
    }
  }

  /// Obtener detalle de un producto
  Future<ProductoModel> getProductoDetalle(int id) async {
    try {
      final response = await _dio.get('inventory/productos/$id/');
      return ProductoModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final msg = _extractErrorMessage(e);
      throw Exception(msg);
    }
  }

  /// Actualizar producto (solo dueño)
  Future<void> actualizarProducto(
    int id, {
    String? tipoIgv,
    bool? isActive,
    File? imagenFile,
  }) async {
    try {
      // Si hay imagen, usar FormData; si no, usar JSON simple
      if (imagenFile != null) {
        final formData = FormData.fromMap({
          'tipo_igv': tipoIgv,
          'is_active': isActive,
          'imagen': await MultipartFile.fromFile(
            imagenFile.path,
            filename: imagenFile.path.split('/').last,
          ),
        });
        await _dio.patch('inventory/productos/$id/', data: formData);
      } else {
        final data = <String, dynamic>{};
        data['tipo_igv'] = tipoIgv;
        data['is_active'] = isActive;
        await _dio.patch('inventory/productos/$id/', data: data);
      }
    } on DioException catch (e) {
      final msg = _extractErrorMessage(e);
      throw Exception(msg);
    }
  }

  /// Crear un nuevo lote con sus productos
  Future<LoteResponse> crearLote(LoteCreateModel lote) async {
    try {
      final response = await _dio.post(
        'inventory/lotes/',
        data: lote.toJson(),
      );
      return LoteResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final msg = _extractErrorMessage(e);
      throw Exception(msg);
    }
  }

  /// Obtener lista de lotes de una tienda con cursor pagination
  Future<({List<LoteResponse> lotes, String? nextCursor})> getLotes(
    int tiendaId, {
    String? cursor,
  }) async {
    try {
      final params = <String, dynamic>{
        'tienda': tiendaId,
      };
      if (cursor != null) {
        params['cursor'] = cursor;
      }
      final response = await _dio.get(
        'inventory/lotes/',
        queryParameters: params,
      );

      final data = response.data;
      String? nextCursor;
      final List results;
      if (data is Map && data.containsKey('results')) {
        results = data['results'] as List;
        final nextUrl = data['next'] as String?;
        if (nextUrl != null) {
          final uri = Uri.parse(nextUrl);
          nextCursor = uri.queryParameters['cursor'];
        }
      } else if (data is List) {
        results = data;
      } else {
        results = [];
      }

      final lotes = results
          .map((e) => LoteResponse.fromJson(e as Map<String, dynamic>))
          .toList();

      return (lotes: lotes, nextCursor: nextCursor);
    } on DioException catch (e) {
      final msg = _extractErrorMessage(e);
      throw Exception(msg);
    }
  }

  /// Obtener detalle de un lote específico
  Future<LoteResponse> getLoteDetalle(int id) async {
    try {
      final response = await _dio.get('inventory/lotes/$id/');
      return LoteResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final msg = _extractErrorMessage(e);
      throw Exception(msg);
    }
  }

  /// Desactivar un lote (soft delete)
  Future<void> desactivarLote(int id) async {
    try {
      await _dio.delete('inventory/lotes/$id/');
    } on DioException catch (e) {
      final msg = _extractErrorMessage(e);
      throw Exception(msg);
    }
  }

  /// Obtener stock agregado por producto en una tienda
  Future<List<StockModel>> getStock(int tiendaId) async {
    try {
      final response = await _dio.get(
        'inventory/stock/',
        queryParameters: {
          'tienda': tiendaId,
        },
      );

      final data = response.data;
      final List results;
      if (data is Map && data.containsKey('results')) {
        results = data['results'] as List;
      } else if (data is List) {
        results = data;
      } else {
        results = [];
      }

      return results
          .map((e) => StockModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      final msg = _extractErrorMessage(e);
      throw Exception(msg);
    }
  }

  /// Obtener catálogo de productos de una tienda con paginación
  Future<({List<ProductoCatalogoModel> productos, String? nextCursor})> getCatalogo(
    int tiendaId, {
    String? cursor,
    String? search,
    int pageSize = 20,
  }) async {
    try {
      final params = <String, dynamic>{
        'tienda': tiendaId,
        'page_size': pageSize,
      };
      if (cursor != null) {
        params['cursor'] = cursor;
      }
      if (search != null && search.isNotEmpty) {
        params['search'] = search;
      }

      final response = await _dio.get(
        'inventory/catalogo/',
        queryParameters: params,
      );

      final data = response.data;
      String? nextCursor;
      final List results;

      if (data is Map && data.containsKey('results')) {
        results = data['results'] as List;
        final nextUrl = data['next'] as String?;
        if (nextUrl != null) {
          final uri = Uri.parse(nextUrl);
          nextCursor = uri.queryParameters['cursor'];
        }
      } else if (data is List) {
        results = data;
      } else {
        results = [];
      }

      final productos = results
          .map((e) => ProductoCatalogoModel.fromJson(e as Map<String, dynamic>))
          .toList();

      return (productos: productos, nextCursor: nextCursor);
    } on DioException catch (e) {
      final msg = _extractErrorMessage(e);
      throw Exception(msg);
    }
  }

  /// Extrae mensaje de error de la respuesta de la API
  String _extractErrorMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map) {
      final values = data.values.first;
      if (values is List) {
        return values.first.toString();
      }
      return values.toString();
    }
    return 'Error en la operación';
  }
}
