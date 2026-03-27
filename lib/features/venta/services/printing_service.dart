import 'dart:io';
import 'dart:typed_data';
import 'package:management_system_ui/core/common_libs.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';

/// Servicio para descargar PDFs e imprimir en impresoras Bluetooth/de red
class PrintingService {
  final Dio _dio;

  PrintingService(this._dio);

  /// Descarga un PDF desde una URL y retorna los bytes
  Future<Uint8List> descargarPdf(String url) async {
    try {
      final response = await _dio.get<List<int>>(
        url,
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: true,
          validateStatus: (status) => status! < 500,
        ),
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Error al descargar PDF: ${response.statusCode}',
        );
      }

      return Uint8List.fromList(response.data ?? []);
    } on DioException catch (e) {
      throw Exception('Error descargando PDF: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado descargando PDF: $e');
    }
  }

  /// Abre el diálogo de impresoras disponibles para imprimir un PDF
  /// Retorna true si se imprimió exitosamente
  Future<bool> imprimirPdf(String urlPdf, {String? nombreComprobante}) async {
    try {
      // Descargar el PDF
      final bytes = await descargarPdf(urlPdf);

      // Usar el layout de impresión de Flutter
      await Printing.layoutPdf(
        onLayout: (_) async => bytes,
        name: nombreComprobante ?? 'Comprobante',
      );

      return true;
    } catch (e) {
      throw Exception('Error durante impresión: $e');
    }
  }

  /// Retorna true si hay al menos una impresora disponible
  Future<bool> hayImprosorasDisponibles() async {
    try {
      final printers = await Printing.listPrinters();
      return printers.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Obtiene la lista de impresoras disponibles
  Future<List<Printer>> obtenerImpresoras() async {
    try {
      return await Printing.listPrinters();
    } catch (e) {
      return [];
    }
  }

  /// Guarda un PDF descargado en la carpeta Downloads del dispositivo
  /// Retorna la ruta del archivo guardado
  Future<String> guardarPdfEnDescargas(
    Uint8List bytes,
    String nombreArchivo,
  ) async {
    try {
      // Obtener directorio de descargas
      Directory? downloadsDir;

      if (Platform.isAndroid) {
        // En Android, usar el directorio de Descargas
        downloadsDir = Directory('/storage/emulated/0/Download');

        // Si no existe, intentar con path_provider
        if (!downloadsDir.existsSync()) {
          downloadsDir = await getExternalStorageDirectory();
        }
      } else if (Platform.isIOS) {
        // En iOS, usar el directorio de documentos
        downloadsDir = await getApplicationDocumentsDirectory();
      } else {
        downloadsDir = await getDownloadsDirectory();
      }

      if (downloadsDir == null) {
        throw Exception('No se pudo obtener el directorio de descargas');
      }

      // Asegurar que existe el directorio
      if (!downloadsDir.existsSync()) {
        downloadsDir.createSync(recursive: true);
      }

      // Crear ruta del archivo
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = nombreArchivo.replaceAll(' ', '_');
      final filePath = '${downloadsDir.path}/${fileName}_$timestamp.pdf';

      // Guardar el archivo
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      return filePath;
    } catch (e) {
      throw Exception('Error al guardar PDF: $e');
    }
  }
}
