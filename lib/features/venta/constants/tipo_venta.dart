class TipoVenta {
  static const String normal = 'NORMAL';
  static const String credito = 'CREDITO';
  static const String sunat = 'SUNAT';

  static const Map<String, String> labels = {
    'NORMAL': 'Normal',
    'CREDITO': 'Crédito',
    'SUNAT': 'SUNAT',
  };

  static String getLabel(String tipo) => labels[tipo] ?? tipo;
}
