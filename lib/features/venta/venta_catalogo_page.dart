import 'package:management_system_ui/core/common_libs.dart';
import 'package:management_system_ui/features/auth/auth_provider.dart';
import 'package:management_system_ui/features/lote/constants/unidad_medida.dart';
import 'package:management_system_ui/features/lote/lote_provider.dart';
import 'package:management_system_ui/features/lote/models/producto_catalogo_model.dart';
import 'package:management_system_ui/features/tienda/tienda_switcher_sheet.dart';
import 'package:management_system_ui/features/venta/venta_flow_header.dart';
import 'package:management_system_ui/features/venta/venta_provider.dart';

class VentaCatalogoPage extends ConsumerStatefulWidget {
  const VentaCatalogoPage({super.key});

  @override
  ConsumerState<VentaCatalogoPage> createState() =>
      _VentaCatalogoPageState();
}

class _VentaCatalogoPageState extends ConsumerState<VentaCatalogoPage> {
  final _searchController = TextEditingController();
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    Future.microtask(() {
      final tiendaId = ref.read(authProvider).selectedTiendaId;
      if (tiendaId != null) {
        ref.read(productoCatalogoProvider.notifier).cargarCatalogo();
      }
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(productoCatalogoProvider.notifier).cargarMasProductos();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final carrito = ref.watch(carritoProvider);
    final state = ref.watch(productoCatalogoProvider);
    final authState = ref.watch(authProvider);
    final productos = state.productos;
    final userMe = authState.userMe;
    final esDueno = userMe?.isDueno ?? false;

    // Recargar si la tienda cambia
    ref.listen(
      authProvider.select((a) => a.selectedTiendaId),
      (previous, next) {
        if (next != null && next != previous) {
          ref.read(productoCatalogoProvider.notifier).cargarCatalogo();
        }
      },
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      body: SafeArea(
        child: Column(
          children: [
            // Header unificado igual a home y usuarios
            CustomAppBar(
              title: 'Ventas',
              subtitle: 'Registro de operaciones',
              icon: Icons.point_of_sale,
              isTiendaTitle: esDueno,
              onTiendaPressed: () => _mostrarSelectorTienda(context, ref, carrito.items.length),
            ),
            VentaFlowHeader(currentStep: 0, showTiendaHeader: false),
          // Buscador
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: TextField(
              controller: _searchController,
              onChanged: (query) {
                ref.read(productoCatalogoProvider.notifier).cargarCatalogo(
                  search: query.isNotEmpty ? query : null,
                );
              },
              decoration: InputDecoration(
                hintText: 'Buscar producto...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(productoCatalogoProvider.notifier).cargarCatalogo();
                        },
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
                          ref.read(productoCatalogoProvider.notifier).cargarCatalogo();
                        },
                      )
                    : productos.isEmpty
                        ? const EmptyState(
                            icon: Icons.inventory_outlined,
                            titulo: 'Sin productos disponibles',
                            subtitulo: 'No hay productos en el catálogo',
                          )
                        : RefreshIndicator(
                            color: const Color(0xFF2F3A8F),
                            onRefresh: () async {
                              await ref.read(productoCatalogoProvider.notifier).cargarCatalogo();
                            },
                            child: GridView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.all(16),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 0.70,
                              ),
                              itemCount: productos.length + (state.hasMore ? 1 : 0),
                              itemBuilder: (context, index) {
                                // Mostrar loading spinner al final si hay más productos
                                if (index == productos.length) {
                                  return const Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        color: Color(0xFF2F3A8F),
                                      ),
                                    ),
                                  );
                                }

                                final producto = productos[index];
                                final enCarrito = carrito.items
                                    .any((i) => i.productoId == producto.productoId);
                                return _ProductoVentaCard(
                                  producto: producto,
                                  enCarrito: enCarrito,
                                  onTapNormal: () => _handleProductoTap(
                                    context,
                                    producto,
                                    ref,
                                    esAveriado: false,
                                  ),
                                  onTapAveriado: () => _handleProductoTap(
                                    context,
                                    producto,
                                    ref,
                                    esAveriado: true,
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
        ),
      ),
      bottomNavigationBar: carrito.items.isNotEmpty
          ? GestureDetector(
              onTap: () => context.go('/ventas/carrito'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF2F3A8F),
                  border: Border(
                    top: BorderSide(
                      color: Colors.grey[300]!,
                      width: 1,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        const Icon(
                          Icons.shopping_cart,
                          color: Colors.white,
                          size: 24,
                        ),
                        Positioned(
                          right: -8,
                          top: -8,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${carrito.items.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Carrito · ${carrito.items.length} producto${carrito.items.length != 1 ? 's' : ''}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            'S/. ${carrito.total.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white,
                      size: 16,
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

}

void _handleProductoTap(
  BuildContext context,
  ProductoCatalogoModel producto,
  WidgetRef ref, {
  required bool esAveriado,
}) {
  final carrito = ref.watch(carritoProvider);
  final idx = carrito.items.indexWhere((i) => i.productoId == producto.productoId);

  if (idx >= 0) {
    // Producto ya está en carrito → eliminar
    ref.read(carritoProvider.notifier).eliminarItem(idx);
  } else {
    // Agregar producto al carrito
    final precioVenta = double.tryParse(producto.precioVentaMercado) ?? 0;
    final item = CarritoItem(
      productoId: producto.productoId,
      productoNombre: producto.nombre,
      unidadMedida: producto.unidadMedida,
      cantidad: 1,
      precioVenta: precioVenta,
      productoImagen: producto.imagen,
      esAveriado: esAveriado,
    );
    ref.read(carritoProvider.notifier).agregarItem(item);
  }
}

void _mostrarSelectorTienda(
  BuildContext context,
  WidgetRef ref,
  int carritoItemsCount,
) {
  showTiendaSwitcher(
    context,
    carritoItemsCount: carritoItemsCount,
    onConfirmClearCarrito: () =>
        ref.read(carritoProvider.notifier).limpiar(),
  );
}


class _ProductoVentaCard extends StatelessWidget {
  final ProductoCatalogoModel producto;
  final bool enCarrito;
  final VoidCallback? onTapNormal;
  final VoidCallback? onTapAveriado;

  const _ProductoVentaCard({
    required this.producto,
    required this.enCarrito,
    required this.onTapNormal,
    required this.onTapAveriado,
  });

  bool _tieneStock() {
    final cantidad = double.tryParse(producto.cantidadDisponible) ?? 0;
    return cantidad > 0;
  }

  bool _tieneAveriados() {
    final cantidad = double.tryParse(producto.cantidadAveriada) ?? 0;
    return cantidad > 0;
  }

  VoidCallback? _handleTap(BuildContext context) {
    // Si no tiene stock disponible
    if (!_tieneStock()) {
      return null;
    }

    // Si tiene averiados y no está en carrito → mostrar opciones
    if (_tieneAveriados() && onTapNormal != null && !enCarrito) {
      return () => _mostrarOpcionesAveriado(context);
    }

    // En cualquier otro caso, usar el callback normal
    return onTapNormal;
  }

  void _mostrarOpcionesAveriado(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Selecciona el tipo de producto',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Opción: Producto normal
            _buildOpcionProducto(
              context,
              icono: Icons.check_circle,
              colorBase: Colors.green,
              titulo: 'Producto normal',
              cantidad: producto.cantidadDisponible,
              onTap: () {
                Navigator.pop(context);
                onTapNormal?.call();
              },
            ),

            const SizedBox(height: 12),

            // Opción: Producto averiado
            _buildOpcionProducto(
              context,
              icono: Icons.warning_amber,
              colorBase: Colors.orange,
              titulo: 'Producto averiado',
              cantidad: producto.cantidadAveriada,
              onTap: () {
                Navigator.pop(context);
                onTapAveriado?.call();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOpcionProducto(
    BuildContext context, {
    required IconData icono,
    required Color colorBase,
    required String titulo,
    required String cantidad,
    required VoidCallback onTap,
  }) {
    final borderColor = colorBase.withValues(alpha: 0.3);
    final bgColor = colorBase.withValues(alpha: 0.1);

    return Material(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(12),
            color: bgColor,
          ),
          child: Row(
            children: [
              Icon(icono, color: colorBase, size: 28),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: colorBase,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Disponibles: ${formatCantidadStr(cantidad)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorBase.withValues(alpha: 0.7),
                      ),
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap(context),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: enCarrito
              ? Border.all(color: Colors.green, width: 2)
              : Border.all(color: Colors.transparent, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen con badge de stock y check
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF2F4F7),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: producto.imagen != null &&
                            producto.imagen!.isNotEmpty
                        ? ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                            ),
                            child: Image.network(
                              producto.imagen!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stack) {
                                return Center(
                                  child: Icon(
                                    Icons.inventory_2_outlined,
                                    size: 32,
                                    color: Colors.grey[400],
                                  ),
                                );
                              },
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                if (loadingProgress == null) {
                                  return child;
                                }
                                return const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                );
                              },
                            ),
                          )
                        : Center(
                            child: Icon(
                              Icons.inventory_2_outlined,
                              size: 32,
                              color: Colors.grey[400],
                            ),
                          ),
                  ),
                  // Overlay verde si está en carrito
                  if (enCarrito)
                    Container(
                      width: double.infinity,
                      height: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.3),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 48,
                        ),
                      ),
                    ),
                  // Badge de stock
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _tieneStock() ? Colors.green : Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _tieneStock() ? 'En stock' : 'Sin stock',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  // Badge de averiados (esquina inferior izquierda)
                  if (_tieneAveriados())
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange[700],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${double.tryParse(producto.cantidadAveriada)?.toInt() ?? 0} averiados',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
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
                    Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          'S/. ${producto.precioVentaMercado}',
                          style: const TextStyle(
                            color: Color(0xFF2F3A8F),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${formatCantidadStr(producto.cantidadDisponible)} ${UnidadMedida.getLabel(producto.unidadMedida)}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                            ),
                            if (_tieneAveriados())
                              Padding(
                                padding: const EdgeInsets.only(top: 1),
                                child: Text(
                                  '${double.tryParse(producto.cantidadAveriada)?.toInt() ?? 0} averiadas',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.orange[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: producto.tieneConFactura
                                ? const Color(0xFF1565C0)
                                : Colors.grey[600],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            producto.tieneConFactura ? 'Con factura' : 'Sin factura',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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
