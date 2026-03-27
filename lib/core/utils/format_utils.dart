/// Formatea un double sin decimales si es entero, con decimales si los tiene
/// Ej: 5.0 → "5", 5.5 → "5.5", 200.0 → "200"
String formatCantidad(double value) {
  if (value % 1 == 0) return value.toInt().toString();
  // Eliminar ceros finales innecesarios (ej: 5.500 → "5.5")
  final str = value.toString();
  return str.contains('.')
      ? str
          .replaceAll(RegExp(r'0+$'), '')
          .replaceAll(RegExp(r'\.$'), '')
      : str;
}

/// Versión para String que viene de la API (ej: "200.000")
String formatCantidadStr(String rawStr) {
  final value = double.tryParse(rawStr);
  if (value == null) return rawStr;
  return formatCantidad(value);
}
