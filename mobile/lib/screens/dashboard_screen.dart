// ─── Executive Admin Dashboard Screen ────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_theme.dart';
import '../models/user.dart';
import '../router/app_router.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';

/// Fetches from the 3 real dashboard endpoints in parallel and merges them
final dashboardStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  try {
    final results = await Future.wait([
      ApiService().get('/dashboard/financial-summary'),
      ApiService().get('/dashboard/alerts'),
      ApiService().get('/dashboard/collections'),
    ]);

    final financials = (results[0].data as Map<String, dynamic>?) ?? {};
    final alertsData = (results[1].data as Map<String, dynamic>?) ?? {};
    final collections = (results[2].data as Map<String, dynamic>?) ?? {};

    return {
      ...financials,
      'alerts': alertsData['alerts'] ?? [],
      'todayCollections': collections['payment_methods_breakdown'] ?? [],
    };
  } catch (e) {
    throw Exception('Failed to load dashboard stats: $e');
  }
});

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final role = User.normalizeRole(user?.role);

    if (role != 'admin') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          context.go(getDefaultRouteForRole(role));
        }
      });
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 2.5),
      );
    }

    final statsAsync = ref.watch(dashboardStatsProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(dashboardStatsProvider),
      color: AppTheme.primary,
      backgroundColor: AppTheme.surface,
      child: statsAsync.when(
        loading: () => _buildLoadingSkeleton(),
        error: (e, _) => _buildErrorState(
          e.toString(),
          () => ref.invalidate(dashboardStatsProvider),
        ),
        data: (stats) => _DashboardContent(
          stats: stats,
          userName: user?.name ?? 'Administrator',
        ),
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SkeletonBox(height: 100),
          const SizedBox(height: 20),
          const _SkeletonBox(width: 160, height: 18),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              mainAxisExtent: 88,
            ),
            itemCount: 6,
            itemBuilder: (_, __) => const _SkeletonBox(height: 88),
          ),
          const SizedBox(height: 22),
          const _SkeletonBox(width: 180, height: 18),
          const SizedBox(height: 12),
          ...List.generate(
            3,
            (_) => const Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: _SkeletonBox(height: 76),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.danger.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.cloud_off_rounded,
                  color: AppTheme.danger,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Unable to load dashboard',
                style: GoogleFonts.outfit(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                error.replaceAll('Exception: ', ''),
                style: GoogleFonts.inter(
                  color: AppTheme.textSecondary,
                  fontSize: 12.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: const Color(0xFF04130F),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 17),
                label: Text(
                  'Retry',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  final double? width;
  final double height;

  const _SkeletonBox({this.width, this.height = 60});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
    );
  }
}

class _DashboardContent extends StatefulWidget {
  final Map<String, dynamic> stats;
  final String userName;
  const _DashboardContent({required this.stats, required this.userName});

  @override
  State<_DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<_DashboardContent> {
  String _alertFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final stats = widget.stats;
    final now = DateTime.now();
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final dateBadge = '${now.day} ${months[now.month - 1]} ${now.year}';

    final allAlerts = (stats['alerts'] as List<dynamic>?) ?? [];
    final electricityAlerts = allAlerts
        .where((a) => (a['category'] ?? '').toString().toLowerCase().contains('electric'))
        .toList();
    final rentAlerts = allAlerts
        .where((a) => (a['category'] ?? '').toString().toLowerCase().contains('contract'))
        .toList();

    final filteredAlerts = _alertFilter == 'All'
        ? allAlerts
        : _alertFilter == 'Electricity'
            ? electricityAlerts
            : rentAlerts;

    final List<({String title, String value, IconData icon, Color color})> finItems = [
      (
        title: 'Total Rent Due',
        value: stats['total_rent_due']?.toString() ?? '—',
        icon: Icons.account_balance_wallet_outlined,
        color: AppTheme.info,
      ),
      (
        title: 'Rent Collected',
        value: stats['total_rent_collected']?.toString() ?? '—',
        icon: Icons.payments_outlined,
        color: AppTheme.primary,
      ),
      (
        title: 'Outstanding Rent',
        value: stats['outstanding_rent_balance']?.toString() ?? '—',
        icon: Icons.trending_down_rounded,
        color: AppTheme.danger,
      ),
      (
        title: 'Unpaid Invoices',
        value: '${stats['unpaid_rent_invoices'] ?? '—'}',
        icon: Icons.receipt_long_outlined,
        color: AppTheme.warning,
      ),
      (
        title: 'Insurance Pool',
        value: stats['insurance_collected']?.toString() ?? '—',
        icon: Icons.verified_user_outlined,
        color: AppTheme.secondary,
      ),
      (
        title: 'Electricity Pool',
        value: stats['electricity_collected']?.toString() ?? '—',
        icon: Icons.electric_bolt_rounded,
        color: AppTheme.accent,
      ),
      (
        title: 'Generator Pool',
        value: stats['generator_collected']?.toString() ?? '—',
        icon: Icons.power_outlined,
        color: AppTheme.primaryLight,
      ),
    ];

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Executive Overview Banner ──────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppTheme.primary.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.domain_rounded,
                            size: 12,
                            color: AppTheme.primary,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'EXECUTIVE OVERVIEW',
                            style: GoogleFonts.inter(
                              color: AppTheme.primary,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      dateBadge,
                      style: GoogleFonts.inter(
                        color: AppTheme.textMuted,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Welcome back, ${widget.userName}',
                  style: GoogleFonts.outfit(
                    color: AppTheme.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Portfolio financial performance, daily collections, and active alerts',
                  style: GoogleFonts.inter(
                    color: AppTheme.textSecondary,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),

          // ── Financial Summary Section Header ───────────────────────────────
          AppTheme.sectionHeader(
            'Financial Summary',
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.border),
              ),
              child: Text(
                'Current Month',
                style: GoogleFonts.inter(
                  color: AppTheme.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              mainAxisExtent: 88,
            ),
            itemCount: finItems.length,
            itemBuilder: (context, index) {
              final item = finItems[index];
              return _FinCard(
                title: item.title,
                value: item.value,
                icon: item.icon,
                iconColor: item.color,
              );
            },
          ),

          const SizedBox(height: 24),

          // ── Today's Collections ────────────────────────────────────────────
          AppTheme.sectionHeader(
            "Today's Collections",
            subtitle: 'Breakdown by payment method',
          ),
          if ((stats['todayCollections'] as List?)?.isEmpty ?? true)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 18),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceHover,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.point_of_sale_outlined,
                      color: AppTheme.textMuted,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'No collections recorded yet today.',
                      style: GoogleFonts.inter(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            ...(stats['todayCollections'] as List<dynamic>).map(
              (c) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.account_balance_wallet_outlined,
                            color: AppTheme.primary,
                            size: 17,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          c['payment_method']?.toString() ??
                              c['method']?.toString() ??
                              'Cash',
                          style: GoogleFonts.inter(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      c['total']?.toString() ?? c['amount']?.toString() ?? '0',
                      style: GoogleFonts.outfit(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 24),

          // ── Alerts & Action Center ─────────────────────────────────────────
          AppTheme.sectionHeader(
            'Active Alerts',
            trailing: allAlerts.isNotEmpty
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.danger.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.danger.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      '${allAlerts.length}',
                      style: GoogleFonts.inter(
                        color: AppTheme.danger,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                : null,
          ),

          if (allAlerts.isNotEmpty) ...[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: 'All (${allAlerts.length})',
                    isSelected: _alertFilter == 'All',
                    onTap: () => setState(() => _alertFilter = 'All'),
                  ),
                  if (electricityAlerts.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Electricity (${electricityAlerts.length})',
                      isSelected: _alertFilter == 'Electricity',
                      onTap: () => setState(() => _alertFilter = 'Electricity'),
                    ),
                  ],
                  if (rentAlerts.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Rent (${rentAlerts.length})',
                      isSelected: _alertFilter == 'Rent',
                      onTap: () => setState(() => _alertFilter = 'Rent'),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            ...filteredAlerts.map(
              (alert) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _AlertCard(
                  title: alert['title']?.toString() ??
                      alert['type']?.toString() ??
                      'Alert',
                  badge: alert['priority']?.toString() ?? 'Warning',
                  badgeColor: (alert['priority'] ?? '')
                              .toString()
                              .toLowerCase() ==
                          'critical'
                      ? AppTheme.danger
                      : AppTheme.warning,
                  detail: alert['message']?.toString() ?? '',
                  subDetail:
                      'Apt ${alert['apartment_number'] ?? ''} • ${alert['tenant_name'] ?? ''}',
                ),
              ),
            ),
          ] else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.check_circle_outline_rounded,
                      color: AppTheme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'All systems nominal',
                          style: GoogleFonts.outfit(
                            color: AppTheme.textPrimary,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'No critical property alerts require attention.',
                          style: GoogleFonts.inter(
                            color: AppTheme.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primary.withValues(alpha: 0.14)
              : AppTheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? AppTheme.primary.withValues(alpha: 0.4)
                : AppTheme.border,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _FinCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;

  const _FinCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 15, color: iconColor),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    color: AppTheme.textSecondary,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Text(
            value,
            style: GoogleFonts.outfit(
              color: AppTheme.textPrimary,
              fontSize: 16.5,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final String title;
  final String badge;
  final Color badgeColor;
  final String detail;
  final String subDetail;

  const _AlertCard({
    required this.title,
    required this.badge,
    required this.badgeColor,
    required this.detail,
    required this.subDetail,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.warning_amber_rounded,
              color: badgeColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: GoogleFonts.outfit(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        badge.toUpperCase(),
                        style: GoogleFonts.inter(
                          color: badgeColor,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  detail,
                  style: GoogleFonts.inter(
                    color: AppTheme.textSecondary,
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subDetail,
                  style: GoogleFonts.inter(
                    color: AppTheme.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
