import 'package:management_system_ui/core/common_libs.dart';
import 'package:management_system_ui/features/auth/auth_provider.dart';
import 'package:management_system_ui/features/venta/models/venta_create_model.dart';
import 'package:management_system_ui/features/venta/models/venta_read_model.dart';
import 'package:management_system_ui/features/venta/venta_flow_header.dart';
import 'package:management_system_ui/features/venta/venta_provider.dart';

class VentaPropuestaSunatPage extends ConsumerStatefulWidget {
  const VentaPropuestaSunatPage({super.key});

  @override
  ConsumerState<VentaPropuestaSunatPage> createState() =>
      _VentaPropuestaSunatPageState();
}

class _VentaPropuestaSunatPageState extends ConsumerState<VentaPropuestaSunatPage> {
  late Map<int, TextEditingController> cantidadControllers;
  late Map<int, TextEditingController> precioControllers;
  late Map<int, dynamic> productosReemplazo; // Track cambios en productos

  @override
  void initState() {
    super.initState();
    cantidadControllers = {};
    precioControllers = {};
    productosReemplazo = {};
  }

  @override
  void dispose() {
    for (var controller in cantidadControllers.values) {
      controller.dispose();
    }
    for (var controller in precioControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _initializeControllers(List<dynamic> propuesta) {
    for (int i = 0; i < propuesta.length; i++) {
      final item = propuesta[i];
      if (!cantidadControllers.containsKey(i)) {
        cantidadControllers[i] = TextEditingController(
          text: formatCantidad(double.tryParse(item.cantidad.toString()) ?? 0),
        );
      }
      if (!precioControllers.containsKey(i)) {
        precioControllers[i] = TextEditingController(
          text: formatCantidad(double.tryParse(item.precio.toString()) ?? 0),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ventaState = ref.watch(ventaProvider);
    final venta = ventaState.ventaCreada;

    // Initialize controllers on first build with propuesta
    if (venta?.propuestaSunat != null &&
        cantidadControllers.isEmpty &&
        precioControllers.isEmpty) {
      _initializeControllers(venta!.propuestaSunat!);
    }

    final authState = ref.watch(authProvider);
    final userMe = authState.userMe;
    final esDueno = userMe?.isDueno ?? false;

    if (venta == null || venta.propuestaSunat == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Propuesta SUNAT'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/ventas/historial'),
          ),
        ),
        body: const Center(
          child: Text('No hay propuesta SUNAT disponible'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      body: SafeArea(
        child: Column(
          children: [
            CustomAppBar(
              title: 'Ventas',
              subtitle: 'Propuesta SUNAT',
              icon: Icons.point_of_sale,
              isTiendaTitle: esDueno,
            ),
            VentaFlowHeader(currentStep: 3, showTiendaHeader: false),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Info banner
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        border: Border.all(color: Colors.blue[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info,
                            color: Colors.blue[700],
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Verifica los reemplazos sugeridos. Puedes editar cantidad y precio.',
                              style: TextStyle(
                                color: Colors.blue[900],
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    const Text(
                      'Propuesta de facturación',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Cargar imágenes de los lotes
                    _buildPropuestaSunatItems(
                      venta.propuestaSunat!,
                      venta.detalle,
                      ref,
                    ),

                    const SizedBox(height: 24),

                    // Botón confirmar
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: ventaState.isSaving
                            ? null
                            : () => _confirmarPropuesta(
                                  context,
                                  ref,
                                  venta,
                                ),
                        child: ventaState.isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Confirmar propuesta'),
                      ),
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

  Widget _buildPropuestaSunatItems(
    List<dynamic> propuestaSunat,
    List<VentaLineaModel> detalle,
    WidgetRef ref,
  ) {
    return FutureBuilder(
      future: _cargarProductosCompletos(ref),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // Mapeo completo de productos (id → datos completos)
        final productosMap = snapshot.data ?? {};

        return Column(
          children: propuestaSunat.asMap().entries.map((entry) {
            return _buildPropuestaItemWithImage(
              entry.value,
              entry.key,
              detalle,
              productosMap,
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildPropuestaItemWithImage(
    dynamic propuestaItem,
    int index,
    List<VentaLineaModel> detalle,
    Map<int, dynamic> productosMap,
  ) {
    final cantidadCtrl = cantidadControllers[index] ?? TextEditingController();
    final precioCtrl = precioControllers[index] ?? TextEditingController();

    // Obtener el producto original del detalle
    final productoOriginal = detalle.isNotEmpty ? detalle[index % detalle.length] : null;

    // Obtener datos del producto de reemplazo
    final productoData = productosMap[propuestaItem.loteProductoId] ?? {};
    final imagenReemplazo = productoData['imagen'] ?? '';

    final isRelleno = propuestaItem.esRelleno ?? false;

    return isRelleno
        ? _buildRellnoItem(
            propuestaItem,
            index,
            productoOriginal,
            cantidadCtrl,
            precioCtrl,
            imagenReemplazo,
            ref,
            productosMap,
          )
        : _buildProductoNormalItem(
            propuestaItem,
            cantidadCtrl,
            precioCtrl,
            imagenReemplazo,
          );
  }

  Widget _buildProductoNormalItem(
    dynamic propuestaItem,
    TextEditingController cantidadCtrl,
    TextEditingController precioCtrl,
    String imagenUrl,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green[300]!, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green[600], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Producto con factura disponible',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Producto
              Row(
                children: [
                  _buildImagePlaceholder(
                    imageUrl: imagenUrl,
                    width: 70,
                    height: 70,
                    bgColor: Colors.grey[200]!,
                    iconColor: Colors.grey[400]!,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          propuestaItem.loteProductoNombre,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'ID: ${propuestaItem.loteProductoId}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Cantidad y Precio
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: _buildInputField(
                      'Cantidad',
                      cantidadCtrl,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: _buildInputField(
                      'Precio',
                      precioCtrl,
                      prefixText: 'S/. ',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Subtotal
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  border: Border.all(color: Colors.green[200]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Subtotal',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.green[900],
                      ),
                    ),
                    Text(
                      'S/. ${propuestaItem.subtotal}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[900],
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

  Widget _buildRellnoItem(
    dynamic propuestaItem,
    int index,
    VentaLineaModel? productoOriginal,
    TextEditingController cantidadCtrl,
    TextEditingController precioCtrl,
    String imagenUrl,
    WidgetRef ref,
    Map<int, dynamic> productosMap,
  ) {
    final productoFueReemplazado = productosReemplazo.containsKey(index);
    final productoReemplazoData = productosReemplazo[index];

    // Obtener imagen del producto original si está disponible
    final imagenProductoOriginal = propuestaItem.loteProductoOriginalId != null
        ? (productosMap[propuestaItem.loteProductoOriginalId] ?? {})['imagen'] ?? ''
        : '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orange[400]!, Colors.orange[600]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.swap_horiz, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Producto en reemplazo',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          // Warning si no hay relleno encontrado
          if (propuestaItem.loteProductoOriginalId == null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                border: Border.all(color: Colors.orange[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.orange[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'No se encontró relleno para este producto.\nRequiere intervención manual.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.orange[900],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Card
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Original
                  if (productoOriginal != null) ...[
                    Text(
                      'Producto solicitado',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Row(
                        children: [
                          _buildImagePlaceholder(
                            imageUrl: imagenProductoOriginal,
                            width: 60,
                            height: 60,
                            bgColor: Colors.grey[200]!,
                            iconColor: Colors.grey[400]!,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  productoOriginal.productoNombre,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange[100],
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Icon(
                          Icons.arrow_downward,
                          color: Colors.orange[700],
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Reemplazo
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Reemplazado con',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.swap_horiz, size: 16),
                        label: const Text('Cambiar'),
                        onPressed: () => _mostrarSelectorProductos(index, ref),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    child: Row(
                      children: [
                        _buildImagePlaceholder(
                          imageUrl: productoFueReemplazado
                              ? (productoReemplazoData['imagen'] ?? '')
                              : imagenUrl,
                          width: 60,
                          height: 60,
                          bgColor: Colors.green[100]!,
                          iconColor: Colors.green[600]!,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                productoFueReemplazado
                                    ? (productoReemplazoData['nombre'] ?? '')
                                    : propuestaItem.loteProductoNombre,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Cantidad y Precio
                  Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: _buildInputField('Cantidad', cantidadCtrl),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 1,
                        child: _buildInputField(
                          'Precio',
                          precioCtrl,
                          prefixText: 'S/. ',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Subtotal
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      border: Border.all(color: Colors.blue[200]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Subtotal',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue[900],
                          ),
                        ),
                        Text(
                          'S/. ${propuestaItem.subtotal}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[900],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField(
    String label,
    TextEditingController controller, {
    String? prefixText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[50],
            prefixText: prefixText,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          ),
        ),
      ],
    );
  }

  Future<Map<int, dynamic>> _cargarProductosCompletos(WidgetRef ref) async {
    try {
      final dio = ref.read(dioProvider);
      final authState = ref.read(authProvider);
      final tiendaId = authState.selectedTiendaId;

      if (tiendaId == null) {
        return {};
      }

      // Obtener productos (igual que catálogo)
      final productosResponse = await dio.get('inventory/productos/');

      // Obtener stock de la tienda (igual que catálogo)
      final stockResponse = await dio.get(
        'inventory/stock/',
        queryParameters: {'tienda': tiendaId},
      );

      Map<int, dynamic> productosMap = {};

      // Procesar productos base
      if (productosResponse.data is List) {
        for (var prod in productosResponse.data) {
          final id = prod['id'] as int?;
          if (id != null) {
            productosMap[id] = {
              'id': id,
              'nombre': prod['nombre'] ?? '',
              'codigo': prod['codigo'] ?? '',
              'imagen': prod['imagen'] ?? '',
              'precio': 0.0,
              'stock': 0,
            };
          }
        }
      }

      // Procesar stock y hacer match con productos
      // El stock tiene: producto_id, cantidad_disponible, precio_venta_mercado
      List stockList = [];
      if (stockResponse.data is Map && stockResponse.data.containsKey('results')) {
        stockList = stockResponse.data['results'];
      } else if (stockResponse.data is List) {
        stockList = stockResponse.data;
      }

      // Hacer match: producto_id -> StockData
      for (var stockItem in stockList) {
        final productoId = stockItem['producto_id'] as int?;
        final cantidadDisponible =
            double.tryParse(stockItem['cantidad_disponible']?.toString() ?? '0') ?? 0.0;
        final precioVentaMercado =
            double.tryParse(stockItem['precio_venta_mercado']?.toString() ?? '0') ?? 0.0;

        if (productoId != null && productosMap.containsKey(productoId)) {
          productosMap[productoId]['stock'] = cantidadDisponible.toInt();
          productosMap[productoId]['precio'] = precioVentaMercado;
        }
      }

      return productosMap;
    } catch (e) {
      return {};
    }
  }

  Future<void> _mostrarSelectorProductos(int indexActual, WidgetRef ref) async {
    final dio = ref.read(dioProvider);
    final authState = ref.read(authProvider);
    final tiendaId = authState.selectedTiendaId;

    try {
      if (tiendaId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No hay tienda seleccionada')),
          );
        }
        return;
      }

      // Cargar productos
      final productosResponse = await dio.get('inventory/productos/');

      // Cargar stock de la tienda
      final stockResponse = await dio.get(
        'inventory/stock/',
        queryParameters: {'tienda': tiendaId},
      );

      if (!mounted) return;

      final productos = productosResponse.data is List ? productosResponse.data : [];

      // Procesar stock y crear mapa: producto_id -> datos stock
      List stockList = [];
      if (stockResponse.data is Map && stockResponse.data.containsKey('results')) {
        stockList = stockResponse.data['results'];
      } else if (stockResponse.data is List) {
        stockList = stockResponse.data;
      }

      // Map de stock por producto_id
      Map<int, Map<String, dynamic>> stockPorProducto = {};
      for (var stockItem in stockList) {
        final productoId = stockItem['producto_id'] as int?;
        final cantidadDisponible =
            double.tryParse(stockItem['cantidad_disponible']?.toString() ?? '0') ?? 0.0;
        final precioVentaMercado =
            double.tryParse(stockItem['precio_venta_mercado']?.toString() ?? '0') ?? 0.0;

        if (productoId != null) {
          stockPorProducto[productoId] = {
            'stock': cantidadDisponible.toInt(),
            'precio': precioVentaMercado,
          };
        }
      }

      // Agregar datos de stock a cada producto
      for (var prod in productos) {
        final productoId = prod['id'] as int?;
        if (productoId != null && stockPorProducto.containsKey(productoId)) {
          final stockData = stockPorProducto[productoId];
          prod['stock'] = stockData?['stock'] ?? 0;
          prod['precio'] = stockData?['precio'] ?? 0.0;
        } else {
          prod['stock'] = 0;
          prod['precio'] = 0.0;
        }
      }

      // Estado para el filtrado
      String filtro = '';

      await showDialog(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setStateDialog) {
            // Filtrar productos según búsqueda
            final productosFiltrados = productos
                .where((prod) {
                  final nombre = (prod['nombre'] ?? '').toString().toLowerCase();
                  final codigo = (prod['codigo'] ?? '').toString().toLowerCase();
                  return nombre.contains(filtro.toLowerCase()) ||
                      codigo.contains(filtro.toLowerCase());
                })
                .toList();

            return Dialog(
              insetPadding: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              backgroundColor: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Scaffold(
                  backgroundColor: Colors.transparent,
                  appBar: AppBar(
                    title: const Text(
                      'Cambiar producto de reemplazo',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    centerTitle: false,
                    elevation: 0,
                    backgroundColor: const Color(0xFF2F3A8F),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    leading: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  body: Column(
                    children: [
                      // Buscador
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          border: Border(
                            bottom: BorderSide(color: Colors.grey[100]!),
                          ),
                        ),
                        child: TextField(
                          onChanged: (value) {
                            setStateDialog(() {
                              filtro = value;
                            });
                          },
                          decoration: InputDecoration(
                            hintText: 'Buscar por nombre o código...',
                            hintStyle: TextStyle(color: Colors.grey[500]),
                            prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                            suffixIcon: filtro.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    color: Colors.grey[600],
                                    onPressed: () {
                                      setStateDialog(() {
                                        filtro = '';
                                      });
                                    },
                                  )
                                : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Color(0xFFE0E0E0),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Color(0xFFE0E0E0),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Color(0xFF2F3A8F),
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),

                      // Lista de productos
                      Expanded(
                        child: productosFiltrados.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.search_off,
                                      size: 56,
                                      color: Colors.grey[300],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No se encontraron productos',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Intenta con otro término de búsqueda',
                                      style: TextStyle(
                                        color: Colors.grey[500],
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                itemCount: productosFiltrados.length,
                                itemBuilder: (context, idx) {
                                  final prod = productosFiltrados[idx];
                                  final precio = (prod['precio'] as num?)?.toDouble() ?? 0.0;
                                  final stock = prod['stock'] ?? 0;

                                  return Container(
                                    margin: const EdgeInsets.symmetric(vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.grey[100]!,
                                      ),
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () {
                                          // Actualizar el producto en la propuesta
                                          setState(() {
                                            productosReemplazo[indexActual] = {
                                              'id': prod['id'],
                                              'nombre': prod['nombre'],
                                              'imagen': prod['imagen'],
                                            };
                                          });
                                          Navigator.pop(context);
                                        },
                                        borderRadius: BorderRadius.circular(12),
                                        child: Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: Row(
                                            children: [
                                              // Imagen
                                              Container(
                                                width: 70,
                                                height: 70,
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  color: Colors.grey[100],
                                                ),
                                                child: (prod['imagen'] ?? '')
                                                        .isNotEmpty
                                                    ? ClipRRect(
                                                        borderRadius:
                                                            BorderRadius.circular(10),
                                                        child: Image.network(
                                                          prod['imagen'],
                                                          fit: BoxFit.cover,
                                                          errorBuilder:
                                                              (context, error,
                                                                  stackTrace) =>
                                                                  Icon(
                                                            Icons.image,
                                                            color: Colors
                                                                .grey[400],
                                                            size: 32,
                                                          ),
                                                        ),
                                                      )
                                                    : Icon(
                                                        Icons.image,
                                                        color: Colors.grey[400],
                                                        size: 32,
                                                      ),
                                              ),
                                              const SizedBox(width: 14),

                                              // Información
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      prod['nombre'] ?? '',
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontSize: 14,
                                                        color: Color(
                                                            0xFF1F1F1F),
                                                      ),
                                                      maxLines: 2,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                    const SizedBox(height: 6),
                                                    Text(
                                                      'Código: ${prod['codigo'] ?? ''}',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color:
                                                            Colors.grey[600],
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        Container(
                                                          padding: const EdgeInsets
                                                              .symmetric(
                                                            horizontal: 10,
                                                            vertical: 4,
                                                          ),
                                                          decoration:
                                                              BoxDecoration(
                                                            color: const Color(
                                                                0xFF2F3A8F),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(6),
                                                          ),
                                                          child: Text(
                                                            'S/. ${precio.toStringAsFixed(2)}',
                                                            style: const TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              fontSize: 13,
                                                              color: Colors
                                                                  .white,
                                                            ),
                                                          ),
                                                        ),
                                                        Container(
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                            horizontal: 10,
                                                            vertical: 4,
                                                          ),
                                                          decoration:
                                                              BoxDecoration(
                                                            color: stock > 0
                                                                ? const Color(
                                                                    0xFFE8F5E9)
                                                                : const Color(
                                                                    0xFFFFEBEE),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(6),
                                                            border: Border.all(
                                                              color: stock > 0
                                                                  ? const Color(
                                                                      0xFF4CAF50)
                                                                  : const Color(
                                                                      0xFFE53935),
                                                              width: 1,
                                                            ),
                                                          ),
                                                          child: Text(
                                                            'Stock: $stock',
                                                            style: TextStyle(
                                                              fontSize: 11,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              color: stock > 0
                                                                  ? const Color(
                                                                      0xFF2E7D32)
                                                                  : const Color(
                                                                      0xFFC62828),
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
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Widget _buildImagePlaceholder({
    required String imageUrl,
    required double width,
    required double height,
    required Color bgColor,
    required Color iconColor,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: imageUrl.isNotEmpty && imageUrl.trim() != ''
          ? ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(Icons.image, color: iconColor);
                },
              ),
            )
          : Icon(Icons.image, color: iconColor),
    );
  }

  Future<void> _confirmarPropuesta(
    BuildContext context,
    WidgetRef ref,
    VentaReadModel? venta,
  ) async {
    if (venta == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay venta seleccionada'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (venta.propuestaSunat == null || venta.propuestaSunat!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay propuesta para confirmar'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final items = venta.propuestaSunat!
        .map((p) {
          return ConfirmarSunatItem(
            loteProductoId: p.loteProductoId,
            cantidad: p.cantidad,
            precio: p.precio,
            esRelleno: p.esRelleno,
            loteProductoOriginalId: p.loteProductoOriginalId,
          );
        })
        .toList();

    try {
      await ref
          .read(ventaProvider.notifier)
          .confirmarSunat(venta.numeroComprobante, items);

      if (!context.mounted) return;

      final ventaState = ref.read(ventaProvider);

      if (ventaState.successMessage != null) {
        ref.read(carritoProvider.notifier).limpiar();
        context.go('/ventas/comprobante');
      } else if (ventaState.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ventaState.errorMessage!),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
