import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecureStorageHelper {
  static final SecureStorageHelper instance = SecureStorageHelper._init();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      resetOnError: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  /// Instant in-memory cache so reading token/user on every API request takes 0ms.
  final Map<String, String> _memoryCache = {};
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
      await prefs.setString('auth_persist_$key', value);
    } catch (_) {}

    if (!kIsWeb) {
      try {
        await _secureStorage.write(key: key, value: value);
      } catch (_) {}
    }
  }

  Future<String?> read(String key) async {
    final memVal = _memoryCache[key];
    if (memVal != null && memVal.isNotEmpty) {
      return memVal;
    }

    if (!kIsWeb) {
      try {
        final val = await _secureStorage.read(key: key);
        if (val != null && val.isNotEmpty) {
          _memoryCache[key] = val;
          // Mirror to SharedPreferences for instant subsequent startup reads
          _getPrefs().then((p) {
            p.setString(key, val);
            p.setString('auth_persist_$key', val);
          }).catchError((_) {});
          return val;
        }
      } catch (_) {}
    }

    try {
      final prefs = await _getPrefs();
      final prefVal = prefs.getString(key) ?? prefs.getString('auth_persist_$key');
      if (prefVal != null && prefVal.isNotEmpty) {
        _memoryCache[key] = prefVal;
        if (!kIsWeb) {
          _secureStorage.write(key: key, value: prefVal).catchError((_) {});
        }
        return prefVal;
      }
    } catch (_) {}

    // Never cache null in _memoryCache so transient locked-device reads never poison the session
    return null;
  }

  Future<void> delete(String key) async {
    _memoryCache.remove(key);
    try {
      final prefs = await _getPrefs();
      await prefs.remove(key);
      await prefs.remove('auth_persist_$key');
    } catch (_) {}

    if (!kIsWeb) {
      try {
        await _secureStorage.delete(key: key);
      } catch (_) {}
    }
  }
}
