// ─── Notification Service ─────────────────────────────────────────────────────
// Handles:
//   1. Firebase Cloud Messaging (FCM) across all 4 states:
//      Foreground, Background, Minimized, and Normally Terminated
//   2. Multi-device token registration & lifecycle (/api/devices/register & /unregister)
//   3. Direct deep-link routing on notification tap (getInitialMessage, onMessageOpenedApp, local tap)
//   4. Role-aware live aggregation (Admin, Manager, Agent, Maintenance, Tenant)

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import '../core/storage/secure_storage_helper.dart';
import '../router/app_router.dart';

/// Top-level background message handler — runs in a separate isolate when app is backgrounded/terminated.
/// Note: Standard FCM messages include both `notification` and `data` blocks so Android/iOS OS displays
/// them natively with zero Dart RAM overhead when terminated. Data-only messages fallback to local display here.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    if (Firebase.apps.isEmpty) {
      try {
        await Firebase.initializeApp();
      } catch (_) {
        await Firebase.initializeApp(
          options: const FirebaseOptions(
            apiKey: 'AIzaSyDHfdeXmqXf3rEDvE2gL5EvvPpk9UWWwRs',
            appId: '1:192387594223:android:49fdaaaa22c899d9c2a81a',
            messagingSenderId: '192387594223',
            projectId: 'bitar-pms',
            storageBucket: 'bitar-pms.firebasestorage.app',
          ),
        );
      }
    }

    // Record notification_id in SharedPreferences so foreground polling never duplicates
    // a push notification that was already delivered while the app was closed/backgrounded/locked.
    final notifId = message.data['notification_id']?.toString() ?? message.messageId;
    if (notifId != null && notifId.isNotEmpty) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final list = prefs.getStringList('pushed_notification_ids_v2') ?? <String>[];
        if (!list.contains(notifId)) {
          list.add(notifId);
          final trimmed = list.length > 500 ? list.sublist(list.length - 500) : list;
          await prefs.setStringList('pushed_notification_ids_v2', trimmed);
        }
      } catch (_) {}
    }

    // Standard FCM payloads include a `notification` block so the native Android/iOS OS
    // displays them automatically when the app is backgrounded, terminated, or locked.
    // For data-only pushes (where `message.notification == null`), display a local notification:
    if (message.notification == null) {
      final title = message.data['title']?.toString();
      final body = message.data['body']?.toString() ?? message.data['message']?.toString();
      final route = message.data['route']?.toString() ?? '/notifications';
      if (title != null && body != null) {
        final plugin = FlutterLocalNotificationsPlugin();
        const androidSettings = AndroidInitializationSettings('@mipmap/launcher_icon');
        const darwinSettings = DarwinInitializationSettings();
        await plugin.initialize(
          settings: const InitializationSettings(
            android: androidSettings,
            iOS: darwinSettings,
            macOS: darwinSettings,
          ),
        );
        await plugin.show(
          id: (notifId ?? title).hashCode & 0x7FFFFFFF,
          title: title,
          body: body,
          payload: route,
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              'enterprise_push_channel_v2',
              'Enterprise Push Alerts',
              importance: Importance.max,
              priority: Priority.high,
              visibility: NotificationVisibility.public,
              playSound: true,
              enableVibration: true,
              styleInformation: BigTextStyleInformation(body),
            ),
            iOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
        );
      }
    }
  } catch (_) {}
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  final FlutterLocalNotificationsPlugin _localPlugin =
      FlutterLocalNotificationsPlugin();
  Timer? _pollingTimer;
  final Set<String> _notifiedIds = {};
  final Set<String> _dismissedIds = {};
  String? _fcmToken;
  String? _deviceId;
  String? _pendingInitialRoute;

  static const String _notifiedIdsKey = 'pushed_notification_ids_v2';
  static const String _dismissedIdsKey = 'dismissed_notification_ids_v2';
  static const String _deviceIdKey = 'device_unique_id_v1';

  NotificationService._internal();

  // ── Android notification channel ────────────────────────────────────────────
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'enterprise_push_channel_v2',
    'Enterprise Push Alerts',
    description:
        'Realtime task assignments, rent collections, maintenance requests, approvals, and rejections.',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  Future<void> initialize() async {
    try {
      await _loadNotifiedIds();
      await _ensureDeviceId();

      if (!kIsWeb) {
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
            final targetRoute = (response.payload != null && response.payload!.trim().isNotEmpty)
                ? response.payload!.trim()
                : '/notifications';
            _navigateToRoute(targetRoute);
          },
        );

        await _localPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(_channel);

        try {
          await _localPlugin
              .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin>()
              ?.requestNotificationsPermission();
        } catch (_) {}
      }

      await _initFCM();
      _startPolling();
    } catch (e) {
      if (kDebugMode) print('[NotificationService] Init failed: $e');
    }
  }

  Future<String> _ensureDeviceId() async {
    if (_deviceId != null && _deviceId!.isNotEmpty) return _deviceId!;
    try {
      final prefs = await SharedPreferences.getInstance();
      var saved = prefs.getString(_deviceIdKey);
      if (saved == null || saved.isEmpty) {
        final rnd = Random.secure();
        final bytes = List<int>.generate(16, (_) => rnd.nextInt(256));
        saved = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
        await prefs.setString(_deviceIdKey, saved);
      }
      _deviceId = saved;
      return saved;
    } catch (_) {
      _deviceId = 'dev_${DateTime.now().millisecondsSinceEpoch}';
      return _deviceId!;
    }
  }

  String _detectPlatform() {
    if (kIsWeb) return 'web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      default:
        return 'android';
    }
  }

  void _navigateToRoute(String route) {
    final cleanRoute = route.startsWith('/') ? route : '/notifications';
    final ctx = rootNavigatorKey.currentContext;
    if (ctx != null) {
      try {
        GoRouter.of(ctx).push(cleanRoute);
        _pendingInitialRoute = null;
        return;
      } catch (_) {}
    }
    _pendingInitialRoute = cleanRoute;
  }

  /// Called immediately after user logs in or session is restored
  Future<void> syncAfterLogin() async {
    if (_fcmToken != null && _fcmToken!.isNotEmpty) {
      unawaited(_registerFCMToken(_fcmToken!));
    } else {
      try {
        final token = await FirebaseMessaging.instance.getToken();
        if (token != null && token.isNotEmpty) {
          _fcmToken = token;
          unawaited(_registerFCMToken(token));
        }
      } catch (_) {}
    }
    _startPolling();

    // If app was launched from terminated state by tapping a notification, navigate now
    if (_pendingInitialRoute != null) {
      final target = _pendingInitialRoute!;
      _pendingInitialRoute = null;
      Future.delayed(const Duration(milliseconds: 350), () {
        _navigateToRoute(target);
      });
    }
  }

  /// Called when the app returns to the foreground from background or lock screen
  Future<void> onAppResumed() async {
    await _loadNotifiedIds();
    if (_fcmToken != null && _fcmToken!.isNotEmpty) {
      unawaited(_registerFCMToken(_fcmToken!));
    } else if (!kIsWeb) {
      try {
        final token = await FirebaseMessaging.instance.getToken();
        if (token != null && token.isNotEmpty) {
          _fcmToken = token;
          unawaited(_registerFCMToken(token));
        }
      } catch (_) {}
    }
    await _checkUnreadNotificationsLightweight();
  }

  /// Unregisters the current device's FCM token from the server on logout
  /// so logged-out users no longer receive push alerts on this device.
  Future<void> unregisterCurrentDevice() async {
    try {
      final devId = await _ensureDeviceId();
      await ApiService().post('/devices/unregister', data: {
        'device_id': devId,
        if (_fcmToken != null) 'fcm_token': _fcmToken,
      });
    } catch (_) {}
  }

  Future<void> _loadNotifiedIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedList = prefs.getStringList(_notifiedIdsKey);
      if (savedList != null) _notifiedIds.addAll(savedList);
      final dismissedList = prefs.getStringList(_dismissedIdsKey);
      if (dismissedList != null) _dismissedIds.addAll(dismissedList);
    } catch (_) {}
  }

  Future<void> _saveNotifiedIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final listToSave = _notifiedIds.length > 500
          ? _notifiedIds.toList().sublist(_notifiedIds.length - 500)
          : _notifiedIds.toList();
      await prefs.setStringList(_notifiedIdsKey, listToSave);
    } catch (_) {}
  }

  Future<void> markDismissed(String id) async {
    _dismissedIds.add(id);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_dismissedIdsKey, _dismissedIds.toList());
    } catch (_) {}
  }

  bool isDismissed(String id) => _dismissedIds.contains(id);

  Future<void> _initFCM() async {
    try {
      final messaging = FirebaseMessaging.instance;

      await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      // Ensure iOS displays foreground notifications cleanly
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      final token = await messaging.getToken();
      if (token != null && token.isNotEmpty) {
        _fcmToken = token;
        unawaited(_registerFCMToken(token));
      }

      // Listen for token refresh and automatically update backend user_devices table
      messaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        _registerFCMToken(newToken);
      });

      // 1. FOREGROUND STATE: Display local banner with sound & deep-link payload
      FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
        final notification = message.notification;
        final title = notification?.title ?? message.data['title']?.toString();
        final body = notification?.body ??
            message.data['body']?.toString() ??
            message.data['message']?.toString();
        final route = message.data['route']?.toString() ?? '/notifications';

        if (title != null && body != null) {
          final notifId = message.data['notification_id']?.toString() ??
              message.messageId ??
              'fcm_${message.sentTime?.millisecondsSinceEpoch}_$title';
          if (!_notifiedIds.contains(notifId)) {
            _notifiedIds.add(notifId);
            await _saveNotifiedIds();
            await showNotification(
              id: notifId.hashCode & 0x7FFFFFFF,
              title: title,
              body: body,
              payload: route,
            );
          }
        }
      });

      // 2. BACKGROUND ISOLATE HANDLER
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // 3. BACKGROUND / MINIMIZED STATE TAP: Navigate directly to target screen
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        final route = message.data['route']?.toString() ?? '/notifications';
        _navigateToRoute(route);
      });

      // 4. TERMINATED STATE TAP: Check if app was cold-launched by tapping an FCM notification
      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        final route = initialMessage.data['route']?.toString() ?? '/notifications';
        _pendingInitialRoute = route;
        Future.delayed(const Duration(milliseconds: 600), () {
          if (_pendingInitialRoute != null) {
            _navigateToRoute(_pendingInitialRoute!);
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _registerFCMToken(String token) async {
    try {
      final authToken = await SecureStorageHelper.instance.read('token');
      if (authToken == null || authToken.isEmpty) return;

      final devId = await _ensureDeviceId();
      final platform = _detectPlatform();

      await ApiService().post('/devices/register', data: {
        'fcm_token': token,
        'device_id': devId,
        'platform': platform,
        'device_name': '${platform.toUpperCase()} Mobile',
      });
    } catch (_) {
      try {
        await ApiService().post('/auth/fcm-token', data: {'token': token});
      } catch (_) {}
    }
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    // Lightweight 60-second foreground check against `/notifications/unread`
    // (Instant push is handled by FCM; heavy 7-endpoint synthesis only runs when opening NotificationsScreen)
    _pollingTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      _checkUnreadNotificationsLightweight();
    });
    _checkUnreadNotificationsLightweight();
  }

  Future<void> _checkUnreadNotificationsLightweight() async {
    try {
      final token = await SecureStorageHelper.instance.read('token');
      if (token == null || token.isEmpty) return;

      // Sync IDs written by the background isolate so we never duplicate a background FCM push
      await _loadNotifiedIds();

      final res = await ApiService().get('/notifications/unread', forceRefresh: true);
      if (res.data is List) {
        await processUnreadNotifications(res.data as List);
      } else if (res.data is Map && res.data['notifications'] is List) {
        await processUnreadNotifications(res.data['notifications'] as List);
      }
    } catch (_) {}
  }

  double _num(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString().replaceAll(RegExp(r'[^0-9.-]'), '')) ?? 0;
  }

  /// Fetches and synthesizes ALL notifications, tasks, requests, collections, and approvals
  /// for the current user's role (Admin, Manager, Agent, Maintenance, Tenant) with full names & details.
  Future<List<Map<String, dynamic>>> fetchComprehensiveRoleNotifications() async {
    final token = await SecureStorageHelper.instance.read('token');
    if (token == null || token.isEmpty) return [];

    String role = 'admin';
    try {
      final rawUser = await SecureStorageHelper.instance.read('user');
      if (rawUser != null && rawUser.isNotEmpty) {
        final decoded = jsonDecode(rawUser);
        if (decoded is Map) {
          role = (decoded['role'] ?? 'admin').toString().toLowerCase();
        }
      }
    } catch (_) {}

    final combined = <Map<String, dynamic>>[];
    final seenIds = <String>{};

    void addItem(Map<String, dynamic> item) {
      final id = item['id']?.toString() ?? '';
      if (id.isEmpty || _dismissedIds.contains(id) || !seenIds.add(id)) return;
      combined.add(item);
    }

    // 1. Always fetch `/notifications/unread`
    try {
      final res = await ApiService().get('/notifications/unread', forceRefresh: true);
      if (res.data is List) {
        for (final raw in res.data as List) {
          if (raw is Map) {
            addItem(Map<String, dynamic>.from(raw));
          }
        }
      }
    } catch (_) {}

    final fmt = NumberFormat('#,##0');

    // 2. ADMIN & MANAGER: All Generator Submissions, Maintenance Tickets, AC Submissions, Purchases, & Meter Readings with Names
    if (role == 'admin' || role == 'manager') {
      final results = await Future.wait([
        ApiService().get('/maintenance-tickets/all').then<dynamic>((r) => r.data).catchError((_) => []),
        ApiService().get('/maintenance/admin/tasks').then<dynamic>((r) => r.data).catchError((_) => []),
        ApiService().get('/energy/agent/apartment-purchases/pending').then<dynamic>((r) => r.data).catchError((_) => []),
        ApiService().get('/energy/apartments/meter-readings/pending').then<dynamic>((r) => r.data).catchError((_) => []),
        ApiService().get('/agent-purchases?all=1').then<dynamic>((r) => r.data).catchError((_) => []),
        ApiService().get('/energy/reports/pending').then<dynamic>((r) => r.data).catchError((_) => []),
        ApiService().get('/energy/agent/subscription-readings/pending').then<dynamic>((r) => r.data).catchError((_) => []),
      ]);

      // A. Pending Generator Daily Reports
      final pendingGenReports = results[5] is List ? results[5] as List : [];
      for (final raw in pendingGenReports) {
        if (raw is! Map) continue;
        final agName = (raw['submitter_name'] ?? raw['agent_name'] ?? 'Field Agent').toString();
        final genName = (raw['generator_name'] ?? 'Generator').toString();
        final bld = (raw['building_name'] ?? 'Building').toString();
        final meterHrs = raw['current_meter_hours'] ?? raw['meter_hours'] ?? raw['current_kwh'] ?? 0;
        final runHrs = raw['running_hours'] ?? 0;
        final fuelAdd = raw['fuel_added'] ?? 0;
        final notes = (raw['notes'] ?? '').toString();

        addItem({
          'id': 'gen_rep_${raw['id']}',
          'title': '$agName submitted Generator Report — waiting for your response',
          'message': '$agName has submitted a generator reading for $genName ($bld) — waiting for your response.\nWhat is it: Generator Daily Report • Meter: $meterHrs hrs (+$runHrs hrs) • Fuel Added: ${fuelAdd}L${notes.isNotEmpty ? "\nNotes: $notes" : ""}',
          'type': 'generator_report',
          'route': '/energy/verification',
          'is_read': 0,
          'created_at': raw['submitted_at'] ?? raw['created_at'] ?? raw['date'] ?? DateTime.now().toIso8601String(),
        });
      }

      // B. AC Maintenance Tasks
      final acTasks = results[1] is List
          ? results[1] as List
          : (results[1] is Map && results[1]['tasks'] is List ? results[1]['tasks'] as List : []);
      for (final raw in acTasks) {
        if (raw is! Map) continue;
        final st = (raw['status'] ?? 'Pending').toString();
        if (st == 'Approved' || st == 'Completed') continue;
        final wName = (raw['worker_name'] ?? 'Maintenance Worker').toString();
        final bld = (raw['building_name'] ?? 'Building').toString();
        final apt = (raw['apartment_code'] ?? '').toString();
        final notes = (raw['notes'] ?? raw['description'] ?? '').toString();
        final isSubmitted = st.toLowerCase().contains('approval') || st.toLowerCase().contains('submit');

        addItem({
          'id': 'ac_${raw['id']}_$st',
          'title': isSubmitted
              ? '$wName completed AC Task — waiting for your response'
              : 'AC Task assigned to $wName ($bld • Apt $apt)',
          'message': isSubmitted
              ? '$wName has completed the AC maintenance task for $bld • Apt $apt — waiting for your response.\nWhat is it: AC Maintenance Submission${notes.isNotEmpty ? " — $notes" : ""}'
              : 'AC maintenance task at $bld • Apt $apt is assigned to $wName (Status: $st).${notes.isNotEmpty ? "\nDetails: $notes" : ""}',
          'type': 'maintenance_ac',
          'route': '/ac-maintenance',
          'is_read': 0,
          'created_at': raw['submission_date'] ?? raw['scheduled_date'] ?? DateTime.now().toIso8601String(),
        });
      }

      // C. Tenant Maintenance Tickets
      final tickets = results[0] is List
          ? results[0] as List
          : (results[0] is Map && results[0]['tickets'] is List ? results[0]['tickets'] as List : []);
      for (final raw in tickets) {
        if (raw is! Map) continue;
        final st = (raw['status'] ?? 'Open').toString();
        if (st == 'Closed' || st == 'Approved') continue;
        final tName = (raw['tenant_name'] ?? raw['full_name'] ?? 'Tenant').toString();
        final bld = (raw['building_name'] ?? 'Building').toString();
        final apt = (raw['apartment_code'] ?? raw['apartment_number'] ?? '').toString();
        final wName = (raw['worker_name'] ?? '').toString();
        final title = (raw['title'] ?? raw['category'] ?? 'Maintenance Request').toString();
        final desc = (raw['description'] ?? '').toString();
        final wNotes = (raw['worker_notes'] ?? '').toString();

        if (st == 'Resolved' || st == 'Submitted' || st == 'Pending_Approval') {
          final actor = wName.isNotEmpty ? wName : 'Maintenance Worker';
          addItem({
            'id': 'ticket_${raw['id']}_$st',
            'title': '$actor completed Task ($bld Apt $apt) — waiting for your response',
            'message': '$actor has completed the maintenance task for Tenant $tName ($bld • Apt $apt) — waiting for your response.\nWhat is it: $title${wNotes.isNotEmpty ? " • Worker Notes: $wNotes" : (desc.isNotEmpty ? " — $desc" : "")}',
            'type': 'tenant_maintenance',
            'route': '/ac-maintenance',
            'is_read': 0,
            'created_at': raw['resolved_at'] ?? raw['completion_date'] ?? raw['created_at'] ?? DateTime.now().toIso8601String(),
          });
        } else {
          addItem({
            'id': 'ticket_${raw['id']}_$st',
            'title': '$tName requested Maintenance — waiting for your response',
            'message': '$tName submitted a maintenance request for $bld • Apt $apt${wName.isNotEmpty ? " (Assigned to $wName)" : ""} — waiting for your response.\nWhat is it: $title${desc.isNotEmpty ? " — $desc" : ""}',
            'type': 'tenant_maintenance',
            'route': '/ac-maintenance',
            'is_read': 0,
            'created_at': raw['created_at'] ?? DateTime.now().toIso8601String(),
          });
        }
      }

      // D. Pending Agent Apartment Purchases
      final pendingPurch = results[2] is List ? results[2] as List : [];
      for (final raw in pendingPurch) {
        if (raw is! Map) continue;
        final agName = (raw['submitter_name'] ?? raw['agent_name'] ?? 'Field Agent').toString();
        final sup = (raw['supplier_name'] ?? raw['supplier'] ?? 'Supplier').toString();
        final bld = (raw['building_name'] ?? 'Building').toString();
        final apt = (raw['apartment_code'] ?? raw['apartment_number'] ?? '').toString();
        final amt = fmt.format(_num(raw['amount']));
        final notes = (raw['notes'] ?? raw['items'] ?? '').toString();

        addItem({
          'id': 'purch_${raw['id']}',
          'title': '$agName submitted Purchase (CFA $amt) — waiting for your response',
          'message': '$agName has submitted a purchase of CFA $amt from $sup for $bld • Apt $apt — waiting for your response.\nWhat is it: Apartment Purchase${notes.isNotEmpty ? " — $notes" : ""}',
          'type': 'task_purchase',
          'route': '/agent-purchase-review',
          'is_read': 0,
          'created_at': raw['date'] ?? raw['created_at'] ?? DateTime.now().toIso8601String(),
        });
      }

      final legacyPurch = results[4] is List ? results[4] as List : [];
      for (final raw in legacyPurch) {
        if (raw is! Map) continue;
        final st = (raw['status'] ?? '').toString();
        if (!st.toLowerCase().contains('pending')) continue;
        final agName = (raw['submitter_name'] ?? 'Field Agent').toString();
        final sup = (raw['supplier'] ?? 'Supplier').toString();
        final bld = (raw['building_name'] ?? 'Building').toString();
        final apt = (raw['apartment_number'] ?? '').toString();
        final amt = fmt.format(_num(raw['amount']));
        final items = (raw['items'] ?? '').toString();

        addItem({
          'id': 'agpurch_${raw['id']}',
          'title': '$agName submitted Purchase (CFA $amt) — waiting for your response',
          'message': '$agName has submitted a purchase of CFA $amt from $sup for $bld • Apt $apt — waiting for your response.\nWhat is it: $items',
          'type': 'task_purchase',
          'route': '/agent-purchase-review',
          'is_read': 0,
          'created_at': raw['created_at'] ?? DateTime.now().toIso8601String(),
        });
      }

      // E. Pending Electricity & Subscription Meter Readings
      final pendingMeters = results[3] is List ? results[3] as List : [];
      for (final raw in pendingMeters) {
        if (raw is! Map) continue;
        final agName = (raw['submitter_name'] ?? raw['agent_name'] ?? 'Field Agent').toString();
        final bld = (raw['building_name'] ?? 'Building').toString();
        final apt = (raw['apartment_code'] ?? '').toString();
        final cur = raw['current_reading'] ?? 0;
        final cons = raw['consumption'] ?? 0;
        final bill = fmt.format(_num(raw['bill_amount']));

        addItem({
          'id': 'meter_${raw['id']}',
          'title': '$agName submitted Meter Reading — waiting for your response',
          'message': '$agName has submitted an electricity meter reading for $bld • Apt $apt — waiting for your response.\nWhat is it: Meter Reading ($cur kWh • Consumption: $cons kWh • Bill: CFA $bill)',
          'type': 'electricity_meter',
          'route': '/energy/verification',
          'is_read': 0,
          'created_at': raw['created_at'] ?? DateTime.now().toIso8601String(),
        });
      }

      final pendingSubReadings = results[6] is List ? results[6] as List : [];
      for (final raw in pendingSubReadings) {
        if (raw is! Map) continue;
        final agName = (raw['submitter_name'] ?? raw['agent_name'] ?? 'Field Agent').toString();
        final tName = (raw['tenant_name'] ?? 'Tenant').toString();
        final bld = (raw['building_name'] ?? 'Building').toString();
        final apt = (raw['apartment_code'] ?? '').toString();
        final cur = raw['current_reading'] ?? 0;
        final cons = raw['consumption'] ?? 0;
        final collected = _num(raw['amount_collected']);

        addItem({
          'id': 'submeter_${raw['id']}',
          'title': '$agName submitted Generator/Sub Reading — waiting for your response',
          'message': '$agName has submitted a subscription reading for $tName ($bld • Apt $apt) — waiting for your response.\nWhat is it: Subscription Reading ($cur kWh • Consumption: $cons kWh${collected > 0 ? " • Collected: CFA ${fmt.format(collected)}" : ""})',
          'type': 'electricity_meter',
          'route': '/energy/verification',
          'is_read': 0,
          'created_at': raw['created_at'] ?? DateTime.now().toIso8601String(),
        });
      }
    }

    // 3. MAINTENANCE WORKER: All Assigned Tasks & Tenant Requests with Tenant Names & Details
    if (role == 'maintenance') {
      final results = await Future.wait([
        ApiService().get('/maintenance/tasks').then<dynamic>((r) => r.data).catchError((_) => []),
        ApiService().get('/maintenance-tickets/all').then<dynamic>((r) => r.data).catchError((_) => []),
      ]);

      final workerTasks = results[0] is List
          ? results[0] as List
          : (results[0] is Map && results[0]['tasks'] is List ? results[0]['tasks'] as List : []);
      final allTickets = results[1] is List
          ? results[1] as List
          : (results[1] is Map && results[1]['tickets'] is List ? results[1]['tickets'] as List : []);

      for (final raw in [...workerTasks, ...allTickets]) {
        if (raw is! Map) continue;
        final st = (raw['status'] ?? 'Open').toString();
        if (st == 'Resolved' || st == 'Completed' || st == 'Approved' || st == 'Closed') continue;

        final bld = (raw['building_name'] ?? 'Building').toString();
        final apt = (raw['apartment_code'] ?? raw['apartment_number'] ?? '').toString();
        final tName = (raw['tenant_name'] ?? raw['full_name'] ?? 'Tenant / Resident').toString();
        final tPhone = (raw['tenant_phone'] ?? raw['phone'] ?? '').toString();
        final title = (raw['title'] ?? raw['category'] ?? 'AC / Maintenance Task').toString();
        final desc = (raw['description'] ?? raw['notes'] ?? '').toString();
        final dateStr = (raw['scheduled_date'] ?? raw['created_at'] ?? '').toString();

        addItem({
          'id': 'maint_task_${raw['id']}_$st',
          'title': '$tName requested Maintenance ($bld Apt $apt) — waiting for your response',
          'message': '$tName${tPhone.isNotEmpty ? " ($tPhone)" : ""} at $bld • Apt $apt has a maintenance task waiting for your response.\nWhat is it: $title${desc.isNotEmpty ? " — $desc" : ""} (Status: $st)',
          'type': 'maintenance_task',
          'route': '/maintenance-dashboard',
          'is_read': 0,
          'created_at': dateStr.isNotEmpty ? dateStr : DateTime.now().toIso8601String(),
        });
      }
    }

    // 4. FIELD AGENT: All Rent Collection Tasks, Subscription Collections, Meter Tasks & Reading Feedback with Names
    if (role == 'agent') {
      final results = await Future.wait([
        ApiService().get('/agent/rent/tasks').then<dynamic>((r) => r.data).catchError((_) => []),
        ApiService().get('/energy/agent/subscription-invoices').then<dynamic>((r) => r.data).catchError((_) => []),
        ApiService().get('/energy/agent/subscription-tasks').then<dynamic>((r) => r.data).catchError((_) => []),
        ApiService().get('/energy/agent/reading-notifications').then<dynamic>((r) => r.data).catchError((_) => []),
      ]);

      final rentTasks = results[0] is List
          ? results[0] as List
          : (results[0] is Map && results[0]['tasks'] is List ? results[0]['tasks'] as List : []);
      for (final raw in rentTasks) {
        if (raw is! Map) continue;
        final tName = (raw['tenant_name'] ?? raw['full_name'] ?? 'Tenant').toString();
        final phone = (raw['phone'] ?? raw['tenant_phone'] ?? '').toString();
        final bld = (raw['building_name'] ?? 'Building').toString();
        final apt = (raw['apartment_code'] ?? '').toString();
        final invNo = (raw['invoice_number'] ?? 'INV').toString();
        final due = (raw['due_date'] ?? '').toString();
        final amt = fmt.format(_num(raw['outstanding'] ?? raw['amount_due'] ?? raw['amount']));

        addItem({
          'id': 'agent_rent_${raw['id'] ?? invNo}',
          'title': 'Collect Rent from $tName (CFA $amt) — waiting for your response',
          'message': '$tName${phone.isNotEmpty ? " ($phone)" : ""} at $bld • Apt $apt has rent of CFA $amt waiting for collection.\nWhat is it: Rent Invoice $invNo • Due: $due',
          'type': 'task_rent_collection',
          'route': '/agent-rent-collection',
          'is_read': 0,
          'created_at': due.isNotEmpty ? due : DateTime.now().toIso8601String(),
        });
      }

      final subInvoices = results[1] is List ? results[1] as List : [];
      for (final raw in subInvoices) {
        if (raw is! Map) continue;
        final tName = (raw['tenant_name'] ?? 'Resident').toString();
        final bld = (raw['building_name'] ?? 'Building').toString();
        final apt = (raw['apartment_code'] ?? '').toString();
        final type = (raw['type'] ?? 'Subscription').toString();
        final due = (raw['due_date'] ?? '').toString();
        final rem = _num(raw['amount']) - _num(raw['amount_paid']);
        if (rem <= 0) continue;

        addItem({
          'id': 'agent_subinv_${raw['id']}',
          'title': 'Collect $type from $tName (CFA ${fmt.format(rem)}) — waiting for your response',
          'message': '$tName at $bld • Apt $apt has a $type invoice of CFA ${fmt.format(rem)} waiting for collection.\nWhat is it: $type Collection • Due: $due',
          'type': 'electricity_collection',
          'route': '/agent-subscriptions',
          'is_read': 0,
          'created_at': due.isNotEmpty ? due : DateTime.now().toIso8601String(),
        });
      }

      final subTasks = results[2] is List ? results[2] as List : [];
      for (final raw in subTasks.take(15)) {
        if (raw is! Map) continue;
        final st = (raw['task_status'] ?? raw['status'] ?? '').toString();
        if (st.toLowerCase() == 'completed' || st.toLowerCase() == 'verified') continue;
        final tName = (raw['tenant_name'] ?? 'Resident').toString();
        final bld = (raw['building_name'] ?? 'Building').toString();
        final apt = (raw['apartment_code'] ?? '').toString();
        final plan = (raw['type'] ?? 'Meter').toString();

        addItem({
          'id': 'agent_subtask_${raw['apartment_id'] ?? raw['id']}',
          'title': 'Submit Reading for $tName ($bld Apt $apt) — waiting for your response',
          'message': '$tName at $bld • Apt $apt requires a $plan reading submission — waiting for your response.\nWhat is it: $plan Subscription Task',
          'type': 'task_subscription',
          'route': '/agent-subscriptions',
          'is_read': 0,
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      final readingNotifs = results[3] is List ? results[3] as List : [];
      for (final raw in readingNotifs) {
        if (raw is! Map) continue;
        final st = (raw['status'] ?? 'Updated').toString();
        final bld = (raw['building_name'] ?? 'Building').toString();
        final apt = (raw['apartment_code'] ?? '').toString();
        final reason = (raw['rejection_reason'] ?? '').toString();

        addItem({
          'id': 'agent_readnotif_${raw['id']}_$st',
          'title': st == 'Rejected'
              ? 'Admin rejected your reading ($bld Apt $apt) — waiting for your response'
              : 'Admin approved your reading ($bld Apt $apt)',
          'message': st == 'Rejected'
              ? 'Admin rejected your submitted reading for $bld • Apt $apt — waiting for your correction.\nWhat is it: Reading Rejection${reason.isNotEmpty ? " • Reason: $reason" : ""}'
              : 'Admin approved your submitted reading for $bld • Apt $apt.',
          'type': st == 'Rejected' ? 'rejected_reading' : 'approved_reading',
          'route': '/agent-history',
          'is_read': 0,
          'created_at': raw['created_at'] ?? DateTime.now().toIso8601String(),
        });
      }
    }

    return combined;
  }

  /// Processes unread notifications and displays native OS notifications for new IDs.
  Future<void> processUnreadNotifications(List<dynamic> notifications) async {
    if (notifications.isEmpty) return;

    bool hasChanges = false;
    int shownInBatch = 0;

    for (var n in notifications) {
      if (n is! Map) continue;
      final id = n['id']?.toString();
      if (id == null) continue;

      if (!_notifiedIds.contains(id)) {
        _notifiedIds.add(id);
        hasChanges = true;

        // Cap simultaneous OS banner popups per poll cycle to 3
        if (shownInBatch < 3) {
          shownInBatch++;
          await showNotification(
            id: id.hashCode & 0x7FFFFFFF,
            title: n['title']?.toString() ?? 'New Operational Alert',
            body: n['message']?.toString() ?? 'Action required on assigned task or request.',
            payload: n['route']?.toString() ?? '/notifications',
          );
        }
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
    if (kIsWeb) return;
    try {
      // Mask to positive 31-bit integer so 64-bit Dart hashCodes never crash Android's 32-bit NotificationManager
      final int safeId = id & 0x7FFFFFFF;
      final androidDetails = AndroidNotificationDetails(
        _channel.id,
        _channel.name,
        channelDescription: _channel.description,
        importance: Importance.max,
        priority: Priority.high,
        visibility: NotificationVisibility.public,
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
        id: safeId,
        title: title,
        body: body,
        notificationDetails: details,
        payload: payload,
      );
    } catch (e) {
      if (kDebugMode) print('[NotificationService] showNotification error: $e');
    }
  }

  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }
}
