import 'dart:async';
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
    _startPollingFallback();
  }

  void _startPollingFallback() {
    _mode = ConnectionMode.polling;
    _pollingTimer?.cancel();

    // Since FCM delivers push notifications in real time across all states,
    // use a lightweight 45-second foreground sync interval to conserve RAM & battery.
    _pollingTimer = Timer.periodic(const Duration(seconds: 45), (_) async {
      await pollLatestEvents();
    });
  }

  Future<void> pollLatestEvents() async {
    try {
      final res = await ApiService().get('/notifications/unread');
      if (res.statusCode == 200 && res.data != null) {
        final List list = res.data is List ? res.data : (res.data['notifications'] ?? []);

        for (var item in list) {
          if (item is Map) {
            final event = RealtimeEvent(
              type: item['type']?.toString() ?? 'general',
              data: Map<String, dynamic>.from(item),
            );
            _eventController.add(event);
          }
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
    _pollingTimer = null;
    _mode = ConnectionMode.disconnected;
  }
}
