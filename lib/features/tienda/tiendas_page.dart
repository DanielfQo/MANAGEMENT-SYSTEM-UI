import 'package:management_system_ui/core/common_libs.dart';
import 'package:management_system_ui/features/auth/auth_provider.dart';
import 'package:management_system_ui/features/tienda/tienda_edit_sheet.dart';
import 'tienda_provider.dart';

class TiendasPage extends ConsumerStatefulWidget {
  const TiendasPage({super.key});

  @override
  ConsumerState<TiendasPage> createState() => _TiendasPageState();
}

class _TiendasPageState extends ConsumerState<TiendasPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(tiendaProvider.notifier).cargarTiendas());
  }

  @override
  Widget build(BuildContext context) {
    final tiendaState = ref.watch(tiendaProvider);
    final selectedId = ref.watch(authProvider).selectedTiendaId;

    return Scaffold(
      backgroundColor: const Color(0xfff3f4f6),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header con CustomAppBar ────────────────────────────────────
            CustomAppBar(
              title: 'Mis Tiendas',
              subtitle: 'Administra tus sucursales',
              icon: Icons.store_outlined,
              isTiendaTitle: false,
              onBack: () => context.go('/home'),
              badge: '${tiendaState.tiendas.length}',
            ),

            const SizedBox(height: 12),

            // ── Lista de tiendas ──────────────────────────────────────────
            Expanded(
              child: Builder(builder: (_) {
                if (tiendaState.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xff1f2a7c)),
                  );
                }
                if (tiendaState.errorMessage != null) {
                  return Center(child: Text(tiendaState.errorMessage!));
                }
                if (tiendaState.tiendas.isEmpty) {
                  return const Center(child: Text('No hay tiendas registradas'));
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: tiendaState.tiendas.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final tienda = tiendaState.tiendas[index];
                    final isActive = tienda.id == selectedId;

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          )
                        ],
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: const Color(0xff1f2a7c)
                                .withValues(alpha: 0.1),
                            child: Text(
                              tienda.nombreSede.isNotEmpty
                                  ? tienda.nombreSede[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xff1f2a7c),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        tienda.nombreSede,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                                    if (isActive)
                                      Container(
                                        padding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade50,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                            color: Colors.green.shade300,
                                            width: 0.5,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.check_circle,
                                                size: 12,
                                                color:
                                                    Colors.green.shade600),
                                            const SizedBox(width: 3),
                                            Text(
                                              'Activa',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight:
                                                    FontWeight.w600,
                                                color: Colors.green
                                                    .shade600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  tienda.direccion,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert),
                            onSelected: (value) {
                              if (value == 'editar') {
                                showTiendaEditSheet(context, tienda);
                              } else if (value == 'desactivar') {
                                _confirmarDesactivar(context,
                                    tienda.id, tienda.nombreSede);
                              }
                            },
                            itemBuilder: (_) => [
                              const PopupMenuItem(
                                value: 'editar',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit_outlined, size: 18),
                                    SizedBox(width: 8),
                                    Text('Editar'),
                                  ],
                                ),
                              ),
                              if (!isActive)
                                const PopupMenuItem(
                                  value: 'desactivar',
                                  child: Row(
                                    children: [
                                      Icon(Icons.block_outlined,
                                          size: 18, color: Colors.red),
                                      SizedBox(width: 8),
                                      Text('Desactivar',
                                          style: TextStyle(
                                              color: Colors.red)),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/tiendas/form'),
        backgroundColor: const Color(0xff1f2a7c),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _confirmarDesactivar(
      BuildContext context, int id, String nombre) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Desactivar tienda'),
        content: Text(
            '¿Estás seguro de que deseas desactivar "$nombre"? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(tiendaProvider.notifier).desactivarTienda(id);
            },
            child: const Text('Desactivar',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}