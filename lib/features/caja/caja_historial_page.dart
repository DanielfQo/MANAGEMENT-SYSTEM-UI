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
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {
          _searchQuery = _searchController.text;
        }));
    Future.microtask(() {
      ref.read(ventaProvider.notifier).cargarVentas();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ventaState = ref.watch(ventaProvider);

    // Filtrar ventas por número de comprobante
    final ventasFiltradas = ventaState.ventas
        .where((v) => _searchQuery.isEmpty ||
            v.numeroComprobante
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Ventas'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/caja'),
        ),
      ),
      body: Column(
        children: [
          // Buscador de comprobante
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por número de comprobante...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
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
                      : ventasFiltradas.isEmpty
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
                                    'No hay ventas registradas',
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding:
                                  const EdgeInsets.all(16),
                              itemCount:
                                  ventasFiltradas.length,
                              itemBuilder: (context, index) {
                                final venta =
                                    ventasFiltradas[index];
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
          ),
        ],
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

class _VentaDetalleSheet extends ConsumerWidget {
  final VentaReadModel venta;

  const _VentaDetalleSheet({required this.venta});

  bool _esHoy(DateTime fecha) {
    final hoy = DateTime.now();
    return fecha.year == hoy.year &&
        fecha.month == hoy.month &&
        fecha.day == hoy.day;
  }

  void _confirmarCancelar(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar venta'),
        content: const Text('¿Estás seguro de cancelar esta venta?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(ventaProvider.notifier).cancelarVenta(venta.numeroComprobante);
              Navigator.pop(context);
              Navigator.pop(context); // Cierra el sheet
            },
            child: const Text('Cancelar venta'),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoAnular(BuildContext context, WidgetRef ref) {
    String? codigoSeleccionado;
    final motivoController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Anular venta'),
        content: StatefulBuilder(
          builder: (context, setState) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Selecciona el código de anulación:'),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: codigoSeleccionado,
                  decoration: const InputDecoration(
                    hintText: 'Selecciona un código',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: '01', child: Text('01 - Anulación por error en RUC')),
                    DropdownMenuItem(value: '06', child: Text('06 - Devolución total de bienes')),
                    DropdownMenuItem(value: '07', child: Text('07 - Devolución por ítem')),
                    DropdownMenuItem(value: '09', child: Text('09 - Disminución de valor')),
                  ],
                  onChanged: (value) => setState(() => codigoSeleccionado = value),
                ),
                const SizedBox(height: 16),
                const Text('Motivo:'),
                const SizedBox(height: 8),
                TextField(
                  controller: motivoController,
                  decoration: const InputDecoration(
                    hintText: 'Escribe el motivo...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: codigoSeleccionado != null && motivoController.text.isNotEmpty
                ? () {
                    ref.read(ventaProvider.notifier).anularVenta(
                      venta.numeroComprobante,
                      codigoTipo: codigoSeleccionado!,
                      motivo: motivoController.text,
                    );
                    Navigator.pop(context);
                    Navigator.pop(context); // Cierra el sheet
                  }
                : null,
            child: const Text('Anular'),
          ),
        ],
      ),
    );
  }

  void _confirmarNotaCredito(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Emitir nota de crédito'),
        content: const Text('¿Deseas emitir una nota de crédito para esta venta?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(ventaProvider.notifier).emitirNotaCredito(venta.numeroComprobante);
              Navigator.pop(context);
              Navigator.pop(context); // Cierra el sheet
            },
            child: const Text('Emitir'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fecha = DateTime.parse(venta.fecha);
    final fechaFormateada =
        DateFormat('dd/MM/yyyy - HH:mm:ss')
            .format(fecha);
    final esHoy = _esHoy(fecha);
    final esSunatAceptado = venta.estadoSunat == 'ACEPTADO';

    // Lógica para mostrar botones
    final puedeCancelar = venta.isActive &&
        venta.estadoSunat != 'ACEPTADO' &&
        venta.estadoSunat != 'ANULADO';
    final puedeAnular = venta.isActive && esSunatAceptado && esHoy;
    final puedeNotaCredito = venta.isActive && esSunatAceptado && !esHoy;

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
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            venta.numeroComprobante,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                          if (!venta.isActive)
                            Container(
                              margin: const EdgeInsets.only(top: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red[100],
                                borderRadius:
                                    BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Anulada',
                                style: TextStyle(
                                  color: Colors.red[700],
                                  fontSize: 12,
                                  fontWeight:
                                      FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
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
                // Botones de acción
                if (venta.isActive)
                  Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.stretch,
                    children: [
                      if (puedeCancelar)
                        ElevatedButton(
                          onPressed: () =>
                              _confirmarCancelar(
                                  context, ref),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          child: const Text('Cancelar venta'),
                        ),
                      if (puedeAnular) ...[
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () =>
                              _mostrarDialogoAnular(
                                  context, ref),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                          ),
                          child: const Text('Anular venta'),
                        ),
                      ],
                      if (puedeNotaCredito) ...[
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () =>
                              _confirmarNotaCredito(
                                  context, ref),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                          ),
                          child:
                              const Text('Nota de crédito'),
                        ),
                      ],
                    ],
                  ),
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
