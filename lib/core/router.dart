import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:management_system_ui/core/common_libs.dart';
import 'package:management_system_ui/features/auth/auth_page.dart';
import 'package:management_system_ui/features/auth/auth_provider.dart';
import 'package:management_system_ui/features/auth/tienda_selection_page.dart';
import 'package:management_system_ui/features/lote/lote_page.dart';
import 'package:management_system_ui/features/venta/venta_page.dart';
import 'package:management_system_ui/features/home/home_page.dart';

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
        path: '/lotes',
        builder: (context, state) => const LotePage(),
      ),
      GoRoute(
        path: '/select-store',
        builder: (context, state) => const TiendaSelectionPage(),
      ),
      GoRoute(
        path: '/venta',
        builder: (context, state) => const VentaPage(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomePage(),
      ),
    ],
    
    // REDIRECCIÓN LÓGICA: El "Guardian" de tu app
    redirect: (context, state) {
      final loggingIn = state.matchedLocation == '/login';
      final selectingStore = state.matchedLocation == '/select-store';

      if (!authState.isAuthenticated) {
        return loggingIn ? null : '/login';
      }

      final tiendas = authState.userMe?.tiendas ?? [];
      final hasMultipleStores = tiendas.length > 1;
      final hasStoreSelected = authState.selectedTiendaId != null;

      // Si ya está autenticado y quiere ir al login, verificar si tiene tiendas
      if (!hasStoreSelected) {
        // Si tiene multiples tiendas -> ir a seleccionar tienda
        if (hasMultipleStores) {
          return selectingStore ? null : '/select-store';
        }

        // Si solo tiene 1 tienda -> asignarla automaticamente
        if (tiendas.length == 1) {
          Future.microtask(() {
            ref.read(authProvider.notifier).selectTienda(tiendas.first.tiendaId);
          });
          return null;
        }
      }

      // Si ya tiene tienda seleccionada y esta en login o select- -> inventory
      if (hasStoreSelected && (loggingIn || selectingStore)) {
        return '/home';
      }

      return null;
    },
  );
});