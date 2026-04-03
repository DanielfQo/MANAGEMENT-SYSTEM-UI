import 'package:management_system_ui/core/common_libs.dart';
import 'package:management_system_ui/features/auth/auth_provider.dart';
import 'package:management_system_ui/features/tienda/tienda_switcher_sheet.dart';
import 'package:management_system_ui/features/venta/venta_provider.dart';
import 'package:management_system_ui/features/servicio/servicio_provider.dart';

class OperacionesHubPage extends ConsumerStatefulWidget {
  const OperacionesHubPage({super.key});

  @override
  ConsumerState<OperacionesHubPage> createState() =>
      _OperacionesHubPageState();
}

class _OperacionesHubPageState extends ConsumerState<OperacionesHubPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(ventaProvider.notifier).cargarVentas();
      ref.read(servicioProvider.notifier).cargarServicios();
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final esDueno = authState.userMe?.isDueno ?? false;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      body: SafeArea(
        child: Column(
          children: [
            CustomAppBar(
              title: 'Operaciones',
              subtitle: 'Ventas y servicios',
              icon: Icons.point_of_sale,
              isTiendaTitle: esDueno,
              onTiendaPressed:
                  esDueno ? () => showTiendaSwitcher(context) : null,
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await Future.wait([
                    ref.read(ventaProvider.notifier).cargarVentas(),
                    ref.read(servicioProvider.notifier).cargarServicios(),
                  ]);
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Cards de acciones
                      _buildAccionCard(
                        icon: Icons.shopping_cart,
                        label: 'Nueva Venta',
                        subtitle: 'Iniciar una venta desde el catálogo',
                        color: const Color(0xFF2F3A8F),
                        onTap: () => context.go('/ventas'),
                      ),
                      const SizedBox(height: 12),
                      _buildAccionCard(
                        icon: Icons.build,
                        label: 'Nuevo Servicio',
                        subtitle: 'Registrar un servicio realizado',
                        color: const Color(0xFF00897B),
                        onTap: () => context.go('/servicios'),
                      ),
                      const SizedBox(height: 24),

                      // Botón al historial
                      GestureDetector(
                        onTap: () =>
                            context.go('/operaciones/historial'),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF2F3A8F).withValues(alpha: 0.08),
                                const Color(0xFF2F3A8F).withValues(alpha: 0.03),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color:
                                  const Color(0xFF2F3A8F).withValues(alpha: 0.25),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2F3A8F)
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.history,
                                  color: Color(0xFF2F3A8F),
                                  size: 26,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Historial de operaciones',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1F1F1F),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Consulta ventas, servicios y transacciones',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios,
                                color: Colors.grey[500],
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccionCard({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
