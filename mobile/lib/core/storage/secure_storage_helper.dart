import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecureStorageHelper {
  static final SecureStorageHelper instance = SecureStorageHelper._init();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  /// Instant in-memory cache so reading token/user on every API request takes 0ms.
  final Map<String, String?> _memoryCache = {};
  SharedPreferences? _prefs;

  SecureStorageHelper._init();

  Future<SharedPreferences> _getPrefs() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  Future<void> write(String key, String value) async {
    _memoryCache[key] = value;
    try {
      final prefs = await _getPrefs();
      await prefs.setString(key, value);
    } catch (_) {}

    if (!kIsWeb) {
      try {
        await _secureStorage.write(key: key, value: value);
      } catch (_) {}
    }
  }

  Future<String?> read(String key) async {
    if (_memoryCache.containsKey(key)) {
      return _memoryCache[key];
    }

    try {
      final prefs = await _getPrefs();
      final prefVal = prefs.getString(key);
      if (prefVal != null) {
        _memoryCache[key] = prefVal;
        return prefVal;
      }
    } catch (_) {}

    if (!kIsWeb) {
      try {
        final val = await _secureStorage.read(key: key);
        if (val != null) {
          _memoryCache[key] = val;
          // Mirror to SharedPreferences for instant subsequent startup reads
          _getPrefs().then((p) => p.setString(key, val));
          return val;
        }
      } catch (_) {}
    }

    _memoryCache[key] = null;
    return null;
  }

  Future<void> delete(String key) async {
    _memoryCache.remove(key);
    try {
      final prefs = await _getPrefs();
      await prefs.remove(key);
    } catch (_) {}

    if (!kIsWeb) {
      try {
        await _secureStorage.delete(key: key);
      } catch (_) {}
    }
  }
}
