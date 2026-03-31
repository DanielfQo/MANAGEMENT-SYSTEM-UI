import 'dart:typed_data';
import 'dart:convert';
import 'package:management_system_ui/core/common_libs.dart';
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
  /// Retorna ServicioConPdf con los datos y el PDF (si es NORMAL/CREDITO)
  Future<ServicioConPdf> crearServicio(ServicioCreateModel servicio) async {
    final validationError = servicio.validate();
    if (validationError != null) {
      throw Exception(validationError);
    }

    try {
      final response = await _dio.post(
        'services/servicio/',
        data: servicio.toJson(),
        options: Options(
          responseType: ResponseType.bytes,
          validateStatus: (status) => status! < 500,
        ),
      );

      // SUNAT retorna JSON (parseado como bytes y luego convertido a JSON)
      if (response.data is List<int>) {
        try {
          final jsonString = String.fromCharCodes(response.data as List<int>);
          final jsonData = jsonDecode(jsonString);
          if (jsonData is Map<String, dynamic>) {
            return ServicioConPdf(
              servicio: ServicioReadModel.fromJson(jsonData),
              pdfBytes: null,
            );
          }
        } catch (_) {
          // No es JSON, continuar como PDF
        }
      }

      // NORMAL/CREDITO retornan PDF directamente
      final pdfBytes = Uint8List.fromList(response.data as List<int>);

      // Intentar extraer numero_comprobante del header content-disposition
      // Ejemplo: filename="servicio_10.pdf" → numero_comprobante = "10"
      String? numeroComprobante;
      final contentDispositionList = response.headers['content-disposition'];
      if (contentDispositionList != null && contentDispositionList.isNotEmpty) {
        final contentDisposition = contentDispositionList.first;
        final match = RegExp(r'servicio_(\d+)\.pdf').firstMatch(contentDisposition);
        if (match != null) {
          numeroComprobante = match.group(1);
        }
      }

      // Obtener los datos completos del servicio
      final servicios = await getServicios(tiendaId: servicio.tiendaId);
      if (servicios.isNotEmpty) {
        // Si se extrajo el número, buscar ese servicio específico
        if (numeroComprobante != null) {
          final servicioCreado = servicios.firstWhere(
            (s) => s.numeroComprobante == numeroComprobante,
            orElse: () => servicios.first,
          );
          return ServicioConPdf(
            servicio: servicioCreado,
            pdfBytes: pdfBytes,
          );
        }

        // Si no se extrajo el número, retornar el más reciente
        return ServicioConPdf(
          servicio: servicios.first,
          pdfBytes: pdfBytes,
        );
      }

      throw Exception('No se pudo obtener los datos del servicio creado.');
    } on DioException catch (e) {
      final errorMsg = _extractErrorMessage(e, 'Error al crear el servicio');
      throw Exception(errorMsg);
    }
  }

  /// GET /services/servicio/ - Listar servicios con filtros opcionales
  Future<List<ServicioReadModel>> getServicios({
    required int tiendaId,
    String? tipo,
    String? search,
    String? estadoSunat,
  }) async {
    try {
      final queryParams = <String, dynamic>{'tienda': tiendaId};
      if (tipo != null) queryParams['tipo'] = tipo;
      if (search != null) queryParams['search'] = search;
      if (estadoSunat != null) queryParams['estado_sunat'] = estadoSunat;

      final response = await _dio.get(
        'services/servicio/',
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
          .map((e) => ServicioReadModel.fromJson(e))
          .toList();
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
  Future<ServicioReadModel> emitirNotaCredito(
    String numeroComprobante, {
    required String motivo,
  }) async {
    try {
      final response = await _dio.post(
        'services/servicio/$numeroComprobante/nota-credito/',
        data: {'motivo': motivo},
      );
      return ServicioReadModel.fromJson(response.data);
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
}
