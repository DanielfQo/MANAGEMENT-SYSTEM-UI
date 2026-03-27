/// Tipos de venta
class TipoVenta {
  static const String normal = 'NORMAL';
  static const String credito = 'CREDITO';
  static const String sunat = 'SUNAT';

  static const List<String> all = [normal, credito, sunat];

  static String display(String tipo) {
    switch (tipo.toUpperCase()) {
      case normal:
        return 'Venta Normal';
      case credito:
        return 'Venta a Crédito';
      case sunat:
        return 'Venta SUNAT';
      default:
        return tipo;
    }
  }
}

/// Métodos de pago
class MetodoPago {
  static const String efectivo = 'EFECTIVO';
  static const String yape = 'YAPE';
  static const String plin = 'PLIN';
  static const String transferencia = 'TRANSFERENCIA';
  static const String tarjeta = 'TARJETA';

  static const List<String> all = [
    efectivo,
    yape,
    plin,
    transferencia,
    tarjeta,
  ];

  static String display(String metodo) {
    switch (metodo.toUpperCase()) {
      case efectivo:
        return 'Efectivo';
      case yape:
        return 'Yape';
      case plin:
        return 'Plin';
      case transferencia:
        return 'Transferencia Bancaria';
      case tarjeta:
        return 'Tarjeta';
      default:
        return metodo;
    }
  }
}

/// Tipos de comprobante SUNAT
class TipoComprobanteSunat {
  static const String factura = '01';
  static const String boleta = '03';

  static const List<String> all = [factura, boleta];

  static String display(String tipo) {
    switch (tipo) {
      case factura:
        return 'Factura';
      case boleta:
        return 'Boleta';
      default:
        return tipo;
    }
  }
}

/// Tipos de documento de identidad
class TipoDocumento {
  static const String dni = '1';
  static const String ruc = '6';

  static String display(String tipo) {
    switch (tipo) {
      case dni:
        return 'DNI';
      case ruc:
        return 'RUC';
      default:
        return tipo;
    }
  }
}
