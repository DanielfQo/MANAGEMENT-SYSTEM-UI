import 'package:management_system_ui/core/common_libs.dart';
import 'models/usuario_tienda_model.dart';
import 'models/refrescar_invitacion_response_model.dart';

export 'models/usuario_tienda_model.dart';
export 'models/refrescar_invitacion_response_model.dart';

final usuariosRepositoryProvider = Provider((ref) {
  final dio = ref.watch(dioProvider);
  return UsuariosRepository(dio);
});

class UsuariosRepository {
  final Dio _dio;
  UsuariosRepository(this._dio);

  Future<List<UsuarioTiendaModel>> getUsuarios({
    int? tiendaId,
    String? rol,
  }) async {
    try {
      final queryParameters = <String, dynamic>{};
      if (tiendaId != null) queryParameters['tienda'] = tiendaId;
      if (rol != null) queryParameters['rol'] = rol;

      final response = await _dio.get(
        'auth/usuario-tienda/',
        queryParameters: queryParameters.isNotEmpty ? queryParameters : null,
      );
      return (response.data as List)
          .map((e) => UsuarioTiendaModel.fromJson(e))
          .toList();
    } on DioException catch (e) {
      final detail =
          e.response?.data['detail'] ?? 'Error al obtener usuarios';
      throw Exception(detail);
    }
  }

  Future<UsuarioTiendaModel> editarUsuario({
    required int id,
    int? tiendaId,
    String? rol,
    String? salario,
  }) async {
    try {
      await _dio.patch(
        'auth/usuario-tienda/$id/',
        data: {
          'tienda': tiendaId,
          'rol': rol,
          'salario': salario,
        },
      );
      final response = await _dio.get('auth/usuario-tienda/$id/');
      return UsuarioTiendaModel.fromJson(response.data);
    } on DioException catch (e) {
      final data = e.response?.data;
      String message = 'Error al editar el usuario';
      if (data is Map) {
        final values = data.values.first;
        message = values is List ? values.first.toString() : values.toString();
      }
      throw Exception(message);
    }
  }

  Future<UsuarioTiendaModel> toggleEstado(int id) async {
    try {
      await _dio.patch('auth/usuario-tienda/$id/estado/');
      final response = await _dio.get('auth/usuario-tienda/$id/');
      return UsuarioTiendaModel.fromJson(response.data);
    } on DioException catch (e) {
      final data = e.response?.data;
      String message = 'Error al cambiar el estado del usuario';
      if (data is Map) {
        final values = data.values.first;
        message = values is List ? values.first.toString() : values.toString();
      }
      throw Exception(message);
    }
  }

  Future<RefrescarInvitacionResponse> refrescarInvitacion(
      int usuarioId) async {
    try {
      final response = await _dio.post(
        'auth/invitacion/$usuarioId/refrescar/',
      );
      return RefrescarInvitacionResponse.fromJson(response.data);
    } on DioException catch (e) {
      final detail = e.response?.data['error'] ??
          e.response?.data['detail'] ??
          'Error al refrescar la invitación';
      throw Exception(detail);
    }
  }
}