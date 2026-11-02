import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/app_theme.dart';
import '../../core/network/request_queue.dart';
import 'sync_status_indicator.dart';

class EnterpriseMobileScaffold extends StatefulWidget {
  final String title;
  final String userRole;
  final String userName;
  final String? activeBuilding;
  final Widget body;
  final int currentTabIndex;
  final ValueChanged<int>? onTabSelected;
  final VoidCallback? onNotificationTap;
  final int unreadNotifications;
  final Widget? floatingActionButton;
  final bool showBottomNav;

  const EnterpriseMobileScaffold({
    Key? key,
    required this.title,
    required this.userRole,
    required this.userName,
    this.activeBuilding,
    required this.body,
    this.currentTabIndex = 0,
    this.onTabSelected,
    this.onNotificationTap,
    this.unreadNotifications = 0,
    this.floatingActionButton,
    this.showBottomNav = false,
  }) : super(key: key);

  @override
  State<EnterpriseMobileScaffold> createState() => _EnterpriseMobileScaffoldState();
}

class _EnterpriseMobileScaffoldState extends State<EnterpriseMobileScaffold> {
  late StreamSubscription<SyncStatusInfo> _syncSub;
  SyncStatusInfo _currentSyncStatus = SyncStatusInfo(
    state: SyncStatusState.synchronized,
    pendingCount: 0,
    label: 'Synchronized',
  );

  @override
  void initState() {
    super.initState();
    _syncSub = RequestQueue.instance.statusStream.listen((info) {
      if (mounted) {
        setState(() {
          _currentSyncStatus = info;
        });
      }
    });
  }

  @override
  void dispose() {
    _syncSub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateStr = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
    final canPop = Navigator.of(context).canPop();

    final content = Column(
      children: [
        // Sleek Luxury Context Strip (replaces redundant second AppBar)
        Container(
          margin: const EdgeInsets.fromLTRB(16, 10, 16, 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xE6111E2C),
                Color(0xCC0A131C),
              ],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppTheme.border.withValues(alpha: 0.8),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              if (canPop) ...[
                InkWell(
                  onTap: () => Navigator.of(context).maybePop(),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceHover,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 14,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.3),
                      blurRadius: 10,
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  widget.userName.isNotEmpty ? widget.userName[0].toUpperCase() : 'U',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF04130F),
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            widget.userName,
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.accent.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppTheme.accent.withValues(alpha: 0.35),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            widget.userRole.toUpperCase(),
                            style: GoogleFonts.plusJakartaSans(
                              color: AppTheme.accent,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${widget.activeBuilding ?? 'All Properties'}  •  $dateStr',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.5,
                        color: AppTheme.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              SyncStatusIndicator(status: _currentSyncStatus),
            ],
          ),
        ),
        Expanded(child: widget.body),
      ],
    );

    return Scaffold(
      backgroundColor: canPop ? AppTheme.background : Colors.transparent,
      floatingActionButton: widget.floatingActionButton,
      body: canPop
          ? AmbientLuxuryBackground(
              child: SafeArea(
                bottom: !widget.showBottomNav,
                child: content,
              ),
            )
          : SafeArea(
              top: false,
              bottom: !widget.showBottomNav,
              child: content,
            ),
      bottomNavigationBar: widget.showBottomNav
          ? Container(
              decoration: const BoxDecoration(
                color: AppTheme.surface,
                border: Border(top: BorderSide(color: AppTheme.border, width: 1)),
              ),
              child: BottomNavigationBar(
                currentIndex: widget.currentTabIndex,
                onTap: widget.onTabSelected,
                backgroundColor: Colors.transparent,
                elevation: 0,
                type: BottomNavigationBarType.fixed,
                selectedItemColor: AppTheme.primary,
                unselectedItemColor: AppTheme.textMuted,
                selectedFontSize: 11,
                unselectedFontSize: 11,
                items: const [
                  BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), label: 'Dashboard'),
                  BottomNavigationBarItem(icon: Icon(Icons.task_alt_outlined), label: 'Tasks'),
                  BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
                  BottomNavigationBarItem(icon: Icon(Icons.notifications_outlined), label: 'Alerts'),
                  BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
                ],
              ),
            )
          : null,
    );
  }
}
