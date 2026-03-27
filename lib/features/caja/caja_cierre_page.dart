import 'package:management_system_ui/core/common_libs.dart';
import 'package:intl/intl.dart';
import 'package:management_system_ui/features/venta/venta_provider.dart';

class CajaCierrePage extends ConsumerStatefulWidget {
  const CajaCierrePage({super.key});

  @override
  ConsumerState<CajaCierrePage> createState() =>
      _CajaClosurePageState();
}

class _CajaClosurePageState extends ConsumerState<CajaCierrePage> {
  final efectivoController = TextEditingController();
  final notasController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(ventaProvider.notifier).cargarVentas();
    });
  }

  @override
  void dispose() {
    efectivoController.dispose();
    notasController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ventaState = ref.watch(ventaProvider);

    // Calcular total de sistema
    double totalSistema = 0;
    for (final venta in ventaState.ventas) {
      totalSistema += venta.total;
    }

    final efectivoIngresado =
        double.tryParse(efectivoController.text) ?? 0;
    final diferencia =
        efectivoIngresado - totalSistema;

    final ahora = DateTime.now();
    final fechaFormato =
        DateFormat('dd/MM/yyyy - HH:mm')
            .format(ahora);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cierre de Caja'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/caja'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            // Información
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hora: $fechaFormato',
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

            // Total del sistema
            const Text(
              'Información del Sistema',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                border: Border.all(
                  color: Colors.blue,
                ),
                borderRadius:
                    BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total en Sistema:',
                    style: TextStyle(
                      color: Colors.blue[900],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'S/. ${totalSistema.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[900],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '(${ventaState.ventas.length} ventas registradas)',
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Ingreso de efectivo real
            const Text(
              'Registro de Cierre',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: efectivoController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText:
                    'Efectivo Contado en Caja',
                hintText: '0.00',
                border: const OutlineInputBorder(),
                prefixText: 'S/. ',
                suffixIcon: IconButton(
                  icon: const Icon(
                    Icons.clear,
                  ),
                  onPressed: () {
                    efectivoController.clear();
                  },
                ),
              ),
              onChanged: (_) {
                setState(() {});
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: notasController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText:
                    'Notas (opcional)',
                hintText:
                    'Ej: falta de cambio, '
                    'retirada de efectivo...',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            // Resumen de diferencia
            if (efectivoController.text.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: diferencia == 0
                      ? Colors.green[50]
                      : diferencia > 0
                          ? Colors.blue[50]
                          : Colors.red[50],
                  border: Border.all(
                    color: diferencia == 0
                        ? Colors.green
                        : diferencia > 0
                            ? Colors.blue
                            : Colors.red,
                  ),
                  borderRadius:
                      BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Resumen:',
                      style: TextStyle(
                        color: diferencia == 0
                            ? Colors.green[900]
                            : diferencia > 0
                                ? Colors.blue[900]
                                : Colors.red[900],
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment
                              .spaceBetween,
                      children: [
                        const Text('Esperado:'),
                        Text(
                          'S/. ${totalSistema.toStringAsFixed(2)}',
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment
                              .spaceBetween,
                      children: [
                        const Text('Contado:'),
                        Text(
                          'S/. ${efectivoIngresado.toStringAsFixed(2)}',
                        ),
                      ],
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment
                              .spaceBetween,
                      children: [
                        Text(
                          'Diferencia:',
                          style: TextStyle(
                            fontWeight:
                                FontWeight.bold,
                            color: diferencia == 0
                                ? Colors
                                    .green[900]
                                : diferencia > 0
                                    ? Colors
                                        .blue[900]
                                    : Colors
                                        .red[900],
                          ),
                        ),
                        Text(
                          'S/. ${diferencia.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight:
                                FontWeight.bold,
                            color: diferencia == 0
                                ? Colors.green
                                : diferencia > 0
                                    ? Colors.blue
                                    : Colors.red,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 32),

            // Botón confirmar cierre
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.check_circle),
                label: const Text('Confirmar Cierre'),
                onPressed:
                    efectivoController
                            .text.isEmpty
                        ? null
                        : () {
                            _confirmarCierre(
                              context,
                              totalSistema,
                              efectivoIngresado,
                              notasController
                                  .text,
                            );
                          },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmarCierre(
    BuildContext context,
    double totalSistema,
    double efectivoIngresado,
    String notas,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirmar Cierre'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              'Total Sistema: S/. ${totalSistema.toStringAsFixed(2)}',
            ),
            Text(
              'Efectivo Contado: S/. ${efectivoIngresado.toStringAsFixed(2)}',
            ),
            Text(
              'Diferencia: S/. ${(efectivoIngresado - totalSistema).toStringAsFixed(2)}',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              ScaffoldMessenger.of(context)
                  .showSnackBar(
                const SnackBar(
                  content: Text(
                    'Cierre de caja registrado exitosamente',
                  ),
                ),
              );
              context.go('/caja');
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }
}
