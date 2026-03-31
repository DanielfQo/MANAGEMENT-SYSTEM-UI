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
import 'package:management_system_ui/features/operaciones/operaciones_hub_page.dart';
import 'package:management_system_ui/features/servicio/servicio_formulario_page.dart';
import 'package:management_system_ui/features/servicio/servicio_resumen_page.dart';
import 'package:management_system_ui/features/servicio/servicio_comprobante_page.dart';
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
  static const invitationNew = '/invitation/new';

  static const login = '/login';
  static const profileComplete = '/profile/complete';
  static const setup = '/setup';
  static const selectStore = '/select-store';

  static const home = '/home';
  static const usuarios = '/usuarios';
  static const asistencia = '/asistencia';

  static const lotes = '/lotes';
  static const lotesLista = '/lotes/lista';
  static const lotesCrear = '/lotes/crear';
  static const lotesDetalle = '/lotes/:id';
  static const productos = '/productos';

  static const ventas = '/ventas';
  static const ventasCarrito = '/ventas/carrito';
  static const ventasResumen = '/ventas/resumen';
  static const ventasPropuestaSunat = '/ventas/propuesta-sunat';
  static const ventasComprobante = '/ventas/comprobante';

  static const operaciones = '/operaciones';
  static const servicios = '/servicios';
  static const serviciosResumen = '/servicios/resumen';
  static const serviciosComprobante = '/servicios/comprobante';

  static const caja = '/caja';
  static const cajaHistorial = '/caja/historial';
  static const cajaResumen = '/caja/resumen';
  static const cajaCierre = '/caja/cierre';

  static const configImpresora = '/config/impresora';
  static const tiendas = '/tiendas';
  static const tiendasForm = '/tiendas/form';

  static const onboarding = [login, profileComplete, setup];
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
        label: 'Operaciones',
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

    final currentIndex = _resolveNavIndex(
      location: location,
      canViewUsers: puedeVerUsuarios,
    );

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
              context.go(AppRoutes.operaciones);
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

  int _resolveNavIndex({
    required String location,
    required bool canViewUsers,
  }) {
    if (location.startsWith(AppRoutes.lotes) ||
        location.startsWith(AppRoutes.productos)) {
      return 1;
    }

    if (location.startsWith(AppRoutes.operaciones) ||
        location.startsWith(AppRoutes.ventas) ||
        location.startsWith(AppRoutes.servicios)) {
      return 2;
    }
    if (location.startsWith(AppRoutes.caja)) return 3;

    if (canViewUsers &&
        (location.startsWith(AppRoutes.usuarios) ||
            location.startsWith(AppRoutes.asistencia))) {
      return 4;
    }

    return 0;
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
            path: AppRoutes.lotesLista,
            builder: (context, state) => const LoteListPage(),
          ),
          GoRoute(
            path: AppRoutes.lotesCrear,
            builder: (context, state) => const LoteFormPage(),
          ),
          GoRoute(
            path: AppRoutes.lotesDetalle,
            builder: (context, state) {
              final id = int.parse(state.pathParameters['id']!);
              return LoteDetailPage(id: id);
            },
          ),
          GoRoute(
            path: AppRoutes.productos,
            builder: (context, state) => const ProductosPage(),
          ),
          GoRoute(
            path: AppRoutes.operaciones,
            builder: (context, state) => const OperacionesHubPage(),
          ),
          GoRoute(
            path: AppRoutes.servicios,
            builder: (context, state) => const ServicioFormularioPage(),
          ),
          GoRoute(
            path: AppRoutes.serviciosResumen,
            builder: (context, state) => const ServicioResumenPage(),
          ),
          GoRoute(
            path: AppRoutes.serviciosComprobante,
            builder: (context, state) => const ServicioComprobantePage(),
          ),
          GoRoute(
            path: AppRoutes.ventas,
            builder: (context, state) => const VentaCatalogoPage(),
          ),
          GoRoute(
            path: AppRoutes.ventasCarrito,
            builder: (context, state) => const VentaCarritoPage(),
          ),
          GoRoute(
            path: AppRoutes.ventasResumen,
            builder: (context, state) => const VentaResumenPage(),
          ),
          GoRoute(
            path: AppRoutes.ventasPropuestaSunat,
            builder: (context, state) =>
                const VentaPropuestaSunatPage(),
          ),
          GoRoute(
            path: AppRoutes.ventasComprobante,
            builder: (context, state) =>
                const VentaComprobantePage(),
          ),
          GoRoute(
            path: AppRoutes.configImpresora,
            builder: (context, state) =>
                const ImpresoraConfigPage(),
          ),
          GoRoute(
            path: AppRoutes.caja,
            builder: (context, state) => const CajaPage(),
          ),
          GoRoute(
            path: AppRoutes.cajaHistorial,
            builder: (context, state) =>
                const CajaHistorialPage(),
          ),
          GoRoute(
            path: AppRoutes.cajaResumen,
            builder: (context, state) =>
                const CajaResumenPage(),
          ),
          GoRoute(
            path: AppRoutes.cajaCierre,
            builder: (context, state) =>
                const CajaCierrePage(),
          ),
          GoRoute(
            path: AppRoutes.tiendas,
            builder: (context, state) => const TiendasPage(),
          ),
          GoRoute(
            path: AppRoutes.tiendasForm,
            builder: (context, state) {
              final tienda = state.extra as StoreModel?;
              return TiendaFormPage(tiendaExistente: tienda);
            },
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.invitationNew,
        builder: (context, state) => const InvitationFormPage(),
      ),
    ],

    redirect: (context, state) => _resolveRedirect(
      authState: ref.read(authProvider),
      currentPath: state.uri.path,
    ),
  );
});

String? _resolveRedirect({
  required AuthState authState,
  required String currentPath,
}) {
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

  if (AppRoutes.onboarding.contains(currentPath)) {
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
}