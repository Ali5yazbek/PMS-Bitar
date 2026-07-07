// ─── Auth Provider (Riverpod 3.x) ────────────────────────────────────────────
// Riverpod 3 replaced StateNotifier with Notifier + NotifierProvider.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';

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
      state = AuthState(user: user, isAuthenticated: true);
    } else {
      state = const AuthState(isAuthenticated: false);
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _authService.login(email, password);
      state = AuthState(user: user, isAuthenticated: true);
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
    await _authService.logout();
    state = const AuthState(isAuthenticated: false);
  }

  String _parseError(dynamic e) {
    try {
      return (e as dynamic).response?.data?['error'] ?? 'Login failed. Try again.';
    } catch (_) {
      return 'Login failed. Try again.';
    }
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────
final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
