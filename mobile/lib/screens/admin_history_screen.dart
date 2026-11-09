import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_theme.dart';
import '../services/api_service.dart';
import '../widgets/mobile/enterprise_mobile_scaffold.dart';
import '../widgets/mobile/audit_timeline_widget.dart';

final adminHistoryDataProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  try {
    final agentRes = await ApiService().get('/energy/agent/history/generators');
    final maintRes = await ApiService().get('/maintenance/tasks');
    return {
      'agentHistory': (agentRes.data as List<dynamic>?) ?? [],
      'maintenanceHistory': (maintRes.data as List<dynamic>?) ?? [],
    };
  } catch (e) {
    return {'agentHistory': [], 'maintenanceHistory': []};
  }
});

class AdminHistoryScreen extends ConsumerStatefulWidget {
  const AdminHistoryScreen({super.key});

  @override
  ConsumerState<AdminHistoryScreen> createState() => _AdminHistoryScreenState();
}

class _AdminHistoryScreenState extends ConsumerState<AdminHistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

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

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(adminHistoryDataProvider);

    return EnterpriseMobileScaffold(
      title: 'Centralized Admin History Center',
      userRole: 'Admin',
      userName: 'Administrator',
      currentTabIndex: 2,
      body: Column(
        children: [
          Container(
            decoration: const BoxDecoration(
              color: AppTheme.surface,
              border: Border(bottom: BorderSide(color: AppTheme.border)),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorColor: AppTheme.primary,
              dividerColor: Colors.transparent,
              labelColor: AppTheme.textPrimary,
              unselectedLabelColor: AppTheme.textMuted,
              labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12.5),
              tabs: const [
                Tab(text: 'Agent History'),
                Tab(text: 'Maintenance History'),
                Tab(text: 'Tenant Requests'),
                Tab(text: 'Approvals'),
                Tab(text: 'Rejections'),
              ],
            ),
          ),
          Expanded(
            child: historyAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
              error: (err, _) => Center(child: Text('Error loading history: $err', style: const TextStyle(color: Colors.red))),
              data: (data) {
                final agentList = (data['agentHistory'] as List<dynamic>?) ?? [];
                final maintList = (data['maintenanceHistory'] as List<dynamic>?) ?? [];

                return TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 1: Agent History
                    _buildAgentHistoryList(agentList),
                    // Tab 2: Maintenance History
                    _buildMaintenanceHistoryList(maintList),
                    // Tab 3: Tenant Requests
                    _buildTenantRequestsList(),
                    // Tab 4: Approvals
                    _buildApprovalsList(agentList, maintList),
                    // Tab 5: Rejections
                    _buildRejectionsList(agentList, maintList),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgentHistoryList(List<dynamic> list) {
    if (list.isEmpty) {
      return Center(child: Text('No agent meter reading records found.', style: GoogleFonts.inter(color: Colors.blueGrey.shade400)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final item = list[index];
        final status = item['status'] ?? 'Pending Verification';

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
                  Text(
                    '${item['building_name']} • Gen Counter: ${item['generator_counter'] ?? 'N/A'}',
                    style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  _StatusChip(status: status),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Date: ${item['date'] ?? 'Today'} • Submitted by Agent ID #${item['submitted_by'] ?? '1'}',
                style: GoogleFonts.inter(color: Colors.blueGrey.shade400, fontSize: 11),
              ),
              const SizedBox(height: 12),
              AuditTimelineWidget(
                steps: [
                  TimelineStep(title: 'Reading Submitted', isCompleted: true, timestamp: item['date']),
                  TimelineStep(title: 'Photo Proof Uploaded', isCompleted: true),
                  TimelineStep(title: 'Admin Verification', isCompleted: status == 'Verified' || status == 'Approved', isCurrent: status == 'Pending Verification'),
                  TimelineStep(title: 'Archived', isCompleted: status == 'Verified'),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMaintenanceHistoryList(List<dynamic> list) {
    if (list.isEmpty) {
      return Center(child: Text('No maintenance completion records found.', style: GoogleFonts.inter(color: Colors.blueGrey.shade400)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final item = list[index];
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
              Text('${item['building_name']} - Work Order #${item['id']}', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('Description: ${item['description'] ?? 'General Repair'}', style: GoogleFonts.inter(color: Colors.blueGrey.shade300, fontSize: 12)),
              const SizedBox(height: 12),
              AuditTimelineWidget(
                steps: [
                  TimelineStep(title: 'Task Created & Assigned', isCompleted: true),
                  TimelineStep(title: 'Work Started by Technician', isCompleted: true),
                  TimelineStep(title: 'Before & After Photos Uploaded', isCompleted: true),
                  TimelineStep(title: 'Waiting Admin Approval', isCompleted: true, isCurrent: item['status'] == 'Waiting Approval'),
                  TimelineStep(title: 'Approved', isCompleted: item['status'] == 'Approved'),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTenantRequestsList() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: const Color(0xFF0D1620), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF1D3347))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Tenant Request #102 • Apt A3', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: Colors.amber.shade900.withOpacity(0.4), borderRadius: BorderRadius.circular(8)),
                    child: const Text('HIGH PRIORITY', style: TextStyle(color: Colors.amber, fontSize: 9, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text('Issue: AC Unit leaking water in bedroom.', style: GoogleFonts.inter(color: Colors.blueGrey.shade300, fontSize: 12)),
              const SizedBox(height: 12),
              AuditTimelineWidget(
                steps: [
                  TimelineStep(title: 'New Request Created by Tenant', isCompleted: true, timestamp: 'Yesterday'),
                  TimelineStep(title: 'Accepted & Assigned to Tech', isCompleted: true, timestamp: 'Today 08:00 AM'),
                  TimelineStep(title: 'In Progress', isCompleted: true, isCurrent: true),
                  TimelineStep(title: 'Work Completed & Approved', isCompleted: false),
                  TimelineStep(title: 'Ticket Closed', isCompleted: false),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildApprovalsList(List<dynamic> agent, List<dynamic> maint) {
    return Center(child: Text('Showing all approved history records (${agent.length + maint.length} Total)', style: GoogleFonts.inter(color: Colors.green.shade400)));
  }

  Widget _buildRejectionsList(List<dynamic> agent, List<dynamic> maint) {
    return Center(child: Text('Showing all rejected history records needing re-submission.', style: GoogleFonts.inter(color: Colors.red.shade400)));
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color = status == 'Verified' || status == 'Approved' ? Colors.green : (status == 'Rejected' ? Colors.red : Colors.amber);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold),
      ),
    );
  }
}
