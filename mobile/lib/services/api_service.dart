// ─── High-Speed API Service (Dio HTTP Client with RAM Cache, Deduplication & Prefetch) ───
import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../core/storage/secure_storage_helper.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  late final Dio _dio;
  SharedPreferences? _prefs;

  /// In-memory response cache for 0ms page transitions
  final Map<String, dynamic> _memoryCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};

  /// Deduplicates concurrent identical GET requests
  final Map<String, Future<Response>> _inFlightGets = {};

  /// How long a live network GET stays fresh in RAM before re-fetching
  static const Duration _freshTtl = Duration(seconds: 15);

  Function()? onUnauthorized;

  Dio get client => _dio;

  ApiService._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: AppConfig.connectTimeout,
      receiveTimeout: AppConfig.receiveTimeout,
      headers: {'Content-Type': 'application/json'},
    ));

    // Pre-warm SharedPreferences in background
    SharedPreferences.getInstance().then((p) => _prefs = p).catchError((_) => null);

    // Request / Response / Error interceptor
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await SecureStorageHelper.instance.read('token');
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onResponse: (response, handler) {
        // Resolve response immediately (0ms delay), then persist to disk cache asynchronously
        handler.next(response);

        if (response.requestOptions.method == 'GET' && response.statusCode == 200) {
          final cacheKey = 'cache_${response.requestOptions.uri}';
          _memoryCache[cacheKey] = response.data;
          _cacheTimestamps[cacheKey] = DateTime.now();
          _saveToDiskAsync(cacheKey, response.data);
        }
      },
      onError: (DioException e, handler) async {
        if (e.response?.statusCode == 401) {
          final path = e.requestOptions.path;
          if (!path.contains('/auth/login')) {
            await SecureStorageHelper.instance.delete('token');
            await SecureStorageHelper.instance.delete('user');
            clearCache();
            onUnauthorized?.call();
          }
        }

        // Offline fallback for GET requests
        if (_isNetworkError(e) && e.requestOptions.method == 'GET') {
          final cacheKey = 'cache_${e.requestOptions.uri}';
          if (_memoryCache.containsKey(cacheKey)) {
            return handler.resolve(Response(
              requestOptions: e.requestOptions,
              data: _memoryCache[cacheKey],
              statusCode: 200,
            ));
          }

          final prefs = _prefs ?? await SharedPreferences.getInstance();
          final cachedData = prefs.getString(cacheKey);
          if (cachedData != null) {
            final decoded = jsonDecode(cachedData);
            _memoryCache[cacheKey] = decoded;
            return handler.resolve(Response(
              requestOptions: e.requestOptions,
              data: decoded,
              statusCode: 200,
            ));
          }
        }

        return handler.next(e);
      },
    ));
  }

  void _saveToDiskAsync(String cacheKey, dynamic data) {
    Future.microtask(() async {
      try {
        final prefs = _prefs ?? await SharedPreferences.getInstance();
        await prefs.setString(cacheKey, jsonEncode(data));
      } catch (_) {}
    });
  }

  bool _isNetworkError(DioException error) {
    return error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.connectionError;
  }

  String _buildCacheKey(String path, Map<String, dynamic>? queryParameters) {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}$path').replace(
      queryParameters: queryParameters?.map((k, v) => MapEntry(k, v?.toString() ?? '')),
    );
    return 'cache_$uri';
  }

  /// Clear RAM cache (called automatically on any POST / PUT / DELETE mutation)
  void clearCache() {
    _memoryCache.clear();
    _cacheTimestamps.clear();
  }

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    bool forceRefresh = false,
  }) async {
    final cacheKey = _buildCacheKey(path, queryParameters);

    // 1. Return fresh RAM cache in 0ms
    if (!forceRefresh && _memoryCache.containsKey(cacheKey)) {
      final ts = _cacheTimestamps[cacheKey];
      if (ts != null && DateTime.now().difference(ts) < _freshTtl) {
        return Response(
          requestOptions: RequestOptions(path: path, queryParameters: queryParameters),
          data: _memoryCache[cacheKey],
          statusCode: 200,
        );
      }
    }

    // 2. Deduplicate concurrent identical GET requests
    if (_inFlightGets.containsKey(cacheKey)) {
      return await _inFlightGets[cacheKey]!;
    }

    final future = _dio.get(path, queryParameters: queryParameters);
    _inFlightGets[cacheKey] = future;
    try {
      return await future;
    } finally {
      _inFlightGets.remove(cacheKey);
    }
  }

  Future<Response> post(String path, {dynamic data}) async {
    final res = await _dio.post(path, data: data);
    clearCache();
    return res;
  }

  Future<Response> put(String path, {dynamic data}) async {
    final res = await _dio.put(path, data: data);
    clearCache();
    return res;
  }

  Future<Response> delete(String path, {dynamic data}) async {
    final res = await _dio.delete(path, data: data);
    clearCache();
    return res;
  }

  /// Pre-fetches key screens in the background right after authentication
  /// so tab switches are instant (0ms).
  void prefetchForRole(String? role) {
    Future.microtask(() async {
      final routes = <String>[];
      switch (role) {
        case 'agent':
          routes.addAll([
            '/energy/agent/dashboard-stats',
            '/agent/smart-tasks',
            '/energy/agent/subscription-tasks',
            '/energy/agent/generator-tasks',
            '/energy/agent/apartment-tasks',
          ]);
          break;
        case 'maintenance':
          routes.addAll([
            '/maintenance/tasks',
            '/maintenance/history',
          ]);
          break;
        case 'tenant':
          routes.addAll([
            '/tenant-portal/dashboard',
            '/tenant-portal/rent-history',
          ]);
          break;
        case 'manager':
          routes.addAll([
            '/dashboard/manager',
            '/buildings',
            '/contracts',
          ]);
          break;
        default:
          // Admin
          routes.addAll([
            '/dashboard/financial-summary',
            '/dashboard/alerts',
            '/dashboard/collections',
            '/maintenance-tickets/all',
            '/maintenance/admin/tasks',
            '/buildings',
            '/tenants',
            '/contracts',
          ]);
          break;
      }

      await Future.wait(
        routes.map((r) => get(r).catchError((_) => Response(requestOptions: RequestOptions(path: r)))),
      );
    });
  }

  Future<void> syncOfflineQueue() async {
    // Sync offline queue if needed
  }
}
