import 'dart:async';
import 'package:intl/intl.dart';
import 'package:management_system_ui/core/common_libs.dart';
import 'package:management_system_ui/features/auth/auth_provider.dart';
import 'package:management_system_ui/features/servicio/models/servicio_read_model.dart';
import 'package:management_system_ui/features/servicio/servicio_repository.dart';
import 'package:management_system_ui/features/tienda/tienda_switcher_sheet.dart';
import 'package:management_system_ui/features/venta/constants/estado_sunat.dart';
import 'package:management_system_ui/features/venta/models/venta_read_model.dart';
import 'package:management_system_ui/features/venta/venta_provider.dart';
import 'package:management_system_ui/features/venta/venta_repository.dart';

class OperacionesHistorialPage extends ConsumerStatefulWidget {
  const OperacionesHistorialPage({super.key});

  @override
  ConsumerState<OperacionesHistorialPage> createState() =>
      _OperacionesHistorialPageState();
}

class _OperacionesHistorialPageState
    extends ConsumerState<OperacionesHistorialPage> {
  // Estado local
  List<_OperacionItem> _items = [];
  String? _nextVentasCursor;
  String? _nextServiciosCursor;
  bool _hasMoreVentas = false;
  bool _hasMoreServicios = false;
  bool _isLoading = true;
  bool _isLoadingMore = false;

  // Filtros
  String _filtroTipo = 'todos'; // 'todos' | 'ventas' | 'servicios'
  String _fechaFiltro = '';
  bool _usaRango = false;
  String? _fechaDesde, _fechaHasta;

  // Controllers
  Timer? _debounce;
  late ScrollController _scrollController;
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _searchController = TextEditingController();
    _scrollController.addListener(_onScroll);
    _fechaFiltro = _hoy();
    _cargarInicial();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  String _hoy() {
    return DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  String _ayer() {
    return DateFormat('yyyy-MM-dd')
        .format(DateTime.now().subtract(const Duration(days: 1)));
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _cargarMas();
    }
  }

  void _onSearch(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _cargarInicial();
    });
  }

  Future<void> _cargarInicial() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _items = [];
      _nextVentasCursor = null;
      _nextServiciosCursor = null;
    });

    final tiendaId = ref.read(authProvider).selectedTiendaId;
    if (tiendaId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    final search = _searchController.text.isNotEmpty
        ? _searchController.text
        : null;
    final fecha = _usaRango ? null : _fechaFiltro;
    final desde = _usaRango ? _fechaDesde : null;
    final hasta = _usaRango ? _fechaHasta : null;

    try {
      List<_OperacionItem> ventas = [];
      List<_OperacionItem> servicios = [];
      String? nextV, nextS;
      bool hasMoreV = false, hasMoreS = false;

      if (_filtroTipo != 'servicios') {
        final result =
            await ref.read(ventaRepositoryProvider).getVentas(
              tiendaId: tiendaId,
              fecha: fecha,
              fechaDesde: desde,
              fechaHasta: hasta,
              search: search,
            );
        ventas = result.items.map(_OperacionItem.fromVenta).toList();
        nextV = result.nextCursor;
        hasMoreV = nextV != null;
      }

      if (_filtroTipo != 'ventas') {
        final result =
            await ref.read(servicioRepositoryProvider).getServicios(
              tiendaId: tiendaId,
              fecha: fecha,
              fechaDesde: desde,
              fechaHasta: hasta,
              search: search,
            );
        servicios = result.items.map(_OperacionItem.fromServicio).toList();
        nextS = result.nextCursor;
        hasMoreS = nextS != null;
      }

      final merged = [...ventas, ...servicios]
        ..sort((a, b) => b.fecha.compareTo(a.fecha));

      if (!mounted) return;
      setState(() {
        _items = merged;
        _nextVentasCursor = nextV;
        _nextServiciosCursor = nextS;
        _hasMoreVentas = hasMoreV;
        _hasMoreServicios = hasMoreS;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _cargarMas() async {
    if (_isLoadingMore || (!_hasMoreVentas && !_hasMoreServicios)) {
      return;
    }

    setState(() => _isLoadingMore = true);

    final tiendaId = ref.read(authProvider).selectedTiendaId;
    if (tiendaId == null) {
      if (mounted) setState(() => _isLoadingMore = false);
      return;
    }

    final search =
        _searchController.text.isNotEmpty ? _searchController.text : null;
    final fecha = _usaRango ? null : _fechaFiltro;
    final desde = _usaRango ? _fechaDesde : null;
    final hasta = _usaRango ? _fechaHasta : null;

    try {
      List<_OperacionItem> newVentas = [];
      List<_OperacionItem> newServicios = [];

      if (_filtroTipo != 'servicios' && _hasMoreVentas) {
        final result =
            await ref.read(ventaRepositoryProvider).getVentas(
              tiendaId: tiendaId,
              fecha: fecha,
              fechaDesde: desde,
              fechaHasta: hasta,
              search: search,
              cursor: _nextVentasCursor,
            );
        newVentas = result.items.map(_OperacionItem.fromVenta).toList();
        _nextVentasCursor = result.nextCursor;
        _hasMoreVentas = result.nextCursor != null;
      }

      if (_filtroTipo != 'ventas' && _hasMoreServicios) {
        final result =
            await ref.read(servicioRepositoryProvider).getServicios(
              tiendaId: tiendaId,
              fecha: fecha,
              fechaDesde: desde,
              fechaHasta: hasta,
              search: search,
              cursor: _nextServiciosCursor,
            );
        newServicios = result.items.map(_OperacionItem.fromServicio).toList();
        _nextServiciosCursor = result.nextCursor;
        _hasMoreServicios = result.nextCursor != null;
      }

      if (!mounted) return;
      setState(() {
        _items = [
          ..._items,
          ...newVentas,
          ...newServicios,
        ];
        _items.sort((a, b) => b.fecha.compareTo(a.fecha));
        _isLoadingMore = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  void _cambiarFecha(String nuevaFecha) {
    setState(() {
      _fechaFiltro = nuevaFecha;
      _usaRango = false;
      _fechaDesde = null;
      _fechaHasta = null;
    });
    _cargarInicial();
  }

  void _cambiarTipo(String tipo) {
    setState(() => _filtroTipo = tipo);
    _cargarInicial();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final userMe = authState.userMe;
    final esDueno = userMe?.isDueno ?? false;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            CustomAppBar(
              title: 'Operaciones',
              subtitle: 'Historial',
              icon: Icons.point_of_sale,
              isTiendaTitle: esDueno,
              onTiendaPressed:
                  esDueno ? () => showTiendaSwitcher(context) : null,
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      children: [
                        // Botón volver
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              icon: const Icon(Icons.chevron_left, size: 18),
                              label: const Text('Operaciones'),
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFF2F3A8F),
                              ),
                              onPressed: () => context.go('/operaciones'),
                            ),
                          ),
                        ),
                        // Buscador
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: TextField(
                            controller: _searchController,
                            onChanged: _onSearch,
                            decoration: InputDecoration(
                              hintText: 'Buscar por cliente o comprobante...',
                              prefixIcon: const Icon(Icons.search),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Chips de fecha
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              _FechaChip(
                                label: 'Hoy',
                                selected: !_usaRango &&
                                    _fechaFiltro == _hoy(),
                                onTap: () => _cambiarFecha(_hoy()),
                              ),
                              const SizedBox(width: 8),
                              _FechaChip(
                                label: 'Ayer',
                                selected: !_usaRango &&
                                    _fechaFiltro == _ayer(),
                                onTap: () => _cambiarFecha(_ayer()),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Chips de tipo
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              FilterChip(
                                label: const Text('Todos'),
                                selected: _filtroTipo == 'todos',
                                onSelected: (_) => _cambiarTipo('todos'),
                              ),
                              const SizedBox(width: 8),
                              FilterChip(
                                label: const Text('Ventas'),
                                selected: _filtroTipo == 'ventas',
                                onSelected: (_) => _cambiarTipo('ventas'),
                              ),
                              const SizedBox(width: 8),
                              FilterChip(
                                label: const Text('Servicios'),
                                selected: _filtroTipo == 'servicios',
                                onSelected: (_) =>
                                    _cambiarTipo('servicios'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Lista de operaciones
                        Expanded(
                          child: _items.isEmpty
                              ? const Center(
                                  child: Text('No hay operaciones'))
                              : ListView.builder(
                                  controller: _scrollController,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  itemCount: _items.length +
                                      (_hasMoreVentas ||
                                              _hasMoreServicios
                                          ? 1
                                          : 0),
                                  itemBuilder: (context, index) {
                                    if (index == _items.length) {
                                      return Center(
                                        child: _isLoadingMore
                                            ? const Padding(
                                                padding: EdgeInsets.all(16),
                                                child:
                                                    CircularProgressIndicator(),
                                              )
                                            : const SizedBox.shrink(),
                                      );
                                    }
                                    final item = _items[index];
                                    return _OperacionCard(
                                      item: item,
                                      onTap: () =>
                                          _mostrarDetalle(context, item),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarDetalle(BuildContext context, _OperacionItem item) {
    if (item.esVenta) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) =>
            _VentaDetalleSheet(venta: item.venta!),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) =>
            _ServicioDetalleSheet(servicio: item.servicio!),
      );
    }
  }
}

// ────────────────────────────────────────────────────────────────────
// Modelos y Widgets privados
// ────────────────────────────────────────────────────────────────────

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

  factory _OperacionItem.fromVenta(VentaReadModel venta) {
    return _OperacionItem(
      esVenta: true,
      numeroComprobante: venta.numeroComprobante,
      tipo: venta.tipo,
      tipoDisplay: venta.tipoDisplay,
      total: venta.total,
      fecha: venta.fecha,
      estadoSunat: venta.estadoSunat,
      clienteNombre: venta.cliente?.nombre,
      isActive: venta.isActive,
      venta: venta,
    );
  }

  factory _OperacionItem.fromServicio(ServicioReadModel servicio) {
    return _OperacionItem(
      esVenta: false,
      numeroComprobante: servicio.numeroComprobante,
      tipo: servicio.tipo,
      tipoDisplay: servicio.tipoDisplay,
      total: servicio.total,
      fecha: servicio.fecha,
      estadoSunat: servicio.estadoSunat,
      clienteNombre: servicio.cliente?.nombre,
      isActive: servicio.isActive,
      servicio: servicio,
    );
  }
}

class _FechaChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FechaChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}

class _OperacionCard extends StatelessWidget {
  final _OperacionItem item;
  final VoidCallback onTap;

  const _OperacionCard({
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fecha =
        DateFormat('d MMM, HH:mm', 'es_ES').format(
      DateTime.parse(item.fecha),
    );

    return GestureDetector(
      onTap: onTap,
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: item.esVenta
                          ? const Color(0xFF2F3A8F)
                          : const Color(0xFF27AE60),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      item.esVenta ? Icons.shopping_cart : Icons.build,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.numeroComprobante,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          '${item.tipoDisplay} • $fecha',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: EstadoSUNAT.getColor(item.estadoSunat)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      EstadoSUNAT.getLabel(item.estadoSunat),
                      style: TextStyle(
                        color: EstadoSUNAT.getColor(item.estadoSunat),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.clienteNombre ?? 'Sin cliente',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    'S/. ${item.total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VentaDetalleSheet extends ConsumerWidget {
  final VentaReadModel venta;

  const _VentaDetalleSheet({required this.venta});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canDelete = venta.isActive && venta.estadoSunat != 'ACEPTADO' &&
        venta.estadoSunat != 'ANULADO';
    final canAnular = venta.isActive &&
        venta.estadoSunat == 'ACEPTADO' &&
        _esHoy(venta.fecha);
    final canNotaCredito = venta.isActive &&
        venta.estadoSunat == 'ACEPTADO' &&
        !_esHoy(venta.fecha);

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => SingleChildScrollView(
        controller: scrollController,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        venta.numeroComprobante,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        venta.tipoDisplay,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Total
              _InfoRow('Total', 'S/. ${venta.total.toStringAsFixed(2)}'),
              _InfoRow('Fecha',
                  DateFormat('dd/MM/yyyy HH:mm').format(
                    DateTime.parse(venta.fecha),
                  )),
              _InfoRow('Tipo', venta.tipoDisplay),
              _InfoRow('Método de pago', venta.metodoPagoDisplay),
              _InfoRow('Usuario', venta.usuarioTienda.nombre),
              if (venta.cliente != null)
                _InfoRow('Cliente', venta.cliente!.nombre),
              const SizedBox(height: 16),
              // Botones
              if (canDelete || canAnular || canNotaCredito) ...[
                const Divider(),
                const SizedBox(height: 16),
                Row(
                  children: [
                    if (canDelete)
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Cancelar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade600,
                          ),
                          onPressed: () async {
                            Navigator.pop(context);
                            await ref
                                .read(ventaProvider.notifier)
                                .cancelarVenta(venta.numeroComprobante);
                          },
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  bool _esHoy(String fecha) {
    final hoy = DateTime.now();
    final fechaDt = DateTime.parse(fecha);
    return hoy.year == fechaDt.year &&
        hoy.month == fechaDt.month &&
        hoy.day == fechaDt.day;
  }
}

class _ServicioDetalleSheet extends ConsumerWidget {
  final ServicioReadModel servicio;

  const _ServicioDetalleSheet({required this.servicio});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => SingleChildScrollView(
        controller: scrollController,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        servicio.numeroComprobante,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        servicio.tipoDisplay,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Detalles
              _InfoRow('Total', 'S/. ${servicio.total.toStringAsFixed(2)}'),
              _InfoRow('Fecha',
                  DateFormat('dd/MM/yyyy HH:mm').format(
                    DateTime.parse(servicio.fecha),
                  )),
              _InfoRow('Tipo', servicio.tipoDisplay),
              _InfoRow('Método de pago', servicio.metodoPagoDisplay),
              _InfoRow('Usuario', servicio.usuarioTienda.nombre),
              if (servicio.cliente != null)
                _InfoRow('Cliente', servicio.cliente!.nombre),
              _InfoRow('Descripción', servicio.descripcion),
              _InfoRow('Fecha inicio', servicio.fechaInicio),
              _InfoRow('Fecha fin', servicio.fechaFin),
            ],
          ),
        ),
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
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey[600]),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
