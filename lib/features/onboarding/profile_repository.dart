import 'package:management_system_ui/core/common_libs.dart';

final profileRepositoryProvider = Provider((ref) {
  final dio = ref.watch(dioProvider);
  return ProfileRepository(dio);
});

class ProfileRepository {
  final Dio _dio;
  ProfileRepository(this._dio);

  Future<void> completarPerfil({
    required String firstName,
    required String lastName,
  }) async {
    try {
      await _dio.patch(
        'auth/profile/complete/',
        data: {
          'first_name': firstName,
          'last_name': lastName,
        },
      );
    } on DioException catch (e) {
      final data = e.response?.data;
      String message = 'Error al actualizar el perfil';
      if (data is Map) {
        final values = data.values.first;
        message = values is List ? values.first.toString() : values.toString();
      }
      throw Exception(message);
    }
  }
}