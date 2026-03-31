import 'package:management_system_ui/core/common_libs.dart';
import 'package:management_system_ui/core/router.dart';
import 'finanzas_provider.dart';
import 'models/caja_resumen_model.dart';

class CajaResumenPage extends ConsumerStatefulWidget {
  const CajaResumenPage({super.key});

  @override
  ConsumerState<CajaResumenPage> createState() => _CajaResumenPageState();
}

class _CajaResumenPageState extends ConsumerState<CajaResumenPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(finanzasProvider.notifier).cargarCajaResumen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(finanzasProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      body: SafeArea(
        child: Column(
          children: [
            CustomAppBar(
              title: 'Resumen del Día',
              subtitle: state.cajaResumen?.fecha ?? '',
              icon: Icons.payment_outlined,
              onBack: () => context.go(AppRoutes.finanzas),
            ),
            Expanded(
              child: state.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : state.errorMessage != null
                      ? ErrorState(
                          mensaje: state.errorMessage!,
                          onRetry: () =>
                              ref.read(finanzasProvider.notifier).cargarCajaResumen(),
                        )
                      : state.cajaResumen == null
                          ? EmptyState(
                              icon: Icons.money_off_outlined,
                              titulo: 'Sin datos',
                              subtitulo:
                                  'No hay resumen disponible para hoy',
                            )
                          : _buildResumen(context, state.cajaResumen!),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResumen(BuildContext context, CajaResumenModel resumen) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MetricCard(
            label: 'Total General',
            value: 'S/ ${resumen.totalGeneral}',
            color: Colors.green,
          ),
          const SizedBox(height: 24),
          const Text(
            'Métodos de Pago',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _MetricCard(
            label: 'Efectivo',
            value: 'S/ ${resumen.totalEfectivo}',
            color: Colors.blue,
          ),
          const SizedBox(height: 8),
          _MetricCard(
            label: 'Yape',
            value: 'S/ ${resumen.totalYape}',
            color: Colors.purple,
          ),
          const SizedBox(height: 8),
          _MetricCard(
            label: 'Plin',
            value: 'S/ ${resumen.totalPlin}',
            color: Colors.orange,
          ),
          const SizedBox(height: 8),
          _MetricCard(
            label: 'Tarjeta',
            value: 'S/ ${resumen.totalTarjeta}',
            color: Colors.red,
          ),
          const SizedBox(height: 8),
          _MetricCard(
            label: 'Transferencia',
            value: 'S/ ${resumen.totalTransferencia}',
            color: Colors.cyan,
          ),
          const SizedBox(height: 24),
          const Text(
            'Por Modalidad',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _MetricCard(
            label: 'Contado',
            value: 'S/ ${resumen.totalContado}',
            color: Colors.indigo,
          ),
          const SizedBox(height: 8),
          _MetricCard(
            label: 'Crédito',
            value: 'S/ ${resumen.totalCredito}',
            color: Colors.yellow[700]!,
          ),
          const SizedBox(height: 24),
          if (resumen.ventas.isNotEmpty) ...[
            const Text(
              'Ventas del Día',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ..._buildOperacionesList(resumen.ventas),
            const SizedBox(height: 24),
          ],
          if (resumen.servicios.isNotEmpty) ...[
            const Text(
              'Servicios del Día',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ..._buildOperacionesList(resumen.servicios),
            const SizedBox(height: 24),
          ],
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.go('/finanzas/caja/cierre'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1F2A7C),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Cerrar Caja',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildOperacionesList(List<OperacionInfo> operaciones) {
    return operaciones.map((op) {
      final colorTipo = op.tipo == 'SUNAT'
          ? Colors.orange[700]
          : op.tipo == 'CREDITO'
              ? Colors.amber
              : Colors.blue[700];

      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Chip(
                          label: Text(op.tipo, style: const TextStyle(fontSize: 11)),
                          backgroundColor: colorTipo?.withValues(alpha: 0.2),
                          labelStyle: TextStyle(color: colorTipo),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        const SizedBox(width: 8),
                        Chip(
                          label: Text(op.metodoPago, style: const TextStyle(fontSize: 11)),
                          backgroundColor: Colors.grey[300],
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ID: ${op.id}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Text(
                'S/ ${op.total}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
