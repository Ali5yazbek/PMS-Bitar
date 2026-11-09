import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/app_theme.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import '../providers/app_providers.dart';
import '../widgets/mobile/enterprise_mobile_scaffold.dart';
import '../widgets/mobile/audit_timeline_widget.dart';
import '../widgets/async_button.dart';

final maintenanceTasksProvider = FutureProvider<List<dynamic>>((ref) async {
  try {
    final res = await ApiService().get('/maintenance/tasks');
    final data = res.data;
    if (data is List) return data;
    if (data is String) {
      final decoded = jsonDecode(data);
      if (decoded is List) return decoded;
      if (decoded is Map && decoded.containsKey('tasks')) return (decoded['tasks'] as List<dynamic>?) ?? [];
      if (decoded is Map && decoded.containsKey('data')) return (decoded['data'] as List<dynamic>?) ?? [];
    }
    if (data is Map && data.containsKey('tasks')) return (data['tasks'] as List<dynamic>?) ?? [];
    if (data is Map && data.containsKey('data')) return (data['data'] as List<dynamic>?) ?? [];
    return [];
  } catch (e) {
    debugPrint('[MaintenanceDashboard] Error fetching tasks: $e');
    return [];
  }
});

class MaintenanceDashboardScreen extends ConsumerStatefulWidget {
  const MaintenanceDashboardScreen({super.key});

  @override
  ConsumerState<MaintenanceDashboardScreen> createState() => _MaintenanceDashboardScreenState();
}

class _MaintenanceDashboardScreenState extends ConsumerState<MaintenanceDashboardScreen> with WidgetsBindingObserver {
  int _filterIndex = 0; // 0: All, 1: Tenant Requests, 2: Routine AC

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(maintenanceTasksProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(maintenanceTasksProvider);
    final userName = ref.watch(authProvider.select((s) => s.user?.name ?? 'Maintenance Technician'));
    final unreadNotifs = ref.watch(
      notificationsProvider.select((list) => list.where((n) => !n.isRead).length),
    );

    return EnterpriseMobileScaffold(
      title: 'Maintenance Workspace',
      userRole: 'Maintenance',
      userName: userName,
      activeBuilding: 'All Properties',
      unreadNotifications: unreadNotifs,
      currentTabIndex: 0,
      onTabSelected: (index) {
        if (index == 1 || index == 2) context.go('/maintenance-history');
        if (index == 3) context.go('/notifications');
        if (index == 4) context.go('/settings');
      },
      onNotificationTap: () => context.go('/notifications'),
      body: RefreshIndicator(
        color: AppTheme.primary,
        backgroundColor: AppTheme.surface,
        onRefresh: () async {
          ref.invalidate(maintenanceTasksProvider);
          await ref.read(maintenanceTasksProvider.future);
        },
        child: tasksAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 2.5),
            ),
          ),
          error: (err, _) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.danger.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.danger.withValues(alpha: 0.3)),
                ),
                child: Text(
                  'Unable to load maintenance tasks: $err',
                  style: GoogleFonts.inter(color: AppTheme.textPrimary, fontSize: 13),
                ),
              ),
            ],
          ),
          data: (tasks) {
            final assignedCount = tasks.length;
            final tenantTickets = tasks.where((t) => t['task_type'] == 'tenant_ticket').toList();
            final routineACTasks = tasks.where((t) => t['task_type'] == 'routine_ac' || t['task_type'] == null).toList();
            final urgentCount = tasks.where((t) {
              final p = (t['priority'] ?? '').toString().toLowerCase();
              return p == 'urgent' || p == 'high' || p == 'critical';
            }).length;
            final waitingApproval = tasks.where((t) => t['status'] == 'Waiting Approval' || t['status'] == 'Pending_Approval').length;

            List<dynamic> displayedTasks;
            if (_filterIndex == 1) {
              displayedTasks = tenantTickets;
            } else if (_filterIndex == 2) {
              displayedTasks = routineACTasks;
            } else {
              displayedTasks = tasks;
            }

            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppTheme.sectionHeader(
                          'Field Operations Summary',
                          subtitle: 'Assigned repairs and scheduled AC maintenance',
                        ),
                        GridView(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            mainAxisExtent: 86,
                          ),
                          children: [
                            _MaintCard(
                              title: 'Total Work Orders',
                              value: '$assignedCount',
                              icon: Icons.assignment_outlined,
                              color: AppTheme.info,
                            ),
                            _MaintCard(
                              title: 'Tenant Requests',
                              value: '${tenantTickets.length}',
                              icon: Icons.person_outline_rounded,
                              color: AppTheme.primary,
                              isHighlight: tenantTickets.isNotEmpty,
                            ),
                            _MaintCard(
                              title: 'Urgent Repairs',
                              value: '$urgentCount',
                              icon: Icons.warning_amber_rounded,
                              color: AppTheme.danger,
                              isHighlight: urgentCount > 0,
                            ),
                            _MaintCard(
                              title: 'Awaiting Review',
                              value: '$waitingApproval',
                              icon: Icons.schedule_rounded,
                              color: AppTheme.warning,
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: Row(
                            children: [
                              _buildFilterTab(0, 'All (${tasks.length})'),
                              _buildFilterTab(1, 'Requests (${tenantTickets.length})'),
                              _buildFilterTab(2, 'Routine AC (${routineACTasks.length})'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        AppTheme.sectionHeader(
                          _filterIndex == 1
                              ? 'Tenant Maintenance Requests'
                              : (_filterIndex == 2 ? 'Routine AC Schedules' : 'All Assigned Work Orders'),
                        ),
                      ],
                    ),
                  ),
                ),
                if (displayedTasks.isEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    sliver: SliverToBoxAdapter(
                      child: Container(
                        padding: const EdgeInsets.all(28),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.task_alt_rounded,
                                size: 32,
                                color: AppTheme.primary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _filterIndex == 1
                                  ? 'No pending tenant requests'
                                  : 'No tasks in this category',
                              style: GoogleFonts.outfit(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'All assigned work items are completed and up to date.',
                              style: GoogleFonts.inter(
                                color: AppTheme.textMuted,
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 36),
                    sliver: SliverList.builder(
                      itemCount: displayedTasks.length,
                      itemBuilder: (context, index) {
                        final task = displayedTasks[index];
                        return RepaintBoundary(
                          child: _buildTaskCard(context, task),
                        );
                      },
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTaskCard(BuildContext context, dynamic task) {
    final isTenantTicket = task['task_type'] == 'tenant_ticket';
    final status = (task['status'] ?? 'Assigned').toString();
    final isPendingApproval = status == 'Waiting Approval' || status == 'Pending_Approval';
    final isDone = status == 'Completed' || status == 'Approved' || status == 'Resolved';
    final priority = (task['priority'] ?? 'Medium').toString();
    final isUrgent = priority.toLowerCase() == 'urgent' || priority.toLowerCase() == 'critical';
    final isHigh = priority.toLowerCase() == 'high';

    final Color priorityColor = isUrgent
        ? AppTheme.danger
        : (isHigh ? AppTheme.warning : AppTheme.info);
    final Color typeColor = isTenantTicket ? AppTheme.primary : AppTheme.info;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUrgent ? AppTheme.danger.withValues(alpha: 0.45) : AppTheme.border,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                    decoration: BoxDecoration(
                      color: typeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: typeColor.withValues(alpha: 0.28)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isTenantTicket ? Icons.person_outline_rounded : Icons.ac_unit_rounded,
                          size: 12,
                          color: typeColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isTenantTicket ? 'TENANT REQUEST' : 'ROUTINE AC',
                          style: GoogleFonts.inter(
                            color: typeColor,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (task['category'] != null && task['category'].toString().isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceHover,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Text(
                        task['category'].toString(),
                        style: GoogleFonts.inter(
                          color: AppTheme.textSecondary,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                decoration: BoxDecoration(
                  color: priorityColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: priorityColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  priority.toUpperCase(),
                  style: GoogleFonts.inter(
                    color: priorityColor,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.apartment_rounded, size: 17, color: AppTheme.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${task['building_name'] ?? 'Building'} • Apt ${task['apartment_code'] ?? 'N/A'}',
                  style: GoogleFonts.outfit(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 15.5,
                  ),
                ),
              ),
            ],
          ),
          if (task['tenant_name'] != null && task['tenant_name'].toString().isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: AppTheme.surfaceHover,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.person_outline_rounded, size: 14, color: AppTheme.textMuted),
                      const SizedBox(width: 6),
                      Text(
                        task['tenant_name'].toString(),
                        style: GoogleFonts.inter(
                          color: AppTheme.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  if (task['tenant_phone'] != null && task['tenant_phone'].toString().isNotEmpty)
                    InkWell(
                      onTap: () {
                        final phone = task['tenant_phone'].toString();
                        launchUrl(Uri.parse('tel:$phone'));
                      },
                      child: Row(
                        children: [
                          const Icon(Icons.phone_outlined, size: 13, color: AppTheme.primary),
                          const SizedBox(width: 4),
                          Text(
                            task['tenant_phone'].toString(),
                            style: GoogleFonts.inter(
                              color: AppTheme.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),
          Text(
            task['title'] ?? (isTenantTicket ? 'Apartment Maintenance Request' : 'Routine AC Cleaning'),
            style: GoogleFonts.outfit(
              color: AppTheme.textPrimary,
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  isTenantTicket ? Icons.build_circle_outlined : Icons.cleaning_services_outlined,
                  size: 16,
                  color: AppTheme.textMuted,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    task['description'] != null && task['description'].toString().isNotEmpty
                        ? task['description'].toString()
                        : (isTenantTicket
                            ? 'Tenant reported an issue requiring field inspection.'
                            : 'Standard AC filter and coil maintenance.'),
                    style: GoogleFonts.inter(
                      color: AppTheme.textSecondary,
                      fontSize: 12.5,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (task['scheduled_date'] != null && task['scheduled_date'].toString().isNotEmpty) ...[
                const Icon(Icons.calendar_today_outlined, size: 13, color: AppTheme.textMuted),
                const SizedBox(width: 5),
                Text(
                  'Scheduled: ${task['scheduled_date']}',
                  style: GoogleFonts.inter(
                    color: AppTheme.textMuted,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (isDone
                          ? AppTheme.success
                          : (isPendingApproval ? AppTheme.warning : AppTheme.info))
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: GoogleFonts.inter(
                    color: isDone
                        ? AppTheme.success
                        : (isPendingApproval ? AppTheme.warning : AppTheme.info),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          AuditTimelineWidget(
            steps: [
              TimelineStep(
                title: 'Request Created',
                isCompleted: true,
                timestamp: task['scheduled_date']?.toString() ?? 'Assigned',
              ),
              TimelineStep(
                title: 'Technician Assigned',
                isCompleted: true,
                isCurrent: status == 'In Progress' || status == 'Open',
              ),
              TimelineStep(
                title: 'Work & Photos Uploaded',
                isCompleted: isDone || isPendingApproval,
                timestamp: isDone || isPendingApproval
                    ? (task['submission_date']?.toString() ?? 'Submitted')
                    : null,
              ),
              TimelineStep(
                title: 'Resolved / Approved',
                isCompleted: isDone,
                isCurrent: isPendingApproval,
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: isPendingApproval ? AppTheme.surfaceHover : AppTheme.primary,
                foregroundColor: isPendingApproval ? AppTheme.textMuted : const Color(0xFF04130F),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
              ),
              onPressed: isPendingApproval
                  ? null
                  : () => _showSubmissionModal(context, ref, task),
              icon: Icon(
                isPendingApproval
                    ? Icons.schedule_rounded
                    : (isTenantTicket
                        ? Icons.check_circle_outline_rounded
                        : Icons.upload_file_rounded),
                size: 16,
              ),
              label: Text(
                isPendingApproval
                    ? 'Awaiting Admin Approval'
                    : (isTenantTicket ? 'Resolve Request' : 'Submit AC Maintenance'),
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTab(int index, String label) {
    final isSelected = _filterIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _filterIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.inter(
                color: isSelected ? const Color(0xFF04130F) : AppTheme.textSecondary,
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }

  void _showSubmissionModal(BuildContext context, WidgetRef ref, Map task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _MaintenanceSubmissionForm(task: task, ref: ref),
    );
  }
}

class _MaintCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final bool isHighlight;

  const _MaintCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.isHighlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isHighlight ? color.withValues(alpha: 0.4) : AppTheme.border,
        ),
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
                child: Icon(icon, color: color, size: 14),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
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
              color: isHighlight ? color : AppTheme.textPrimary,
              fontSize: 19,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MaintenanceSubmissionForm extends StatefulWidget {
  final Map task;
  final WidgetRef ref;
  const _MaintenanceSubmissionForm({required this.task, required this.ref});

  @override
  State<_MaintenanceSubmissionForm> createState() => _MaintenanceSubmissionFormState();
}

class _MaintenanceSubmissionFormState extends State<_MaintenanceSubmissionForm> {
  final _notesController = TextEditingController();
  final _hoursController = TextEditingController(text: '1.0');
  final _materialsController = TextEditingController();
  Uint8List? _beforeImageBytes;
  Uint8List? _afterImageBytes;

  @override
  void initState() {
    super.initState();
    final isTenantTicket = widget.task['task_type'] == 'tenant_ticket';
    if (!isTenantTicket) {
      _materialsController.text = 'AC Filter cleaner, coil brush';
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _hoursController.dispose();
    _materialsController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(bool isBefore) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
      maxWidth: 1280,
      maxHeight: 1280,
    );
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      if (!mounted) return;
      setState(() {
        if (isBefore) {
          _beforeImageBytes = bytes;
        } else {
          _afterImageBytes = bytes;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (_beforeImageBytes == null || _afterImageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please capture both Before and After photos for verification.'),
        ),
      );
      return;
    }

    final taskId = widget.task['id'];
    final isTenantTicket = widget.task['task_type'] == 'tenant_ticket';
    final notesText = _notesController.text.trim().isEmpty
        ? (isTenantTicket
            ? 'Repair completed and tested successfully.'
            : 'AC filter and coil maintenance completed.')
        : _notesController.text.trim();
    final beforeBase64 = 'data:image/jpeg;base64,${base64Encode(_beforeImageBytes!)}';
    final afterBase64 = 'data:image/jpeg;base64,${base64Encode(_afterImageBytes!)}';

    try {
      await ApiService().post('/maintenance/tasks/$taskId/submit', data: {
        'task_id': taskId,
        'task_type': widget.task['task_type'] ?? 'routine_ac',
        'before_photo': beforeBase64,
        'after_photo': afterBase64,
        'notes': notesText,
        'worker_notes': notesText,
        'hours': _hoursController.text,
        'materials': _materialsController.text,
        'status': isTenantTicket ? 'Resolved' : 'Pending_Approval',
      });

      if (mounted) {
        Navigator.pop(context);
        widget.ref.invalidate(maintenanceTasksProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isTenantTicket
                  ? 'Tenant request resolved successfully.'
                  : 'Maintenance submission recorded successfully.',
            ),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        if (e.toString().contains('OFFLINE_QUEUED')) {
          Navigator.pop(context);
          widget.ref.invalidate(maintenanceTasksProvider);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Saved offline and queued for synchronization.'),
              backgroundColor: AppTheme.warning,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to submit: $e'),
              backgroundColor: AppTheme.danger,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTenantTicket = widget.task['task_type'] == 'tenant_ticket';

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: AppTheme.borderLight)),
        ),
        child: SingleChildScrollView(
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
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isTenantTicket ? 'Resolve Work Order' : 'Submit AC Maintenance',
                    style: GoogleFonts.outfit(
                      color: AppTheme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, color: AppTheme.textSecondary, size: 20),
                  ),
                ],
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${widget.task['building_name']} • Apt ${widget.task['apartment_code']}',
                      style: GoogleFonts.outfit(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.task['title'] ??
                          (isTenantTicket ? 'Tenant Reported Issue' : 'Routine AC Cleaning'),
                      style: GoogleFonts.inter(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 12.5,
                      ),
                    ),
                    if (widget.task['description'] != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        widget.task['description'].toString(),
                        style: GoogleFonts.inter(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              Text(
                'Verification Photos (Required)',
                style: GoogleFonts.inter(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '1. Before Work',
                          style: GoogleFonts.inter(color: AppTheme.textMuted, fontSize: 11),
                        ),
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: () => _pickImage(true),
                          child: Container(
                            height: 104,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: AppTheme.background,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _beforeImageBytes != null
                                    ? AppTheme.primary
                                    : AppTheme.border,
                              ),
                            ),
                            child: _beforeImageBytes != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(11),
                                    child: Image.memory(
                                      _beforeImageBytes!,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: 104,
                                      cacheWidth: 360,
                                    ),
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.camera_alt_outlined,
                                        color: AppTheme.textMuted,
                                        size: 24,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Capture Before',
                                        style: GoogleFonts.inter(
                                          color: AppTheme.textMuted,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '2. After Completion',
                          style: GoogleFonts.inter(color: AppTheme.textMuted, fontSize: 11),
                        ),
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: () => _pickImage(false),
                          child: Container(
                            height: 104,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: AppTheme.background,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _afterImageBytes != null
                                    ? AppTheme.success
                                    : AppTheme.border,
                              ),
                            ),
                            child: _afterImageBytes != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(11),
                                    child: Image.memory(
                                      _afterImageBytes!,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: 104,
                                      cacheWidth: 360,
                                    ),
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.camera_alt_outlined,
                                        color: AppTheme.textMuted,
                                        size: 24,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Capture After',
                                        style: GoogleFonts.inter(
                                          color: AppTheme.textMuted,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _hoursController,
                      style: GoogleFonts.inter(color: AppTheme.textPrimary, fontSize: 13),
                      decoration: const InputDecoration(labelText: 'Labor Hours'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _materialsController,
                      style: GoogleFonts.inter(color: AppTheme.textPrimary, fontSize: 13),
                      decoration: const InputDecoration(labelText: 'Parts / Materials Used'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _notesController,
                maxLines: 3,
                style: GoogleFonts.inter(color: AppTheme.textPrimary, fontSize: 13),
                decoration: const InputDecoration(
                  labelText: 'Resolution Notes',
                  hintText: 'Describe what was repaired, replaced, or serviced...',
                ),
              ),
              const SizedBox(height: 20),
              AsyncButton(
                text: isTenantTicket
                    ? 'Mark Resolved & Submit Work'
                    : 'Submit for Admin Approval',
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
