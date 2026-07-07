// ─── Main Entry Point ─────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'config/app_theme.dart';
import 'router/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load .env file
  await dotenv.load(fileName: '.env');

  runApp(
    const ProviderScope(
      child: BitarApp(),
    ),
  );
}

class BitarApp extends ConsumerWidget {
  const BitarApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Bitar PMS',
      theme: AppTheme.dark,
      themeMode: ThemeMode.dark, // Force dark mode
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
