// ─── Enterprise Account & Workspace Settings Screen ──────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_config.dart';
import '../config/app_theme.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';
import '../providers/currency_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppTheme.border),
        ),
        title: Text(
          'Sign Out',
          style: GoogleFonts.outfit(
            color: AppTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Are you sure you want to sign out of your SOCIMCO account on this device?',
          style: GoogleFonts.inter(
            color: AppTheme.textSecondary,
            fontSize: 13.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.danger,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Sign Out',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(authProvider.notifier).logout();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final cleanRole = User.normalizeRole(user?.role);
    final currentCurrency = ref.watch(currencyProvider).currency;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
      children: [
        // ── User Profile Card ────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.border),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppTheme.primary.withValues(alpha: 0.3),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  (user?.name.isNotEmpty == true ? user!.name : 'U')[0].toUpperCase(),
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.name ?? 'User',
                      style: GoogleFonts.outfit(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    if ((user?.email ?? '').isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        user!.email,
                        style: GoogleFonts.inter(
                          color: AppTheme.textSecondary,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        cleanRole.toUpperCase(),
                        style: GoogleFonts.inter(
                          color: AppTheme.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // ── Workspace Preferences ────────────────────────────────────────────
        AppTheme.sectionHeader('Workspace Preferences'),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.border),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: _buildIcon(Icons.currency_exchange_rounded, AppTheme.primary),
            title: Text(
              'Display Currency',
              style: GoogleFonts.inter(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 13.5,
              ),
            ),
            subtitle: Text(
              'Active currency for financial displays',
              style: GoogleFonts.inter(
                color: AppTheme.textMuted,
                fontSize: 11.5,
              ),
            ),
            trailing: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => ref.read(currencyProvider.notifier).toggleCurrency(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceHover,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.borderLight),
                ),
                child: Text(
                  currentCurrency,
                  style: GoogleFonts.inter(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 20),

        // ── Reports & Financials (Admin / Manager) ───────────────────────────
        if (cleanRole == 'admin' || cleanRole == 'manager') ...[
          AppTheme.sectionHeader('Reports & Financials'),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              children: [
                _NavTile(
                  icon: Icons.shopping_bag_outlined,
                  iconColor: AppTheme.primary,
                  title: 'Apartment Cost Report',
                  onTap: () => context.push('/apartment-costs'),
                ),
                const Divider(height: 1, indent: 56, color: AppTheme.border),
                _NavTile(
                  icon: Icons.business_outlined,
                  iconColor: AppTheme.info,
                  title: 'Financial Building Report',
                  onTap: () => context.push('/financial-buildings-report'),
                ),
                const Divider(height: 1, indent: 56, color: AppTheme.border),
                _NavTile(
                  icon: Icons.bar_chart_rounded,
                  iconColor: AppTheme.success,
                  title: 'Financial Reports',
                  onTap: () => context.push('/financial-reports'),
                ),
                const Divider(height: 1, indent: 56, color: AppTheme.border),
                _NavTile(
                  icon: Icons.verified_user_outlined,
                  iconColor: AppTheme.warning,
                  title: 'Insurance Hub',
                  onTap: () => context.push('/insurance-hub'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],

        // ── System Information ───────────────────────────────────────────────
        AppTheme.sectionHeader('System Information'),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            children: [
              _SettingsTile(
                icon: Icons.dns_outlined,
                label: 'API Endpoint',
                value: AppConfig.apiBaseUrl,
                color: AppTheme.primary,
              ),
              const Divider(height: 1, indent: 56, color: AppTheme.border),
              const _SettingsTile(
                icon: Icons.info_outline_rounded,
                label: 'Application Version',
                value: '1.0.0 (Enterprise Build)',
                color: AppTheme.info,
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // ── Sign Out Button ──────────────────────────────────────────────────
        SizedBox(
          height: 48,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.danger.withValues(alpha: 0.12),
              foregroundColor: AppTheme.danger,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: AppTheme.danger.withValues(alpha: 0.35)),
              ),
            ),
            icon: const Icon(Icons.logout_rounded, size: 18),
            label: Text(
              'Sign Out',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            onPressed: () => _confirmLogout(context, ref),
          ),
        ),
      ],
    );
  }

  Widget _buildIcon(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Icon(icon, color: color, size: 19),
    );
  }
}

class _NavTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final VoidCallback onTap;

  const _NavTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(icon, color: iconColor, size: 19),
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(
          color: AppTheme.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 13.5,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        size: 18,
        color: AppTheme.textMuted,
      ),
      onTap: onTap,
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(icon, color: color, size: 19),
      ),
      title: Text(
        label,
        style: GoogleFonts.inter(
          color: AppTheme.textMuted,
          fontSize: 11.5,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        value,
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          color: AppTheme.textPrimary,
          fontSize: 13,
        ),
      ),
    );
  }
}
