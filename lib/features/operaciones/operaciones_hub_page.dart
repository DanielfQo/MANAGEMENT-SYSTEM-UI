import 'package:management_system_ui/core/common_libs.dart';
import 'package:management_system_ui/features/auth/auth_provider.dart';
import 'package:management_system_ui/features/tienda/tienda_switcher_sheet.dart';

class OperacionesHubPage extends ConsumerWidget {
  const OperacionesHubPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final userMe = authState.userMe;
    final esDueno = userMe?.isDueno ?? false;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            CustomAppBar(
              title: 'Operaciones',
              subtitle: 'Gestiona tus operaciones',
              icon: Icons.point_of_sale,
              isTiendaTitle: esDueno,
              onTiendaPressed:
                  esDueno ? () => showTiendaSwitcher(context) : null,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Cards de acciones rápidas
                    Row(
                      children: [
                        Expanded(
                          child: _ActionCard(
                            icon: Icons.shopping_cart,
                            title: 'Nueva Venta',
                            color: const Color(0xFF2F3A8F),
                            onTap: () => context.go('/ventas'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _ActionCard(
                            icon: Icons.build,
                            title: 'Nuevo Servicio',
                            color: const Color(0xFF27AE60),
                            onTap: () => context.go('/servicios'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    // Botón para ver historial
                    GestureDetector(
                      onTap: () => context.go('/operaciones/historial'),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.history,
                                color: Colors.grey[700], size: 24),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Historial de operaciones',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[900],
                                    ),
                                  ),
                                  Text(
                                    'Ver ventas y servicios',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.arrow_forward,
                                color: Colors.grey[600], size: 20),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 40),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
