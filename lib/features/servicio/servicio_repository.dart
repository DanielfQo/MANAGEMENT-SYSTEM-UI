import 'dart:typed_data';
import 'package:management_system_ui/core/common_libs.dart';
import 'package:management_system_ui/features/servicio/models/nota_credito_data.dart';
import 'package:management_system_ui/features/servicio/models/servicio_create_model.dart';
import 'package:management_system_ui/features/servicio/models/servicio_read_model.dart';

final servicioRepositoryProvider = Provider((ref) {
  final dio = ref.watch(dioProvider);
  return ServicioRepository(dio);
});

/// Clase auxiliar para retornar tanto los datos del servicio como el PDF generado
class ServicioConPdf {
  final ServicioReadModel servicio;
  final Uint8List? pdfBytes;

  ServicioConPdf({
    required this.servicio,
    this.pdfBytes,
  });
}

class ServicioRepository {
  final Dio _dio;
  ServicioRepository(this._dio);

  /// POST /services/servicio/ - Crear nuevo servicio
  /// Ahora siempre devuelve JSON para todos los tipos (NORMAL, CREDITO, SUNAT)
  /// El PDF se obtiene on-demand mediante GET /services/servicio/{numero}/ticket/
  Future<ServicioConPdf> crearServicio(ServicioCreateModel servicio) async {
    final validationError = servicio.validate();
    if (validationError != null) {
      throw Exception(validationError);
    }

    try {
      final response = await _dio.post(
        'services/servicio/',
        data: servicio.toJson(),
      );

      // El endpoint siempre devuelve JSON ahora
      final servicioCreado = ServicioReadModel.fromJson(response.data);
      return ServicioConPdf(
        servicio: servicioCreado,
        pdfBytes: null,  // PDF se obtiene on-demand, no después del POST
      );
    } on DioException catch (e) {
      final errorMsg = _extractErrorMessage(e, 'Error al crear el servicio');
      throw Exception(errorMsg);
    }
  }

  /// GET /services/servicio/ - Listar servicios con filtros y paginación por cursor
  Future<ServiciosPageResult> getServicios({
    required int tiendaId,
    String? fecha,
    String? fechaDesde,
    String? fechaHasta,
    String? tipo,
    String? search,
    String? estadoSunat,
    String? cursor,
    int? pageSize,
  }) async {
    try {
      final queryParams = <String, dynamic>{'tienda': tiendaId};
      if (fecha != null) queryParams['fecha'] = fecha;
      if (fechaDesde != null) queryParams['fecha_desde'] = fechaDesde;
      if (fechaHasta != null) queryParams['fecha_hasta'] = fechaHasta;
      if (tipo != null) queryParams['tipo'] = tipo;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (estadoSunat != null) queryParams['estado_sunat'] = estadoSunat;
      if (cursor != null) queryParams['cursor'] = cursor;
      if (pageSize != null) queryParams['page_size'] = pageSize;

      final response = await _dio.get(
        'services/servicio/',
        queryParameters: queryParams,
      );

      final data = response.data;
      final List results;
      String? nextCursor;

      if (data is Map && data.containsKey('results')) {
        results = data['results'] as List;
        nextCursor = _extractCursor(data['next'] as String?);
      } else if (data is List) {
        results = data;
        nextCursor = null;
      } else {
        results = [];
        nextCursor = null;
      }

      try {
        return ServiciosPageResult(
          items: results
              .map((e) => ServicioReadModel.fromJson(e))
              .toList(),
          nextCursor: nextCursor,
        );
      } on TypeError catch (e) {
        final shape = results.isEmpty
            ? '<lista vacía>'
            : results.first.runtimeType.toString();
        throw Exception(
          'Error parseando lista de servicios '
          '(primer item es $shape, esperado Map). '
          'Detalle: $e',
        );
      }
    } on DioException catch (e) {
      final errorMsg =
          _extractErrorMessage(e, 'Error al obtener servicios');
      throw Exception(errorMsg);
    }
  }

  /// GET /services/servicio/{numero_comprobante}/ - Detalle de un servicio
  Future<ServicioReadModel> getServicioDetalle(
      String numeroComprobante) async {
    try {
      final response =
          await _dio.get('services/servicio/$numeroComprobante/');
      return ServicioReadModel.fromJson(response.data);
    } on DioException catch (e) {
      final errorMsg =
          _extractErrorMessage(e, 'Error al obtener detalle del servicio');
      throw Exception(errorMsg);
    }
  }

  /// DELETE /services/servicio/{numero_comprobante}/ - Soft delete
  Future<void> eliminarServicio(String numeroComprobante) async {
    try {
      await _dio.delete('services/servicio/$numeroComprobante/');
    } on DioException catch (e) {
      final errorMsg =
          _extractErrorMessage(e, 'Error al eliminar servicio');
      throw Exception(errorMsg);
    }
  }

  /// POST /services/servicio/{numero_comprobante}/anular/ - Anular SUNAT (mismo dia)
  Future<ServicioReadModel> anularServicio(
    String numeroComprobante, {
    required String motivo,
  }) async {
    try {
      final response = await _dio.post(
        'services/servicio/$numeroComprobante/anular/',
        data: {'motivo': motivo},
      );
      return ServicioReadModel.fromJson(response.data);
    } on DioException catch (e) {
      final errorMsg =
          _extractErrorMessage(e, 'Error al anular servicio');
      throw Exception(errorMsg);
    }
  }

  /// POST /services/servicio/{numero_comprobante}/nota-credito/ - Nota de credito
  ///
  /// El backend devuelve el servicio actualizado y, además, un dict
  /// transitorio `nota_credito` con `numero`, `pdf_ticket`, `pdf_a4`,
  /// etc. — esos datos NO se persisten en BD, así que esta es la única
  /// chance de capturarlos para mostrar/imprimir el comprobante.
  /// POST /services/servicio/{numero_comprobante}/nota-credito/
  ///
  /// Tipos soportados:
  ///   01 — Anulación total. Solo requiere motivo.
  ///   09 — Disminución en valor. Requiere precio_nuevo (nuevo total del servicio).
  Future<({ServicioReadModel servicio, NotaCreditoData? notaCredito})>
      emitirNotaCredito(
    String numeroComprobante, {
    String codigoTipo = '01',
    required String motivo,
    String? precioNuevo,
  }) async {
    try {
      final body = <String, dynamic>{'codigo_tipo': codigoTipo};
      if (motivo.isNotEmpty) body['motivo'] = motivo;
      if (precioNuevo != null && precioNuevo.isNotEmpty) {
        body['precio_nuevo'] = precioNuevo;
      }
      final response = await _dio.post(
        'services/servicio/$numeroComprobante/nota-credito/',
        data: body,
      );
      final servicio = ServicioReadModel.fromJson(response.data);
      final ncMap = response.data['nota_credito'] as Map<String, dynamic>?;
      return (
        servicio: servicio,
        notaCredito:
            ncMap != null ? NotaCreditoData.fromJson(ncMap) : null,
      );
    } on DioException catch (e) {
      final errorMsg =
          _extractErrorMessage(e, 'Error al emitir nota de crédito');
      throw Exception(errorMsg);
    }
  }

  /// GET /services/servicio/{numero_comprobante}/ticket/ - Descargar ticket PDF
  Future<Uint8List> descargarTicketPdf(String numeroComprobante) async {
    try {
      final response = await _dio.get<List<int>>(
        'services/servicio/$numeroComprobante/ticket/',
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
      final errorMsg =
          _extractErrorMessage(e, 'Error al descargar ticket PDF');
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

    if (data is List && data.isNotEmpty) {
      return data.map((e) => e.toString()).join('\n');
    }

    if (data is Map) {
      if (data.containsKey('detail')) {
        return data['detail'].toString();
      }
      if (data.containsKey('non_field_errors')) {
        final nfe = data['non_field_errors'];
        if (nfe is List && nfe.isNotEmpty) {
          return nfe.map((e) => e.toString()).join('\n');
        }
      }
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

  /// Helper: Extrae el cursor del parámetro de URL ?cursor=
  String? _extractCursor(String? nextUrl) {
    if (nextUrl == null) return null;
    return Uri.tryParse(nextUrl)?.queryParameters['cursor'];
  }
}

/// Modelo de respuesta paginada para servicios
class ServiciosPageResult {
  final List<ServicioReadModel> items;
  final String? nextCursor;

  const ServiciosPageResult({
    required this.items,
    required this.nextCursor,
  });
}
