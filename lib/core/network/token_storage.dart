// lib/core/network/token_storage.dart
//
// Guarda los tokens de sesión cifrados (Keychain en iOS, Keystore en Android).
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const _kAccess = 'um_access_token';
  static const _kRefresh = 'um_refresh_token';

  final FlutterSecureStorage _storage;

  // Cachea en memoria para no leer el almacenamiento seguro en cada petición.
  String? _access;
  String? _refresh;
  bool _loaded = false;

  TokenStorage([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  Future<void> _load() async {
    if (_loaded) return;
    try {
      _access = await _storage.read(key: _kAccess);
      _refresh = await _storage.read(key: _kRefresh);
    } catch (_) {
      // Si el almacenamiento quedó corrupto (p. ej. tras restaurar una copia), se empieza de cero.
      _access = null;
      _refresh = null;
    }
    _loaded = true;
  }

  Future<String?> get accessToken async {
    await _load();
    return _access;
  }

  Future<String?> get refreshToken async {
    await _load();
    return _refresh;
  }

  Future<void> save(String access, String refresh) async {
    _access = access;
    _refresh = refresh;
    _loaded = true;
    await _storage.write(key: _kAccess, value: access);
    await _storage.write(key: _kRefresh, value: refresh);
  }

  Future<void> clear() async {
    _access = null;
    _refresh = null;
    _loaded = true;
    try {
      await _storage.delete(key: _kAccess);
      await _storage.delete(key: _kRefresh);
    } catch (_) {}
  }
}
