import 'package:management_system_ui/core/common_libs.dart';
import 'package:intl/intl.dart';
import 'package:management_system_ui/features/venta/venta_provider.dart';

class CajaResumenPage extends ConsumerStatefulWidget {
  const CajaResumenPage({super.key});

  @override
  ConsumerState<CajaResumenPage> createState() =>
      _CajaResumenPageState();
}

class _CajaResumenPageState extends ConsumerState<CajaResumenPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(ventaProvider.notifier).cargarVentas();
    });
  }

  @override
  Widget build(BuildContext context) {
    final ventaState = ref.watch(ventaProvider);

    // Calcular resumen
    double totalIngresos = 0;
    int cantidadVentas = 0;

    for (final venta in ventaState.ventas) {
      totalIngresos += venta.total;
      cantidadVentas++;
    }

    final promedio = cantidadVentas > 0
        ? totalIngresos / cantidadVentas
        : 0.0;

    final ahora = DateTime.now();
    final fechaFormato =
        DateFormat('dd/MM/yyyy').format(ahora);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resumen del Día'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/caja'),
        ),
      ),
      body: ventaState.isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  // Fecha
                  Card(
                    child: Padding(
                      padding:
                          const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today),
                          const SizedBox(width: 12),
                          Text(
                            'Fecha: $fechaFormato',
                            style: const TextStyle(
                              fontWeight:
                                  FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Métricas principales
                  const Text(
                    'Resumen de Ventas',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Total Ingresos
                  _MetricaCard(
                    titulo: 'Total Ingresos',
                    valor: 'S/. ${totalIngresos.toStringAsFixed(2)}',
                    icono: Icons.attach_money,
                    color: Colors.green,
                  ),
                  const SizedBox(height: 12),

                  // Cantidad de Ventas
                  _MetricaCard(
                    titulo: 'Cantidad de Ventas',
                    valor: '$cantidadVentas',
                    icono: Icons.shopping_cart,
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 12),

                  // Promedio por Venta
                  _MetricaCard(
                    titulo: 'Promedio por Venta',
                    valor: 'S/. ${promedio.toStringAsFixed(2)}',
                    icono: Icons.trending_up,
                    color: Colors.orange,
                  ),
                  const SizedBox(height: 32),

                  // Nota
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber[50],
                      border: Border.all(
                        color: Colors.amber,
                      ),
                      borderRadius:
                          BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info,
                          color: Colors.amber[900],
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Para proceder con el cierre,'
                            ' verifica estos datos '
                            'contra el efectivo físico.',
                            style: TextStyle(
                              color:
                                  Colors.amber[900],
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Botón Proceder al Cierre
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.lock),
                      label: const Text(
                        'Proceder al Cierre de Caja',
                      ),
                      onPressed: () =>
                          context.go('/caja/cierre'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _MetricaCard extends StatelessWidget {
  final String titulo;
  final String valor;
  final IconData icono;
  final Color color;

  const _MetricaCard({
    required this.titulo,
    required this.valor,
    required this.icono,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius:
                    BorderRadius.circular(8),
              ),
              child: Icon(icono, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    valor,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
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
