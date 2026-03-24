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

  const CustomAppBar({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.isTiendaTitle = false,
    this.onBack,
    this.badge,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userMe = ref.watch(authProvider).userMe;
    final esDueno = userMe?.isDueno ?? false;
    final showSelector = esDueno && isTiendaTitle;

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
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.primary,
              child: Icon(icon, color: Colors.white),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: showSelector
                ? _TiendaSelectorDropdown()
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
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
          if (onBack == null) ...[
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

/// Widget que muestra y permite cambiar la tienda actual (inline en AppBar)
class _TiendaSelectorDropdown extends ConsumerWidget {
  const _TiendaSelectorDropdown();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final selectedId = authState.selectedTiendaId;
    final userTiendas = authState.userMe?.tiendas ?? [];

    final tiendaNombre = userTiendas.isEmpty
        ? null
        : userTiendas
                .where((t) => t.tiendaId == selectedId)
                .firstOrNull
                ?.tiendaNombre ??
            userTiendas.first.tiendaNombre;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => showTiendaSwitcher(context),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.lightBackground,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppColors.secondary.withValues(alpha: 0.15),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.store,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tienda Actual',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      tiendaNombre ?? 'Sin tienda',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
