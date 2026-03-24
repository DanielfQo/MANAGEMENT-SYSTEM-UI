class UnidadMedida {
  static const String unidad = 'NIU';
  static const String kilogramo = 'KGM';
  static const String metro = 'MTR';
  static const String litro = 'LTR';
  static const String bolsa = 'BG';
  static const String caja = 'BX';
  static const String metroCuadrado = 'MTK';
  static const String metroCubico = 'MTQ';
  static const String kit = 'KT';
  static const String juego = 'SET';
  static const String paquete = 'PK';
  static const String tubo = 'TU';
  static const String par = 'PR';
  static const String lata = 'CA';
  static const String balde = 'BJ';
  static const String cilindro = 'CY';
  static const String centimetro = 'CMT';
  static const String milimetro = 'MMT';
  static const String galon = 'GLL';
  static const String docena = 'DZN';
  static const String pieza = 'C62';
  static const String gramo = 'GRM';
  static const String mililitro = 'MLT';
  static const String pie = 'FOT';
  static const String servicio = 'ZZ';

  static const Map<String, String> labels = {
    unidad: 'Unidad',
    kilogramo: 'Kilogramo',
    metro: 'Metro',
    litro: 'Litro',
    bolsa: 'Bolsa',
    caja: 'Caja',
    metroCuadrado: 'Metro cuadrado',
    metroCubico: 'Metro cúbico',
    kit: 'Kit',
    juego: 'Juego',
    paquete: 'Paquete',
    tubo: 'Tubo',
    par: 'Par',
    lata: 'Lata',
    balde: 'Balde',
    cilindro: 'Cilindro',
    centimetro: 'Centímetro lineal',
    milimetro: 'Milímetro',
    galon: 'Galón',
    docena: 'Docena',
    pieza: 'Pieza',
    gramo: 'Gramo',
    mililitro: 'Mililitro',
    pie: 'Pie',
    servicio: 'Servicio',
  };

  static List<String> get values => labels.keys.toList();

  static String getLabel(String code) => labels[code] ?? code;
}