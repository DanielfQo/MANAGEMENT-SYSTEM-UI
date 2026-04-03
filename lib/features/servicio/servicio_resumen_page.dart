import 'package:management_system_ui/core/common_libs.dart';
import 'package:management_system_ui/features/auth/auth_provider.dart';
import 'package:management_system_ui/features/venta/constants/cliente_form_config.dart';
import 'package:management_system_ui/features/venta/constants/metodo_pago.dart';
import 'package:management_system_ui/features/venta/constants/tipo_comprobante.dart';
import 'package:management_system_ui/features/venta/constants/tipo_venta.dart';
import 'package:management_system_ui/features/venta/models/cliente_model.dart';
import 'package:management_system_ui/features/servicio/models/servicio_create_model.dart';
import 'package:management_system_ui/features/servicio/servicio_flow_header.dart';
import 'package:management_system_ui/features/servicio/servicio_provider.dart';
import 'package:management_system_ui/features/venta/venta_repository.dart';
import 'package:management_system_ui/features/venta/widgets/cliente_search_field.dart';
import 'package:management_system_ui/features/tienda/tienda_switcher_sheet.dart';

const Map<String, String> tiposDocumento = {
  '1': 'DNI',
  '6': 'RUC',
  '4': 'Pasaporte',
  '7': 'Carnet de extranjería',
  '0': 'Sin documento',
};

class ServicioResumenPage extends ConsumerStatefulWidget {
  const ServicioResumenPage({super.key});

  @override
  ConsumerState<ServicioResumenPage> createState() =>
      _ServicioResumenPageState();
}

class _ServicioResumenPageState extends ConsumerState<ServicioResumenPage> {
  String tipoVentaSeleccionado = TipoVenta.normal;
  String metodoPagoSeleccionado = MetodoPago.efectivo;
  String tipoComprobanteSeleccionado = TipoComprobante.boleta;
  bool usarClienteExistente = true;
  int? clienteSeleccionadoId;
  ClienteModel? clienteSeleccionado;
  String tipoDocumentoSeleccionado = '1';

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
      final saved = ref.read(resumenServicioProvider);
      setState(() {
        tipoVentaSeleccionado = saved.tipoVenta;
        metodoPagoSeleccionado = saved.metodoPago;
        tipoComprobanteSeleccionado = saved.tipoComprobante;
        tipoDocumentoSeleccionado = saved.tipoDocumento;
        usarClienteExistente = saved.usarClienteExistente;
        clienteSeleccionadoId = saved.clienteId;
        clienteSeleccionado = saved.cliente;
      });
      nombreClienteController.text = saved.nombre;
      numeroDocumentoController.text = saved.numeroDocumento;
      telefonoClienteController.text = saved.telefono;
      emailClienteController.text = saved.email;
      direccionClienteController.text = saved.direccion;
      telefonoClienteExistenteController.text = saved.telefonoExistente;
      emailClienteExistenteController.text = saved.emailExistente;
      direccionClienteExistenteController.text = saved.direccionExistente;
    });
    numeroDocumentoController.addListener(_actualizarTipoDocumento);
  }

  void _actualizarTipoDocumento() {
    final numero = numeroDocumentoController.text.trim();
    if (numero.isEmpty) return;
    if (numero.length == 8 && tipoDocumentoSeleccionado != '1') {
      setState(() => tipoDocumentoSeleccionado = '1');
    } else if (numero.length == 11 && tipoDocumentoSeleccionado != '6') {
      setState(() => tipoDocumentoSeleccionado = '6');
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

  void _guardarEstado() {
    ref.read(resumenServicioProvider.notifier).actualizar(
      ResumenServicioState(
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

  void _guardarCliente(ClienteModel? cliente) {
    final estadoActual = ref.read(resumenServicioProvider);
    ref.read(resumenServicioProvider.notifier).actualizar(
      ResumenServicioState(
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

  bool get clienteRequerido {
    if (tipoVentaSeleccionado == TipoVenta.credito) return true;
    if (tipoVentaSeleccionado == TipoVenta.sunat &&
        tipoComprobanteSeleccionado == TipoComprobante.factura) {
      return true;
    }
    return false;
  }

  bool get requiereRuc {
    return tipoVentaSeleccionado == TipoVenta.sunat &&
        tipoComprobanteSeleccionado == TipoComprobante.factura;
  }

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

  bool get clienteValido {
    if (!clienteRequerido) return true;
    if (usarClienteExistente) {
      if (clienteSeleccionado == null) return false;
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
    if (nombreClienteController.text.trim().isEmpty) return false;
    if (numeroDocumentoController.text.trim().isEmpty) return false;
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

  ClienteFieldsConfig _getClienteFieldsConfig() {
    if (tipoVentaSeleccionado == TipoVenta.sunat && requiereRuc) {
      return ClienteFormConfig.getConfig('SUNAT_FACTURA');
    }
    if (tipoVentaSeleccionado == TipoVenta.sunat && !requiereRuc) {
      return ClienteFormConfig.getConfig('SUNAT_BOLETA');
    }
    return ClienteFormConfig.getConfig(tipoVentaSeleccionado);
  }

  bool get _tieneClienteNuevo {
    return nombreClienteController.text.trim().isNotEmpty &&
        numeroDocumentoController.text.trim().isNotEmpty;
  }

  void _preLlenarClienteNuevo(String busqueda) {
    if (busqueda.isEmpty) return;
    final esNumero = RegExp(r'^\d+$').hasMatch(busqueda);
    if (esNumero) {
      numeroDocumentoController.text = busqueda;
      if (busqueda.length == 8) tipoDocumentoSeleccionado = '1';
      if (busqueda.length == 11) tipoDocumentoSeleccionado = '6';
    } else {
      nombreClienteController.text = busqueda;
    }
  }

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

  Future<void> _enviarServicio(WidgetRef ref, int tiendaId) async {
    final formState = ref.read(servicioFormProvider);

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

    final int? clienteId = usarClienteExistente ? clienteSeleccionadoId : null;

    // Actualizar campos faltantes del cliente existente si los hay
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

    final servicio = ServicioCreateModel(
      tiendaId: tiendaId,
      descripcion: formState.descripcion.isNotEmpty ? formState.descripcion : null,
      fechaInicio: formState.fechaInicio,
      fechaFin: formState.fechaFin,
      total: formState.total,
      tipo: tipoVentaSeleccionado,
      metodoPago: metodoPagoSeleccionado,
      tipoComprobante: tipoVentaSeleccionado == TipoVenta.sunat
          ? tipoComprobanteSeleccionado
          : null,
      clienteId: clienteId,
      clienteNuevo: clienteNuevo,
      camposFaltantesClienteExistente: camposFaltantes,
    );

    await ref.read(servicioProvider.notifier).crearServicio(servicio);
  }

  @override
  Widget build(BuildContext context) {
    final servicioState = ref.watch(servicioProvider);
    final formState = ref.watch(servicioFormProvider);
    final tiendaId = ref.watch(authProvider).selectedTiendaId;
    final userMe = ref.watch(authProvider).userMe;
    final esDueno = userMe?.isDueno ?? false;

    ref.listen(servicioProvider, (previous, next) {
      if (next.successMessage != null && previous?.successMessage == null) {
        ref.read(servicioFormProvider.notifier).limpiar();
        ref.read(resumenServicioProvider.notifier).limpiar();
        context.go('/servicios/comprobante');
        ref.read(servicioProvider.notifier).clearMessages();
      } else if (next.errorMessage != null && previous?.errorMessage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
        ref.read(servicioProvider.notifier).clearMessages();
      }
    });

    // Si no hay datos del formulario, redirigir
    if (formState.fechaInicio.isEmpty || formState.total.isEmpty) {
      return Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              CustomAppBar(
                title: 'Servicios',
                subtitle: 'Resumen del servicio',
                icon: Icons.build,
                isTiendaTitle: esDueno,
              ),
              const ServicioFlowHeader(currentStep: 1, showTiendaHeader: false),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('No hay datos del servicio'),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => context.go('/servicios'),
                        child: const Text('Volver al formulario'),
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
          context.go('/servicios');
        }
      },
      child: Scaffold(
        body: Stack(children: [SafeArea(
          child: Column(
            children: [
              CustomAppBar(
                title: 'Servicios',
                subtitle: 'Resumen del servicio',
                icon: Icons.build,
                isTiendaTitle: esDueno,
                onTiendaPressed: esDueno ? () => showTiendaSwitcher(context) : null,
              ),
              ServicioFlowHeader(
                currentStep: 1,
                showTiendaHeader: false,
                onStepTap: (stepIndex) {
                  _guardarEstado();
                  if (stepIndex == 0) context.go('/servicios');
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
                      // Resumen del servicio
                      _buildResumenServicio(formState, isSmallScreen, context),
                      SizedBox(height: isSmallScreen ? 16 : 20),

                      // Tipo de servicio
                      _buildAccordionTipoVenta(isSmallScreen, context),
                      SizedBox(height: isSmallScreen ? 8 : 12),

                      // Método de pago
                      _buildAccordionMetodoPago(isSmallScreen, context),
                      SizedBox(height: isSmallScreen ? 8 : 12),

                      // Tipo de comprobante (solo SUNAT)
                      if (tipoVentaSeleccionado == TipoVenta.sunat)
                        _buildAccordionComprobante(isSmallScreen, context),
                      SizedBox(height: tipoVentaSeleccionado == TipoVenta.sunat ? 12 : 0),

                      // Cliente (solo para CREDITO y SUNAT)
                      if (tipoVentaSeleccionado != TipoVenta.normal)
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
                                _guardarCliente(cliente);
                              },
                              onAgregarNuevo: (busqueda) {
                                _preLlenarClienteNuevo(busqueda);
                                setState(() {
                                  usarClienteExistente = false;
                                  clienteSeleccionadoId = null;
                                });
                              },
                            ),
                            if (clienteSeleccionado != null) ...[
                              SizedBox(height: isSmallScreen ? 12 : 16),
                              _buildCamposFaltantesClienteExistente(
                                clienteSeleccionado!, isSmallScreen),
                            ],
                            if (!usarClienteExistente) ...[
                              SizedBox(height: isSmallScreen ? 12 : 16),
                              _buildNuevoClienteHeader(isSmallScreen),
                              SizedBox(height: isSmallScreen ? 12 : 16),
                              _buildClienteNuevoForm(isSmallScreen),
                            ],
                          ],
                        ),
                      ),
                      // SizedBox solo si hay sección de cliente
                      if (tipoVentaSeleccionado != TipoVenta.normal)
                        SizedBox(height: isSmallScreen ? 100 : 120)
                      else
                        const SizedBox.shrink(),
                    ],
                  ),
                ),
              ),

              // Footer
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
                        // Resumen total
                        Container(
                          padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2F3A8F).withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total del servicio:',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 12 : 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                'S/. ${formState.total}',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 18 : 20,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF2F3A8F),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: isSmallScreen ? 12 : 14),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(
                                    vertical: isSmallScreen ? 12 : 14,
                                  ),
                                  side: const BorderSide(
                                    color: Color(0xFF2F3A8F), width: 1.5),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                onPressed: () {
                                  _guardarEstado();
                                  context.go('/servicios');
                                },
                                child: const Text(
                                  '\u2190 Datos',
                                  style: TextStyle(
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
                                onPressed: servicioState.isSaving ||
                                        !formularioValido ||
                                        tiendaId == null
                                    ? null
                                    : () => _enviarServicio(ref, tiendaId),
                                child: servicioState.isSaving
                                    ? SizedBox(
                                        height: isSmallScreen ? 18 : 20,
                                        width: isSmallScreen ? 18 : 20,
                                        child: const CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.white),
                                      )
                                    : Text(
                                        'Registrar servicio',
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
        if (servicioState.isSaving)
          const LoadingOverlay(message: 'Registrando servicio...'),
      ]),
    ),
    );
  }

  // ── Resumen del servicio (colapsable)
  Widget _buildResumenServicio(
      ServicioFormState formState, bool isSmallScreen, BuildContext ctx) {
    return Theme(
      data: Theme.of(ctx).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.all(isSmallScreen ? 12 : 16),
        childrenPadding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 12 : 16),
        title: Row(
          children: [
            Icon(Icons.build_outlined,
                color: const Color(0xFF2F3A8F), size: isSmallScreen ? 20 : 24),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Resumen del servicio',
                      style: TextStyle(
                          fontSize: isSmallScreen ? 15 : 16,
                          fontWeight: FontWeight.bold)),
                  Text('S/. ${formState.total}',
                      style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF2F3A8F),
                          fontWeight: FontWeight.w600)),
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
              if (formState.descripcion.isNotEmpty) ...[
                Text('Descripción',
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey[600])),
                const SizedBox(height: 4),
                Text(formState.descripcion,
                    style: const TextStyle(fontSize: 13)),
                const SizedBox(height: 12),
              ],
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Fecha inicio',
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey[600])),
                        Text(formState.fechaInicio,
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Fecha fin',
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey[600])),
                        Text(formState.fechaFin,
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total',
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey[600])),
                  Text('S/. ${formState.total}',
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2F3A8F))),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        ],
      ),
    );
  }

  // ── Acordeón Tipo de Venta
  Widget _buildAccordionTipoVenta(bool isSmallScreen, BuildContext ctx) {
    return Theme(
      data: Theme.of(ctx).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.all(isSmallScreen ? 12 : 16),
        childrenPadding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 12 : 16,
            vertical: isSmallScreen ? 8 : 12),
        title: Row(
          children: [
            const Icon(Icons.trending_up, color: Color(0xFF2F3A8F), size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Tipo de servicio',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  Text(
                      TipoVenta.labels[tipoVentaSeleccionado] ?? 'Seleccionar',
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        collapsedBackgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey[200]!)),
        collapsedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey[200]!)),
        children: [
          Wrap(
            spacing: isSmallScreen ? 6 : 8,
            runSpacing: isSmallScreen ? 6 : 8,
            children: TipoVenta.labels.entries.map((e) {
              final isSelected = tipoVentaSeleccionado == e.key;
              return FilterChip(
                label: Text(e.value,
                    style: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                        fontSize: isSmallScreen ? 11 : 12)),
                selected: isSelected,
                backgroundColor: Colors.white,
                selectedColor:
                    const Color(0xFF2F3A8F).withValues(alpha: 0.2),
                side: BorderSide(
                    color: isSelected
                        ? const Color(0xFF2F3A8F)
                        : Colors.grey[300]!,
                    width: isSelected ? 1.5 : 1),
                onSelected: (_) {
                  setState(() {
                    tipoVentaSeleccionado = e.key;
                    clienteSeleccionadoId = null;
                    clienteSeleccionado = null;
                    nombreClienteController.clear();
                    if (requiereRuc) tipoDocumentoSeleccionado = '6';
                  });
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── Acordeón Método de Pago
  Widget _buildAccordionMetodoPago(bool isSmallScreen, BuildContext ctx) {
    return Theme(
      data: Theme.of(ctx).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.all(isSmallScreen ? 12 : 16),
        childrenPadding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 12 : 16,
            vertical: isSmallScreen ? 8 : 12),
        title: Row(
          children: [
            const Icon(Icons.payment, color: Color(0xFF2F3A8F), size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Método de pago',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  Text(
                      MetodoPago.labels[metodoPagoSeleccionado] ??
                          'Seleccionar',
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        collapsedBackgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey[200]!)),
        collapsedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey[200]!)),
        children: [
          Wrap(
            spacing: isSmallScreen ? 6 : 8,
            runSpacing: isSmallScreen ? 6 : 8,
            children: MetodoPago.labels.entries.map((e) {
              final isSelected = metodoPagoSeleccionado == e.key;
              return FilterChip(
                label: Text(e.value,
                    style: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                        fontSize: isSmallScreen ? 11 : 12)),
                selected: isSelected,
                backgroundColor: Colors.white,
                selectedColor:
                    const Color(0xFF2F3A8F).withValues(alpha: 0.2),
                side: BorderSide(
                    color: isSelected
                        ? const Color(0xFF2F3A8F)
                        : Colors.grey[300]!,
                    width: isSelected ? 1.5 : 1),
                onSelected: (_) =>
                    setState(() => metodoPagoSeleccionado = e.key),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── Acordeón Comprobante (solo SUNAT)
  Widget _buildAccordionComprobante(bool isSmallScreen, BuildContext ctx) {
    return Theme(
      data: Theme.of(ctx).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.all(isSmallScreen ? 12 : 16),
        childrenPadding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 12 : 16,
            vertical: isSmallScreen ? 8 : 12),
        title: Row(
          children: [
            const Icon(Icons.receipt_long, color: Color(0xFF2F3A8F), size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Tipo de comprobante',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  Text(
                      TipoComprobante.labels[tipoComprobanteSeleccionado] ??
                          'Seleccionar',
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        collapsedBackgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey[200]!)),
        collapsedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey[200]!)),
        children: [
          Wrap(
            spacing: isSmallScreen ? 6 : 8,
            runSpacing: isSmallScreen ? 6 : 8,
            children: TipoComprobante.labels.entries.map((e) {
              final isSelected = tipoComprobanteSeleccionado == e.key;
              return FilterChip(
                label: Text(e.value,
                    style: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                        fontSize: isSmallScreen ? 11 : 12)),
                selected: isSelected,
                backgroundColor: Colors.white,
                selectedColor:
                    const Color(0xFF2F3A8F).withValues(alpha: 0.2),
                side: BorderSide(
                    color: isSelected
                        ? const Color(0xFF2F3A8F)
                        : Colors.grey[300]!,
                    width: isSelected ? 1.5 : 1),
                onSelected: (_) {
                  setState(() {
                    tipoComprobanteSeleccionado = e.key;
                    clienteSeleccionadoId = null;
                    clienteSeleccionado = null;
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
                Icon(icon,
                    color: const Color(0xFF2F3A8F),
                    size: isSmallScreen ? 20 : 24),
                const SizedBox(width: 8),
                Text(title,
                    style: TextStyle(
                        fontSize: isSmallScreen ? 15 : 16,
                        fontWeight: FontWeight.bold)),
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
      ClienteModel cliente, bool isSmallScreen) {
    final camposFaltantes = _obtenerCamposFaltantes(cliente);
    if (camposFaltantes.isEmpty) return const SizedBox.shrink();

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
          child: Text('Completa los campos faltantes',
              style: TextStyle(
                  color: Colors.orange[900],
                  fontSize: isSmallScreen ? 12 : 13,
                  fontWeight: FontWeight.w500)),
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
                  vertical: isSmallScreen ? 8 : 10),
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
                  vertical: isSmallScreen ? 8 : 10),
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
                  vertical: isSmallScreen ? 8 : 10),
            ),
          ),
      ],
    );
  }

  Widget _buildNuevoClienteHeader(bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        border: Border.all(color: Colors.blue[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.person_add,
              size: isSmallScreen ? 16 : 18, color: Colors.blue[600]),
          SizedBox(width: isSmallScreen ? 8 : 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Agregar nuevo cliente',
                    style: TextStyle(
                        fontSize: isSmallScreen ? 12 : 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.blue[800])),
                const SizedBox(height: 2),
                Text('Completa los campos requeridos',
                    style: TextStyle(
                        fontSize: isSmallScreen ? 10 : 11,
                        color: Colors.blue[600])),
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
                  vertical: isSmallScreen ? 6 : 8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.close, size: isSmallScreen ? 14 : 16),
                SizedBox(width: isSmallScreen ? 4 : 6),
                Text('Cancelar',
                    style: TextStyle(
                        fontSize: isSmallScreen ? 10 : 11,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClienteNuevoForm(bool isSmallScreen) {
    final config = _getClienteFieldsConfig();
    final spacing = isSmallScreen ? 10.0 : 12.0;
    final contentPadding = EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 10 : 12, vertical: isSmallScreen ? 8 : 10);

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
                  child: Text(e.value,
                      style: TextStyle(fontSize: isSmallScreen ? 12 : 13)),
                );
              }).toList(),
              onChanged: requiereRuc
                  ? null
                  : (value) =>
                      setState(() => tipoDocumentoSeleccionado = value ?? '1'),
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
}
