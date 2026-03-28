import 'package:management_system_ui/core/common_libs.dart';
import 'package:management_system_ui/features/auth/auth_provider.dart';
import 'package:management_system_ui/features/lote/constants/unidad_medida.dart';
import 'package:management_system_ui/features/lote/lote_provider.dart';
import 'package:management_system_ui/features/lote/models/producto_model.dart';
import 'package:management_system_ui/features/lote/models/stock_model.dart';
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
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {
          _searchQuery = _searchController.text;
        }));
    _cargarDatos();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _cargarDatos() {
    Future.microtask(() {
      final tiendaId = ref.read(authProvider).selectedTiendaId;
      if (tiendaId != null) {
        ref.read(inventarioProvider.notifier).cargarProductos();
        ref.read(inventarioProvider.notifier).cargarStock();
        ref.read(inventarioProvider.notifier).cargarLotes();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final carrito = ref.watch(carritoProvider);
    final inventario = ref.watch(inventarioProvider);
    final authState = ref.watch(authProvider);
    final productos = inventario.productos;
    final stock = inventario.stock;
    final userMe = authState.userMe;
    final esDueno = userMe?.isDueno ?? false;

    // Recargar si la tienda cambia
    ref.listen(
      authProvider.select((a) => a.selectedTiendaId),
      (previous, next) {
        if (next != null && next != previous) {
          _cargarDatos();
        }
      },
    );

    // Crear mapa de stock: productoId -> StockModel
    final stockMap = {
      for (final s in stock) s.productoId: s,
    };

    // Calcular cantidadAveriada por producto desde lotes
    final averiados = <int, double>{};
    for (final lote in inventario.lotes) {
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
      for (final lote in inventario.lotes)
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
            child: inventario.isLoading && productos.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF2F3A8F),
                    ),
                  )
                : inventario.errorMessage != null && productos.isEmpty
                    ? ErrorState(
                        mensaje: inventario.errorMessage!,
                        onRetry: () {
                          ref
                              .read(inventarioProvider.notifier)
                              .cargarProductos();
                          ref.read(inventarioProvider.notifier).cargarStock();
                          ref.read(inventarioProvider.notifier).cargarLotes();
                        },
                      )
                    : productosParaMostrar.isEmpty
                        ? const EmptyState(
                            icon: Icons.inventory_outlined,
                            titulo: 'Sin productos disponibles',
                            subtitulo: 'No hay productos en el catálogo',
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
                              padding: const EdgeInsets.all(16),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 0.70,
                              ),
                              itemCount: productosParaMostrar.length,
                              itemBuilder: (context, index) {
                                final producto =
                                    productosParaMostrar[index];
                                final productoStock =
                                    stockMap[producto.id];
                                final tieneFactura =
                                    facturableIds.contains(producto.id);
                                final enCarrito = carrito.items
                                    .any((i) => i.productoId == producto.id);
                                return _ProductoVentaCard(
                                  producto: producto,
                                  stock: productoStock,
                                  tieneFactura: tieneFactura,
                                  enCarrito: enCarrito,
                                  cantidadAveriada: averiados[producto.id],
                                  onTapNormal: productoStock == null
                                      ? null
                                      : () => _handleProductoTap(
                                            context,
                                            producto,
                                            productoStock,
                                            ref,
                                            esAveriado: false,
                                          ),
                                  onTapAveriado: productoStock == null
                                      ? null
                                      : () => _handleProductoTap(
                                            context,
                                            producto,
                                            productoStock,
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
  ProductoModel producto,
  StockModel productoStock,
  WidgetRef ref, {
  required bool esAveriado,
}) {
  final carrito = ref.watch(carritoProvider);
  final idx = carrito.items.indexWhere((i) => i.productoId == producto.id);

  if (idx >= 0) {
    // Producto ya está en carrito → eliminar
    ref.read(carritoProvider.notifier).eliminarItem(idx);
  } else {
    // Agregar producto al carrito
    final precioVenta =
        double.tryParse(productoStock.precioVentaMercado) ?? 0;
    final item = CarritoItem(
      productoId: producto.id,
      productoNombre: producto.nombre,
      unidadMedida: productoStock.unidadMedida,
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
  final ProductoModel producto;
  final StockModel? stock;
  final bool tieneFactura;
  final bool enCarrito;
  final double? cantidadAveriada;
  final VoidCallback? onTapNormal;
  final VoidCallback? onTapAveriado;

  const _ProductoVentaCard({
    required this.producto,
    this.stock,
    required this.tieneFactura,
    required this.enCarrito,
    this.cantidadAveriada,
    required this.onTapNormal,
    required this.onTapAveriado,
  });

  bool _tieneStock() {
    if (stock == null) return false;
    final cantidad = double.tryParse(stock!.cantidadDisponible) ?? 0;
    return cantidad > 0;
  }

  bool _tieneAveriados() {
    final cantidad = cantidadAveriada ?? 0;
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
              cantidad: stock!.cantidadDisponible,
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
              cantidad: '${cantidadAveriada?.toInt() ?? 0}',
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
                          '${cantidadAveriada!.toInt()} averiados',
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
                          stock != null
                              ? 'S/. ${stock!.precioVentaMercado}'
                              : 'N/A',
                          style: const TextStyle(
                            color: Color(0xFF2F3A8F),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        if (stock != null)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${formatCantidadStr(stock!.cantidadDisponible)} ${UnidadMedida.getLabel(stock!.unidadMedida)}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                ),
                              ),
                              if (cantidadAveriada != null && cantidadAveriada! > 0)
                                Padding(
                                  padding: const EdgeInsets.only(top: 1),
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
                          )
                        else
                          Text(
                            'Sin stock',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                        const SizedBox(height: 4),
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
