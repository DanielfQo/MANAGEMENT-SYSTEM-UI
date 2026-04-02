class ProductoCatalogoModel {
  final int productoId;
  final String nombre;
  final String codigo;
  final String? imagen;
  final String tipoIgv;
  final bool isActive;
  final String unidadMedida;
  final String cantidadDisponible;
  final String cantidadAveriada;
  final bool tieneConFactura;
  final bool tieneSinFactura;
  final String precioVentaMercado;
  final num? precioVentaBase;

  ProductoCatalogoModel({
    required this.productoId,
    required this.nombre,
    required this.codigo,
    this.imagen,
    required this.tipoIgv,
    required this.isActive,
    required this.unidadMedida,
    required this.cantidadDisponible,
    required this.cantidadAveriada,
    required this.tieneConFactura,
    required this.tieneSinFactura,
    required this.precioVentaMercado,
    this.precioVentaBase,
  });

  factory ProductoCatalogoModel.fromJson(Map<String, dynamic> json) {
    return ProductoCatalogoModel(
      productoId: json['producto_id'] as int,
      nombre: json['nombre'] as String,
      codigo: json['codigo'] as String,
      imagen: json['imagen'] as String?,
      tipoIgv: json['tipo_igv'] as String,
      isActive: json['is_active'] as bool,
      unidadMedida: json['unidad_medida'] as String,
      cantidadDisponible: json['cantidad_disponible'] as String,
      cantidadAveriada: json['cantidad_averiada'] as String,
      tieneConFactura: json['tiene_con_factura'] as bool,
      tieneSinFactura: json['tiene_sin_factura'] as bool,
      precioVentaMercado: json['precio_venta_mercado'] as String,
      precioVentaBase: json['precio_venta_base'] as num?,
    );
  }
}
