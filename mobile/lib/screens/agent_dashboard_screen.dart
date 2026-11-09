import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_theme.dart';
import '../providers/auth_provider.dart';
import '../services/agent_api.dart';
import '../core/network/request_queue.dart';
import '../widgets/mobile/enterprise_mobile_scaffold.dart';

final agentDashboardProvider = StreamProvider<Map<String, dynamic>>((ref) {
  return AgentApi.instance.getDashboardMetricsStream();
});

final agentSmartTasksStreamProvider = StreamProvider<List<dynamic>>((ref) {
  return AgentApi.instance.getSmartTasksStream();
});

class AgentDashboardScreen extends ConsumerStatefulWidget {
  const AgentDashboardScreen({super.key});

  @override
  ConsumerState<AgentDashboardScreen> createState() => _AgentDashboardScreenState();
}

class _AgentDashboardScreenState extends ConsumerState<AgentDashboardScreen> with WidgetsBindingObserver {
  late StreamSubscription<SyncStatusInfo> _syncSub;
  SyncStatusInfo _syncInfo = SyncStatusInfo(
    state: SyncStatusState.synchronized,
    pendingCount: 0,
    label: 'All data synchronized',
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _syncSub = RequestQueue.instance.statusStream.listen((info) async {
      if (mounted) {
        setState(() {
          _syncInfo = info;
        });
        if (info.state == SyncStatusState.synchronized) {
          ref.invalidate(agentDashboardProvider);
        }
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(agentDashboardProvider);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _syncSub.cancel();
    super.dispose();
  }

  String _cleanSyncLabel(String raw) {
    return raw.replaceAll('✓', '').trim();
  }

  @override
  Widget build(BuildContext context) {
    final metricsAsync = ref.watch(agentDashboardProvider);
    final userName = ref.watch(authProvider).user?.name ?? 'Field Agent';

    final Color syncColor = _syncInfo.state == SyncStatusState.offline
        ? AppTheme.danger
        : (_syncInfo.state == SyncStatusState.uploading ? AppTheme.warning : AppTheme.primary);

    return EnterpriseMobileScaffold(
      title: 'Agent Dashboard',
      userRole: 'Agent',
      userName: userName,
      currentTabIndex: 0,
      unreadNotifications: 0,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(agentDashboardProvider);
          ref.invalidate(agentSmartTasksStreamProvider);
        },
        color: AppTheme.primary,
        backgroundColor: AppTheme.surface,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Compact Welcome & Sync Status Card ──────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: syncColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _syncInfo.state == SyncStatusState.offline
                            ? Icons.cloud_off_rounded
                            : (_syncInfo.state == SyncStatusState.uploading
                                ? Icons.cloud_upload_rounded
                                : Icons.cloud_done_outlined),
                        color: syncColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName,
                            style: GoogleFonts.outfit(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 15.5,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _syncInfo.pendingCount > 0
                                ? '${_cleanSyncLabel(_syncInfo.label)} • ${_syncInfo.pendingCount} pending'
                                : _cleanSyncLabel(_syncInfo.label),
                            style: GoogleFonts.inter(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Sync now',
                      icon: const Icon(Icons.sync_rounded, color: AppTheme.primary, size: 20),
                      onPressed: () {
                        RequestQueue.instance.triggerSync();
                        ref.invalidate(agentDashboardProvider);
                        ref.invalidate(agentSmartTasksStreamProvider);
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              AppTheme.sectionHeader('Field Operations Overview'),

              metricsAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(28),
                    child: CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 2.5),
                  ),
                ),
                error: (e, _) => Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Text(
                    'Unable to load metrics: $e',
                    style: GoogleFonts.inter(color: AppTheme.danger, fontSize: 12.5),
                  ),
                ),
                data: (metrics) {
                  final genTasksDue = metrics['pendingGenReadings'] ?? 0;
                  final aptTasksDue = metrics['pendingAptReadings'] ?? 0;
                  final subTasksDue = metrics['pendingSubTasks'] ?? 0;
                  final genSubmittedToday = metrics['submittedGenToday'] ?? 0;
                  final isReportSubmitted = genSubmittedToday > 0;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 3-Column Quick Pulse Row
                      Row(
                        children: [
                          Expanded(
                            child: _PulseCard(
                              title: 'Generators',
                              value: '$genTasksDue due',
                              icon: Icons.power_outlined,
                              color: AppTheme.accent,
                              onTap: () => context.go('/agent-generators'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _PulseCard(
                              title: 'Apartments',
                              value: '$aptTasksDue due',
                              icon: Icons.apartment_rounded,
                              color: AppTheme.info,
                              onTap: () => context.go('/agent-apartments'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _PulseCard(
                              title: 'Subscriptions',
                              value: '$subTasksDue due',
                              icon: Icons.electric_bolt_rounded,
                              color: AppTheme.primary,
                              onTap: () => context.go('/agent-subscriptions'),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 22),
                      AppTheme.sectionHeader(
                        'Priority Dispatch',
                        subtitle: 'Assigned tasks requiring field action',
                      ),

                      Consumer(builder: (context, ref, child) {
                        final smartTasksAsync = ref.watch(agentSmartTasksStreamProvider);
                        return smartTasksAsync.when(
                          loading: () => const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 2.5),
                            ),
                          ),
                          error: (e, _) => Text(
                            'Unable to load tasks',
                            style: GoogleFonts.inter(color: AppTheme.danger, fontSize: 12.5),
                          ),
                          data: (tasks) {
                            if (tasks.isEmpty) {
                              return Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  color: AppTheme.surface,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: AppTheme.border),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primary.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.check_circle_outline_rounded,
                                        color: AppTheme.primary,
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'All priority field tasks are completed.',
                                        style: GoogleFonts.inter(
                                          color: AppTheme.textSecondary,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                            return Column(
                              children: tasks.map((t) {
                                final taskMap = t as Map<String, dynamic>;
                                final title = taskMap['title']?.toString() ?? 'Task';
                                final tag = taskMap['task_tag']?.toString() ?? '';
                                final desc = taskMap['description']?.toString() ??
                                    (taskMap['unpaid_count'] != null
                                        ? '${taskMap['unpaid_count']} unpaid invoice(s) • Apt: ${taskMap['apartments_list'] ?? ''}'
                                        : tag);
                                final actionText = taskMap['action_text']?.toString() ??
                                    taskMap['action_label']?.toString() ??
                                    'Open';
                                final actionType = taskMap['action_type']?.toString() ?? '';

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: AppTheme.surface,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: AppTheme.border),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(9),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primary.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Icon(
                                          Icons.task_alt_rounded,
                                          color: AppTheme.primary,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            if (tag.isNotEmpty) ...[
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 6,
                                                  vertical: 2,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: AppTheme.accent.withValues(alpha: 0.12),
                                                  borderRadius: BorderRadius.circular(5),
                                                ),
                                                child: Text(
                                                  tag,
                                                  style: GoogleFonts.inter(
                                                    color: AppTheme.accent,
                                                    fontSize: 9.5,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                            ],
                                            Text(
                                              title,
                                              style: GoogleFonts.outfit(
                                                color: AppTheme.textPrimary,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              desc,
                                              style: GoogleFonts.inter(
                                                color: AppTheme.textSecondary,
                                                fontSize: 12,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppTheme.primary,
                                          foregroundColor: const Color(0xFF04130F),
                                          elevation: 0,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 9,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                        ),
                                        onPressed: () {
                                          if (actionType == 'GENERATOR_LOG') {
                                            context.push('/agent-generators');
                                          } else if (actionType == 'SUBSCRIPTION_REVIEW' ||
                                              actionType == 'ELECTRICITY_COLLECTION') {
                                            context.push('/agent-subscriptions');
                                          } else if (actionType == 'RENT_COLLECTION') {
                                            context.push('/agent-rent-collection');
                                          } else if (actionType == 'METER_READING' ||
                                              actionType == 'EXPIRING_CONTRACT') {
                                            context.push('/agent-apartments');
                                          } else {
                                            final route = taskMap['action_route']?.toString();
                                            if (route != null && route.isNotEmpty) {
                                              context.push(route);
                                            } else {
                                              context.push('/agent-subscriptions');
                                            }
                                          }
                                        },
                                        child: Text(
                                          actionText.length > 12 ? 'Open' : actionText,
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        );
                      }),

                      const SizedBox(height: 22),
                      AppTheme.sectionHeader('Operational Telemetry'),

                      GridView(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          mainAxisExtent: 86,
                        ),
                        children: [
                          _MetricCard(
                            title: 'Sub Tasks Due',
                            value: '$subTasksDue',
                            icon: Icons.payments_outlined,
                            color: AppTheme.primary,
                          ),
                          _MetricCard(
                            title: 'Gen Tasks Due',
                            value: '$genTasksDue',
                            icon: Icons.power_outlined,
                            color: AppTheme.accent,
                          ),
                          _MetricCard(
                            title: 'Apt Tasks Due',
                            value: '$aptTasksDue',
                            icon: Icons.home_work_outlined,
                            color: AppTheme.secondary,
                          ),
                          _MetricCard(
                            title: 'Daily Report',
                            value: isReportSubmitted ? 'Submitted' : 'Pending',
                            icon: Icons.assignment_turned_in_outlined,
                            color: isReportSubmitted ? AppTheme.primary : AppTheme.danger,
                          ),
                        ],
                      ),

                      const SizedBox(height: 22),
                      AppTheme.sectionHeader("Today's Workflow Checklist"),

                      _WorkflowTaskItem(
                        title: 'Rent & Utility Collection',
                        subtitle: 'Collect due invoices for assigned tenants',
                        status: subTasksDue == 0 ? 'Completed' : '$subTasksDue Pending',
                        isDone: subTasksDue == 0,
                      ),
                      const SizedBox(height: 8),
                      _WorkflowTaskItem(
                        title: 'Generator Morning Reading',
                        subtitle: 'Record meter hours and fuel levels',
                        status: genTasksDue == 0 ? 'Completed' : '$genTasksDue Pending',
                        isDone: genTasksDue == 0,
                      ),
                      const SizedBox(height: 8),
                      _WorkflowTaskItem(
                        title: 'Apartment Electricity Readings',
                        subtitle: 'Capture monthly unit meter readings',
                        status: aptTasksDue == 0 ? 'Completed' : '$aptTasksDue Pending',
                        isDone: aptTasksDue == 0,
                      ),
                      const SizedBox(height: 8),
                      _WorkflowTaskItem(
                        title: 'Daily Field Summary Report',
                        subtitle: 'Submit daily site inspection report',
                        status: isReportSubmitted ? 'Submitted' : 'Action Required',
                        isDone: isReportSubmitted,
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PulseCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _PulseCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 15, color: color),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: GoogleFonts.outfit(
                color: AppTheme.textPrimary,
                fontSize: 15.5,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: GoogleFonts.inter(
                color: AppTheme.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(7),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 14, color: color),
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
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _WorkflowTaskItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final String status;
  final bool isDone;

  const _WorkflowTaskItem({
    required this.title,
    required this.subtitle,
    required this.status,
    required this.isDone,
  });

  @override
  Widget build(BuildContext context) {
    final accent = isDone ? AppTheme.primary : AppTheme.warning;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(
              isDone ? Icons.check_circle_outline_rounded : Icons.schedule_rounded,
              color: accent,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    color: AppTheme.textMuted,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: accent.withValues(alpha: 0.28)),
            ),
            child: Text(
              status,
              style: GoogleFonts.inter(
                color: accent,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
