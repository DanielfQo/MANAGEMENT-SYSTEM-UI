import 'package:management_system_ui/core/common_libs.dart';
import 'package:management_system_ui/core/router.dart';
import 'package:management_system_ui/features/auth/auth_provider.dart';
import 'finanzas_provider.dart';


class CajaCierrePage extends ConsumerStatefulWidget {
  const CajaCierrePage({super.key});

  @override
  ConsumerState<CajaCierrePage> createState() => _CajaCierrePageState();
}

class _CajaCierrePageState extends ConsumerState<CajaCierrePage> {
  late TextEditingController _montoRealController;
  late TextEditingController _observacionesController;

  @override
  void initState() {
    super.initState();
    _montoRealController = TextEditingController();
    _observacionesController = TextEditingController();

    Future.microtask(
      () => ref.read(finanzasProvider.notifier).cargarCajaResumen(),
    );
  }

  @override
  void dispose() {
    _montoRealController.dispose();
    _observacionesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(finanzasProvider);
    final authState = ref.watch(authProvider);

    ref.listen(authProvider, (previous, next) {
      if (previous?.selectedTiendaId != next.selectedTiendaId) {
        ref.read(finanzasProvider.notifier).cargarCajaResumen();
      }
    });

    ref.listen(finanzasProvider, (previous, next) {
      if (!mounted) return;
      if (next.successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.successMessage!)),
        );
        ref.read(finanzasProvider.notifier).clearMessages();
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted && context.mounted) context.go(AppRoutes.finanzas);
        });
      }
      if (next.errorMessage != null && (previous?.errorMessage ?? '') != next.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: Colors.red,
          ),
        );
      }
    });

    final montoEsperado =
        double.tryParse(state.cajaResumen?.totalGeneral ?? '0') ?? 0;
    final montoReal = double.tryParse(_montoRealController.text) ?? 0;
    final diferencia = montoReal - montoEsperado;
    final colorDiferencia = diferencia == 0
        ? Colors.green
        : diferencia > 0
            ? Colors.orange
            : Colors.red;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      body: SafeArea(
        child: Column(
          children: [
            CustomAppBar(
              title: 'Cerrar Caja',
              subtitle: 'Cierre del día',
              icon: Icons.lock_outline,
              isTiendaTitle: true,
              onBack: () => context.go(AppRoutes.finanzasCajaResumen),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Monto Esperado (Sistema)',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'S/ ${montoEsperado.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _montoRealController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Monto Real Contado',
                        hintText: '0.00',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixText: 'S/ ',
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _observacionesController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: 'Observaciones (Opcional)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        hintText: 'Ej: Diferencia por billetes rotos',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: colorDiferencia.withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Diferencia',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'S/ ${diferencia.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: colorDiferencia,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            diferencia == 0
                                ? 'Cuadra correctamente'
                                : diferencia > 0
                                    ? 'Sobra efectivo'
                                    : 'Falta efectivo',
                            style: TextStyle(
                              fontSize: 12,
                              color: colorDiferencia,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: state.isSaving
                            ? null
                            : () => _cerrarCaja(
                                  authState.selectedTiendaId ?? 0,
                                  _montoRealController.text,
                                  _observacionesController.text,
                                ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1F2A7C),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          disabledBackgroundColor: Colors.grey,
                        ),
                        child: state.isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text(
                                'Confirmar Cierre',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
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

  void _cerrarCaja(int tiendaId, String monto, String observaciones) {
    if (monto.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor ingresa el monto'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    ref.read(finanzasProvider.notifier).cerrarCaja(
          tiendaId: tiendaId,
          montoReal: monto,
          observaciones: observaciones,
        );
  }
}
