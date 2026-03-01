class LoteResponse {
  final int id;
  final TiendaResponse tienda;
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
      id: json['id'],
      tienda: TiendaResponse.fromJson(json['tienda']),
      fechaLlegada: json['fecha_llegada'],
      costoOperacion: json['costo_operacion'],
      costoTransporte: json['costo_transporte'],
      isActive: json['is_active'],
      productos: (json['productos'] as List)
          .map((e) => LoteProductoResponse.fromJson(e))
          .toList(),
    );
  }
}

class TiendaResponse {
  final int id;
  final String nombreSede;

  TiendaResponse({
    required this.id,
    required this.nombreSede,
  });

  factory TiendaResponse.fromJson(Map<String, dynamic> json) {
    return TiendaResponse(
      id: json['id'],
      nombreSede: json['nombre_sede'],
    );
  }
}

class LoteProductoResponse {
  final int id;
  final int producto;
  final String productoNombre;
  final int cantidadInicial;
  final int cantidadActual;
  final String precioCompra;
  final String precioVentaBase;
  final bool isActive;

  LoteProductoResponse({
    required this.id,
    required this.producto,
    required this.productoNombre,
    required this.cantidadInicial,
    required this.cantidadActual,
    required this.precioCompra,
    required this.precioVentaBase,
    required this.isActive,
  });

  factory LoteProductoResponse.fromJson(Map<String, dynamic> json) {
    return LoteProductoResponse(
      id: json['id'],
      producto: json['producto'],
      productoNombre: json['producto_nombre'],
      cantidadInicial: json['cantidad_inicial'],
      cantidadActual: json['cantidad_actual'],
      precioCompra: json['precio_compra'],
      precioVentaBase: json['precio_venta_base'],
      isActive: json['is_active'],
    );
  }
}