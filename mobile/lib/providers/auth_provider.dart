// ─── Auth Provider (Riverpod 3.x) ────────────────────────────────────────────

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../core/network/realtime_service.dart';
import '../core/storage/secure_storage_helper.dart';
import '../config/app_config.dart';
import 'currency_provider.dart';

// ── Auth state ────────────────────────────────────────────────────────────────
class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;
  final bool isAuthenticated;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.isAuthenticated = false,
  });

  AuthState copyWith({
    User? user,
    bool? isLoading,
    String? error,
    bool? isAuthenticated,
  }) =>
      AuthState(
        user: user ?? this.user,
        isLoading: isLoading ?? this.isLoading,
        error: error,
        isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      );
}

// ── Auth notifier (Riverpod 3 Notifier) ───────────────────────────────────────
class AuthNotifier extends Notifier<AuthState> {
  final AuthService _authService = AuthService();

  @override
  AuthState build() {
    // Wire 401 callback: any unauthorized response triggers logout
    ApiService().onUnauthorized = logout;
    // Load persisted token on startup
    _init();
    return const AuthState(isLoading: true);
  }

  Future<void> _init() async {
    final loggedIn = await _authService.isLoggedIn();
    if (loggedIn) {
      final user = await _authService.getCurrentUser();
      if (user != null) {
        // Restore authenticated session immediately so splash navigates straight to the dashboard
        state = AuthState(user: user, isAuthenticated: true);

        // Immediately start pre-warming role endpoints in parallel (0ms delay)
        ApiService().prefetchForRole(user.role);

        // Background silent token refresh & notification sync
        Future.microtask(() async {
          var currentToken = await SecureStorageHelper.instance.read('token');
          if (AuthService.isTokenExpiringSoon(currentToken, bufferSeconds: 120)) {
            final outcome = await AuthService.refreshSession();
            if (outcome == RefreshResult.revoked) {
              await logout();
              return;
            }
            if (outcome == RefreshResult.refreshed) {
              currentToken = await SecureStorageHelper.instance.read('token');
              final refreshedUser = await _authService.getCurrentUser();
              if (refreshedUser != null) {
                state = AuthState(user: refreshedUser, isAuthenticated: true);
              }
            }
          }

          NotificationService().syncAfterLogin();

          if (currentToken != null && state.user != null) {
            _initRealtime(currentToken, state.user!.role);
          }
        });
        return;
      }
    }
    state = const AuthState(isAuthenticated: false);
  }

  Future<bool> login(String loginIdentifier, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _authService.login(loginIdentifier, password);
      state = AuthState(user: user, isAuthenticated: true);
      ApiService().prefetchForRole(user.role);
      NotificationService().syncAfterLogin();

      // After successful login, wire realtime service + set currency default
      final token = await SecureStorageHelper.instance.read('token');
      if (token != null) {
        _initRealtime(token, user.role);
      }

      // Set currency default for this role
      await ref.read(currencyProvider.notifier).setCurrencyForRole(user.role);

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _parseError(e),
        isAuthenticated: false,
      );
      return false;
    }
  }

  Future<void> logout() async {
    // Stop notification polling and unregister device FCM token first
    NotificationService().stopPolling();
    await NotificationService().unregisterCurrentDevice();
    // Dispose realtime connection
    RealtimeService.instance.dispose();

    await _authService.logout();
    state = const AuthState(isAuthenticated: false);
  }

  /// Initialize the realtime polling service with the auth token.
  void _initRealtime(String token, String role) {
    try {
      RealtimeService.instance.initialize(
        baseUrl: AppConfig.apiBaseUrl,
        token: token,
      );
    } catch (e) {
      // Non-fatal: real-time updates will be unavailable but app still works
    }
  }

  String _parseError(dynamic e) {
    if (e is DioException) {
      if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.receiveTimeout) {
        return 'Connection timeout. Check your Wi-Fi or internet connection.';
      }
      if (e.type == DioExceptionType.connectionError || e.response == null) {
        return 'Cannot connect to server. Please check your Wi-Fi or internet connection.';
      }
      final rawData = e.response?.data;
      if (rawData != null) {
        try {
          if (rawData is Map) {
            return rawData['error']?.toString() ?? rawData['message']?.toString() ?? 'Invalid credentials. Please try again.';
          }
          if (rawData is String && rawData.trim().startsWith('{')) {
            final parsed = jsonDecode(rawData);
            if (parsed is Map) {
              return parsed['error']?.toString() ?? parsed['message']?.toString() ?? 'Invalid credentials. Please try again.';
            }
          }
          if (rawData is String && rawData.contains('<html')) {
            return 'Server error. Please contact your administrator. (HTTP ${e.response?.statusCode})';
          }
        } catch (_) {}
      }
      if (e.response?.statusCode == 401) return 'Invalid credentials. Please try again.';
      if (e.response?.statusCode == 403) return 'Access denied. Your account may not have permission.';
      if (e.response?.statusCode == 500) return 'Server error (500). Please try again or contact support.';
    }
    return 'Login failed. Please check your internet connection and credentials.';
  }

  /// Expose a way to read the stored token for external services.
  Future<String?> getToken() => SecureStorageHelper.instance.read('token');
}

// ── Provider ──────────────────────────────────────────────────────────────────
final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
