import 'dart:typed_data';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:image/image.dart' as img;
import 'package:printing/printing.dart';

/// Convertidor de PDF a comandos ESC/POS para impresoras térmicas
class TicketConverter {
  /// Convierte PDF bytes a comandos ESC/POS renderizando como imagen
  static Future<List<int>> pdfAEscPos(Uint8List pdfBytes) async {
    try {
      final profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm80, profile);

      final comandos = <int>[];
      comandos.addAll(generator.reset());

      // Rasterizar cada página del PDF a imagen
      await for (final page in Printing.raster(pdfBytes, dpi: 203)) {
        final pngBytes = await page.toPng();
        final image = img.decodeImage(pngBytes);
        if (image == null) continue;

        // Crear fondo blanco y componer la imagen encima
        // (Printing.raster puede generar PNGs con fondo transparente,
        // cuyos píxeles RGB son (0,0,0) y se interpretan como negro)
        final withWhiteBg = img.Image(width: image.width, height: image.height);
        img.fill(withWhiteBg, color: img.ColorRgba8(255, 255, 255, 255));
        img.compositeImage(withWhiteBg, image);

        // Redimensionar al ancho de 80mm (576px a 203dpi)
        final resized = img.copyResize(withWhiteBg, width: 576);

        comandos.addAll(generator.imageRaster(resized));
        comandos.addAll(generator.feed(1));
      }

      comandos.addAll(generator.feed(2));
      comandos.addAll(generator.cut());

      return comandos;
    } catch (e) {
      throw Exception('Error al convertir PDF: $e');
    }
  }
}
