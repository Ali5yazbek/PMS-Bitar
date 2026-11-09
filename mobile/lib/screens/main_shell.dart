// ─── Main Shell (Enterprise Navigation & Workspace Shell) ────────────────────
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_theme.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';
import '../providers/currency_provider.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../services/update_service.dart';
import '../widgets/common/smart_bottom_nav.dart';

class MainShell extends ConsumerStatefulWidget {
  final StatefulNavigationShell? navigationShell;
  final Widget? child;

  const MainShell({
    super.key,
    this.navigationShell,
    this.child,
  });

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final role = ref.read(authProvider).user?.role;
      ApiService().prefetchForRole(role);
      UpdateService.checkForUpdates(context);
    });
  }

  List<SmartNavItem> _getNavItems(String? role) {
    final cleanRole = User.normalizeRole(role);
    switch (cleanRole) {
      case 'manager':
        return const [
          SmartNavItem(icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard_rounded, label: 'Dashboard', path: '/manager-dashboard'),
          SmartNavItem(icon: Icons.apartment_outlined, activeIcon: Icons.apartment_rounded, label: 'Buildings', path: '/buildings'),
          SmartNavItem(icon: Icons.description_outlined, activeIcon: Icons.description_rounded, label: 'Contracts', path: '/contracts'),
          SmartNavItem(icon: Icons.attach_money_outlined, activeIcon: Icons.attach_money_rounded, label: 'Finance', path: '/financial-reports'),
          SmartNavItem(icon: Icons.grid_view_rounded, activeIcon: Icons.grid_view_rounded, label: 'More', path: ''),
        ];
      case 'agent':
        return const [
          SmartNavItem(icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard_rounded, label: 'Dashboard', path: '/agent-dashboard'),
          SmartNavItem(icon: Icons.electric_bolt_outlined, activeIcon: Icons.electric_bolt_rounded, label: 'Tasks', path: '/agent-subscriptions'),
          SmartNavItem(icon: Icons.power_outlined, activeIcon: Icons.power_rounded, label: 'Generators', path: '/agent-generators'),
          SmartNavItem(icon: Icons.home_work_outlined, activeIcon: Icons.home_work_rounded, label: 'Readings', path: '/agent-apartments'),
          SmartNavItem(icon: Icons.grid_view_rounded, activeIcon: Icons.grid_view_rounded, label: 'More', path: ''),
        ];
      case 'tenant':
        return const [
          SmartNavItem(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Home', path: '/tenant-dashboard'),
          SmartNavItem(icon: Icons.payment_outlined, activeIcon: Icons.payment_rounded, label: 'Payments', path: '/tenant-payments'),
          SmartNavItem(icon: Icons.description_outlined, activeIcon: Icons.description_rounded, label: 'Contract', path: '/tenant-contract'),
          SmartNavItem(icon: Icons.flash_on_outlined, activeIcon: Icons.flash_on_rounded, label: 'Power', path: '/tenant-subscriptions'),
        ];
      case 'cashier':
        return const [
          SmartNavItem(icon: Icons.point_of_sale_outlined, activeIcon: Icons.point_of_sale_rounded, label: 'POS', path: '/pos'),
          SmartNavItem(icon: Icons.receipt_long_outlined, activeIcon: Icons.receipt_long_rounded, label: 'Sales', path: '/cashier-dashboard'),
          SmartNavItem(icon: Icons.payment_outlined, activeIcon: Icons.payment_rounded, label: 'Payments', path: '/rent'),
          SmartNavItem(icon: Icons.settings_outlined, activeIcon: Icons.settings_rounded, label: 'Settings', path: '/settings'),
        ];
      case 'maintenance':
        return const [
          SmartNavItem(icon: Icons.engineering_outlined, activeIcon: Icons.engineering_rounded, label: 'Tasks', path: '/maintenance-dashboard'),
          SmartNavItem(icon: Icons.history_outlined, activeIcon: Icons.history_rounded, label: 'History', path: '/maintenance-history'),
        ];
      default:
        // Admin
        return const [
          SmartNavItem(icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard_rounded, label: 'Dashboard', path: '/'),
          SmartNavItem(icon: Icons.engineering_outlined, activeIcon: Icons.engineering_rounded, label: 'AC Maint.', path: '/ac-maintenance'),
          SmartNavItem(icon: Icons.fact_check_outlined, activeIcon: Icons.fact_check_rounded, label: 'Verification', path: '/energy/verification'),
          SmartNavItem(icon: Icons.shopping_cart_outlined, activeIcon: Icons.shopping_cart_rounded, label: 'Review', path: '/agent-purchase-review'),
          SmartNavItem(icon: Icons.grid_view_rounded, activeIcon: Icons.grid_view_rounded, label: 'More', path: ''),
        ];
    }
  }

  List<SmartNavItem> _getOverflowItems(String? role) {
    final cleanRole = User.normalizeRole(role);
    switch (cleanRole) {
      case 'maintenance':
      case 'tenant':
      case 'cashier':
        return const [];
      case 'agent':
        return const [
          SmartNavItem(icon: Icons.payments_outlined, activeIcon: Icons.payments_rounded, label: 'Rent Collection', path: '/agent-rent-collection'),
          SmartNavItem(icon: Icons.receipt_long_outlined, activeIcon: Icons.receipt_long_rounded, label: 'Collection History', path: '/agent-collection-history'),
          SmartNavItem(icon: Icons.history_edu_outlined, activeIcon: Icons.history_edu_rounded, label: 'Reading History', path: '/agent-history'),
          SmartNavItem(icon: Icons.task_alt_outlined, activeIcon: Icons.task_alt_rounded, label: 'Daily Report', path: '/agent-daily-report'),
          SmartNavItem(icon: Icons.shopping_bag_outlined, activeIcon: Icons.shopping_bag_rounded, label: 'Apartment Cost', path: '/apartment-costs'),
        ];
      case 'manager':
        return const [
          SmartNavItem(icon: Icons.engineering_outlined, activeIcon: Icons.engineering_rounded, label: 'AC Maintenance', path: '/ac-maintenance'),
          SmartNavItem(icon: Icons.electric_bolt_outlined, activeIcon: Icons.electric_bolt_rounded, label: 'Energy', path: '/energy'),
          SmartNavItem(icon: Icons.fact_check_outlined, activeIcon: Icons.fact_check_rounded, label: 'Readings Verification', path: '/energy/verification'),
          SmartNavItem(icon: Icons.assignment_outlined, activeIcon: Icons.assignment_rounded, label: 'Gen Report', path: '/gen-report'),
          SmartNavItem(icon: Icons.bar_chart_outlined, activeIcon: Icons.bar_chart_rounded, label: 'Reports', path: '/reports'),
          SmartNavItem(icon: Icons.home_repair_service_outlined, activeIcon: Icons.home_repair_service_rounded, label: 'Workshop', path: '/workshop'),
          SmartNavItem(icon: Icons.inventory_2_outlined, activeIcon: Icons.inventory_2_rounded, label: 'Warehouse', path: '/warehouse'),
          SmartNavItem(icon: Icons.settings_outlined, activeIcon: Icons.settings_rounded, label: 'Settings', path: '/settings'),
        ];
      default:
        // Admin overflow
        return const [
          SmartNavItem(icon: Icons.apartment_outlined, activeIcon: Icons.apartment_rounded, label: 'Buildings', path: '/buildings'),
          SmartNavItem(icon: Icons.people_outline_rounded, activeIcon: Icons.people_rounded, label: 'Tenants', path: '/tenants'),
          SmartNavItem(icon: Icons.description_outlined, activeIcon: Icons.description_rounded, label: 'Contracts', path: '/contracts'),
          SmartNavItem(icon: Icons.bar_chart_outlined, activeIcon: Icons.bar_chart_rounded, label: 'Reports', path: '/reports'),
          SmartNavItem(icon: Icons.settings_outlined, activeIcon: Icons.settings_rounded, label: 'Settings', path: '/settings'),
          SmartNavItem(icon: Icons.manage_accounts_outlined, activeIcon: Icons.manage_accounts_rounded, label: 'Users', path: '/user-management'),
          SmartNavItem(icon: Icons.engineering_outlined, activeIcon: Icons.engineering_rounded, label: 'Field Tech Tasks', path: '/maintenance-dashboard'),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final isDesktop = MediaQuery.of(context).size.width > 800;
    final role = ref.watch(authProvider).user?.role;
    final navItems = _getNavItems(role);

    int currentIndex = 0;
    final navItemIndex = navItems.indexWhere(
      (item) => item.path.isNotEmpty && (location == item.path || location.startsWith('${item.path}/')),
    );
    if (navItemIndex != -1) {
      currentIndex = navItemIndex;
    } else if (widget.navigationShell != null) {
      currentIndex = widget.navigationShell!.currentIndex;
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      extendBody: false,
      appBar: isDesktop ? null : _buildMobileAppBar(location, role),
      bottomNavigationBar: isDesktop
          ? null
          : SmartBottomNav(
              currentIndex: currentIndex,
              items: navItems,
              onTap: (index) {
                if (index < navItems.length) {
                  final target = navItems[index].path;
                  if (target.isNotEmpty) {
                    context.go(target);
                    return;
                  }
                }
                if (widget.navigationShell != null) {
                  widget.navigationShell!.goBranch(
                    index,
                    initialLocation: index == widget.navigationShell!.currentIndex,
                  );
                }
              },
              onMoreTap: () => _showMoreMenu(_getOverflowItems(role)),
            ),
      floatingActionButton: User.normalizeRole(role) == 'admin'
          ? Padding(
              padding: EdgeInsets.only(bottom: isDesktop ? 0 : 4),
              child: FloatingActionButton.extended(
                onPressed: () => context.push('/admin-chat'),
                backgroundColor: AppTheme.primary,
                foregroundColor: const Color(0xFF04130F),
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                label: Text(
                  'Agency AI',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF04130F),
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                    letterSpacing: 0.1,
                  ),
                ),
              ),
            )
          : null,
      body: SafeArea(
        top: false,
        bottom: false,
        child: Row(
          children: [
            if (isDesktop) _buildSidebar(location, role),
            Expanded(
              child: widget.navigationShell ?? widget.child ?? const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildMobileAppBar(String location, String? role) {
    final user = ref.watch(authProvider).user;
    final initial = (user?.name.isNotEmpty == true ? user!.name : 'S')[0].toUpperCase();

    return PreferredSize(
      preferredSize: const Size.fromHeight(60),
      child: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 0,
        shape: const Border(
          bottom: BorderSide(color: AppTheme.border, width: 1),
        ),
        leadingWidth: 56,
        leading: Padding(
          padding: const EdgeInsets.only(left: 14, top: 12, bottom: 12, right: 6),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => context.push('/settings'),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppTheme.primary.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                initial,
                style: GoogleFonts.outfit(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _titleForPath(location, role),
              style: GoogleFonts.outfit(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 17,
                letterSpacing: -0.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 1),
            Row(
              children: [
                Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    color: AppTheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    'SOCIMCO • ${User.normalizeRole(role).toUpperCase()}',
                    style: GoogleFonts.inter(
                      color: AppTheme.textMuted,
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                      letterSpacing: 0.6,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Currency Toggle Pill
          GestureDetector(
            onTap: () => ref.read(currencyProvider.notifier).toggleCurrency(),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 13),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppTheme.surfaceHover,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.borderLight, width: 1),
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.currency_exchange_rounded, size: 12, color: AppTheme.primary),
                  const SizedBox(width: 4),
                  Text(
                    ref.watch(currencyProvider).currency,
                    style: GoogleFonts.inter(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 11.5,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),
          _buildTopActionButton(
            icon: Icons.search_rounded,
            color: AppTheme.textSecondary,
            tooltip: 'Search',
            onTap: () => context.push('/global-search'),
          ),
          const SizedBox(width: 6),
          _buildTopActionButton(
            icon: Icons.notifications_none_rounded,
            color: AppTheme.textSecondary,
            tooltip: 'Notifications',
            onTap: () => _showNotifications(context),
          ),
          const SizedBox(width: 6),
          _buildTopActionButton(
            icon: Icons.logout_rounded,
            color: AppTheme.danger,
            borderColor: AppTheme.danger.withValues(alpha: 0.25),
            bgColor: AppTheme.danger.withValues(alpha: 0.08),
            tooltip: 'Sign Out',
            onTap: () => _confirmLogout(context),
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }

  Widget _buildTopActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    String? tooltip,
    Color? borderColor,
    Color? bgColor,
  }) {
    return Tooltip(
      message: tooltip ?? '',
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          width: 34,
          height: 34,
          margin: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            color: bgColor ?? AppTheme.surfaceHover,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: borderColor ?? AppTheme.border,
              width: 1,
            ),
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: color, size: 17),
        ),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppTheme.border),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.danger.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.logout_rounded, color: AppTheme.danger, size: 18),
            ),
            const SizedBox(width: 12),
            Text(
              'Sign Out',
              style: GoogleFonts.outfit(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to sign out of your SOCIMCO account on this device?',
          style: GoogleFonts.inter(
            color: AppTheme.textSecondary,
            fontSize: 13.5,
            height: 1.45,
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
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Sign Out',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(authProvider.notifier).logout();
    }
  }

  String _cleanNotificationTitle(String raw) {
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

  IconData _iconForNotifType(String? type) {
    switch ((type ?? '').toLowerCase()) {
      case 'energy':
      case 'power':
        return Icons.electric_bolt_rounded;
      case 'ac':
        return Icons.ac_unit_rounded;
      case 'maintenance':
        return Icons.build_circle_outlined;
      case 'purchase':
        return Icons.shopping_bag_outlined;
      case 'rent':
      case 'payment':
        return Icons.payments_outlined;
      case 'contract':
        return Icons.description_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _colorForNotifType(String? type) {
    switch ((type ?? '').toLowerCase()) {
      case 'energy':
      case 'power':
        return AppTheme.warning;
      case 'ac':
        return AppTheme.info;
      case 'maintenance':
        return AppTheme.accent;
      case 'purchase':
        return AppTheme.secondary;
      case 'rent':
      case 'payment':
        return AppTheme.success;
      default:
        return AppTheme.primary;
    }
  }

  void _showNotifications(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.74,
          decoration: const BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(color: AppTheme.borderLight, width: 1),
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.borderLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 14, 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppTheme.primary.withValues(alpha: 0.25)),
                          ),
                          child: const Icon(Icons.notifications_none_rounded, color: AppTheme.primary, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Notifications',
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            Text(
                              'System alerts and operational updates',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            context.push('/notifications');
                          },
                          child: Text(
                            'View All',
                            style: GoogleFonts.inter(
                              color: AppTheme.primary,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: AppTheme.textSecondary, size: 20),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(color: AppTheme.border, height: 1),
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: NotificationService().fetchComprehensiveRoleNotifications(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 2.5),
                      );
                    }
                    final notifications = snapshot.data ?? <Map<String, dynamic>>[];
                    if (snapshot.hasError || notifications.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceHover,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppTheme.border),
                              ),
                              child: const Icon(
                                Icons.notifications_none_rounded,
                                size: 32,
                                color: AppTheme.textMuted,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'All caught up',
                              style: GoogleFonts.outfit(
                                color: AppTheme.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'There are no unread notifications right now.',
                              style: GoogleFonts.inter(
                                color: AppTheme.textMuted,
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: notifications.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final notif = notifications[index];
                        final notifId = notif['id']?.toString() ?? '';
                        final route = notif['route']?.toString();
                        final type = notif['type']?.toString();
                        final badgeColor = _colorForNotifType(type);
                        final rawTitle = (notif['title'] ?? 'System Alert').toString();
                        final cleanTitle = _cleanNotificationTitle(rawTitle);

                        return InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () async {
                            try {
                              await NotificationService().markDismissed(notifId);
                              if (int.tryParse(notifId) != null) {
                                await ApiService().post('/notifications/$notifId/read');
                              }
                            } catch (_) {}
                            if (context.mounted) {
                              Navigator.pop(context);
                              if (route != null && route.isNotEmpty) {
                                context.go(route);
                              } else {
                                _showNotifications(context);
                              }
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceHover,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppTheme.border),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(9),
                                  decoration: BoxDecoration(
                                    color: badgeColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    _iconForNotifType(type),
                                    color: badgeColor,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        cleanTitle.isEmpty ? rawTitle : cleanTitle,
                                        style: GoogleFonts.outfit(
                                          color: AppTheme.textPrimary,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        notif['message'] ?? '',
                                        style: GoogleFonts.inter(
                                          color: AppTheme.textSecondary,
                                          fontSize: 12.5,
                                          height: 1.35,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  width: 7,
                                  height: 7,
                                  margin: const EdgeInsets.only(top: 5),
                                  decoration: BoxDecoration(
                                    color: badgeColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showMoreMenu(List<SmartNavItem> overflowItems) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: EdgeInsets.fromLTRB(
            20,
            10,
            20,
            MediaQuery.of(context).padding.bottom + 24,
          ),
          decoration: const BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(color: AppTheme.borderLight, width: 1),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.borderLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.primary.withValues(alpha: 0.25)),
                    ),
                    child: const Icon(Icons.grid_view_rounded, color: AppTheme.primary, size: 19),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Workspace Modules',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          'Direct access to management tools',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, color: AppTheme.textSecondary, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  mainAxisExtent: 62,
                ),
                itemCount: overflowItems.length,
                itemBuilder: (context, index) {
                  final item = overflowItems[index];
                  return InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () {
                      Navigator.pop(context);
                      context.go(item.path);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceHover,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.border, width: 1),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              item.activeIcon,
                              color: AppTheme.primary,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              item.label,
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                                height: 1.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            size: 16,
                            color: AppTheme.textMuted,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSidebar(String location, String? role) {
    return Container(
      width: 260,
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(
          right: BorderSide(color: AppTheme.border, width: 1),
        ),
      ),
      child: _buildNavContent(location, role: role),
    );
  }

  Widget _buildNavContent(String location, {required String? role}) {
    final user = ref.watch(authProvider).user;
    final allItems = [
      ..._getNavItems(role).where((i) => i.path.isNotEmpty),
      ..._getOverflowItems(role),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(22.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                ),
                child: const Icon(Icons.apartment_rounded, color: AppTheme.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SOCIMCO',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    'ENTERPRISE PMS',
                    style: GoogleFonts.inter(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textMuted,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const Divider(color: AppTheme.border, height: 1),
        const SizedBox(height: 12),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 10, bottom: 8),
                child: Text(
                  'MODULES',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textMuted,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              ...allItems.map((item) {
                final isSelected = location == item.path ||
                    (item.path != '/' && location.startsWith('${item.path}/'));
                return _buildSidebarNavItem(item, isSelected);
              }),
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.all(14),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.surfaceHover,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.border),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  (user?.name.isNotEmpty == true ? user!.name : 'U')[0].toUpperCase(),
                  style: GoogleFonts.outfit(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.name ?? 'User',
                      style: GoogleFonts.outfit(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      User.normalizeRole(user?.role).toUpperCase(),
                      style: GoogleFonts.inter(
                        color: AppTheme.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.logout_rounded, color: AppTheme.danger, size: 18),
                onPressed: () => _confirmLogout(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSidebarNavItem(SmartNavItem item, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => context.go(item.path),
          hoverColor: AppTheme.surfaceHover,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: isSelected
                  ? AppTheme.primary.withValues(alpha: 0.12)
                  : Colors.transparent,
              border: Border.all(
                color: isSelected
                    ? AppTheme.primary.withValues(alpha: 0.3)
                    : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isSelected ? item.activeIcon : item.icon,
                  size: 19,
                  color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.label,
                    style: GoogleFonts.inter(
                      color: isSelected ? AppTheme.textPrimary : AppTheme.textSecondary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _titleForPath(String path, String? role) {
    final allItems = [..._getNavItems(role), ..._getOverflowItems(role)];
    final item = allItems.firstWhere(
      (n) => n.path.isNotEmpty && (n.path == path || path.startsWith('${n.path}/')),
      orElse: () => allItems.first,
    );
    return item.label;
  }
}
