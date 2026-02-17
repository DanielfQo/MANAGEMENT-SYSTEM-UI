import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:management_system_ui/core/common_libs.dart';
import 'package:management_system_ui/features/auth/auth_page.dart';
import 'package:management_system_ui/features/auth/auth_provider.dart';

// Importa tu InventoryPage cuando la crees

final routerProvider = Provider<GoRouter>((ref) {
  // Escuchamos el estado de autenticación
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const AuthPage(),
      ),
      GoRoute(
        path: '/inventory',
        builder: (context, state) => const Scaffold(body: Center(child: Text("Inventario"))),
      ),
    ],
    
    // REDIRECCIÓN LÓGICA: El "Guardian" de tu app
    redirect: (context, state) {
      final loggingIn = state.matchedLocation == '/login';

      if (!authState.isAuthenticated) {
        return loggingIn ? null : '/login';
      }

      // Si ya está autenticado y quiere ir al login, mándalo al inventario
      if (loggingIn) return '/inventory';

      return null;
    },
  );
});