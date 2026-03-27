import 'dart:typed_data';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';

/// Convertidor de PDF a comandos ESC/POS para impresoras térmicas
class TicketConverter {
  /// Convierte PDF bytes a comandos ESC/POS
  /// Envía el PDF como contenido raw a la impresora
  static Future<List<int>> pdfAEscPos(Uint8List pdfBytes) async {
    try {
      final profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm80, profile);

      final comandos = <int>[];

      // Inicializar impresora
      comandos.addAll(generator.reset());

      // Enviar el PDF como datos raw
      comandos.addAll(pdfBytes);

      // Espaciado y corte
      comandos.addAll(generator.feed(2));
      comandos.addAll(generator.cut());

      return comandos;
    } catch (e) {
      throw Exception('Error al convertir PDF: $e');
    }
  }
}
