import 'package:management_system_ui/core/common_libs.dart';
import 'package:management_system_ui/features/auth/auth_provider.dart';

/// Header del flujo de venta con steps y progress bar
/// currentStep: 0 (Catálogo) → 1 (Carrito) → 2 (Resumen) → 3 (Comprobante)
class VentaFlowHeader extends ConsumerWidget {
  final int currentStep;
  final bool showTiendaHeader;
  final void Function(int)? onStepTap;

  const VentaFlowHeader({
    required this.currentStep,
    this.showTiendaHeader = true,
    this.onStepTap,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final userMe = auth.userMe;
    final tiendaId = auth.selectedTiendaId;

    String tiendaNombre = 'Tienda';
    if (userMe != null && tiendaId != null) {
      try {
        final tienda = userMe.tiendas.firstWhere((t) => t.tiendaId == tiendaId);
        tiendaNombre = tienda.tiendaNombre;
      } catch (_) {}
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
      color: const Color(0xFFF2F4F7),
      child: Column(
        children: [
          if (showTiendaHeader) ...[
            // Logo + nombre tienda
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2F3A8F),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.store_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  tiendaNombre,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],

          // Step indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStepIndicator(
                index: 0,
                currentIndex: currentStep,
                icon: Icons.storefront,
                label: 'Productos',
                onTap: onStepTap,
              ),
              _buildStepConnector(
                currentIndex: currentStep,
                stepIndex: 0,
              ),
              _buildStepIndicator(
                index: 1,
                currentIndex: currentStep,
                icon: Icons.shopping_cart,
                label: 'Carrito',
                onTap: onStepTap,
              ),
              _buildStepConnector(
                currentIndex: currentStep,
                stepIndex: 1,
              ),
              _buildStepIndicator(
                index: 2,
                currentIndex: currentStep,
                icon: Icons.receipt_long,
                label: 'Resumen',
                onTap: onStepTap,
              ),
              _buildStepConnector(
                currentIndex: currentStep,
                stepIndex: 2,
              ),
              _buildStepIndicator(
                index: 3,
                currentIndex: currentStep,
                icon: Icons.check_circle,
                label: 'Comprobante',
                onTap: onStepTap,
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (currentStep + 1) / 4,
              minHeight: 4,
              backgroundColor: const Color(0xFFE0E0E0),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF2F3A8F),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator({
    required int index,
    required int currentIndex,
    required IconData icon,
    required String label,
    void Function(int)? onTap,
  }) {
    final isCompleted = currentIndex > index;
    final isActive = currentIndex == index;
    final isClickable = isCompleted && onTap != null;

    final container = AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isCompleted || isActive
            ? const Color(0xFF2F3A8F)
            : const Color(0xFFE0E0E0),
      ),
      child: Center(
        child: isCompleted
            ? const Icon(Icons.check, color: Colors.white, size: 20)
            : Icon(
                icon,
                color: isActive ? Colors.white : Colors.grey,
                size: 20,
              ),
      ),
    );

    return Column(
      children: [
        if (isClickable)
          GestureDetector(
            onTap: () => onTap!(index),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: container,
            ),
          )
        else
          container,
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: isActive || isCompleted
                ? const Color(0xFF2F3A8F)
                : Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildStepConnector({
    required int currentIndex,
    required int stepIndex,
  }) {
    return Container(
      width: 48,
      height: 3,
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: currentIndex > stepIndex
            ? const Color(0xFF2F3A8F)
            : const Color(0xFFE0E0E0),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
