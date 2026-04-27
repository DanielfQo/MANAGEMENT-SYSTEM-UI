import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:management_system_ui/core/common_libs.dart';
import 'package:management_system_ui/features/auth/auth_provider.dart';
import 'package:management_system_ui/features/impresora/impresora_provider.dart';
import 'package:management_system_ui/features/impresora/impresora_repository.dart';
import 'package:management_system_ui/features/impresora/ticket_converter.dart';
import 'package:management_system_ui/features/servicio/models/nota_credito_data.dart';
import 'package:management_system_ui/features/servicio/models/servicio_read_model.dart';
import 'package:management_system_ui/features/servicio/servicio_repository.dart';
import 'package:management_system_ui/features/tienda/tienda_switcher_sheet.dart';
import 'package:management_system_ui/features/venta/constants/estado_sunat.dart';
import 'package:management_system_ui/features/venta/models/venta_read_model.dart';
import 'package:management_system_ui/features/venta/services/printing_service.dart';
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

  Future<void> _mostrarDetalle(
    BuildContext context,
    _OperacionItem item,
  ) async {
    final actuado = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => item.esVenta
          ? _VentaDetalleSheet(venta: item.venta!)
          : _ServicioDetalleSheet(servicio: item.servicio!),
    );
    if (actuado == true && mounted) {
      await _cargarInicial();
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

// Fallback cuando el backend no envía `tipo_display` (p.ej. en servicios).
String _labelTipoOperacion(String tipo) {
  switch (tipo.toUpperCase()) {
    case 'NORMAL':
      return 'Operación normal';
    case 'CREDITO':
      return 'Operación a crédito';
    case 'SUNAT':
      return 'Operación con comprobante SUNAT';
    default:
      return tipo;
  }
}

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
    final detalle = venta.tipoDisplay.isNotEmpty
        ? venta.tipoDisplay
        : _labelTipoOperacion(venta.tipo);
    return _OperacionItem(
      esVenta: true,
      numeroComprobante: venta.numeroComprobante,
      tipo: venta.tipo,
      tipoDisplay:
          detalle.isNotEmpty ? 'Venta · $detalle' : 'Venta',
      total: venta.total,
      fecha: venta.fecha,
      estadoSunat: venta.estadoSunat,
      clienteNombre: venta.cliente?.nombre,
      isActive: venta.isActive,
      venta: venta,
    );
  }

  factory _OperacionItem.fromServicio(ServicioReadModel servicio) {
    final detalle = servicio.tipoDisplay.isNotEmpty
        ? servicio.tipoDisplay
        : _labelTipoOperacion(servicio.tipo);
    return _OperacionItem(
      esVenta: false,
      numeroComprobante: servicio.numeroComprobante,
      tipo: servicio.tipo,
      tipoDisplay:
          detalle.isNotEmpty ? 'Servicio · $detalle' : 'Servicio',
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
                              style: const TextStyle(
                                color: AppColors.textSecondary,
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
    // `fecha` viene del backend en UTC (ISO 8601 con Z). Hay que
    // convertirlo a local antes de comparar día/mes/año, si no una
    // venta de anoche local aparece como "hoy" en UTC y la UI ofrece
    // "Anular" cuando el backend ya solo acepta "Nota de crédito".
    final fechaDt = DateTime.parse(fecha).toLocal();
    return hoy.year == fechaDt.year &&
        hoy.month == fechaDt.month &&
        hoy.day == fechaDt.day;
  }

  int _diasDesdeEmision(String fecha) {
    final hoy = DateTime.now();
    final fechaDt = DateTime.parse(fecha).toLocal();
    final hoyNorm = DateTime(hoy.year, hoy.month, hoy.day);
    final fechaNorm = DateTime(fechaDt.year, fechaDt.month, fechaDt.day);
    return hoyNorm.difference(fechaNorm).inDays;
  }

  Future<void> _confirmarAnulacion() async {
    final result = await showModalBottomSheet<_ConfirmacionResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _ConfirmacionOperacionSheet(
        titulo: 'Anular venta',
        descripcion:
            'La venta se comunicará a SUNAT como anulada. '
            'Ingresa el motivo de la anulación.',
        botonLabel: 'Anular',
        botonColor: Color(0xFFE67E00),
        pedirCodigoTipo: false,
      ),
    );
    if (result == null || !result.confirmado || !mounted) return;
    try {
      await ref.read(ventaProvider.notifier).anularVenta(
            widget.venta.numeroComprobante,
            motivo: result.motivo,
          );
      final error = ref.read(ventaProvider).errorMessage;
      if (!mounted) return;
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red),
        );
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Venta anulada ante SUNAT')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _emitirNotaCredito() async {
    // Fetch full detail so detalle items include lote_producto_id (needed for tipos 07/09)
    VentaReadModel ventaDetalle;
    try {
      ventaDetalle = await ref
          .read(ventaRepositoryProvider)
          .getVentaDetalle(widget.venta.numeroComprobante);
    } catch (_) {
      ventaDetalle = widget.venta;
    }

    if (!mounted) return;
    final result = await showModalBottomSheet<_NotaCreditoVentaResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _NotaCreditoVentaSheet(venta: ventaDetalle),
    );
    if (result == null || !mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (_) =>
          const _CargandoDialog(mensaje: 'Emitiendo nota de crédito…'),
    );

    VentaReadModel? updated;
    Object? apiError;
    try {
      updated = await ref.read(ventaProvider.notifier).emitirNotaCredito(
            widget.venta.numeroComprobante,
            codigoTipo: result.codigoTipo,
            motivo: result.motivo,
            items: result.items.isEmpty
                ? null
                : result.items
                    .map((i) => NotaCreditoItemInput(
                          loteProductoId: i.loteProductoId,
                          cantidad: i.cantidad,
                          precioNuevo: i.precioNuevo,
                        ))
                    .toList(),
          );
    } catch (e) {
      apiError = e;
    }

    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop(); // cerrar diálogo de carga

    if (apiError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $apiError'), backgroundColor: Colors.red),
      );
      return;
    }

    final error = ref.read(ventaProvider).errorMessage;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
      return;
    }

    final url = updated?.notaCredito?.urlPdfTicket ??
        updated?.notaCredito?.urlPdfA4;
    if (url != null && url.isNotEmpty && mounted) {
      await _mostrarImpresionNotaCredito(
        context,
        ref,
        pdfTicketUrl: url,
        numeroNc: updated!.notaCredito!.numeroComprobante,
      );
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Nota de crédito emitida')),
    );
    Navigator.pop(context, true);
  }

  Future<void> _cancelarVenta() async {
    final result = await showModalBottomSheet<_ConfirmacionResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _ConfirmacionOperacionSheet(
        titulo: 'Cancelar venta',
        descripcion:
            '¿Estás seguro de que deseas cancelar esta venta? '
            'Esta acción no se puede deshacer.',
        botonLabel: 'Sí, cancelar',
        botonColor: Color(0xFFD32F2F),
        pedirCodigoTipo: false,
        pedirMotivo: false,
      ),
    );
    if (result == null || !result.confirmado || !mounted) return;
    try {
      await ref
          .read(ventaProvider.notifier)
          .cancelarVenta(widget.venta.numeroComprobante);
      final error = ref.read(ventaProvider).errorMessage;
      if (!mounted) return;
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red),
        );
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Venta cancelada')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _verPdfNotaCredito() async {
    final url = widget.venta.notaCredito?.urlPdfA4 ??
        widget.venta.notaCredito?.urlPdfTicket;
    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La nota de crédito no tiene PDF disponible'),
        ),
      );
      return;
    }
    try {
      final bytes = await PrintingService(ref.read(dioProvider))
          .descargarPdf(url);
      if (!mounted) return;
      final tempDir = await getTemporaryDirectory();
      final file = File(
        '${tempDir.path}/nc_${widget.venta.notaCredito!.numeroComprobante}.pdf',
      );
      await file.writeAsBytes(bytes);
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (ctx) => Dialog(
          insetPadding: const EdgeInsets.all(16),
          child: Scaffold(
            appBar: AppBar(
              title: Text(
                'Nota de crédito '
                '${widget.venta.notaCredito!.numeroComprobante}',
              ),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
            body: PDFView(
              filePath: file.path,
              enableSwipe: true,
              fitPolicy: FitPolicy.WIDTH,
            ),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar PDF: $e')),
      );
    }
  }

  Future<void> _imprimirTicketNotaCredito() async {
    final url = widget.venta.notaCredito?.urlPdfTicket;
    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La nota de crédito no tiene ticket imprimible'),
        ),
      );
      return;
    }
    final config = ref.read(impresoraConfigProvider);
    if (!config.estaConfigura) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay impresora configurada')),
      );
      return;
    }
    try {
      final bytes = await PrintingService(ref.read(dioProvider))
          .descargarPdf(url);
      final comandos = await TicketConverter.pdfAEscPos(bytes);
      final repo = ref.read(impresoraRepositoryProvider);
      if (config.esUsbCups) {
        await repo.enviarViaCups(comandos);
      } else {
        await repo.enviarAImpresora(config.ip, config.puerto, comandos);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nota de crédito enviada a impresora')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al imprimir: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final venta = widget.venta;
    final canDelete = venta.isActive && venta.estadoSunat != 'ACEPTADO' &&
        venta.estadoSunat != 'ANULADO';
    // Factura (01): /anular/ válido mismo día hasta 7 días calendario.
    // Boleta  (03): /anular/ solo mismo día.
    final canAnular = venta.isActive &&
        venta.estadoSunat == 'ACEPTADO' &&
        (venta.tipoComprobante == '01'
            ? _diasDesdeEmision(venta.fecha) <= 7
            : _esHoy(venta.fecha));
    // /nota-credito/ disponible desde el mismo día, sin límite de fecha.
    final canNotaCredito = venta.isActive &&
        venta.estadoSunat == 'ACEPTADO' &&
        venta.notaCredito == null;

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
              // Sección Nota de Crédito (si fue emitida)
              if (venta.notaCredito != null) ...[
                _DetalleSection(
                  title: 'Nota de Crédito',
                  rows: [
                    _DetalleRow(
                      'Número',
                      venta.notaCredito!.numeroComprobante,
                      bold: true,
                    ),
                    _DetalleRow(
                      'Tipo',
                      venta.notaCredito!.tipoComprobanteDisplay,
                    ),
                    if (venta.notaCredito!.motivo.isNotEmpty)
                      _DetalleRow('Motivo', venta.notaCredito!.motivo),
                    _DetalleRow(
                      'Fecha',
                      DateFormat('dd/MM/yyyy HH:mm').format(
                        DateTime.parse(venta.notaCredito!.fecha),
                      ),
                    ),
                  ],
                ),
                // Ítems de NC para tipos 07 y 09
                if (venta.notaCredito!.itemsNc.isNotEmpty)
                  _DetalleSection(
                    title: venta.notaCredito!.tipoComprobante == '07'
                        ? 'Productos devueltos'
                        : 'Ajuste de precio por producto',
                    rows: venta.notaCredito!.itemsNc.map((item) {
                      final candidatos = venta.detalle
                          .where((d) => d.loteProductoId == item.loteProductoId);
                      final nombre = candidatos.isNotEmpty
                          ? candidatos.first.productoNombre
                          : 'Producto #${item.loteProductoId}';
                      final detalle = item.precioNuevo != null
                          ? '${item.cantidad} un. · Precio nuevo: S/. ${item.precioNuevo}'
                          : '${item.cantidad} un.';
                      return _DetalleRow(nombre, detalle);
                    }).toList(),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 4,
                  ),
                  child: Row(
                    children: [
                      if ((venta.notaCredito!.urlPdfA4 ?? '').isNotEmpty ||
                          (venta.notaCredito!.urlPdfTicket ?? '').isNotEmpty)
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.picture_as_pdf_outlined),
                            label: const Text('Ver PDF'),
                            onPressed: _verPdfNotaCredito,
                          ),
                        ),
                      if ((venta.notaCredito!.urlPdfTicket ?? '')
                          .isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.print_outlined),
                            label: const Text('Imprimir'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2F3A8F),
                              foregroundColor: Colors.white,
                            ),
                            onPressed: _imprimirTicketNotaCredito,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
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
    // `fecha` viene del backend en UTC (ISO 8601 con Z). Hay que
    // convertirlo a local antes de comparar día/mes/año, si no una
    // venta de anoche local aparece como "hoy" en UTC y la UI ofrece
    // "Anular" cuando el backend ya solo acepta "Nota de crédito".
    final fechaDt = DateTime.parse(fecha).toLocal();
    return hoy.year == fechaDt.year &&
        hoy.month == fechaDt.month &&
        hoy.day == fechaDt.day;
  }

  int _diasDesdeEmision(String fecha) {
    final hoy = DateTime.now();
    final fechaDt = DateTime.parse(fecha).toLocal();
    final hoyNorm = DateTime(hoy.year, hoy.month, hoy.day);
    final fechaNorm = DateTime(fechaDt.year, fechaDt.month, fechaDt.day);
    return hoyNorm.difference(fechaNorm).inDays;
  }

  Future<void> _confirmarAnulacion() async {
    final result = await showModalBottomSheet<_ConfirmacionResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _ConfirmacionOperacionSheet(
        titulo: 'Anular servicio',
        descripcion:
            'El servicio se comunicará a SUNAT como anulado. '
            'Ingresa el motivo de la anulación.',
        botonLabel: 'Anular',
        botonColor: Color(0xFFE67E00),
      ),
    );
    if (result == null || !result.confirmado || !mounted) return;
    try {
      await ref.read(servicioProvider.notifier).anularServicio(
            widget.servicio.numeroComprobante,
            motivo: result.motivo,
          );
      final error = ref.read(servicioProvider).errorMessage;
      if (!mounted) return;
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red),
        );
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Servicio anulado ante SUNAT')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _emitirNotaCredito() async {
    final result = await showModalBottomSheet<_NotaCreditoServicioResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _NotaCreditoServicioSheet(servicio: widget.servicio),
    );
    if (result == null || !mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (_) =>
          const _CargandoDialog(mensaje: 'Emitiendo nota de crédito…'),
    );

    NotaCreditoData? ncData;
    Object? apiError;
    try {
      ncData = await ref
          .read(servicioProvider.notifier)
          .emitirNotaCredito(
            widget.servicio.numeroComprobante,
            codigoTipo: result.codigoTipo,
            motivo: result.motivo,
            precioNuevo: result.precioNuevo,
          );
    } catch (e) {
      apiError = e;
    }

    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop(); // cerrar diálogo de carga

    if (apiError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $apiError'), backgroundColor: Colors.red),
      );
      return;
    }

    final error = ref.read(servicioProvider).errorMessage;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
      return;
    }

    // Preview con botón imprimir. Para servicios la NC NO se persiste
    // en BD — esta es la única chance de mostrarla / imprimirla.
    final url = ncData?.pdfTicket ?? ncData?.pdfA4;
    if (url != null && url.isNotEmpty && ncData != null) {
      await _mostrarImpresionNotaCredito(
        context,
        ref,
        pdfTicketUrl: url,
        numeroNc: ncData.numero,
      );
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Nota de crédito emitida')),
    );
    Navigator.pop(context, true);
  }

  Future<void> _eliminarServicio() async {
    final result = await showModalBottomSheet<_ConfirmacionResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _ConfirmacionOperacionSheet(
        titulo: 'Eliminar servicio',
        descripcion:
            '¿Estás seguro de que deseas eliminar este servicio? '
            'Esta acción no se puede deshacer.',
        botonLabel: 'Sí, eliminar',
        botonColor: Color(0xFFD32F2F),
        pedirMotivo: false,
      ),
    );
    if (result == null || !result.confirmado || !mounted) return;
    try {
      await ref
          .read(servicioProvider.notifier)
          .eliminarServicio(widget.servicio.numeroComprobante);
      final error = ref.read(servicioProvider).errorMessage;
      if (!mounted) return;
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red),
        );
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Servicio eliminado')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final servicio = widget.servicio;
    final canEliminar = servicio.isActive &&
        servicio.estadoSunat != 'ACEPTADO' &&
        servicio.estadoSunat != 'ANULADO';
    // Factura (01): /anular/ válido mismo día hasta 7 días calendario.
    // Boleta  (03): /anular/ solo mismo día.
    final canAnular = servicio.isActive &&
        servicio.estadoSunat == 'ACEPTADO' &&
        (servicio.tipoComprobante == '01'
            ? _diasDesdeEmision(servicio.fecha) <= 7
            : _esHoy(servicio.fecha));
    // /nota-credito/ disponible desde el mismo día, sin límite de fecha.
    final canNotaCredito = servicio.isActive &&
        servicio.estadoSunat == 'ACEPTADO';

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

// ────────────────────────────────────────────────────────────────────
// Nota de crédito para ventas — nueva sheet con selección de tipo e ítems
// ────────────────────────────────────────────────────────────────────

class _NotaCreditoVentaResult {
  final String codigoTipo;
  final String motivo;
  final List<_NCItemInput> items;
  const _NotaCreditoVentaResult({
    required this.codigoTipo,
    required this.motivo,
    this.items = const [],
  });
}

class _NCItemInput {
  final int loteProductoId;
  final String cantidad;
  final String? precioNuevo;
  const _NCItemInput({
    required this.loteProductoId,
    required this.cantidad,
    this.precioNuevo,
  });
}

class _ItemFormState {
  final VentaLineaModel linea;
  bool seleccionado;
  final TextEditingController cantidadCtrl;
  final TextEditingController precioNuevoCtrl;

  _ItemFormState({required this.linea})
      : seleccionado = false,
        cantidadCtrl = TextEditingController(text: linea.cantidad),
        precioNuevoCtrl = TextEditingController();

  void dispose() {
    cantidadCtrl.dispose();
    precioNuevoCtrl.dispose();
  }
}

class _NotaCreditoVentaSheet extends StatefulWidget {
  final VentaReadModel venta;
  const _NotaCreditoVentaSheet({required this.venta});

  @override
  State<_NotaCreditoVentaSheet> createState() => _NotaCreditoVentaSheetState();
}

class _NotaCreditoVentaSheetState extends State<_NotaCreditoVentaSheet> {
  String _codigoTipo = '01';
  final _motivoCtrl = TextEditingController();
  late final List<_ItemFormState> _itemForms;
  String? _errorMsg;

  static const _tiposNC = [
    ('01', 'Anulación total', 'Cancela toda la venta y revierte el stock completo'),
    ('06', 'Devolución total', 'El cliente devuelve todos los productos'),
    ('07', 'Devolución por ítem', 'El cliente devuelve productos específicos o cantidades parciales'),
    ('09', 'Ajuste de precio', 'Se acordó un precio menor; no se devuelven productos'),
  ];

  @override
  void initState() {
    super.initState();
    _itemForms = widget.venta.detalle
        .where((d) => d.loteProductoId != null)
        .map((d) => _ItemFormState(linea: d))
        .toList();
  }

  @override
  void dispose() {
    _motivoCtrl.dispose();
    for (final f in _itemForms) {
      f.dispose();
    }
    super.dispose();
  }

  bool get _requiereItems => _codigoTipo == '07' || _codigoTipo == '09';

  bool _validar() {
    if (_requiereItems) {
      final sel = _itemForms.where((f) => f.seleccionado).toList();
      if (sel.isEmpty) {
        setState(() => _errorMsg = 'Selecciona al menos un producto');
        return false;
      }
      for (final f in sel) {
        if (_codigoTipo == '07') {
          final cant = double.tryParse(f.cantidadCtrl.text.trim());
          final orig = double.tryParse(f.linea.cantidad);
          if (cant == null || cant <= 0) {
            setState(() => _errorMsg = 'Cantidad inválida para ${f.linea.productoNombre}');
            return false;
          }
          if (orig != null && cant > orig) {
            setState(() => _errorMsg = 'La cantidad no puede superar ${f.linea.cantidad} para ${f.linea.productoNombre}');
            return false;
          }
        } else {
          final precio = double.tryParse(f.precioNuevoCtrl.text.trim());
          final orig = double.tryParse(f.linea.precio);
          if (precio == null || precio <= 0) {
            setState(() => _errorMsg = 'Precio inválido para ${f.linea.productoNombre}');
            return false;
          }
          if (orig != null && precio >= orig) {
            setState(() => _errorMsg = 'El precio nuevo debe ser menor a S/. ${f.linea.precio} para ${f.linea.productoNombre}');
            return false;
          }
        }
      }
    }
    setState(() => _errorMsg = null);
    return true;
  }

  void _confirmar() {
    if (!_validar()) return;
    final items = _requiereItems
        ? _itemForms
            .where((f) => f.seleccionado)
            .map((f) => _NCItemInput(
                  loteProductoId: f.linea.loteProductoId!,
                  cantidad: f.cantidadCtrl.text.trim(),
                  precioNuevo: _codigoTipo == '09'
                      ? f.precioNuevoCtrl.text.trim()
                      : null,
                ))
            .toList()
        : <_NCItemInput>[];
    Navigator.pop(
      context,
      _NotaCreditoVentaResult(
        codigoTipo: _codigoTipo,
        motivo: _motivoCtrl.text.trim(),
        items: items,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 16),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 12, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Nota de crédito',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            widget.venta.numeroComprobante,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              // Tipo section label
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text(
                  '¿Qué tipo de nota de crédito necesitas?',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
              ),
              // Tipo tiles
              for (final tipo in _tiposNC)
                _buildTipoTile(tipo.$1, tipo.$2, tipo.$3),
              // Motivo
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: TextField(
                  controller: _motivoCtrl,
                  minLines: 2,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Motivo',
                    hintText: 'Opcional — describe brevemente la razón',
                    filled: true,
                    fillColor: const Color(0xFFF8F9FB),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey[200]!),
                    ),
                  ),
                ),
              ),
              // Items section (solo tipos 07/09)
              if (_requiereItems) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: Text(
                    _codigoTipo == '07'
                        ? 'Productos a devolver'
                        : 'Productos con ajuste de precio',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
                if (_itemForms.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber_outlined,
                              size: 18, color: Colors.orange[700]),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Los productos de esta venta no tienen ID de lote disponible para devolución por ítem.',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  for (final form in _itemForms) _buildItemForm(form),
              ],
              // Error
              if (_errorMsg != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline,
                            size: 16, color: Colors.red[700]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMsg!,
                            style: TextStyle(
                                fontSize: 12, color: Colors.red[700]),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              // Botones
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(46),
                        ),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2F3A8F),
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(46),
                        ),
                        onPressed: _confirmar,
                        child: const Text('Emitir NC'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTipoTile(String codigo, String titulo, String descripcion) {
    final selected = _codigoTipo == codigo;
    return GestureDetector(
      onTap: () => setState(() {
        _codigoTipo = codigo;
        _errorMsg = null;
      }),
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF2F3A8F).withValues(alpha: 0.06)
              : const Color(0xFFF8F9FB),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? const Color(0xFF2F3A8F) : Colors.grey[200]!,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected
                      ? const Color(0xFF2F3A8F)
                      : Colors.grey[400]!,
                  width: 2,
                ),
              ),
              child: selected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF2F3A8F),
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$codigo — $titulo',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: selected
                          ? const Color(0xFF2F3A8F)
                          : const Color(0xFF1F1F1F),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    descripcion,
                    style:
                        TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemForm(_ItemFormState form) {
    final selected = form.seleccionado;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Container(
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF2F3A8F).withValues(alpha: 0.04)
              : const Color(0xFFF8F9FB),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? const Color(0xFF2F3A8F).withValues(alpha: 0.4)
                : Colors.grey[200]!,
          ),
        ),
        child: Column(
          children: [
            InkWell(
              borderRadius: selected
                  ? const BorderRadius.vertical(top: Radius.circular(10))
                  : BorderRadius.circular(10),
              onTap: () => setState(() {
                form.seleccionado = !form.seleccionado;
                _errorMsg = null;
              }),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(
                      selected
                          ? Icons.check_box
                          : Icons.check_box_outline_blank,
                      color: selected
                          ? const Color(0xFF2F3A8F)
                          : Colors.grey[400],
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            form.linea.productoNombre,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${form.linea.cantidad} ${form.linea.unidadMedida} · S/. ${form.linea.precio}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (selected) ...[
              Divider(height: 1, color: Colors.grey[200]),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: _codigoTipo == '07'
                    ? TextField(
                        controller: form.cantidadCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Cantidad a devolver',
                          hintText:
                              'Máx: ${form.linea.cantidad} ${form.linea.unidadMedida}',
                          suffixText: form.linea.unidadMedida,
                          filled: true,
                          fillColor: Colors.white,
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                BorderSide(color: Colors.grey[300]!),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                        ),
                      )
                    : TextField(
                        controller: form.precioNuevoCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Precio nuevo',
                          hintText:
                              'Debe ser menor a S/. ${form.linea.precio}',
                          prefixText: 'S/. ',
                          filled: true,
                          fillColor: Colors.white,
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                BorderSide(color: Colors.grey[300]!),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                        ),
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────
// Preview e impresión de la nota de crédito recién emitida.
// Reusable para ventas y servicios — el patrón sigue
// `venta_comprobante_page._mostrarPreviewPdf`.
// ────────────────────────────────────────────────────────────────────

Future<void> _mostrarImpresionNotaCredito(
  BuildContext context,
  WidgetRef ref, {
  required String pdfTicketUrl,
  required String numeroNc,
}) async {
  Uint8List bytes;
  try {
    bytes = await PrintingService(ref.read(dioProvider))
        .descargarPdf(pdfTicketUrl);
  } catch (e) {
    if (!context.mounted) return;
    final mensaje = e.toString().toLowerCase();
    final esProblemaRed = mensaje.contains('host lookup') ||
        mensaje.contains('socketexception') ||
        mensaje.contains('failed to connect') ||
        mensaje.contains('connection error');
    if (esProblemaRed) {
      final reintentar = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Sin acceso a SUNAT'),
          content: Text(
            'La nota de crédito $numeroNc fue emitida correctamente, '
            'pero esta red no puede descargar el PDF desde SUNAT. '
            'Conéctate a una red con acceso a internet estándar y '
            'reinténtalo.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cerrar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
      if (reintentar == true && context.mounted) {
        await _mostrarImpresionNotaCredito(
          context,
          ref,
          pdfTicketUrl: pdfTicketUrl,
          numeroNc: numeroNc,
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo descargar el PDF: $e')),
      );
    }
    return;
  }

  final tempDir = await getTemporaryDirectory();
  final tempFile = File(
    '${tempDir.path}/nc_${numeroNc.replaceAll(RegExp('[^A-Za-z0-9]'), '_')}.pdf',
  );
  await tempFile.writeAsBytes(bytes);

  if (!context.mounted) return;

  bool imprimiendo = false;

  await showDialog(
    context: context,
    builder: (dialogCtx) => StatefulBuilder(
      builder: (ctx, setLocal) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: Scaffold(
          appBar: AppBar(
            title: Text('Nota de crédito $numeroNc'),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(ctx),
            ),
          ),
          body: PDFView(
            filePath: tempFile.path,
            enableSwipe: true,
            fitPolicy: FitPolicy.WIDTH,
            onError: (e) {
              ScaffoldMessenger.of(ctx).showSnackBar(
                SnackBar(content: Text('Error al cargar PDF: $e')),
              );
            },
          ),
          // Consumer hace que el botón sea reactivo al estado real de la
          // impresora. Esto evita que quede deshabilitado cuando el provider
          // todavía no había cargado la config de SharedPreferences.
          bottomNavigationBar: Consumer(
            builder: (_, cRef, child) {
              final config = cRef.watch(impresoraConfigProvider);
              final puedeImprimir = config.estaConfigura;
              return Padding(
                padding: const EdgeInsets.all(12),
                child: ElevatedButton.icon(
                  icon: imprimiendo
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.print_outlined),
                  label: Text(
                    puedeImprimir
                        ? (imprimiendo ? 'Imprimiendo…' : 'Imprimir ahora')
                        : 'Sin impresora configurada',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: puedeImprimir
                        ? const Color(0xFF2F3A8F)
                        : Colors.grey[400],
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                  ),
                  onPressed: !puedeImprimir || imprimiendo
                      ? null
                      : () async {
                          setLocal(() => imprimiendo = true);
                          try {
                            final comandos =
                                await TicketConverter.pdfAEscPos(bytes);
                            final repo = cRef.read(impresoraRepositoryProvider);
                            if (config.esUsbCups) {
                              await repo.enviarViaCups(comandos);
                            } else {
                              await repo.enviarAImpresora(
                                config.ip,
                                config.puerto,
                                comandos,
                              );
                            }
                            if (!ctx.mounted) return;
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(
                                content: Text('Nota de crédito enviada'),
                              ),
                            );
                            Navigator.pop(ctx);
                          } catch (e) {
                            if (!ctx.mounted) return;
                            setLocal(() => imprimiendo = false);
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(
                                content: Text('Error al imprimir: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                ),
              );
            },
          ),
        ),
      ),
    ),
  );

  try {
    await tempFile.delete();
  } catch (_) {}
}

// ────────────────────────────────────────────────────────────────────
// Nota de crédito — Servicios (tipos 01 y 09)
// ────────────────────────────────────────────────────────────────────

class _NotaCreditoServicioResult {
  final String codigoTipo;
  final String motivo;
  final String? precioNuevo;

  const _NotaCreditoServicioResult({
    required this.codigoTipo,
    required this.motivo,
    this.precioNuevo,
  });
}

class _NotaCreditoServicioSheet extends StatefulWidget {
  final ServicioReadModel servicio;
  const _NotaCreditoServicioSheet({required this.servicio});

  @override
  State<_NotaCreditoServicioSheet> createState() =>
      _NotaCreditoServicioSheetState();
}

class _NotaCreditoServicioSheetState
    extends State<_NotaCreditoServicioSheet> {
  static const _tiposNC = [
    ('01', 'Anulación total', 'Revierte la operación completa ante SUNAT.'),
    (
      '09',
      'Disminución en valor',
      'Ajusta el total del servicio a un precio menor acordado.'
    ),
  ];

  String _codigoTipo = '01';
  final _motivoCtrl = TextEditingController();
  final _precioNuevoCtrl = TextEditingController();

  @override
  void dispose() {
    _motivoCtrl.dispose();
    _precioNuevoCtrl.dispose();
    super.dispose();
  }

  bool get _requierePrecioNuevo => _codigoTipo == '09';

  String? _validar() {
    if (_motivoCtrl.text.trim().isEmpty) return 'El motivo es requerido.';
    if (_requierePrecioNuevo) {
      final raw = _precioNuevoCtrl.text.trim();
      if (raw.isEmpty) return 'Ingresa el nuevo total del servicio.';
      final valor = double.tryParse(raw);
      if (valor == null || valor <= 0) {
        return 'Ingresa un monto válido mayor a 0.';
      }
      if (valor >= widget.servicio.total) {
        return 'El precio nuevo (S/ $raw) debe ser menor al total actual '
            '(S/ ${widget.servicio.total.toStringAsFixed(2)}).';
      }
    }
    return null;
  }

  void _emitir() {
    final error = _validar();
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error), backgroundColor: Colors.red));
      return;
    }
    Navigator.pop(
      context,
      _NotaCreditoServicioResult(
        codigoTipo: _codigoTipo,
        motivo: _motivoCtrl.text.trim(),
        precioNuevo: _requierePrecioNuevo ? _precioNuevoCtrl.text.trim() : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Nota de Crédito',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.servicio.numeroComprobante,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Content
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.all(20),
                children: [
                  const Text(
                    'Tipo de nota de crédito',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 10),
                  for (final (codigo, nombre, desc) in _tiposNC)
                    _buildTipoTile(codigo, nombre, desc),
                  const SizedBox(height: 16),
                  // Motivo
                  const Text(
                    'Motivo',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _motivoCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Describe el motivo de la nota de crédito',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  // Campo precio_nuevo solo para tipo 09
                  if (_requierePrecioNuevo) ...[
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Nuevo total del servicio',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        Text(
                          'Total actual: S/ ${widget.servicio.total.toStringAsFixed(2)}',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _precioNuevoCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      decoration: InputDecoration(
                        hintText: 'Ej: 500.00',
                        prefixText: 'S/ ',
                        helperText:
                            'Debe ser menor al total actual. El crédito = total actual − nuevo total.',
                        helperMaxLines: 2,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _emitir,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2F3A8F),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Emitir nota de crédito',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold),
                      ),
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

  Widget _buildTipoTile(String codigo, String nombre, String descripcion) {
    final selected = _codigoTipo == codigo;
    return GestureDetector(
      onTap: () => setState(() => _codigoTipo = codigo),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: selected ? const Color(0xFF2F3A8F) : Colors.grey[300]!,
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(10),
          color: selected
              ? const Color(0xFF2F3A8F).withValues(alpha: 0.05)
              : Colors.transparent,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 2),
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected
                      ? const Color(0xFF2F3A8F)
                      : Colors.grey[400]!,
                  width: 2,
                ),
              ),
              child: selected
                  ? Center(
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF2F3A8F),
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(nombre,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: selected
                            ? const Color(0xFF2F3A8F)
                            : Colors.black87,
                      )),
                  const SizedBox(height: 2),
                  Text(descripcion,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey[600])),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────
// Bottom sheet reutilizable para confirmar anulación / nota crédito /
// cancelación con estilo consistente (reemplazo de AlertDialog).
// ────────────────────────────────────────────────────────────────────

class _ConfirmacionResult {
  final bool confirmado;
  final String motivo;
  final String codigoTipo;
  const _ConfirmacionResult({
    required this.confirmado,
    this.motivo = '',
    this.codigoTipo = '01',
  });
}

class _ConfirmacionOperacionSheet extends StatefulWidget {
  final String titulo;
  final String descripcion;
  final String botonLabel;
  final Color botonColor;
  final bool pedirCodigoTipo;
  final bool pedirMotivo;

  const _ConfirmacionOperacionSheet({
    required this.titulo,
    required this.descripcion,
    required this.botonLabel,
    required this.botonColor,
    this.pedirCodigoTipo = false,
    this.pedirMotivo = true,
  });

  @override
  State<_ConfirmacionOperacionSheet> createState() =>
      _ConfirmacionOperacionSheetState();
}

class _ConfirmacionOperacionSheetState
    extends State<_ConfirmacionOperacionSheet> {
  late TextEditingController _motivoController;
  String _codigoTipo = '01';

  static const _tiposNotaCredito = <String, String>{
    '01': '01 · Anulación de la operación',
    '06': '06 · Devolución total',
    '07': '07 · Devolución por ítem',
    '09': '09 · Disminución del valor',
  };

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

  @override
  Widget build(BuildContext context) {
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: keyboardInset),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 16),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        widget.titulo,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Text(
                  widget.descripcion,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              if (widget.pedirCodigoTipo)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: DropdownButtonFormField<String>(
                    initialValue: _codigoTipo,
                    decoration: InputDecoration(
                      labelText: 'Tipo de nota de crédito',
                      filled: true,
                      fillColor: const Color(0xFFF8F9FB),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey[200]!),
                      ),
                    ),
                    items: _tiposNotaCredito.entries
                        .map(
                          (e) => DropdownMenuItem(
                            value: e.key,
                            child: Text(e.value),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _codigoTipo = v);
                    },
                  ),
                ),
              if (widget.pedirMotivo)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: TextField(
                    controller: _motivoController,
                    minLines: 2,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: 'Motivo',
                      hintText: 'Describe brevemente la razón…',
                      filled: true,
                      fillColor: const Color(0xFFF8F9FB),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey[200]!),
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(
                          context,
                          const _ConfirmacionResult(confirmado: false),
                        ),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(46),
                        ),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.botonColor,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(46),
                        ),
                        onPressed: () => Navigator.pop(
                          context,
                          _ConfirmacionResult(
                            confirmado: true,
                            motivo: _motivoController.text.trim(),
                            codigoTipo: _codigoTipo,
                          ),
                        ),
                        child: Text(widget.botonLabel),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────
// Diálogo de carga bloqueante para operaciones contra el servidor.
// ────────────────────────────────────────────────────────────────────

class _CargandoDialog extends StatelessWidget {
  final String mensaje;
  const _CargandoDialog({this.mensaje = 'Procesando…'});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              strokeWidth: 3,
              color: Color(0xFF2F3A8F),
            ),
            const SizedBox(width: 20),
            Flexible(
              child: Text(
                mensaje,
                style: const TextStyle(fontSize: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
