

import 'package:management_system_ui/core/common_libs.dart';

class AuthInterceptor extends Interceptor {

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {

    final token = await StorageService.getToken();

    if (token != null && token.isNotEmpty) {
      options.headers["Authorization"] = "Bearer ${token.trim()}";
    }

    handler.next(options);
  }
}