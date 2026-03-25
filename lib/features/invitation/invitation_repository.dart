import 'package:management_system_ui/core/common_libs.dart';
import 'package:management_system_ui/core/models/store_model.dart';
import 'models/role_model.dart';
import 'models/invitation_response_model.dart';

final invitationRepositoryProvider = Provider((ref) {
  final dio = ref.watch(dioProvider);
  return InvitationRepository(dio);
});

class InvitationRepository {
  final Dio _dio;
  InvitationRepository(this._dio);

  Future<List<StoreModel>> getTiendas() async {
    try {
      final response = await _dio.get('store/');
      return (response.data as List)
          .map((e) => StoreModel.fromJson(e))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener las tiendas');
    }
  }

  Future<List<RoleModel>> getRoles() async {
    try {
      final response = await _dio.get('auth/roles/');
      return (response.data as List)
          .map((e) => RoleModel.fromJson(e))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener los roles');
    }
  }

  Future<InvitationResponseModel> registrarUsuario({
    required String email,
    required int? tiendaId,
    required String rol,
    required String salario,
  }) async {
    try {
        final data = <String, dynamic>{
        'email': email,
        'rol': rol,
        'salario': salario,
        };

        if (tiendaId != null) {
          data['tienda'] = tiendaId;
        }

        final response = await _dio.post('auth/register/', data: data);
        return InvitationResponseModel.fromJson(response.data);
    } catch (e) {
        throw Exception('Error al registrar el usuario');
    }
  }
}