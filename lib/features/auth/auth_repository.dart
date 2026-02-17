import 'package:management_system_ui/core/common_libs.dart';

final authRepositoryProvider = Provider((ref) {
  final dio = ref.watch(dioProvider);
  return AuthRepository(dio);
});

class AuthRepository {
  final Dio _dio;
  AuthRepository(this._dio);

  Future<void> login(String email, String password) async {
    // Aquí irá tu lógica de peticiones POST
  }
}