// ─── Auth Service (Persistent Encrypted Session + Automatic Token Refresh) ───

import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';
import '../models/user.dart';
import '../core/storage/secure_storage_helper.dart';
import 'api_service.dart';

enum RefreshResult {
  refreshed,
  transientFailure,
  revoked,
}

class AuthService {
  final ApiService _api = ApiService();

  static Completer<RefreshResult>? _refreshCompleter;
  static DateTime? _lastTransientFailureAt;

  static Map<String, dynamic>? decodeJwtPayload(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final normalized = base64Url.normalize(parts[1]);
      final payloadString = utf8.decode(base64Url.decode(normalized));
      final decoded = jsonDecode(payloadString);
      return decoded is Map ? Map<String, dynamic>.from(decoded) : null;
    } catch (_) {
      return null;
    }
  }

  /// Returns true if the JWT has expired or will expire within [bufferSeconds].
  static bool isTokenExpiringSoon(String? token, {int bufferSeconds = 120}) {
    if (token == null || token.isEmpty) return true;
    final payload = decodeJwtPayload(token);
    if (payload == null) return false;
    final exp = payload['exp'];
    if (exp is num) {
      final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      return exp.toInt() <= (nowSec + bufferSeconds);
    }
    return false;
  }

  // Login → store token + refresh_token + user, return User
  Future<User> login(String loginIdentifier, String password) async {
    final platform = kIsWeb
        ? 'web'
        : (defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android');

    final response = await _api.client.post(
      '/auth/login',
      data: {
        'loginIdentifier': loginIdentifier,
        'email': loginIdentifier,
        'username': loginIdentifier,
        'password': password,
        'platform': platform,
      },
      options: Options(headers: {'Content-Type': 'application/json'}),
    );

    final data = response.data is String ? jsonDecode(response.data) : response.data;
    final token = (data['token'] ?? '').toString();
    final refreshToken = (data['refresh_token'] ?? token).toString();
    final userRaw = data['user'];

    Map<String, dynamic> userMap = {};
    if (userRaw is Map) {
      userMap = Map<String, dynamic>.from(userRaw);
    }

    // Fallback: extract role from JWT if missing in user payload
    if ((userMap['role'] == null || userMap['role'].toString().trim().isEmpty) && token.isNotEmpty) {
      final jwtPayload = decodeJwtPayload(token);
      if (jwtPayload != null && jwtPayload['role'] != null) {
        userMap['role'] = jwtPayload['role'];
      }
    }

    final user = User.fromJson(userMap);

    await SecureStorageHelper.instance.write('token', token);
    if (refreshToken.isNotEmpty) {
      await SecureStorageHelper.instance.write('refresh_token', refreshToken);
    }
    await SecureStorageHelper.instance.write('user', jsonEncode(user.toJson()));
    _lastTransientFailureAt = null;

    return user;
  }

  /// Automatically exchanges the stored refresh_token (or signed token) for a new
  /// access token without logging the user out. Deduplicates concurrent refresh calls.
  static Future<RefreshResult> refreshSession() async {
    if (_refreshCompleter != null) {
      return _refreshCompleter!.future;
    }
    if (_lastTransientFailureAt != null &&
        DateTime.now().difference(_lastTransientFailureAt!) < const Duration(minutes: 5)) {
      return RefreshResult.transientFailure;
    }
    final completer = Completer<RefreshResult>();
    _refreshCompleter = completer;

    try {
      final token = await SecureStorageHelper.instance.read('token');
      final refreshToken = await SecureStorageHelper.instance.read('refresh_token');

      if ((token == null || token.isEmpty) && (refreshToken == null || refreshToken.isEmpty)) {
        completer.complete(RefreshResult.revoked);
        return RefreshResult.revoked;
      }

      final platform = kIsWeb
          ? 'web'
          : (defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android');

      final refreshDio = Dio(BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: 4),
        receiveTimeout: const Duration(seconds: 4),
        headers: {
          'Content-Type': 'application/json',
          if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
      ));

      final response = await refreshDio.post(
        '/auth/refresh',
        data: {
          'refresh_token': refreshToken ?? token ?? '',
          'token': token ?? '',
          'platform': platform,
        },
      );

      final data = response.data is String ? jsonDecode(response.data) : response.data;
      if (response.statusCode == 200 && data is Map && data['token'] != null) {
        final newToken = data['token'].toString();
        final newRefreshToken = (data['refresh_token'] ?? refreshToken ?? newToken).toString();

        await SecureStorageHelper.instance.write('token', newToken);
        if (newRefreshToken.isNotEmpty) {
          await SecureStorageHelper.instance.write('refresh_token', newRefreshToken);
        }

        if (data['user'] is Map) {
          final updatedUser = User.fromJson(Map<String, dynamic>.from(data['user']));
          await SecureStorageHelper.instance.write('user', jsonEncode(updatedUser.toJson()));
        }

        _lastTransientFailureAt = null;
        completer.complete(RefreshResult.refreshed);
        return RefreshResult.refreshed;
      }

      _lastTransientFailureAt = DateTime.now();
      completer.complete(RefreshResult.transientFailure);
      return RefreshResult.transientFailure;
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 401 || status == 403) {
        dynamic body = e.response?.data;
        if (body is String && body.trim().startsWith('{')) {
          try {
            body = jsonDecode(body);
          } catch (_) {}
        }
        if (body is Map && body['revoked'] == true) {
          completer.complete(RefreshResult.revoked);
          return RefreshResult.revoked;
        }
      }
      // Network timeout, offline, 404 on unmigrated server, or 5xx: preserve session!
      _lastTransientFailureAt = DateTime.now();
      completer.complete(RefreshResult.transientFailure);
      return RefreshResult.transientFailure;
    } catch (_) {
      _lastTransientFailureAt = DateTime.now();
      completer.complete(RefreshResult.transientFailure);
      return RefreshResult.transientFailure;
    } finally {
      _refreshCompleter = null;
    }
  }

  /// Proactively refreshes the access token if it is expired or close to expiry.
  static Future<void> refreshSessionIfNeeded() async {
    final token = await SecureStorageHelper.instance.read('token');
    if (isTokenExpiringSoon(token, bufferSeconds: 300)) {
      await refreshSession();
    }
  }

  Future<void> logout() async {
    final token = await SecureStorageHelper.instance.read('token');
    final refreshToken = await SecureStorageHelper.instance.read('refresh_token');

    // Clear local credentials immediately so UI transitions without waiting
    await SecureStorageHelper.instance.delete('token');
    await SecureStorageHelper.instance.delete('refresh_token');
    await SecureStorageHelper.instance.delete('user');

    // Best-effort server-side refresh token revocation
    if ((token != null && token.isNotEmpty) || (refreshToken != null && refreshToken.isNotEmpty)) {
      unawaited(Future.microtask(() async {
        try {
          final revokeDio = Dio(BaseOptions(
            baseUrl: AppConfig.apiBaseUrl,
            connectTimeout: const Duration(seconds: 5),
            receiveTimeout: const Duration(seconds: 5),
            headers: {
              'Content-Type': 'application/json',
              if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
            },
          ));
          await revokeDio.post('/auth/logout', data: {
            'refresh_token': refreshToken ?? '',
          });
        } catch (_) {}
      }));
    }
  }

  Future<bool> isLoggedIn() async {
    final token = await SecureStorageHelper.instance.read('token');
    if (token != null && token.isNotEmpty) return true;
    final refreshToken = await SecureStorageHelper.instance.read('refresh_token');
    if (refreshToken != null && refreshToken.isNotEmpty) return true;
    final userJson = await SecureStorageHelper.instance.read('user');
    return userJson != null && userJson.isNotEmpty;
  }

  Future<User?> getCurrentUser() async {
    final userJson = await SecureStorageHelper.instance.read('user');
    final token = await SecureStorageHelper.instance.read('token');

    Map<String, dynamic>? userMap;
    if (userJson != null && userJson.isNotEmpty) {
      try {
        final decoded = jsonDecode(userJson);
        if (decoded is Map) {
          userMap = Map<String, dynamic>.from(decoded);
        }
      } catch (_) {}
    }

    // Fallback to JWT payload if user storage was missing or had empty role
    if (token != null && token.isNotEmpty) {
      final jwtPayload = decodeJwtPayload(token);
      if (jwtPayload != null) {
        userMap ??= {};
        if (userMap['role'] == null || userMap['role'].toString().trim().isEmpty) {
          userMap['role'] = jwtPayload['role'];
        }
        if (userMap['name'] == null || userMap['name'].toString().trim().isEmpty) {
          userMap['name'] = jwtPayload['name'];
        }
        if (userMap['id'] == null || userMap['id'] == 0) {
          userMap['id'] = jwtPayload['user_id'];
        }
      }
    }

    if (userMap == null || userMap.isEmpty) return null;
    return User.fromJson(userMap);
  }
}
