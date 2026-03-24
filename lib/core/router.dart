import 'package:flutter/material.dart';
import 'package:management_system_ui/core/common_libs.dart';
import 'package:management_system_ui/features/auth/auth_page.dart';
import 'package:management_system_ui/features/auth/auth_provider.dart';
import 'package:management_system_ui/features/auth/tienda_selection_page.dart';
import 'package:management_system_ui/features/lote/lote_page.dart';
import 'package:management_system_ui/features/venta/venta_page.dart';
import 'package:management_system_ui/features/home/home_page.dart';
import 'package:management_system_ui/features/lote/lote_list_page.dart';
import 'package:management_system_ui/features/lote/inventario_page.dart';
import 'package:management_system_ui/features/venta/ventas_page.dart';
import 'package:management_system_ui/features/venta/venta_historial_page.dart';
import 'package:management_system_ui/features/invitation/invitation_form_page.dart';
import 'package:management_system_ui/features/invitation/invitation_accept_page.dart';
import 'package:management_system_ui/features/onboarding/profile_complete_page.dart';
import 'package:management_system_ui/features/onboarding/setup_page.dart';
import 'package:management_system_ui/features/users/usuarios_page.dart';
import 'package:management_system_ui/features/asistencia/asistencia_page.dart';
import 'package:management_system_ui/features/tienda/tiendas_page.dart';
import 'package:management_system_ui/features/tienda/tienda_form_page.dart';
import 'package:management_system_ui/core/models/store_model.dart';

class AuthStateNotifier extends ChangeNotifier {
  final Ref _ref;
  AuthStateNotifier(this._ref) {
    _ref.listen(authProvider, (_, _) => notifyListeners());
  }
}

final authStateNotifierProvider = Provider<AuthStateNotifier>((ref) {
  return AuthStateNotifier(ref);
});

class MainShell extends ConsumerWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userMe = ref.watch(authProvider).userMe;
    final esDueno = userMe?.isDueno ?? false;
    final esAdmin = userMe?.rol == Roles.administrador;
    final puedeVerUsuarios = esDueno || esAdmin;
    final location = GoRouterState.of(context).uri.path;

    int currentIndex = 0;
    if (location.startsWith('/lotes')) currentIndex = 1;
    if (location == '/usuarios' || location == '/ventas') currentIndex = 2;
    if (location == '/asistencia' && puedeVerUsuarios) currentIndex = 3;

    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF2F3A8F),
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          if (index == 0) context.go('/home');
          if (index == 1) context.go('/lotes');
          if (index == 2) {
            puedeVerUsuarios
                ? context.go('/usuarios')
                : context.go('/ventas');
          }
          if (index == 3 && puedeVerUsuarios) context.go('/asistencia');
        },
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined),
            activeIcon: Icon(Icons.inventory_2),
            label: 'Inventario',
          ),
          if (puedeVerUsuarios)
            const BottomNavigationBarItem(
              icon: Icon(Icons.people_outline),
              activeIcon: Icon(Icons.people),
              label: 'Usuarios',
            )
          else
            const BottomNavigationBarItem(
              icon: Icon(Icons.point_of_sale_outlined),
              activeIcon: Icon(Icons.point_of_sale),
              label: 'Ventas',
            ),
          if (puedeVerUsuarios)
            const BottomNavigationBarItem(
              icon: Icon(Icons.access_time_outlined),
              activeIcon: Icon(Icons.access_time_filled),
              label: 'Asistencia',
            ),
        ],
      ),
    );
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = ref.read(authStateNotifierProvider);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: authNotifier,
    routes: [
      GoRoute(
        path: '/invite',
        builder: (context, state) {
          final token = state.uri.queryParameters['token'];
          return InvitationAcceptPage(token: token);
        },
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const AuthPage(),
      ),
      GoRoute(
        path: '/profile/complete',
        builder: (context, state) => const ProfileCompletePage(),
      ),
      GoRoute(
        path: '/setup',
        builder: (context, state) => const SetupPage(),
      ),
      GoRoute(
        path: '/select-store',
        builder: (context, state) => const TiendaSelectionPage(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomePage(),
          ),
          GoRoute(
            path: '/usuarios',
            builder: (context, state) => const UsuariosPage(),
          ),
          GoRoute(
            path: '/asistencia',
            builder: (context, state) => const AsistenciaPage(),
          ),
          GoRoute(
            path: '/lotes',
            builder: (context, state) => const InventarioPage(),
          ),
          GoRoute(
            path: '/lotes/stock',
            builder: (context, state) => const LoteListPage(),
          ),
          GoRoute(
            path: '/lotes/crear',
            builder: (context, state) => const LotePage(),
          ),
          GoRoute(
            path: '/ventas',
            builder: (context, state) => const VentasPage(),
          ),
          GoRoute(
            path: '/ventas/historial',
            builder: (context, state) => const VentaHistorialPage(),
          ),
          GoRoute(
            path: '/tiendas',
            builder: (context, state) => const TiendasPage(),
          ),
          GoRoute(
            path: '/tiendas/form',
            builder: (context, state) {
              final tienda = state.extra as StoreModel?;
              return TiendaFormPage(tiendaExistente: tienda);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/invitation/new',
        builder: (context, state) => const InvitationFormPage(),
      ),
      GoRoute(
        path: '/ventas/nueva',
        builder: (context, state) => const VentaPage(),
      ),
    ],

    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final currentPath = state.uri.path;

      if (currentPath == '/invite') return null;

      if (!authState.isAuthenticated) {
        return currentPath == '/login' ? null : '/login';
      }

      final userMe = authState.userMe;
      final tiendas = userMe?.tiendas ?? [];
      final isDueno = userMe?.isDueno ?? false;

      final isProfileIncomplete = userMe?.isProfileIncomplete ?? false;
      if (isProfileIncomplete) {
        return currentPath == '/profile/complete' ? null : '/profile/complete';
      }

      if (isDueno && tiendas.isEmpty) {
        return currentPath == '/setup' ? null : '/setup';
      }

      final onboardingPaths = ['/login', '/profile/complete', '/setup'];
      if (onboardingPaths.contains(currentPath)) {
        if (tiendas.length > 1 && authState.selectedTiendaId == null) {
          return '/select-store';
        }
        return '/home';
      }

      final hasStoreSelected = authState.selectedTiendaId != null;
      if (!hasStoreSelected) {
        if (tiendas.length > 1) {
          return currentPath == '/select-store' ? null : '/select-store';
        }
        if (tiendas.length == 1) {
          Future.microtask(() async {
            await ref
                .read(authProvider.notifier)
                .selectTienda(tiendas.first.tiendaId);
          });
          return null;
        }
      }

      if (hasStoreSelected && currentPath == '/select-store') {
        return '/home';
      }

      return null;
    },
  );
});