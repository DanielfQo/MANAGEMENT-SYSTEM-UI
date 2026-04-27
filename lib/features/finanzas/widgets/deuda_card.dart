import 'package:management_system_ui/core/common_libs.dart';
import 'package:management_system_ui/features/finanzas/constants/estados_deuda.dart';
import 'package:management_system_ui/features/finanzas/models/deuda_model.dart';

class DeudaCard extends StatelessWidget {
  final DeudaModel deuda;
  final VoidCallback? onPayTap;

  const DeudaCard({
    super.key,
    required this.deuda,
    this.onPayTap,
  });

  IconData get _origenIcon {
    switch (deuda.tipoOrigen.toUpperCase()) {
      case 'VENTA':
        return Icons.shopping_cart_outlined;
      case 'SERVICIO':
        return Icons.build_outlined;
      default:
        return Icons.receipt_outlined;
    }
  }

  Color get _origenColor {
    switch (deuda.tipoOrigen.toUpperCase()) {
      case 'VENTA':
        return Colors.blue;
      case 'SERVICIO':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  String get _origenLabel {
    final tipo = deuda.tipoOrigen.toUpperCase();
    if (tipo == 'VENTA') return 'Venta';
    if (tipo == 'SERVICIO') return 'Servicio';
    return deuda.tipoOrigen;
  }

  @override
  Widget build(BuildContext context) {
    final esActiva = deuda.estado == EstadosDeuda.activa;
    final montoTotal = double.tryParse(deuda.montoTotal) ?? 0;
    final saldo = double.tryParse(deuda.saldo) ?? 0;
    final pagado = montoTotal - saldo;
    final progreso = montoTotal > 0 ? (pagado / montoTotal).clamp(0.0, 1.0) : 0.0;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Encabezado ────────────────────────────────────────────────
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _origenColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_origenIcon, color: _origenColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _origenLabel,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      deuda.numeroComprobante != null &&
                              deuda.numeroComprobante!.isNotEmpty
                          ? 'Comprobante ${deuda.numeroComprobante}'
                          : 'Comprobante #${deuda.origenId}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              StatusBadge(
                label: EstadosDeuda.getLabel(deuda.estado),
                color: esActiva ? Colors.orange : Colors.green,
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ── Montos ────────────────────────────────────────────────────
          Row(
            children: [
              _MontoChip(
                label: 'Total',
                value: 'S/ ${deuda.montoTotal}',
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              _MontoChip(
                label: 'Pagado',
                value: 'S/ ${pagado.toStringAsFixed(2)}',
                color: Colors.green,
              ),
              const SizedBox(width: 8),
              _MontoChip(
                label: 'Saldo',
                value: 'S/ ${deuda.saldo}',
                color: saldo > 0 ? Colors.red : Colors.green,
                highlighted: saldo > 0,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Barra de progreso ─────────────────────────────────────────
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progreso,
              minHeight: 6,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                progreso >= 1.0 ? Colors.green : const Color(0xFF2F3A8F),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${(progreso * 100).toStringAsFixed(0)}% pagado',
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),

          // ── Pagos previos ─────────────────────────────────────────────
          if (deuda.pagos.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.history, size: 13, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  '${deuda.pagos.length} pago(s) previo(s)',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ...deuda.pagos.map(
              (pago) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.circle,
                            size: 6, color: Colors.green),
                        const SizedBox(width: 6),
                        Text(
                          pago.fecha,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    Text(
                      'S/ ${pago.monto}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // ── Botón de pago ─────────────────────────────────────────────
          if (esActiva && onPayTap != null) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onPayTap,
                icon: const Icon(Icons.payments_outlined,
                    color: Colors.white, size: 18),
                label: const Text(
                  'Registrar Pago',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2F3A8F),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MontoChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool highlighted;

  const _MontoChip({
    required this.label,
    required this.value,
    required this.color,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: highlighted
              ? color.withValues(alpha: 0.08)
              : const Color(0xFFF8F9FC),
          borderRadius: BorderRadius.circular(10),
          border: highlighted
              ? Border.all(color: color.withValues(alpha: 0.25))
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: AppColors.textTertiary),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
