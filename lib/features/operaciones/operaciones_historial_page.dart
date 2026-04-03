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
import 'package:management_system_ui/features/servicio/servicio_provider.dart';

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

  String _inicioSemana() {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    return DateFormat('yyyy-MM-dd').format(monday);
  }

  String _inicioMes() {
    final now = DateTime.now();
    return DateFormat('yyyy-MM-dd').format(DateTime(now.year, now.month, 1));
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

  void _cambiarRango(String desde, String hasta) {
    setState(() {
      _usaRango = true;
      _fechaFiltro = '';
      _fechaDesde = desde;
      _fechaHasta = hasta;
    });
    _cargarInicial();
  }

  Future<void> _mostrarDateRangePicker() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => _CustomDateRangePicker(
        firstDate: DateTime(2020),
        lastDate: DateTime.now(),
      ),
    );
    if (result != null && result['start'] != null && result['end'] != null) {
      _cambiarRango(result['start']!, result['end']!);
    }
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
                              prefixIcon: const Icon(Icons.search,
                                  color: Color(0xFF2F3A8F)),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.close, size: 20),
                                      onPressed: () {
                                        _searchController.clear();
                                        _cargarInicial();
                                      },
                                    )
                                  : null,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: Colors.grey[300]!),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: Colors.grey[300]!),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
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
                              const SizedBox(width: 8),
                              _FechaChip(
                                label: 'Esta semana',
                                selected: _usaRango &&
                                    _fechaDesde == _inicioSemana() &&
                                    _fechaHasta == _hoy(),
                                onTap: () => _cambiarRango(_inicioSemana(), _hoy()),
                              ),
                              const SizedBox(width: 8),
                              _FechaChip(
                                label: 'Este mes',
                                selected: _usaRango &&
                                    _fechaDesde == _inicioMes() &&
                                    _fechaHasta == _hoy(),
                                onTap: () => _cambiarRango(_inicioMes(), _hoy()),
                              ),
                              const SizedBox(width: 8),
                              _FechaChip(
                                label: _usaRango &&
                                        _fechaDesde != _inicioSemana() &&
                                        _fechaDesde != _inicioMes()
                                    ? '$_fechaDesde → $_fechaHasta'
                                    : 'Personalizado',
                                selected: _usaRango &&
                                    _fechaDesde != _inicioSemana() &&
                                    _fechaDesde != _inicioMes(),
                                icon: Icons.date_range_outlined,
                                onTap: _mostrarDateRangePicker,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        // Chips de tipo
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _TipoChip(
                                  label: 'Todos',
                                  selected: _filtroTipo == 'todos',
                                  onSelected: () => _cambiarTipo('todos'),
                                ),
                                const SizedBox(width: 10),
                                _TipoChip(
                                  label: 'Ventas',
                                  selected: _filtroTipo == 'ventas',
                                  onSelected: () => _cambiarTipo('ventas'),
                                ),
                                const SizedBox(width: 10),
                                _TipoChip(
                                  label: 'Servicios',
                                  selected: _filtroTipo == 'servicios',
                                  onSelected: () =>
                                      _cambiarTipo('servicios'),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Lista de operaciones
                        Expanded(
                          child: _items.isEmpty
                              ? Center(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 32),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.receipt_long_outlined,
                                          size: 56,
                                          color: Colors.grey[300],
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'No hay operaciones',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Intenta cambiar los filtros',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey[500],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  controller: _scrollController,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
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
// Custom Date Range Picker (Dialog)
// ────────────────────────────────────────────────────────────────────

class _CustomDateRangePicker extends StatefulWidget {
  final DateTime firstDate;
  final DateTime lastDate;

  const _CustomDateRangePicker({
    required this.firstDate,
    required this.lastDate,
  });

  @override
  State<_CustomDateRangePicker> createState() =>
      _CustomDateRangePickerState();
}

class _CustomDateRangePickerState extends State<_CustomDateRangePicker> {
  DateTime? _startDate;
  DateTime? _endDate;

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: widget.firstDate,
      lastDate: widget.lastDate,
      locale: const Locale('es', 'ES'),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF2F3A8F)),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        if (_endDate != null && _startDate!.isAfter(_endDate!)) {
          _endDate = _startDate;
        }
      });
    }
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? (_startDate ?? DateTime.now()),
      firstDate: _startDate ?? widget.firstDate,
      lastDate: widget.lastDate,
      locale: const Locale('es', 'ES'),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF2F3A8F)),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Seleccionar período',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1F1F1F),
                  ),
            ),
            const SizedBox(height: 20),
            // Fecha inicio
            _buildDateField(
              label: 'Desde',
              date: _startDate,
              onTap: _selectStartDate,
            ),
            const SizedBox(height: 16),
            // Fecha fin
            _buildDateField(
              label: 'Hasta',
              date: _endDate,
              onTap: _selectEndDate,
            ),
            const SizedBox(height: 24),
            // Botones
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey[600],
                      side: BorderSide(color: Colors.grey[300]!),
                      minimumSize: const Size.fromHeight(44),
                    ),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _startDate != null && _endDate != null
                        ? () => Navigator.pop(
                              context,
                              {
                                'start': DateFormat('yyyy-MM-dd').format(_startDate!),
                                'end': DateFormat('yyyy-MM-dd').format(_endDate!),
                              },
                            )
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2F3A8F),
                      disabledBackgroundColor: Colors.grey[300],
                      minimumSize: const Size.fromHeight(44),
                    ),
                    child: const Text(
                      'Aplicar',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey[50],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date != null
                        ? DateFormat('dd MMM yyyy', 'es_ES').format(date)
                        : 'Seleccionar fecha',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: date != null ? const Color(0xFF1F1F1F) : Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.calendar_today,
              color: Colors.grey[400],
              size: 20,
            ),
          ],
        ),
      ),
    );
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
  final IconData? icon;

  const _FechaChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF2F3A8F)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? const Color(0xFF2F3A8F)
                : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: icon != null
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 14,
                    color: selected ? Colors.white : Colors.grey[700],
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      color: selected ? Colors.white : Colors.grey[700],
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              )
            : Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : Colors.grey[700],
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
      ),
    );
  }
}

class _TipoChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  const _TipoChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onSelected,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF2F3A8F).withValues(alpha: 0.1)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? const Color(0xFF2F3A8F)
                : Colors.grey[300]!,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected
                ? const Color(0xFF2F3A8F)
                : Colors.grey[700],
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
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
    final fecha = DateFormat('d MMM', 'es_ES').format(
      DateTime.parse(item.fecha),
    );
    final hora = DateFormat('HH:mm').format(
      DateTime.parse(item.fecha),
    );
    final iconColor =
        item.esVenta ? const Color(0xFF2F3A8F) : const Color(0xFF27AE60);
    final backgroundColor = iconColor.withValues(alpha: 0.08);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.grey[200]!,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Primera fila: icono, comprobante, estado
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: backgroundColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          item.esVenta
                              ? Icons.shopping_cart_outlined
                              : Icons.build_circle,
                          color: iconColor,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.numeroComprobante,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: Color(0xFF1F1F1F),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.tipoDisplay,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: EstadoSUNAT.getColor(item.estadoSunat)
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          EstadoSUNAT.getLabel(item.estadoSunat),
                          style: TextStyle(
                            color:
                                EstadoSUNAT.getColor(item.estadoSunat),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Segunda fila: cliente, fecha, monto
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          item.clienteNombre ?? 'Sin cliente',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$fecha • $hora',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'S/. ${item.total.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: Color(0xFF1F1F1F),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _VentaDetalleSheet extends ConsumerStatefulWidget {
  final VentaReadModel venta;

  const _VentaDetalleSheet({required this.venta});

  @override
  ConsumerState<_VentaDetalleSheet> createState() =>
      _VentaDetalleSheetState();
}

class _VentaDetalleSheetState extends ConsumerState<_VentaDetalleSheet> {
  late TextEditingController _motivoController;

  @override
  void initState() {
    super.initState();
    _motivoController = TextEditingController();
  }

  @override
  void dispose() {
    _motivoController.dispose();
    super.dispose();
  }

  bool _esHoy(String fecha) {
    final hoy = DateTime.now();
    final fechaDt = DateTime.parse(fecha);
    return hoy.year == fechaDt.year &&
        hoy.month == fechaDt.month &&
        hoy.day == fechaDt.day;
  }

  Future<void> _confirmarAnulacion() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Motivo de anulación'),
        content: TextField(
          controller: _motivoController,
          decoration: const InputDecoration(
            hintText: 'Ingresa el motivo...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      Navigator.pop(context);
      await ref.read(ventaProvider.notifier).anularVenta(
            widget.venta.numeroComprobante,
            codigoTipo: widget.venta.tipoComprobante,
            motivo: _motivoController.text,
          );
    }
  }

  Future<void> _emitirNotaCredito() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Motivo de nota de crédito'),
        content: TextField(
          controller: _motivoController,
          decoration: const InputDecoration(
            hintText: 'Ingresa el motivo...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      Navigator.pop(context);
      await ref
          .read(ventaProvider.notifier)
          .emitirNotaCredito(widget.venta.numeroComprobante);
    }
  }

  Future<void> _cancelarVenta() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancelar venta'),
        content: const Text('¿Estás seguro de que deseas cancelar esta venta?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      Navigator.pop(context);
      await ref
          .read(ventaProvider.notifier)
          .cancelarVenta(widget.venta.numeroComprobante);
    }
  }

  @override
  Widget build(BuildContext context) {
    final venta = widget.venta;
    final canDelete = venta.isActive && venta.estadoSunat != 'ACEPTADO' &&
        venta.estadoSunat != 'ANULADO';
    final canAnular =
        venta.isActive && venta.estadoSunat == 'ACEPTADO' && _esHoy(venta.fecha);
    final canNotaCredito = venta.isActive &&
        venta.estadoSunat == 'ACEPTADO' &&
        !_esHoy(venta.fecha);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Column(
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 16),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2F3A8F).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.shopping_cart_outlined,
                        color: Color(0xFF2F3A8F),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            venta.numeroComprobante,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            venta.tipoDisplay,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: EstadoSUNAT.getColor(venta.estadoSunat)
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        EstadoSUNAT.getLabel(venta.estadoSunat),
                        style: TextStyle(
                          color: EstadoSUNAT.getColor(venta.estadoSunat),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Sección Financiero
              _DetalleSection(
                title: 'Financiero',
                rows: [
                  _DetalleRow(
                    'Total',
                    'S/. ${venta.total.toStringAsFixed(2)}',
                    bold: true,
                  ),
                  _DetalleRow('Método de pago', venta.metodoPagoDisplay),
                  _DetalleRow('Tipo', venta.tipoDisplay),
                ],
              ),
              // Sección Cliente
              if (venta.cliente != null)
                _DetalleSection(
                  title: 'Cliente',
                  rows: [
                    _DetalleRow('Nombre', venta.cliente!.nombre),
                    if (venta.cliente!.numeroDocumento.isNotEmpty)
                      _DetalleRow('Documento', venta.cliente!.numeroDocumento),
                  ],
                ),
              // Sección Registro
              _DetalleSection(
                title: 'Registro',
                rows: [
                  _DetalleRow(
                    'Fecha',
                    DateFormat('dd/MM/yyyy HH:mm').format(
                      DateTime.parse(venta.fecha),
                    ),
                  ),
                  _DetalleRow('Registrado por', venta.usuarioTienda.nombre),
                ],
              ),
              // Acciones
              if (canDelete || canAnular || canNotaCredito)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Divider(),
                      const SizedBox(height: 12),
                      if (canAnular)
                        _ActionButton(
                          label: 'Anular (SUNAT)',
                          icon: Icons.cancel_outlined,
                          color: Colors.orange[700]!,
                          onTap: _confirmarAnulacion,
                        ),
                      if (canNotaCredito)
                        _ActionButton(
                          label: 'Nota de crédito',
                          icon: Icons.undo_outlined,
                          color: const Color(0xFF2F3A8F),
                          onTap: _emitirNotaCredito,
                        ),
                      if (canDelete)
                        _ActionButton(
                          label: 'Cancelar venta',
                          icon: Icons.delete_outline,
                          color: Colors.red[600]!,
                          onTap: _cancelarVenta,
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServicioDetalleSheet extends ConsumerStatefulWidget {
  final ServicioReadModel servicio;

  const _ServicioDetalleSheet({required this.servicio});

  @override
  ConsumerState<_ServicioDetalleSheet> createState() =>
      _ServicioDetalleSheetState();
}

class _ServicioDetalleSheetState extends ConsumerState<_ServicioDetalleSheet>
    with SingleTickerProviderStateMixin {
  late TextEditingController _motivoController;

  @override
  void initState() {
    super.initState();
    _motivoController = TextEditingController();
  }

  @override
  void dispose() {
    _motivoController.dispose();
    super.dispose();
  }

  bool _esHoy(String fecha) {
    final hoy = DateTime.now();
    final fechaDt = DateTime.parse(fecha);
    return hoy.year == fechaDt.year &&
        hoy.month == fechaDt.month &&
        hoy.day == fechaDt.day;
  }

  Future<void> _confirmarAnulacion() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Motivo de anulación'),
        content: TextField(
          controller: _motivoController,
          decoration: const InputDecoration(
            hintText: 'Ingresa el motivo...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      Navigator.pop(context);
      await ref.read(servicioProvider.notifier).anularServicio(
            widget.servicio.numeroComprobante,
            motivo: _motivoController.text,
          );
    }
  }

  Future<void> _emitirNotaCredito() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Motivo de nota de crédito'),
        content: TextField(
          controller: _motivoController,
          decoration: const InputDecoration(
            hintText: 'Ingresa el motivo...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      Navigator.pop(context);
      await ref.read(servicioProvider.notifier).emitirNotaCredito(
            widget.servicio.numeroComprobante,
            motivo: _motivoController.text,
          );
    }
  }

  Future<void> _eliminarServicio() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar servicio'),
        content: const Text('¿Estás seguro de que deseas eliminar este servicio?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      Navigator.pop(context);
      await ref
          .read(servicioProvider.notifier)
          .eliminarServicio(widget.servicio.numeroComprobante);
    }
  }

  @override
  Widget build(BuildContext context) {
    final servicio = widget.servicio;
    final canEliminar = servicio.isActive &&
        servicio.estadoSunat != 'ACEPTADO' &&
        servicio.estadoSunat != 'ANULADO';
    final canAnular = servicio.isActive &&
        servicio.estadoSunat == 'ACEPTADO' &&
        _esHoy(servicio.fecha);
    final canNotaCredito = servicio.isActive &&
        servicio.estadoSunat == 'ACEPTADO' &&
        !_esHoy(servicio.fecha);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Column(
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 16),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFF27AE60).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.build_circle,
                        color: Color(0xFF27AE60),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            servicio.numeroComprobante,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            servicio.tipoDisplay,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: EstadoSUNAT.getColor(servicio.estadoSunat)
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        EstadoSUNAT.getLabel(servicio.estadoSunat),
                        style: TextStyle(
                          color: EstadoSUNAT.getColor(servicio.estadoSunat),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Sección Financiero
              _DetalleSection(
                title: 'Financiero',
                rows: [
                  _DetalleRow(
                    'Total',
                    'S/. ${servicio.total.toStringAsFixed(2)}',
                    bold: true,
                  ),
                  _DetalleRow('Método de pago', servicio.metodoPagoDisplay),
                  _DetalleRow('Tipo', servicio.tipoDisplay),
                ],
              ),
              // Sección Cliente
              if (servicio.cliente != null)
                _DetalleSection(
                  title: 'Cliente',
                  rows: [
                    _DetalleRow('Nombre', servicio.cliente!.nombre),
                    if (servicio.cliente!.numeroDocumento.isNotEmpty)
                      _DetalleRow('Documento', servicio.cliente!.numeroDocumento),
                  ],
                ),
              // Sección Servicio
              _DetalleSection(
                title: 'Servicio',
                rows: [
                  _DetalleRow('Descripción', servicio.descripcion),
                  _DetalleRow('Fecha inicio', servicio.fechaInicio),
                  _DetalleRow('Fecha fin', servicio.fechaFin),
                ],
              ),
              // Sección Registro
              _DetalleSection(
                title: 'Registro',
                rows: [
                  _DetalleRow(
                    'Fecha',
                    DateFormat('dd/MM/yyyy HH:mm').format(
                      DateTime.parse(servicio.fecha),
                    ),
                  ),
                  _DetalleRow('Registrado por', servicio.usuarioTienda.nombre),
                ],
              ),
              // Acciones
              if (canEliminar || canAnular || canNotaCredito)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Divider(),
                      const SizedBox(height: 12),
                      if (canAnular)
                        _ActionButton(
                          label: 'Anular (SUNAT)',
                          icon: Icons.cancel_outlined,
                          color: Colors.orange[700]!,
                          onTap: _confirmarAnulacion,
                        ),
                      if (canNotaCredito)
                        _ActionButton(
                          label: 'Nota de crédito',
                          icon: Icons.undo_outlined,
                          color: const Color(0xFF27AE60),
                          onTap: _emitirNotaCredito,
                        ),
                      if (canEliminar)
                        _ActionButton(
                          label: 'Eliminar servicio',
                          icon: Icons.delete_outline,
                          color: Colors.red[600]!,
                          onTap: _eliminarServicio,
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetalleSection extends StatelessWidget {
  final String title;
  final List<_DetalleRow> rows;

  const _DetalleSection({
    required this.title,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 12),
            ...rows
                .asMap()
                .entries
                .map(
                  (entry) => Column(
                    children: [
                      entry.value,
                      if (entry.key < rows.length - 1)
                        Divider(color: Colors.grey[300], height: 12),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _DetalleRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;

  const _DetalleRow(
    this.label,
    this.value, {
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
              fontSize: 13,
              color: const Color(0xFF1F1F1F),
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: OutlinedButton.icon(
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color, width: 1.5),
          minimumSize: const Size.fromHeight(44),
        ),
        onPressed: onTap,
      ),
    );
  }
}
