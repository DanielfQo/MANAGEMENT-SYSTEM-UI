import 'dart:io';
import 'package:management_system_ui/core/common_libs.dart';

final impresoraRepositoryProvider = Provider((ref) {
  return ImpresoraRepository();
});

class ImpresoraRepository {
  /// Envía datos a la impresora por TCP socket (WiFi)
  Future<void> enviarAImpresora(String ip, int puerto, List<int> datos) async {
    try {
      final socket = await Socket.connect(
        ip,
        puerto,
        timeout: const Duration(seconds: 10),
      );

      socket.add(datos);
      await socket.flush();
      socket.destroy();
    } on SocketException catch (e) {
      throw Exception('Error de conexión: ${e.message}');
    } catch (e) {
      throw Exception('Error al enviar a impresora: $e');
    }
  }

  /// Envía datos ESC/POS a la impresora vía CUPS (USB)
  Future<void> enviarViaCups(List<int> datos, {String? nombreImpresora}) async {
    try {
      final tempDir = Directory.systemTemp;
      final tempFile = File('${tempDir.path}/ticket_${DateTime.now().millisecondsSinceEpoch}.bin');
      await tempFile.writeAsBytes(datos);

      final args = ['-o', 'raw'];
      if (nombreImpresora != null && nombreImpresora.isNotEmpty) {
        args.addAll(['-d', nombreImpresora]);
      }
      args.add(tempFile.path);

      final result = await Process.run('lp', args);

      // Limpiar archivo temporal
      try {
        await tempFile.delete();
      } catch (_) {}

      if (result.exitCode != 0) {
        throw Exception('Error CUPS: ${result.stderr}');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Error al enviar vía CUPS: $e');
    }
  }

  /// Prueba la conexión a la impresora (WiFi)
  Future<bool> probarConexion(String ip, int puerto) async {
    try {
      final socket = await Socket.connect(
        ip,
        puerto,
        timeout: const Duration(seconds: 5),
      );
      socket.destroy();
      return true;
    } catch (e) {
      return false;
    }
  }
}
