import 'package:intl/intl.dart';
import 'package:management_system_ui/core/common_libs.dart';
import 'package:management_system_ui/features/auth/auth_provider.dart';
import 'package:management_system_ui/features/servicio/servicio_flow_header.dart';
import 'package:management_system_ui/features/servicio/servicio_provider.dart';
import 'package:management_system_ui/features/tienda/tienda_switcher_sheet.dart';

class ServicioFormularioPage extends ConsumerStatefulWidget {
  const ServicioFormularioPage({super.key});

  @override
  ConsumerState<ServicioFormularioPage> createState() =>
      _ServicioFormularioPageState();
}

class _ServicioFormularioPageState
    extends ConsumerState<ServicioFormularioPage> {
  late final TextEditingController _descripcionCtrl;
  late final TextEditingController _fechaInicioCtrl;
  late final TextEditingController _fechaFinCtrl;
  late final TextEditingController _totalCtrl;

  final _formKey = GlobalKey<FormState>();

  // Almacena fechas en formato yyyy-MM-dd
  String _fechaInicioValue = '';
  String _fechaFinValue = '';

  @override
  void initState() {
    super.initState();
    _descripcionCtrl = TextEditingController();
    _fechaInicioCtrl = TextEditingController();
    _fechaFinCtrl = TextEditingController();
    _totalCtrl = TextEditingController();

    // Sincronizar con el estado del provider si ya tiene datos
    Future.microtask(() {
      final formState = ref.read(servicioFormProvider);
      if (formState.descripcion.isNotEmpty) {
        _descripcionCtrl.text = formState.descripcion;
      }
      if (formState.fechaInicio.isNotEmpty) {
        _fechaInicioValue = formState.fechaInicio;
        _fechaInicioCtrl.text = _formatDisplayDate(formState.fechaInicio);
      }
      if (formState.fechaFin.isNotEmpty) {
        _fechaFinValue = formState.fechaFin;
        _fechaFinCtrl.text = _formatDisplayDate(formState.fechaFin);
      }
      if (formState.total.isNotEmpty) {
        _totalCtrl.text = formState.total;
      }
    });
  }

  @override
  void dispose() {
    _descripcionCtrl.dispose();
    _fechaInicioCtrl.dispose();
    _fechaFinCtrl.dispose();
    _totalCtrl.dispose();
    super.dispose();
  }

  /// Convierte yyyy-MM-dd a dd/MM/yyyy para mostrar
  String _formatDisplayDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (_) {
      return isoDate;
    }
  }

  Future<void> _seleccionarFechaInicio() async {
    final ahora = DateTime.now();
    final inicial = _fechaInicioValue.isNotEmpty
        ? DateTime.tryParse(_fechaInicioValue) ?? ahora
        : ahora;

    final fecha = await showDatePicker(
      context: context,
      initialDate: inicial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      locale: const Locale('es', 'PE'),
    );

    if (fecha != null) {
      setState(() {
        _fechaInicioValue = DateFormat('yyyy-MM-dd').format(fecha);
        _fechaInicioCtrl.text = DateFormat('dd/MM/yyyy').format(fecha);
      });

      // Si fechaFin es anterior a fechaInicio, limpiarla
      if (_fechaFinValue.isNotEmpty) {
        final fechaFin = DateTime.tryParse(_fechaFinValue);
        if (fechaFin != null && fechaFin.isBefore(fecha)) {
          setState(() {
            _fechaFinValue = '';
            _fechaFinCtrl.clear();
          });
        }
      }
    }
  }

  Future<void> _seleccionarFechaFin() async {
    final ahora = DateTime.now();
    final minimaFechaFin = _fechaInicioValue.isNotEmpty
        ? DateTime.tryParse(_fechaInicioValue) ?? ahora
        : ahora;
    final inicial = _fechaFinValue.isNotEmpty
        ? DateTime.tryParse(_fechaFinValue) ?? minimaFechaFin
        : minimaFechaFin;

    final fecha = await showDatePicker(
      context: context,
      initialDate: inicial.isBefore(minimaFechaFin) ? minimaFechaFin : inicial,
      firstDate: minimaFechaFin,
      lastDate: DateTime(2030),
      locale: const Locale('es', 'PE'),
    );

    if (fecha != null) {
      setState(() {
        _fechaFinValue = DateFormat('yyyy-MM-dd').format(fecha);
        _fechaFinCtrl.text = DateFormat('dd/MM/yyyy').format(fecha);
      });
    }
  }

  void _continuar() {
    if (!_formKey.currentState!.validate()) return;

    // Validar fechas requeridas
    if (_fechaInicioValue.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 12),
              Expanded(child: Text('Selecciona la fecha de inicio')),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_fechaFinValue.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 12),
              Expanded(child: Text('Selecciona la fecha de fin')),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Guardar en el provider
    ref.read(servicioFormProvider.notifier).actualizar(
          ServicioFormState(
            descripcion: _descripcionCtrl.text.trim(),
            fechaInicio: _fechaInicioValue,
            fechaFin: _fechaFinValue,
            total: _totalCtrl.text.trim(),
          ),
        );

    context.go('/servicios/resumen');
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final esDueno = authState.userMe?.isDueno ?? false;
    final isSmallScreen = MediaQuery.of(context).size.width < 400;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          context.go('/operaciones');
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F4F7),
        body: SafeArea(
          child: Column(
            children: [
              CustomAppBar(
                title: 'Servicios',
                subtitle: 'Registro de servicios',
                icon: Icons.build,
                isTiendaTitle: esDueno,
                onBack: () => context.go('/operaciones'),
                onTiendaPressed:
                    esDueno ? () => showTiendaSwitcher(context) : null,
              ),
              const ServicioFlowHeader(
                currentStep: 0,
                showTiendaHeader: false,
              ),
              Expanded(
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 14 : 20,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),

                        // Descripcion
                        _buildSectionCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Descripcion',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _descripcionCtrl,
                                maxLines: 3,
                                decoration: _inputDecoration(
                                  hint: 'Descripcion del servicio (opcional)',
                                  icon: Icons.description_outlined,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Fechas
                        _buildSectionCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildRequiredLabel('Fecha de inicio'),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _fechaInicioCtrl,
                                readOnly: true,
                                onTap: _seleccionarFechaInicio,
                                decoration: _inputDecoration(
                                  hint: 'dd/mm/aaaa',
                                  icon: Icons.calendar_today_outlined,
                                ),
                                validator: (_) {
                                  if (_fechaInicioValue.isEmpty) {
                                    return 'La fecha de inicio es requerida';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              _buildRequiredLabel('Fecha de fin'),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _fechaFinCtrl,
                                readOnly: true,
                                onTap: _seleccionarFechaFin,
                                decoration: _inputDecoration(
                                  hint: 'dd/mm/aaaa',
                                  icon: Icons.calendar_today_outlined,
                                ),
                                validator: (_) {
                                  if (_fechaFinValue.isEmpty) {
                                    return 'La fecha de fin es requerida';
                                  }
                                  if (_fechaInicioValue.isNotEmpty) {
                                    final inicio =
                                        DateTime.tryParse(_fechaInicioValue);
                                    final fin =
                                        DateTime.tryParse(_fechaFinValue);
                                    if (inicio != null &&
                                        fin != null &&
                                        fin.isBefore(inicio)) {
                                      return 'La fecha de fin debe ser mayor o igual a la de inicio';
                                    }
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Total
                        _buildSectionCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildRequiredLabel('Total (S/)'),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _totalCtrl,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                decoration: _inputDecoration(
                                  hint: '0.00',
                                  icon: Icons.attach_money,
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'El total es requerido';
                                  }
                                  final parsed =
                                      double.tryParse(value.trim());
                                  if (parsed == null) {
                                    return 'Ingresa un valor numerico valido';
                                  }
                                  if (parsed <= 0) {
                                    return 'El total debe ser mayor a 0';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),

              // Footer con boton Continuar
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 14 : 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _continuar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2F3A8F),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Continuar',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
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

  Widget _buildSectionCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: child,
    );
  }

  Widget _buildRequiredLabel(String text) {
    return Row(
      children: [
        Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(width: 4),
        const Text(
          '*',
          style: TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, size: 20),
      filled: true,
      fillColor: Colors.grey[50],
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF2F3A8F), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
    );
  }
}
