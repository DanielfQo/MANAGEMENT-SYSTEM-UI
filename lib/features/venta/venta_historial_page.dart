import 'package:management_system_ui/core/common_libs.dart';
import 'package:intl/intl.dart';
import 'package:management_system_ui/features/venta/constants/estado_sunat.dart';
import 'package:management_system_ui/features/venta/models/venta_read_model.dart';
import 'package:management_system_ui/features/venta/venta_provider.dart';

class VentaHistorialPage extends ConsumerStatefulWidget {
  const VentaHistorialPage({super.key});

  @override
  ConsumerState<VentaHistorialPage> createState() =>
      _VentaHistorialPageState();
}

class _VentaHistorialPageState extends ConsumerState<VentaHistorialPage> {
  String? filtroTipo;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim());
    });
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

    final ventasFiltradas = _searchQuery.isEmpty
        ? ventaState.ventas
        : ventaState.ventas
            .where((v) => v.numeroComprobante
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()))
            .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Ventas'),
        centerTitle: true,
        actions: [
          if (ventaState.ventas.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Badge(
                  label: Text('${ventaState.ventas.length}'),
                  child: const Icon(Icons.list),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Buscador por número de comprobante
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
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
                fillColor: Colors.grey[100],
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
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
                _searchController.clear();
                return ref
                    .read(ventaProvider.notifier)
                    .cargarVentas(tipo: filtroTipo);
              },
              child: ventaState.isLoading && ventaState.ventas.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : ventaState.errorMessage != null &&
                          ventaState.ventas.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline,
                                  size: 48, color: Colors.grey),
                              const SizedBox(height: 16),
                              Text(ventaState.errorMessage!),
                              const SizedBox(height: 24),
                              ElevatedButton(
                                onPressed: () => ref
                                    .read(ventaProvider.notifier)
                                    .cargarVentas(),
                                child: const Text('Reintentar'),
                              ),
                            ],
                          ),
                        )
                      : ventasFiltradas.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.receipt_long_outlined,
                                      size: 48, color: Colors.grey),
                                  const SizedBox(height: 16),
                                  Text(
                                    _searchQuery.isNotEmpty
                                        ? 'No se encontró el comprobante "$_searchQuery"'
                                        : 'No hay ventas registradas',
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: ventasFiltradas.length,
                              itemBuilder: (context, index) {
                                final venta = ventasFiltradas[index];
                                return _VentaCard(
                                  venta: venta,
                                  onTap: () {
                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      builder: (_) =>
                                          _VentaDetalleSheet(venta: venta),
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

  const _VentaCard({required this.venta, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final fecha = DateTime.parse(venta.fecha);
    final fechaFormateada = DateFormat('dd/MM/yyyy - HH:mm').format(fecha);

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
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _EstadoSunatBadge(estado: venta.estadoSunat),
          ],
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fecha = DateTime.parse(venta.fecha);
    final fechaFormateada =
        DateFormat('dd/MM/yyyy - HH:mm:ss').format(fecha);
    final ventaState = ref.watch(ventaProvider);

    // Determinar acciones disponibles
    final esHoy = _esHoy(fecha);
    final esSunatAceptado = venta.estadoSunat == 'ACEPTADO';
    final puedeAnular = venta.isActive && esSunatAceptado && esHoy;
    final puedeNotaCredito = venta.isActive && esSunatAceptado && !esHoy;
    final puedeCancelar = venta.isActive &&
        venta.estadoSunat != 'ACEPTADO' &&
        venta.estadoSunat != 'ANULADO';

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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Venta #${venta.id}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        if (!venta.isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.red[100],
                              border: Border.all(color: Colors.red),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Anulada',
                              style: TextStyle(
                                color: Colors.red[700],
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        if (!venta.isActive) const SizedBox(width: 6),
                        _EstadoSunatBadge(estado: venta.estadoSunat),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Información general
                _InfoRow('Total:',
                    'S/. ${venta.total.toStringAsFixed(2)}'),
                _InfoRow('Fecha:', fechaFormateada),
                _InfoRow('Tipo:', venta.tipoDisplay),
                _InfoRow('Método de Pago:', venta.metodoPagoDisplay),
                _InfoRow('Comprobante:', venta.tipoComprobanteDisplay),
                _InfoRow('Número:', venta.numeroComprobante),
                _InfoRow('Atendido por:', venta.usuarioTienda.nombre),

                if (venta.cliente != null) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  const Text(
                    'Cliente',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  _InfoRow('Nombre:', venta.cliente!.nombre),
                  _InfoRow(
                    'Documento:',
                    '${venta.cliente!.tipoDocumentoDisplay} - ${venta.cliente!.numeroDocumento}',
                  ),
                  _InfoRow('Teléfono:', venta.cliente!.telefono),
                  if (venta.cliente!.email != null)
                    _InfoRow('Email:', venta.cliente!.email!),
                  _InfoRow('Dirección:', venta.cliente!.direccion),
                ],

                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                const Text(
                  'Productos',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 12),

                ...venta.detalle.map((item) {
                  final subtotal =
                      (double.tryParse(item.subtotal) ?? 0);
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(item.productoNombre),
                    subtitle: Text(
                        '${item.cantidad} ${item.unidadMedida}'),
                    trailing: Text(
                      'S/. ${subtotal.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold),
                    ),
                  );
                }),

                if (venta.notaCredito != null) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  const Text(
                    'Nota de Crédito',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  _InfoRow(
                      'Número:', venta.notaCredito!.numeroComprobante),
                  _InfoRow('Motivo:', venta.notaCredito!.motivo),
                  _InfoRow('Fecha:', venta.notaCredito!.fecha),
                ],

                // Sección de acciones
                if (puedeCancelar || puedeAnular || puedeNotaCredito) ...[
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 8),
                  const Text(
                    'Acciones',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 12),

                  if (ventaState.isSaving)
                    const Center(child: CircularProgressIndicator()),

                  if (!ventaState.isSaving) ...[
                    if (puedeCancelar)
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.cancel_outlined),
                          label: const Text('Cancelar venta'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(
                                vertical: 12),
                          ),
                          onPressed: () => _confirmarCancelar(
                              context, ref),
                        ),
                      ),

                    if (puedeAnular)
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.block),
                          label: const Text('Anular venta'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(
                                vertical: 12),
                          ),
                          onPressed: () =>
                              _mostrarDialogoAnular(context, ref),
                        ),
                      ),

                    if (puedeNotaCredito)
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          icon: const Icon(
                              Icons.receipt_long_outlined),
                          label:
                              const Text('Emitir nota de crédito'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.orange[700],
                            side: BorderSide(
                                color: Colors.orange[700]!),
                            padding: const EdgeInsets.symmetric(
                                vertical: 12),
                          ),
                          onPressed: () =>
                              _confirmarNotaCredito(context, ref),
                        ),
                      ),
                  ],
                ],

                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmarCancelar(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar venta'),
        content: Text(
            '¿Confirmas la cancelación de la venta ${venta.numeroComprobante}? '
            'Se revertirá el stock de los productos.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('No'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref
                  .read(ventaProvider.notifier)
                  .cancelarVenta(venta.numeroComprobante);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoAnular(BuildContext context, WidgetRef ref) {
    const codigos = {
      '01': 'Anulación de la operación',
      '06': 'Devolución total',
      '07': 'Devolución por ítem',
      '09': 'Disminución en el valor',
    };

    String codigoSeleccionado = '01';
    final motivoController =
        TextEditingController(text: 'Anulación de operación');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Anular venta SUNAT'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Motivo de anulación',
                style: TextStyle(
                    fontWeight: FontWeight.w500, fontSize: 13),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: codigoSeleccionado,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  isDense: true,
                ),
                items: codigos.entries
                    .map((e) => DropdownMenuItem(
                          value: e.key,
                          child: Text(
                            '${e.key} - ${e.value}',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ))
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      codigoSeleccionado = val;
                      motivoController.text = codigos[val]!;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              const Text(
                'Descripción',
                style: TextStyle(
                    fontWeight: FontWeight.w500, fontSize: 13),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: motivoController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  isDense: true,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white),
              onPressed: () async {
                final motivo = motivoController.text.trim();
                if (motivo.isEmpty) return;
                Navigator.pop(ctx);
                await ref
                    .read(ventaProvider.notifier)
                    .anularVenta(
                      venta.numeroComprobante,
                      codigoTipo: codigoSeleccionado,
                      motivo: motivo,
                    );
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Confirmar anulación'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmarNotaCredito(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nota de crédito'),
        content: Text(
            '¿Emitir nota de crédito para la venta ${venta.numeroComprobante}? '
            'Se anulará el comprobante ante SUNAT.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('No'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[700],
                foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref
                  .read(ventaProvider.notifier)
                  .emitirNotaCredito(venta.numeroComprobante);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Sí, emitir'),
          ),
        ],
      ),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
