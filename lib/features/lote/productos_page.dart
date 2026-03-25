import 'package:management_system_ui/core/common_libs.dart';
import 'package:management_system_ui/features/auth/auth_provider.dart';
import 'lote_provider.dart';
import 'models/producto_model.dart';
import 'models/stock_model.dart';
import 'constants/unidad_medida.dart';
import 'widgets/producto_detail_sheet.dart';

class ProductosPage extends ConsumerStatefulWidget {
  const ProductosPage({super.key});

  @override
  ConsumerState<ProductosPage> createState() => _ProductosPageState();
}

class _ProductosPageState extends ConsumerState<ProductosPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () {
        ref.read(inventarioProvider.notifier).cargarProductos();
        ref.read(inventarioProvider.notifier).cargarStock();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDueno = ref.watch(authProvider).userMe?.isDueno ?? false;
    final state = ref.watch(inventarioProvider);
    final productos = state.productos;
    final stock = state.stock;

    // Crear mapa de stock para búsqueda rápida: productoId -> StockModel
    final stockMap = {
      for (final s in stock) s.productoId: s,
    };

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      body: SafeArea(
        child: Column(
          children: [
            CustomAppBar(
              title: 'Catálogo de Productos',
              subtitle: 'Productos y disponibilidad',
              icon: Icons.inventory,
              onBack: () => context.go('/lotes'),
            ),
            Expanded(
              child: state.isLoading && productos.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF2F3A8F),
                      ),
                    )
                  : state.errorMessage != null && productos.isEmpty
                      ? ErrorState(
                          mensaje: state.errorMessage!,
                          onRetry: () {
                            ref
                                .read(inventarioProvider.notifier)
                                .cargarProductos();
                            ref
                                .read(inventarioProvider.notifier)
                                .cargarStock();
                          },
                        )
                      : productos.isEmpty
                          ? const EmptyState(
                              icon: Icons.inventory_outlined,
                              titulo: 'Sin productos',
                              subtitulo:
                                  'No hay productos en el catálogo',
                            )
                          : RefreshIndicator(
                              color: const Color(0xFF2F3A8F),
                              onRefresh: () async {
                                await ref
                                    .read(inventarioProvider.notifier)
                                    .cargarProductos();
                                await ref
                                    .read(inventarioProvider.notifier)
                                    .cargarStock();
                              },
                              child: GridView.builder(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 16, 16, 16),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: 0.75,
                                ),
                                itemCount: productos.length,
                                itemBuilder: (context, index) {
                                  final producto = productos[index];
                                  final productoStock =
                                      stockMap[producto.id];
                                  return _ProductoGridCard(
                                    producto: producto,
                                    stock: productoStock,
                                    isDueno: isDueno,
                                    onTap: () {
                                      _mostrarDetalleModal(
                                        context,
                                        producto,
                                        productoStock,
                                        isDueno,
                                      );
                                    },
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

  void _mostrarDetalleModal(
    BuildContext context,
    ProductoModel producto,
    StockModel? stock,
    bool isDueno,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProductoDetailSheet(
        producto: producto,
        stock: stock,
        isDueno: isDueno,
      ),
    );
  }
}

class _ProductoGridCard extends StatelessWidget {
  final ProductoModel producto;
  final StockModel? stock;
  final bool isDueno;
  final VoidCallback onTap;

  const _ProductoGridCard({
    required this.producto,
    this.stock,
    required this.isDueno,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tieneDisponibilidad = stock != null &&
        (double.tryParse(stock!.cantidadDisponible) ?? 0) > 0;

    return GestureDetector(
      onTap: onTap,
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
            // Imagen
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F4F7),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    producto.imagen != null && producto.imagen!.isNotEmpty
                        ? ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                            ),
                            child: Image.network(
                              producto.imagen!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Center(
                                  child: Icon(
                                    Icons.image_not_supported,
                                    size: 32,
                                    color: Colors.grey[400],
                                  ),
                                );
                              },
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress
                                                .expectedTotalBytes !=
                                            null
                                        ? loadingProgress
                                                .cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                );
                              },
                            ),
                          )
                        : Center(
                            child: Icon(
                              Icons.image_not_supported,
                              size: 32,
                              color: Colors.grey[400],
                            ),
                          ),
                    // Badge de disponibilidad
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: tieneDisponibilidad
                              ? Colors.green
                              : Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          tieneDisponibilidad
                              ? 'En stock'
                              : 'Sin stock',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          producto.nombre,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          producto.codigo,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                        if (stock != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              '${stock!.cantidadDisponible} ${UnidadMedida.getLabel(stock!.unidadMedida)}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF2F3A8F),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    StatusBadge(
                      label:
                          producto.isActive ? 'Activo' : 'Inactivo',
                      color: producto.isActive ? Colors.green : Colors.red,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
