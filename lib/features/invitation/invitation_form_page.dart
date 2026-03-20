import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:management_system_ui/core/common_libs.dart';
import 'invitation_provider.dart';
import 'models/store_model.dart';
import 'models/role_model.dart';
import 'package:go_router/go_router.dart';
import 'package:management_system_ui/core/constants/constants.dart';

class InvitationFormPage extends ConsumerStatefulWidget {
  const InvitationFormPage({super.key});

  @override
  ConsumerState<InvitationFormPage> createState() => _InvitationFormPageState();
}

class _InvitationFormPageState extends ConsumerState<InvitationFormPage> {
  final _emailController = TextEditingController();
  final _salarioController = TextEditingController();

  StoreModel? _selectedTienda;
  RoleModel? _selectedRol;

  // Roles que requieren tienda y salario
  bool get _requiresExtra =>
    _selectedRol != null &&
    Roles.requiresStore.contains(_selectedRol!.value);

  @override
  void dispose() {
    _emailController.dispose();
    _salarioController.dispose();
    super.dispose();
  }

  void _submit() {
    final email = _emailController.text.trim();

    if (email.isEmpty || _selectedRol == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa todos los campos requeridos')),
      );
      return;
    }

    if (_requiresExtra && _selectedTienda == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una tienda para este rol')),
      );
      return;
    }

    ref.read(invitationProvider.notifier).enviarInvitacion(
          email: email,
          tiendaId: _selectedTienda?.id,
          rol: _selectedRol!.value,
          salario: _requiresExtra ? _salarioController.text.trim() : '0.00',
        );
  }

  void _shareLink(String link) {
    Share.share(
      '¡Te invito a unirte al sistema! Toca el link para completar tu registro:\n$link',
      subject: 'Invitación al sistema de gestión',
    );
  }

  void _reset() {
    ref.read(invitationProvider.notifier).reset();
    _emailController.clear();
    _salarioController.clear();
    setState(() {
      _selectedTienda = null;
      _selectedRol = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final invitationState = ref.watch(invitationProvider);
    final tiendasAsync = ref.watch(tiendasProvider);
    final rolesAsync = ref.watch(rolesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2F4F7),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF2F3A8F)),
          onPressed: () => context.go('/home')
        ),
        title: const Text(
          'Invitar Usuario',
          style: TextStyle(
            color: Color(0xFF2F3A8F),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            /// ÍCONO SUPERIOR
            Container(
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFE9EEF6),
              ),
              child: const Icon(
                Icons.person_add_alt_1,
                size: 40,
                color: Color(0xFF2F3A8F),
              ),
            ),

            const SizedBox(height: 16),

            const Text(
              'Nuevo Colaborador',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 6),

            const Text(
              'El usuario recibirá un link para completar su registro',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),

            // ── FORMULARIO O RESULTADO ──────────────────────────────────
            if (!invitationState.isSuccess) ...[
              _buildForm(tiendasAsync, rolesAsync, invitationState),
            ] else ...[
              _buildSuccess(invitationState.invitationLink!),
            ],
          ],
        ),
      ),
    );
  }

  // ─── FORMULARIO ────────────────────────────────────────────────────────────

  Widget _buildForm(
    AsyncValue<List<StoreModel>> tiendasAsync,
    AsyncValue<List<RoleModel>> rolesAsync,
    InvitationState invitationState,
  ) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Datos del nuevo usuario',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),

          const SizedBox(height: 20),

          /// EMAIL
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              hintText: 'Correo electrónico',
              prefixIcon: const Icon(Icons.email_outlined),
              filled: true,
              fillColor: const Color(0xFFF6F7FB),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
            ),
          ),

          const SizedBox(height: 15),

          /// ROL
          rolesAsync.when(
            loading: () => _dropdownSkeleton('Cargando roles...'),
            error: (_, __) => _dropdownSkeleton('Error al cargar roles'),
            data: (roles) => _buildDropdown<RoleModel>(
              hint: 'Selecciona un rol',
              icon: Icons.badge_outlined,
              value: _selectedRol,
              items: roles,
              itemLabel: (r) => r.label,
              onChanged: (r) => setState(() {
                _selectedRol = r;
                _selectedTienda = null; // resetear tienda al cambiar rol
              }),
            ),
          ),

          /// TIENDA Y SALARIO (solo si requiere)
          if (_requiresExtra) ...[
            const SizedBox(height: 15),

            tiendasAsync.when(
              loading: () => _dropdownSkeleton('Cargando tiendas...'),
              error: (_, __) => _dropdownSkeleton('Error al cargar tiendas'),
              data: (tiendas) => _buildDropdown<StoreModel>(
                hint: 'Selecciona una tienda',
                icon: Icons.store_outlined,
                value: _selectedTienda,
                items: tiendas,
                itemLabel: (t) => t.nombreSede,
                onChanged: (t) => setState(() => _selectedTienda = t),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: _salarioController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: 'Salario (ej: 1500.00)',
                prefixIcon: const Icon(Icons.attach_money_outlined),
                filled: true,
                fillColor: const Color(0xFFF6F7FB),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],

          const SizedBox(height: 24),

          /// BOTÓN
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2F3A8F),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onPressed: invitationState.isLoading ? null : _submit,
              child: invitationState.isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Generar Invitación',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
            ),
          ),

          if (invitationState.errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                invitationState.errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
        ],
      ),
    );
  }

  // ─── RESULTADO / LINK GENERADO ─────────────────────────────────────────────

  Widget _buildSuccess(String link) {
    return Container(
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
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.green.withOpacity(0.1),
            ),
            child: const Icon(Icons.check_circle, color: Colors.green, size: 40),
          ),

          const SizedBox(height: 16),

          const Text(
            '¡Invitación lista!',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 8),

          const Text(
            'Comparte el link con el nuevo colaborador',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 20),

          /// LINK
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF6F7FB),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              link,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF2F3A8F),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 20),

          /// BOTON COMPARTIR
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2F3A8F),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onPressed: () => _shareLink(link),
              icon: const Icon(Icons.share, color: Colors.white),
              label: const Text(
                'Compartir Invitación',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),

          const SizedBox(height: 12),

          /// BOTON NUEVA INVITACION
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF2F3A8F)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onPressed: _reset,
              child: const Text(
                'Nueva Invitación',
                style: TextStyle(color: Color(0xFF2F3A8F), fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── HELPERS ───────────────────────────────────────────────────────────────

  Widget _buildDropdown<T>({
    required String hint,
    required IconData icon,
    required T? value,
    required List<T> items,
    required String Function(T) itemLabel,
    required void Function(T?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F7FB),
        borderRadius: BorderRadius.circular(30),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          hint: Row(
            children: [
              Icon(icon, color: Colors.grey),
              const SizedBox(width: 12),
              Text(hint, style: const TextStyle(color: Colors.grey)),
            ],
          ),
          items: items
              .map((item) => DropdownMenuItem<T>(
                    value: item,
                    child: Text(itemLabel(item)),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _dropdownSkeleton(String label) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F7FB),
        borderRadius: BorderRadius.circular(30),
      ),
      alignment: Alignment.centerLeft,
      child: Text(label, style: const TextStyle(color: Colors.grey)),
    );
  }
}