class AppConstants {
    static const bool _isEmulator = bool.fromEnvironment('IS_EMULATOR', defaultValue: false);
    static const String apiBaseUrl = _isEmulator
        ? "http://10.0.2.2:8000/api/"
        : "http://127.0.0.1:8000/api/";
    static const String inviteBaseUrl = "myapp://invite";
}

class Roles {
  static const String dueno        = 'DUENO';
  static const String administrador = 'ADMINISTRADOR';
  static const String trabajador   = 'TRABAJADOR';

  static const List<String> requiresStore = [administrador, trabajador];
}