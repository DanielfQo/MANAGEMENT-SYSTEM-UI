import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

/// Widget reutilizable que muestra el link de invitación generado.
/// Se usa como bottom sheet tanto en InvitationFormPage como en UsuariosPage.
///
/// Uso:
/// ```dart
/// InvitationLinkSheet.show(context, link: link, onClose: () { ... });
/// ```
class InvitationLinkSheet extends StatelessWidget {
  final String link;
  final VoidCallback? onClose;

  const InvitationLinkSheet({
    super.key,
    required this.link,
    this.onClose,
  });

  static Future<void> show(
    BuildContext context, {
    required String link,
    VoidCallback? onClose,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => InvitationLinkSheet(link: link, onClose: onClose),
    ).then((_) => onClose?.call());
  }

  void _share() {
    SharePlus.instance.share(
      ShareParams(
        text: '¡Te invito a unirte al sistema! Toca el link para completar tu registro:\n$link',
        subject: 'Invitación al sistema de gestión',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Handle ──────────────────────────────────────────────────
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // ── Ícono de éxito ──────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.green.withValues(alpha: 0.1),
            ),
            child: const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 40,
            ),
          ),

          const SizedBox(height: 16),

          const Text(
            '¡Invitación lista!',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 6),

          const Text(
            'Comparte el link con el nuevo colaborador',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 20),

          // ── Link ────────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF6F7FB),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              link,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF2F3A8F),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 20),

          // ── Botón compartir ─────────────────────────────────────────
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
              onPressed: _share,
              icon: const Icon(Icons.share, color: Colors.white),
              label: const Text(
                'Compartir Invitación',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ── Botón cerrar ────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 50,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cerrar',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}