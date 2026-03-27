class MetodoPago {
  static const String efectivo = 'EFECTIVO';
  static const String yape = 'YAPE';
  static const String plin = 'PLIN';
  static const String transferencia = 'TRANSFERENCIA';
  static const String tarjeta = 'TARJETA';

  static const Map<String, String> labels = {
    'EFECTIVO': 'Efectivo',
    'YAPE': 'Yape',
    'PLIN': 'Plin',
    'TRANSFERENCIA': 'Transferencia bancaria',
    'TARJETA': 'Tarjeta de débito/crédito',
  };

  static String getLabel(String metodo) => labels[metodo] ?? metodo;

  static const List<String> values = [
    efectivo,
    yape,
    plin,
    transferencia,
    tarjeta,
  ];
}
