class LoteResponse {
  final int id;
  final TiendaLoteInfo tienda;
  final String fechaLlegada;
  final String costoOperacion;
  final String costoTransporte;
  final bool isActive;
  final List<LoteProductoResponse> productos;

  LoteResponse({
    required this.id,
    required this.tienda,
    required this.fechaLlegada,
    required this.costoOperacion,
    required this.costoTransporte,
    required this.isActive,
    required this.productos,
  });

  factory LoteResponse.fromJson(Map<String, dynamic> json) {
    return LoteResponse(
      id: json['id'] as int,
      tienda: TiendaLoteInfo.fromJson(json['tienda'] as Map<String, dynamic>),
      fechaLlegada: json['fecha_llegada'] as String,
      costoOperacion: json['costo_operacion'].toString(),
      costoTransporte: json['costo_transporte'].toString(),
      isActive: json['is_active'] as bool,
      productos: (json['productos'] as List)
          .map((e) => LoteProductoResponse.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class TiendaLoteInfo {
  final int id;
  final String nombreSede;

  TiendaLoteInfo({
    required this.id,
    required this.nombreSede,
  });

  factory TiendaLoteInfo.fromJson(Map<String, dynamic> json) {
    return TiendaLoteInfo(
      id: json['id'] as int,
      nombreSede: json['nombre_sede'] as String,
    );
  }
}

class LoteProductoResponse {
  final int id;
  final int producto;
  final String productoNombre;
  final String productoCodigo;
  final String unidadMedida;
  final String unidadMedidaDisplay;
  final bool conFactura;
  final String cantidadInicial; // Decimal string
  final String cantidadActual; // Decimal string
  final String cantidadAveriada; // Decimal string
  final int cantidadDisponible;
  final String costoTotal;
  final String precioCompra;
  final String? precioVentaBase; // Nullable - solo para dueño
  final String precioVentaMercado;
  final bool isActive;

  LoteProductoResponse({
    required this.id,
    required this.producto,
    required this.productoNombre,
    required this.productoCodigo,
    required this.unidadMedida,
    required this.unidadMedidaDisplay,
    required this.conFactura,
    required this.cantidadInicial,
    required this.cantidadActual,
    required this.cantidadAveriada,
    required this.cantidadDisponible,
    required this.costoTotal,
    required this.precioCompra,
    this.precioVentaBase,
    required this.precioVentaMercado,
    required this.isActive,
  });

  factory LoteProductoResponse.fromJson(Map<String, dynamic> json) {
    return LoteProductoResponse(
      id: json['id'] as int,
      producto: json['producto'] as int,
      productoNombre: json['producto_nombre'] as String,
      productoCodigo: json['producto_codigo'] as String,
      unidadMedida: json['unidad_medida'] as String,
      unidadMedidaDisplay: json['unidad_medida_display'] as String,
      conFactura: json['con_factura'] as bool,
      cantidadInicial: json['cantidad_inicial'].toString(),
      cantidadActual: json['cantidad_actual'].toString(),
      cantidadAveriada: json['cantidad_averiada'].toString(),
      cantidadDisponible: json['cantidad_disponible'] as int,
      costoTotal: json['costo_total'].toString(),
      precioCompra: json['precio_compra'].toString(),
      precioVentaBase: json['precio_venta_base']?.toString(),
      precioVentaMercado: json['precio_venta_mercado'].toString(),
      isActive: json['is_active'] as bool,
    );
  }
}
