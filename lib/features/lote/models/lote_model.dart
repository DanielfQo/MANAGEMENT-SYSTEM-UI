class LoteCreateModel {
  final int tienda;
  final String fechaLlegada;
  final String costoOperacion;
  final String costoTransporte;
  final List<LoteProductoInput> productos;

  LoteCreateModel({
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

class LoteProductoInput {
  final int? productoId; // Para producto existente
  final String? nombre;  // Para producto nuevo
  final String unidadMedida; // NIU, KGM, MTR, LTR
  final bool conFactura;
  final String cantidad; // Decimal string "200.000"
  final String cantidadAveriada; // Decimal string, defaults to "0.000"
  final String costoTotal;
  final String? precioVentaBase; // Nullable - solo para dueño
  final String precioVentaMercado;

  LoteProductoInput({
    this.productoId,
    this.nombre,
    required this.unidadMedida,
    required this.conFactura,
    required this.cantidad,
    required this.cantidadAveriada,
    required this.costoTotal,
    this.precioVentaBase,
    required this.precioVentaMercado,
  });

  Map<String, dynamic> toJson() {
    final data = {
      "unidad_medida": unidadMedida,
      "con_factura": conFactura,
      "cantidad": cantidad,
      "cantidad_averiada": cantidadAveriada,
      "costo_total": costoTotal,
      "precio_venta_mercado": precioVentaMercado,
    };

    if (productoId != null) {
      data["producto_id"] = productoId!;
    }

    if (nombre != null) {
      data["nombre"] = nombre!;
    }

    if (precioVentaBase != null) {
      data["precio_venta_base"] = precioVentaBase!;
    }

    return data;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LoteProductoInput &&
          runtimeType == other.runtimeType &&
          productoId == other.productoId &&
          nombre == other.nombre;

  @override
  int get hashCode => productoId.hashCode ^ nombre.hashCode;
}
