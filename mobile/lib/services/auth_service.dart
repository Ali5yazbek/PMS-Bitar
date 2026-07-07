// ─── Auth Service ─────────────────────────────────────────────────────────────

import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart';
import 'api_service.dart';

class AuthService {
  final ApiService _api = ApiService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Login → store token + user, return User
  Future<User> login(String loginIdentifier, String password) async {
    final response = await _api.post('/auth/login', data: {
      'loginIdentifier': loginIdentifier,
      'password': password,
    });

    final token = response.data['token'] as String;
    final userJson = response.data['user'] as Map<String, dynamic>;

    await _storage.write(key: 'token', value: token);
    await _storage.write(key: 'user', value: jsonEncode(userJson));

    return User.fromJson(userJson);
  }

  Future<void> logout() async {
    await _storage.delete(key: 'token');
    await _storage.delete(key: 'user');
  }

  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: 'token');
    return token != null && token.isNotEmpty;
  }

  Future<User?> getCurrentUser() async {
    final userJson = await _storage.read(key: 'user');
    if (userJson == null) return null;
    return User.fromJson(jsonDecode(userJson));
  }
}
