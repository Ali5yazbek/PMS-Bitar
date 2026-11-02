import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../storage/local_database.dart';
import 'request_queue.dart';

class SyncEngine {
  static final SyncEngine instance = SyncEngine._init();
  final LocalDatabase _db = LocalDatabase.instance;
  final RequestQueue _queue = RequestQueue.instance;
  
  late Dio _dio;
  bool _isSyncing = false;
  Timer? _periodicTimer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  SyncEngine._init() {
    _dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ));
  }

  void initialize({required String baseUrl, String? authToken}) {
    _dio.options.baseUrl = baseUrl;
    if (authToken != null) {
      _dio.options.headers['Authorization'] = 'Bearer $authToken';
    }

    // Monitor connectivity changes
    _connectivitySub?.cancel();
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      final isOnline = results.any((r) => r != ConnectivityResult.none);
      if (isOnline) {
        triggerSync();
      } else {
        _queue.notifyStatus(SyncStatusState.offline, isOnline: false);
      }
    });

    // Start periodic background timer (every 30 seconds)
    _periodicTimer?.cancel();
    _periodicTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      triggerSync();
    });
  }

  void updateToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  Future<void> triggerSync() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      final queue = await _db.getQueuedRequests();
      final pending = queue.where((q) => q.status != 'synced').toList();

      if (pending.isEmpty) {
        await _queue.notifyStatus(SyncStatusState.synchronized, isOnline: true);
        _isSyncing = false;
        return;
      }

      await _queue.notifyStatus(SyncStatusState.uploading, isOnline: true);

      for (final item in pending) {
        try {
          await _db.updateRequestStatus(item.id, 'sending');

          late Response res;
          if (item.method.toUpperCase() == 'POST') {
            res = await _dio.post(item.endpoint, data: item.payload);
          } else if (item.method.toUpperCase() == 'PUT') {
            res = await _dio.put(item.endpoint, data: item.payload);
          }

          if (res.statusCode != null && res.statusCode! >= 200 && res.statusCode! < 300) {
            await _db.removeRequest(item.id);
          } else {
            await _db.updateRequestStatus(item.id, 'failed');
          }
        } catch (e) {
          if (kDebugMode) print('Sync request failed for ${item.endpoint}: $e');
          await _db.updateRequestStatus(item.id, 'failed');
        }
      }

      await _queue.notifyStatus(SyncStatusState.synchronized, isOnline: true);
    } catch (e) {
      if (kDebugMode) print('Sync engine error: $e');
    } finally {
      _isSyncing = false;
    }
  }

  void dispose() {
    _periodicTimer?.cancel();
    _connectivitySub?.cancel();
  }
}
