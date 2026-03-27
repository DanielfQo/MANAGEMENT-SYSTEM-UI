import 'package:management_system_ui/core/common_libs.dart';
import 'package:shared_preferences/shared_preferences.dart';

final impresoraConfigProvider = NotifierProvider<ImpresoraConfigNotifier, ImpresoraConfig>(() {
  return ImpresoraConfigNotifier();
});

class ImpresoraConfig {
  final String ip;
  final int puerto;

  const ImpresoraConfig({
    required this.ip,
    required this.puerto,
  });

  bool get estaConfigura => ip.isNotEmpty;
}

class ImpresoraConfigNotifier extends Notifier<ImpresoraConfig> {
  @override
  ImpresoraConfig build() {
    _cargarConfiguracion();
    return const ImpresoraConfig(ip: '', puerto: 9100);
  }

  Future<void> _cargarConfiguracion() async {
    final prefs = await SharedPreferences.getInstance();
    final ip = prefs.getString('impresora_ip') ?? '';
    final puerto = prefs.getInt('impresora_puerto') ?? 9100;
    state = ImpresoraConfig(ip: ip, puerto: puerto);
  }

  Future<void> guardarConfiguracion(String ip, int puerto) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('impresora_ip', ip);
    await prefs.setInt('impresora_puerto', puerto);
    state = ImpresoraConfig(ip: ip, puerto: puerto);
  }

  Future<void> limpiar() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('impresora_ip');
    await prefs.remove('impresora_puerto');
    state = const ImpresoraConfig(ip: '', puerto: 9100);
  }
}
