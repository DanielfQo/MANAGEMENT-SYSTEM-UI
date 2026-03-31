import 'package:intl/intl.dart';
import 'package:management_system_ui/core/common_libs.dart';
import 'package:management_system_ui/features/auth/auth_provider.dart';
import 'package:management_system_ui/features/servicio/models/servicio_read_model.dart';
import 'package:management_system_ui/features/servicio/servicio_provider.dart';
import 'package:management_system_ui/features/tienda/tienda_switcher_sheet.dart';
import 'package:management_system_ui/features/venta/constants/estado_sunat.dart';
import 'package:management_system_ui/features/venta/models/venta_read_model.dart';
import 'package:management_system_ui/features/venta/venta_provider.dart';

class OperacionesHubPage extends ConsumerStatefulWidget {
  const OperacionesHubPage({super.key});

  @override
  ConsumerState<OperacionesHubPage> createState() =>
      _OperacionesHubPageState();
}

class _OperacionesHubPageState extends ConsumerState<OperacionesHubPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _filtroTipo = 'todos'; // 'todos', 'ventas', 'servicios'

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text);
    });
    Future.microtask(() {
      ref.read(ventaProvider.notifier).cargarVentas();
      ref.read(servicioProvider.notifier).cargarServicios();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final esDueno = authState.userMe?.isDueno ?? false;
    final ventaState = ref.watch(ventaProvider);
    final servicioState = ref.watch(servicioProvider);

    // Construir lista unificada
    final items = <_OperacionItem>[];

    if (_filtroTipo == 'todos' || _filtroTipo == 'ventas') {
      for (final v in ventaState.ventas) {
        if (_matchesSearch(v.numeroComprobante)) {
          items.add(_OperacionItem.fromVenta(v));
        }
      }
    }

    if (_filtroTipo == 'todos' || _filtroTipo == 'servicios') {
      for (final s in servicioState.servicios) {
        if (_matchesSearch(s.numeroComprobante)) {
          items.add(_OperacionItem.fromServicio(s));
        }
      }
    }

    // Ordenar por fecha descendente
    items.sort((a, b) => b.fecha.compareTo(a.fecha));

    final isLoading = ventaState.isLoading || servicioState.isLoading;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      body: SafeArea(
        child: Column(
          children: [
            CustomAppBar(
              title: 'Operaciones',
              subtitle: 'Ventas y servicios',
              icon: Icons.point_of_sale,
              isTiendaTitle: esDueno,
              onTiendaPressed:
                  esDueno ? () => showTiendaSwitcher(context) : null,
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await Future.wait([
                    ref.read(ventaProvider.notifier).cargarVentas(),
                    ref.read(servicioProvider.notifier).cargarServicios(),
                  ]);
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Cards de acciones
                      _buildAccionCard(
                        icon: Icons.shopping_cart,
                        label: 'Nueva Venta',
                        subtitle: 'Iniciar una venta desde el catálogo',
                        color: const Color(0xFF2F3A8F),
                        onTap: () => context.go('/ventas'),
                      ),
                      const SizedBox(height: 12),
                      _buildAccionCard(
                        icon: Icons.build,
                        label: 'Nuevo Servicio',
                        subtitle: 'Registrar un servicio realizado',
                        color: const Color(0xFF00897B),
                        onTap: () => context.go('/servicios'),
                      ),
                      const SizedBox(height: 24),

                      // Historial
                      const Text(
                        'Historial de operaciones',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Buscador
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Buscar por número de comprobante...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () =>
                                      _searchController.clear(),
                                )
                              : null,
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 0, horizontal: 16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Filtro tabs
                      Row(
                        children: [
                          _buildFiltroChip('Todos', 'todos'),
                          const SizedBox(width: 8),
                          _buildFiltroChip('Ventas', 'ventas'),
                          const SizedBox(width: 8),
                          _buildFiltroChip('Servicios', 'servicios'),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Lista
                      if (isLoading && items.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (items.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.receipt_long_outlined,
                                  size: 48,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'No hay operaciones registradas',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ...items.map((item) => _OperacionCard(
                              item: item,
                              onTap: () => _mostrarDetalle(item),
                            )),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _matchesSearch(String numeroComprobante) {
    if (_searchQuery.isEmpty) return true;
    return numeroComprobante
        .toLowerCase()
        .contains(_searchQuery.toLowerCase());
  }

  Widget _buildAccionCard({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltroChip(String label, String value) {
    final isSelected = _filtroTipo == value;
    return GestureDetector(
      onTap: () => setState(() => _filtroTipo = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2F3A8F) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                isSelected ? const Color(0xFF2F3A8F) : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : Colors.grey[700],
          ),
        ),
      ),
    );
  }

  void _mostrarDetalle(_OperacionItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => item.esVenta
          ? _VentaDetalleSheet(venta: item.venta!)
          : _ServicioDetalleSheet(servicio: item.servicio!),
    );
  }
}

// ============================================================================
// Modelo unificado para la lista
// ============================================================================

class _OperacionItem {
  final bool esVenta;
  final String numeroComprobante;
  final String tipo;
  final String tipoDisplay;
  final double total;
  final String fecha;
  final String estadoSunat;
  final String? clienteNombre;
  final bool isActive;
  final VentaReadModel? venta;
  final ServicioReadModel? servicio;

  _OperacionItem({
    required this.esVenta,
    required this.numeroComprobante,
    required this.tipo,
    required this.tipoDisplay,
    required this.total,
    required this.fecha,
    required this.estadoSunat,
    this.clienteNombre,
    required this.isActive,
    this.venta,
    this.servicio,
  });

  factory _OperacionItem.fromVenta(VentaReadModel v) {
    return _OperacionItem(
      esVenta: true,
      numeroComprobante: v.numeroComprobante,
      tipo: v.tipo,
      tipoDisplay: v.tipoDisplay,
      total: v.total,
      fecha: v.fecha,
      estadoSunat: v.estadoSunat,
      clienteNombre: v.cliente?.nombre,
      isActive: v.isActive,
      venta: v,
    );
  }

  factory _OperacionItem.fromServicio(ServicioReadModel s) {
    return _OperacionItem(
      esVenta: false,
      numeroComprobante: s.numeroComprobante,
      tipo: s.tipo,
      tipoDisplay:
          s.tipoDisplay.isNotEmpty ? s.tipoDisplay : s.tipo,
      total: s.total,
      fecha: s.fecha,
      estadoSunat: s.estadoSunat,
      clienteNombre: s.cliente?.nombre,
      isActive: s.isActive,
      servicio: s,
    );
  }
}

// ============================================================================
// Card de operación en la lista
// ============================================================================

class _OperacionCard extends StatelessWidget {
  final _OperacionItem item;
  final VoidCallback onTap;

  const _OperacionCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    String fechaFormateada = '';
    try {
      final fecha = DateTime.parse(item.fecha);
      fechaFormateada = DateFormat('dd/MM/yyyy - HH:mm').format(fecha);
    } catch (_) {
      fechaFormateada = item.fecha;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: item.esVenta
              ? const Color(0xFF2F3A8F).withValues(alpha: 0.1)
              : const Color(0xFF00897B).withValues(alpha: 0.1),
          child: Icon(
            item.esVenta ? Icons.shopping_cart : Icons.build,
            color: item.esVenta
                ? const Color(0xFF2F3A8F)
                : const Color(0xFF00897B),
            size: 20,
          ),
        ),
        title: Text(
          '${item.esVenta ? "Venta" : "Servicio"} - ${item.tipoDisplay}',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              item.numeroComprobante,
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
            Text(
              fechaFormateada,
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            ),
            if (item.clienteNombre != null)
              Text(
                item.clienteNombre!,
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'S/. ${item.total.toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 4),
            _EstadoBadge(estado: item.estadoSunat),
          ],
        ),
      ),
    );
  }
}

class _EstadoBadge extends StatelessWidget {
  final String estado;
  const _EstadoBadge({required this.estado});

  @override
  Widget build(BuildContext context) {
    final color = EstadoSUNAT.getColor(estado);
    final label = EstadoSUNAT.getLabel(estado);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// ============================================================================
// Detalle Sheet - Venta
// ============================================================================

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
    final esHoy = _esHoy(fecha);
    final esSunatAceptado = venta.estadoSunat == 'ACEPTADO';

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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            venta.numeroComprobante,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (!venta.isActive)
                            Container(
                              margin: const EdgeInsets.only(top: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.red[100],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Anulada',
                                style: TextStyle(
                                  color: Colors.red[700],
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    _EstadoBadge(estado: venta.estadoSunat),
                  ],
                ),
                const SizedBox(height: 16),
                _InfoRow('Total:', 'S/. ${venta.total.toStringAsFixed(2)}'),
                _InfoRow('Fecha:', fechaFormateada),
                _InfoRow('Tipo:', venta.tipoDisplay),
                _InfoRow('Método Pago:', venta.metodoPagoDisplay),
                _InfoRow('Atendido por:', venta.usuarioTienda.nombre),
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
                      double.tryParse(item.subtotal) ?? 0;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(item.productoNombre),
                    subtitle:
                        Text('${item.cantidad} ${item.unidadMedida}'),
                    trailing: Text(
                      'S/. ${subtotal.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold),
                    ),
                  );
                }),
                const SizedBox(height: 24),
                if (venta.isActive)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (puedeCancelar)
                        ElevatedButton(
                          onPressed: () =>
                              _confirmarCancelar(context, ref),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red),
                          child: const Text('Cancelar venta'),
                        ),
                      if (puedeAnular) ...[
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () =>
                              _mostrarDialogoAnular(context, ref),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange),
                          child: const Text('Anular venta'),
                        ),
                      ],
                      if (puedeNotaCredito) ...[
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () =>
                              _confirmarNotaCredito(context, ref),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue),
                          child: const Text('Nota de crédito'),
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
              ref
                  .read(ventaProvider.notifier)
                  .cancelarVenta(venta.numeroComprobante);
              Navigator.pop(context);
              Navigator.pop(context);
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
                    DropdownMenuItem(
                        value: '01',
                        child: Text('01 - Anulación por error en RUC')),
                    DropdownMenuItem(
                        value: '06',
                        child:
                            Text('06 - Devolución total de bienes')),
                    DropdownMenuItem(
                        value: '07',
                        child: Text('07 - Devolución por ítem')),
                    DropdownMenuItem(
                        value: '09',
                        child: Text('09 - Disminución de valor')),
                  ],
                  onChanged: (value) =>
                      setState(() => codigoSeleccionado = value),
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
            onPressed: codigoSeleccionado != null &&
                    motivoController.text.isNotEmpty
                ? () {
                    ref.read(ventaProvider.notifier).anularVenta(
                          venta.numeroComprobante,
                          codigoTipo: codigoSeleccionado!,
                          motivo: motivoController.text,
                        );
                    Navigator.pop(context);
                    Navigator.pop(context);
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
        content: const Text(
            '¿Deseas emitir una nota de crédito para esta venta?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () {
              ref
                  .read(ventaProvider.notifier)
                  .emitirNotaCredito(venta.numeroComprobante);
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Emitir'),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Detalle Sheet - Servicio
// ============================================================================

class _ServicioDetalleSheet extends ConsumerWidget {
  final ServicioReadModel servicio;
  const _ServicioDetalleSheet({required this.servicio});

  bool _esHoy(DateTime fecha) {
    final hoy = DateTime.now();
    return fecha.year == hoy.year &&
        fecha.month == hoy.month &&
        fecha.day == hoy.day;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fecha = DateTime.parse(servicio.fecha);
    final fechaFormateada =
        DateFormat('dd/MM/yyyy - HH:mm:ss').format(fecha);
    final esHoy = _esHoy(fecha);
    final esSunatAceptado = servicio.estadoSunat == 'ACEPTADO';

    final puedeCancelar = servicio.isActive &&
        servicio.estadoSunat != 'ACEPTADO' &&
        servicio.estadoSunat != 'ANULADO';
    final puedeAnular = servicio.isActive && esSunatAceptado && esHoy;
    final puedeNotaCredito =
        servicio.isActive && esSunatAceptado && !esHoy;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            servicio.numeroComprobante,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (!servicio.isActive)
                            Container(
                              margin: const EdgeInsets.only(top: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.red[100],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Anulado',
                                style: TextStyle(
                                  color: Colors.red[700],
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    _EstadoBadge(estado: servicio.estadoSunat),
                  ],
                ),
                const SizedBox(height: 16),
                _InfoRow(
                    'Total:', 'S/. ${servicio.total.toStringAsFixed(2)}'),
                _InfoRow('Fecha:', fechaFormateada),
                _InfoRow(
                  'Tipo:',
                  servicio.tipoDisplay.isNotEmpty
                      ? servicio.tipoDisplay
                      : servicio.tipo,
                ),
                _InfoRow(
                  'Método Pago:',
                  servicio.metodoPagoDisplay.isNotEmpty
                      ? servicio.metodoPagoDisplay
                      : servicio.metodoPago,
                ),
                _InfoRow('Atendido por:', servicio.usuarioTienda.nombre),
                if (servicio.cliente != null)
                  _InfoRow('Cliente:', servicio.cliente!.nombre),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                const Text(
                  'Detalle del servicio',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                if (servicio.descripcion.isNotEmpty) ...[
                  Text(
                    servicio.descripcion,
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                ],
                _InfoRow('Fecha inicio:', servicio.fechaInicio),
                _InfoRow('Fecha fin:', servicio.fechaFin),
                const SizedBox(height: 24),
                if (servicio.isActive)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (puedeCancelar)
                        ElevatedButton(
                          onPressed: () =>
                              _confirmarEliminar(context, ref),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red),
                          child: const Text('Eliminar servicio'),
                        ),
                      if (puedeAnular) ...[
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () =>
                              _mostrarDialogoAnular(context, ref),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange),
                          child: const Text('Anular servicio'),
                        ),
                      ],
                      if (puedeNotaCredito) ...[
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () =>
                              _confirmarNotaCredito(context, ref),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue),
                          child: const Text('Nota de crédito'),
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

  void _confirmarEliminar(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar servicio'),
        content:
            const Text('¿Estás seguro de eliminar este servicio?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () {
              ref
                  .read(servicioProvider.notifier)
                  .eliminarServicio(servicio.numeroComprobante);
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoAnular(BuildContext context, WidgetRef ref) {
    final motivoController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Anular servicio'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Motivo de anulación:'),
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
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (motivoController.text.isNotEmpty) {
                ref.read(servicioProvider.notifier).anularServicio(
                      servicio.numeroComprobante,
                      motivo: motivoController.text,
                    );
                Navigator.pop(context);
                Navigator.pop(context);
              }
            },
            child: const Text('Anular'),
          ),
        ],
      ),
    );
  }

  void _confirmarNotaCredito(BuildContext context, WidgetRef ref) {
    final motivoController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Emitir nota de crédito'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () {
              if (motivoController.text.isNotEmpty) {
                ref.read(servicioProvider.notifier).emitirNotaCredito(
                      servicio.numeroComprobante,
                      motivo: motivoController.text,
                    );
                Navigator.pop(context);
                Navigator.pop(context);
              }
            },
            child: const Text('Emitir'),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Helper widgets
// ============================================================================

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
