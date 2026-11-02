import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QueueItem {
  final String id;
  final String endpoint;
  final String method;
  final Map<String, dynamic> payload;
  final String status; // 'queued', 'sending', 'failed', 'synced'
  final int retryCount;
  final DateTime createdAt;
  final DateTime? lastRetryAt;

  QueueItem({
    required this.id,
    required this.endpoint,
    required this.method,
    required this.payload,
    this.status = 'queued',
    this.retryCount = 0,
    required this.createdAt,
    this.lastRetryAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'endpoint': endpoint,
        'method': method,
        'payload': payload,
        'status': status,
        'retryCount': retryCount,
        'createdAt': createdAt.toIso8601String(),
        'lastRetryAt': lastRetryAt?.toIso8601String(),
      };

  factory QueueItem.fromJson(Map<String, dynamic> json) => QueueItem(
        id: json['id'],
        endpoint: json['endpoint'],
        method: json['method'],
        payload: json['payload'] is String
            ? jsonDecode(json['payload'])
            : Map<String, dynamic>.from(json['payload'] ?? {}),
        status: json['status'] ?? 'queued',
        retryCount: json['retryCount'] ?? 0,
        createdAt: DateTime.parse(json['createdAt']),
        lastRetryAt: json['lastRetryAt'] != null
            ? DateTime.parse(json['lastRetryAt'])
            : null,
      );

  QueueItem copyWith({
    String? status,
    int? retryCount,
    DateTime? lastRetryAt,
  }) {
    return QueueItem(
      id: id,
      endpoint: endpoint,
      method: method,
      payload: payload,
      status: status ?? this.status,
      retryCount: retryCount ?? this.retryCount,
      createdAt: createdAt,
      lastRetryAt: lastRetryAt ?? this.lastRetryAt,
    );
  }
}

class LocalDatabase {
  static final LocalDatabase instance = LocalDatabase._init();
  static const String _queueKey = 'enterprise_offline_queue_db_v2';
  static const String _cacheKeyPrefix = 'enterprise_cache_';

  LocalDatabase._init();

  Future<List<QueueItem>> getQueuedRequests() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? rawJson = prefs.getString(_queueKey);
      if (rawJson == null || rawJson.isEmpty) return [];

      final List<dynamic> list = jsonDecode(rawJson);
      return list.map((item) => QueueItem.fromJson(item)).toList();
    } catch (e) {
      if (kDebugMode) print('LocalDatabase get error: $e');
      return [];
    }
  }

  Future<void> saveQueue(List<QueueItem> queue) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String rawJson = jsonEncode(queue.map((q) => q.toJson()).toList());
      await prefs.setString(_queueKey, rawJson);
    } catch (e) {
      if (kDebugMode) print('LocalDatabase save error: $e');
    }
  }

  Future<void> insertRequest(QueueItem item) async {
    final queue = await getQueuedRequests();
    // Deduplicate
    queue.removeWhere((q) => q.id == item.id);
    queue.add(item);
    await saveQueue(queue);
  }

  Future<void> updateRequestStatus(String id, String status, {int? retryCount}) async {
    final queue = await getQueuedRequests();
    final index = queue.indexWhere((q) => q.id == id);
    if (index != -1) {
      queue[index] = queue[index].copyWith(
        status: status,
        retryCount: retryCount ?? (queue[index].retryCount + 1),
        lastRetryAt: DateTime.now(),
      );
      await saveQueue(queue);
    }
  }

  Future<void> removeRequest(String id) async {
    final queue = await getQueuedRequests();
    queue.removeWhere((q) => q.id == id);
    await saveQueue(queue);
  }

  Future<void> cacheData(String key, Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_cacheKeyPrefix$key', jsonEncode({
        'timestamp': DateTime.now().toIso8601String(),
        'data': data,
      }));
    } catch (e) {
      if (kDebugMode) print('LocalDatabase cacheData error: $e');
    }
  }

  Future<Map<String, dynamic>?> getCachedData(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? raw = prefs.getString('$_cacheKeyPrefix$key');
      if (raw == null) return null;

      final Map<String, dynamic> parsed = jsonDecode(raw);
      return parsed['data'] as Map<String, dynamic>?;
    } catch (e) {
      return null;
    }
  }

  // Table-based List Caching (Generator, Subscription, History, Apartment, Building, Purchase, Daily Report)
  Future<void> setCacheList(String tableKey, List<dynamic> list) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_cacheKeyPrefix$tableKey', jsonEncode({
        'timestamp': DateTime.now().toIso8601String(),
        'list': list,
      }));
    } catch (e) {
      if (kDebugMode) print('LocalDatabase setCacheList error: $e');
    }
  }

  Future<List<dynamic>> getCacheList(String tableKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? raw = prefs.getString('$_cacheKeyPrefix$tableKey');
      if (raw == null) return [];

      final Map<String, dynamic> parsed = jsonDecode(raw);
      return (parsed['list'] as List<dynamic>?) ?? [];
    } catch (e) {
      return [];
    }
  }
}
