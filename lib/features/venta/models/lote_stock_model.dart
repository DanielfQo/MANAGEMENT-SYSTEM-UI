class LoteStockModel {
  final int productoId;
  final String productoNombre;
  final int cantidadActual;
  final String precioVentaBase;

  LoteStockModel({
    required this.productoId,
    required this.productoNombre,
    required this.cantidadActual,
    required this.precioVentaBase,
  });

  factory LoteStockModel.fromJson(Map<String, dynamic> json) {
    return LoteStockModel(
      productoId: json['producto'],
      productoNombre: json['producto_nombre'],
      cantidadActual: json['cantidad_actual'],
      precioVentaBase: json['precio_venta_base'],
    );
  }
}
