class VentaProducto {
  final int productoId;
  final int cantidad;
  final String? precioVenta;

  VentaProducto({
    required this.productoId,
    required this.cantidad,
    this.precioVenta,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      "producto_id": productoId,
      "cantidad": cantidad,
    };

    if (precioVenta != null) {
      data["precio_venta"] = precioVenta;
    }

    return data;
  }
}

class ClienteNuevo {
  final String nombre;
  final String telefono;
  final String email;

  ClienteNuevo({
    required this.nombre,
    required this.telefono,
    required this.email,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      "nombre": nombre,
      "telefono": telefono,
      "email": email,
    };

    return data;
  }
}

class VentaModel {
  final int tiendaId;
  final String metodoPago;
  final bool esCredito;
  final int? clienteId;
  final ClienteNuevo? cliente;
  final List<VentaProducto> productos;

  VentaModel({
    required this.tiendaId,
    required this.metodoPago,
    required this.esCredito,
    this.clienteId,
    this.cliente,
    required this.productos,
  });

  VentaModel copyWith({
  int? tiendaId,
  String? metodoPago,
  bool? esCredito,
  int? clienteId,
  ClienteNuevo? cliente,
  List<VentaProducto>? productos,
  bool resetCliente = false,
  }) {
    return VentaModel(
      tiendaId: tiendaId ?? this.tiendaId,
      metodoPago: metodoPago ?? this.metodoPago,
      esCredito: esCredito ?? this.esCredito,
      clienteId: resetCliente ? clienteId : (clienteId ?? this.clienteId),
      cliente: resetCliente ? cliente : (cliente ?? this.cliente),
      productos: productos ?? this.productos,
    );
  }

  Map<String, dynamic> toJson() {
    final data = {
      "tienda_id": tiendaId,
      "metodo_pago": metodoPago,
      "es_credito": esCredito,
      "productos": productos.map((e) => e.toJson()).toList(),
    };

    if (clienteId != null) {
      data["cliente_id"] = clienteId!;
    }

    if (cliente != null) {
      data["cliente"] = cliente!.toJson();
    }

    return data;
  }
}

class VentaResponse {
  final int id;
  final String fecha;
  final String metodoPago;
  final bool esCredito;
  final double total;
  final String tiendaNombre;
  final String usuarioNombre;
  final String? clienteNombre;
  final List<DetalleVentaResponse> detalle;

  VentaResponse({
    required this.id,
    required this.fecha,
    required this.metodoPago,
    required this.esCredito,
    required this.total,
    required this.tiendaNombre,
    required this.usuarioNombre,
    required this.detalle,
    this.clienteNombre,
  });

  factory VentaResponse.fromJson(Map<String, dynamic> json) {
    return VentaResponse(
      id: json['id'],
      fecha: json['fecha'],
      metodoPago: json['metodo_pago'],
      esCredito: json['es_credito'],
      total: double.parse(json['total'].toString()),
      tiendaNombre: json['tienda']['nombre_sede'],
      usuarioNombre: json['usuario_tienda']['nombre'],
      clienteNombre: json['cliente']?['nombre'],
      detalle: (json['detalle'] as List)
          .map((e) => DetalleVentaResponse.fromJson(e))
          .toList(),
    );
  }
}

class DetalleVentaResponse {
  final String producto;
  final int cantidad;
  final String precioVenta;

  DetalleVentaResponse({
    required this.producto,
    required this.cantidad,
    required this.precioVenta,
  });

  factory DetalleVentaResponse.fromJson(Map<String, dynamic> json) {
    return DetalleVentaResponse(
      producto: json['producto'],
      cantidad: json['cantidad'],
      precioVenta: json['precio_venta'],
    );
  }
}