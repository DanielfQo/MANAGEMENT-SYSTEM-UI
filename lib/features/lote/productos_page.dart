import 'package:management_system_ui/core/common_libs.dart';
import 'package:management_system_ui/features/auth/auth_provider.dart';
import 'lote_provider.dart';
import 'models/producto_model.dart';
import 'models/stock_model.dart';
import 'constants/unidad_medida.dart';
import 'widgets/producto_detail_sheet.dart';

/// Formatea cantidad sin decimales si son .000
String _formatearCantidad(String cantidad) {
  final num = double.tryParse(cantidad) ?? 0;
  if (num == num.toInt()) {
    return num.toInt().toString();
  }
  return num.toStringAsFixed(3).replaceAll(RegExp(r'\.?0+$'), '');
}

class ProductosPage extends ConsumerStatefulWidget {
  const ProductosPage({super.key});

  @override
  ConsumerState<ProductosPage> createState() => _ProductosPageState();
}

class _ProductosPageState extends ConsumerState<ProductosPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {
          _searchQuery = _searchController.text;
        }));
    Future.microtask(
      () {
        ref.read(inventarioProvider.notifier).cargarProductos();
        ref.read(inventarioProvider.notifier).cargarStock();
        ref.read(inventarioProvider.notifier).cargarLotes();
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

    // Calcular cantidadAveriada por producto desde lotes
    final averiados = <int, double>{};
    for (final lote in state.lotes) {
      for (final lp in lote.productos) {
        if (lp.isActive) {
          final cantidad = double.tryParse(lp.cantidadAveriada) ?? 0;
          if (cantidad > 0) {
            averiados[lp.producto] = (averiados[lp.producto] ?? 0) + cantidad;
          }
        }
      }
    }

    // Set de productos con factura (cruzar con lotes activos)
    final facturableIds = <int>{
      for (final lote in state.lotes)
        for (final lp in lote.productos)
          if (lp.conFactura && lp.isActive) lp.producto,
    };

    // Filtrar productos por búsqueda
    final productosParaMostrar = productos
        .where((p) => _searchQuery.isEmpty ||
            p.nombre.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

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
            // Buscador
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Buscar producto...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => _searchController.clear(),
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
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
                            ref
                                .read(inventarioProvider.notifier)
                                .cargarLotes();
                          },
                        )
                      : productosParaMostrar.isEmpty
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
                                await ref
                                    .read(inventarioProvider.notifier)
                                    .cargarLotes();
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
                                itemCount: productosParaMostrar.length,
                                itemBuilder: (context, index) {
                                  final producto = productosParaMostrar[index];
                                  final productoStock =
                                      stockMap[producto.id];
                                  final tieneFactura =
                                      facturableIds.contains(producto.id);
                                  return _ProductoGridCard(
                                    producto: producto,
                                    stock: productoStock,
                                    cantidadAveriada: averiados[producto.id],
                                    tieneFactura: tieneFactura,
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
  final double? cantidadAveriada;
  final bool tieneFactura;
  final bool isDueno;
  final VoidCallback onTap;

  const _ProductoGridCard({
    required this.producto,
    this.stock,
    this.cantidadAveriada,
    required this.tieneFactura,
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
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          producto.nombre,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (stock != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 1),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Cantidad disponible
                                Text(
                                  '${_formatearCantidad(stock!.cantidadDisponible)} ${UnidadMedida.getLabel(stock!.unidadMedida)}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF2F3A8F),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                // Cantidad averiada
                                if (cantidadAveriada != null && cantidadAveriada! > 0)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(
                                      '${cantidadAveriada!.toInt()} averiadas',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.orange[700],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: tieneFactura
                                ? const Color(0xFF1565C0)
                                : Colors.grey[600],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            tieneFactura ? 'Con factura' : 'Sin factura',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        StatusBadge(
                          label:
                              producto.isActive ? 'Activo' : 'Inactivo',
                          color: producto.isActive ? Colors.green : Colors.red,
                        ),
                      ],
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
