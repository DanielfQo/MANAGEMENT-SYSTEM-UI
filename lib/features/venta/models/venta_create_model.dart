import 'package:management_system_ui/features/venta/models/cliente_model.dart';

class VentaProductoItem {
  final int? loteProductoId;
  final int? productoId;
  final String cantidad;
  final String? precioVenta;
  final bool esAveriado;

  VentaProductoItem({
    this.loteProductoId,
    this.productoId,
    required this.cantidad,
    this.precioVenta,
    this.esAveriado = false,
  });

  /// Valida que el producto sea válido
  /// Requiere al menos uno de: productoId o loteProductoId
  /// Cantidad debe ser > 0
  String? validate() {
    if ((loteProductoId == null || loteProductoId == 0) &&
        (productoId == null || productoId == 0)) {
      return 'Producto debe tener producto_id o lote_producto_id';
    }

    final cantidadNum = double.tryParse(cantidad);
    if (cantidadNum == null || cantidadNum <= 0) {
      return 'Cantidad debe ser un número mayor a 0';
    }

    return null;
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'cantidad': cantidad,
      'es_averiado': esAveriado,
    };

    if (loteProductoId != null && loteProductoId! > 0) {
      map['lote_producto_id'] = loteProductoId;
    } else if (productoId != null && productoId! > 0) {
      map['producto_id'] = productoId;
    }

    if (precioVenta != null && precioVenta!.isNotEmpty) {
      map['precio_venta'] = precioVenta;
    }

    return map;
  }

  VentaProductoItem copyWith({
    int? loteProductoId,
    int? productoId,
    String? cantidad,
    String? precioVenta,
    bool? esAveriado,
  }) {
    return VentaProductoItem(
      loteProductoId: loteProductoId ?? this.loteProductoId,
      productoId: productoId ?? this.productoId,
      cantidad: cantidad ?? this.cantidad,
      precioVenta: precioVenta ?? this.precioVenta,
      esAveriado: esAveriado ?? this.esAveriado,
    );
  }
}

class VentaCreateModel {
  final int tiendaId;
  final String tipo;
  final String metodoPago;
  final String? tipoComprobante;
  final int? clienteId;
  final ClienteNuevoInput? clienteNuevo;
  final List<VentaProductoItem> productos;
  final Map<String, String>? camposFaltantesClienteExistente;

  VentaCreateModel({
    required this.tiendaId,
    required this.tipo,
    required this.metodoPago,
    this.tipoComprobante,
    this.clienteId,
    this.clienteNuevo,
    required this.productos,
    this.camposFaltantesClienteExistente,
  });

  /// Valida todos los campos según el tipo de venta
  /// Retorna un mensaje de error si hay problemas, null si es válido
  String? validate() {
    // Validar tienda
    if (tiendaId <= 0) {
      return 'Tienda es requerida';
    }

    // Validar método de pago
    if (metodoPago.isEmpty) {
      return 'Método de pago es requerido';
    }

    // Validar productos
    if (productos.isEmpty) {
      return 'Debe agregar al menos un producto';
    }

    // Validar cada producto
    for (final producto in productos) {
      final error = producto.validate();
      if (error != null) return error;
    }

    // Validaciones específicas por tipo
    switch (tipo.toUpperCase()) {
      case 'NORMAL':
        return _validateNormal();

      case 'CREDITO':
        return _validateCredito();

      case 'SUNAT':
        return _validateSunat();

      default:
        return 'Tipo de venta no válido: $tipo';
    }
  }

  /// Venta NORMAL: cliente opcional, tipo_comprobante no aplica
  String? _validateNormal() {
    // Cliente es opcional - sin validaciones adicionales
    return null;
  }

  /// Venta CREDITO: cliente requerido, tipo_comprobante no aplica
  String? _validateCredito() {
    if (clienteId == null && clienteNuevo == null) {
      return 'Cliente es requerido para ventas a crédito';
    }

    if (clienteNuevo != null) {
      return _validateClienteNuevo('CREDITO');
    }

    return null;
  }

  /// Venta SUNAT: tipo_comprobante requerido
  String? _validateSunat() {
    if (tipoComprobante == null || tipoComprobante!.isEmpty) {
      return 'Tipo de comprobante es requerido para ventas SUNAT';
    }

    if (tipoComprobante != '01' && tipoComprobante != '03') {
      return 'Tipo de comprobante debe ser 01 (Factura) o 03 (Boleta)';
    }

    // Factura (01) requiere cliente con RUC
    if (tipoComprobante == '01') {
      if (clienteId == null && clienteNuevo == null) {
        return 'Cliente es requerido para facturas';
      }

      if (clienteNuevo != null) {
        return _validateClienteNuevo('SUNAT_FACTURA');
      }
    }

    // Boleta (03) permite cliente sin RUC o sin cliente
    if (tipoComprobante == '03' && clienteNuevo != null) {
      return _validateClienteNuevo('SUNAT_BOLETA');
    }

    return null;
  }

  /// Valida cliente nuevo según tipo de venta
  String? _validateClienteNuevo(String ventaTipo) {
    if (clienteNuevo == null) return null;

    switch (ventaTipo) {
      case 'CREDITO':
        return _validateClienteCredito();

      case 'SUNAT_FACTURA':
        return _validateClienteSunatFactura();

      case 'SUNAT_BOLETA':
        return _validateClienteSunatBoleta();

      default:
        return null;
    }
  }

  /// Cliente para CREDITO: TODOS los campos son requeridos
  /// nombre, tipo_documento, numero_documento, telefono, email, direccion
  String? _validateClienteCredito() {
    if (clienteNuevo == null) return null;

    final nombre = clienteNuevo!.nombre.trim();
    if (nombre.isEmpty) {
      return 'Nombre de cliente es requerido para crédito';
    }

    final tipoDocumento = clienteNuevo!.tipoDocumento.trim();
    if (tipoDocumento.isEmpty) {
      return 'Tipo de documento es requerido para crédito';
    }

    final numeroDocumento = clienteNuevo!.numeroDocumento.trim();
    if (numeroDocumento.isEmpty) {
      return 'Número de documento es requerido para crédito';
    }

    final telefono = clienteNuevo!.telefono.trim();
    if (telefono.isEmpty) {
      return 'Teléfono es requerido para crédito';
    }

    final email = clienteNuevo!.email.trim();
    if (email.isEmpty) {
      return 'Email es requerido para crédito';
    }

    final direccion = clienteNuevo!.direccion.trim();
    if (direccion.isEmpty) {
      return 'Dirección es requerida para crédito';
    }

    return null;
  }

  /// Cliente para SUNAT FACTURA: nombre, tipo_documento="6", numero_documento requeridos
  /// numero_documento debe ser RUC válido (11 dígitos)
  /// telefono, email, direccion son opcionales
  String? _validateClienteSunatFactura() {
    if (clienteNuevo == null) return null;

    final nombre = clienteNuevo!.nombre.trim();
    if (nombre.isEmpty) {
      return 'Nombre de cliente/empresa es requerido para factura';
    }

    final tipoDocumento = clienteNuevo!.tipoDocumento.trim();
    if (tipoDocumento.isEmpty || tipoDocumento != '6') {
      return 'Tipo de documento DEBE ser RUC (tipo_documento: 6) para factura';
    }

    final numeroDocumento = clienteNuevo!.numeroDocumento.trim();
    if (numeroDocumento.isEmpty) {
      return 'RUC es requerido para factura';
    }

    if (numeroDocumento.length != 11 || !RegExp(r'^\d+$').hasMatch(numeroDocumento)) {
      return 'RUC debe ser exactamente 11 dígitos numéricos';
    }

    return null;
  }

  /// Cliente para SUNAT BOLETA: nombre y numero_documento requeridos
  /// tipo_documento es opcional (default "1"), pero NO puede ser "6" (RUC)
  /// telefono, email, direccion son opcionales
  String? _validateClienteSunatBoleta() {
    if (clienteNuevo == null) return null;

    final nombre = clienteNuevo!.nombre.trim();
    if (nombre.isEmpty) {
      return 'Nombre de cliente es requerido para boleta';
    }

    final numeroDocumento = clienteNuevo!.numeroDocumento.trim();
    if (numeroDocumento.isEmpty) {
      return 'Número de documento es requerido para boleta';
    }

    final tipoDocumento = clienteNuevo!.tipoDocumento.trim();
    if (tipoDocumento.isNotEmpty && tipoDocumento == '6') {
      return 'Para boletas no puede usar RUC (tipo_documento: 6). Debe ser DNI u otro tipo de documento';
    }

    return null;
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'tienda_id': tiendaId,
      'tipo': tipo,
      'metodo_pago': metodoPago,
      'productos': productos.map((p) => p.toJson()).toList(),
    };

    // Solo agregar tipo_comprobante para SUNAT
    if (tipo.toUpperCase() == 'SUNAT' && tipoComprobante != null && tipoComprobante!.isNotEmpty) {
      map['tipo_comprobante'] = tipoComprobante;
    }

    if (clienteId != null && clienteId! > 0) {
      map['cliente_id'] = clienteId;
      // Incluir campos faltantes si se completaron
      if (camposFaltantesClienteExistente != null &&
          camposFaltantesClienteExistente!.isNotEmpty) {
        map['cliente_campos_adicionales'] = camposFaltantesClienteExistente;
      }
    } else if (clienteNuevo != null) {
      map['cliente'] = clienteNuevo!.toJson();
    }

    return map;
  }

  VentaCreateModel copyWith({
    int? tiendaId,
    String? tipo,
    String? metodoPago,
    String? tipoComprobante,
    int? clienteId,
    ClienteNuevoInput? clienteNuevo,
    List<VentaProductoItem>? productos,
    Map<String, String>? camposFaltantesClienteExistente,
  }) {
    return VentaCreateModel(
      tiendaId: tiendaId ?? this.tiendaId,
      tipo: tipo ?? this.tipo,
      metodoPago: metodoPago ?? this.metodoPago,
      tipoComprobante: tipoComprobante ?? this.tipoComprobante,
      clienteId: clienteId ?? this.clienteId,
      clienteNuevo: clienteNuevo ?? this.clienteNuevo,
      productos: productos ?? this.productos,
      camposFaltantesClienteExistente: camposFaltantesClienteExistente ??
          this.camposFaltantesClienteExistente,
    );
  }
}

class ConfirmarSunatItem {
  final int loteProductoId;
  final String cantidad;
  final String precio;
  final bool esRelleno;
  final int? loteProductoOriginalId;

  ConfirmarSunatItem({
    required this.loteProductoId,
    required this.cantidad,
    required this.precio,
    required this.esRelleno,
    this.loteProductoOriginalId,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'lote_producto_id': loteProductoId,
      'cantidad': cantidad,
      'precio': precio,
      'es_relleno': esRelleno,
    };

    if (loteProductoOriginalId != null) {
      map['lote_producto_original_id'] = loteProductoOriginalId;
    }

    return map;
  }
}
