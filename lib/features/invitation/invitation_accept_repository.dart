import 'package:management_system_ui/core/common_libs.dart';

final invitationAcceptRepositoryProvider = Provider((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConstants.apiBaseUrl,
      connectTimeout: const Duration(seconds: 5),
    ),
  );
  dio.interceptors.add(LogInterceptor(
    requestBody: true,
    responseBody: true,
  ));
  return InvitationAcceptRepository(dio);
});

class ValidarTokenResponse {
  final String mensaje;
  final String usuario;

  ValidarTokenResponse({required this.mensaje, required this.usuario});

  factory ValidarTokenResponse.fromJson(Map<String, dynamic> json) {
    return ValidarTokenResponse(
      mensaje: json['mensaje'],
      usuario: json['usuario'],
    );
  }
}

class InvitationAcceptRepository {
  final Dio _dio;
  InvitationAcceptRepository(this._dio);

  Future<ValidarTokenResponse> validarToken(String token) async {
    try {
      final response = await _dio.post(
        'auth/invitacion/validar/',
        data: {'token': token},
      );
      return ValidarTokenResponse.fromJson(response.data);
    } on DioException catch (e) {
      final detail = e.response?.data['detail'] ??
          e.response?.data['error'] ??
          'Token inválido o expirado';
      throw Exception(detail);
    }
  }

  Future<String> completarInvitacion({
    required String token,
    required String password,
    required String confirmarPassword,
  }) async {
    try {
      final response = await _dio.post(
        'auth/invitacion/completar/',
        data: {
          'token': token,
          'password': password,
          'confirmar_password': confirmarPassword,
        },
      );
      return response.data['mensaje'];
    } on DioException catch (e) {
      final data = e.response?.data;
      String message = 'Error al completar el registro';
      if (data is Map) {
        final values = data.values.first;
        if (values is List) {
          message = values.first.toString();
        } else {
          message = values.toString();
        }
      }
      throw Exception(message);
    }
  }
}