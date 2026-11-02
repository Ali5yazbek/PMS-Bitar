// ─── Executive Dashboard Screen (Luxury Obsidian & Royal Teal/Gold) ──────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_theme.dart';
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
    final statsAsync = ref.watch(dashboardStatsProvider);
    final user = ref.watch(authProvider).user;

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(dashboardStatsProvider),
      color: AppTheme.primary,
      backgroundColor: AppTheme.surface,
      child: statsAsync.when(
        loading: () => _buildLoadingSkeleton(user?.name ?? 'Admin'),
        error: (e, _) => _buildErrorState(e.toString(), () => ref.invalidate(dashboardStatsProvider)),
        data: (stats) => _DashboardContent(stats: stats, userName: user?.name ?? 'Admin'),
      ),
    );
  }

  Widget _buildLoadingSkeleton(String name) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SkeletonBox(height: 110),
          const SizedBox(height: 20),
          const _SkeletonBox(width: 180, height: 20),
          const SizedBox(height: 14),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.55,
            children: List.generate(6, (_) => const _SkeletonBox()),
          ),
          const SizedBox(height: 24),
          const _SkeletonBox(width: 200, height: 18),
          const SizedBox(height: 12),
          ...List.generate(
            3,
            (_) => const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: _SkeletonBox(height: 84),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: AppTheme.glassCardDecoration(borderRadius: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppTheme.danger.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.cloud_off_rounded, color: AppTheme.danger, size: 44),
              ),
              const SizedBox(height: 18),
              Text(
                'Connection Interrupted',
                style: GoogleFonts.outfit(
                  color: AppTheme.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error.replaceAll('Exception: ', ''),
                style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.textSecondary,
                  fontSize: 12.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: const Color(0xFF04130F),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(
                  'Reconnect Now',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w800),
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
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.6)),
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

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Luxury Executive Welcome Hero Card ──────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0E2925),
                  Color(0xFF0B1926),
                  Color(0xFF141E2B),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppTheme.primary.withValues(alpha: 0.35),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.14),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -12,
                  top: -12,
                  child: Icon(
                    Icons.domain_rounded,
                    size: 96,
                    color: AppTheme.accent.withValues(alpha: 0.08),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.accent.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppTheme.accent.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.workspace_premium_rounded, size: 13, color: AppTheme.accent),
                              const SizedBox(width: 5),
                              Text(
                                'EXECUTIVE PORTFOLIO',
                                style: GoogleFonts.plusJakartaSans(
                                  color: AppTheme.accent,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.28),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: Text(
                            dateBadge,
                            style: GoogleFonts.plusJakartaSans(
                              color: AppTheme.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Welcome back, ${widget.userName}',
                      style: GoogleFonts.outfit(
                        color: AppTheme.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Live financial telemetry, collections & active property alerts',
                      style: GoogleFonts.plusJakartaSans(
                        color: AppTheme.textSecondary,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),

          // ── Financial Summary Section Header ────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 18,
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Financial Telemetry',
                    style: GoogleFonts.outfit(
                      color: AppTheme.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Text(
                  'Current Month',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.textMuted,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ── Bento Financial Summary Grid ────────────────────────────────────
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.52,
            children: [
              _FinCard(
                title: 'Total Rent Due',
                value: stats['total_rent_due']?.toString() ?? '—',
                icon: Icons.account_balance_wallet_rounded,
                iconColor: const Color(0xFF38BDF8),
              ),
              _FinCard(
                title: 'Rent Collected',
                value: stats['total_rent_collected']?.toString() ?? '—',
                icon: Icons.payments_rounded,
                iconColor: AppTheme.primary,
              ),
              _FinCard(
                title: 'Outstanding Rent',
                value: stats['outstanding_rent_balance']?.toString() ?? '—',
                icon: Icons.trending_down_rounded,
                iconColor: AppTheme.danger,
              ),
              _FinCard(
                title: 'Unpaid Invoices',
                value: '${stats['unpaid_rent_invoices'] ?? '—'}',
                icon: Icons.receipt_long_rounded,
                iconColor: AppTheme.accent,
              ),
              _FinCard(
                title: 'Insurance Pool',
                value: stats['insurance_collected']?.toString() ?? '—',
                icon: Icons.verified_user_rounded,
                iconColor: const Color(0xFFA78BFA),
              ),
              _FinCard(
                title: 'Electricity Pool',
                value: stats['electricity_collected']?.toString() ?? '—',
                icon: Icons.electric_bolt_rounded,
                iconColor: AppTheme.accent,
              ),
              _FinCard(
                title: 'Generator Pool',
                value: stats['generator_collected']?.toString() ?? '—',
                icon: Icons.bolt_rounded,
                iconColor: const Color(0xFF2DD4BF),
              ),
            ],
          ),

          const SizedBox(height: 26),

          // ── Today's Collections ─────────────────────────────────────────────
          Row(
            children: [
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  gradient: AppTheme.goldGradient,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                "Today's Collections",
                style: GoogleFonts.outfit(
                  color: AppTheme.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'By Method',
                style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if ((stats['todayCollections'] as List?)?.isEmpty ?? true)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 20),
              decoration: AppTheme.glassCardDecoration(borderRadius: 20),
              child: Column(
                children: [
                  Icon(
                    Icons.point_of_sale_rounded,
                    color: AppTheme.textMuted.withValues(alpha: 0.6),
                    size: 30,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No collections recorded yet today.',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          else
            ...(stats['todayCollections'] as List<dynamic>).map(
              (c) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: AppTheme.glassCardDecoration(borderRadius: 18),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.account_balance_wallet_rounded,
                            color: AppTheme.primary,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          c['payment_method']?.toString() ?? c['method']?.toString() ?? 'Cash',
                          style: GoogleFonts.outfit(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.primary.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Text(
                        c['total']?.toString() ?? c['amount']?.toString() ?? '0',
                        style: GoogleFonts.outfit(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 14.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 26),

          // ── Alerts & Action Center ──────────────────────────────────────────
          Row(
            children: [
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  color: AppTheme.danger,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Alerts & Action Center',
                style: GoogleFonts.outfit(
                  color: AppTheme.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (allAlerts.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(left: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.danger.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.danger.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    '${allAlerts.length}',
                    style: GoogleFonts.outfit(
                      color: AppTheme.danger,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

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
                  const SizedBox(width: 8),
                  if (electricityAlerts.isNotEmpty)
                    _FilterChip(
                      label: 'Electricity (${electricityAlerts.length})',
                      isSelected: _alertFilter == 'Electricity',
                      onTap: () => setState(() => _alertFilter = 'Electricity'),
                    ),
                  const SizedBox(width: 8),
                  if (rentAlerts.isNotEmpty)
                    _FilterChip(
                      label: 'Rent (${rentAlerts.length})',
                      isSelected: _alertFilter == 'Rent',
                      onTap: () => setState(() => _alertFilter = 'Rent'),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            ...filteredAlerts.map(
              (alert) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _AlertCard(
                  title: alert['title']?.toString() ?? alert['type']?.toString() ?? 'Alert',
                  badge: alert['priority']?.toString() ?? 'Warning',
                  badgeColor: (alert['priority'] ?? '').toString().toLowerCase() == 'critical'
                      ? AppTheme.danger
                      : AppTheme.accent,
                  detail: alert['message']?.toString() ?? '',
                  subDetail:
                      'Apt ${alert['apartment_number'] ?? ''} • ${alert['tenant_name'] ?? ''}',
                ),
              ),
            ),
          ] else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(26),
              decoration: AppTheme.glassCardDecoration(borderRadius: 20),
              child: Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.14),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.verified_rounded,
                        color: AppTheme.primary,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'All Systems Nominal',
                      style: GoogleFonts.outfit(
                        color: AppTheme.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'No critical alerts require attention.',
                      style: GoogleFonts.plusJakartaSans(
                        color: AppTheme.textMuted,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
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
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          gradient: isSelected ? AppTheme.primaryGradient : null,
          color: isSelected ? null : AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.border,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.3),
                    blurRadius: 10,
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            color: isSelected ? const Color(0xFF04130F) : AppTheme.textSecondary,
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: AppTheme.obsidianCardGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: iconColor.withValues(alpha: 0.25),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.32),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            top: -10,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: iconColor.withValues(alpha: 0.08),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: iconColor.withValues(alpha: 0.3),
                        width: 0.8,
                      ),
                    ),
                    child: Icon(icon, size: 16, color: iconColor),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.plusJakartaSans(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              Text(
                value,
                style: GoogleFonts.outfit(
                  color: AppTheme.textPrimary,
                  fontSize: 17.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            badgeColor.withValues(alpha: 0.14),
            AppTheme.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: badgeColor.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.warning_amber_rounded, color: badgeColor, size: 18),
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
                          fontWeight: FontWeight.w700,
                          fontSize: 14.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        badge.toUpperCase(),
                        style: GoogleFonts.plusJakartaSans(
                          color: badgeColor,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  detail,
                  style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subDetail,
                  style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.textMuted,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
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
