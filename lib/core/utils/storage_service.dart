import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class SessionStorage {
  Future<void> saveToken(String token);
  Future<String?> getToken();

  Future<void> saveRefreshToken(String token);
  Future<String?> getRefreshToken();

  Future<void> clearAuthTokens();

  Future<void> setLastTiendaId(int tiendaId);
  Future<int?> getLastTiendaId();
}

final sessionStorageProvider = Provider<SessionStorage>((ref) {
  return SecureSessionStorage(
    secureStorage: const FlutterSecureStorage(),
    preferencesFuture: SharedPreferences.getInstance(),
  );
});

class SecureSessionStorage implements SessionStorage {
  SecureSessionStorage({
    required FlutterSecureStorage secureStorage,
    required Future<SharedPreferences> preferencesFuture,
  })  : _secureStorage = secureStorage,
        _preferencesFuture = preferencesFuture;

  final FlutterSecureStorage _secureStorage;
  final Future<SharedPreferences> _preferencesFuture;

  static const _tokenKey = 'token';
  static const _refreshTokenKey = 'refresh_token';
  static const _lastTiendaIdKey = 'last_tienda_id';

  @override
  Future<void> saveToken(String token) {
    return _secureStorage.write(key: _tokenKey, value: token.trim());
  }

  @override
  Future<String?> getToken() {
    return _secureStorage.read(key: _tokenKey);
  }

  @override
  Future<void> saveRefreshToken(String token) {
    return _secureStorage.write(key: _refreshTokenKey, value: token.trim());
  }

  @override
  Future<String?> getRefreshToken() {
    return _secureStorage.read(key: _refreshTokenKey);
  }

  @override
  Future<void> clearAuthTokens() async {
    await _secureStorage.delete(key: _tokenKey);
    await _secureStorage.delete(key: _refreshTokenKey);
  }

  @override
  Future<void> setLastTiendaId(int tiendaId) async {
    final prefs = await _preferencesFuture;
    await prefs.setInt(_lastTiendaIdKey, tiendaId);
  }

  @override
  Future<int?> getLastTiendaId() async {
    final prefs = await _preferencesFuture;
    return prefs.getInt(_lastTiendaIdKey);
  }
}