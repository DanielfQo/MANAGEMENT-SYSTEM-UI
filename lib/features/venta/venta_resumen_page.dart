import 'package:management_system_ui/core/common_libs.dart';
import 'package:management_system_ui/features/auth/auth_provider.dart';
import 'package:management_system_ui/features/tienda/tienda_switcher_sheet.dart';
import 'package:management_system_ui/features/venta/constants/cliente_form_config.dart';
import 'package:management_system_ui/features/venta/constants/metodo_pago.dart';
import 'package:management_system_ui/features/venta/constants/tipo_comprobante.dart';
import 'package:management_system_ui/features/venta/constants/tipo_venta.dart';
import 'package:management_system_ui/features/venta/models/cliente_model.dart';
import 'package:management_system_ui/features/venta/models/venta_create_model.dart';
import 'package:management_system_ui/features/venta/venta_flow_header.dart';
import 'package:management_system_ui/features/venta/venta_provider.dart';
import 'package:management_system_ui/features/venta/venta_repository.dart';
import 'package:management_system_ui/features/venta/widgets/cliente_search_field.dart';

/// Tipos de documento según backend
const Map<String, String> tiposDocumento = {
  '1': 'DNI',
  '6': 'RUC',
  '4': 'Pasaporte',
  '7': 'Carnet de extranjería',
  '0': 'Sin documento',
};

class VentaResumenPage extends ConsumerStatefulWidget {
  const VentaResumenPage({super.key});

  @override
  ConsumerState<VentaResumenPage> createState() =>
      _VentaResumenPageState();
}

class _VentaResumenPageState extends ConsumerState<VentaResumenPage> {
  String tipoVentaSeleccionado = TipoVenta.normal;
  String metodoPagoSeleccionado = MetodoPago.efectivo;
  String tipoComprobanteSeleccionado = TipoComprobante.boleta;
  bool usarClienteExistente = true;
  int? clienteSeleccionadoId;
  ClienteModel? clienteSeleccionado; // Guardar cliente completo
  String tipoDocumentoSeleccionado = '1'; // DNI por defecto

  // Campos adicionales para cliente existente
  final telefonoClienteExistenteController = TextEditingController();
  final emailClienteExistenteController = TextEditingController();
  final direccionClienteExistenteController = TextEditingController();

  final nombreClienteController = TextEditingController();
  final numeroDocumentoController = TextEditingController();
  final telefonoClienteController = TextEditingController();
  final emailClienteController = TextEditingController();
  final direccionClienteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      // Restaurar estado guardado del provider
      final saved = ref.read(resumenVentaProvider);
      setState(() {
        tipoVentaSeleccionado = saved.tipoVenta;
        metodoPagoSeleccionado = saved.metodoPago;
        tipoComprobanteSeleccionado = saved.tipoComprobante;
        tipoDocumentoSeleccionado = saved.tipoDocumento;
        usarClienteExistente = saved.usarClienteExistente;
        clienteSeleccionadoId = saved.clienteId;
        clienteSeleccionado = saved.cliente;
      });
      // Poblar controllers con valores guardados
      nombreClienteController.text = saved.nombre;
      numeroDocumentoController.text = saved.numeroDocumento;
      telefonoClienteController.text = saved.telefono;
      emailClienteController.text = saved.email;
      direccionClienteController.text = saved.direccion;
      telefonoClienteExistenteController.text = saved.telefonoExistente;
      emailClienteExistenteController.text = saved.emailExistente;
      direccionClienteExistenteController.text = saved.direccionExistente;
    });
    // Detectar tipo de documento cuando el usuario cambia el número
    numeroDocumentoController.addListener(_actualizarTipoDocumento);
  }

  /// Detecta automáticamente el tipo de documento según la longitud del número
  void _actualizarTipoDocumento() {
    final numero = numeroDocumentoController.text.trim();
    if (numero.isEmpty) return;

    // Solo detectar si el usuario no ha cambiado manualmente el dropdown
    // (si hace un cambio manual, no queremos sobreescribirlo)
    if (numero.length == 8 && tipoDocumentoSeleccionado != '1') {
      setState(() => tipoDocumentoSeleccionado = '1'); // DNI
    } else if (numero.length == 11 && tipoDocumentoSeleccionado != '6') {
      setState(() => tipoDocumentoSeleccionado = '6'); // RUC
    }
  }

  @override
  void dispose() {
    numeroDocumentoController.removeListener(_actualizarTipoDocumento);
    nombreClienteController.dispose();
    numeroDocumentoController.dispose();
    telefonoClienteController.dispose();
    emailClienteController.dispose();
    direccionClienteController.dispose();
    telefonoClienteExistenteController.dispose();
    emailClienteExistenteController.dispose();
    direccionClienteExistenteController.dispose();
    super.dispose();
  }

  /// Guarda solo el cliente seleccionado en el provider
  void _guardarCliente(ClienteModel? cliente) {
    final estadoActual = ref.read(resumenVentaProvider);
    ref.read(resumenVentaProvider.notifier).actualizar(
      ResumenVentaState(
        tipoVenta: estadoActual.tipoVenta,
        metodoPago: estadoActual.metodoPago,
        tipoComprobante: estadoActual.tipoComprobante,
        tipoDocumento: estadoActual.tipoDocumento,
        usarClienteExistente: estadoActual.usarClienteExistente,
        clienteId: cliente?.id,
        cliente: cliente,
        nombre: estadoActual.nombre,
        numeroDocumento: estadoActual.numeroDocumento,
        telefono: estadoActual.telefono,
        email: estadoActual.email,
        direccion: estadoActual.direccion,
        telefonoExistente: estadoActual.telefonoExistente,
        emailExistente: estadoActual.emailExistente,
        direccionExistente: estadoActual.direccionExistente,
      ),
    );
  }

  /// Guarda el estado actual del formulario en el provider
  /// Se llama explícitamente antes de navegar, no en dispose
  void _guardarEstado() {
    ref.read(resumenVentaProvider.notifier).actualizar(
      ResumenVentaState(
        tipoVenta: tipoVentaSeleccionado,
        metodoPago: metodoPagoSeleccionado,
        tipoComprobante: tipoComprobanteSeleccionado,
        tipoDocumento: tipoDocumentoSeleccionado,
        usarClienteExistente: usarClienteExistente,
        clienteId: clienteSeleccionadoId,
        cliente: clienteSeleccionado,
        nombre: nombreClienteController.text,
        numeroDocumento: numeroDocumentoController.text,
        telefono: telefonoClienteController.text,
        email: emailClienteController.text,
        direccion: direccionClienteController.text,
        telefonoExistente: telefonoClienteExistenteController.text,
        emailExistente: emailClienteExistenteController.text,
        direccionExistente: direccionClienteExistenteController.text,
      ),
    );
  }

  /// Cliente requerido: CREDITO siempre, SUNAT+FACTURA siempre
  bool get clienteRequerido {
    if (tipoVentaSeleccionado == TipoVenta.credito) return true;
    if (tipoVentaSeleccionado == TipoVenta.sunat &&
        tipoComprobanteSeleccionado == TipoComprobante.factura) {
      return true;
    }
    return false;
  }

  /// Obtiene los campos faltantes de un cliente existente según el tipo de venta
  Set<String> _obtenerCamposFaltantes(ClienteModel cliente) {
    final config = _getClienteFieldsConfig();
    final faltantes = <String>{};

    if (config.telefono && cliente.telefono.isEmpty) {
      faltantes.add('telefono');
    }
    if (config.email && (cliente.email == null || cliente.email!.isEmpty)) {
      faltantes.add('email');
    }
    if (config.direccion && cliente.direccion.isEmpty) {
      faltantes.add('direccion');
    }

    return faltantes;
  }

  /// Si es factura, el tipo de documento del cliente DEBE ser RUC
  bool get requiereRuc {
    return tipoVentaSeleccionado == TipoVenta.sunat &&
        tipoComprobanteSeleccionado == TipoComprobante.factura;
  }

  bool get clienteValido {
    if (!clienteRequerido) return true;

    if (usarClienteExistente) {
      if (clienteSeleccionado == null) return false;

      // Verificar que los campos faltantes estén completos
      final camposFaltantes = _obtenerCamposFaltantes(clienteSeleccionado!);

      for (var campo in camposFaltantes) {
        if (campo == 'telefono' &&
            telefonoClienteExistenteController.text.trim().isEmpty) {
          return false;
        }
        if (campo == 'email' &&
            emailClienteExistenteController.text.trim().isEmpty) {
          return false;
        }
        if (campo == 'direccion' &&
            direccionClienteExistenteController.text.trim().isEmpty) {
          return false;
        }
      }

      return true;
    }

    // Cliente nuevo: nombre y documento requeridos
    if (nombreClienteController.text.trim().isEmpty) return false;
    if (numeroDocumentoController.text.trim().isEmpty) return false;
    // Si requiere RUC, verificar que esté seleccionado
    if (requiereRuc && tipoDocumentoSeleccionado != '6') return false;
    return true;
  }

  bool get formularioValido {
    if (tipoVentaSeleccionado == TipoVenta.sunat &&
        tipoComprobanteSeleccionado.isEmpty) {
      return false;
    }
    return clienteValido;
  }

  @override
  Widget build(BuildContext context) {
    final carrito = ref.watch(carritoProvider);
    final ventaState = ref.watch(ventaProvider);
    final tiendaId = ref.watch(authProvider).selectedTiendaId;

    // Listener para éxito/error — registrado en build, no en callback
    ref.listen(ventaProvider, (previous, next) {
      if (next.successMessage != null &&
          previous?.successMessage == null) {
        // Limpiar carrito y resumen cuando la venta se completa exitosamente
        ref.read(carritoProvider.notifier).limpiar();
        ref.read(resumenVentaProvider.notifier).limpiar();
        if (next.ventaCreada?.propuestaSunat != null) {
          context.go('/ventas/propuesta-sunat');
        } else {
          // Navegar a página de comprobante en lugar del historial
          context.go('/ventas/comprobante');
        }
        ref.read(ventaProvider.notifier).clearMessages();
      } else if (next.errorMessage != null &&
          previous?.errorMessage == null) {
        final esErrorRelleno = next.errorMessage!.contains('No se encontró relleno');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: esErrorRelleno ? Colors.orange[700] : Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
        ref.read(ventaProvider.notifier).clearMessages();
      }
    });

    final userMe = ref.watch(authProvider).userMe;
    final esDueno = userMe?.isDueno ?? false;

    if (carrito.items.isEmpty) {
      return Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              CustomAppBar(
                title: 'Ventas',
                subtitle: 'Registro de operaciones',
                icon: Icons.point_of_sale,
                isTiendaTitle: esDueno,
                onTiendaPressed: () => _mostrarSelectorTienda(context, ref, carrito.items.length),
              ),
              VentaFlowHeader(
                currentStep: 2,
                showTiendaHeader: false,
                onStepTap: (stepIndex) {
                  _guardarEstado();
                  if (stepIndex == 0) {
                    context.go('/ventas');
                  } else if (stepIndex == 1) {
                    context.go('/ventas/carrito');
                  }
                },
              ),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Carrito vacío'),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => context.go('/ventas'),
                        child: const Text('Volver al catálogo'),
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

    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 400;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _guardarEstado();
          context.go('/ventas/carrito');
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              CustomAppBar(
                title: 'Ventas',
                subtitle: 'Registro de operaciones',
                icon: Icons.point_of_sale,
                isTiendaTitle: esDueno,
                onTiendaPressed: () => _mostrarSelectorTienda(context, ref, carrito.items.length),
              ),
              VentaFlowHeader(
                currentStep: 2,
                showTiendaHeader: false,
                onStepTap: (stepIndex) {
                  _guardarEstado();
                  if (stepIndex == 0) {
                    context.go('/ventas');
                  } else if (stepIndex == 1) {
                    context.go('/ventas/carrito');
                  }
                },
              ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 12 : 16,
                  vertical: isSmallScreen ? 12 : 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
            // ── RESUMEN COLAPSABLE ────────────────────────
            _buildResumenColapsable(carrito, isSmallScreen, context),
            SizedBox(height: isSmallScreen ? 16 : 20),

            // ── ACORDEÓN: TIPO DE VENTA ───────────────────
            _buildAccordionTipoVenta(isSmallScreen, context),
            SizedBox(height: isSmallScreen ? 8 : 12),

            // ── ACORDEÓN: MÉTODO DE PAGO ──────────────────
            _buildAccordionMetodoPago(isSmallScreen, context),
            SizedBox(height: isSmallScreen ? 8 : 12),

            // ── ACORDEÓN: TIPO DE COMPROBANTE (solo SUNAT) ─
            if (tipoVentaSeleccionado == TipoVenta.sunat)
              _buildAccordionComprobante(isSmallScreen, context),

            // Espaciador dinámico para que no se tapen con footer
            SizedBox(height: tipoVentaSeleccionado == TipoVenta.sunat ? 12 : 0),

            // ── SECCIÓN: DATOS DEL CLIENTE ─────────────────
            _buildFormSectionCard(
              icon: Icons.person_outline,
              title: clienteRequerido
                  ? 'Cliente (obligatorio)'
                  : 'Cliente (opcional)',
              isSmallScreen: isSmallScreen,
              ctx: context,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Buscador de clientes
                  ClienteSearchField(
                    clienteInicial: clienteSeleccionado,
                    requiereRuc: requiereRuc,
                    clienteRequerido: clienteRequerido,
                    isSmallScreen: isSmallScreen,
                    onClienteSeleccionado: (cliente) {
                      setState(() {
                        if (cliente != null) {
                          clienteSeleccionado = cliente;
                          clienteSeleccionadoId = cliente.id;
                          usarClienteExistente = true;
                          nombreClienteController.clear();
                          numeroDocumentoController.clear();
                        } else {
                          clienteSeleccionado = null;
                          clienteSeleccionadoId = null;
                        }
                      });
                      // Guardar cliente inmediatamente en el provider
                      _guardarCliente(cliente);
                    },
                    onAgregarNuevo: (busqueda) {
                      // Pre-llenar campos inteligentemente
                      _preLlenarClienteNuevo(busqueda);
                      setState(() {
                        usarClienteExistente = false;
                        clienteSeleccionadoId = null;
                      });
                    },
                  ),
                  // Mostrar campos faltantes si cliente está seleccionado
                  if (clienteSeleccionado != null) ...[
                    SizedBox(height: isSmallScreen ? 12 : 16),
                    _buildCamposFaltantesClienteExistente(
                      clienteSeleccionado!,
                      isSmallScreen,
                    ),
                  ],
                  // Mostrar formulario de cliente nuevo si se selecciona
                  if (!usarClienteExistente) ...[
                    SizedBox(height: isSmallScreen ? 12 : 16),
                    // Header del formulario de nuevo cliente
                    Container(
                      padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        border: Border.all(color: Colors.blue[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.person_add,
                            size: isSmallScreen ? 16 : 18,
                            color: Colors.blue[600],
                          ),
                          SizedBox(width: isSmallScreen ? 8 : 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Agregar nuevo cliente',
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 12 : 13,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.blue[800],
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Completa los campos requeridos',
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 10 : 11,
                                    color: Colors.blue[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          FilledButton.tonal(
                            onPressed: () {
                              setState(() {
                                usarClienteExistente = true;
                                nombreClienteController.clear();
                                numeroDocumentoController.clear();
                                telefonoClienteController.clear();
                                emailClienteController.clear();
                                direccionClienteController.clear();
                              });
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.red[100],
                              foregroundColor: Colors.red[700],
                              padding: EdgeInsets.symmetric(
                                horizontal: isSmallScreen ? 8 : 10,
                                vertical: isSmallScreen ? 6 : 8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.close,
                                  size: isSmallScreen ? 14 : 16,
                                ),
                                SizedBox(width: isSmallScreen ? 4 : 6),
                                Text(
                                  'Cancelar',
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 10 : 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 12 : 16),
                    _buildClienteNuevoForm(isSmallScreen),
                  ],
                ],
              ),
            ),

            // Espaciador para el footer sticky
            SizedBox(height: isSmallScreen ? 100 : 120),
          ],
        ),  // closes inner Column
      ),  // closes SingleChildScrollView
    ),  // closes Expanded

            // ── FOOTER STICKY CON RESUMEN Y BOTÓN ──────────
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Colors.grey[200]!, width: 1),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                  child: Column(
                    children: [
                      // Resumen de totales
                      Container(
                        padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2F3A8F).withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${carrito.items.length} producto${carrito.items.length != 1 ? 's' : ''}',
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 11 : 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Total:',
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 11 : 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'S/. ${carrito.total.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 18 : 20,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF2F3A8F),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 12 : 14),
                      // Botones de navegación y envío
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                  vertical: isSmallScreen ? 12 : 14,
                                ),
                                side: const BorderSide(
                                  color: Color(0xFF2F3A8F),
                                  width: 1.5,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: () {
                                _guardarEstado();
                                context.go('/ventas/carrito');
                              },
                              child: Text(
                                '← Carrito',
                                style: const TextStyle(
                                  color: Color(0xFF2F3A8F),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: isSmallScreen ? 8 : 12),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2F3A8F),
                                disabledBackgroundColor: Colors.grey[300],
                                padding: EdgeInsets.symmetric(
                                  vertical: isSmallScreen ? 12 : 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: ventaState.isSaving ||
                                      !formularioValido ||
                                      tiendaId == null
                                  ? null
                                  : () => _enviarVenta(ref, tiendaId),
                              child: ventaState.isSaving
                                  ? SizedBox(
                                      height: isSmallScreen ? 18 : 20,
                                      width: isSmallScreen ? 18 : 20,
                                      child: const CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      'Enviar venta',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: isSmallScreen ? 13 : 14,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  // ── WIDGET: Resumen colapsable
  Widget _buildResumenColapsable(CarritoState carrito, bool isSmallScreen, BuildContext ctx) {
    return Theme(
      data: Theme.of(ctx).copyWith(
        dividerColor: Colors.transparent,
      ),
      child: ExpansionTile(
        tilePadding: EdgeInsets.all(isSmallScreen ? 12 : 16),
        childrenPadding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 12 : 16),
        title: Row(
          children: [
            Icon(
              Icons.shopping_bag_outlined,
              color: const Color(0xFF2F3A8F),
              size: isSmallScreen ? 20 : 24,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Resumen de productos',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 15 : 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'S/. ${carrito.total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF2F3A8F),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        collapsedBackgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey[200]!),
        ),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey[200]!),
        ),
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...carrito.items.asMap().entries.map((entry) {
                final item = entry.value;
                final isLast = entry.key == carrito.items.length - 1;
                return Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2F3A8F),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Center(
                            child: Text(
                              '${entry.key + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.productoNombre,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: isSmallScreen ? 12 : 13,
                                ),
                              ),
                              Text(
                                '${formatCantidad(item.cantidad)} × S/. ${item.precioVenta.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'S/. ${item.subtotal.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            color: Color(0xFF2F3A8F),
                          ),
                        ),
                      ],
                    ),
                    if (!isLast)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Divider(
                          height: 1,
                          color: Colors.grey[200],
                        ),
                      )
                    else
                      const SizedBox(height: 10),
                  ],
                );
              }),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ── WIDGET: Acordeón Tipo de Venta
  Widget _buildAccordionTipoVenta(bool isSmallScreen, BuildContext ctx) {
    return Theme(
      data: Theme.of(ctx).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.all(isSmallScreen ? 12 : 16),
        childrenPadding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 12 : 16, vertical: isSmallScreen ? 8 : 12),
        title: Row(
          children: [
            const Icon(
              Icons.trending_up,
              color: Color(0xFF2F3A8F),
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tipo de venta',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    TipoVenta.labels[tipoVentaSeleccionado] ?? 'Seleccionar',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        collapsedBackgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey[200]!),
        ),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey[200]!),
        ),
        children: [
          Wrap(
            spacing: isSmallScreen ? 6 : 8,
            runSpacing: isSmallScreen ? 6 : 8,
            children: TipoVenta.labels.entries.map((e) {
              final isSelected = tipoVentaSeleccionado == e.key;
              return FilterChip(
                label: Text(
                  e.value,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: isSmallScreen ? 11 : 12,
                  ),
                ),
                selected: isSelected,
                backgroundColor: Colors.white,
                selectedColor: const Color(0xFF2F3A8F).withValues(alpha: 0.2),
                side: BorderSide(
                  color: isSelected ? const Color(0xFF2F3A8F) : Colors.grey[300]!,
                  width: isSelected ? 1.5 : 1,
                ),
                onSelected: (_) {
                  setState(() {
                    tipoVentaSeleccionado = e.key;
                    clienteSeleccionadoId = null;
                    nombreClienteController.clear();
                    if (requiereRuc) {
                      tipoDocumentoSeleccionado = '6';
                    }
                  });
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── WIDGET: Acordeón Método de Pago
  Widget _buildAccordionMetodoPago(bool isSmallScreen, BuildContext ctx) {
    return Theme(
      data: Theme.of(ctx).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.all(isSmallScreen ? 12 : 16),
        childrenPadding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 12 : 16, vertical: isSmallScreen ? 8 : 12),
        title: Row(
          children: [
            const Icon(
              Icons.payment,
              color: Color(0xFF2F3A8F),
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Método de pago',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    MetodoPago.labels[metodoPagoSeleccionado] ?? 'Seleccionar',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        collapsedBackgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey[200]!),
        ),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey[200]!),
        ),
        children: [
          Wrap(
            spacing: isSmallScreen ? 6 : 8,
            runSpacing: isSmallScreen ? 6 : 8,
            children: MetodoPago.labels.entries.map((e) {
              final isSelected = metodoPagoSeleccionado == e.key;
              return FilterChip(
                label: Text(
                  e.value,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: isSmallScreen ? 11 : 12,
                  ),
                ),
                selected: isSelected,
                backgroundColor: Colors.white,
                selectedColor: const Color(0xFF2F3A8F).withValues(alpha: 0.2),
                side: BorderSide(
                  color: isSelected ? const Color(0xFF2F3A8F) : Colors.grey[300]!,
                  width: isSelected ? 1.5 : 1,
                ),
                onSelected: (_) {
                  setState(() {
                    metodoPagoSeleccionado = e.key;
                  });
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── WIDGET: Acordeón Comprobante (solo SUNAT)
  Widget _buildAccordionComprobante(bool isSmallScreen, BuildContext ctx) {
    return Theme(
      data: Theme.of(ctx).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.all(isSmallScreen ? 12 : 16),
        childrenPadding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 12 : 16, vertical: isSmallScreen ? 8 : 12),
        title: Row(
          children: [
            const Icon(
              Icons.receipt_long,
              color: Color(0xFF2F3A8F),
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tipo de comprobante',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    TipoComprobante.labels[tipoComprobanteSeleccionado] ?? 'Seleccionar',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        collapsedBackgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey[200]!),
        ),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey[200]!),
        ),
        children: [
          Wrap(
            spacing: isSmallScreen ? 6 : 8,
            runSpacing: isSmallScreen ? 6 : 8,
            children: TipoComprobante.labels.entries.map((e) {
              final isSelected = tipoComprobanteSeleccionado == e.key;
              return FilterChip(
                label: Text(
                  e.value,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: isSmallScreen ? 11 : 12,
                  ),
                ),
                selected: isSelected,
                backgroundColor: Colors.white,
                selectedColor: const Color(0xFF2F3A8F).withValues(alpha: 0.2),
                side: BorderSide(
                  color: isSelected ? const Color(0xFF2F3A8F) : Colors.grey[300]!,
                  width: isSelected ? 1.5 : 1,
                ),
                onSelected: (_) {
                  setState(() {
                    tipoComprobanteSeleccionado = e.key;
                    clienteSeleccionadoId = null;
                    nombreClienteController.clear();
                    if (e.key == TipoComprobante.factura) {
                      tipoDocumentoSeleccionado = '6';
                    } else {
                      tipoDocumentoSeleccionado = '1';
                    }
                  });
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFormSectionCard({
    required IconData icon,
    required String title,
    required Widget child,
    required bool isSmallScreen,
    required BuildContext ctx,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: const Color(0xFF2F3A8F),
                  size: isSmallScreen ? 20 : 24,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 15 : 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: isSmallScreen ? 12 : 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildCamposFaltantesClienteExistente(
    ClienteModel cliente,
    bool isSmallScreen,
  ) {
    final camposFaltantes = _obtenerCamposFaltantes(cliente);

    if (camposFaltantes.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
          decoration: BoxDecoration(
            color: Colors.orange[50],
            border: Border.all(color: Colors.orange[300]!, width: 1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'Completa los campos faltantes',
            style: TextStyle(
              color: Colors.orange[900],
              fontSize: isSmallScreen ? 12 : 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        SizedBox(height: isSmallScreen ? 12 : 16),
        if (camposFaltantes.contains('telefono')) ...[
          TextField(
            controller: telefonoClienteExistenteController,
            onChanged: (_) => setState(() {}),
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'Teléfono *',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.phone),
              contentPadding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 10 : 12,
                vertical: isSmallScreen ? 8 : 10,
              ),
            ),
          ),
          SizedBox(height: isSmallScreen ? 10 : 12),
        ],
        if (camposFaltantes.contains('email')) ...[
          TextField(
            controller: emailClienteExistenteController,
            onChanged: (_) => setState(() {}),
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Email *',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.email),
              contentPadding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 10 : 12,
                vertical: isSmallScreen ? 8 : 10,
              ),
            ),
          ),
          SizedBox(height: isSmallScreen ? 10 : 12),
        ],
        if (camposFaltantes.contains('direccion'))
          TextField(
            controller: direccionClienteExistenteController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Dirección *',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.location_on),
              contentPadding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 10 : 12,
                vertical: isSmallScreen ? 8 : 10,
              ),
            ),
          ),
      ],
    );
  }

  /// Pre-llena los campos del cliente nuevo basado en el texto de búsqueda
  void _preLlenarClienteNuevo(String busqueda) {
    if (busqueda.isEmpty) return;

    // Detectar si es número o letra
    final esNumero = RegExp(r'^\d+$').hasMatch(busqueda);

    if (esNumero) {
      // Es número → va al campo de documento
      numeroDocumentoController.text = busqueda;

      // Intentar detectar si es DNI (8 dígitos) o RUC (11 dígitos)
      if (busqueda.length == 8) {
        tipoDocumentoSeleccionado = '1'; // DNI
      } else if (busqueda.length == 11) {
        tipoDocumentoSeleccionado = '6'; // RUC
      }
    } else {
      // Es texto → va al nombre
      nombreClienteController.text = busqueda;
    }
  }

  Widget _buildClienteNuevoForm(bool isSmallScreen) {
    // Obtener configuración de campos requeridos para este tipo de venta
    final config = _getClienteFieldsConfig();
    final spacing = isSmallScreen ? 10.0 : 12.0;
    final contentPadding = EdgeInsets.symmetric(
      horizontal: isSmallScreen ? 10 : 12,
      vertical: isSmallScreen ? 8 : 10,
    );

    return Column(
      children: [
        TextField(
          controller: nombreClienteController,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            labelText: 'Nombre del cliente *',
            border: const OutlineInputBorder(),
            contentPadding: contentPadding,
          ),
        ),
        SizedBox(height: spacing),
        // Tipo de documento como dropdown
        InputDecorator(
          decoration: InputDecoration(
            labelText: _getFieldLabel('tipoDocumento', config),
            border: const OutlineInputBorder(),
            contentPadding: contentPadding,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: tipoDocumentoSeleccionado,
              isExpanded: true,
              items: tiposDocumento.entries.map((e) {
                return DropdownMenuItem<String>(
                  value: e.key,
                  child: Text(
                    e.value,
                    style: TextStyle(fontSize: isSmallScreen ? 12 : 13),
                  ),
                );
              }).toList(),
              onChanged: requiereRuc
                  ? null
                  : (value) {
                      setState(() {
                        tipoDocumentoSeleccionado = value ?? '1';
                      });
                    },
            ),
          ),
        ),
        SizedBox(height: spacing),
        TextField(
          controller: numeroDocumentoController,
          onChanged: (_) => setState(() {}),
          keyboardType: TextInputType.number,
          maxLength: tipoDocumentoSeleccionado == '6' ? 11 : 8,
          decoration: InputDecoration(
            labelText: _getFieldLabel('numeroDocumento', config),
            border: const OutlineInputBorder(),
            counterText: '',
            contentPadding: contentPadding,
            helperText: tipoDocumentoSeleccionado == '6'
                ? 'RUC: 11 dígitos'
                : tipoDocumentoSeleccionado == '1'
                    ? 'DNI: 8 dígitos'
                    : null,
          ),
        ),
        SizedBox(height: spacing),
        TextField(
          controller: telefonoClienteController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: _getFieldLabel('telefono', config),
            border: const OutlineInputBorder(),
            contentPadding: contentPadding,
          ),
        ),
        SizedBox(height: spacing),
        TextField(
          controller: emailClienteController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: _getFieldLabel('email', config),
            border: const OutlineInputBorder(),
            contentPadding: contentPadding,
          ),
        ),
        SizedBox(height: spacing),
        TextField(
          controller: direccionClienteController,
          decoration: InputDecoration(
            labelText: _getFieldLabel('direccion', config),
            border: const OutlineInputBorder(),
            contentPadding: contentPadding,
          ),
        ),
      ],
    );
  }

  /// Genera el label del campo indicando si es requerido u opcional
  String _getFieldLabel(String campo, ClienteFieldsConfig config) {
    final esRequerido = config.esRequerido(campo);
    final labels = {
      'tipoDocumento': 'Tipo de documento',
      'numeroDocumento': 'Número de documento',
      'telefono': 'Teléfono',
      'email': 'Email',
      'direccion': 'Dirección',
    };

    final label = labels[campo] ?? campo;
    return esRequerido ? '$label *' : '$label (opcional)';
  }

  /// Obtiene la configuración de campos según el tipo de venta
  ClienteFieldsConfig _getClienteFieldsConfig() {
    final config = ClienteFormConfig.getConfig(tipoVentaSeleccionado);

    // Para SUNAT Factura, usar configuración específica
    if (tipoVentaSeleccionado == TipoVenta.sunat && requiereRuc) {
      return ClienteFormConfig.getConfig('SUNAT_FACTURA');
    }

    // Para SUNAT Boleta
    if (tipoVentaSeleccionado == TipoVenta.sunat && !requiereRuc) {
      return ClienteFormConfig.getConfig('SUNAT_BOLETA');
    }

    return config;
  }

  /// Determina si el usuario proporcionó datos de cliente (aunque sea opcional)
  bool get _tieneClienteNuevo {
    return nombreClienteController.text.trim().isNotEmpty &&
        numeroDocumentoController.text.trim().isNotEmpty;
  }

  Future<void> _enviarVenta(WidgetRef ref, int tiendaId) async {
    final carrito = ref.read(carritoProvider);

    // Construir cliente nuevo si el usuario llenó los datos
    ClienteNuevoInput? clienteNuevo;
    if (!usarClienteExistente && _tieneClienteNuevo) {
      clienteNuevo = ClienteNuevoInput(
        nombre: nombreClienteController.text.trim(),
        tipoDocumento: tipoDocumentoSeleccionado,
        numeroDocumento: numeroDocumentoController.text.trim(),
        telefono: telefonoClienteController.text.trim(),
        email: emailClienteController.text.trim(),
        direccion: direccionClienteController.text.trim(),
      );
    }

    // Cliente existente seleccionado
    final int? clienteId = usarClienteExistente
        ? clienteSeleccionadoId
        : null;

    // Recopilar campos faltantes completados del cliente existente
    Map<String, String>? camposFaltantes;
    if (usarClienteExistente && clienteId != null) {
      camposFaltantes = <String, String>{};
      if (telefonoClienteExistenteController.text.trim().isNotEmpty) {
        camposFaltantes['telefono'] = telefonoClienteExistenteController.text.trim();
      }
      if (emailClienteExistenteController.text.trim().isNotEmpty) {
        camposFaltantes['email'] = emailClienteExistenteController.text.trim();
      }
      if (direccionClienteExistenteController.text.trim().isNotEmpty) {
        camposFaltantes['direccion'] = direccionClienteExistenteController.text.trim();
      }
      if (camposFaltantes.isEmpty) {
        camposFaltantes = null;
      } else {
        // Actualizar cliente primero si hay campos faltantes completados
        try {
          final repository = ref.read(ventaRepositoryProvider);
          await repository.actualizarCliente(clienteId, camposFaltantes);
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error al actualizar cliente: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      }
    }

    // Construir productos
    final productos = carrito.items.map((item) {
      return VentaProductoItem(
        loteProductoId: item.loteProductoId,
        productoId: item.productoId,
        cantidad: item.cantidad.toString(),
        precioVenta: item.precioVenta.toString(),
        esAveriado: item.esAveriado,
      );
    }).toList();

    // Construir modelo
    final venta = VentaCreateModel(
      tiendaId: tiendaId,
      tipo: tipoVentaSeleccionado,
      metodoPago: metodoPagoSeleccionado,
      tipoComprobante: tipoVentaSeleccionado == TipoVenta.sunat
          ? tipoComprobanteSeleccionado
          : null,
      clienteId: clienteId,
      clienteNuevo: clienteNuevo,
      productos: productos,
      camposFaltantesClienteExistente: camposFaltantes,
    );

    await ref.read(ventaProvider.notifier).crearVenta(venta);
  }

  void _mostrarSelectorTienda(
    BuildContext context,
    WidgetRef ref,
    int carritoItemsCount,
  ) {
    showTiendaSwitcher(
      context,
      carritoItemsCount: carritoItemsCount,
      onConfirmClearCarrito: () =>
          ref.read(carritoProvider.notifier).limpiar(),
    );
  }
}
