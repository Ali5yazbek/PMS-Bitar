// ─── API Service (Dio HTTP Client) ────────────────────────────────────────────
// Mirrors the axios.js setup: JWT Bearer token injected on every request,
// 401 → clear token and redirect to login.

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/app_config.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  late final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Callbacks set by auth provider to handle 401
  Function()? onUnauthorized;

  ApiService._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: AppConfig.connectTimeout,
      receiveTimeout: AppConfig.receiveTimeout,
      headers: {'Content-Type': 'application/json'},
    ));

    // ── Request interceptor: attach JWT token ──────────────────────────────
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) async {
        if (e.response?.statusCode == 401) {
          // Clear stored credentials and notify provider
          await _storage.delete(key: 'token');
          await _storage.delete(key: 'user');
          onUnauthorized?.call();
        }
        return handler.next(e);
      },
    ));
  }

  Dio get client => _dio;

  // ── Helper methods ─────────────────────────────────────────────────────────
  Future<Response> get(String path,
          {Map<String, dynamic>? queryParameters}) async =>
      _dio.get(path, queryParameters: queryParameters);

  Future<Response> post(String path, {dynamic data}) async =>
      _dio.post(path, data: data);

  Future<Response> put(String path, {dynamic data}) async =>
      _dio.put(path, data: data);

  Future<Response> delete(String path) async => _dio.delete(path);
}
