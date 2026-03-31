import 'package:management_system_ui/core/common_libs.dart';
import 'package:management_system_ui/features/auth/models/auth_response_model.dart';
import 'package:management_system_ui/features/auth/models/user_me_model.dart';

final authRepositoryProvider = Provider((ref) {
  final dio = ref.watch(dioProvider);
  final storage = ref.watch(sessionStorageProvider);
  return AuthRepository(dio, storage);
});

class AuthRepository {
  final Dio _dio;
  final SessionStorage _storage;
  AuthRepository(this._dio, this._storage);

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

      await _storage.saveToken(response.data['access']);
      await _storage.saveRefreshToken(response.data['refresh']);

      return AuthResponseModel.fromJson(response.data); 
    } on DioException catch (e, st) {
      throw _mapDioAuthFailure(e, st);
    } catch (e, st) {
      throw AuthFailure(
        AuthErrorType.unknown,
        'Error inesperado al iniciar sesion',
        cause: e,
        stackTrace: st,
      );
    }
  }

  Future<UserMeModel> getMe() async {
    final response = await _dio.get('auth/me/');
    return UserMeModel.fromJson(response.data);
  }

  AuthFailure _mapDioAuthFailure(DioException e, StackTrace st) {
    final statusCode = e.response?.statusCode;
    final data = e.response?.data;

    if (statusCode == 401) {
      if (data is Map<String, dynamic>) {
        final detail = data['detail']?.toString();
        if (detail != null && detail.isNotEmpty) {
          return AuthFailure(
            AuthErrorType.unauthorized,
            detail,
            cause: e,
            stackTrace: st,
          );
        }
      }
      return AuthFailure(
        AuthErrorType.unauthorized,
        'Usuario o contrasena incorrectos',
        cause: e,
        stackTrace: st,
      );
    }

    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return AuthFailure(
        AuthErrorType.timeout,
        'Tiempo de espera agotado. Intenta nuevamente',
        cause: e,
        stackTrace: st,
      );
    }

    if (e.type == DioExceptionType.connectionError) {
      return AuthFailure(
        AuthErrorType.network,
        'No se pudo conectar con el servidor',
        cause: e,
        stackTrace: st,
      );
    }

    if (data is Map<String, dynamic>) {
      final detail = data['detail']?.toString();
      if (detail != null && detail.isNotEmpty) {
        return AuthFailure(
          AuthErrorType.auth,
          detail,
          cause: e,
          stackTrace: st,
        );
      }
    }

    return AuthFailure(
      AuthErrorType.auth,
      'Error al iniciar sesion${statusCode != null ? ' (HTTP $statusCode)' : ''}',
      cause: e,
      stackTrace: st,
    );
  }
}

enum AuthErrorType { unauthorized, network, timeout, auth, unknown }

class AuthFailure implements Exception {
  final AuthErrorType type;
  final String message;
  final Object? cause;
  final StackTrace? stackTrace;

  const AuthFailure(
    this.type,
    this.message, {
    this.cause,
    this.stackTrace,
  });

  @override
  String toString() => message;
}
