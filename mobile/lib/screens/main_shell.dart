// ─── Main Shell (Luxury Obsidian & Royal Teal/Gold Navigation Shell) ─────────
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/currency_provider.dart';
import '../services/api_service.dart';
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
  List<SmartNavItem> _getNavItems(String? role) {
    switch (role) {
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
    switch (role) {
      case 'agent':
        return const [
          SmartNavItem(icon: Icons.attach_money_outlined, activeIcon: Icons.attach_money_rounded, label: 'Rent Collection', path: '/agent-rent-collection'),
          SmartNavItem(icon: Icons.receipt_long_outlined, activeIcon: Icons.receipt_long_rounded, label: 'Collection History', path: '/agent-collection-history'),
          SmartNavItem(icon: Icons.history_edu_outlined, activeIcon: Icons.history_edu_rounded, label: 'Reading History', path: '/agent-history'),
          SmartNavItem(icon: Icons.task_alt_outlined, activeIcon: Icons.task_alt_rounded, label: 'Daily Report', path: '/agent-daily-report'),
          SmartNavItem(icon: Icons.shopping_cart_outlined, activeIcon: Icons.shopping_cart_rounded, label: 'Apartment Cost', path: '/apartment-costs'),
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
          SmartNavItem(icon: Icons.people_outline, activeIcon: Icons.people_rounded, label: 'Tenants', path: '/tenants'),
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

    // Calculate current tab index for SmartBottomNav
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
      extendBody: !isDesktop,
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
      floatingActionButton: role == 'admin'
          ? Padding(
              padding: EdgeInsets.only(bottom: isDesktop ? 0 : 4),
              child: Container(
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.4),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: FloatingActionButton.extended(
                  onPressed: () => context.push('/admin-chat'),
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  highlightElevation: 0,
                  icon: const Icon(Icons.psychology_rounded, color: Color(0xFF04130F), size: 22),
                  label: Text(
                    'Agency AI',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF04130F),
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
            )
          : null,
      body: AmbientLuxuryBackground(
        child: SafeArea(
          top: false,
          bottom: false,
          child: Row(
            children: [
              if (isDesktop) _buildSidebar(location, role),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: isDesktop ? 0 : 88),
                  child: ClipRRect(
                    borderRadius: isDesktop
                        ? const BorderRadius.only(
                            topLeft: Radius.circular(28),
                            bottomLeft: Radius.circular(28),
                          )
                        : BorderRadius.zero,
                    child: widget.navigationShell ?? widget.child ?? const SizedBox.shrink(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildMobileAppBar(String location, String? role) {
    final user = ref.watch(authProvider).user;
    final initial = (user?.name.isNotEmpty == true ? user!.name : 'S')[0].toUpperCase();

    return PreferredSize(
      preferredSize: const Size.fromHeight(64),
      child: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xEE081018),
                    Color(0xD90B1520),
                  ],
                ),
                border: Border(
                  bottom: BorderSide(
                    color: AppTheme.border.withValues(alpha: 0.7),
                    width: 1,
                  ),
                ),
              ),
            ),
          ),
        ),
        leadingWidth: 58,
        leading: Padding(
          padding: const EdgeInsets.only(left: 14, top: 10, bottom: 10, right: 6),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppTheme.primary, AppTheme.accent],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.35),
                  blurRadius: 10,
                ),
              ],
            ),
            padding: const EdgeInsets.all(1.8),
            child: Container(
              decoration: const BoxDecoration(
                color: AppTheme.surface,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                initial,
                style: GoogleFonts.outfit(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
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
                fontSize: 18,
                letterSpacing: -0.3,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Row(
              children: [
                Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    color: AppTheme.accent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  'SOCIMCO • ${(role ?? 'ADMIN').toUpperCase()}',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.accent,
                    fontWeight: FontWeight.w700,
                    fontSize: 9.5,
                    letterSpacing: 0.9,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Luxury Gold/Teal Currency Pill
          GestureDetector(
            onTap: () => ref.read(currencyProvider.notifier).toggleCurrency(),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 13),
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.accent.withValues(alpha: 0.18),
                    AppTheme.primary.withValues(alpha: 0.12),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.accent.withValues(alpha: 0.45),
                  width: 1,
                ),
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.currency_exchange_rounded, size: 12, color: AppTheme.accent),
                  const SizedBox(width: 4),
                  Text(
                    ref.watch(currencyProvider).currency,
                    style: GoogleFonts.outfit(
                      color: AppTheme.accent,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),
          _buildTopActionButton(
            icon: Icons.search_rounded,
            color: AppTheme.textPrimary,
            onTap: () => context.push('/global-search'),
          ),
          const SizedBox(width: 6),
          _buildTopActionButton(
            icon: Icons.notifications_none_rounded,
            color: AppTheme.textPrimary,
            onTap: () => _showNotifications(context),
          ),
          const SizedBox(width: 6),
          _buildTopActionButton(
            icon: Icons.power_settings_new_rounded,
            color: AppTheme.danger,
            borderColor: AppTheme.danger.withValues(alpha: 0.35),
            bgColor: AppTheme.danger.withValues(alpha: 0.1),
            onTap: () => ref.read(authProvider.notifier).logout(),
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
    Color? borderColor,
    Color? bgColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        margin: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: bgColor ?? AppTheme.surfaceHover.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
            color: borderColor ?? AppTheme.border,
            width: 1,
          ),
        ),
        alignment: Alignment.center,
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }

  void _showNotifications(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              height: MediaQuery.of(context).size.height * 0.72,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xF5101D2A),
                    Color(0xFA060B10),
                  ],
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                border: Border.all(
                  color: AppTheme.primary.withValues(alpha: 0.25),
                  width: 1.2,
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.borderLight,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 18, 18, 14),
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
                                border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                              ),
                              child: const Icon(Icons.notifications_active_rounded, color: AppTheme.primary, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Notifications',
                                  style: GoogleFonts.outfit(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                Text(
                                  'Real-time system alerts & updates',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11.5,
                                    color: AppTheme.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: AppTheme.textSecondary),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: AppTheme.border, height: 1),
                  Expanded(
                    child: FutureBuilder<dynamic>(
                      future: ApiService().get('/notifications/unread').then((res) => res.data),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
                        }
                        final notifications = (snapshot.data is List) ? (snapshot.data as List<dynamic>) : <dynamic>[];
                        if (snapshot.hasError || notifications.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: AppTheme.surfaceHover,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppTheme.border),
                                  ),
                                  child: const Icon(
                                    Icons.notifications_off_outlined,
                                    size: 36,
                                    color: AppTheme.textMuted,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  'All caught up!',
                                  style: GoogleFonts.outfit(
                                    color: AppTheme.textPrimary,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'No unread notifications at the moment.',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: AppTheme.textMuted,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return ListView.separated(
                          padding: const EdgeInsets.all(18),
                          itemCount: notifications.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final notif = notifications[index] as Map<String, dynamic>;
                            return InkWell(
                              borderRadius: BorderRadius.circular(18),
                              onTap: () async {
                                try {
                                  await ApiService().post('/notifications/${notif['id']}/read');
                                  if (context.mounted) {
                                    Navigator.pop(context);
                                    _showNotifications(context);
                                  }
                                } catch (_) {}
                              },
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: AppTheme.glassCardDecoration(borderRadius: 18),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primary.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(Icons.bolt_rounded, color: AppTheme.primary, size: 20),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            notif['title'] ?? 'System Alert',
                                            style: GoogleFonts.outfit(
                                              color: AppTheme.textPrimary,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 14.5,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            notif['message'] ?? '',
                                            style: GoogleFonts.plusJakartaSans(
                                              color: AppTheme.textSecondary,
                                              fontSize: 12.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      width: 8,
                                      height: 8,
                                      margin: const EdgeInsets.only(top: 4),
                                      decoration: const BoxDecoration(
                                        color: AppTheme.accent,
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
            ),
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
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 30),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xF5111F2E),
                    Color(0xFA060B10),
                  ],
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                border: Border.all(
                  color: AppTheme.accent.withValues(alpha: 0.3),
                  width: 1.2,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.accent.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: AppTheme.accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.accent.withValues(alpha: 0.35)),
                        ),
                        child: const Icon(Icons.widgets_rounded, color: AppTheme.accent, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Enterprise Modules',
                              style: GoogleFonts.outfit(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            Text(
                              'Quick access to all workspace tools',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 0.98,
                    ),
                    itemCount: overflowItems.length,
                    itemBuilder: (context, index) {
                      final item = overflowItems[index];
                      final isGoldAccent = index % 2 == 1;
                      final accentColor = isGoldAccent ? AppTheme.accent : AppTheme.primary;

                      return InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () {
                          Navigator.pop(context);
                          context.go(item.path);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                const Color(0xFF12202F),
                                const Color(0xFF0B141E),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: accentColor.withValues(alpha: 0.28),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(11),
                                decoration: BoxDecoration(
                                  color: accentColor.withValues(alpha: 0.14),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: accentColor.withValues(alpha: 0.35),
                                    width: 1,
                                  ),
                                ),
                                child: Icon(
                                  item.activeIcon,
                                  color: accentColor,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(height: 9),
                              Text(
                                item.label,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary,
                                  height: 1.15,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSidebar(String location, String? role) {
    return Container(
      width: 268,
      decoration: const BoxDecoration(
        color: Color(0xCC081018),
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
        // Brand Header
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.accent]),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: const Icon(Icons.apartment_rounded, color: Color(0xFF04130F), size: 24),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SOCIMCO',
                    style: GoogleFonts.outfit(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                      letterSpacing: 0.8,
                    ),
                  ),
                  Text(
                    'LUXURY PMS SUITE',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.accent,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Navigation Items
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 10),
                child: Text(
                  'WORKSPACE MODULES',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textMuted,
                    letterSpacing: 1.4,
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

        // User Footer
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(14),
          decoration: AppTheme.glassCardDecoration(borderRadius: 18),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  (user?.name.isNotEmpty == true ? user!.name : 'U')[0].toUpperCase(),
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF04130F),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.name ?? 'User',
                      style: GoogleFonts.outfit(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      (user?.role ?? 'Role').toUpperCase(),
                      style: GoogleFonts.plusJakartaSans(
                        color: AppTheme.accent,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.logout_rounded, color: AppTheme.danger, size: 20),
                onPressed: () => ref.read(authProvider.notifier).logout(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSidebarNavItem(SmartNavItem item, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => context.go(item.path),
          hoverColor: AppTheme.surfaceHover,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: isSelected
                  ? LinearGradient(
                      colors: [
                        AppTheme.primary.withValues(alpha: 0.2),
                        AppTheme.primary.withValues(alpha: 0.05),
                      ],
                    )
                  : null,
              border: Border.all(
                color: isSelected
                    ? AppTheme.primary.withValues(alpha: 0.45)
                    : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isSelected ? item.activeIcon : item.icon,
                  size: 20,
                  color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    item.label,
                    style: GoogleFonts.plusJakartaSans(
                      color: isSelected ? AppTheme.textPrimary : AppTheme.textSecondary,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 13.5,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppTheme.primary,
                      shape: BoxShape.circle,
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
