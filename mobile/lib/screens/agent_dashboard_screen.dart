import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_theme.dart';
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
    label: '✓ All data synchronized',
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

  @override
  Widget build(BuildContext context) {
    final metricsAsync = ref.watch(agentDashboardProvider);

    final Color syncColor = _syncInfo.state == SyncStatusState.offline
        ? AppTheme.danger
        : (_syncInfo.state == SyncStatusState.uploading ? AppTheme.accent : AppTheme.primary);

    return EnterpriseMobileScaffold(
      title: 'Agent Dashboard',
      userRole: 'Agent',
      userName: 'Field Agent',
      currentTabIndex: 0,
      unreadNotifications: 2,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(agentDashboardProvider);
        },
        color: AppTheme.primary,
        backgroundColor: AppTheme.surface,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Luxury Sync Telemetry Card ──────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      syncColor.withValues(alpha: 0.14),
                      AppTheme.surface,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: syncColor.withValues(alpha: 0.35)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: syncColor.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              _syncInfo.state == SyncStatusState.offline
                                  ? Icons.cloud_off_rounded
                                  : (_syncInfo.state == SyncStatusState.uploading
                                      ? Icons.cloud_upload_rounded
                                      : Icons.verified_rounded),
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
                                  _syncInfo.label,
                                  style: GoogleFonts.outfit(
                                    color: AppTheme.textPrimary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Offline Queue: ${_syncInfo.pendingCount} pending packet(s)',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: AppTheme.textSecondary,
                                    fontSize: 11,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.sync_rounded, color: AppTheme.primary, size: 22),
                      onPressed: () {
                        RequestQueue.instance.triggerSync();
                        ref.invalidate(agentDashboardProvider);
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),
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
                    'Field Operations Pulse',
                    style: GoogleFonts.outfit(
                      color: AppTheme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              metricsAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(28),
                    child: CircularProgressIndicator(color: AppTheme.primary),
                  ),
                ),
                error: (e, _) => Center(
                  child: Text('Error loading stats: $e', style: const TextStyle(color: AppTheme.danger)),
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
                            child: _MetricCard(
                              title: 'Generators',
                              value: '$genTasksDue due',
                              icon: Icons.bolt_rounded,
                              color: AppTheme.accent,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _MetricCard(
                              title: 'Apartments',
                              value: '$aptTasksDue due',
                              icon: Icons.apartment_rounded,
                              color: const Color(0xFF38BDF8),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _MetricCard(
                              title: 'Subscriptions',
                              value: '$subTasksDue due',
                              icon: Icons.flash_on_rounded,
                              color: AppTheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
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
                            'Smart Priority Dispatch',
                            style: GoogleFonts.outfit(
                              color: AppTheme.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Consumer(builder: (context, ref, child) {
                        final smartTasksAsync = ref.watch(agentSmartTasksStreamProvider);
                        return smartTasksAsync.when(
                          loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
                          error: (e, _) => const Text('Error loading tasks', style: TextStyle(color: AppTheme.danger)),
                          data: (tasks) {
                            if (tasks.isEmpty) {
                              return Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(20),
                                decoration: AppTheme.glassCardDecoration(borderRadius: 18),
                                child: Text(
                                  'All priority field tasks are completed.',
                                  style: GoogleFonts.plusJakartaSans(color: AppTheme.textSecondary),
                                  textAlign: TextAlign.center,
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
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  decoration: AppTheme.glassCardDecoration(borderRadius: 18),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primary.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(14),
                                          border: Border.all(
                                            color: AppTheme.primary.withValues(alpha: 0.35),
                                          ),
                                        ),
                                        child: const Icon(Icons.task_alt_rounded, color: AppTheme.primary, size: 22),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Directionality(
                                              textDirection: TextDirection.ltr,
                                              child: Row(
                                                children: [
                                                  if (tag.isNotEmpty) ...[
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: AppTheme.accent.withValues(alpha: 0.16),
                                                        borderRadius: BorderRadius.circular(6),
                                                        border: Border.all(
                                                          color: AppTheme.accent.withValues(alpha: 0.35),
                                                        ),
                                                      ),
                                                      child: Text(
                                                        tag,
                                                        style: GoogleFonts.plusJakartaSans(
                                                          color: AppTheme.accent,
                                                          fontSize: 9,
                                                          fontWeight: FontWeight.w800,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 6),
                                                  ],
                                                ],
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Directionality(
                                              textDirection: TextDirection.ltr,
                                              child: Text(
                                                title,
                                                style: GoogleFonts.outfit(
                                                  color: AppTheme.textPrimary,
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 14.5,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 2,
                                              ),
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              desc,
                                              style: GoogleFonts.plusJakartaSans(
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
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
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
                                          style: GoogleFonts.outfit(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w800,
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

                      const SizedBox(height: 24),
                      Text(
                        'Operational Telemetry',
                        style: GoogleFonts.outfit(
                          color: AppTheme.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.5,
                        children: [
                          _MetricCard(
                            title: 'Sub Tasks Due',
                            value: '$subTasksDue',
                            icon: Icons.payments_rounded,
                            color: AppTheme.primary,
                          ),
                          _MetricCard(
                            title: 'Gen Tasks Due',
                            value: '$genTasksDue',
                            icon: Icons.power_rounded,
                            color: AppTheme.accent,
                          ),
                          _MetricCard(
                            title: 'Apt Tasks Due',
                            value: '$aptTasksDue',
                            icon: Icons.home_work_rounded,
                            color: const Color(0xFFA78BFA),
                          ),
                          _MetricCard(
                            title: 'Daily Report',
                            value: isReportSubmitted ? 'Submitted' : 'Pending',
                            icon: Icons.assignment_turned_in_rounded,
                            color: isReportSubmitted ? AppTheme.primary : AppTheme.danger,
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),
                      Text(
                        "Today's Assigned Workflow",
                        style: GoogleFonts.outfit(
                          color: AppTheme.textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),

                      _WorkflowTaskItem(
                        title: 'Rent Collection',
                        subtitle: 'Collect rent for assigned tenants',
                        status: subTasksDue == 0 ? 'Completed' : '$subTasksDue Pending',
                        isDone: subTasksDue == 0,
                      ),
                      const SizedBox(height: 10),
                      _WorkflowTaskItem(
                        title: 'Generator Morning Reading',
                        subtitle: 'Galaxy Building • CAT 350kVA',
                        status: genTasksDue == 0 ? 'Completed' : '$genTasksDue Pending',
                        isDone: genTasksDue == 0,
                      ),
                      const SizedBox(height: 10),
                      _WorkflowTaskItem(
                        title: 'Apartment Electricity Verification',
                        subtitle: 'Galaxy & Bitar Towers • Apartments',
                        status: '$aptTasksDue Pending',
                        isDone: aptTasksDue == 0,
                      ),
                      const SizedBox(height: 10),
                      _WorkflowTaskItem(
                        title: 'Daily Field Summary Report',
                        subtitle: 'Location visits & evidence photo submission',
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: AppTheme.obsidianCardGradient,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.textSecondary,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.outfit(
              color: AppTheme.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w800,
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
    final accent = isDone ? AppTheme.primary : AppTheme.accent;

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: AppTheme.glassCardDecoration(borderRadius: 18),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isDone ? Icons.check_circle_rounded : Icons.schedule_rounded,
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
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.textMuted,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: accent.withValues(alpha: 0.35)),
            ),
            child: Text(
              status,
              style: GoogleFonts.plusJakartaSans(
                color: accent,
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
