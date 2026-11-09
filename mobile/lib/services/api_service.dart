// ─── High-Speed API Service (Bounded LRU Cache, Background Isolate JSON & Idempotency) ───
import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../core/storage/secure_storage_helper.dart';
import 'auth_service.dart';

/// Top-level function for background isolate JSON decoding via `compute()`
dynamic _decodeJsonInIsolate(String text) {
  return jsonDecode(text);
}

class _IsolateJsonTransformer extends BackgroundTransformer {
  _IsolateJsonTransformer() : super();

  @override
  Future transformResponse(
    RequestOptions options,
    ResponseBody responseBody,
  ) async {
    final response = await super.transformResponse(options, responseBody);
    if (!kIsWeb && response is String && response.length > 32768) {
      final trimmed = response.trimLeft();
      if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
        try {
          return await compute(_decodeJsonInIsolate, response);
        } catch (_) {}
      }
    } else if (kIsWeb && response is String) {
      final trimmed = response.trimLeft();
      if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
        try {
          return jsonDecode(response);
        } catch (_) {}
      }
    }
    return response;
  }
}

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  late final Dio _dio;
  SharedPreferences? _prefs;

  /// Bounded LRU in-memory response cache
  static const int _maxCacheEntries = 80;
  final LinkedHashMap<String, dynamic> _memoryCache = LinkedHashMap<String, dynamic>();
  final Map<String, DateTime> _cacheTimestamps = {};

  /// Deduplicates concurrent identical GET requests
  final Map<String, Future<Response>> _inFlightGets = {};

  /// Deduplicates concurrent identical POST/PUT/DELETE mutations (prevents double-submission)
  final Map<String, Future<Response>> _inFlightMutations = {};

  /// How long a live network GET stays fresh in RAM before background re-validation
  static const Duration _freshTtl = Duration(seconds: 90);

  Function()? onUnauthorized;

  Dio get client => _dio;

  void _putInMemoryCache(String key, dynamic value, {DateTime? timestamp}) {
    if (_memoryCache.containsKey(key)) {
      _memoryCache.remove(key);
    } else if (_memoryCache.length >= _maxCacheEntries) {
      final oldestKey = _memoryCache.keys.first;
      _memoryCache.remove(oldestKey);
      _cacheTimestamps.remove(oldestKey);
    }
    _memoryCache[key] = value;
    _cacheTimestamps[key] = timestamp ?? DateTime.now();
  }

  ApiService._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: AppConfig.connectTimeout,
      receiveTimeout: AppConfig.receiveTimeout,
      headers: {'Content-Type': 'application/json'},
    ));
    _dio.transformer = _IsolateJsonTransformer();

    // Pre-warm SharedPreferences and hydrate RAM cache immediately at startup
    unawaited(SharedPreferences.getInstance().then((p) {
      _prefs = p;
      _hydrateMemoryCacheFromDisk(p);
    }, onError: (_) {}));

    // Request / Response / Error interceptor
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final path = options.path;
        final isAuthRoute = path.contains('/auth/login') ||
            path.contains('/auth/refresh') ||
            path.contains('/auth/logout');

        final token = await SecureStorageHelper.instance.read('token');
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }

        // Let Dio generate the proper multipart boundary header when sending FormData
        if (options.data is FormData) {
          options.headers.remove('Content-Type');
          options.headers.remove('content-type');
        }

        // Never block outgoing requests waiting on token refresh; trigger in background if needed
        if (!isAuthRoute && AuthService.isTokenExpiringSoon(token, bufferSeconds: 120)) {
          unawaited(AuthService.refreshSession());
        }

        return handler.next(options);
      },
      onResponse: (response, handler) {
        handler.next(response);

        if (response.requestOptions.method == 'GET' && response.statusCode == 200) {
          final cacheKey = 'cache_${response.requestOptions.uri}';
          _putInMemoryCache(cacheKey, response.data);
          _saveToDiskAsync(cacheKey, response.data);
        }
      },
      onError: (DioException e, handler) async {
        if (e.response?.statusCode == 401) {
          final path = e.requestOptions.path;
          final isAuthRoute = path.contains('/auth/login') ||
              path.contains('/auth/refresh') ||
              path.contains('/auth/logout');

          if (!isAuthRoute && e.requestOptions.extra['_retriedAfterRefresh'] != true) {
            final refreshOutcome = await AuthService.refreshSession();
            if (refreshOutcome == RefreshResult.refreshed) {
              final newToken = await SecureStorageHelper.instance.read('token');
              if (newToken != null && newToken.isNotEmpty) {
                e.requestOptions.headers['Authorization'] = 'Bearer $newToken';
                e.requestOptions.extra['_retriedAfterRefresh'] = true;
                try {
                  final retryResponse = await _dio.fetch(e.requestOptions);
                  return handler.resolve(retryResponse);
                } on DioException catch (retryErr) {
                  return handler.next(retryErr);
                }
              }
            } else if (refreshOutcome == RefreshResult.revoked) {
              // Only wipe session and force logout when the server explicitly revokes the refresh token
              await SecureStorageHelper.instance.delete('token');
              await SecureStorageHelper.instance.delete('refresh_token');
              await SecureStorageHelper.instance.delete('user');
              clearCache();
              onUnauthorized?.call();
            }
            // On RefreshResult.transientFailure (network error / timeout / unmigrated endpoint),
            // preserve the user's session so they are NEVER automatically logged out!
          }
        }

        // Offline / fallback cache for GET requests (including transient 401 when offline)
        if ((_isNetworkError(e) || e.response?.statusCode == 401) && e.requestOptions.method == 'GET') {
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
            final decoded = cachedData.length > 32768
                ? await compute(_decodeJsonInIsolate, cachedData)
                : jsonDecode(cachedData);
            _putInMemoryCache(cacheKey, decoded);
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

  void _hydrateMemoryCacheFromDisk(SharedPreferences prefs) {
    try {
      final staleTs = DateTime.now().subtract(const Duration(seconds: 75));
      for (final key in prefs.getKeys()) {
        if (!key.startsWith('cache_')) continue;
        if (_memoryCache.containsKey(key)) continue;
        final raw = prefs.getString(key);
        if (raw == null || raw.isEmpty) continue;
        try {
          final decoded = jsonDecode(raw);
          _putInMemoryCache(key, decoded, timestamp: staleTs);
        } catch (_) {}
      }
    } catch (_) {}
  }

  /// Strips oversized base64 image strings (>4 KB) only for the SharedPreferences
  /// disk snapshot so list screens cache cleanly within 256 KB without blocking UI frames.
  dynamic _stripHeavyBlobsForDisk(dynamic input, [int depth = 0]) {
    if (depth > 4 || input == null) return input;
    if (input is String) {
      if (input.length > 4096) return null;
      return input;
    }
    if (input is List) {
      final capped = input.length > 150 ? input.sublist(0, 150) : input;
      return capped.map((e) => _stripHeavyBlobsForDisk(e, depth + 1)).toList();
    }
    if (input is Map) {
      final out = <String, dynamic>{};
      input.forEach((k, v) {
        final keyStr = k.toString();
        final isReceiptKey = keyStr == 'receipt_image' || keyStr == 'receipt_path';
        final maxLen = isReceiptKey ? 204800 : 4096;
        if (v is String && v.length > maxLen) {
          out[keyStr] = null;
        } else {
          out[keyStr] = _stripHeavyBlobsForDisk(v, depth + 1);
        }
      });
      return out;
    }
    return input;
  }

  void _saveToDiskAsync(String cacheKey, dynamic data) {
    Future.delayed(const Duration(milliseconds: 50), () async {
      try {
        final prefs = _prefs ?? await SharedPreferences.getInstance();
        final diskSafe = _stripHeavyBlobsForDisk(data);
        final encoded = jsonEncode(diskSafe);
        if (encoded.length <= 524288) {
          await prefs.setString(cacheKey, encoded);
        }
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

  Future<Response> _fetchNetworkGet(
    String path,
    Map<String, dynamic>? queryParameters,
    String cacheKey,
  ) async {
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

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    bool forceRefresh = false,
  }) async {
    final cacheKey = _buildCacheKey(path, queryParameters);

    // 1. Return RAM cache immediately in 0ms (Stale-While-Revalidate if older than _freshTtl)
    if (!forceRefresh && _memoryCache.containsKey(cacheKey)) {
      final ts = _cacheTimestamps[cacheKey];
      final isFresh = ts != null && DateTime.now().difference(ts) < _freshTtl;
      if (!isFresh) {
        unawaited(_fetchNetworkGet(path, queryParameters, cacheKey).then((_) {}, onError: (_) {}));
      }
      return Response(
        requestOptions: RequestOptions(path: path, queryParameters: queryParameters),
        data: _memoryCache[cacheKey],
        statusCode: 200,
      );
    }

    // 2. Check synchronous disk cache if RAM wasn't hydrated yet -> return in <5ms + revalidate
    if (!forceRefresh && _prefs != null) {
      final diskRaw = _prefs!.getString(cacheKey);
      if (diskRaw != null && diskRaw.isNotEmpty) {
        try {
          final decoded = jsonDecode(diskRaw);
          _putInMemoryCache(cacheKey, decoded);
          unawaited(_fetchNetworkGet(path, queryParameters, cacheKey).then((_) {}, onError: (_) {}));
          return Response(
            requestOptions: RequestOptions(path: path, queryParameters: queryParameters),
            data: decoded,
            statusCode: 200,
          );
        } catch (_) {}
      }
    }

    // 3. Deduplicated live network GET
    return await _fetchNetworkGet(path, queryParameters, cacheKey);
  }

  String _buildMutationKey(String method, String path, dynamic data) {
    String payloadSig = '';
    try {
      payloadSig = data == null ? '' : jsonEncode(data);
      if (payloadSig.length > 512) {
        payloadSig = '${payloadSig.length}:${payloadSig.substring(0, 256)}:${payloadSig.substring(payloadSig.length - 256)}';
      }
    } catch (_) {
      payloadSig = data.hashCode.toString();
    }
    return '$method:$path:${payloadSig.hashCode}';
  }

  Future<Response> _executeMutation(
    String method,
    String path, {
    dynamic data,
  }) async {
    final mutKey = _buildMutationKey(method, path, data);

    // Client-side duplicate submission guard: if the exact same mutation is already in-flight, return it
    if (_inFlightMutations.containsKey(mutKey)) {
      return await _inFlightMutations[mutKey]!;
    }

    // Deterministic 10-second bucket idempotency key for server-side IdempotencyGuard
    final timeBucket = DateTime.now().millisecondsSinceEpoch ~/ 10000;
    final idempotencyKey = '${mutKey.hashCode.toRadixString(16)}_$timeBucket';
    final options = Options(
      method: method,
      headers: {'X-Idempotency-Key': idempotencyKey},
    );

    final future = _dio.request(path, data: data, options: options);
    _inFlightMutations[mutKey] = future;
    try {
      final res = await future;
      clearCache();
      return res;
    } finally {
      _inFlightMutations.remove(mutKey);
    }
  }

  Future<Response> post(String path, {dynamic data}) =>
      _executeMutation('POST', path, data: data);

  Future<Response> put(String path, {dynamic data}) =>
      _executeMutation('PUT', path, data: data);

  Future<Response> delete(String path, {dynamic data}) =>
      _executeMutation('DELETE', path, data: data);

  /// Pre-warms all primary navigation tabs for the user's role in parallel batches
  /// so switching tabs renders in <50ms without loading spinners.
  void prefetchForRole(String? role) {
    Future.microtask(() async {
      final cleanRole = (role ?? 'admin').toLowerCase().trim();
      final batch1 = <String>[];
      final batch2 = <String>[];

      switch (cleanRole) {
        case 'agent':
          batch1.addAll([
            '/energy/agent/dashboard-stats',
            '/agent/smart-tasks',
            '/agent/subscriptions',
            '/agent/generators/assigned',
          ]);
          batch2.addAll([
            '/agent/rent/tasks',
            '/buildings',
          ]);
          break;
        case 'maintenance':
          batch1.addAll([
            '/maintenance/tasks',
            '/maintenance/worker-history',
          ]);
          break;
        case 'tenant':
          batch1.addAll([
            '/tenant-portal/dashboard',
            '/tenant-portal/maintenance-tickets',
            '/tenant-portal/apartments',
          ]);
          break;
        case 'manager':
          batch1.addAll([
            '/dashboard/manager',
            '/buildings',
            '/contracts',
            '/maintenance-tickets/all',
          ]);
          break;
        default:
          // Admin primary tabs: Dashboard, AC Maint., Verification, Review
          batch1.addAll([
            '/dashboard/financial-summary',
            '/dashboard/alerts',
            '/dashboard/collections',
            '/maintenance-tickets/all',
            '/maintenance/admin/tasks',
            '/maintenance/admin/history',
            '/maintenance/admin/worker-reports',
          ]);
          batch2.addAll([
            '/users',
            '/approval/admin-kpi',
            '/approval/queue/electricity?status=pending',
            '/agent-purchases?all=1',
            '/energy/agent/apartment-purchases/pending',
            '/energy/agent/apartment-purchases',
          ]);
          break;
      }

      await Future.wait(
        batch1.map((r) => get(r).then<void>((_) {}, onError: (_) {})),
      );
      if (batch2.isNotEmpty) {
        await Future.wait(
          batch2.map((r) => get(r).then<void>((_) {}, onError: (_) {})),
        );
      }
    });
  }

  Future<void> syncOfflineQueue() async {
    // Sync offline queue if needed
  }
}
