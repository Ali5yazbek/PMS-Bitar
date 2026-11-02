import 'dart:convert';
import 'dart:typed_data';
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
    debugPrint('[MaintenanceDashboard] Error fetching tasks: ' + e.toString());
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
    final user = ref.watch(authProvider).user;
    final unreadNotifs = ref.watch(notificationsProvider).where((n) => !n.isRead).length;

    return EnterpriseMobileScaffold(
      title: 'Maintenance Field Workspace',
      userRole: 'Maintenance',
      userName: user?.name ?? 'Maintenance Tech',
      activeBuilding: 'Galaxy Building',
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
        onRefresh: () async {
          ref.invalidate(maintenanceTasksProvider);
          await ref.read(maintenanceTasksProvider.future);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Operational Metrics Grid
              Text('Maintenance Field Operations', style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),

              tasksAsync.when(
                loading: () => const Center(child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(color: AppTheme.primary),
                )),
                error: (err, _) => Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppTheme.danger.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: Text('Error loading tasks: $err', style: GoogleFonts.inter(color: Colors.white)),
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

                  // Filter tasks according to selected tab
                  List<dynamic> displayedTasks;
                  if (_filterIndex == 1) {
                    displayedTasks = tenantTickets;
                  } else if (_filterIndex == 2) {
                    displayedTasks = routineACTasks;
                  } else {
                    displayedTasks = tasks;
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.55,
                        children: [
                          _MaintCard(
                            title: 'TOTAL WORK ORDERS', 
                            value: '$assignedCount', 
                            icon: Icons.assignment_outlined, 
                            color: Colors.blue
                          ),
                          _MaintCard(
                            title: 'TENANT REQUESTS', 
                            value: '${tenantTickets.length}', 
                            icon: Icons.person_pin_outlined, 
                            color: Color(0xFF00D4AA),
                            isHighlight: tenantTickets.isNotEmpty
                          ),
                          _MaintCard(
                            title: 'URGENT APARTMENT REPAIRS', 
                            value: '$urgentCount', 
                            icon: Icons.warning_amber_rounded, 
                            color: Colors.redAccent, 
                            isHighlight: urgentCount > 0
                          ),
                          _MaintCard(
                            title: 'WAITING APPROVAL', 
                            value: '$waitingApproval', 
                            icon: Icons.hourglass_top_rounded, 
                            color: Colors.orangeAccent
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Filter Segmented Controls
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D1620),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFF1D3347)),
                        ),
                        child: Row(
                          children: [
                            _buildFilterTab(0, 'All Tasks (${tasks.length})'),
                            _buildFilterTab(1, 'Tenant Requests (${tenantTickets.length})'),
                            _buildFilterTab(2, 'Routine AC (${routineACTasks.length})'),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),
                      Text(
                        _filterIndex == 1 
                          ? 'Active Tenant Apartment Requests'
                          : (_filterIndex == 2 ? 'Routine AC Cleaning Schedules' : 'All Assigned Field Tasks'),
                        style: GoogleFonts.outfit(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)
                      ),
                      const SizedBox(height: 12),

                      if (displayedTasks.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(32),
                          width: double.infinity,
                          decoration: BoxDecoration(color: const Color(0xFF0D1620), borderRadius: BorderRadius.circular(16)),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(Icons.task_alt_rounded, size: 48, color: const Color(0xFF10B981).withValues(alpha: 0.6)),
                                const SizedBox(height: 12),
                                Text(
                                  _filterIndex == 1
                                    ? 'No pending tenant requests!'
                                    : 'No tasks in this category.',
                                  style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)
                                ),
                                const SizedBox(height: 4),
                                Text('All current work items are completed and caught up.', style: GoogleFonts.inter(color: Colors.blueGrey.shade400, fontSize: 13)),
                              ],
                            ),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: displayedTasks.length,
                          itemBuilder: (context, index) {
                            final task = displayedTasks[index];
                            final isTenantTicket = task['task_type'] == 'tenant_ticket';
                            final status = task['status'] ?? 'Assigned';
                            final isPendingApproval = status == 'Waiting Approval' || status == 'Pending_Approval';
                            final isDone = status == 'Completed' || status == 'Approved' || status == 'Resolved';
                            final priority = (task['priority'] ?? 'Medium').toString();
                            final isUrgent = priority.toLowerCase() == 'urgent' || priority.toLowerCase() == 'critical';

                            return Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isTenantTicket ? const Color(0xFF111E2C) : const Color(0xFF0D1620),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: isUrgent 
                                    ? Colors.redAccent.withOpacity(0.6) 
                                    : (isTenantTicket ? Color(0xFF00D4AA).withOpacity(0.4) : const Color(0xFF1D3347)),
                                  width: isUrgent ? 1.5 : 1.0,
                                ),
                                boxShadow: isUrgent ? [
                                  BoxShadow(color: Colors.redAccent.withOpacity(0.12), blurRadius: 10, spreadRadius: 1)
                                ] : null,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Header Badges
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      // Task Type & Category
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: isTenantTicket ? Colors.indigo.withOpacity(0.3) : Colors.cyan.withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(
                                                color: isTenantTicket ? Color(0xFF00D4AA).withOpacity(0.5) : Colors.cyan.withOpacity(0.4)
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  isTenantTicket ? Icons.person_pin_rounded : Icons.ac_unit_rounded, 
                                                  size: 13, 
                                                  color: isTenantTicket ? const Color(0xFF99F3E2) : Colors.cyanAccent
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  isTenantTicket ? 'TENANT REQUEST' : 'ROUTINE AC',
                                                  style: TextStyle(
                                                    color: isTenantTicket ? const Color(0xFF99F3E2) : Colors.cyanAccent,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          if (task['category'] != null && task['category'].toString().isNotEmpty)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(0.08),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                task['category'].toString(),
                                                style: GoogleFonts.inter(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600),
                                              ),
                                            ),
                                        ],
                                      ),

                                      // Urgency / Priority Badge
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: isUrgent ? Colors.red.withOpacity(0.25) : (priority.toLowerCase() == 'high' ? Colors.orange.withOpacity(0.2) : Colors.blue.withOpacity(0.15)),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: isUrgent ? Colors.redAccent : (priority.toLowerCase() == 'high' ? Colors.orangeAccent : Colors.blueAccent.withOpacity(0.4)),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (isUrgent) ...[
                                              const Icon(Icons.local_fire_department_rounded, size: 12, color: Colors.redAccent),
                                              const SizedBox(width: 2),
                                            ],
                                            Text(
                                              priority.toUpperCase(),
                                              style: TextStyle(
                                                color: isUrgent ? Colors.redAccent : (priority.toLowerCase() == 'high' ? Colors.orangeAccent : Colors.lightBlueAccent),
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 12),

                                  // Building & Apartment Title
                                  Row(
                                    children: [
                                      const Icon(Icons.apartment_rounded, size: 18, color: AppTheme.primary),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          '${task['building_name'] ?? 'Building'}  •  Apartment ${task['apartment_code'] ?? 'N/A'}',
                                          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                        ),
                                      ),
                                    ],
                                  ),

                                  // Tenant details if tenant request
                                  if (task['tenant_name'] != null && task['tenant_name'].toString().isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.black26,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              const Icon(Icons.person_outline_rounded, size: 14, color: Colors.blueGrey),
                                              const SizedBox(width: 4),
                                              Text(
                                                task['tenant_name'].toString(),
                                                style: GoogleFonts.inter(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                                              ),
                                            ],
                                          ),
                                          if (task['tenant_phone'] != null && task['tenant_phone'].toString().isNotEmpty)
                                            GestureDetector(
                                              onTap: () {
                                                final phone = task['tenant_phone'].toString();
                                                launchUrl(Uri.parse('tel:$phone'));
                                              },
                                              child: Row(
                                                children: [
                                                  const Icon(Icons.phone_rounded, size: 13, color: AppTheme.primary),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    task['tenant_phone'].toString(),
                                                    style: GoogleFonts.inter(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.bold),
                                                  ),
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],

                                  const SizedBox(height: 10),

                                  // Problem Title
                                  Text(
                                    task['title'] ?? (isTenantTicket ? 'Tenant Apartment Maintenance' : 'Routine AC Cleaning'),
                                    style: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
                                  ),

                                  const SizedBox(height: 6),

                                  // Problem Description
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF060B10).withOpacity(0.7),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: const Color(0xFF1D3347).withOpacity(0.5)),
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Icon(
                                          isTenantTicket ? Icons.report_problem_outlined : Icons.cleaning_services_outlined,
                                          size: 16,
                                          color: isTenantTicket ? Colors.amber.shade400 : Colors.cyan.shade300,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            task['description'] != null && task['description'].toString().isNotEmpty
                                              ? task['description'].toString()
                                              : (isTenantTicket ? 'Tenant reported an issue requiring inspection.' : 'Standard AC coil and filter cleaning.'),
                                            style: GoogleFonts.inter(color: Colors.blueGrey.shade200, fontSize: 12.5, height: 1.35),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 12),

                                  // Date Badges
                                  Row(
                                    children: [
                                      if (task['scheduled_date'] != null && task['scheduled_date'].toString().isNotEmpty) ...[
                                        Icon(Icons.calendar_month_outlined, size: 14, color: Colors.blueGrey.shade400),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Date: ${task['scheduled_date']}',
                                          style: GoogleFonts.inter(color: Colors.blueGrey.shade300, fontSize: 11, fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                      const Spacer(),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: isDone ? Colors.green.withOpacity(0.2) : (isPendingApproval ? Colors.orange.withOpacity(0.2) : Colors.amber.withOpacity(0.15)),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          status.toUpperCase(),
                                          style: TextStyle(
                                            color: isDone ? Colors.green.shade300 : (isPendingApproval ? Colors.orange.shade300 : Colors.amber.shade300),
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 16),

                                  // Audit Timeline widget preview
                                  AuditTimelineWidget(
                                    steps: [
                                      TimelineStep(title: 'Request Created', isCompleted: true, timestamp: task['scheduled_date']?.toString() ?? '08:00 AM'),
                                      TimelineStep(title: 'Tech Assigned', isCompleted: true, isCurrent: status == 'In Progress' || status == 'Open'),
                                      TimelineStep(title: 'Work & Photos Uploaded', isCompleted: isDone || isPendingApproval, timestamp: isDone || isPendingApproval ? (task['submission_date']?.toString() ?? 'Done') : null),
                                      TimelineStep(title: 'Resolved / Approved', isCompleted: isDone, isCurrent: isPendingApproval),
                                    ],
                                  ),

                                  const SizedBox(height: 16),

                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: isPendingApproval 
                                            ? Colors.amber.shade800 
                                            : (isTenantTicket ? const Color(0xFF00A884) : AppTheme.primary),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                        ),
                                        onPressed: isPendingApproval ? null : () => _showSubmissionModal(context, ref, task),
                                        icon: Icon(
                                          isPendingApproval 
                                            ? Icons.hourglass_top 
                                            : (isTenantTicket ? Icons.check_circle_outline_rounded : Icons.upload_file_rounded), 
                                          size: 16
                                        ),
                                        label: Text(
                                          isPendingApproval 
                                            ? 'Awaiting Admin Approval' 
                                            : (isTenantTicket ? 'Resolve Tenant Request' : 'Complete AC Cleaning'),
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
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

  Widget _buildFilterTab(int index, String label) {
    final isSelected = _filterIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _filterIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.inter(
                color: isSelected ? Colors.white : Colors.blueGrey.shade300,
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1620),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isHighlight ? color : const Color(0xFF1D3347)),
        boxShadow: isHighlight ? [BoxShadow(color: color.withOpacity(0.15), blurRadius: 8, spreadRadius: 1)] : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: GoogleFonts.inter(color: Colors.blueGrey.shade400, fontSize: 10, fontWeight: FontWeight.bold)),
              Icon(icon, color: color, size: 18),
            ],
          ),
          Text(value, style: GoogleFonts.outfit(color: isHighlight ? color : Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
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

  Future<void> _pickImage(bool isBefore) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera, imageQuality: 70);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
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
        const SnackBar(content: Text('Please capture both Before and After photos for verification.')),
      );
      return;
    }

    final taskId = widget.task['id'];
    final isTenantTicket = widget.task['task_type'] == 'tenant_ticket';
    final notesText = _notesController.text.trim().isEmpty
        ? (isTenantTicket ? 'Repair completed and tested successfully.' : 'AC filter and coil maintenance completed.')
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
            content: Text(isTenantTicket ? 'Tenant request resolved successfully! ✓' : 'Maintenance submission recorded successfully! ✓'), 
            backgroundColor: AppTheme.success
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        if (e.toString().contains('OFFLINE_QUEUED')) {
          Navigator.pop(context);
          widget.ref.invalidate(maintenanceTasksProvider);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Saved offline and queued for sync ✓'), backgroundColor: Colors.amber),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to submit: $e'), backgroundColor: AppTheme.danger),
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
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFF0D1620),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isTenantTicket ? 'Resolve Tenant Work Order' : 'Submit AC Maintenance', 
                    style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context), 
                    icon: const Icon(Icons.close, color: Colors.blueGrey)
                  ),
                ],
              ),
              
              // Brief summary header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF060B10),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF1D3347)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${widget.task['building_name']}  •  Apt ${widget.task['apartment_code']}',
                      style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.task['title'] ?? (isTenantTicket ? 'Tenant Reported Issue' : 'Routine AC Cleaning'),
                      style: GoogleFonts.inter(color: Colors.amber.shade300, fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    if (widget.task['description'] != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        widget.task['description'].toString(),
                        style: GoogleFonts.inter(color: Colors.blueGrey.shade300, fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              // Photo Documentation
              Text('Photo Proof (Mandatory)', style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        const Text('1. Before Photo (Problem)', style: TextStyle(color: Colors.blueGrey, fontSize: 11)),
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: () => _pickImage(true),
                          child: Container(
                            height: 110,
                            decoration: BoxDecoration(
                              color: const Color(0xFF060B10), 
                              borderRadius: BorderRadius.circular(12), 
                              border: Border.all(color: _beforeImageBytes != null ? AppTheme.primary : const Color(0xFF1D3347))
                            ),
                            child: _beforeImageBytes != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(11),
                                    child: Image.memory(_beforeImageBytes!, fit: BoxFit.cover, width: double.infinity, height: 110),
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(Icons.camera_alt_outlined, color: Colors.blueGrey, size: 28),
                                      SizedBox(height: 4),
                                      Text('Capture Before', style: TextStyle(color: Colors.blueGrey, fontSize: 11)),
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
                      children: [
                        const Text('2. After Photo (Fixed)', style: TextStyle(color: Colors.blueGrey, fontSize: 11)),
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: () => _pickImage(false),
                          child: Container(
                            height: 110,
                            decoration: BoxDecoration(
                              color: const Color(0xFF060B10), 
                              borderRadius: BorderRadius.circular(12), 
                              border: Border.all(color: _afterImageBytes != null ? Colors.green : const Color(0xFF1D3347))
                            ),
                            child: _afterImageBytes != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(11),
                                    child: Image.memory(_afterImageBytes!, fit: BoxFit.cover, width: double.infinity, height: 110),
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(Icons.camera_alt_outlined, color: Colors.blueGrey, size: 28),
                                      SizedBox(height: 4),
                                      Text('Capture After', style: TextStyle(color: Colors.blueGrey, fontSize: 11)),
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
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: const InputDecoration(labelText: 'Labor Hours', labelStyle: TextStyle(color: Colors.blueGrey, fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _materialsController,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: const InputDecoration(labelText: 'Parts / Materials Used', labelStyle: TextStyle(color: Colors.blueGrey, fontSize: 12)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              TextField(
                controller: _notesController,
                maxLines: 3,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: const InputDecoration(
                  labelText: 'Resolution Notes & Fix Details *', 
                  labelStyle: TextStyle(color: Colors.blueGrey, fontSize: 12),
                  hintText: 'Describe what was repaired, replaced, or adjusted...',
                  hintStyle: TextStyle(color: Colors.white24, fontSize: 12),
                ),
              ),
              const SizedBox(height: 24),

              AsyncButton(
                text: isTenantTicket ? 'Mark Resolved & Submit Work' : 'Submit for Admin Approval',
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
