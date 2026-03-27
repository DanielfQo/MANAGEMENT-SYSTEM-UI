import 'package:management_system_ui/core/common_libs.dart';
import 'package:management_system_ui/core/network/auth_events.dart';

class AuthInterceptor extends Interceptor {
  final Dio _dio;
  final SessionStorage _storage;

  AuthInterceptor(this._dio, this._storage);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.getToken();

    if (token != null && token.isNotEmpty) {
      options.headers["Authorization"] = "Bearer ${token.trim()}";
    }

    handler.next(options);
  }

  @override
  void onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode != 401 ||
        err.requestOptions.path.contains('auth/refresh/')) {
      return handler.next(err);
    }

    try {
      final refreshToken = await _storage.getRefreshToken();
      if (refreshToken == null) return handler.next(err);

      final response = await Dio().post(
        '${err.requestOptions.baseUrl}auth/refresh/',
        data: {'refresh': refreshToken},
      );

      final newAccessToken = response.data['access'];
      final newRefreshToken = response.data['refresh'];

      await _storage.saveToken(newAccessToken);
      await _storage.saveRefreshToken(newRefreshToken);

      
      final options = err.requestOptions;
      options.headers['Authorization'] = 'Bearer $newAccessToken';

      final retryResponse = await _dio.fetch(options);
      return handler.resolve(retryResponse);
    } catch (_) {
      authEventController.add(AuthEvent.logout);
      return handler.next(err);
    }
  }
}