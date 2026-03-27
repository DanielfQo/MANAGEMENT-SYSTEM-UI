import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_interceptor.dart';
import 'package:management_system_ui/core/constants/constants.dart';
import 'package:management_system_ui/core/utils/storage_service.dart';

bool _isDebug() {
  bool inDebugMode = false;
  assert(inDebugMode = true);
  return inDebugMode;
}

// Este provider crea una única instancia de Dio para toda la app
final dioProvider = Provider<Dio>((ref) {
  final storage = ref.watch(sessionStorageProvider);

  final dio = Dio(
    BaseOptions(
      baseUrl: AppConstants.apiBaseUrl,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 10),
      validateStatus: (status) => status != null && status < 500,
    ),
  );

  dio.interceptors.add(AuthInterceptor(dio, storage));

  // Solo loguear en debug mode
  if (_isDebug()) {
    dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
    ));
  }

  return dio;
});