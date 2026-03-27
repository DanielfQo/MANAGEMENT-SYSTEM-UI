import 'package:management_system_ui/core/common_libs.dart';
import 'package:management_system_ui/features/auth/auth_provider.dart';
import 'package:intl/intl.dart';

class CajaPage extends ConsumerWidget {
  const CajaPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final tienda = authState.userMe?.tiendas
        .firstWhere((t) => t.tiendaId == authState.selectedTiendaId);

    final ahora = DateTime.now();
    final fechaFormato =
        DateFormat('dd/MM/yyyy').format(ahora);

    final nombreUsuario =
        '${authState.userMe?.firstName ?? ''} ${authState.userMe?.lastName ?? ''}'.trim();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cierre de Caja'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Información de la tienda
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      tienda?.tiendaNombre ?? 'Tienda',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Fecha: $fechaFormato',
                      style: const TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Atendido por: ${nombreUsuario.isNotEmpty ? nombreUsuario : 'Usuario'}',
                      style: const TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Opciones principales
            const Text(
              'Acciones',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Botón: Ver Historial
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.history),
                label: const Text('Ver Historial de Ventas'),
                onPressed: () =>
                    context.go('/caja/historial'),
              ),
            ),
            const SizedBox(height: 12),

            // Botón: Resumen del Día
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.summarize),
                label: const Text('Resumen del Día'),
                onPressed: () =>
                    context.go('/caja/resumen'),
              ),
            ),
            const SizedBox(height: 12),

            // Botón: Cerrar Caja
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.lock),
                label: const Text('Realizar Cierre de Caja'),
                onPressed: () =>
                    context.go('/caja/cierre'),
              ),
            ),
            const SizedBox(height: 32),

            // Información útil
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                border: Border.all(
                  color: Colors.blue,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info,
                        color: Colors.blue[900],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'El cierre de caja registra '
                          'los ingresos reales y '
                          'finaliza el turno.',
                          style: TextStyle(
                            color: Colors.blue[900],
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
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
