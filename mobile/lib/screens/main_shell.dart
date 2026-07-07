// ─── Main Shell (Navigation) ────────────────────────────────────────────────
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_theme.dart';
import '../providers/auth_provider.dart';

class MainShell extends ConsumerStatefulWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  static const _navItems = [
    _NavItem(icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard_rounded, label: 'Dashboard', path: '/'),
    _NavItem(icon: Icons.calendar_month_outlined, activeIcon: Icons.calendar_month, label: 'Schedule', path: '/schedule'),
    _NavItem(icon: Icons.apartment_outlined, activeIcon: Icons.apartment_rounded, label: 'Buildings', path: '/buildings'),
    _NavItem(icon: Icons.build_circle_outlined, activeIcon: Icons.build_circle_rounded, label: 'Workshop', path: '/workshop'),
    _NavItem(icon: Icons.storefront_outlined, activeIcon: Icons.storefront_rounded, label: 'Commerce', path: '/warehouse'),
    _NavItem(icon: Icons.people_outline, activeIcon: Icons.people_rounded, label: 'Users', path: '/users'),
    _NavItem(icon: Icons.ac_unit_outlined, activeIcon: Icons.ac_unit_rounded, label: 'AC Maintenance', path: '/ac-maintenance'),
    _NavItem(icon: Icons.bolt_outlined, activeIcon: Icons.bolt_rounded, label: 'Energy', path: '/energy'),
    _NavItem(icon: Icons.local_gas_station_outlined, activeIcon: Icons.local_gas_station_rounded, label: 'Fuel Reserve', path: '/fuel'),
    _NavItem(icon: Icons.receipt_long_outlined, activeIcon: Icons.receipt_long_rounded, label: 'Expenses', path: '/expenses'),
    _NavItem(icon: Icons.bar_chart_outlined, activeIcon: Icons.bar_chart_rounded, label: 'Reports', path: '/reports'),
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppTheme.background,
      appBar: isDesktop ? null : _buildMobileAppBar(location),
      drawer: isDesktop ? null : _buildDrawer(location),
      body: Row(
        children: [
          if (isDesktop) _buildSidebar(location),
          Expanded(
            child: ClipRRect(
              borderRadius: isDesktop ? const BorderRadius.only(topLeft: Radius.circular(24), bottomLeft: Radius.circular(24)) : BorderRadius.zero,
              child: Container(
                color: AppTheme.background,
                child: widget.child,
              ),
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildMobileAppBar(String location) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(color: AppTheme.background.withOpacity(0.5)),
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.menu_rounded),
        onPressed: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      title: Text(_titleForPath(location)),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () {},
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildDrawer(String location) {
    return Drawer(
      backgroundColor: AppTheme.surface,
      child: SafeArea(
        child: _buildNavContent(location, isMobile: true),
      ),
    );
  }

  Widget _buildSidebar(String location) {
    return Container(
      width: 260,
      color: AppTheme.background,
      child: _buildNavContent(location, isMobile: false),
    );
  }

  Widget _buildNavContent(String location, {required bool isMobile}) {
    final user = ref.watch(authProvider).user;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Brand Header
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.accent]),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: AppTheme.primary.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))
                  ],
                ),
                child: const Icon(Icons.apartment_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Text(
                'PMS System',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),

        // Navigation Items
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              Text('MODULES', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textSecondary, letterSpacing: 1.2)),
              const SizedBox(height: 12),
              ..._navItems.map((item) {
                final isSelected = location == item.path || (item.path != '/' && location.startsWith(item.path));
                return _buildNavItem(item, isSelected, isMobile);
              }),
            ],
          ),
        ),

        // User Footer
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceHover,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppTheme.primary,
                child: Text((user?.name ?? 'U')[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user?.name ?? 'Admin', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    Text(user?.role ?? 'Administrator', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.logout_rounded, color: AppTheme.textSecondary, size: 20),
                onPressed: () => ref.read(authProvider.notifier).logout(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNavItem(_NavItem item, bool isSelected, bool isMobile) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            context.go(item.path);
            if (isMobile) Navigator.pop(context); // Close drawer
          },
          hoverColor: AppTheme.surfaceHover,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: isSelected ? AppTheme.primary.withOpacity(0.15) : Colors.transparent,
              border: Border.all(
                color: isSelected ? AppTheme.primary.withOpacity(0.3) : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isSelected ? item.activeIcon : item.icon,
                  size: 20,
                  color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
                ),
                const SizedBox(width: 16),
                Text(
                  item.label,
                  style: GoogleFonts.inter(
                    color: isSelected ? Colors.white : AppTheme.textSecondary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _titleForPath(String path) {
    final item = _navItems.firstWhere(
      (n) => n.path == path || (n.path != '/' && path.startsWith(n.path)),
      orElse: () => _navItems.first,
    );
    return item.label;
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String path;
  const _NavItem({required this.icon, required this.activeIcon, required this.label, required this.path});
}
