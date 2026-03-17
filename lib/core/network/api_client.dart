import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/riverpod.dart';
import '../utils/storage_service.dart';
import 'auth_interceptor.dart';

// Este provider crea una única instancia de Dio para toda la app
final dioProvider = Provider<Dio>((ref) {

  final dio = Dio(
    BaseOptions(
      baseUrl: "http://127.0.0.1:8000/api/",
      connectTimeout: const Duration(seconds: 5),
    ),
  );

  dio.interceptors.add(AuthInterceptor());

  dio.interceptors.add(LogInterceptor(
    requestBody: true,
    responseBody: true,
  ));

  return dio;
});