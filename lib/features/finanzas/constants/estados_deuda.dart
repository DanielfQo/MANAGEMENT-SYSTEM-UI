class EstadosDeuda {
  static const String activa = 'ACTIVA';
  static const String pagada = 'PAGADA';

  static const Map<String, String> labels = {
    'ACTIVA': 'Activa',
    'PAGADA': 'Pagada',
  };

  static String getLabel(String code) {
    return labels[code] ?? code;
  }

  static List<String> get values => ['ACTIVA', 'PAGADA'];
}
