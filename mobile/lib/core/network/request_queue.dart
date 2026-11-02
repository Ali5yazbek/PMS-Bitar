import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../storage/local_database.dart';
import '../../services/api_service.dart';

enum SyncStatusState { synchronized, uploading, offline }

class SyncStatusInfo {
  final SyncStatusState state;
  final int pendingCount;
  final String label;

  SyncStatusInfo({
    required this.state,
    required this.pendingCount,
    required this.label,
  });
}

class RequestQueue {
  static final RequestQueue instance = RequestQueue._init();
  final LocalDatabase _db = LocalDatabase.instance;
  final Set<String> _inFlightLocks = {};

  final StreamController<SyncStatusInfo> _statusController =
      StreamController<SyncStatusInfo>.broadcast();

  Stream<SyncStatusInfo> get statusStream => _statusController.stream;

  RequestQueue._init();

  String generateRequestId(String endpoint, String method, Map<String, dynamic> payload) {
    final raw = '$endpoint:$method:${jsonEncode(payload)}';
    return md5.convert(utf8.encode(raw)).toString();
  }

  bool isLocked(String id) => _inFlightLocks.contains(id);

  Future<bool> addRequest({
    required String endpoint,
    required String method,
    required Map<String, dynamic> payload,
  }) async {
    final id = generateRequestId(endpoint, method, payload);

    if (_inFlightLocks.contains(id)) {
      if (kDebugMode) print('Duplicate submission locked: $id');
      return false;
    }

    _inFlightLocks.add(id);

    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      final isOffline = connectivityResult.contains(ConnectivityResult.none);

      if (!isOffline) {
        // Try online immediately
        try {
          if (method.toUpperCase() == 'POST') {
            if (_isMultipartEndpoint(endpoint)) {
               final formData = await _buildFormData(payload);
               await ApiService().post(endpoint, data: formData);
            } else {
               await ApiService().post(endpoint, data: payload);
            }
          } else if (method.toUpperCase() == 'PUT') {
            await ApiService().put(endpoint, data: payload);
          } else if (method.toUpperCase() == 'DELETE') {
            await ApiService().delete(endpoint);
          }
          await notifyStatus(SyncStatusState.synchronized, isOnline: true);
          return true;
        } catch (e) {
          if (e is DioException && (
              e.type == DioExceptionType.connectionTimeout ||
              e.type == DioExceptionType.sendTimeout ||
              e.type == DioExceptionType.receiveTimeout ||
              e.type == DioExceptionType.connectionError ||
              e.error == 'OFFLINE_QUEUED')) {
            // Network failed during attempt, fallback to queue
            return await _saveOffline(id, endpoint, method, payload);
          }
          rethrow; // Re-throw other API errors (400, 500, etc.)
        }
      } else {
        // Definitely offline
        return await _saveOffline(id, endpoint, method, payload);
      }
    } finally {
      Timer(const Duration(seconds: 3), () {
        _inFlightLocks.remove(id);
      });
    }
  }

  Future<bool> _saveOffline(String id, String endpoint, String method, Map<String, dynamic> payload) async {
    final item = QueueItem(
      id: id,
      endpoint: endpoint,
      method: method,
      payload: payload,
      status: 'queued',
      createdAt: DateTime.now(),
    );
    await _db.insertRequest(item);
    await notifyStatus(SyncStatusState.offline, isOnline: false);
    throw Exception('OFFLINE_QUEUED');
  }

  Future<void> triggerSync() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) return;

    final queue = await _db.getQueuedRequests();
    final pending = queue.where((q) => q.status != 'synced').toList();

    if (pending.isEmpty) {
      await notifyStatus(SyncStatusState.synchronized, isOnline: true);
      return;
    }

    await notifyStatus(SyncStatusState.uploading, isOnline: true);

    for (var req in pending) {
      try {
        if (req.method.toUpperCase() == 'POST') {
          if (_isMultipartEndpoint(req.endpoint)) {
             final formData = await _buildFormData(req.payload);
             await ApiService().post(req.endpoint, data: formData);
          } else {
             await ApiService().post(req.endpoint, data: req.payload);
          }
        } else if (req.method.toUpperCase() == 'PUT') {
          await ApiService().put(req.endpoint, data: req.payload);
        } else if (req.method.toUpperCase() == 'DELETE') {
          await ApiService().delete(req.endpoint);
        }
        await _db.removeRequest(req.id);
      } catch (e) {
        if (e is DioException) {
          if (e.type == DioExceptionType.connectionTimeout ||
              e.type == DioExceptionType.connectionError ||
              e.error == 'OFFLINE_QUEUED') {
            // Still offline, stop syncing
            await notifyStatus(SyncStatusState.offline, isOnline: false);
            return;
          }
          if (e.response?.statusCode == 400 || e.response?.statusCode == 403) {
            // Permanent failure (validation/auth), delete it so it doesn't loop forever
            await _db.removeRequest(req.id);
            continue;
          }
        }
        // If it failed due to a 500, we probably shouldn't block the queue.
        // For now, mark failed and continue.
        await _db.updateRequestStatus(req.id, 'failed');
      }
    }
    
    // Sync other ApiService queues if any
    await ApiService().syncOfflineQueue();
    await notifyStatus(SyncStatusState.synchronized, isOnline: true);
  }

  Future<void> notifyStatus(SyncStatusState state, {bool isOnline = true}) async {
    final queue = await _db.getQueuedRequests();
    final pending = queue.where((q) => q.status != 'synced').length;

    String label;
    if (!isOnline) {
      label = pending > 0 ? 'Offline ($pending waiting)' : 'Offline';
    } else if (pending > 0) {
      label = 'Uploading... ($pending pending)';
    } else {
      label = '✓ All data synchronized';
    }

    _statusController.add(SyncStatusInfo(
      state: !isOnline
          ? SyncStatusState.offline
          : (pending > 0 ? SyncStatusState.uploading : SyncStatusState.synchronized),
      pendingCount: pending,
      label: label,
    ));
  }

  bool _isMultipartEndpoint(String endpoint) {
    return endpoint.contains('/generators/submit') || 
           endpoint.contains('/generator-reading') ||
           endpoint.contains('/subscription-reading');
  }

  Future<FormData> _buildFormData(Map<String, dynamic> payload) async {
    final formData = FormData();
    for (var entry in payload.entries) {
      if (entry.value is List) {
        // e.g. photos: ['/path/to/img1.jpg', 'base64:....']
        for (var i = 0; i < entry.value.length; i++) {
          final val = entry.value[i].toString();
          if (val.startsWith('/') || val.contains(':/')) {
            try {
              formData.files.add(MapEntry(
                '${entry.key}[$i]',
                await MultipartFile.fromFile(val, filename: val.split('/').last),
              ));
            } catch (_) {}
          } else if (val.startsWith('base64:')) {
            try {
              final bytes = base64Decode(val.substring(7));
              formData.files.add(MapEntry(
                '${entry.key}[$i]',
                MultipartFile.fromBytes(bytes, filename: 'photo_$i.jpg'),
              ));
            } catch (_) {}
          } else {
            formData.fields.add(MapEntry('${entry.key}[$i]', val));
          }
        }
      } else {
        final val = entry.value.toString();
        if ((entry.key.contains('photo') || entry.key.contains('file'))) {
          if (val.startsWith('/') || val.contains(':/')) {
            try {
               formData.files.add(MapEntry(
                 entry.key,
                 await MultipartFile.fromFile(val, filename: val.split('/').last),
               ));
            } catch (_) {}
          } else if (val.startsWith('base64:')) {
            formData.fields.add(MapEntry('${entry.key}_base64', val));
          } else {
            formData.fields.add(MapEntry(entry.key, val));
          }
        } else {
          formData.fields.add(MapEntry(entry.key, val));
        }
      }
    }
    return formData;
  }
}
