import 'package:management_system_ui/core/common_libs.dart';
import 'package:management_system_ui/features/auth/auth_provider.dart';
import 'package:management_system_ui/features/tienda/tienda_switcher_sheet.dart';

/// AppBar unificado y consistente para todas las páginas
/// Incluye selector de tienda contextual para dueños (inline en el header)
/// Soporta botón de volver (onBack) y badge con contador
class CustomAppBar extends ConsumerWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isTiendaTitle;
  final VoidCallback? onBack;
  final String? badge;
  final Widget? trailing;
  final VoidCallback? onTiendaPressed;

  const CustomAppBar({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.isTiendaTitle = false,
    this.onBack,
    this.badge,
    this.trailing,
    this.onTiendaPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final userMe = authState.userMe;
    final esDueno = userMe?.isDueno ?? false;

    // Obtener nombre de la tienda actual
    String tiendaNombre = 'Tienda';
    if (isTiendaTitle && userMe != null && userMe.tiendas.isNotEmpty) {
      try {
        final tiendaActual = userMe.tiendas
            .firstWhere((t) => t.tiendaId == authState.selectedTiendaId);
        tiendaNombre = tiendaActual.tiendaNombre;
      } catch (e) {
        // Si no encuentra la tienda, usar la primera
        tiendaNombre = userMe.tiendas.first.tiendaNombre;
      }
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          if (onBack != null)
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: onBack,
            )
          else
            GestureDetector(
              onTap: (isTiendaTitle && esDueno) ? onTiendaPressed : null,
              child: CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primary,
                child: Icon(icon, color: Colors.white),
              ),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: (isTiendaTitle && esDueno) ? onTiendaPressed : null,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isTiendaTitle ? tiendaNombre : title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (badge != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                badge!,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                  fontSize: 13,
                ),
              ),
            ),
          // Selector de tienda para dueños (si isTiendaTitle=true)
          if (esDueno && isTiendaTitle) ...[
            const SizedBox(width: 12),
            _TiendaSelectorCompact(onPressed: onTiendaPressed),
          ],
          if (trailing != null)
            trailing!
          else if (onBack == null) ...[
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.notifications_none),
            ),
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.person_outline),
            ),
          ],
        ],
      ),
    );
  }
}

/// Widget compacto que muestra icono de tienda y permite cambiarla
class _TiendaSelectorCompact extends StatelessWidget {
  final VoidCallback? onPressed;

  const _TiendaSelectorCompact({this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Tooltip(
        message: 'Cambiar tienda',
        child: IconButton(
          icon: const Icon(Icons.store_outlined),
          onPressed: onPressed ?? () => showTiendaSwitcher(context),
        ),
      ),
    );
  }
}
