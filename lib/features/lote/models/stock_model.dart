class StockModel {
  final int productoId;
  final String productoNombre;
  final String unidadMedida;
  final String cantidadDisponible;
  final String precioVentaMercado;

  StockModel({
    required this.productoId,
    required this.productoNombre,
    required this.unidadMedida,
    required this.cantidadDisponible,
    required this.precioVentaMercado,
  });

  factory StockModel.fromJson(Map<String, dynamic> json) {
    return StockModel(
      productoId: json['producto_id'] as int,
      productoNombre: json['producto_nombre'] as String,
      unidadMedida: json['unidad_medida'] as String,
      cantidadDisponible: json['cantidad_disponible'].toString(),
      precioVentaMercado: json['precio_venta_mercado'].toString(),
    );
  }
}
