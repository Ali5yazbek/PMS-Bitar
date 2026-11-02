// ─── Auth Service ─────────────────────────────────────────────────────────────

import 'dart:convert';
import 'package:dio/dio.dart';
import '../models/user.dart';
import '../core/storage/secure_storage_helper.dart';
import 'api_service.dart';

class AuthService {
  final ApiService _api = ApiService();

  // Login → store token + user, return User
  Future<User> login(String loginIdentifier, String password) async {
    final response = await _api.client.post(
      '/auth/login',
      data: {
        'loginIdentifier': loginIdentifier,
        'email': loginIdentifier,
        'username': loginIdentifier,
        'password': password,
      },
      options: Options(headers: {'Content-Type': 'application/json'}),
    );

    final data = response.data is String ? jsonDecode(response.data) : response.data;
    final token = data['token'] as String;
    final userJson = data['user'] as Map<String, dynamic>;

    await SecureStorageHelper.instance.write('token', token);
    await SecureStorageHelper.instance.write('user', jsonEncode(userJson));

    return User.fromJson(userJson);
  }

  Future<void> logout() async {
    await SecureStorageHelper.instance.delete('token');
    await SecureStorageHelper.instance.delete('user');
  }

  Future<bool> isLoggedIn() async {
    final token = await SecureStorageHelper.instance.read('token');
    return token != null && token.isNotEmpty;
  }

  Future<User?> getCurrentUser() async {
    final userJson = await SecureStorageHelper.instance.read('user');
    if (userJson == null) return null;
    return User.fromJson(jsonDecode(userJson));
  }
}
