import 'package:flutter/material.dart';
import 'package:management_system_ui/core/common_libs.dart';
import 'invitation_accept_provider.dart';

class _PasswordRequirement {
  final String label;
  final bool Function(String) test;
  const _PasswordRequirement({required this.label, required this.test});
}

const _requirements = [
  _PasswordRequirement(
    label: 'Al menos 8 caracteres',
    test: _hasMinLength,
  ),
  _PasswordRequirement(
    label: 'Al menos una mayúscula',
    test: _hasUppercase,
  ),
  _PasswordRequirement(
    label: 'Al menos una minúscula',
    test: _hasLowercase,
  ),
  _PasswordRequirement(
    label: 'Al menos un número',
    test: _hasNumber,
  ),
  _PasswordRequirement(
    label: 'Al menos un carácter especial',
    test: _hasSpecial,
  ),
];

bool _hasMinLength(String p) => p.length >= 8;
bool _hasUppercase(String p) => RegExp(r'[A-Z]').hasMatch(p);
bool _hasLowercase(String p) => RegExp(r'[a-z]').hasMatch(p);
bool _hasNumber(String p) => RegExp(r'\d').hasMatch(p);
bool _hasSpecial(String p) =>
    RegExp(r'[!@#$%^&*()\-_=+\[\]{};:,.<>?/\\|`~"' "'" r']').hasMatch(p);

class InvitationAcceptPage extends ConsumerStatefulWidget {
  final String? token;
  const InvitationAcceptPage({super.key, this.token});

  @override
  ConsumerState<InvitationAcceptPage> createState() =>
      _InvitationAcceptPageState();
}

class _InvitationAcceptPageState extends ConsumerState<InvitationAcceptPage> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String _password = '';
  String _confirm = '';

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(() =>
        setState(() => _password = _passwordController.text));
    _confirmController.addListener(() =>
        setState(() => _confirm = _confirmController.text));

    Future.microtask(() {
      ref.read(invitationAcceptProvider.notifier).validarToken(widget.token);
    });
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  int get _metCount =>
      _requirements.where((r) => r.test(_password)).length;

  double get _strengthPercent => _metCount / _requirements.length;

  Color get _strengthColor {
    if (_strengthPercent <= 0.4) return Colors.red;
    if (_strengthPercent <= 0.8) return Colors.orange;
    return const Color(0xFF2F3A8F);
  }

  String get _strengthLabel {
    if (_password.isEmpty) return '';
    if (_strengthPercent <= 0.4) return 'Débil';
    if (_strengthPercent <= 0.8) return 'Media';
    return 'Fuerte';
  }

  bool get _allMet => _metCount == _requirements.length;
  bool get _passwordsMatch => _password == _confirm && _confirm.isNotEmpty;

  void _submit() {
    if (widget.token == null) return;
    ref.read(invitationAcceptProvider.notifier).completarRegistro(
          token: widget.token!,
          password: _password,
          confirmarPassword: _confirm,
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(invitationAcceptProvider);

    ref.listen(invitationAcceptProvider, (prev, next) {
      if (next.status == InvitationAcceptStatus.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Registro completado! Ya puedes iniciar sesión.'),
            backgroundColor: Colors.green,
          ),
        );
        context.go('/login');
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFE9EEF6),
                ),
                child: const Icon(Icons.construction,
                    size: 40, color: Color(0xFF2F3A8F)),
              ),
              const SizedBox(height: 16),
              const Text('Ferretería Central',
                  style: TextStyle(
                      fontSize: 26, fontWeight: FontWeight.bold)),
              const Text('Gestión de Inventario y Ventas',
                  style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 25),

              if (state.status == InvitationAcceptStatus.validating)
                _buildValidating()
              else if (state.status == InvitationAcceptStatus.expired)
                _buildExpired(state.errorMessage)
              else
                _buildForm(state),

              const SizedBox(height: 15),
              const Text('Este link tiene una validez limitada',
                  style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildValidating() {
    return Container(
      width: 380,
      padding: const EdgeInsets.all(40),
      decoration: _cardDecoration(),
      child: const Column(
        children: [
          CircularProgressIndicator(color: Color(0xFF2F3A8F)),
          SizedBox(height: 20),
          Text('Verificando invitación...',
              style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildExpired(String? mensaje) {
    return Container(
      width: 380,
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.red.withValues(alpha: 0.1),
            ),
            child: const Icon(Icons.link_off, size: 36, color: Colors.red),
          ),
          const SizedBox(height: 16),
          const Text('Invitación no válida',
              style:
                  TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            mensaje ?? 'Este link ha expirado o ya fue utilizado.',
            style: const TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          const Text(
            'Contacta al administrador para recibir una nueva invitación.',
            style: TextStyle(color: Colors.grey, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildForm(InvitationAcceptState state) {
    final isLoading = state.status == InvitationAcceptStatus.loading;
    final canSubmit = _allMet && _passwordsMatch && !isLoading;

    return Container(
      width: 380,
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (state.username != null) ...[
            Center(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF2F3A8F).withValues(alpha: 0.1),
                ),
                child: const Icon(Icons.mark_email_read_outlined,
                    size: 36, color: Color(0xFF2F3A8F)),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text('¡Hola, ${state.username}!',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
            ),
            const Center(
              child: Text('Establece tu contraseña para acceder',
                  style: TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center),
            ),
            const SizedBox(height: 24),
          ],

          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              hintText: 'Nueva contraseña',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
              filled: true,
              fillColor: const Color(0xFFF6F7FB),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
            ),
          ),

          if (_password.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Seguridad',
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey)),
                Text(
                  _strengthLabel,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _strengthColor),
                ),
              ],
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _strengthPercent,
                minHeight: 6,
                backgroundColor: const Color(0xFFE0E0E0),
                valueColor:
                    AlwaysStoppedAnimation<Color>(_strengthColor),
              ),
            ),
          ],

          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF6F7FB),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Requisitos:',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 10),
                ..._requirements.map((req) {
                  final met = req.test(_password);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: met
                              ? const Icon(Icons.check_circle,
                                  key: ValueKey('check'),
                                  size: 18,
                                  color: Color(0xFF2F3A8F))
                              : Container(
                                  key: const ValueKey('circle'),
                                  width: 18,
                                  height: 18,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.grey.shade300,
                                        width: 2),
                                  ),
                                ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          req.label,
                          style: TextStyle(
                            fontSize: 13,
                            color: met
                                ? const Color(0xFF2F3A8F)
                                : Colors.grey,
                            fontWeight: met
                                ? FontWeight.w500
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: 16),

          TextField(
            controller: _confirmController,
            obscureText: _obscureConfirm,
            decoration: InputDecoration(
              hintText: 'Confirmar contraseña',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_obscureConfirm
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined),
                onPressed: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
              ),
              filled: true,
              fillColor: const Color(0xFFF6F7FB),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
            ),
          ),

          if (_confirm.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  _passwordsMatch ? Icons.check_circle : Icons.cancel,
                  size: 14,
                  color: _passwordsMatch ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 6),
                Text(
                  _passwordsMatch
                      ? 'Las contraseñas coinciden'
                      : 'Las contraseñas no coinciden',
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        _passwordsMatch ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 20),

          if (state.errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
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
            ),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: canSubmit
                    ? const Color(0xFF2F3A8F)
                    : Colors.grey.shade300,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onPressed: canSubmit ? _submit : null,
              child: isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      'Completar Registro',
                      style: TextStyle(
                        color: canSubmit ? Colors.white : Colors.grey,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 10,
          offset: const Offset(0, 4),
        )
      ],
    );
  }
}