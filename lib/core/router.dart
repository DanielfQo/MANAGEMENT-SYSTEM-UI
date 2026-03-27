import 'package:management_system_ui/core/common_libs.dart';
import 'package:management_system_ui/features/auth/auth_page.dart';
import 'package:management_system_ui/features/auth/auth_provider.dart';
import 'package:management_system_ui/features/auth/tienda_selection_page.dart';
import 'package:management_system_ui/features/lote/lote_form_page.dart';
import 'package:management_system_ui/features/lote/lote_detail_page.dart';
import 'package:management_system_ui/features/lote/productos_page.dart';
import 'package:management_system_ui/features/home/home_page.dart';
import 'package:management_system_ui/features/lote/lote_list_page.dart';
import 'package:management_system_ui/features/lote/inventario_page.dart';
import 'package:management_system_ui/features/venta/venta_catalogo_page.dart';
import 'package:management_system_ui/features/venta/venta_carrito_page.dart';
import 'package:management_system_ui/features/venta/venta_resumen_page.dart';
import 'package:management_system_ui/features/venta/venta_propuesta_sunat_page.dart';
import 'package:management_system_ui/features/venta/venta_comprobante_page.dart';
import 'package:management_system_ui/features/impresora/impresora_config_page.dart';
import 'package:management_system_ui/features/caja/caja_page.dart';
import 'package:management_system_ui/features/caja/caja_historial_page.dart';
import 'package:management_system_ui/features/caja/caja_resumen_page.dart';
import 'package:management_system_ui/features/caja/caja_cierre_page.dart';
import 'package:management_system_ui/features/invitation/invitation_form_page.dart';
import 'package:management_system_ui/features/invitation/invitation_accept_page.dart';
import 'package:management_system_ui/features/onboarding/profile_complete_page.dart';
import 'package:management_system_ui/features/onboarding/setup_page.dart';
import 'package:management_system_ui/features/users/usuarios_page.dart';
import 'package:management_system_ui/features/asistencia/asistencia_page.dart';
import 'package:management_system_ui/features/tienda/tiendas_page.dart';
import 'package:management_system_ui/features/tienda/tienda_form_page.dart';
import 'package:management_system_ui/core/models/store_model.dart';

class AppRoutes {
  static const invite = '/invite';
  static const login = '/login';
  static const profileComplete = '/profile/complete';
  static const setup = '/setup';
  static const selectStore = '/select-store';

  static const home = '/home';
  static const usuarios = '/usuarios';
  static const asistencia = '/asistencia';
  static const lotes = '/lotes';
  static const ventas = '/ventas';
  static const caja = '/caja';
}

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

    // Construir lista de items dinámicamente
    final items = <BottomNavigationBarItem>[
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
      const BottomNavigationBarItem(
        icon: Icon(Icons.point_of_sale_outlined),
        activeIcon: Icon(Icons.point_of_sale),
        label: 'Ventas',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.receipt_outlined),
        activeIcon: Icon(Icons.receipt),
        label: 'Caja',
      ),
      if (puedeVerUsuarios)
        const BottomNavigationBarItem(
          icon: Icon(Icons.people_outline),
          activeIcon: Icon(Icons.people),
          label: 'Usuarios',
        ),
    ];

    // Calcular currentIndex según la ruta
    int currentIndex = 0;
    if (location.startsWith('/lotes') ||
        location.startsWith('/productos')) {
      currentIndex = 1;
    } else if (location.startsWith('/ventas')) {
      currentIndex = 2;
    } else if (location.startsWith('/caja')) {
      currentIndex = 3;
    } else if (puedeVerUsuarios &&
        (location.startsWith('/usuarios') ||
         location.startsWith('/asistencia'))) {
      currentIndex = 4;
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF2F3A8F),
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          switch (index) {
            case 0:
              context.go(AppRoutes.home);
              break;
            case 1:
              context.go(AppRoutes.lotes);
              break;
            case 2:
              context.go(AppRoutes.ventas);
              break;
            case 3:
              context.go(AppRoutes.caja);
              break;
            case 4:
              if (puedeVerUsuarios) context.go(AppRoutes.usuarios);
              break;
          }
        },
        items: items,
      ),
    );
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = ref.read(authStateNotifierProvider);

  return GoRouter(
    initialLocation: AppRoutes.login,
    refreshListenable: authNotifier,
    routes: [
      GoRoute(
        path: AppRoutes.invite,
        builder: (context, state) {
          final token = state.uri.queryParameters['token'];
          return InvitationAcceptPage(token: token);
        },
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const AuthPage(),
      ),
      GoRoute(
        path: AppRoutes.profileComplete,
        builder: (context, state) => const ProfileCompletePage(),
      ),
      GoRoute(
        path: AppRoutes.setup,
        builder: (context, state) => const SetupPage(),
      ),
      GoRoute(
        path: AppRoutes.selectStore,
        builder: (context, state) => const TiendaSelectionPage(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            builder: (context, state) => const HomePage(),
          ),
          GoRoute(
            path: AppRoutes.usuarios,
            builder: (context, state) => const UsuariosPage(),
          ),
          GoRoute(
            path: AppRoutes.asistencia,
            builder: (context, state) => const AsistenciaPage(),
          ),
          GoRoute(
            path: AppRoutes.lotes,
            builder: (context, state) => const InventarioPage(),
          ),
          GoRoute(
            path: '/lotes/lista',
            builder: (context, state) => const LoteListPage(),
          ),
          GoRoute(
            path: '/lotes/crear',
            builder: (context, state) => const LoteFormPage(),
          ),
          GoRoute(
            path: '/lotes/:id',
            builder: (context, state) {
              final id = int.parse(state.pathParameters['id']!);
              return LoteDetailPage(id: id);
            },
          ),
          GoRoute(
            path: '/productos',
            builder: (context, state) => const ProductosPage(),
          ),
          GoRoute(
            path: AppRoutes.ventas,
            builder: (context, state) => const VentaCatalogoPage(),
          ),
          GoRoute(
            path: '/ventas/carrito',
            builder: (context, state) => const VentaCarritoPage(),
          ),
          GoRoute(
            path: '/ventas/resumen',
            builder: (context, state) => const VentaResumenPage(),
          ),
          GoRoute(
            path: '/ventas/propuesta-sunat',
            builder: (context, state) =>
                const VentaPropuestaSunatPage(),
          ),
          GoRoute(
            path: '/ventas/comprobante',
            builder: (context, state) =>
                const VentaComprobantePage(),
          ),
          GoRoute(
            path: '/config/impresora',
            builder: (context, state) =>
                const ImpresoraConfigPage(),
          ),
          GoRoute(
            path: AppRoutes.caja,
            builder: (context, state) => const CajaPage(),
          ),
          GoRoute(
            path: '/caja/historial',
            builder: (context, state) =>
                const CajaHistorialPage(),
          ),
          GoRoute(
            path: '/caja/resumen',
            builder: (context, state) =>
                const CajaResumenPage(),
          ),
          GoRoute(
            path: '/caja/cierre',
            builder: (context, state) =>
                const CajaCierrePage(),
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
    ],

    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final currentPath = state.uri.path;

      if (currentPath == AppRoutes.invite) return null;

      if (!authState.isAuthenticated) {
        return currentPath == AppRoutes.login ? null : AppRoutes.login;
      }

      final userMe = authState.userMe;
      final tiendas = userMe?.tiendas ?? [];
      final isDueno = userMe?.isDueno ?? false;
      final esAdmin = userMe?.rol == Roles.administrador;
      final puedeVerUsuarios = isDueno || esAdmin;

      final isProfileIncomplete = userMe?.isProfileIncomplete ?? false;
      if (isProfileIncomplete) {
        return currentPath == AppRoutes.profileComplete
            ? null
            : AppRoutes.profileComplete;
      }

      if (isDueno && tiendas.isEmpty) {
        return currentPath == AppRoutes.setup ? null : AppRoutes.setup;
      }

      if (!puedeVerUsuarios &&
          (currentPath.startsWith(AppRoutes.usuarios) ||
              currentPath.startsWith(AppRoutes.asistencia))) {
        return AppRoutes.home;
      }

      final onboardingPaths = [
        AppRoutes.login,
        AppRoutes.profileComplete,
        AppRoutes.setup,
      ];
      if (onboardingPaths.contains(currentPath)) {
        if (tiendas.isNotEmpty && authState.selectedTiendaId == null) {
          return AppRoutes.selectStore;
        }
        return AppRoutes.home;
      }

      final hasStoreSelected = authState.selectedTiendaId != null;
      if (!hasStoreSelected && tiendas.isNotEmpty) {
        return currentPath == AppRoutes.selectStore ? null : AppRoutes.selectStore;
      }

      if (hasStoreSelected && currentPath == AppRoutes.selectStore) {
        return AppRoutes.home;
      }

      return null;
    },
  );
});