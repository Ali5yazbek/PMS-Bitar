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
    final canPop = Navigator.of(context).canPop();
    final isEmbeddedInMainShell = !canPop && !widget.showBottomNav && widget.floatingActionButton == null;

    // When embedded inside MainShell, MainShell already renders the top AppBar with the
    // authenticated user's identity, role, currency toggle, search, notifications, and logout.
    // Do NOT render a duplicate second user bar underneath it. Only show a compact sync strip
    // if the device is currently offline or uploading queued items.
    if (isEmbeddedInMainShell) {
      if (_currentSyncStatus.state == SyncStatusState.synchronized) {
        return widget.body;
      }
      return Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: const BoxDecoration(
              color: AppTheme.surface,
              border: Border(bottom: BorderSide(color: AppTheme.border)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _currentSyncStatus.state == SyncStatusState.offline
                      ? 'Working Offline • Changes queued locally'
                      : 'Synchronizing pending field packets...',
                  style: GoogleFonts.inter(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SyncStatusIndicator(status: _currentSyncStatus),
              ],
            ),
          ),
          Expanded(child: widget.body),
        ],
      );
    }

    // Standalone pushed screen (canPop == true): show a clean navigation header with back button and title.
    final content = Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: const BoxDecoration(
            color: AppTheme.surface,
            border: Border(
              bottom: BorderSide(color: AppTheme.border, width: 1),
            ),
          ),
          child: Row(
            children: [
              if (canPop) ...[
                InkWell(
                  onTap: () => Navigator.of(context).maybePop(),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceHover,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 15,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.title,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (widget.activeBuilding != null && widget.activeBuilding!.isNotEmpty)
                      Text(
                        widget.activeBuilding!,
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SyncStatusIndicator(status: _currentSyncStatus),
            ],
          ),
        ),
        Expanded(child: widget.body),
      ],
    );

    return Scaffold(
      backgroundColor: AppTheme.background,
      floatingActionButton: widget.floatingActionButton,
      body: SafeArea(
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
