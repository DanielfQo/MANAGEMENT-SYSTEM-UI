import 'package:management_system_ui/core/common_libs.dart';
import 'package:management_system_ui/core/models/store_model.dart';
import 'package:management_system_ui/features/onboarding/setup_repository.dart';
import 'tienda_provider.dart';

class TiendaFormPage extends ConsumerStatefulWidget {
  final StoreModel? tiendaExistente; // null = crear, !null = editar

  const TiendaFormPage({super.key, this.tiendaExistente});

  @override
  ConsumerState<TiendaFormPage> createState() => _TiendaFormPageState();
}

class _TiendaFormPageState extends ConsumerState<TiendaFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _direccionCtrl;
  late final TextEditingController _ubigeoCtrl;

  // Solo para creación
  final _serieFacturaCtrl = TextEditingController();
  final _serieBoletaCtrl = TextEditingController();
  final _serieTicketCtrl = TextEditingController();

  bool get _esEdicion => widget.tiendaExistente != null;

  @override
  void initState() {
    super.initState();
    final t = widget.tiendaExistente;
    _nombreCtrl = TextEditingController(text: t?.nombreSede ?? '');
    _direccionCtrl = TextEditingController(text: t?.direccion ?? '');
    _ubigeoCtrl = TextEditingController(text: t?.ubigeo ?? '');

    // Pre-llenar series con sugerencias si es creación
    if (!_esEdicion) {
      Future.microtask(() {
        final tiendas = ref.read(tiendaProvider).tiendas;
        _sugerirSeries(tiendas);
      });
    }
  }

  /// Calcula la siguiente serie secuencial basada en las tiendas existentes
  void _sugerirSeries(List<StoreModel> tiendas) {
    if (tiendas.isEmpty) {
      // Si no hay tiendas, sugerir las primeras series
      _serieFacturaCtrl.text = 'F001';
      _serieBoletaCtrl.text = 'B001';
      _serieTicketCtrl.text = 'T001';
      return;
    }

    // Extraer el número máximo de cada serie y sugerir el siguiente
    _serieFacturaCtrl.text = _obtenerSiguienteSerie(
      tiendas.map((t) => t.serieFactura).toList(),
      'F',
    );
    _serieBoletaCtrl.text = _obtenerSiguienteSerie(
      tiendas.map((t) => t.serieBoleta).toList(),
      'B',
    );
    _serieTicketCtrl.text = _obtenerSiguienteSerie(
      tiendas.map((t) => t.serieTicket).toList(),
      'T',
    );
  }

  /// Obtiene la siguiente serie secuencial (ej: F001 -> F002)
  String _obtenerSiguienteSerie(List<String> seriesExistentes, String prefijo) {
    int maxNum = 0;

    for (final serie in seriesExistentes) {
      // Extraer número de la serie (ej: "F001" -> 1)
      final match = RegExp(r'(\d+)').firstMatch(serie);
      if (match != null) {
        final num = int.tryParse(match.group(1) ?? '0') ?? 0;
        maxNum = maxNum < num ? num : maxNum;
      }
    }

    // Retornar siguiente número con formato (ej: 1 -> F002)
    return '$prefijo${(maxNum + 1).toString().padLeft(3, '0')}';
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _direccionCtrl.dispose();
    _ubigeoCtrl.dispose();
    _serieFacturaCtrl.dispose();
    _serieBoletaCtrl.dispose();
    _serieTicketCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tiendaState = ref.watch(tiendaProvider);

    ref.listen(tiendaProvider, (_, next) {
      if (next.isSuccess) {
        ref.read(tiendaProvider.notifier).resetSuccess();
        context.go('/tiendas');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tienda creada correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: Colors.red,
          ),
        );
        ref.read(tiendaProvider.notifier).resetError();
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xfff3f4f6),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header con CustomAppBar ────────────────────────────────────
              CustomAppBar(
                title: _esEdicion ? 'Editar Tienda' : 'Nueva Tienda',
                subtitle: 'Completa los datos de la tienda',
                icon: Icons.store_outlined,
                isTiendaTitle: false,
                onBack: () => context.go('/tiendas'),
              ),

              const SizedBox(height: 20),

              // ── Form ────────────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
              _buildField(
                controller: _nombreCtrl,
                label: 'Nombre de la sede',
                icon: Icons.store_outlined,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 16),
              _buildField(
                controller: _direccionCtrl,
                label: 'Dirección',
                icon: Icons.location_on_outlined,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 16),
              _buildField(
                controller: _ubigeoCtrl,
                label: 'Ubigeo (6 dígitos)',
                icon: Icons.map_outlined,
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Campo requerido';
                  if (v.length != 6) return 'Debe tener exactamente 6 dígitos';
                  return null;
                },
              ),

              // Campos extra solo para creación
              if (!_esEdicion) ...[
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Text(
                      'Series de comprobantes',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(width: 8),
                    Tooltip(
                      message:
                          'Las series deben ser secuenciales para evitar colisiones en SUNAT. Se sugieren automáticamente.',
                      child: Icon(Icons.info_outline,
                          size: 18, color: Colors.grey.shade600),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildSeriesField(
                  controller: _serieFacturaCtrl,
                  label: 'Serie Factura',
                  icon: Icons.receipt_long_outlined,
                  hint: 'F001',
                  tooltip:
                      'Formato: Letra + 3 dígitos. Ej: F001, F002, etc.\nEvita colisiones secuenciales.',
                ),
                const SizedBox(height: 16),
                _buildSeriesField(
                  controller: _serieBoletaCtrl,
                  label: 'Serie Boleta',
                  icon: Icons.receipt_outlined,
                  hint: 'B001',
                  tooltip:
                      'Formato: Letra + 3 dígitos. Ej: B001, B002, etc.\nEvita colisiones secuenciales.',
                ),
                const SizedBox(height: 16),
                _buildSeriesField(
                  controller: _serieTicketCtrl,
                  label: 'Serie Ticket',
                  icon: Icons.confirmation_number_outlined,
                  hint: 'T001',
                  tooltip:
                      'Formato: Letra + 3 dígitos. Ej: T001, T002, etc.\nEvita colisiones secuenciales.',
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.lightbulb_outline,
                          size: 18, color: Colors.blue),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Las series se sugieren automáticamente basadas en las tiendas existentes para evitar duplicados.',
                          style: TextStyle(fontSize: 12, color: Colors.blue),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: tiendaState.isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff1f2a7c),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: tiendaState.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        _esEdicion ? 'Guardar cambios' : 'Crear tienda',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 16),
                      ),
              ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xff1f2a7c)),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xff1f2a7c)),
        ),
      ),
    );
  }

  Widget _buildSeriesField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: TextFormField(
        controller: controller,
        textCapitalization: TextCapitalization.characters,
        validator: (v) {
          if (v == null || v.isEmpty) return 'Campo requerido';
          // Validar formato: Letra + 3 dígitos
          if (!RegExp(r'^[A-Z]\d{3}$').hasMatch(v)) {
            return 'Formato: Letra + 3 dígitos (ej: F001)';
          }
          return null;
        },
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: const Color(0xff1f2a7c)),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xff1f2a7c)),
          ),
          helperText: 'Sugerido automáticamente',
          helperStyle: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_esEdicion) {
      await ref.read(tiendaProvider.notifier).actualizarTienda(
            id: widget.tiendaExistente!.id,
            nombreSede: _nombreCtrl.text.trim(),
            direccion: _direccionCtrl.text.trim(),
            ubigeo: _ubigeoCtrl.text.trim(),
          );
    } else {
      // Necesitamos el empresaId — lo sacamos del SetupRepository
      final setupRepo = ref.read(setupRepositoryProvider);
      final empresas = await setupRepo.getEmpresas();
      if (!mounted) return;
      if (empresas.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Debes crear una empresa antes de agregar tiendas'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      await ref.read(tiendaProvider.notifier).crearTienda(
            nombreSede: _nombreCtrl.text.trim(),
            direccion: _direccionCtrl.text.trim(),
            ubigeo: _ubigeoCtrl.text.trim(),
            serieFactura: _serieFacturaCtrl.text.trim(),
            serieBoleta: _serieBoletaCtrl.text.trim(),
            serieTicket: _serieTicketCtrl.text.trim(),
            empresaId: empresas.first.id,
          );
    }
  }
}