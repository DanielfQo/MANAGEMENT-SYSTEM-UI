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

  Future<List<UsuarioTiendaModel>> getUsuarios({int? tiendaId}) async {
    try {
      final response = await _dio.get(
        'auth/usuario-tienda/',
        queryParameters: {
          if (tiendaId != null) 'tienda': tiendaId,
        },
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