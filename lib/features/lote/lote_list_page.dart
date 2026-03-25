import 'package:management_system_ui/core/common_libs.dart';
import 'package:management_system_ui/features/auth/auth_provider.dart';
import 'lote_provider.dart';
import 'models/lote_response_model.dart';

class LoteListPage extends ConsumerStatefulWidget {
  const LoteListPage({super.key});

  @override
  ConsumerState<LoteListPage> createState() => _LoteListPageState();
}

class _LoteListPageState extends ConsumerState<LoteListPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(inventarioProvider.notifier).cargarLotes(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(inventarioProvider);
    final isDueno = ref.watch(authProvider).userMe?.isDueno ?? false;
    final lotes = state.lotes;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      body: SafeArea(
        child: Column(
          children: [
            CustomAppBar(
              title: 'Lotes',
              subtitle: 'Historial de recepciones',
              icon: Icons.inbox,
              onBack: () => context.go('/lotes'),
              badge: lotes.length.toString(),
            ),
            Expanded(
              child: state.isLoading && lotes.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF2F3A8F),
                      ),
                    )
                  : state.errorMessage != null && lotes.isEmpty
                      ? ErrorState(
                          mensaje: state.errorMessage!,
                          onRetry: () => ref
                              .read(inventarioProvider.notifier)
                              .cargarLotes(),
                        )
                      : lotes.isEmpty
                          ? const EmptyState(
                              icon: Icons.inbox_outlined,
                              titulo: 'Sin lotes',
                              subtitulo:
                                  'No hay lotes registrados en esta tienda',
                            )
                          : RefreshIndicator(
                              color: const Color(0xFF2F3A8F),
                              onRefresh: () =>
                                  ref.read(inventarioProvider.notifier).cargarLotes(),
                              child: GridView.builder(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 16, 16, 16),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: 0.8,
                                ),
                                itemCount: lotes.length,
                                itemBuilder: (context, index) {
                                  final lote = lotes[index];
                                  return _LoteCard(
                                    lote: lote,
                                    isDueno: isDueno,
                                    onDesactivar: () =>
                                        _mostrarConfirmacion(context, lote.id),
                                  );
                                },
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarConfirmacion(BuildContext context, int loteId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.amber[700],
              size: 28,
            ),
            const SizedBox(width: 12),
            const Text('Desactivar lote'),
          ],
        ),
        content: const Text(
          'El lote será desactivado. Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ref
                  .read(inventarioProvider.notifier)
                  .desactivarLote(loteId);
            },
            child: const Text('Desactivar',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _LoteCard extends StatelessWidget {
  final LoteResponse lote;
  final bool isDueno;
  final VoidCallback onDesactivar;

  const _LoteCard({
    required this.lote,
    required this.isDueno,
    required this.onDesactivar,
  });

  @override
  Widget build(BuildContext context) {
    final costoTotal = (double.tryParse(lote.costoOperacion) ?? 0) +
        (double.tryParse(lote.costoTransporte) ?? 0);

    return GestureDetector(
      onTap: () => context.go('/lotes/${lote.id}'),
      child: Container(
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con badge
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: lote.isActive
                    ? const Color(0xFF2F3A8F).withValues(alpha: 0.08)
                    : Colors.red.withValues(alpha: 0.08),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Lote #${lote.id}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2F3A8F),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        lote.tienda.nombreSede,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  StatusBadge(
                    label: lote.isActive ? 'Activo' : 'Inactivo',
                    color: lote.isActive ? Colors.green : Colors.red,
                  ),
                ],
              ),
            ),
            // Contenido principal
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Información del lote
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              lote.fechaLlegada,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.shopping_bag_outlined,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${lote.productos.length} producto${lote.productos.length != 1 ? 's' : ''}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    // Costo
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2F3A8F).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Costo total',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            'S/. ${costoTotal.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2F3A8F),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Footer con botones
            if (isDueno)
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.grey[200]!),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => context.go('/lotes/${lote.id}'),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.visibility_outlined,
                                size: 16,
                                color: const Color(0xFF2F3A8F),
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'Ver',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF2F3A8F),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: 1,
                      color: Colors.grey[200],
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: onDesactivar,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(
                                Icons.block_outlined,
                                size: 16,
                                color: Colors.red,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Desactivar',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.red,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
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
}
