// ─── Tenant Subscriptions Screen ──────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../config/app_theme.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';

final tenantSubscriptionProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  // Get user info from auth to fetch their apartment subscription
  final user = ref.watch(authProvider).user;
  if (user == null) return {};

  // Try dashboard for apartment ID first
  final dashRes = await ApiService().get('/tenant-portal/dashboard');
  final dashData = dashRes.data as Map<String, dynamic>;
  final contract = dashData['contract'] as Map<String, dynamic>?;
  if (contract == null) return {};

  final aptId = contract['apartment_id']?.toString() ?? contract['id']?.toString();
  if (aptId == null) return {};

  try {
    final subRes = await ApiService().get('/energy/apartments/$aptId/subscriptions');
    final subData = subRes.data;
    if (subData is Map<String, dynamic>) return subData;
    return {'subscription': subData};
  } catch (_) {
    return {};
  }
});

class TenantSubscriptionsScreen extends ConsumerWidget {
  const TenantSubscriptionsScreen({super.key});

  String _fmtDate(String? d) {
    if (d == null || d.isEmpty) return 'N/A';
    try { return DateFormat('d MMM yyyy').format(DateTime.parse(d)); } catch (_) { return d; }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(tenantSubscriptionProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        color: AppTheme.primary,
        onRefresh: () async => ref.invalidate(tenantSubscriptionProvider),
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
          error: (e, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: AppTheme.danger, size: 48),
                const SizedBox(height: 16),
                Text('Failed to load subscription', style: GoogleFonts.inter(color: Colors.white)),
                TextButton.icon(icon: const Icon(Icons.refresh), label: const Text('Retry'), onPressed: () => ref.invalidate(tenantSubscriptionProvider)),
              ],
            ),
          ),
          data: (data) {
            if (data.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.bolt_outlined, size: 64, color: AppTheme.textSecondary.withValues(alpha: 0.4)),
                    const SizedBox(height: 16),
                    Text('No electricity subscription found', style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 16)),
                  ],
                ),
              );
            }

            // sub could be nested under 'subscription' key
            final sub = (data['subscription'] as Map<String, dynamic>?) ?? data;
            final status = sub['status']?.toString() ?? 'unknown';
            Color statusColor;
            switch (status) {
              case 'active': statusColor = AppTheme.success; break;
              case 'expired': statusColor = AppTheme.danger; break;
              case 'pending_renewal': statusColor = AppTheme.warning; break;
              default: statusColor = AppTheme.textSecondary;
            }

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Header card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [statusColor.withValues(alpha: 0.3), statusColor.withValues(alpha: 0.1)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.2), shape: BoxShape.circle),
                          child: Icon(Icons.electric_bolt_rounded, color: statusColor, size: 36),
                        ),
                        const SizedBox(height: 12),
                        Text('Electricity Subscription', style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
                          child: Text(status.toUpperCase(), style: GoogleFonts.inter(color: statusColor, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1)),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Details
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.surfaceHover),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('SUBSCRIPTION DETAILS', style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
                        const SizedBox(height: 12),
                        _Row('Generator', sub['generator_name']?.toString() ?? 'N/A'),
                        _Row('Start Date', _fmtDate(sub['start_date']?.toString())),
                        _Row('Expiry Date', _fmtDate(sub['expiry_date']?.toString())),
                        _Row('Rate', sub['rate'] != null ? 'CFA ${sub['rate']}/month' : 'N/A', highlight: true),
                        if (sub['meter_number'] != null)
                          _Row('Meter Number', sub['meter_number'].toString()),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;
  const _Row(this.label, this.value, {this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 13)),
          Text(value, style: GoogleFonts.inter(color: highlight ? AppTheme.success : Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
