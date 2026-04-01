import 'package:management_system_ui/core/common_libs.dart';
import 'package:management_system_ui/core/router.dart';
import 'package:management_system_ui/features/auth/auth_provider.dart';
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

    ref.listen(authProvider, (previous, next) {
      if (previous?.selectedTiendaId != next.selectedTiendaId) {
        ref.read(finanzasProvider.notifier).cargarCajaResumen();
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      body: SafeArea(
        child: Column(
          children: [
            CustomAppBar(
              title: 'Caja',
              subtitle: state.cajaResumen?.fecha ?? 'Resumen del día',
              icon: Icons.payment_outlined,
              isTiendaTitle: true,
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
                              subtitulo: 'No hay resumen disponible para hoy',
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
          // ── Total general destacado ──────────────────────────────────────
          _TotalCard(
            label: 'Total del Día',
            value: 'S/ ${resumen.totalGeneral}',
            color: Colors.green,
            icon: Icons.attach_money,
          ),
          const SizedBox(height: 16),

          // ── Resumen de Ventas ────────────────────────────────────────────
          if (resumen.resumenVentas != null) ...[
            _SectionHeader(
              label: 'Ventas',
              icon: Icons.shopping_cart_outlined,
              color: Colors.blue,
            ),
            const SizedBox(height: 8),
            _GroupCard(
              children: [
                _MetricRow(
                  label: 'Total',
                  value: 'S/ ${resumen.resumenVentas!.totalGeneral}',
                  valueColor: Colors.blue,
                  bold: true,
                ),
                const _RowDivider(),
                _MetricRow(
                  label: 'Contado',
                  value: 'S/ ${resumen.resumenVentas!.totalContado}',
                ),
                const _RowDivider(),
                _MetricRow(
                  label: 'Crédito',
                  value: 'S/ ${resumen.resumenVentas!.totalCredito}',
                  valueColor: Colors.amber[700]!,
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // ── Resumen de Servicios ─────────────────────────────────────────
          if (resumen.resumenServicios != null) ...[
            _SectionHeader(
              label: 'Servicios',
              icon: Icons.build_outlined,
              color: Colors.teal,
            ),
            const SizedBox(height: 8),
            _GroupCard(
              children: [
                _MetricRow(
                  label: 'Total',
                  value: 'S/ ${resumen.resumenServicios!.totalGeneral}',
                  valueColor: Colors.teal,
                  bold: true,
                ),
                const _RowDivider(),
                _MetricRow(
                  label: 'Contado',
                  value: 'S/ ${resumen.resumenServicios!.totalContado}',
                ),
                const _RowDivider(),
                _MetricRow(
                  label: 'Crédito',
                  value: 'S/ ${resumen.resumenServicios!.totalCredito}',
                  valueColor: Colors.amber[700]!,
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // ── Métodos de pago ──────────────────────────────────────────────
          _SectionHeader(
            label: 'Métodos de Pago',
            icon: Icons.credit_card_outlined,
            color: const Color(0xFF2F3A8F),
          ),
          const SizedBox(height: 8),
          _GroupCard(
            children: [
              _MetricRow(
                label: 'Efectivo',
                value: 'S/ ${resumen.totalEfectivo}',
                icon: Icons.money,
                iconColor: Colors.green,
              ),
              const _RowDivider(),
              _MetricRow(
                label: 'Yape',
                value: 'S/ ${resumen.totalYape}',
                icon: Icons.phone_android,
                iconColor: Colors.purple,
              ),
              const _RowDivider(),
              _MetricRow(
                label: 'Plin',
                value: 'S/ ${resumen.totalPlin}',
                icon: Icons.phone_android,
                iconColor: Colors.teal,
              ),
              const _RowDivider(),
              _MetricRow(
                label: 'Tarjeta',
                value: 'S/ ${resumen.totalTarjeta}',
                icon: Icons.credit_card,
                iconColor: Colors.indigo,
              ),
              const _RowDivider(),
              _MetricRow(
                label: 'Transferencia',
                value: 'S/ ${resumen.totalTransferencia}',
                icon: Icons.swap_horiz,
                iconColor: Colors.cyan[700]!,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Por modalidad ────────────────────────────────────────────────
          _SectionHeader(
            label: 'Por Modalidad',
            icon: Icons.bar_chart,
            color: Colors.indigo,
          ),
          const SizedBox(height: 8),
          _GroupCard(
            children: [
              _MetricRow(
                label: 'Contado',
                value: 'S/ ${resumen.totalContado}',
                valueColor: Colors.indigo,
              ),
              const _RowDivider(),
              _MetricRow(
                label: 'Crédito',
                value: 'S/ ${resumen.totalCredito}',
                valueColor: Colors.amber[700]!,
              ),
            ],
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.lock_outline, color: Colors.white),
              label: const Text(
                'Cerrar Caja',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              onPressed: () => context.go('/finanzas/caja/cierre'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1F2A7C),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Sub-widgets ────────────────────────────────────────────────────────────

class _TotalCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _TotalCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.15), color.withValues(alpha: 0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _SectionHeader({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: color,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

class _GroupCard extends StatelessWidget {
  final List<Widget> children;

  const _GroupCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, indent: 16, endIndent: 16);
  }
}

class _MetricRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool bold;
  final IconData? icon;
  final Color? iconColor;

  const _MetricRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.bold = false,
    this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: iconColor ?? Colors.grey),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: bold ? FontWeight.bold : FontWeight.w600,
              color: valueColor ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
