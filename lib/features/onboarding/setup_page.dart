import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:management_system_ui/core/common_libs.dart';
import 'setup_provider.dart';

class SetupPage extends ConsumerStatefulWidget {
  const SetupPage({super.key});

  @override
  ConsumerState<SetupPage> createState() => _SetupPageState();
}

class _SetupPageState extends ConsumerState<SetupPage> {
  // ── Empresa ──────────────────────────────────────────────────────────────
  final _rucController = TextEditingController();
  final _razonSocialController = TextEditingController();
  final _nombreComercialController = TextEditingController();

  // ── Tienda ───────────────────────────────────────────────────────────────
  final _nombreSedeController = TextEditingController();
  final _direccionController = TextEditingController();
  final _ubigeoController = TextEditingController();
  final _serieFacturaController = TextEditingController();
  final _serieBoletaController = TextEditingController();
  final _serieTicketController = TextEditingController();

  @override
  void dispose() {
    _rucController.dispose();
    _razonSocialController.dispose();
    _nombreComercialController.dispose();
    _nombreSedeController.dispose();
    _direccionController.dispose();
    _ubigeoController.dispose();
    _serieFacturaController.dispose();
    _serieBoletaController.dispose();
    _serieTicketController.dispose();
    super.dispose();
  }

  void _handleNext(SetupState state) {
    if (state.currentStep == SetupStep.empresa) {
      if (state.empresaCreada != null) {
        ref.read(setupProvider.notifier).avanzarATienda();
      } else {
        _submitEmpresa();
      }
    } else {
      _submitTienda();
    }
  }

  void _submitEmpresa() {
    final ruc = _rucController.text.trim();
    final razonSocial = _razonSocialController.text.trim();
    final nombreComercial = _nombreComercialController.text.trim();

    if (ruc.isEmpty || razonSocial.isEmpty || nombreComercial.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa todos los campos de la empresa')),
      );
      return;
    }

    ref.read(setupProvider.notifier).crearEmpresa(
          ruc: ruc,
          razonSocial: razonSocial,
          nombreComercial: nombreComercial,
        );
  }

  void _submitTienda() {
    final nombreSede = _nombreSedeController.text.trim();
    final direccion = _direccionController.text.trim();
    final ubigeo = _ubigeoController.text.trim();
    final serieFactura = _serieFacturaController.text.trim();
    final serieBoleta = _serieBoletaController.text.trim();
    final serieTicket = _serieTicketController.text.trim();

    if (nombreSede.isEmpty ||
        direccion.isEmpty ||
        ubigeo.isEmpty ||
        serieFactura.isEmpty ||
        serieBoleta.isEmpty ||
        serieTicket.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa todos los campos de la tienda')),
      );
      return;
    }

    ref.read(setupProvider.notifier).crearTienda(
          nombreSede: nombreSede,
          direccion: direccion,
          ubigeo: ubigeo,
          serieFactura: serieFactura,
          serieBoleta: serieBoleta,
          serieTicket: serieTicket,
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(setupProvider);

    ref.listen(setupProvider, (prev, next) {
      if (next.isSuccess) {
        // El router redirigirá automáticamente al detectar tiendas en userMe
      }
    });

    final isEmpresaStep = state.currentStep == SetupStep.empresa;
    final currentStepIndex = isEmpresaStep ? 0 : 1;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      body: SafeArea(
        child: Column(
          children: [
            // ── Header con stepper ───────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
              color: const Color(0xFFF2F4F7),
              child: Column(
                children: [
                  // Logo
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2F3A8F),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.construction,
                            color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Ferretería Central',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Step indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildStepIndicator(
                        index: 0,
                        currentIndex: currentStepIndex,
                        icon: Icons.business_outlined,
                        label: 'Empresa',
                      ),
                      _buildStepConnector(currentIndex: currentStepIndex, stepIndex: 0),
                      _buildStepIndicator(
                        index: 1,
                        currentIndex: currentStepIndex,
                        icon: Icons.store_outlined,
                        label: 'Tienda',
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Barra de progreso
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: isEmpresaStep ? 0.5 : 1.0,
                      minHeight: 4,
                      backgroundColor: const Color(0xFFE0E0E0),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF2F3A8F)),
                    ),
                  ),
                ],
              ),
            ),

            // ── Contenido del paso ───────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Título del paso
                    Text(
                      isEmpresaStep
                          ? 'Datos de la empresa'
                          : 'Configura tu tienda',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isEmpresaStep
                          ? 'Ingresa la información de tu empresa'
                          : 'Agrega tu primera sucursal',
                      style: const TextStyle(color: Colors.grey),
                    ),

                    const SizedBox(height: 20),

                    // Tarjeta del formulario
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: isEmpresaStep
                          ? _buildEmpresaForm()
                          : _buildTiendaForm(state),
                    ),

                    if (state.errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.error_outline,
                              size: 16, color: Colors.red),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              state.errorMessage!,
                              style: const TextStyle(
                                  color: Colors.red, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // ── Botones de navegación ────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                    top: BorderSide(color: Color(0xFFEEEEEE))),
              ),
              child: Row(
                children: [
                  // Botón atrás (solo en step tienda)
                  if (!isEmpresaStep) ...[
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                            color: Color(0xFF2F3A8F)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        minimumSize: const Size(56, 50),
                      ),
                      onPressed: state.isLoading
                          ? null
                          : () => ref
                              .read(setupProvider.notifier)
                              .volverAEmpresa(),
                      child: const Icon(Icons.arrow_back_ios_new,
                          size: 18, color: Color(0xFF2F3A8F)),
                    ),
                    const SizedBox(width: 12),
                  ],

                  // Botón siguiente / finalizar
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2F3A8F),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        onPressed: state.isLoading
                            ? null
                            : () => _handleNext(state),
                        child: state.isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  Text(
                                    isEmpresaStep
                                        ? 'Siguiente'
                                        : 'Finalizar',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16),
                                  ),
                                  if (isEmpresaStep) ...[
                                    const SizedBox(width: 6),
                                    const Icon(
                                        Icons.arrow_forward_ios,
                                        size: 14,
                                        color: Colors.white),
                                  ],
                                ],
                              ),
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

  // ─── Formulario empresa ───────────────────────────────────────────────────

  Widget _buildEmpresaForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel('RUC *'),
        _inputField(
          controller: _rucController,
          hint: '20123456789',
          icon: Icons.numbers_outlined,
          keyboardType: TextInputType.number,
          maxLength: 11,
        ),
        const SizedBox(height: 16),
        _fieldLabel('Razón Social *'),
        _inputField(
          controller: _razonSocialController,
          hint: 'Ferretería Central S.A.C.',
          icon: Icons.business_outlined,
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 16),
        _fieldLabel('Nombre Comercial *'),
        _inputField(
          controller: _nombreComercialController,
          hint: 'Ferretería Central',
          icon: Icons.storefront_outlined,
          textCapitalization: TextCapitalization.words,
        ),
      ],
    );
  }

  // ─── Formulario tienda ────────────────────────────────────────────────────

  Widget _buildTiendaForm(SetupState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Empresa creada — badge informativo
        if (state.empresaCreada != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF2F3A8F).withOpacity(0.06),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle,
                    size: 16, color: Color(0xFF2F3A8F)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Empresa: ${state.empresaCreada!.nombreComercial}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF2F3A8F),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],

        _fieldLabel('Nombre de la sede *'),
        _inputField(
          controller: _nombreSedeController,
          hint: 'Sucursal Centro',
          icon: Icons.store_outlined,
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 16),
        _fieldLabel('Dirección *'),
        _inputField(
          controller: _direccionController,
          hint: 'Av. Principal 123',
          icon: Icons.location_on_outlined,
          textCapitalization: TextCapitalization.sentences,
        ),
        const SizedBox(height: 16),
        _fieldLabel('Ubigeo *'),
        _inputField(
          controller: _ubigeoController,
          hint: '040102',
          icon: Icons.map_outlined,
          keyboardType: TextInputType.number,
          maxLength: 6,
        ),

        const SizedBox(height: 20),

        // Series — en grid 3 columnas
        const Text(
          'Series de comprobantes',
          style: TextStyle(
              fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 4),
        const Text(
          'Máximo 4 caracteres cada una',
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: _serieField(
                controller: _serieFacturaController,
                label: 'Factura',
                hint: 'F001',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _serieField(
                controller: _serieBoletaController,
                label: 'Boleta',
                hint: 'B001',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _serieField(
                controller: _serieTicketController,
                label: 'Ticket',
                hint: 'T001',
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─── Helpers de UI ───────────────────────────────────────────────────────

  Widget _buildStepIndicator({
    required int index,
    required int currentIndex,
    required IconData icon,
    required String label,
  }) {
    final isCompleted = currentIndex > index;
    final isActive = currentIndex == index;

    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted || isActive
                ? const Color(0xFF2F3A8F)
                : const Color(0xFFE0E0E0),
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, color: Colors.white, size: 20)
                : Icon(icon,
                    color: isActive ? Colors.white : Colors.grey,
                    size: 20),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: isActive || isCompleted
                ? const Color(0xFF2F3A8F)
                : Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildStepConnector({
    required int currentIndex,
    required int stepIndex,
  }) {
    return Container(
      width: 48,
      height: 3,
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: currentIndex > stepIndex
            ? const Color(0xFF2F3A8F)
            : const Color(0xFFE0E0E0),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _fieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: const TextStyle(
            fontWeight: FontWeight.w600, fontSize: 14),
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
    int? maxLength,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      maxLength: maxLength,
      buildCounter: maxLength != null
          ? (_, {required currentLength, required isFocused, maxLength}) =>
              null
          : null,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: const Color(0xFFF6F7FB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _serieField({
    required TextEditingController controller,
    required String label,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLength: 4,
          textCapitalization: TextCapitalization.characters,
          buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: const Color(0xFFF6F7FB),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ],
    );
  }
}