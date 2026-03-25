import 'package:management_system_ui/core/common_libs.dart';
import 'models/asistencia_model.dart';
import 'models/asistencia_resumen_model.dart';

export 'models/asistencia_model.dart';
export 'models/asistencia_resumen_model.dart';

final asistenciaRepositoryProvider = Provider((ref) {
  final dio = ref.watch(dioProvider);
  return AsistenciaRepository(dio);
});

class AsistenciaRepository {
  final Dio _dio;
  AsistenciaRepository(this._dio);

  Future<List<AsistenciaModel>> getAsistencias({
    int? usuarioTienda,
    String? fecha,
  }) async {
    try {
      final queryParameters = <String, dynamic>{};
      if (usuarioTienda != null) queryParameters['usuario_tienda'] = usuarioTienda;
      if (fecha != null) queryParameters['fecha'] = fecha;

      final response = await _dio.get(
        'auth/asistencia/',
        queryParameters: queryParameters.isNotEmpty ? queryParameters : null,
      );
      return (response.data as List)
          .map((e) => AsistenciaModel.fromJson(e))
          .toList();
    } on DioException catch (e) {
      final detail =
          e.response?.data['detail'] ?? 'Error al obtener asistencias';
      throw Exception(detail);
    }
  }

  Future<List<AsistenciaResumenModel>> getResumen({
    required int mes,
    required int anio,
    int? usuarioTienda,
  }) async {
    try {
      final queryParameters = <String, dynamic>{
        'mes': mes,
        'anio': anio,
      };
      if (usuarioTienda != null) queryParameters['usuario_tienda'] = usuarioTienda;

      final response = await _dio.get(
        'auth/asistencia/resumen/',
        queryParameters: queryParameters,
      );
      return (response.data as List)
          .map((e) => AsistenciaResumenModel.fromJson(e))
          .toList();
    } on DioException catch (e) {
      final detail =
          e.response?.data['detail'] ?? 'Error al obtener resumen';
      throw Exception(detail);
    }
  }

  Future<void> marcarEntrada(int usuarioTiendaId) async {
    try {
      await _dio.post(
        'auth/asistencia/entrada/',
        data: {'usuario_tienda': usuarioTiendaId},
      );
    } on DioException catch (e) {
      final data = e.response?.data;
      String message = 'Error al marcar entrada';
      if (data is Map) {
        final values = data.values.first;
        message = values is List ? values.first.toString() : values.toString();
      }
      throw Exception(message);
    }
  }

  Future<void> marcarSalida({
    required int usuarioTiendaId,
    required bool almuerzo,
  }) async {
    try {
      await _dio.post(
        'auth/asistencia/salida/',
        data: {
          'usuario_tienda': usuarioTiendaId,
          'almuerzo': almuerzo,
        },
      );
    } on DioException catch (e) {
      final data = e.response?.data;
      String message = 'Error al marcar salida';
      if (data is Map) {
        final values = data.values.first;
        message = values is List ? values.first.toString() : values.toString();
      }
      throw Exception(message);
    }
  }
}