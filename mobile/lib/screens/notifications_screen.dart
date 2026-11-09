import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_theme.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';
import '../providers/app_providers.dart';
import '../widgets/mobile/enterprise_mobile_scaffold.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  String _selectedCategory = 'All';
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshNotifications();
    });
  }

  Future<void> _refreshNotifications() async {
    if (!mounted) return;
    setState(() => _isRefreshing = true);
    await ref.read(notificationsProvider.notifier).loadFromApi();
    if (mounted) {
      setState(() => _isRefreshing = false);
    }
  }

  final List<String> _categories = const [
    'All',
    'Tenant Requests',
    'Maintenance',
    'Contracts',
    'Electricity',
    'Tasks',
    'Approvals',
    'Rejections',
    'Generator',
    'System',
  ];

  String _cleanTitle(String raw) {
    return raw
        .replaceAll(
          RegExp(
            r'^[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}\u{FE00}-\u{FE0F}\s]+',
            unicode: true,
          ),
          '',
        )
        .trim();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final role = User.normalizeRole(user?.role);
    final allNotifications = ref.watch(notificationsProvider);
    final notifier = ref.read(notificationsProvider.notifier);

    final filtered = _selectedCategory == 'All'
        ? allNotifications
        : allNotifications.where((n) => n.category == _selectedCategory).toList();

    final unreadCount = allNotifications.where((n) => !n.isRead).length;

    return EnterpriseMobileScaffold(
      title: 'Notification Center',
      userRole: user?.role ?? 'User',
      userName: user?.name ?? 'User',
      unreadNotifications: unreadCount,
      currentTabIndex: 3,
      onTabSelected: (index) {
        if (role == 'maintenance') {
          if (index == 0 || index == 1 || index == 2) context.go('/maintenance-dashboard');
          if (index == 4) context.go('/settings');
        } else if (role == 'admin' || role == 'manager') {
          if (index == 0) context.go(role == 'manager' ? '/manager-dashboard' : '/');
          if (index == 1) context.go('/ac-maintenance');
          if (index == 2) context.go('/agent-purchase-review');
          if (index == 4) context.go('/settings');
        } else {
          if (index == 0) context.go('/agent-dashboard');
          if (index == 1) context.go('/agent-subscriptions');
          if (index == 2) context.go('/agent-history');
          if (index == 4) context.go('/settings');
        }
      },
      body: Column(
        children: [
          // ── Header Action Row ──────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AppTheme.surface,
              border: Border(bottom: BorderSide(color: AppTheme.border)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Operational Alerts ($unreadCount unread)',
                        style: GoogleFonts.outfit(
                          color: AppTheme.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        'Tasks, submissions, and system updates',
                        style: GoogleFonts.inter(
                          color: AppTheme.textMuted,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Refresh',
                      onPressed: _isRefreshing ? null : _refreshNotifications,
                      icon: _isRefreshing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.primary,
                              ),
                            )
                          : const Icon(Icons.refresh_rounded, size: 18, color: AppTheme.primary),
                    ),
                    TextButton.icon(
                      onPressed: () => notifier.markAllAsRead(),
                      icon: const Icon(Icons.done_all_rounded, size: 15, color: AppTheme.primary),
                      label: Text(
                        'Read All',
                        style: GoogleFonts.inter(
                          color: AppTheme.primary,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => notifier.clearOld(),
                      icon: const Icon(
                        Icons.delete_sweep_outlined,
                        size: 15,
                        color: AppTheme.textSecondary,
                      ),
                      label: Text(
                        'Clear',
                        style: GoogleFonts.inter(
                          color: AppTheme.textSecondary,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Category Filter Chips ──────────────────────────────────────────
          SizedBox(
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = _selectedCategory == cat;
                final countInCat = cat == 'All'
                    ? allNotifications.length
                    : allNotifications.where((n) => n.category == cat).length;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => setState(() => _selectedCategory = cat),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                      alignment: Alignment.center,
                      child: Text(
                        countInCat > 0 ? '$cat ($countInCat)' : cat,
                        style: GoogleFonts.inter(
                          color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
                          fontSize: 11.5,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // ── Notification Feed ──────────────────────────────────────────────
          Expanded(
            child: _isRefreshing && allNotifications.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primary,
                      strokeWidth: 2.5,
                    ),
                  )
                : filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppTheme.surface,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppTheme.border),
                              ),
                              child: const Icon(
                                Icons.notifications_none_rounded,
                                size: 32,
                                color: AppTheme.textMuted,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No notifications in $_selectedCategory',
                              style: GoogleFonts.outfit(
                                color: AppTheme.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextButton.icon(
                              onPressed: _refreshNotifications,
                              icon: const Icon(Icons.refresh_rounded, size: 15, color: AppTheme.primary),
                              label: Text(
                                'Refresh Feed',
                                style: GoogleFonts.inter(
                                  color: AppTheme.primary,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        color: AppTheme.primary,
                        backgroundColor: AppTheme.surface,
                        onRefresh: _refreshNotifications,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final notif = filtered[index];
                            final catColor = _getCategoryColor(notif.category);
                            final cleanTitle = _cleanTitle(notif.title);

                            return GestureDetector(
                              onTap: () {
                                if (notif.route != null && notif.route!.isNotEmpty) {
                                  context.go(notif.route!);
                                }
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: AppTheme.surface,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: notif.isRead
                                        ? AppTheme.border
                                        : catColor.withValues(alpha: 0.4),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 38,
                                      height: 38,
                                      decoration: BoxDecoration(
                                        color: catColor.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      alignment: Alignment.center,
                                      child: Icon(
                                        _getCategoryIcon(notif.category),
                                        size: 18,
                                        color: catColor,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  cleanTitle.isEmpty ? notif.title : cleanTitle,
                                                  style: GoogleFonts.outfit(
                                                    color: AppTheme.textPrimary,
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 7,
                                                  vertical: 2.5,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: catColor.withValues(alpha: 0.12),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  notif.category,
                                                  style: GoogleFonts.inter(
                                                    color: catColor,
                                                    fontSize: 9.5,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: AppTheme.background,
                                              borderRadius: BorderRadius.circular(10),
                                              border: Border.all(color: AppTheme.border),
                                            ),
                                            child: Text(
                                              notif.message,
                                              style: GoogleFonts.inter(
                                                color: AppTheme.textSecondary,
                                                fontSize: 12.5,
                                                height: 1.4,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                _formatTimestamp(notif.createdAt),
                                                style: GoogleFonts.inter(
                                                  color: AppTheme.textMuted,
                                                  fontSize: 10.5,
                                                ),
                                              ),
                                              if (notif.route != null && notif.route!.isNotEmpty)
                                                Row(
                                                  children: [
                                                    Text(
                                                      'Open',
                                                      style: GoogleFonts.inter(
                                                        color: catColor,
                                                        fontSize: 11.5,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 3),
                                                    Icon(
                                                      Icons.chevron_right_rounded,
                                                      size: 15,
                                                      color: catColor,
                                                    ),
                                                  ],
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (!notif.isRead)
                                      IconButton(
                                        tooltip: 'Mark as read',
                                        icon: const Icon(
                                          Icons.check_circle_outline_rounded,
                                          color: AppTheme.primary,
                                          size: 19,
                                        ),
                                        onPressed: () => notifier.markAsRead(notif.id),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime dt) {
    final local = dt.toLocal();
    final datePart =
        '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
    final timePart =
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    return '$datePart • $timePart';
  }

  Color _getCategoryColor(String cat) {
    switch (cat) {
      case 'Approvals':
        return AppTheme.success;
      case 'Rejections':
        return AppTheme.danger;
      case 'Tasks':
        return AppTheme.primary;
      case 'Tenant Requests':
        return AppTheme.accent;
      case 'Contracts':
        return AppTheme.info;
      case 'Electricity':
        return AppTheme.warning;
      case 'Generator':
        return AppTheme.accent;
      case 'Maintenance':
        return AppTheme.info;
      default:
        return AppTheme.primary;
    }
  }

  IconData _getCategoryIcon(String cat) {
    switch (cat) {
      case 'Approvals':
        return Icons.check_circle_outline_rounded;
      case 'Rejections':
        return Icons.cancel_outlined;
      case 'Tasks':
        return Icons.assignment_turned_in_outlined;
      case 'Tenant Requests':
        return Icons.home_repair_service_outlined;
      case 'Contracts':
        return Icons.payments_outlined;
      case 'Electricity':
        return Icons.electric_bolt_rounded;
      case 'Generator':
        return Icons.power_outlined;
      case 'Maintenance':
        return Icons.build_circle_outlined;
      default:
        return Icons.notifications_none_rounded;
    }
  }
}
