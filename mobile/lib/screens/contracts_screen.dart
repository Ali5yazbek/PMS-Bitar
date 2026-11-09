import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_theme.dart';
import '../services/api_service.dart';
import '../widgets/mobile/enterprise_mobile_scaffold.dart';

final contractsListProvider = FutureProvider<List<dynamic>>((ref) async {
  try {
    final res = await ApiService().get('/contracts');
    final data = res.data;
    if (data is List) return data;
    return [];
  } catch (_) {
    return [];
  }
});

class ContractsScreen extends ConsumerStatefulWidget {
  const ContractsScreen({super.key});

  @override
  ConsumerState<ContractsScreen> createState() => _ContractsScreenState();
}

class _ContractsScreenState extends ConsumerState<ContractsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _refreshData() {
    ref.invalidate(contractsListProvider);
  }

  String _getActiveFilter() {
    switch (_tabController.index) {
      case 0:
        return 'all';
      case 1:
        return 'active';
      case 2:
        return 'pending';
      case 3:
        return 'closed';
      default:
        return 'all';
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'pending_signature':
      case 'pending':
      case 'signed':
        return Colors.amber;
      case 'expired':
      case 'closed':
      case 'terminated':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final contractsAsync = ref.watch(contractsListProvider);
    final activeFilter = _getActiveFilter();

    return EnterpriseMobileScaffold(
      title: 'Contracts Management',
      userRole: 'Admin',
      userName: 'Administrator',
      currentTabIndex: 0,
      body: RefreshIndicator(
        onRefresh: () async => _refreshData(),
        color: AppTheme.primary,
        child: Column(
          children: [
            // Top Header & Tab Bar
            Container(
              padding: const EdgeInsets.all(16),
              color: const Color(0xFF0D1620),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: Color(0xFF073B32).withValues(alpha: 0.4), borderRadius: BorderRadius.circular(12)),
                            child: const Icon(Icons.description, color: Color(0xFF00D4AA)),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Contracts Management', style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                              Text('Manage tenant leasing agreements and renewals.', style: GoogleFonts.inter(color: Colors.blueGrey.shade400, fontSize: 11)),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh, color: AppTheme.primary, size: 20),
                        onPressed: () => _refreshData(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Stat metrics row
                  contractsAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (list) {
                      final activeCount = list.where((c) => (c['status'] ?? '').toString().toLowerCase() == 'active').length;
                      final pendingCount = list.where((c) => (c['status'] ?? '').toString().toLowerCase().contains('pending') || (c['status'] ?? '').toString().toLowerCase() == 'signed').length;

                      return Row(
                        children: [
                          Expanded(child: _buildMetricCard('Total Contracts', '${list.length}', Icons.folder_copy, Colors.blue)),
                          const SizedBox(width: 8),
                          Expanded(child: _buildMetricCard('Active Leases', '$activeCount', Icons.check_circle, Colors.green)),
                          const SizedBox(width: 8),
                          Expanded(child: _buildMetricCard('Pending Review', '$pendingCount', Icons.hourglass_top, Colors.amber)),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // Filter Tabs
                  TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    indicatorColor: AppTheme.primary,
                    dividerColor: Colors.transparent,
                    labelColor: AppTheme.textPrimary,
                    unselectedLabelColor: AppTheme.textMuted,
                    labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12.5),
                    tabs: const [
                      Tab(text: 'All Contracts'),
                      Tab(text: 'Active Leases'),
                      Tab(text: 'Pending Review'),
                      Tab(text: 'Closed / Expired'),
                    ],
                  ),
                ],
              ),
            ),

            // Search Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: const Color(0xFF060B10),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Search building, apartment, or tenant...',
                  hintStyle: TextStyle(color: Colors.blueGrey.shade400, fontSize: 12),
                  prefixIcon: const Icon(Icons.search, color: Colors.blueGrey, size: 18),
                  filled: true,
                  fillColor: const Color(0xFF0D1620),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1D3347))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1D3347))),
                ),
              ),
            ),

            // Contracts List
            Expanded(
              child: contractsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
                error: (err, _) => Center(child: Text('Error loading contracts: $err', style: const TextStyle(color: Colors.red))),
                data: (list) {
                  final filtered = list.where((item) {
                    final statusStr = (item['status'] ?? 'Active').toString().toLowerCase();
                    final query = _searchController.text.toLowerCase();
                    final title = '${item['building_name']} ${item['apartment_code']} ${item['tenant_name']}'.toLowerCase();

                    final matchesSearch = query.isEmpty || title.contains(query);

                    if (!matchesSearch) return false;

                    if (activeFilter == 'active') {
                      return statusStr == 'active';
                    } else if (activeFilter == 'pending') {
                      return statusStr.contains('pending') || statusStr == 'signed';
                    } else if (activeFilter == 'closed') {
                      return statusStr == 'closed' || statusStr == 'expired' || statusStr == 'terminated';
                    }
                    return true;
                  }).toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.folder_open_outlined, size: 54, color: Colors.blueGrey),
                          const SizedBox(height: 12),
                          Text('No Contracts Found', style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text('There are no contracts matching the selected filter.', style: GoogleFonts.inter(color: Colors.blueGrey.shade400, fontSize: 12)),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final c = filtered[index] as Map<String, dynamic>;
                      final id = c['id'];
                      final building = c['building_name'] ?? 'Building';
                      final apt = c['apartment_code'] ?? 'N/A';
                      final tenant = c['tenant_name'] ?? 'Tenant';
                      final status = (c['status'] ?? 'Active').toString();
                      final rent = c['monthly_rent'] ?? c['rent_amount'] ?? '0';
                      final insurance = c['monthly_insurance'] ?? '0';
                      final startDate = c['start_date'] ?? c['rent_start_date'] ?? 'N/A';
                      final endDate = c['end_date'] ?? c['rent_end_date'] ?? 'N/A';
                      final statusColor = _getStatusColor(status);

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
                                Text('$building - Apt $apt', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
                                  child: Text(status.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text('Tenant: $tenant', style: TextStyle(color: Colors.blueGrey.shade300, fontSize: 13, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),

                            Row(
                              children: [
                                Text('Monthly Rent: ', style: TextStyle(color: Colors.blueGrey.shade400, fontSize: 12)),
                                Text('CFA $rent', style: GoogleFonts.outfit(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                                const SizedBox(width: 16),
                                Text('Insurance: ', style: TextStyle(color: Colors.blueGrey.shade400, fontSize: 12)),
                                Text('CFA $insurance', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                              ],
                            ),
                            const SizedBox(height: 8),

                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: const Color(0xFF060B10), borderRadius: BorderRadius.circular(10)),
                              child: Row(
                                children: [
                                  const Icon(Icons.date_range, size: 14, color: AppTheme.primary),
                                  const SizedBox(width: 6),
                                  Text('Lease Period: $startDate  ➔  $endDate', style: TextStyle(color: Colors.blueGrey.shade200, fontSize: 11)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Action buttons
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (status == 'Pending_Signature' || status == 'Signed') ...[
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green.shade700,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    ),
                                    icon: const Icon(Icons.check, size: 14, color: Colors.white),
                                    label: const Text('Approve Contract', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                    onPressed: () async {
                                      try {
                                        await ApiService().put('/contracts/$id/status', data: {'status': 'Active'});
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Contract Approved & Activated ✓'), backgroundColor: Colors.green));
                                          _refreshData();
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Status: $e')));
                                        }
                                      }
                                    },
                                  ),
                                ] else if (status == 'Active') ...[
                                  OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.amberAccent,
                                      side: const BorderSide(color: Colors.amberAccent),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    ),
                                    icon: const Icon(Icons.autorenew, size: 14),
                                    label: const Text('Renew Lease', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                    onPressed: () async {
                                      try {
                                        await ApiService().post('/contracts/$id/renew');
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Renewal requested ✓'), backgroundColor: Colors.amber));
                                          _refreshData();
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Status: $e')));
                                        }
                                      }
                                    },
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF060B10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1D3347)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 4),
              Expanded(child: Text(title, style: TextStyle(color: Colors.blueGrey.shade300, fontSize: 10), overflow: TextOverflow.ellipsis)),
            ],
          ),
          const SizedBox(height: 4),
          Text(value, style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
