// ─── App Configuration ────────────────────────────────────────────────────────
// Reads API_BASE_URL from .env via flutter_dotenv
// Change the .env file to switch between local/production

import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static String get apiBaseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'https://yourdomain.com/api';

  static String get appName =>
      dotenv.env['APP_NAME'] ?? 'Bitar PMS';

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 20);
}
