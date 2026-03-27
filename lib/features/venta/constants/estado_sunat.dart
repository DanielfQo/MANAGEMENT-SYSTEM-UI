import 'package:flutter/material.dart';

class EstadoSUNAT {
  static const String noAplica = 'NO_APLICA';
  static const String pendiente = 'PENDIENTE';
  static const String enviado = 'ENVIADO';
  static const String aceptado = 'ACEPTADO';
  static const String rechazado = 'RECHAZADO';
  static const String anulado = 'ANULADO';

  static const Map<String, String> labels = {
    'NO_APLICA': 'No aplica',
    'PENDIENTE': 'Pendiente de confirmación',
    'ENVIADO': 'Enviado al PSE',
    'ACEPTADO': 'Aceptado por SUNAT',
    'RECHAZADO': 'Rechazado por SUNAT',
    'ANULADO': 'Anulado',
  };

  static const Map<String, Color> colors = {
    'ACEPTADO': Colors.green,
    'PENDIENTE': Color(0xFFF57C00),
    'ENVIADO': Color(0xFF1976D2),
    'RECHAZADO': Colors.red,
    'ANULADO': Colors.grey,
    'NO_APLICA': Colors.grey,
  };

  static String getLabel(String estado) => labels[estado] ?? estado;

  static Color getColor(String estado) => colors[estado] ?? Colors.grey;
}
