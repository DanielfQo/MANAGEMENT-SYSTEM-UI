import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/riverpod.dart';

// Este provider crea una única instancia de Dio para toda la app
final dioProvider = Provider<Dio>((ref) {
  return Dio(
    BaseOptions(
      baseUrl: 'http://127.0.0.1:8000/api/',
      connectTimeout: const Duration(seconds: 5),
    ),
  );
});