// ─── Main Entry Point (Non-Blocking Instant Launch & Low-RAM Optimized) ──────

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'config/app_theme.dart';
import 'router/app_router.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';

Future<void> _ensureFirebaseInitialized() async {
  if (Firebase.apps.isNotEmpty) return;
  try {
    await Firebase.initializeApp();
  } catch (_) {
    try {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: 'AIzaSyDHfdeXmqXf3rEDvE2gL5EvvPpk9UWWwRs',
          appId: '1:192387594223:android:49fdaaaa22c899d9c2a81a',
          messagingSenderId: '192387594223',
          projectId: 'bitar-pms',
          storageBucket: 'bitar-pms.firebasestorage.app',
        ),
      );
    } catch (e) {
      if (kDebugMode) print('Firebase init skipped: $e');
    }
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Cap Flutter's decoded image cache to 60 images / 25 MB so 2GB–3GB RAM
  // devices never suffer OOM crashes or GC thrashing on photo-heavy screens.
  PaintingBinding.instance.imageCache.maximumSize = 60;
  PaintingBinding.instance.imageCache.maximumSizeBytes = 25 << 20; // 25 MB

  // Load .env file safely
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {}

  // Bind top-level FCM background isolate handler before runApp so background &
  // terminated messages are immediately received by the OS/Flutter engine.
  if (!kIsWeb) {
    try {
      await _ensureFirebaseInitialized();
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    } catch (_) {}
  }

  // Mount UI immediately
  runApp(
    const ProviderScope(
      child: BitarApp(),
    ),
  );

  // Initialize Notification Service asynchronously in the background
  unawaited(Future.microtask(() async {
    try {
      await _ensureFirebaseInitialized();
      await NotificationService().initialize();
    } catch (_) {}
  }));
}

class BitarApp extends ConsumerStatefulWidget {
  const BitarApp({super.key});

  @override
  ConsumerState<BitarApp> createState() => _BitarAppState();
}

class _BitarAppState extends ConsumerState<BitarApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // When returning from background or lock screen after hours/days:
      // 1. Proactively refresh expired access tokens via refresh_token without logging out
      // 2. Sync FCM token registration & unread notifications
      unawaited(Future.microtask(() async {
        await AuthService.refreshSessionIfNeeded();
        await NotificationService().onAppResumed();
      }));
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'SOCIMCO PMS',
      theme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
