import 'package:management_system_ui/core/common_libs.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum TipoConexionImpresora { wifi, usbCups }

final impresoraConfigProvider = NotifierProvider<ImpresoraConfigNotifier, ImpresoraConfig>(() {
  return ImpresoraConfigNotifier();
});

class ImpresoraConfig {
  final String ip;
  final int puerto;
  final TipoConexionImpresora tipoConexion;

  const ImpresoraConfig({
    required this.ip,
    required this.puerto,
    this.tipoConexion = TipoConexionImpresora.wifi,
  });

  bool get estaConfigura =>
      tipoConexion == TipoConexionImpresora.usbCups || ip.isNotEmpty;

  bool get esUsbCups => tipoConexion == TipoConexionImpresora.usbCups;
  bool get esWifi => tipoConexion == TipoConexionImpresora.wifi;
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
    final tipoStr = prefs.getString('impresora_tipo_conexion') ?? 'wifi';
    final tipo = tipoStr == 'usb_cups'
        ? TipoConexionImpresora.usbCups
        : TipoConexionImpresora.wifi;
    state = ImpresoraConfig(ip: ip, puerto: puerto, tipoConexion: tipo);
  }

  Future<void> guardarConfiguracion(String ip, int puerto,
      {TipoConexionImpresora tipoConexion = TipoConexionImpresora.wifi}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('impresora_ip', ip);
    await prefs.setInt('impresora_puerto', puerto);
    await prefs.setString('impresora_tipo_conexion',
        tipoConexion == TipoConexionImpresora.usbCups ? 'usb_cups' : 'wifi');
    state = ImpresoraConfig(ip: ip, puerto: puerto, tipoConexion: tipoConexion);
  }

  Future<void> limpiar() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('impresora_ip');
    await prefs.remove('impresora_puerto');
    await prefs.remove('impresora_tipo_conexion');
    state = const ImpresoraConfig(ip: '', puerto: 9100);
  }
}
