import 'package:management_system_ui/core/common_libs.dart';
import 'package:management_system_ui/core/models/store_model.dart';
import 'tienda_provider.dart';

class TiendaEditSheet extends ConsumerStatefulWidget {
  final StoreModel tienda;
  const TiendaEditSheet({super.key, required this.tienda});

  @override
  ConsumerState<TiendaEditSheet> createState() => _TiendaEditSheetState();
}

class _TiendaEditSheetState extends ConsumerState<TiendaEditSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _direccionCtrl;
  late final TextEditingController _ubigeoCtrl;

  bool get _tieneCambios =>
      _nombreCtrl.text.trim() != widget.tienda.nombreSede ||
      _direccionCtrl.text.trim() != widget.tienda.direccion ||
      _ubigeoCtrl.text.trim() != widget.tienda.ubigeo;

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController(text: widget.tienda.nombreSede);
    _direccionCtrl = TextEditingController(text: widget.tienda.direccion);
    _ubigeoCtrl = TextEditingController(text: widget.tienda.ubigeo);
    _nombreCtrl.addListener(() => setState(() {}));
    _direccionCtrl.addListener(() => setState(() {}));
    _ubigeoCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _direccionCtrl.dispose();
    _ubigeoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(tiendaProvider).isLoading;

    return Padding(
      // Sube el sheet cuando aparece el teclado
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Editar Tienda',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              _buildField(
                controller: _nombreCtrl,
                label: 'Nombre de la sede',
                icon: Icons.store_outlined,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 14),
              _buildField(
                controller: _direccionCtrl,
                label: 'Dirección',
                icon: Icons.location_on_outlined,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 14),
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
              const SizedBox(height: 24),
              ElevatedButton(
                // Deshabilitado si no hay cambios o está cargando
                onPressed: (!_tieneCambios || isLoading) ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff1f2a7c),
                  disabledBackgroundColor: Colors.grey.shade300,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        _tieneCambios ? 'Guardar cambios' : 'Sin cambios',
                        style: TextStyle(
                          color: _tieneCambios ? Colors.white : Colors.grey,
                          fontSize: 15,
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
        fillColor: const Color(0xfff8f8f8),
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    await ref.read(tiendaProvider.notifier).actualizarTienda(
          id: widget.tienda.id,
          nombreSede: _nombreCtrl.text.trim(),
          direccion: _direccionCtrl.text.trim(),
          ubigeo: _ubigeoCtrl.text.trim(),
        );

    if (!mounted) return;

    final error = ref.read(tiendaProvider).errorMessage;

    if (error != null) {
      ref.read(tiendaProvider.notifier).resetError();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
      return;
    }

    ref.read(tiendaProvider.notifier).resetSuccess();
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tienda actualizada correctamente'),
        backgroundColor: Colors.green,
      ),
    );
  }
}

// Helper
void showTiendaEditSheet(BuildContext context, StoreModel tienda) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => TiendaEditSheet(tienda: tienda),
  );
}