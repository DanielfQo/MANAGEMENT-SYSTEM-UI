import 'dart:typed_data';
import 'package:management_system_ui/core/common_libs.dart';
import 'package:management_system_ui/features/venta/models/cliente_model.dart';
import 'package:management_system_ui/features/venta/models/venta_create_model.dart';
import 'package:management_system_ui/features/venta/models/venta_read_model.dart';

final ventaRepositoryProvider = Provider((ref) {
  final dio = ref.watch(dioProvider);
  return VentaRepository(dio);
});

class VentaRepository {
  final Dio _dio;
  VentaRepository(this._dio);

  /// POST /ventas/ - Crear nueva venta
  /// Valida los campos según el tipo de venta antes de enviar al servidor
  Future<VentaReadModel> crearVenta(VentaCreateModel venta) async {
    // Validar modelo antes de enviar
    final validationError = venta.validate();
    if (validationError != null) {
      throw Exception(validationError);
    }

    try {
      final response = await _dio.post(
        'sales/ventas/',
        data: venta.toJson(),
      );
      return VentaReadModel.fromJson(response.data);
    } on DioException catch (e) {
      final errorMsg = _extractErrorMessage(e, 'Error al crear la venta');
      throw Exception(errorMsg);
    }
  }

  /// GET /ventas/ - Listar ventas con filtros opcionales
  Future<List<VentaReadModel>> getVentas({
    required int tiendaId,
    String? tipo,
    String? fechaDesde,
    String? fechaHasta,
  }) async {
    try {
      final queryParams = <String, dynamic>{'tienda': tiendaId};
      if (tipo != null) queryParams['tipo'] = tipo;
      if (fechaDesde != null) queryParams['fecha_desde'] = fechaDesde;
      if (fechaHasta != null) queryParams['fecha_hasta'] = fechaHasta;

      final response = await _dio.get(
        'sales/ventas/',
        queryParameters: queryParams,
      );

      // Manejar respuesta paginada o lista directa
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
          .map((e) => VentaReadModel.fromJson(e))
          .toList();
    } on DioException catch (e) {
      final errorMsg =
          _extractErrorMessage(e, 'Error al obtener ventas');
      throw Exception(errorMsg);
    }
  }

  /// GET /ventas/{numero_comprobante}/ - Detalle de una venta
  Future<VentaReadModel> getVentaDetalle(String numeroComprobante) async {
    try {
      final response = await _dio.get('sales/ventas/$numeroComprobante/');
      return VentaReadModel.fromJson(response.data);
    } on DioException catch (e) {
      final errorMsg =
          _extractErrorMessage(e, 'Error al obtener detalle de venta');
      throw Exception(errorMsg);
    }
  }

  /// DELETE /ventas/{numero_comprobante}/ - Cancelar venta NORMAL/CRÉDITO (soft delete)
  Future<void> cancelarVenta(String numeroComprobante) async {
    try {
      await _dio.delete('sales/ventas/$numeroComprobante/');
    } on DioException catch (e) {
      final errorMsg =
          _extractErrorMessage(e, 'Error al cancelar venta');
      throw Exception(errorMsg);
    }
  }

  /// POST /ventas/{numero_comprobante}/anular/ - Anular venta SUNAT aceptada (mismo día)
  Future<VentaReadModel> anularVenta(
    String numeroComprobante, {
    required String codigoTipo,
    required String motivo,
  }) async {
    try {
      final response = await _dio.post(
        'sales/ventas/$numeroComprobante/anular/',
        data: {
          'codigo_tipo': codigoTipo,
          'motivo': motivo,
        },
      );
      return VentaReadModel.fromJson(response.data);
    } on DioException catch (e) {
      final errorMsg = _extractErrorMessage(e, 'Error al anular venta');
      throw Exception(errorMsg);
    }
  }

  /// POST /ventas/{numero_comprobante}/nota-credito/ - Nota de crédito para ventas SUNAT de días anteriores
  Future<VentaReadModel> emitirNotaCredito(String numeroComprobante) async {
    try {
      final response = await _dio.post(
        'sales/ventas/$numeroComprobante/nota-credito/',
      );
      return VentaReadModel.fromJson(response.data);
    } on DioException catch (e) {
      final errorMsg = _extractErrorMessage(e, 'Error al emitir nota de crédito');
      throw Exception(errorMsg);
    }
  }

  /// POST /ventas/{numero_comprobante}/confirmar-sunat/ - Confirmar propuesta SUNAT
  Future<VentaReadModel> confirmarSunat(
    String numeroComprobante,
    List<ConfirmarSunatItem> items,
  ) async {
    try {
      final response = await _dio.post(
        'sales/ventas/$numeroComprobante/confirmar-sunat/',
        data: {
          'propuesta': items.map((item) => item.toJson()).toList(),
        },
      );
      return VentaReadModel.fromJson(response.data);
    } on DioException catch (e) {
      final errorMsg = _extractErrorMessage(
        e,
        'Error al confirmar propuesta SUNAT',
      );
      throw Exception(errorMsg);
    }
  }

  /// GET /clientes/ - Listar clientes (filtrado por tienda)
  Future<List<ClienteModel>> getClientes(int tiendaId) async {
    try {
      final response = await _dio.get(
        'sales/clientes/',
        queryParameters: {'tienda': tiendaId},
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
          .map((e) => ClienteModel.fromJson(e))
          .toList();
    } on DioException catch (e) {
      final errorMsg =
          _extractErrorMessage(e, 'Error al obtener clientes');
      throw Exception(errorMsg);
    }
  }

  /// GET /clientes/ - Buscar clientes por DNI, RUC o nombre
  Future<List<ClienteModel>> buscarClientes({
    required String search,
    required bool requiereRuc,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'search': search,
        if (requiereRuc) 'tipo_documento': '6', // RUC
      };

      final response = await _dio.get(
        'sales/clientes/',
        queryParameters: queryParams,
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
          .map((e) => ClienteModel.fromJson(e))
          .toList();
    } on DioException catch (e) {
      final errorMsg =
          _extractErrorMessage(e, 'Error al buscar clientes');
      throw Exception(errorMsg);
    }
  }

  /// GET /clientes/ - Listar clientes con RUC (tipo_documento = "6") para SUNAT Factura
  Future<List<ClienteModel>> getClientesConRuc(int tiendaId) async {
    try {
      final response = await _dio.get(
        'sales/clientes/',
        queryParameters: {'tienda': tiendaId},
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

      final clientes = results
          .map((e) => ClienteModel.fromJson(e))
          .toList();

      // Filtrar solo clientes con RUC (tipo_documento = "6")
      return clientes.where((cliente) => cliente.tipoDocumento == '6').toList();
    } on DioException catch (e) {
      final errorMsg =
          _extractErrorMessage(e, 'Error al obtener clientes con RUC');
      throw Exception(errorMsg);
    }
  }

  /// GET /ventas/{numero_comprobante}/ticket/ - Descargar ticket PDF de venta NORMAL/CREDITO
  /// Retorna los bytes del PDF directamente
  Future<Uint8List> descargarTicketPdf(String numeroComprobante) async {
    try {
      final response = await _dio.get<List<int>>(
        'sales/ventas/$numeroComprobante/ticket/',
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: true,
          validateStatus: (status) => status! < 500,
        ),
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Error al descargar ticket: ${response.statusCode}',
        );
      }

      return Uint8List.fromList(response.data ?? []);
    } on DioException catch (e) {
      final errorMsg = _extractErrorMessage(e, 'Error al descargar ticket PDF');
      throw Exception(errorMsg);
    }
  }

  /// Helper: Extract error message from DioException response
  /// PATCH /clientes/{id}/ - Actualizar cliente
  /// Solo actualiza los campos proporcionados
  /// Retorna true si fue exitoso
  Future<bool> actualizarCliente(
    int clienteId,
    Map<String, String> campos,
  ) async {
    try {
      await _dio.patch(
        'sales/clientes/$clienteId/',
        data: campos,
      );
      return true;
    } on DioException catch (e) {
      final errorMsg = _extractErrorMessage(e, 'Error al actualizar cliente');
      throw Exception(errorMsg);
    }
  }

  String _extractErrorMessage(DioException e, String defaultMessage) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return 'Conexión lenta. Intenta de nuevo';
    }

    final statusCode = e.response?.statusCode;
    if (statusCode == 404) {
      return 'Servicio no disponible (404)';
    }

    final data = e.response?.data;

    // DRF puede devolver una Lista de errores (ej: ValidationError con string)
    if (data is List && data.isNotEmpty) {
      return data.map((e) => e.toString()).join('\n');
    }

    // Solo procesar si es JSON (Map), no HTML (String)
    if (data is Map) {
      // Intentar extraer 'detail' primero (DRF estándar)
      if (data.containsKey('detail')) {
        return data['detail'].toString();
      }
      // non_field_errors (errores de validate())
      if (data.containsKey('non_field_errors')) {
        final nfe = data['non_field_errors'];
        if (nfe is List && nfe.isNotEmpty) {
          return nfe.map((e) => e.toString()).join('\n');
        }
      }
      // Recopilar errores de campo
      final errors = <String>[];
      for (final entry in data.entries) {
        final key = entry.key;
        if (key == 'non_field_errors') continue;
        final value = entry.value;
        if (value is List) {
          for (final item in value) {
            if (item is String) {
              errors.add('$key: $item');
            } else if (item is Map) {
              for (final nested in item.entries) {
                final nVal = nested.value;
                if (nVal is List) {
                  errors.add('${nested.key}: ${nVal.join(', ')}');
                } else {
                  errors.add('${nested.key}: $nVal');
                }
              }
            }
          }
        } else if (value is String) {
          errors.add('$key: $value');
        }
      }
      if (errors.isNotEmpty) {
        return errors.join('\n');
      }
    }

    return defaultMessage;
  }
}
