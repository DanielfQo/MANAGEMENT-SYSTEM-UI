import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static String? _token;
  static String? _refreshToken;

  static Future<void> saveToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token.trim());
  }

  static Future<String?> getToken() async {
    if (_token != null) return _token;
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    return _token;
  }

  static Future<void> saveRefreshToken(String token) async {
    _refreshToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('refresh_token', token.trim());
  }

  static Future<String?> getRefreshToken() async {
    if (_refreshToken != null) return _refreshToken;
    final prefs = await SharedPreferences.getInstance();
    _refreshToken = prefs.getString('refresh_token');
    return _refreshToken;
  }

  static Future<void> clearToken() async {
    _token = null;
    _refreshToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('refresh_token');
  }

  static Future<void> setLastTiendaId(int tiendaId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('last_tienda_id', tiendaId);
  }

  static Future<int?> getLastTiendaId() async {
    final prefs = await SharedPreferences.getInstance();
    final tiendaId = prefs.getInt('last_tienda_id');
    return tiendaId;
  }
}