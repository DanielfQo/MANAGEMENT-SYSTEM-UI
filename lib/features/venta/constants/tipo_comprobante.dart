class TipoComprobante {
  static const String factura = '01';
  static const String boleta = '03';

  static const Map<String, String> labels = {
    '01': 'Factura',
    '03': 'Boleta',
  };

  static String getLabel(String tipo) => labels[tipo] ?? tipo;

  static const List<String> values = [factura, boleta];
}
