// ─── Subscriptions Screen ─────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../config/app_theme.dart';
import '../services/api_service.dart';

final subscriptionsProvider = FutureProvider<List<dynamic>>((ref) async {
  final res = await ApiService().get('/electricity/subscriptions');
  return res.data as List<dynamic>;
});

class SubscriptionsScreen extends ConsumerStatefulWidget {
  const SubscriptionsScreen({super.key});
  @override
  ConsumerState<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends ConsumerState<SubscriptionsScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(subscriptionsProvider);
    final isMobile = MediaQuery.of(context).size.width <= 600;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(isMobile ? 16 : 24),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by apartment or building...',
                prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textSecondary),
                filled: true,
                fillColor: AppTheme.surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppTheme.primary)),
              ),
              style: GoogleFonts.inter(color: Colors.white),
              onChanged: (v) => setState(() => _search = v.toLowerCase()),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              color: AppTheme.primary,
              onRefresh: () async => ref.invalidate(subscriptionsProvider),
              child: async.when(
                loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
                error: (e, _) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: AppTheme.danger, size: 48),
                      const SizedBox(height: 16),
                      Text('Failed to load subscriptions', style: GoogleFonts.inter(color: Colors.white)),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                        onPressed: () => ref.invalidate(subscriptionsProvider),
                      ),
                    ],
                  ),
                ),
                data: (subs) {
                  final filtered = subs.where((s) {
                    final m = s as Map<String, dynamic>;
                    return _search.isEmpty ||
                        (m['apartment_number'] ?? '').toString().toLowerCase().contains(_search) ||
                        (m['building_name'] ?? '').toString().toLowerCase().contains(_search) ||
                        (m['tenant_name'] ?? '').toString().toLowerCase().contains(_search);
                  }).toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.receipt_long_outlined, size: 64, color: AppTheme.textSecondary.withValues(alpha: 0.4)),
                          const SizedBox(height: 16),
                          Text('No subscriptions found', style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 16)),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24, vertical: 8),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) => _SubscriptionCard(sub: filtered[i] as Map<String, dynamic>),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubscriptionCard extends StatelessWidget {
  final Map<String, dynamic> sub;
  const _SubscriptionCard({required this.sub});

  Color _statusColor(String status) {
    switch (status) {
      case 'active': return AppTheme.success;
      case 'expired': return AppTheme.danger;
      case 'pending_renewal': return AppTheme.warning;
      default: return AppTheme.textSecondary;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'active': return 'Active';
      case 'expired': return 'Expired';
      case 'pending_renewal': return 'Renewal Pending';
      default: return status;
    }
  }

  String _fmtDate(String? d) {
    if (d == null || d.isEmpty) return 'N/A';
    try {
      return DateFormat('d MMM yyyy').format(DateTime.parse(d));
    } catch (_) {
      return d;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = sub['status']?.toString() ?? 'unknown';
    final color = _statusColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.surfaceHover),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppTheme.accent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.bolt_rounded, color: AppTheme.accent, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Apt ${sub['apartment_number'] ?? ''} — ${sub['building_name'] ?? ''}',
                      style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                    if (sub['tenant_name'] != null && sub['tenant_name'].toString().isNotEmpty)
                      Text(sub['tenant_name'].toString(), style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
                child: Text(_statusLabel(status), style: GoogleFonts.inter(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: AppTheme.surfaceHover, thickness: 1),
          const SizedBox(height: 8),
          Row(
            children: [
              _InfoItem(icon: Icons.calendar_today_outlined, label: 'Start', value: _fmtDate(sub['start_date']?.toString())),
              const SizedBox(width: 20),
              _InfoItem(icon: Icons.event_outlined, label: 'Expiry', value: _fmtDate(sub['expiry_date']?.toString())),
              const SizedBox(width: 20),
              _InfoItem(
                icon: Icons.payments_outlined,
                label: 'Rate',
                value: sub['rate'] != null ? 'CFA ${sub['rate']}' : 'N/A',
                color: AppTheme.info,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoItem({required this.icon, required this.label, required this.value, this.color = AppTheme.textSecondary});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 12, color: AppTheme.textSecondary),
            const SizedBox(width: 4),
            Text(label, style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 11)),
          ],
        ),
        const SizedBox(height: 2),
        Text(value, style: GoogleFonts.inter(color: color, fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
