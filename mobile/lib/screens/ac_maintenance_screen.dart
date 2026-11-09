import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/app_theme.dart';
import '../services/api_service.dart';
import '../widgets/mobile/enterprise_mobile_scaffold.dart';

List<dynamic> _extractListPayload(dynamic data, [List<String> keys = const ['data', 'tickets', 'tasks', 'history', 'reports', 'workers', 'users']]) {
  if (data is List) return data;
  if (data is String) {
    try {
      final decoded = jsonDecode(data);
      return _extractListPayload(decoded, keys);
    } catch (_) {
      return [];
    }
  }
  if (data is Map) {
    for (final k in keys) {
      if (data[k] is List) return data[k] as List<dynamic>;
    }
  }
  return [];
}

final adminTenantRequestsProvider = FutureProvider<List<dynamic>>((ref) async {
  try {
    final res = await ApiService().get('/maintenance-tickets/all');
    return _extractListPayload(res.data, const ['tickets', 'data']);
  } catch (e) {
    debugPrint('[AdminTenantRequests] Error fetching: $e');
    return [];
  }
});

final acPendingTasksProvider = FutureProvider<List<dynamic>>((ref) async {
  try {
    final res = await ApiService().get('/maintenance/admin/tasks');
    return _extractListPayload(res.data, const ['tasks', 'data']);
  } catch (_) {
    return [];
  }
});

final acHistoryTasksProvider = FutureProvider<List<dynamic>>((ref) async {
  try {
    final res = await ApiService().get('/maintenance/admin/history');
    return _extractListPayload(res.data, const ['history', 'data']);
  } catch (_) {
    return [];
  }
});

final acWorkerReportProvider = FutureProvider<List<dynamic>>((ref) async {
  // Fetch worker reports & users in parallel with fast timeouts, and also read already-fetched task providers
  final results = await Future.wait([
    ApiService()
        .get('/maintenance/admin/worker-reports')
        .timeout(const Duration(seconds: 4))
        .then<List<dynamic>>((r) => _extractListPayload(r.data, const ['reports', 'workers', 'data']))
        .catchError((_) => <dynamic>[]),
    ApiService()
        .get('/users')
        .timeout(const Duration(seconds: 4))
        .then<List<dynamic>>((r) => _extractListPayload(r.data, const ['users', 'data']))
        .catchError((_) => <dynamic>[]),
  ]);

  final rawWorkerReports = results[0];
  final allUsers = results[1];

  // Also grab tasks from the other maintenance providers (either already resolved or resolving)
  List<dynamic> tenantTickets = [];
  List<dynamic> acHistory = [];
  List<dynamic> acPending = [];
  try {
    tenantTickets = await ref.watch(adminTenantRequestsProvider.future);
  } catch (_) {}
  try {
    acHistory = await ref.watch(acHistoryTasksProvider.future);
  } catch (_) {}
  try {
    acPending = await ref.watch(acPendingTasksProvider.future);
  } catch (_) {}

  final Map<String, Map<String, dynamic>> workersByKey = {};
  final Map<String, Set<String>> workerSeenTaskKeys = {};

  String normalizeKey(dynamic id, dynamic name) {
    final cleanName = (name ?? '').toString().trim();
    if (cleanName.isNotEmpty && cleanName.toLowerCase() != 'unassigned' && cleanName.toLowerCase() != 'null') {
      return 'name_${cleanName.toLowerCase()}';
    }
    final cleanId = (id ?? '').toString().trim();
    if (cleanId.isNotEmpty && cleanId != '0' && cleanId.toLowerCase() != 'null') {
      return 'id_$cleanId';
    }
    return '';
  }

  Map<String, dynamic> ensureWorker(String key, {dynamic id, required String name, String roleLabel = 'Maintenance Technician'}) {
    return workersByKey.putIfAbsent(key, () {
      workerSeenTaskKeys[key] = <String>{};
      return {
        'worker_id': id ?? key,
        'worker_name': name,
        'role_label': roleLabel,
        'tasks': <Map<String, dynamic>>[],
      };
    });
  }

  void addTaskToWorker(String workerKey, Map<String, dynamic> task) {
    final w = workersByKey[workerKey];
    if (w == null) return;
    final taskType = (task['task_type'] ?? 'task').toString();
    final taskId = (task['id'] ?? '').toString();
    final dedupKey = '${taskType}_$taskId';
    final seen = workerSeenTaskKeys.putIfAbsent(workerKey, () => <String>{});
    if (taskId.isNotEmpty && !seen.add(dedupKey)) return;
    (w['tasks'] as List<Map<String, dynamic>>).add(task);
  }

  // 1. Seed from `/maintenance/admin/worker-reports`
  for (final raw in rawWorkerReports) {
    if (raw is! Map) continue;
    final wId = raw['worker_id'] ?? raw['id'];
    final wName = (raw['worker_name'] ?? raw['name'] ?? 'Maintenance Technician').toString().trim();
    final key = normalizeKey(wId, wName);
    if (key.isEmpty) continue;
    ensureWorker(key, id: wId, name: wName);
    if (raw['tasks'] is List) {
      for (final t in raw['tasks'] as List) {
        if (t is Map) {
          addTaskToWorker(key, Map<String, dynamic>.from(t));
        }
      }
    }
  }

  // 2. Seed from `/users` (all users with maintenance / technician role)
  for (final raw in allUsers) {
    if (raw is! Map) continue;
    final role = (raw['role'] ?? '').toString().trim().toLowerCase();
    if (role.contains('maint') || role.contains('tech') || role.contains('worker')) {
      final wId = raw['id'];
      final wName = (raw['name'] ?? raw['username'] ?? 'Technician').toString().trim();
      final key = normalizeKey(wId, wName);
      if (key.isNotEmpty) {
        ensureWorker(key, id: wId, name: wName);
      }
    }
  }

  // Build an ID-to-key lookup so tasks that only have worker_id match their named worker
  final Map<String, String> idToWorkerKey = {};
  workersByKey.forEach((k, v) {
    final wId = (v['worker_id'] ?? '').toString().trim();
    if (wId.isNotEmpty) idToWorkerKey[wId] = k;
  });

  String? defaultWorkerKey = workersByKey.keys.length == 1 ? workersByKey.keys.first : null;

  // 3. Merge tasks from Tenant Maintenance Tickets
  for (final raw in tenantTickets) {
    if (raw is! Map) continue;
    final wId = (raw['worker_id'] ?? '').toString().trim();
    final wName = (raw['worker_name'] ?? '').toString().trim();
    final status = (raw['status'] ?? 'Open').toString();
    final isHandled = status == 'Resolved' ||
        status == 'Closed' ||
        status == 'In Progress' ||
        status == 'Assigned' ||
        status == 'Pending_Approval' ||
        wId.isNotEmpty ||
        wName.isNotEmpty;
    if (!isHandled) continue;

    String key = '';
    if (wId.isNotEmpty && idToWorkerKey.containsKey(wId)) {
      key = idToWorkerKey[wId]!;
    } else {
      key = normalizeKey(wId, wName);
    }

    if (key.isEmpty) {
      if (defaultWorkerKey != null) {
        key = defaultWorkerKey;
      } else {
        key = 'team_maintenance';
        ensureWorker(key, id: 0, name: 'Field Maintenance Team', roleLabel: 'Maintenance Operations');
      }
    } else if (!workersByKey.containsKey(key)) {
      ensureWorker(key, id: wId, name: wName.isNotEmpty ? wName : 'Technician #$wId');
    }

    addTaskToWorker(key, {
      'id': raw['id'],
      'task_type': 'tenant_ticket',
      'title': (raw['title'] ?? raw['category'] ?? 'Tenant Maintenance').toString(),
      'notes': (raw['worker_notes'] ?? raw['description'] ?? '').toString(),
      'status': status,
      'submission_date': (raw['completion_date'] ?? raw['resolved_at'] ?? raw['created_at'] ?? '').toString(),
      'apartment_code': (raw['apartment_code'] ?? 'N/A').toString(),
      'building_name': (raw['building_name'] ?? 'Building').toString(),
    });
  }

  // 4. Merge tasks from AC Maintenance History + Pending Approvals
  for (final raw in [...acPending, ...acHistory]) {
    if (raw is! Map) continue;
    final wId = (raw['worker_id'] ?? '').toString().trim();
    final wName = (raw['worker_name'] ?? '').toString().trim();
    final status = (raw['status'] ?? 'Scheduled').toString();
    final isWork = status == 'Completed' ||
        status == 'Approved' ||
        status == 'Pending_Approval' ||
        status == 'Pending Approval' ||
        wId.isNotEmpty ||
        wName.isNotEmpty;
    if (!isWork) continue;

    String key = '';
    if (wId.isNotEmpty && idToWorkerKey.containsKey(wId)) {
      key = idToWorkerKey[wId]!;
    } else {
      key = normalizeKey(wId, wName);
    }

    if (key.isEmpty) {
      if (defaultWorkerKey != null) {
        key = defaultWorkerKey;
      } else {
        key = 'team_maintenance';
        ensureWorker(key, id: 0, name: 'Field Maintenance Team', roleLabel: 'Maintenance Operations');
      }
    } else if (!workersByKey.containsKey(key)) {
      ensureWorker(key, id: wId, name: wName.isNotEmpty ? wName : 'Technician #$wId');
    }

    addTaskToWorker(key, {
      'id': raw['id'],
      'task_type': 'routine_ac',
      'title': 'Routine AC Cleaning',
      'notes': (raw['notes'] ?? '').toString(),
      'status': status,
      'submission_date': (raw['completion_date'] ?? raw['submission_date'] ?? raw['scheduled_date'] ?? raw['created_at'] ?? '').toString(),
      'apartment_code': (raw['apartment_code'] ?? 'N/A').toString(),
      'building_name': (raw['building_name'] ?? 'Building').toString(),
    });
  }

  // Finalize report entries and compute counts
  final List<Map<String, dynamic>> finalReports = [];
  for (final entry in workersByKey.values) {
    final tasks = List<Map<String, dynamic>>.from(entry['tasks'] as List);
    tasks.sort((a, b) => (b['submission_date'] ?? '').toString().compareTo((a['submission_date'] ?? '').toString()));

    int completedCount = 0;
    int pendingCount = 0;
    for (final t in tasks) {
      final st = (t['status'] ?? '').toString().toLowerCase();
      if (st == 'completed' || st == 'approved' || st == 'resolved' || st == 'closed') {
        completedCount++;
      } else {
        pendingCount++;
      }
    }

    finalReports.add({
      'worker_id': entry['worker_id'],
      'worker_name': entry['worker_name'],
      'role_label': entry['role_label'] ?? 'Maintenance Technician',
      'tasks_count': tasks.length,
      'completed_count': completedCount,
      'pending_count': pendingCount,
      'tasks': tasks,
    });
  }

  finalReports.sort((a, b) => ((b['tasks_count'] as int?) ?? 0).compareTo((a['tasks_count'] as int?) ?? 0));
  return finalReports;
});

class ACMaintenanceScreen extends ConsumerStatefulWidget {
  const ACMaintenanceScreen({super.key});

  @override
  ConsumerState<ACMaintenanceScreen> createState() => _ACMaintenanceScreenState();
}

class _ACMaintenanceScreenState extends ConsumerState<ACMaintenanceScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _tenantFilter = 'All'; // 'All', 'Active', 'Resolved'

  /// Bounded in-memory cache of decoded base64 image bytes so scrolling never re-decodes photos on UI frames
  static final LinkedHashMap<int, Uint8List> _decodedPhotoCache = LinkedHashMap<int, Uint8List>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _refreshAll() {
    ApiService().clearCache();
    ref.invalidate(adminTenantRequestsProvider);
    ref.invalidate(acPendingTasksProvider);
    ref.invalidate(acHistoryTasksProvider);
    ref.invalidate(acWorkerReportProvider);
  }

  Widget _buildPhotoThumbnail(String label, String? imgStr) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.blueGrey, fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () {
              if (imgStr != null && imgStr.trim().isNotEmpty) {
                _showFullPhotoDialog(label, imgStr);
              }
            },
            child: Container(
              height: 110,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF060B10),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF1D3347)),
              ),
              child: _renderImage(imgStr),
            ),
          ),
        ],
      ),
    );
  }

  Widget _renderImage(String? imgStr) {
    if (imgStr == null || imgStr.trim().isEmpty) {
      return const Center(child: Text('No Photo', style: TextStyle(color: Colors.blueGrey, fontSize: 11)));
    }

    if (imgStr.startsWith('data:image') || imgStr.length > 200) {
      try {
        final key = imgStr.hashCode;
        Uint8List? bytes = _decodedPhotoCache[key];
        if (bytes == null) {
          final cleanBase64 = imgStr.contains(',') ? imgStr.split(',').last : imgStr;
          bytes = base64Decode(cleanBase64.replaceAll(RegExp(r'\s+'), ''));
          if (_decodedPhotoCache.length >= 30) {
            _decodedPhotoCache.remove(_decodedPhotoCache.keys.first);
          }
          _decodedPhotoCache[key] = bytes;
        }
        return ClipRRect(
          borderRadius: BorderRadius.circular(11),
          child: Image.memory(
            bytes,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            cacheWidth: 480,
            gaplessPlayback: true,
          ),
        );
      } catch (_) {}
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(11),
      child: Image.network(
        imgStr,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => const Center(child: Text('Photo Error', style: TextStyle(color: Colors.red, fontSize: 11))),
      ),
    );
  }

  void _showFullPhotoDialog(String title, String imgStr) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF060B10),
        insetPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  IconButton(icon: const Icon(Icons.close, color: Colors.white70), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
            ),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.7),
              child: _renderImage(imgStr),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Future<void> _updateTicketStatus(int ticketId, String newStatus) async {
    try {
      await ApiService().put('/maintenance-tickets/$ticketId/status', data: {
        'status': newStatus,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ticket status updated to $newStatus ✓'), backgroundColor: Colors.green),
        );
        ref.invalidate(adminTenantRequestsProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating status: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tenantReqAsync = ref.watch(adminTenantRequestsProvider);
    final pendingAsync = ref.watch(acPendingTasksProvider);
    final historyAsync = ref.watch(acHistoryTasksProvider);
    final workerReportAsync = ref.watch(acWorkerReportProvider);

    return EnterpriseMobileScaffold(
      title: 'Maintenance Operations Hub',
      userRole: 'Admin',
      userName: 'Administrator',
      currentTabIndex: 0,
      body: RefreshIndicator(
        onRefresh: () async => _refreshAll(),
        color: AppTheme.primary,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              color: const Color(0xFF0D1620),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Maintenance Oversight',
                          style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00A884),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.engineering_rounded, size: 15),
                            label: const Text('Field Board', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            onPressed: () => context.go('/maintenance-dashboard'),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.refresh, color: AppTheme.primary, size: 20),
                            onPressed: () => _refreshAll(),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    indicatorColor: AppTheme.primary,
                    dividerColor: Colors.transparent,
                    labelColor: AppTheme.textPrimary,
                    unselectedLabelColor: AppTheme.textMuted,
                    labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12.5),
                    tabs: [
                      Tab(
                        child: Row(
                          children: [
                            const Icon(Icons.person_pin_circle_outlined, size: 16),
                            const SizedBox(width: 6),
                            const Text('Tenant Requests'),
                            tenantReqAsync.maybeWhen(
                              data: (list) {
                                final active = list.where((x) => x['status'] != 'Resolved' && x['status'] != 'Closed').length;
                                if (active == 0) return const SizedBox.shrink();
                                return Container(
                                  margin: const EdgeInsets.only(left: 6),
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(10)),
                                  child: Text('$active', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                                );
                              },
                              orElse: () => const SizedBox.shrink(),
                            ),
                          ],
                        ),
                      ),
                      const Tab(child: Row(children: [Icon(Icons.hourglass_top, size: 16), SizedBox(width: 6), Text('Pending Approvals')])),
                      const Tab(child: Row(children: [Icon(Icons.history, size: 16), SizedBox(width: 6), Text('Maintenance History')])),
                      const Tab(child: Row(children: [Icon(Icons.calendar_month, size: 16), SizedBox(width: 6), Text('Scheduled Tasks')])),
                      const Tab(child: Row(children: [Icon(Icons.badge, size: 16), SizedBox(width: 6), Text('Worker Report')])),
                    ],
                  ),
                ],
              ),
            ),

            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // ── Tab 0: Tenant Maintenance Requests ──
                  tenantReqAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
                    error: (err, _) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
                    data: (tickets) {
                      final filteredTickets = tickets.where((t) {
                        final st = (t['status'] ?? '').toString();
                        if (_tenantFilter == 'Active') return st != 'Resolved' && st != 'Closed';
                        if (_tenantFilter == 'Resolved') return st == 'Resolved' || st == 'Closed';
                        return true;
                      }).toList();

                      return Column(
                        children: [
                          // Filter bar
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            color: const Color(0xFF060B10),
                            child: Row(
                              children: [
                                for (final f in ['All', 'Active', 'Resolved'])
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: ChoiceChip(
                                      label: Text(f, style: TextStyle(fontSize: 11, color: _tenantFilter == f ? Colors.white : Colors.blueGrey.shade300)),
                                      selected: _tenantFilter == f,
                                      selectedColor: const Color(0xFF00A884),
                                      backgroundColor: const Color(0xFF0D1620),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      onSelected: (val) {
                                        if (val) setState(() => _tenantFilter = f);
                                      },
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          Expanded(
                            child: filteredTickets.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.task_alt, size: 48, color: Colors.green),
                                        const SizedBox(height: 10),
                                        Text('No tenant requests found', style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                        Text('All tenant work orders are completed.', style: GoogleFonts.inter(color: Colors.blueGrey.shade400, fontSize: 12)),
                                      ],
                                    ),
                                  )
                                : ListView.builder(
                                    padding: const EdgeInsets.all(16),
                                    itemCount: filteredTickets.length,
                                    itemBuilder: (context, index) {
                                      final t = filteredTickets[index] as Map<String, dynamic>;
                                      final ticketId = t['id'] is int ? t['id'] : int.tryParse(t['id'].toString()) ?? 0;
                                      final building = t['building_name'] ?? 'Building';
                                      final apt = t['apartment_code'] ?? 'N/A';
                                      final priority = (t['priority'] ?? 'Medium').toString();
                                      final isUrgent = priority.toLowerCase() == 'urgent' || priority.toLowerCase() == 'high';
                                      final status = (t['status'] ?? 'Open').toString();
                                      final isResolved = status == 'Resolved' || status == 'Closed';
                                      final category = (t['category'] ?? 'General Maintenance').toString();
                                      final tenantName = t['tenant_name'] ?? 'Tenant';
                                      final tenantPhone = t['tenant_phone']?.toString();
                                      final desc = (t['description'] ?? '').toString();
                                      final title = (t['title'] ?? 'Tenant Request').toString();
                                      final hasPhotos = t['before_photo'] != null || t['after_photo'] != null;

                                      return Container(
                                        margin: const EdgeInsets.only(bottom: 16),
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF0D1620),
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(
                                            color: isUrgent
                                                ? Colors.redAccent.withValues(alpha: 0.6)
                                                : (isResolved ? Colors.green.withValues(alpha: 0.4) : const Color(0xFF1D3347)),
                                            width: isUrgent ? 1.5 : 1.0,
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            // Badges row
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Row(
                                                  children: [
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                      decoration: BoxDecoration(
                                                        color: Colors.indigo.withValues(alpha: 0.25),
                                                        borderRadius: BorderRadius.circular(6),
                                                        border: Border.all(color: Color(0xFF00D4AA).withValues(alpha: 0.4)),
                                                      ),
                                                      child: Text(category, style: const TextStyle(color: Color(0xFF00D4AA), fontSize: 10, fontWeight: FontWeight.bold)),
                                                    ),
                                                    const SizedBox(width: 6),
                                                    if (isUrgent)
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                                        decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
                                                        child: Row(
                                                          mainAxisSize: MainAxisSize.min,
                                                          children: [
                                                            const Icon(Icons.local_fire_department, size: 12, color: Colors.redAccent),
                                                            const SizedBox(width: 2),
                                                            Text(priority.toUpperCase(), style: const TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                                                          ],
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                  decoration: BoxDecoration(
                                                    color: isResolved ? Colors.green.withValues(alpha: 0.2) : Colors.amber.withValues(alpha: 0.2),
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Text(status.toUpperCase(), style: TextStyle(color: isResolved ? Colors.greenAccent : Colors.amberAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                                                ),
                                              ],
                                            ),

                                            const SizedBox(height: 10),

                                            // Building & Apartment
                                            Row(
                                              children: [
                                                const Icon(Icons.apartment_rounded, size: 16, color: AppTheme.primary),
                                                const SizedBox(width: 6),
                                                Text('$building • Apt $apt', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                                              ],
                                            ),

                                            const SizedBox(height: 6),

                                            // Tenant & Phone
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Row(
                                                  children: [
                                                    const Icon(Icons.person_outline, size: 14, color: Colors.blueGrey),
                                                    const SizedBox(width: 4),
                                                    Text(tenantName, style: TextStyle(color: Colors.blueGrey.shade200, fontSize: 12, fontWeight: FontWeight.w600)),
                                                  ],
                                                ),
                                                if (tenantPhone != null && tenantPhone.isNotEmpty)
                                                  InkWell(
                                                    onTap: () => launchUrl(Uri.parse('tel:$tenantPhone')),
                                                    child: Row(
                                                      children: [
                                                        const Icon(Icons.phone_rounded, size: 13, color: AppTheme.primary),
                                                        const SizedBox(width: 4),
                                                        Text(tenantPhone, style: const TextStyle(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                                                      ],
                                                    ),
                                                  ),
                                              ],
                                            ),

                                            const SizedBox(height: 10),

                                            // Title & Description Box
                                            Container(
                                              width: double.infinity,
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF060B10),
                                                borderRadius: BorderRadius.circular(10),
                                                border: Border.all(color: const Color(0xFF1D3347).withValues(alpha: 0.5)),
                                              ),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                                  if (desc.isNotEmpty) ...[
                                                    const SizedBox(height: 4),
                                                    Text(desc, style: TextStyle(color: Colors.blueGrey.shade300, fontSize: 12)),
                                                  ],
                                                ],
                                              ),
                                            ),

                                            // Worker proof if technician resolved it
                                            if (hasPhotos || (t['worker_notes'] != null && t['worker_notes'].toString().isNotEmpty)) ...[
                                              const SizedBox(height: 12),
                                              Container(
                                                padding: const EdgeInsets.all(10),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF064E3B).withValues(alpha: 0.2),
                                                  borderRadius: BorderRadius.circular(10),
                                                  border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                                                ),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        const Icon(Icons.verified, size: 14, color: Colors.greenAccent),
                                                        const SizedBox(width: 6),
                                                        Text(
                                                          'Technician Proof ${t['worker_name'] != null ? "• " + t['worker_name'].toString() : ""}',
                                                          style: const TextStyle(color: Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.bold),
                                                        ),
                                                      ],
                                                    ),
                                                    if (t['worker_notes'] != null && t['worker_notes'].toString().isNotEmpty) ...[
                                                      const SizedBox(height: 4),
                                                      Text('Notes: ${t['worker_notes']}', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                                                    ],
                                                    if (hasPhotos) ...[
                                                      const SizedBox(height: 8),
                                                      Row(
                                                        children: [
                                                          if (t['before_photo'] != null)
                                                            _buildPhotoThumbnail('BEFORE PHOTO', t['before_photo'].toString()),
                                                          if (t['before_photo'] != null && t['after_photo'] != null)
                                                            const SizedBox(width: 8),
                                                          if (t['after_photo'] != null)
                                                            _buildPhotoThumbnail('AFTER PHOTO', t['after_photo'].toString()),
                                                        ],
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              ),
                                            ],

                                            const SizedBox(height: 12),

                                            // Action Buttons
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.end,
                                              children: [
                                                if (!isResolved) ...[
                                                  OutlinedButton(
                                                    style: OutlinedButton.styleFrom(
                                                      foregroundColor: Colors.redAccent,
                                                      side: const BorderSide(color: Colors.redAccent),
                                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                    ),
                                                    onPressed: () => _updateTicketStatus(ticketId, 'Rejected'),
                                                    child: const Text('Reject', style: TextStyle(fontSize: 11)),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  if (status == 'Open')
                                                    ElevatedButton(
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor: Colors.amber.shade800,
                                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                      ),
                                                      onPressed: () => _updateTicketStatus(ticketId, 'In Progress'),
                                                      child: const Text('In Progress', style: TextStyle(fontSize: 11, color: Colors.white)),
                                                    ),
                                                  const SizedBox(width: 8),
                                                  ElevatedButton.icon(
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: const Color(0xFF10B981),
                                                      foregroundColor: Colors.white,
                                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                    ),
                                                    icon: const Icon(Icons.check, size: 14),
                                                    label: const Text('Resolve', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                                    onPressed: () => _updateTicketStatus(ticketId, 'Resolved'),
                                                  ),
                                                ] else ...[
                                                  TextButton.icon(
                                                    icon: const Icon(Icons.replay, size: 14, color: Colors.amberAccent),
                                                    label: const Text('Reopen Ticket', style: TextStyle(color: Colors.amberAccent, fontSize: 11)),
                                                    onPressed: () => _updateTicketStatus(ticketId, 'Open'),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      );
                    },
                  ),

                  // ── Tab 1: Pending Approvals (AC Tasks) ──
                  pendingAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
                    error: (err, _) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
                    data: (tasks) {
                      if (tasks.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check_circle_outline, size: 56, color: Colors.green),
                              const SizedBox(height: 12),
                              Text('No Pending Approvals', style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text('All submitted AC maintenance tasks have been reviewed.', style: GoogleFonts.inter(color: Colors.blueGrey.shade400, fontSize: 12)),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: tasks.length,
                        itemBuilder: (context, index) {
                          final t = tasks[index] as Map<String, dynamic>;
                          final taskId = t['id'];
                          final building = t['building_name'] ?? 'Building';
                          final apt = t['apartment_code'] ?? 'N/A';
                          final worker = t['worker_name'] ?? 'Worker';
                          final scheduledDate = t['scheduled_date'] ?? 'N/A';
                          final submissionDate = t['submission_date'] ?? 'Just now';
                          final notes = t['notes'] ?? 'No notes provided';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0D1620),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFF1D3347)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('$building - Apt $apt', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(color: Colors.amber.shade900.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(6)),
                                      child: const Text('PENDING APPROVAL', style: TextStyle(color: Colors.amberAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text('Technician: $worker', style: TextStyle(color: Colors.blueGrey.shade300, fontSize: 12, fontWeight: FontWeight.w600)),
                                Text('Scheduled: $scheduledDate • Submitted: $submissionDate', style: TextStyle(color: Colors.blueGrey.shade400, fontSize: 11)),
                                const SizedBox(height: 12),

                                Row(
                                  children: [
                                    _buildPhotoThumbnail('BEFORE PHOTO', t['before_photo']?.toString()),
                                    const SizedBox(width: 10),
                                    _buildPhotoThumbnail('AFTER PHOTO', t['after_photo']?.toString()),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(color: const Color(0xFF060B10), borderRadius: BorderRadius.circular(10)),
                                  child: Text('Notes: $notes', style: TextStyle(color: Colors.blueGrey.shade200, fontSize: 12)),
                                ),
                                const SizedBox(height: 14),

                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.redAccent,
                                          side: const BorderSide(color: Colors.redAccent),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        ),
                                        icon: const Icon(Icons.close, size: 16),
                                        label: const Text('Reject'),
                                        onPressed: () async {
                                          try {
                                            await ApiService().post('/maintenance/admin/tasks/$taskId/reject');
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Task Rejected ✓'), backgroundColor: Colors.red));
                                              _refreshAll();
                                            }
                                          } catch (e) {
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                                            }
                                          }
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green.shade700,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        ),
                                        icon: const Icon(Icons.check, size: 16, color: Colors.white),
                                        label: const Text('Approve', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                        onPressed: () async {
                                          try {
                                            await ApiService().post('/maintenance/admin/tasks/$taskId/approve');
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Task Approved ✓'), backgroundColor: Colors.green));
                                              _refreshAll();
                                            }
                                          } catch (e) {
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                                            }
                                          }
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),

                  // ── Tab 2: Maintenance History ──
                  historyAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
                    error: (err, _) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
                    data: (historyList) {
                      if (historyList.isEmpty) {
                        return Center(child: Text('No maintenance history recorded.', style: GoogleFonts.inter(color: Colors.blueGrey.shade400)));
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: historyList.length,
                        itemBuilder: (context, index) {
                          final h = historyList[index] as Map<String, dynamic>;
                          final status = (h['status'] ?? 'Scheduled').toString();
                          final isCompleted = status == 'Completed' || status == 'Approved';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0D1620),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFF1D3347)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(color: isCompleted ? Colors.green.withValues(alpha: 0.2) : Colors.amber.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
                                  child: Icon(isCompleted ? Icons.check_circle : Icons.schedule, color: isCompleted ? Colors.greenAccent : Colors.amberAccent, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('${h['building_name']} - Apt ${h['apartment_code']}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                      Text('Worker: ${h['worker_name'] ?? 'Unassigned'} • Scheduled: ${h['scheduled_date'] ?? 'N/A'}', style: TextStyle(color: Colors.blueGrey.shade300, fontSize: 11)),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(color: isCompleted ? Colors.green.shade900 : Color(0xFF073B32), borderRadius: BorderRadius.circular(6)),
                                  child: Text(status.toUpperCase(), style: TextStyle(color: isCompleted ? Colors.greenAccent : Color(0xFF00D4AA), fontSize: 9, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),

                  // ── Tab 3: Scheduled Tasks ──
                  historyAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
                    error: (err, _) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
                    data: (historyList) {
                      final scheduledTasks = historyList.where((h) => h['status'] == 'Scheduled').toList();

                      return Column(
                        children: [
                          Container(
                            margin: const EdgeInsets.all(16),
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, padding: const EdgeInsets.symmetric(vertical: 12)),
                              icon: const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
                              label: const Text('Generate Smart Schedules', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              onPressed: () async {
                                try {
                                  await ApiService().post('/maintenance/admin/buildings/1/generate');
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Smart schedules generated! ✓'), backgroundColor: Colors.green));
                                    _refreshAll();
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Status: $e')));
                                  }
                                }
                              },
                            ),
                          ),
                          Expanded(
                            child: scheduledTasks.isEmpty
                                ? Center(child: Text('No upcoming scheduled tasks.', style: GoogleFonts.inter(color: Colors.blueGrey.shade400)))
                                : ListView.builder(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    itemCount: scheduledTasks.length,
                                    itemBuilder: (context, index) {
                                      final s = scheduledTasks[index] as Map<String, dynamic>;
                                      return Container(
                                        margin: const EdgeInsets.only(bottom: 10),
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(color: const Color(0xFF0D1620), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF1D3347))),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text('${s['building_name']} - Apt ${s['apartment_code']}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                            Text('Scheduled: ${s['scheduled_date']}', style: const TextStyle(color: Colors.amberAccent, fontSize: 11)),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      );
                    },
                  ),

                  // ── Tab 4: Worker Report ──
                  workerReportAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
                    error: (err, _) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
                    data: (reports) {
                      if (reports.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.badge_outlined, size: 44, color: AppTheme.textMuted),
                              const SizedBox(height: 10),
                              Text('No worker reports found.', style: GoogleFonts.inter(color: Colors.blueGrey.shade400)),
                            ],
                          ),
                        );
                      }

                      final totalCompleted = reports.fold<int>(
                        0,
                        (sum, r) => sum + (((r as Map)['completed_count'] as int?) ?? ((r['tasks_count'] as int?) ?? 0)),
                      );
                      final totalPending = reports.fold<int>(
                        0,
                        (sum, r) => sum + (((r as Map)['pending_count'] as int?) ?? 0),
                      );

                      return Column(
                        children: [
                          Container(
                            margin: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppTheme.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppTheme.border),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildWorkerKpiPill('Technicians', '${reports.length}', AppTheme.primary),
                                Container(width: 1, height: 26, color: AppTheme.border),
                                _buildWorkerKpiPill('Completed', '$totalCompleted', AppTheme.success),
                                Container(width: 1, height: 26, color: AppTheme.border),
                                _buildWorkerKpiPill('In Queue', '$totalPending', AppTheme.warning),
                              ],
                            ),
                          ),
                          Expanded(
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: reports.length,
                              itemBuilder: (context, index) {
                                final r = Map<String, dynamic>.from(reports[index] as Map);
                                final workerName = (r['worker_name'] ?? 'Technician').toString();
                                final roleLabel = (r['role_label'] ?? 'Maintenance Technician').toString();
                                final count = (r['tasks_count'] as int?) ?? 0;
                                final completedCount = (r['completed_count'] as int?) ?? count;
                                final pendingCount = (r['pending_count'] as int?) ?? 0;
                                final tasks = (r['tasks'] is List) ? (r['tasks'] as List) : const [];

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 14),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0D1620),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: const Color(0xFF1D3347)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Row(
                                              children: [
                                                CircleAvatar(
                                                  radius: 20,
                                                  backgroundColor: const Color(0xFF00A884).withValues(alpha: 0.2),
                                                  child: Text(
                                                    workerName.isNotEmpty ? workerName[0].toUpperCase() : 'W',
                                                    style: GoogleFonts.outfit(
                                                      color: AppTheme.primary,
                                                      fontWeight: FontWeight.w700,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        workerName,
                                                        style: GoogleFonts.outfit(
                                                          color: Colors.white,
                                                          fontWeight: FontWeight.w700,
                                                          fontSize: 15,
                                                        ),
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        roleLabel,
                                                        style: TextStyle(color: Colors.blueGrey.shade400, fontSize: 11.5),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF073B32),
                                                  borderRadius: BorderRadius.circular(9),
                                                ),
                                                child: Text(
                                                  '$completedCount Done',
                                                  style: const TextStyle(
                                                    color: Color(0xFF00D4AA),
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 11,
                                                  ),
                                                ),
                                              ),
                                              if (pendingCount > 0) ...[
                                                const SizedBox(width: 6),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                                                  decoration: BoxDecoration(
                                                    color: Colors.amber.withValues(alpha: 0.16),
                                                    borderRadius: BorderRadius.circular(9),
                                                  ),
                                                  child: Text(
                                                    '$pendingCount Active',
                                                    style: const TextStyle(
                                                      color: Colors.amberAccent,
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 11,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ],
                                      ),
                                      if (tasks.isNotEmpty) ...[
                                        const SizedBox(height: 12),
                                        const Divider(color: Color(0xFF1D3347), height: 1),
                                        const SizedBox(height: 10),
                                        ...tasks.take(6).map((rawTask) {
                                          final t = rawTask is Map ? Map<String, dynamic>.from(rawTask) : <String, dynamic>{};
                                          final bld = (t['building_name'] ?? 'Building').toString();
                                          final apt = (t['apartment_code'] ?? 'N/A').toString();
                                          final title = (t['title'] ?? 'Maintenance Task').toString();
                                          final st = (t['status'] ?? 'Completed').toString();
                                          final dateStr = (t['submission_date'] ?? t['completion_date'] ?? t['created_at'] ?? '')
                                              .toString()
                                              .split(' ')
                                              .first;
                                          final isDone = st == 'Completed' || st == 'Approved' || st == 'Resolved' || st == 'Closed';

                                          return Padding(
                                            padding: const EdgeInsets.only(bottom: 8),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF060B10),
                                                borderRadius: BorderRadius.circular(10),
                                                border: Border.all(color: const Color(0xFF1D3347).withValues(alpha: 0.7)),
                                              ),
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    isDone ? Icons.check_circle_rounded : Icons.schedule_rounded,
                                                    size: 15,
                                                    color: isDone ? AppTheme.primary : Colors.amberAccent,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          '$bld • Apt $apt — $title',
                                                          style: GoogleFonts.inter(
                                                            color: Colors.white,
                                                            fontSize: 12,
                                                            fontWeight: FontWeight.w600,
                                                          ),
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                        if (dateStr.isNotEmpty)
                                                          Text(
                                                            'Date: $dateStr',
                                                            style: TextStyle(color: Colors.blueGrey.shade400, fontSize: 10.5),
                                                          ),
                                                      ],
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                                    decoration: BoxDecoration(
                                                      color: isDone
                                                          ? AppTheme.primary.withValues(alpha: 0.14)
                                                          : Colors.amber.withValues(alpha: 0.15),
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: Text(
                                                      st.toUpperCase(),
                                                      style: TextStyle(
                                                        color: isDone ? AppTheme.primary : Colors.amberAccent,
                                                        fontSize: 9.5,
                                                        fontWeight: FontWeight.w700,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        }),
                                      ],
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkerKpiPill(String label, String value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: GoogleFonts.outfit(
            color: color,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.inter(
            color: AppTheme.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
