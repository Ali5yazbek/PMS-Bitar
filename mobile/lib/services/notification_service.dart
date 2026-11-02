// ─── Notification Service ─────────────────────────────────────────────────────
// Handles:
//   1. Flutter Local Notifications (local display)
//   2. Firebase Cloud Messaging (FCM) for real push delivery
//   3. Polling fallback for backends without FCM server-side setup
//   4. Single-delivery deduplication & startup baseline across Android and iOS

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import '../router/app_router.dart';

/// Top-level background message handler — must be a top-level function, not a class method.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase is already initialized by main.dart before this fires.
  // We can show a local notification here if needed, but FCM shows one automatically
  // when the app is in background/killed if the payload has a 'notification' field.
  if (kDebugMode) {
    print('[FCM Background] ${message.messageId}: ${message.notification?.title}');
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  final FlutterLocalNotificationsPlugin _localPlugin =
      FlutterLocalNotificationsPlugin();
  Timer? _pollingTimer;
  final Set<String> _notifiedIds = {};
  bool _isInitialFetchDone = false;
  static const String _notifiedIdsKey = 'pushed_notification_ids_v1';

  NotificationService._internal();

  // ── Android notification channel ────────────────────────────────────────────
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'enterprise_push_channel_v2',
    'Enterprise Push Alerts',
    description:
        'Realtime task assignments, approvals, rejections, and overdue alerts.',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  Future<void> initialize() async {
    try {
      // ── 0. Load previously notified IDs from storage ──────────────────
      await _loadNotifiedIds();

      // ── 1. Local Notifications init ─────────────────────────────────────
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/launcher_icon');
      const DarwinInitializationSettings darwinSettings =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
        macOS: darwinSettings,
      );

      await _localPlugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          if (kDebugMode) print('[LocalNotif] Tapped: ${response.payload}');
        },
      );

      // Create Android notification channel
      await _localPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);

      // Request Android 13+ permission
      try {
        await _localPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.requestNotificationsPermission();
      } catch (_) {}

      // ── 2. FCM initialization ───────────────────────────────────────────
      await _initFCM();

      // ── 3. Polling fallback for backends without FCM server integration ─
      _startPolling();
    } catch (e) {
      if (kDebugMode) print('[NotificationService] Init failed: $e');
    }
  }

  Future<void> _loadNotifiedIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedList = prefs.getStringList(_notifiedIdsKey);
      if (savedList != null) {
        _notifiedIds.addAll(savedList);
      }
    } catch (e) {
      if (kDebugMode) print('[NotificationService] Failed to load notified IDs: $e');
    }
  }

  Future<void> _saveNotifiedIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Cap size at 500 to prevent unbounded disk growth
      final listToSave = _notifiedIds.length > 500
          ? _notifiedIds.toList().sublist(_notifiedIds.length - 500)
          : _notifiedIds.toList();
      await prefs.setStringList(_notifiedIdsKey, listToSave);
    } catch (e) {
      if (kDebugMode) print('[NotificationService] Failed to save notified IDs: $e');
    }
  }

  Future<void> _initFCM() async {
    try {
      final messaging = FirebaseMessaging.instance;

      // Request permission (iOS / macOS require explicit permission)
      final settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (kDebugMode) {
        print('[FCM] Permission status: ${settings.authorizationStatus}');
      }

      // Get the FCM token and register with our backend
      final token = await messaging.getToken();
      if (token != null) {
        if (kDebugMode) print('[FCM] Token: $token');
        _registerFCMToken(token);
      }

      // Listen for token refresh
      messaging.onTokenRefresh.listen(_registerFCMToken);

      // ── Foreground FCM messages → show as local notification (deduplicated) ──
      FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
        final notification = message.notification;
        if (notification != null) {
          final notifId = message.messageId ??
              'fcm_${message.sentTime?.millisecondsSinceEpoch}_${notification.title}';
          if (!_notifiedIds.contains(notifId)) {
            _notifiedIds.add(notifId);
            await _saveNotifiedIds();
            await showNotification(
              id: notifId.hashCode,
              title: notification.title ?? 'New Alert',
              body: notification.body ?? 'You have a new update.',
            );
          }
        }
      });

      // ── Background message handler (registered in main.dart) ───────────
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // ── App opened via notification tap ────────────────────────────────
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        if (kDebugMode) print('[FCM] App opened via notification: ${message.data}');
        final route = message.data['route'];
        if (route != null && rootNavigatorKey.currentContext != null) {
          GoRouter.of(rootNavigatorKey.currentContext!).push(route);
        }
      });
    } catch (e) {
      if (kDebugMode) print('[FCM] Init error (non-fatal): $e');
      // FCM failures are non-fatal — polling fallback covers notification delivery.
    }
  }

  Future<void> _registerFCMToken(String token) async {
    try {
      await ApiService().post('/auth/fcm-token', data: {'token': token});
      if (kDebugMode) print('[FCM] Token registered with backend.');
    } catch (_) {
      // Non-fatal: token registration will retry on next app launch
    }
  }

  // ── Polling fallback (30-second interval) ───────────────────────────────────
  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _checkUnreadNotifications();
    });
    _checkUnreadNotifications();
  }

  Future<void> _checkUnreadNotifications() async {
    try {
      final res = await ApiService().get('/notifications/unread');
      final notifications = (res.data as List<dynamic>?) ?? [];
      await processUnreadNotifications(notifications);
    } catch (_) {
      // Ignore transient network errors during polling
    }
  }

  /// Public entry point for processing unread notifications.
  /// Enforces single push notification delivery per notification ID and baseline filtering on app open.
  Future<void> processUnreadNotifications(List<dynamic> notifications) async {
    if (notifications.isEmpty) return;

    bool hasChanges = false;

    // Baseline check: on initial fetch after app start/open, seed existing unread notifications
    // as seen in _notifiedIds so old messages don't pop up as fresh alerts.
    if (!_isInitialFetchDone) {
      _isInitialFetchDone = true;
      for (var n in notifications) {
        final id = n['id']?.toString();
        if (id != null && !_notifiedIds.contains(id)) {
          _notifiedIds.add(id);
          hasChanges = true;
        }
      }
      if (hasChanges) {
        await _saveNotifiedIds();
      }
      return;
    }

    // For subsequent polls, trigger notification push ONLY for newly arrived IDs
    for (var n in notifications) {
      final id = n['id']?.toString();
      if (id == null) continue;

      if (!_notifiedIds.contains(id)) {
        _notifiedIds.add(id);
        hasChanges = true;

        await showNotification(
          id: n['id'].hashCode,
          title: n['title'] ?? '🚨 New Operational Alert',
          body: n['message'] ?? 'Action required on assigned task or reading.',
        );
      }
    }

    if (hasChanges) {
      await _saveNotifiedIds();
    }
  }

  // ── Public: display a local notification ───────────────────────────────────
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      _channel.id,
      _channel.name,
      channelDescription: _channel.description,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      styleInformation: BigTextStyleInformation(body),
    );
    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    final details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );

    await _localPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: details,
      payload: payload,
    );
  }

  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _isInitialFetchDone = false; // Reset session baseline flag
  }
}

