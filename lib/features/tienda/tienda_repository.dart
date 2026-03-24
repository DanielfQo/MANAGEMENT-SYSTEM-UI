import 'package:management_system_ui/core/common_libs.dart';
import 'package:management_system_ui/core/models/store_model.dart';

export 'package:management_system_ui/core/models/store_model.dart';

final tiendaRepositoryProvider = Provider((ref) {
  final dio = ref.watch(dioProvider);
  return TiendaRepository(dio);
});

class TiendaRepository {
  final Dio _dio;
  TiendaRepository(this._dio);

  Future<List<StoreModel>> getTiendas() async {
    try {
      final response = await _dio.get('store/');
      return (response.data as List)
          .map((e) => StoreModel.fromJson(e))
          .toList();
    } on DioException catch (_) {
      throw Exception('Error al obtener las tiendas');
    }
  }

  Future<StoreModel> actualizarTienda({
    required int id,
    required String nombreSede,
    required String direccion,
    required String ubigeo,
  }) async {
    try {
      final response = await _dio.patch(
        'store/$id/',
        data: {
          'nombre_sede': nombreSede,
          'direccion': direccion,
          'ubigeo': ubigeo,
        },
      );
      return StoreModel.fromJson(response.data);
    } on DioException catch (e) {
      final data = e.response?.data;
      String message = 'Error al actualizar la tienda';
      if (data is Map) {
        final values = data.values.first;
        message = values is List ? values.first.toString() : values.toString();
      }
      throw Exception(message);
    }
  }

  Future<void> desactivarTienda(int id) async {
    try {
      await _dio.delete('store/$id/');
    } on DioException catch (_) {
      throw Exception('Error al desactivar la tienda');
    }
  }

  Future<StoreModel> crearTienda({
    required String nombreSede,
    required String direccion,
    required String ubigeo,
    required String serieFactura,
    required String serieBoleta,
    required String serieTicket,
    required int empresaId,
  }) async {
    try {
      final response = await _dio.post(
        'store/',
        data: {
          'nombre_sede': nombreSede,
          'direccion': direccion,
          'ubigeo': ubigeo,
          'serie_factura': serieFactura,
          'serie_boleta': serieBoleta,
          'serie_ticket': serieTicket,
          'empresa_id': empresaId,
        },
      );
      return StoreModel.fromJson(response.data);
    } on DioException catch (e) {
      final data = e.response?.data;
      String message = 'Error al crear la tienda';
      if (data is Map) {
        final values = data.values.first;
        message = values is List ? values.first.toString() : values.toString();
      }
      throw Exception(message);
    }
  }
}