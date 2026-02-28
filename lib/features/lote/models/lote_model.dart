class LoteModel {
  final int tienda;
  final String fechaLlegada;
  final String costoOperacion;
  final String costoTransporte;
  final List<LoteProducto> productos;

  LoteModel({
    required this.tienda,
    required this.fechaLlegada,
    required this.costoOperacion,
    required this.costoTransporte,
    required this.productos,
  });

  Map<String, dynamic> toJson() {
    return {
      "tienda": tienda,
      "fecha_llegada": fechaLlegada,
      "costo_operacion": costoOperacion,
      "costo_transporte": costoTransporte,
      "productos": productos.map((e) => e.toJson()).toList(),
    };
  }
}

class ProductModel {
  final int id;
  final String nombre;
  final bool isActive;

  ProductModel({
    required this.id,
    required this.nombre,
    required this.isActive,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'],
      nombre: json['nombre'],
      isActive: json['is_active'],
    );
  }
}

class LoteProducto {
  final int? productoId; // Para producto existente
  final String? nombre;  // Para producto nuevo
  final int cantidad;
  final String precioCompra;
  final String precioVentaBase;

  LoteProducto({
    this.productoId,
    this.nombre,
    required this.cantidad,
    required this.precioCompra,
    required this.precioVentaBase,
  });

  Map<String, dynamic> toJson() {
    final data = {
      "cantidad": cantidad,
      "precio_compra": precioCompra,
      "precio_venta_base": precioVentaBase,
    };

    if (productoId != null) {
      data["producto_id"] = productoId!;
    }

    if (nombre != null) {
      data["nombre"] = nombre!;
    }

    return data;
  }
}