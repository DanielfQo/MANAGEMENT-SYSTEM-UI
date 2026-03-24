class TipoAfectacionIGV {
  static const String gravado = '10';
  static const String exonerado = '20';
  static const String inafecto = '30';

  static const Map<String, String> labels = {
    gravado: 'Gravado (IGV 18%)',
    exonerado: 'Exonerado',
    inafecto: 'Inafecto',
  };

  static List<String> get values => labels.keys.toList();

  static String getLabel(String code) => labels[code] ?? code;
}