import 'dart:async';
import 'package:management_system_ui/core/common_libs.dart';
import 'package:management_system_ui/features/venta/models/cliente_model.dart';
import 'package:management_system_ui/features/venta/venta_repository.dart';

class ClienteSearchField extends ConsumerStatefulWidget {
  final bool requiereRuc;
  final bool clienteRequerido;
  final ValueChanged<ClienteModel?> onClienteSeleccionado;
  final ValueChanged<String>? onAgregarNuevo; // Pasa el texto de búsqueda
  final bool isSmallScreen;
  final ClienteModel? clienteInicial; // Cliente pre-seleccionado al abrir

  const ClienteSearchField({
    super.key,
    required this.requiereRuc,
    required this.clienteRequerido,
    required this.onClienteSeleccionado,
    required this.isSmallScreen,
    this.onAgregarNuevo,
    this.clienteInicial,
  });

  @override
  ConsumerState<ClienteSearchField> createState() => _ClienteSearchFieldState();
}

class _ClienteSearchFieldState extends ConsumerState<ClienteSearchField> {
  late TextEditingController _searchController;
  ClienteModel? _clienteSeleccionado;
  List<ClienteModel> _clientesEncontrados = [];
  bool _mostrarDropdown = false;
  bool _isSearching = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    // Restaurar cliente inicial si se proporcionó
    if (widget.clienteInicial != null) {
      _clienteSeleccionado = widget.clienteInicial;
      _searchController.text =
          '${widget.clienteInicial!.nombre} | ${widget.clienteInicial!.tipoDocumentoDisplay}: ${widget.clienteInicial!.numeroDocumento}';
    }
  }

  @override
  void didUpdateWidget(ClienteSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si el cliente inicial cambió, actualizar el estado interno
    if (widget.clienteInicial != oldWidget.clienteInicial) {
      if (widget.clienteInicial != null) {
        _clienteSeleccionado = widget.clienteInicial;
        _searchController.text =
            '${widget.clienteInicial!.nombre} | ${widget.clienteInicial!.tipoDocumentoDisplay}: ${widget.clienteInicial!.numeroDocumento}';
      } else {
        // Si clienteInicial es null, limpiar
        _clienteSeleccionado = null;
        _searchController.clear();
        _clientesEncontrados = [];
        _mostrarDropdown = false;
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  /// Ejecuta búsqueda manual cuando el usuario presiona el botón
  Future<void> _buscarManual() async {
    final query = _searchController.text.trim();

    if (query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa DNI, RUC o nombre para buscar'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (_clienteSeleccionado != null) return;

    setState(() {
      _isSearching = true;
    });

    await _buscarClientes(query);
  }

  Future<void> _buscarClientes(String query) async {
    if (query.isEmpty) {
      setState(() {
        _clientesEncontrados = [];
        _mostrarDropdown = false;
        _isSearching = false;
      });
      return;
    }

    try {
      final repository = ref.read(ventaRepositoryProvider);
      final resultados = await repository.buscarClientes(
        search: query,
        requiereRuc: widget.requiereRuc,
      );

      if (mounted) {
        setState(() {
          _clientesEncontrados = resultados;
          _mostrarDropdown = resultados.isNotEmpty;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _clientesEncontrados = [];
          _mostrarDropdown = false;
          _isSearching = false;
        });
      }
    }
  }

  void _seleccionarCliente(ClienteModel cliente) {
    setState(() {
      _clienteSeleccionado = cliente;
      _searchController.text =
          '${cliente.nombre} | ${cliente.tipoDocumentoDisplay}: ${cliente.numeroDocumento}';
      _mostrarDropdown = false;
    });
    widget.onClienteSeleccionado(cliente);
  }

  void _limpiar() {
    setState(() {
      _clienteSeleccionado = null;
      _searchController.clear();
      _clientesEncontrados = [];
      _mostrarDropdown = false;
    });
    widget.onClienteSeleccionado(null);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Alerta si cliente es requerido y no hay cliente seleccionado
        if (widget.clienteRequerido && _clienteSeleccionado == null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: EdgeInsets.all(widget.isSmallScreen ? 10 : 12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                border: Border.all(color: Colors.red[300]!, width: 1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: widget.isSmallScreen ? 16 : 18,
                    color: Colors.red[700],
                  ),
                  SizedBox(width: widget.isSmallScreen ? 8 : 10),
                  Expanded(
                    child: Text(
                      widget.requiereRuc
                          ? 'Se requiere cliente con RUC para este tipo de venta'
                          : 'Se requiere cliente para este tipo de venta',
                      style: TextStyle(
                        fontSize: widget.isSmallScreen ? 11 : 12,
                        color: Colors.red[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        // Campo de búsqueda con botón
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                enabled: _clienteSeleccionado == null,
                decoration: InputDecoration(
                  hintText: widget.requiereRuc
                      ? 'Ej: 12345678901'
                      : 'Ej: Juan Pérez o 12345678',
                  labelText: widget.requiereRuc
                      ? 'Buscar cliente por RUC'
                      : 'Buscar cliente por nombre o DNI',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: Color(0xFF2F3A8F),
                      width: 2,
                    ),
                  ),
                  prefixIcon: _clienteSeleccionado != null
                      ? Icon(Icons.check_circle, color: Colors.green[600])
                      : const Icon(Icons.search),
                  suffixIcon: null,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: widget.isSmallScreen ? 10 : 12,
                    vertical: widget.isSmallScreen ? 8 : 10,
                  ),
                ),
              ),
            ),
            if (_clienteSeleccionado == null) ...[
              SizedBox(width: widget.isSmallScreen ? 6 : 8),
              SizedBox(
                height: widget.isSmallScreen ? 48 : 56,
                child: FilledButton.icon(
                  onPressed: _isSearching ? null : _buscarManual,
                  icon: _isSearching
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.search),
                  label: _isSearching ? const SizedBox.shrink() : const Text('Buscar'),
                ),
              ),
            ],
          ],
        ),
        // Dropdown de sugerencias
        if (_mostrarDropdown && !_isSearching)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              constraints: BoxConstraints(
                maxHeight: 250,
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _clientesEncontrados.length,
                itemBuilder: (context, index) {
                  final cliente = _clientesEncontrados[index];
                  return InkWell(
                    onTap: () => _seleccionarCliente(cliente),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cliente.nombre,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${cliente.tipoDocumentoDisplay}: ${cliente.numeroDocumento}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        // Mostrar opción "No se encontró" + "Agregar nuevo" (botón prominente)
        if (_searchController.text.isNotEmpty &&
            !_isSearching &&
            _clientesEncontrados.isEmpty &&
            _clienteSeleccionado == null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onAgregarNuevo != null
                    ? () => widget.onAgregarNuevo!(_searchController.text.trim())
                    : null,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue[400]!, Colors.blue[600]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: widget.isSmallScreen ? 14 : 16,
                      vertical: widget.isSmallScreen ? 14 : 16,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.person_add,
                            size: widget.isSmallScreen ? 20 : 24,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: widget.isSmallScreen ? 12 : 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Agregar nuevo cliente',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: widget.isSmallScreen ? 13 : 14,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'No se encontró cliente en la búsqueda',
                                style: TextStyle(
                                  fontSize: widget.isSmallScreen ? 10 : 11,
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward,
                          size: widget.isSmallScreen ? 16 : 18,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        // Indicador de cliente seleccionado con detalles y botón para cambiar
        if (_clienteSeleccionado != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              padding: EdgeInsets.all(widget.isSmallScreen ? 10 : 12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                border: Border.all(color: Colors.green[300]!, width: 1.5),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    size: widget.isSmallScreen ? 16 : 18,
                    color: Colors.green[600],
                  ),
                  SizedBox(width: widget.isSmallScreen ? 8 : 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cliente seleccionado',
                          style: TextStyle(
                            fontSize: widget.isSmallScreen ? 11 : 12,
                            color: Colors.green[800],
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _clienteSeleccionado!.nombre,
                          style: TextStyle(
                            fontSize: widget.isSmallScreen ? 10 : 11,
                            color: Colors.green[700],
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${_clienteSeleccionado!.tipoDocumentoDisplay}: ${_clienteSeleccionado!.numeroDocumento}',
                          style: TextStyle(
                            fontSize: widget.isSmallScreen ? 9 : 10,
                            color: Colors.green[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: widget.isSmallScreen ? 8 : 10),
                  FilledButton.tonal(
                    onPressed: _limpiar,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.red[100],
                      foregroundColor: Colors.red[700],
                      padding: EdgeInsets.symmetric(
                        horizontal: widget.isSmallScreen ? 8 : 10,
                        vertical: widget.isSmallScreen ? 6 : 8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.delete_outline,
                          size: widget.isSmallScreen ? 14 : 16,
                        ),
                        SizedBox(width: widget.isSmallScreen ? 4 : 6),
                        Text(
                          'Quitar',
                          style: TextStyle(
                            fontSize: widget.isSmallScreen ? 10 : 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
