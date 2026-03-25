import 'package:flutter/material.dart';
import 'package:management_system_ui/core/common_libs.dart';
import 'package:management_system_ui/features/auth/auth_provider.dart';
import 'tienda_provider.dart';

class TiendaSwitcherSheet extends ConsumerStatefulWidget {
  const TiendaSwitcherSheet({super.key});

  @override
  ConsumerState<TiendaSwitcherSheet> createState() =>
      _TiendaSwitcherSheetState();
}

class _TiendaSwitcherSheetState extends ConsumerState<TiendaSwitcherSheet> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(tiendaProvider.notifier).cargarTiendas());
  }

  @override
  Widget build(BuildContext context) {
    final tiendaState = ref.watch(tiendaProvider);
    final selectedId = ref.watch(authProvider).selectedTiendaId;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
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

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Mis Tiendas',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: () {
                  Navigator.pop(context);
                  context.go('/tiendas');
                },
                tooltip: 'Gestionar tiendas',
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Lista de tiendas
          if (tiendaState.isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(
                  color: Color(0xff1f2a7c),
                ),
              ),
            )
          else if (tiendaState.errorMessage != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                tiendaState.errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            )
          else
            ...tiendaState.tiendas.map((tienda) {
              final isActive = tienda.id == selectedId;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xff1f2a7c)
                        : const Color(0xff1f2a7c).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.store_outlined,
                    color: isActive ? Colors.white : const Color(0xff1f2a7c),
                    size: 20,
                  ),
                ),
                title: Text(
                  tienda.nombreSede,
                  style: TextStyle(
                    fontWeight:
                        isActive ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                subtitle: Text(
                  tienda.direccion,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: isActive
                    ? const Icon(Icons.check_circle,
                        color: Color(0xff1f2a7c))
                    : null,
                onTap: () async {
                  await ref
                      .read(authProvider.notifier)
                      .selectTienda(tienda.id);
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                },
              );
            }),

        ],
      ),
    );
  }
}

// Helper para abrir el sheet fácilmente
void showTiendaSwitcher(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const TiendaSwitcherSheet(),
  );
}