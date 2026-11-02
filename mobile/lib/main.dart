// ─── Main Entry Point (Non-Blocking Instant Launch) ──────────────────────────

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'config/app_theme.dart';
import 'router/app_router.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load .env file
  await dotenv.load(fileName: '.env');

  // Mount UI immediately without blocking on Firebase / Notification init
  runApp(
    const ProviderScope(
      child: BitarApp(),
    ),
  );

  // Initialize Firebase & Notification Service asynchronously in the background
  unawaited(Future.microtask(() async {
    try {
      await Firebase.initializeApp();
    } catch (e) {
      if (kDebugMode) print('Firebase init failed (missing config?): $e');
    }
    try {
      await NotificationService().initialize();
    } catch (_) {}
  }));
}

class BitarApp extends ConsumerWidget {
  const BitarApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
