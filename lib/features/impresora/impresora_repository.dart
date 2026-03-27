import 'dart:io';
import 'package:management_system_ui/core/common_libs.dart';

final impresoraRepositoryProvider = Provider((ref) {
  return ImpresoraRepository();
});

class ImpresoraRepository {
  /// Envía datos a la impresora por TCP socket
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

  /// Prueba la conexión a la impresora
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
