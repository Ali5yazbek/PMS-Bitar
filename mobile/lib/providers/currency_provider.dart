// ─── Currency Provider ────────────────────────────────────────────────────────
// Mirrors the web's CurrencyContext.jsx exactly:
//   • Agents default to USD
//   • Admin/Manager default to CFA
//   • Exchange rate fetched from /auth/me API
//   • Persisted in SharedPreferences ('preferred_currency')
//   • formatAmount(dynamic amountCFA) → currency-aware string

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

// ── State ─────────────────────────────────────────────────────────────────────
class CurrencyState {
  final String currency;       // 'CFA' or 'USD'
  final double exchangeRate;   // CFA per 1 USD
  final bool isInitialized;

  const CurrencyState({
    this.currency = 'CFA',
    this.exchangeRate = 600.0,
    this.isInitialized = false,
  });

  CurrencyState copyWith({
    String? currency,
    double? exchangeRate,
    bool? isInitialized,
  }) =>
      CurrencyState(
        currency: currency ?? this.currency,
        exchangeRate: exchangeRate ?? this.exchangeRate,
        isInitialized: isInitialized ?? this.isInitialized,
      );
}

// ── Notifier ──────────────────────────────────────────────────────────────────
class CurrencyNotifier extends Notifier<CurrencyState> {
  @override
  CurrencyState build() {
    _init();
    return const CurrencyState();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Fetch latest exchange rate from API
    double exchangeRate = 600.0;
    try {
      final res = await ApiService().get('/auth/me');
      final rate = res.data?['settings']?['exchange_rate'];
      if (rate != null) {
        exchangeRate = (rate as num).toDouble();
      }
    } catch (_) {}

    // 2. Determine preferred currency
    final saved = prefs.getString('preferred_currency');
    String currency;

    if (saved != null) {
      currency = saved;
    } else {
      // Agent role defaults to USD, all others to CFA
      final roleHint = prefs.getString('user_role_hint') ?? 'admin';
      currency = roleHint == 'agent' ? 'USD' : 'CFA';
      await prefs.setString('preferred_currency', currency);
    }

    state = CurrencyState(
      currency: currency,
      exchangeRate: exchangeRate,
      isInitialized: true,
    );
  }

  /// Toggle between CFA and USD and persist the choice.
  Future<void> toggleCurrency() async {
    final next = state.currency == 'CFA' ? 'USD' : 'CFA';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('preferred_currency', next);
    state = state.copyWith(currency: next);
  }

  /// Force-set currency default based on user role (called right after login).
  Future<void> setCurrencyForRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_role_hint', role);

    // Only override if no explicit user preference was previously stored
    final saved = prefs.getString('preferred_currency');
    if (saved == null) {
      final defaultCurrency = role == 'agent' ? 'USD' : 'CFA';
      await prefs.setString('preferred_currency', defaultCurrency);
      state = state.copyWith(currency: defaultCurrency);
    }
  }

  /// Update exchange rate when fresh API data arrives.
  void updateExchangeRate(double rate) {
    state = state.copyWith(exchangeRate: rate);
  }

  /// Format a CFA amount into the currently active currency string.
  /// Output examples: "CFA 1,250,000.00"  or  "$2,083.33 USD"
  String formatAmount(dynamic amountCFA) {
    final double cfa = amountCFA == null
        ? 0.0
        : double.tryParse(amountCFA.toString()) ?? 0.0;

    if (state.currency == 'USD') {
      final usd = cfa / state.exchangeRate;
      return '\$${usd.toStringAsFixed(2)} USD';
    } else {
      final parts = cfa.toStringAsFixed(2).split('.');
      final intPart = parts[0].replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
      );
      return 'CFA $intPart.${parts[1]}';
    }
  }

  String get currencySymbol => state.currency == 'USD' ? '\$' : 'CFA';
  String get currencyLabel => state.currency;
}

// ── Provider ──────────────────────────────────────────────────────────────────
final currencyProvider = NotifierProvider<CurrencyNotifier, CurrencyState>(
  CurrencyNotifier.new,
);

/// Convenience: watch this to get a formatting function anywhere in the widget tree.
final formatAmountProvider = Provider<String Function(dynamic)>((ref) {
  return ref.watch(currencyProvider.notifier).formatAmount;
});
