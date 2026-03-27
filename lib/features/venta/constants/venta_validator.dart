/// Validador de ventas según tipo
class VentaValidator {
  /// Valida que los campos requeridos estén presentes según el tipo de venta
  static String? validarVenta({
    required String tipo,
    required String? metodoPago,
    required String? tipoComprobante,
    required int? clienteId,
    required Map<String, dynamic>? clienteNuevo,
    required List<dynamic>? productos,
  }) {
    // Validar método de pago
    if (metodoPago == null || metodoPago.isEmpty) {
      return 'El método de pago es requerido';
    }

    // Validar productos
    if (productos == null || productos.isEmpty) {
      return 'Debe agregar al menos un producto';
    }

    // Validaciones específicas por tipo
    switch (tipo.toUpperCase()) {
      case 'NORMAL':
        return _validarVentaNormal(clienteId, clienteNuevo);

      case 'CREDITO':
        return _validarVentaCredito(clienteId, clienteNuevo);

      case 'SUNAT':
        return _validarVentaSunat(
          tipoComprobante,
          clienteId,
          clienteNuevo,
        );

      default:
        return 'Tipo de venta no válido';
    }
  }

  /// Valida venta NORMAL
  /// Cliente es OPCIONAL
  static String? _validarVentaNormal(int? clienteId, Map<String, dynamic>? clienteNuevo) {
    // Tanto clienteId como clienteNuevo son opcionales
    return null;
  }

  /// Valida venta CREDITO
  /// Cliente es REQUERIDO
  static String? _validarVentaCredito(int? clienteId, Map<String, dynamic>? clienteNuevo) {
    if (clienteId == null && clienteNuevo == null) {
      return 'Cliente es requerido para ventas a crédito';
    }

    if (clienteNuevo != null) {
      return _validarClienteNuevo(
        clienteNuevo,
        tipo: 'CREDITO',
      );
    }

    return null;
  }

  /// Valida venta SUNAT
  /// tipo_comprobante es REQUERIDO ("01" para Factura, "03" para Boleta)
  static String? _validarVentaSunat(
    String? tipoComprobante,
    int? clienteId,
    Map<String, dynamic>? clienteNuevo,
  ) {
    // Validar tipo de comprobante
    if (tipoComprobante == null || tipoComprobante.isEmpty) {
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
        return _validarClienteNuevo(
          clienteNuevo,
          tipo: 'SUNAT_FACTURA',
        );
      }
    }

    // Boleta (03) permite cliente sin RUC o sin cliente
    if (tipoComprobante == '03' && clienteNuevo != null) {
      return _validarClienteNuevo(
        clienteNuevo,
        tipo: 'SUNAT_BOLETA',
      );
    }

    return null;
  }

  /// Valida datos del cliente nuevo según tipo de venta
  static String? _validarClienteNuevo(
    Map<String, dynamic> cliente, {
    required String tipo,
  }) {
    switch (tipo) {
      case 'CREDITO':
        return _validarClienteCredito(cliente);

      case 'SUNAT_FACTURA':
        return _validarClienteSunatFactura(cliente);

      case 'SUNAT_BOLETA':
        return _validarClienteSunatBoleta(cliente);

      default:
        return null;
    }
  }

  /// Valida cliente para CREDITO (todos los campos requeridos)
  static String? _validarClienteCredito(Map<String, dynamic> cliente) {
    final nombre = cliente['nombre']?.toString().trim();
    if (nombre == null || nombre.isEmpty) {
      return 'Nombre de cliente es requerido';
    }

    final tipoDocumento = cliente['tipo_documento']?.toString().trim();
    if (tipoDocumento == null || tipoDocumento.isEmpty) {
      return 'Tipo de documento es requerido';
    }

    final numeroDocumento = cliente['numero_documento']?.toString().trim();
    if (numeroDocumento == null || numeroDocumento.isEmpty) {
      return 'Número de documento es requerido';
    }

    final telefono = cliente['telefono']?.toString().trim();
    if (telefono == null || telefono.isEmpty) {
      return 'Teléfono es requerido';
    }

    final email = cliente['email']?.toString().trim();
    if (email == null || email.isEmpty) {
      return 'Email es requerido';
    }

    final direccion = cliente['direccion']?.toString().trim();
    if (direccion == null || direccion.isEmpty) {
      return 'Dirección es requerida';
    }

    return null;
  }

  /// Valida cliente para SUNAT FACTURA (RUC de 11 dígitos)
  static String? _validarClienteSunatFactura(Map<String, dynamic> cliente) {
    final nombre = cliente['nombre']?.toString().trim();
    if (nombre == null || nombre.isEmpty) {
      return 'Nombre de cliente es requerido';
    }

    final tipoDocumento = cliente['tipo_documento']?.toString().trim() ?? '6';
    if (tipoDocumento != '6') {
      return 'Para facturas debe proporcionar un RUC (tipo_documento: 6)';
    }

    final numeroDocumento = cliente['numero_documento']?.toString().trim();
    if (numeroDocumento == null || numeroDocumento.isEmpty) {
      return 'RUC es requerido para facturas';
    }

    if (numeroDocumento.length != 11 || !RegExp(r'^\d+$').hasMatch(numeroDocumento)) {
      return 'RUC debe tener exactamente 11 dígitos';
    }

    return null;
  }

  /// Valida cliente para SUNAT BOLETA (sin RUC)
  static String? _validarClienteSunatBoleta(Map<String, dynamic> cliente) {
    final nombre = cliente['nombre']?.toString().trim();
    if (nombre == null || nombre.isEmpty) {
      return 'Nombre de cliente es requerido';
    }

    final numeroDocumento = cliente['numero_documento']?.toString().trim();
    if (numeroDocumento == null || numeroDocumento.isEmpty) {
      return 'Número de documento es requerido para boletas';
    }

    final tipoDocumento = cliente['tipo_documento']?.toString().trim() ?? '1';
    if (tipoDocumento == '6') {
      return 'Para boletas no puede usar RUC (tipo_documento: 6)';
    }

    return null;
  }

  /// Valida producto (debe tener productoId o loteProductoId)
  static String? validarProducto(Map<String, dynamic> producto) {
    final productoId = producto['producto_id'];
    final loteProductoId = producto['lote_producto_id'];

    if ((productoId == null || productoId.toString().isEmpty) &&
        (loteProductoId == null || loteProductoId.toString().isEmpty)) {
      return 'Producto debe tener producto_id o lote_producto_id';
    }

    final cantidad = double.tryParse(producto['cantidad']?.toString() ?? '0') ?? 0;
    if (cantidad <= 0) {
      return 'Cantidad debe ser mayor a 0';
    }

    return null;
  }
}
