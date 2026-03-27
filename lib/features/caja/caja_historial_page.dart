import 'package:management_system_ui/core/common_libs.dart';
import 'package:intl/intl.dart';
import 'package:management_system_ui/features/venta/constants/estado_sunat.dart';
import 'package:management_system_ui/features/venta/models/venta_read_model.dart';
import 'package:management_system_ui/features/venta/venta_provider.dart';

class CajaHistorialPage extends ConsumerStatefulWidget {
  const CajaHistorialPage({super.key});

  @override
  ConsumerState<CajaHistorialPage> createState() =>
      _CajaHistorialPageState();
}

class _CajaHistorialPageState
    extends ConsumerState<CajaHistorialPage> {
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Ventas'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/caja'),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          return ref
              .read(ventaProvider.notifier)
              .cargarVentas();
        },
        child: ventaState.isLoading &&
                ventaState.ventas.isEmpty
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : ventaState.errorMessage != null &&
                    ventaState.ventas.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(ventaState.errorMessage!),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () {
                            ref
                                .read(ventaProvider
                                    .notifier)
                                .cargarVentas();
                          },
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  )
                : ventaState.ventas.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.receipt_long_outlined,
                              size: 48,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No hay ventas registradas hoy',
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding:
                            const EdgeInsets.all(16),
                        itemCount:
                            ventaState.ventas.length,
                        itemBuilder: (context, index) {
                          final venta =
                              ventaState.ventas[index];
                          return _VentaCard(
                            venta: venta,
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled:
                                    true,
                                builder: (_) =>
                                    _VentaDetalleSheet(
                                      venta: venta,
                                    ),
                              );
                            },
                          );
                        },
                      ),
      ),
    );
  }
}

class _VentaCard extends StatelessWidget {
  final VentaReadModel venta;
  final VoidCallback onTap;

  const _VentaCard({
    required this.venta,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fecha = DateTime.parse(venta.fecha);
    final fechaFormateada =
        DateFormat('dd/MM/yyyy - HH:mm').format(fecha);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        title: Text(
          'Venta #${venta.id} - ${venta.tipoDisplay} - S/. ${venta.total.toStringAsFixed(2)}',
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(fechaFormateada),
            if (venta.cliente != null)
              Text('Cliente: ${venta.cliente!.nombre}'),
          ],
        ),
        trailing: _EstadoSunatBadge(
          estado: venta.estadoSunat,
        ),
      ),
    );
  }
}

class _EstadoSunatBadge extends StatelessWidget {
  final String estado;

  const _EstadoSunatBadge({required this.estado});

  @override
  Widget build(BuildContext context) {
    final color = EstadoSUNAT.getColor(estado);
    final label = EstadoSUNAT.getLabel(estado);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _VentaDetalleSheet extends StatelessWidget {
  final VentaReadModel venta;

  const _VentaDetalleSheet({required this.venta});

  @override
  Widget build(BuildContext context) {
    final fecha = DateTime.parse(venta.fecha);
    final fechaFormateada =
        DateFormat('dd/MM/yyyy - HH:mm:ss')
            .format(fecha);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment
                          .spaceBetween,
                  children: [
                    Text(
                      'Venta #${venta.id}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    _EstadoSunatBadge(
                      estado: venta.estadoSunat,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _InfoRow('Total:',
                    'S/. ${venta.total.toStringAsFixed(2)}'),
                _InfoRow('Fecha:', fechaFormateada),
                _InfoRow(
                  'Tipo:',
                  venta.tipoDisplay,
                ),
                _InfoRow(
                  'Método Pago:',
                  venta.metodoPagoDisplay,
                ),
                _InfoRow(
                  'Atendido por:',
                  venta.usuarioTienda.nombre,
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                const Text(
                  'Productos',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                ...venta.detalle.map((item) {
                  final subtotal =
                      (double.tryParse(
                              item.subtotal) ??
                          0);
                  return ListTile(
                    contentPadding:
                        EdgeInsets.zero,
                    title: Text(
                      item.productoNombre,
                    ),
                    subtitle: Text(
                      '${item.cantidad} ${item.unidadMedida}',
                    ),
                    trailing: Text(
                      'S/. ${subtotal.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
