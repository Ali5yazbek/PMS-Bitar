import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../services/notification_service.dart';
import '../../services/api_service.dart';

enum ConnectionMode { sse, polling, disconnected }

class RealtimeEvent {
  final String type; // 'task_assigned', 'work_approved', 'work_rejected', 'tenant_request', 'reading_submitted'
  final Map<String, dynamic> data;
  final DateTime timestamp;

  RealtimeEvent({
    required this.type,
    required this.data,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class RealtimeService {
  static final RealtimeService instance = RealtimeService._init();

  ConnectionMode _mode = ConnectionMode.disconnected;
  Timer? _pollingTimer;
  final StreamController<RealtimeEvent> _eventController =
      StreamController<RealtimeEvent>.broadcast();

  Stream<RealtimeEvent> get eventStream => _eventController.stream;
  ConnectionMode get currentMode => _mode;

  RealtimeService._init();

  void initialize({required String baseUrl, required String token}) {
    startConnection();
  }

  void startConnection() {
    _trySseConnection().then((success) {
      if (!success) {
        _startPollingFallback();
      }
    });
  }

  Future<bool> _trySseConnection() async {
    try {
      _mode = ConnectionMode.sse;
      return false; // Fallback to 5s ApiService polling for high-reliability PHP compatibility
    } catch (e) {
      return false;
    }
  }

  void _startPollingFallback() {
    _mode = ConnectionMode.polling;
    _pollingTimer?.cancel();
    if (kDebugMode) print('RealtimeService: Started 5-second polling fallback via ApiService.');

    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      await pollLatestEvents();
    });
  }

  Future<void> pollLatestEvents() async {
    try {
      final res = await ApiService().get('/notifications/unread');
      if (res.statusCode == 200 && res.data != null) {
        final List list = res.data is List ? res.data : (res.data['notifications'] ?? []);

        for (var item in list) {
          final event = RealtimeEvent(
            type: item['type'] ?? 'general',
            data: Map<String, dynamic>.from(item),
          );
          _eventController.add(event);
        }

        // Delegate notification deduplication & pushing to NotificationService
        await NotificationService().processUnreadNotifications(list);
      }
    } catch (e) {
      // Ignore transient network poll errors
    }
  }

  void dispose() {
    _pollingTimer?.cancel();
    _mode = ConnectionMode.disconnected;
  }
}
