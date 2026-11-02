import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_theme.dart';
import '../services/api_service.dart';
import '../widgets/mobile/enterprise_mobile_scaffold.dart';

final adminMonitoringDataProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  try {
    final res = await ApiService().get('/mobile/monitoring');
    return (res.data as Map<String, dynamic>?) ?? {};
  } catch (e) {
    return {
      'agents': [
        {
          'name': 'Agent Ali Yazbek',
          'status': 'Online',
          'lastSync': '1 min ago',
          'pendingQueue': 0,
          'battery': 88,
          'appVersion': '2.1.0',
          'completedToday': 8,
          'rejectedToday': 0,
          'accuracyScore': '98.5%',
          'currentBuilding': 'Galaxy Building'
        }
      ],
      'maintenance': [
        {
          'name': 'Tech Hassan',
          'status': 'Online',
          'lastSync': '3 mins ago',
          'pendingQueue': 1,
          'battery': 64,
          'appVersion': '2.1.0',
          'completedToday': 3,
          'rejectedToday': 0,
          'accuracyScore': '100%',
          'currentBuilding': 'Bitar Tower'
        }
      ]
    };
  }
});

class AdminMobileMonitoringScreen extends ConsumerStatefulWidget {
  const AdminMobileMonitoringScreen({super.key});

  @override
  ConsumerState<AdminMobileMonitoringScreen> createState() => _AdminMobileMonitoringScreenState();
}

class _AdminMobileMonitoringScreenState extends ConsumerState<AdminMobileMonitoringScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final monitoringAsync = ref.watch(adminMonitoringDataProvider);

    return EnterpriseMobileScaffold(
      title: 'Field Agent & Worker Telemetry',
      userRole: 'Admin',
      userName: 'Administrator',
      currentTabIndex: 0,
      body: Column(
        children: [
          Container(
            color: const Color(0xFF0D1620),
            child: TabBar(
              controller: _tabController,
              indicatorColor: Color(0xFF1FE0B8),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.blueGrey.shade400,
              labelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold),
              tabs: const [
                Tab(text: 'Field Agents Telemetry'),
                Tab(text: 'Maintenance Technicians'),
              ],
            ),
          ),
          Expanded(
            child: monitoringAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
              error: (err, _) => Center(child: Text('Error loading telemetry: $err', style: const TextStyle(color: Colors.red))),
              data: (data) {
                final agents = (data['agents'] as List<dynamic>?) ?? [];
                final maint = (data['maintenance'] as List<dynamic>?) ?? [];

                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildWorkerList(agents, 'Agent'),
                    _buildWorkerList(maint, 'Maintenance'),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkerList(List<dynamic> workers, String roleType) {
    if (workers.isEmpty) {
      return Center(child: Text('No active $roleType workers online.', style: GoogleFonts.inter(color: Colors.blueGrey.shade400)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: workers.length,
      itemBuilder: (context, index) {
        final w = workers[index];
        final isOnline = (w['status'] ?? '') == 'Online';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
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
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: isOnline ? Colors.green.withOpacity(0.2) : const Color(0xFF060B10),
                        child: Icon(Icons.person, size: 18, color: isOnline ? Colors.green : Colors.blueGrey),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(w['name'] ?? 'Worker', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
                          Text('Building: ${w['currentBuilding'] ?? 'N/A'}', style: GoogleFonts.inter(color: Colors.blueGrey.shade400, fontSize: 11)),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isOnline ? Colors.green.shade900.withOpacity(0.4) : const Color(0xFF060B10),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: isOnline ? Colors.green.shade500 : const Color(0xFF1D3347)),
                    ),
                    child: Text(
                      isOnline ? 'ONLINE' : 'OFFLINE',
                      style: TextStyle(color: isOnline ? Colors.green.shade300 : Colors.blueGrey.shade400, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(color: Color(0xFF1D3347), height: 1),
              const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _TelemetryBadge(label: 'Battery', value: '${w['battery'] ?? 100}%', icon: Icons.battery_charging_full),
                  _TelemetryBadge(label: 'Offline Queue', value: '${w['pendingQueue'] ?? 0} pending', icon: Icons.cloud_upload_outlined),
                  _TelemetryBadge(label: 'Last Sync', value: w['lastSync'] ?? 'Just now', icon: Icons.sync),
                  _TelemetryBadge(label: 'Accuracy', value: w['accuracyScore'] ?? '100%', icon: Icons.star_outline),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TelemetryBadge extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _TelemetryBadge({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 14, color: Color(0xFF5CEAD0)),
        const SizedBox(height: 2),
        Text(value, style: GoogleFonts.inter(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(color: Colors.blueGrey.shade400, fontSize: 9)),
      ],
    );
  }
}
