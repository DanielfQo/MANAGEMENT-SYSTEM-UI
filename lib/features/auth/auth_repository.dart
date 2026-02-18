import 'package:management_system_ui/core/common_libs.dart';
import 'package:management_system_ui/features/auth/models/auth_response_model.dart';

final authRepositoryProvider = Provider((ref) {
  final dio = ref.watch(dioProvider);
  return AuthRepository(dio);
});

class AuthRepository {
  final Dio _dio;
  AuthRepository(this._dio);

  Future<AuthResponseModel> login(
    String username,
    String password,
  ) async {
    try {
      final response = await _dio.post(
        'auth/login/',
        data: {
          'username': username,
          'password': password,
        },
      );

      return AuthResponseModel.fromJson(response.data); 
    } catch (e) {
      throw Exception('Error al iniciar sesión');
    }
  }
}
