import 'package:management_system_ui/core/common_libs.dart';
import 'package:management_system_ui/features/auth/auth_provider.dart';
import 'package:management_system_ui/features/tienda/tienda_switcher_sheet.dart';
import 'package:management_system_ui/features/venta/venta_flow_header.dart';
import 'package:management_system_ui/features/venta/venta_provider.dart';
import 'package:management_system_ui/features/lote/constants/unidad_medida.dart';
import 'package:management_system_ui/features/lote/lote_provider.dart';

class VentaCarritoPage extends ConsumerStatefulWidget {
  const VentaCarritoPage({super.key});

  @override
  ConsumerState<VentaCarritoPage> createState() => _VentaCarritoPageState();
}

class _VentaCarritoPageState extends ConsumerState<VentaCarritoPage> {
  final List<TextEditingController> _cantidadControllers = [];
  final List<TextEditingController> _precioControllers = [];
  final Set<int> _editingPrecioIndices = {}; // Track which prices are being edited

  @override
  void dispose() {
    for (var controller in _cantidadControllers) {
      controller.dispose();
    }
    for (var controller in _precioControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _syncControllers(List<CarritoItem> items) {
    // Si el número de items cambió, recrear controllers
    if (_cantidadControllers.length != items.length) {
      // Limpiar viejos
      for (var controller in _cantidadControllers) {
        controller.dispose();
      }
      for (var controller in _precioControllers) {
        controller.dispose();
      }
      _cantidadControllers.clear();
      _precioControllers.clear();

      // Crear nuevos
      for (var item in items) {
        _cantidadControllers.add(
          TextEditingController(text: formatCantidad(item.cantidad)),
        );
        _precioControllers.add(
          TextEditingController(text: item.precioVenta.toStringAsFixed(2)),
        );
      }
    } else {
      // Si el número es igual, actualizar solo si el texto no coincide
      for (int i = 0; i < items.length; i++) {
        final expectedCantidad = formatCantidad(items[i].cantidad);
        if (_cantidadControllers[i].text != expectedCantidad) {
          _cantidadControllers[i].text = expectedCantidad;
        }
        // No sincronizar precio si el usuario está editándolo
        if (!_editingPrecioIndices.contains(i)) {
          final expectedPrecio = items[i].precioVenta.toStringAsFixed(2);
          if (_precioControllers[i].text != expectedPrecio) {
            _precioControllers[i].text = expectedPrecio;
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final carrito = ref.watch(carritoProvider);
    final authState = ref.watch(authProvider);
    final userMe = authState.userMe;
    final esDueno = userMe?.isDueno ?? false;
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 400;

    // Sincronizar controllers cuando el carrito cambia
    _syncControllers(carrito.items);

    if (carrito.items.isEmpty) {
      return Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              CustomAppBar(
                title: 'Ventas',
                subtitle: 'Registro de operaciones',
                icon: Icons.point_of_sale,
                isTiendaTitle: esDueno,
                onTiendaPressed: () => _mostrarSelectorTienda(context, ref, carrito.items.length),
              ),
              VentaFlowHeader(currentStep: 1, showTiendaHeader: false),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.shopping_cart_outlined,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      const Text('Carrito vacío'),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => context.go('/ventas'),
                        child: const Text('Ir al catálogo'),
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

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            CustomAppBar(
              title: 'Ventas',
              subtitle: 'Registro de operaciones',
              icon: Icons.point_of_sale,
              isTiendaTitle: esDueno,
              onTiendaPressed: () => _mostrarSelectorTienda(context, ref, carrito.items.length),
            ),
            VentaFlowHeader(
              currentStep: 1,
              showTiendaHeader: false,
              onStepTap: (stepIndex) {
                if (stepIndex == 0) {
                  context.go('/ventas');
                }
              },
            ),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 8 : 12,
                  vertical: isSmallScreen ? 6 : 8,
                ),
                itemCount: carrito.items.length,
                itemBuilder: (context, index) {
                  final item = carrito.items[index];
                  // Dimensiones responsivas
                  final imageSize = isSmallScreen ? 60.0 : 70.0;
                  final labelFontSize = isSmallScreen ? 10.0 : 11.0;
                  final valueFontSize = isSmallScreen ? 12.0 : 13.0;
                  final iconSize = isSmallScreen ? 18.0 : 20.0;
                  final spacing = isSmallScreen ? 6.0 : 12.0;

                  return Padding(
                    padding: EdgeInsets.only(bottom: isSmallScreen ? 8 : 12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: item.esAveriado
                            ? Colors.orange[50]
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: item.esAveriado
                              ? Colors.orange[200]!
                              : Colors.grey[200]!,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Fila superior: Imagen + Nombre + Botón eliminar
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Imagen miniatura
                                Container(
                                  width: imageSize,
                                  height: imageSize,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF2F4F7),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: item.productoImagen != null &&
                                          item.productoImagen!.isNotEmpty
                                      ? ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          child: Image.network(
                                            item.productoImagen!,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error,
                                                stack) {
                                              return Center(
                                                child: Icon(
                                                  Icons
                                                      .inventory_2_outlined,
                                                  size: iconSize,
                                                  color: Colors.grey[400],
                                                ),
                                              );
                                            },
                                            loadingBuilder: (context, child,
                                                loadingProgress) {
                                              if (loadingProgress == null) {
                                                return child;
                                              }
                                              return const Center(
                                                child: SizedBox(
                                                  width: 20,
                                                  height: 20,
                                                  child:
                                                      CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        )
                                      : Center(
                                          child: Icon(
                                            Icons.inventory_2_outlined,
                                            size: iconSize,
                                            color: Colors.grey[400],
                                          ),
                                        ),
                                ),
                                SizedBox(width: spacing),
                                // Información del producto
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.productoNombre,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: valueFontSize + 1,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        UnidadMedida.getLabel(
                                            item.unidadMedida),
                                        style: TextStyle(
                                          fontSize: labelFontSize,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      // Chip para seleccionar lote
                                      _LoteSelectorChip(
                                        item: item,
                                        itemIndex: index,
                                        onTap: () => _mostrarSelectorLote(
                                          context,
                                          ref,
                                          item,
                                          index,
                                        ),
                                      ),
                                      // Toggle de averiado
                                      if (item.esAveriado)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 6),
                                          child: Container(
                                            padding:
                                                const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.orange[50],
                                              border: Border.all(
                                                color: Colors.orange[300]!,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.warning_amber,
                                                  size: labelFontSize,
                                                  color: Colors.orange[700],
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'Averiado',
                                                  style: TextStyle(
                                                    fontSize: labelFontSize - 1,
                                                    color: Colors.orange[700],
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                SizedBox(
                                                  height: 16,
                                                  width: 32,
                                                  child: FittedBox(
                                                    fit: BoxFit.fill,
                                                    child: Switch(
                                                      value: item.esAveriado,
                                                      onChanged: (valor) {
                                                        ref
                                                            .read(
                                                              carritoProvider
                                                                  .notifier,
                                                            )
                                                            .actualizarAveriado(
                                                              index,
                                                              valor,
                                                            );
                                                      },
                                                      activeThumbColor:
                                                          Colors.orange,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                // Botón eliminar
                                IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  iconSize: iconSize,
                                  color: Colors.red[400],
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () {
                                    ref
                                        .read(carritoProvider.notifier)
                                        .eliminarItem(index);
                                  },
                                ),
                              ],
                            ),
                            SizedBox(height: spacing),
                            // Fila inferior: Cantidad + Precio + Subtotal
                            Row(
                              children: [
                                // Cantidad con stepper
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Cantidad',
                                        style: TextStyle(
                                          fontSize: labelFontSize,
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      SizedBox(height: isSmallScreen ? 4 : 6),
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(
                                                Icons.remove_circle_outline),
                                            iconSize: iconSize,
                                            padding: EdgeInsets.zero,
                                            constraints:
                                                const BoxConstraints(),
                                            onPressed: () {
                                              final nuevaCantidad =
                                                  item.cantidad - 1;
                                              if (nuevaCantidad <= 0) {
                                                ref
                                                    .read(carritoProvider
                                                        .notifier)
                                                    .eliminarItem(index);
                                              } else {
                                                ref
                                                    .read(carritoProvider
                                                        .notifier)
                                                    .actualizarCantidad(index,
                                                        nuevaCantidad);
                                              }
                                            },
                                          ),
                                          SizedBox(width: isSmallScreen ? 4 : 8),
                                          Expanded(
                                            child: TextField(
                                              controller:
                                                  _cantidadControllers[index],
                                              textAlign: TextAlign.center,
                                              keyboardType:
                                                  const TextInputType
                                                      .numberWithOptions(
                                                      decimal: true),
                                              onChanged: (val) {
                                                final nueva =
                                                    double.tryParse(val);
                                                if (nueva != null &&
                                                    nueva > 0) {
                                                  ref
                                                      .read(carritoProvider
                                                          .notifier)
                                                      .actualizarCantidad(
                                                          index, nueva);
                                                }
                                              },
                                              decoration: InputDecoration(
                                                isDense: true,
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                contentPadding:
                                                    EdgeInsets
                                                        .symmetric(
                                                        vertical: isSmallScreen ? 4 : 6,
                                                        horizontal: isSmallScreen ? 2 : 4),
                                              ),
                                              style: TextStyle(
                                                  fontSize: valueFontSize),
                                            ),
                                          ),
                                          SizedBox(width: isSmallScreen ? 4 : 8),
                                          IconButton(
                                            icon: const Icon(
                                                Icons.add_circle_outline),
                                            iconSize: iconSize,
                                            padding: EdgeInsets.zero,
                                            constraints:
                                                const BoxConstraints(),
                                            onPressed: () {
                                              ref
                                                  .read(carritoProvider
                                                      .notifier)
                                                  .actualizarCantidad(index,
                                                      item.cantidad + 1);
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: spacing),
                                // Precio
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Precio',
                                        style: TextStyle(
                                          fontSize: labelFontSize,
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      SizedBox(height: isSmallScreen ? 4 : 6),
                                      TextField(
                                        controller: _precioControllers[index],
                                        keyboardType: const TextInputType
                                            .numberWithOptions(
                                                decimal: true),
                                        onChanged: (val) {
                                          final nuevo = double.tryParse(val);
                                          if (nuevo != null && nuevo >= 0) {
                                            ref
                                                .read(carritoProvider
                                                    .notifier)
                                                .actualizarPrecio(
                                                    index, nuevo);
                                          }
                                        },
                                        onTap: () {
                                          setState(
                                              () => _editingPrecioIndices.add(index));
                                        },
                                        onEditingComplete: () {
                                          setState(() =>
                                              _editingPrecioIndices.remove(index));
                                        },
                                        decoration: InputDecoration(
                                          isDense: true,
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          contentPadding:
                                              EdgeInsets.symmetric(
                                                  vertical: isSmallScreen ? 4 : 6,
                                                  horizontal: isSmallScreen ? 6 : 8),
                                          prefixText: 'S/. ',
                                          prefixStyle: TextStyle(
                                            fontSize: valueFontSize,
                                          ),
                                        ),
                                        style: TextStyle(fontSize: valueFontSize),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: spacing),
                                // Subtotal
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'Subtotal',
                                        style: TextStyle(
                                          fontSize: labelFontSize,
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      SizedBox(height: isSmallScreen ? 4 : 6),
                                      Text(
                                        'S/. ${item.subtotal.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: valueFontSize + 1,
                                          color: const Color(0xFF2F3A8F),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            // Footer con total y botones
            Container(
              padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(
                    color: Colors.grey[200]!,
                    width: 1,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Resumen de totales
                  Container(
                    padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2F3A8F).withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${carrito.items.length} producto${carrito.items.length != 1 ? 's' : ''}',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 11 : 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Total:',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 11 : 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'S/. ${carrito.total.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 18 : 20,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF2F3A8F),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Listo para pagar',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 10 : 11,
                                color: Colors.green[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 12 : 16),
                  // Botones de acción
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            context.go('/ventas');
                          },
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              vertical: isSmallScreen ? 10 : 12,
                            ),
                            side: const BorderSide(
                              color: Color(0xFF2F3A8F),
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Agregar más',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: isSmallScreen ? 12 : 14,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: isSmallScreen ? 8 : 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            ref.read(carritoProvider.notifier).limpiar();
                          },
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              vertical: isSmallScreen ? 10 : 12,
                            ),
                            side: BorderSide(
                              color: Colors.red[400]!,
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Limpiar',
                            style: TextStyle(
                              color: Colors.red[400],
                              fontWeight: FontWeight.w600,
                              fontSize: isSmallScreen ? 12 : 14,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: isSmallScreen ? 8 : 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            context.go('/ventas/resumen');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2F3A8F),
                            padding: EdgeInsets.symmetric(
                              vertical: isSmallScreen ? 10 : 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Continuar',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: isSmallScreen ? 12 : 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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

  void _mostrarSelectorLote(
    BuildContext context,
    WidgetRef ref,
    CarritoItem item,
    int itemIndex,
  ) {
    final inventario = ref.watch(inventarioProvider);

    // Filtrar lotes que tengan el producto con stock disponible
    final lotesDisponibles = <Map<String, dynamic>>[];
    var lotesFifo = <Map<String, dynamic>>[];

    for (final lote in inventario.lotes) {
      for (final loteProducto in lote.productos) {
        if (loteProducto.producto == item.productoId &&
            loteProducto.isActive &&
            loteProducto.cantidadDisponible > 0) {
          lotesDisponibles.add({
            'id': loteProducto.id,
            'lote_id': lote.id,
            'fecha': lote.fechaLlegada,
            'stock': loteProducto.cantidadDisponible,
            'precio': loteProducto.precioVentaMercado,
            'con_factura': loteProducto.conFactura,
          });
        }
      }
    }

    // Ordenar por fecha (más antiguo primero para FIFO)
    lotesFifo = List.from(lotesDisponibles)
      ..sort((a, b) => (a['fecha'] as String).compareTo(b['fecha'] as String));

    // El lote FIFO es el más antiguo
    final loteFifo = lotesFifo.isNotEmpty ? lotesFifo.first : null;
    final fechaFifo = loteFifo?['fecha'] as String?;
    final conFacturaFifo = loteFifo?['con_factura'] as bool? ?? false;

    // Excluir el lote actualmente seleccionado de la lista
    final lotesParaMostrar = lotesDisponibles
        .where((lote) => lote['id'] != item.loteProductoId)
        .toList();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      builder: (context) => _LoteSelectorModalContent(
        item: item,
        itemIndex: itemIndex,
        ref: ref,
        lotesParaMostrar: lotesParaMostrar,
        fechaFifo: fechaFifo,
        conFacturaFifo: conFacturaFifo,
      ),
    );
  }
}

class _LoteSelectorModalContent extends StatefulWidget {
  final CarritoItem item;
  final int itemIndex;
  final WidgetRef ref;
  final List<Map<String, dynamic>> lotesParaMostrar;
  final String? fechaFifo;
  final bool conFacturaFifo;

  const _LoteSelectorModalContent({
    required this.item,
    required this.itemIndex,
    required this.ref,
    required this.lotesParaMostrar,
    required this.fechaFifo,
    required this.conFacturaFifo,
  });

  @override
  State<_LoteSelectorModalContent> createState() =>
      _LoteSelectorModalContentState();
}

class _LoteSelectorModalContentState extends State<_LoteSelectorModalContent> {
  bool ordenAscendente = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Selecciona lote para ${widget.item.productoNombre}',
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          // Opción Automática
          Material(
            child: InkWell(
              onTap: () {
                widget.ref
                    .read(carritoProvider.notifier)
                    .actualizarLoteProductoId(widget.itemIndex, null);
                Navigator.pop(context);
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: widget.item.loteProductoId == null
                        ? Colors.green
                        : Colors.grey[300]!,
                    width: widget.item.loteProductoId == null ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  color: widget.item.loteProductoId == null
                      ? Colors.green[50]
                      : Colors.white,
                ),
                child: Row(
                  children: [
                    Icon(
                      widget.item.loteProductoId == null
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Automático',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: Colors.green[700],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Llegada: ${widget.fechaFifo ?? 'N/A'}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  color: widget.conFacturaFifo
                                      ? Colors.green[100]
                                      : Colors.orange[100],
                                ),
                                child: Text(
                                  widget.conFacturaFifo
                                      ? 'Con factura'
                                      : 'Sin factura',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: widget.conFacturaFifo
                                        ? Colors.green[700]
                                        : Colors.orange[700],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Header con filtro
          if (widget.lotesParaMostrar.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Otros lotes',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                PopupMenuButton<bool>(
                  onSelected: (value) {
                    setState(() => ordenAscendente = value);
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: false,
                      child: Row(
                        children: [
                          Icon(
                            Icons.arrow_downward,
                            size: 16,
                            color:
                                !ordenAscendente ? Colors.blue : Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          const Text('Más recientes'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: true,
                      child: Row(
                        children: [
                          Icon(
                            Icons.arrow_upward,
                            size: 16,
                            color: ordenAscendente ? Colors.blue : Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          const Text('Más antiguos'),
                        ],
                      ),
                    ),
                  ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          ordenAscendente
                              ? Icons.arrow_upward
                              : Icons.arrow_downward,
                          size: 14,
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          ordenAscendente ? 'Más antiguos' : 'Más recientes',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.blue[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          // Lista de lotes
          if (widget.lotesParaMostrar.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'Solo disponible el lote automático',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: widget.lotesParaMostrar.length,
                itemBuilder: (context, idx) {
                  final lotesOrdenados = List.from(widget.lotesParaMostrar)
                    ..sort((a, b) {
                      final cmp = (a['fecha'] as String)
                          .compareTo(b['fecha'] as String);
                      return ordenAscendente ? cmp : -cmp;
                    });

                  final lote = lotesOrdenados[idx];
                  final isSelected = widget.item.loteProductoId == lote['id'];

                  return Material(
                    child: InkWell(
                      onTap: () {
                        widget.ref
                            .read(carritoProvider.notifier)
                            .actualizarLoteProductoId(
                                widget.itemIndex, lote['id'] as int);
                        Navigator.pop(context);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isSelected
                                ? Colors.blue
                                : Colors.grey[300]!,
                            width: isSelected ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          color: isSelected ? Colors.blue[50] : Colors.white,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isSelected
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_unchecked,
                              color: Colors.blue,
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
                                          'Llegada: ${lote['fecha']}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                            color: Colors.blue[700],
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(4),
                                          color: (lote['con_factura'] as bool)
                                              ? Colors.green[100]
                                              : Colors.orange[100],
                                        ),
                                        child: Text(
                                          (lote['con_factura'] as bool)
                                              ? 'Con factura'
                                              : 'Sin factura',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: (lote['con_factura']
                                                    as bool)
                                                ? Colors.green[700]
                                                : Colors.orange[700],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Stock: ${lote['stock']}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
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
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _LoteSelectorChip extends ConsumerWidget {
  final CarritoItem item;
  final int itemIndex;
  final VoidCallback onTap;

  const _LoteSelectorChip({
    required this.item,
    required this.itemIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inventario = ref.watch(inventarioProvider);

    // Obtener fecha del lote actual
    String? fechaLote;

    if (item.loteProductoId == null) {
      // FIFO: buscar el lote más antiguo
      final lotesDelProducto = <Map<String, dynamic>>[];
      for (final lote in inventario.lotes) {
        for (final loteProducto in lote.productos) {
          if (loteProducto.producto == item.productoId &&
              loteProducto.isActive) {
            lotesDelProducto.add({
              'fecha': lote.fechaLlegada,
            });
          }
        }
      }
      if (lotesDelProducto.isNotEmpty) {
        lotesDelProducto
            .sort((a, b) => (a['fecha'] as String).compareTo(b['fecha']));
        fechaLote = lotesDelProducto.first['fecha'];
      }
    } else {
      // Lote específico: buscar su fecha
      for (final lote in inventario.lotes) {
        for (final loteProducto in lote.productos) {
          if (loteProducto.id == item.loteProductoId) {
            fechaLote = lote.fechaLlegada;
            break;
          }
        }
      }
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.blue[300]!),
          borderRadius: BorderRadius.circular(6),
          color: Colors.blue[50],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inbox,
              size: 14,
              color: Colors.blue[700],
            ),
            const SizedBox(width: 6),
            Text(
              fechaLote ?? 'N/A',
              style: TextStyle(
                fontSize: 11,
                color: Colors.blue[700],
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.edit,
              size: 12,
              color: Colors.blue[700],
            ),
          ],
        ),
      ),
    );
  }
}
