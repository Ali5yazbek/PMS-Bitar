import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_theme.dart';
import '../services/api_service.dart';
import '../widgets/mobile/enterprise_mobile_scaffold.dart';

final verificationKpiProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  try {
    final res = await ApiService().get('/approval/admin-kpi');
    if (res.data is Map<String, dynamic>) {
      return res.data;
    }
    return {};
  } catch (_) {
    return {};
  }
});

final verificationQueueProvider = FutureProvider.family.autoDispose<List<dynamic>, String>((ref, key) async {
  final parts = key.split(':');
  final type = parts[0];
  final status = parts.length > 1 ? parts[1] : 'pending';
  try {
    final res = await ApiService().get('/approval/queue/$type?status=$status');
    if (res.data is List) return res.data;
    return [];
  } catch (_) {
    return [];
  }
});

class EnergyVerificationScreen extends ConsumerStatefulWidget {
  const EnergyVerificationScreen({super.key});

  @override
  ConsumerState<EnergyVerificationScreen> createState() => _EnergyVerificationScreenState();
}

class _EnergyVerificationScreenState extends ConsumerState<EnergyVerificationScreen> with SingleTickerProviderStateMixin {
  late TabController _moduleTabController;
  String _selectedStatus = 'Pending';
  String _selectedSeverity = 'All';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _severities = ['All', 'Low', 'Medium', 'High', 'Critical'];

  @override
  void initState() {
    super.initState();
    _moduleTabController = TabController(length: 5, vsync: this);
    _moduleTabController.addListener(() {
      if (!_moduleTabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _moduleTabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  String _getActiveModuleType() {
    switch (_moduleTabController.index) {
      case 0:
        return 'electricity';
      case 1:
        return 'generator';
      case 2:
        return 'subscription';
      case 3:
        return 'admin-kpi';
      default:
        return 'electricity';
    }
  }

  void _refreshData() {
    ref.invalidate(verificationKpiProvider);
    final activeType = _getActiveModuleType();
    ref.invalidate(verificationQueueProvider('$activeType:${_selectedStatus.toLowerCase()}'));
  }

  Widget _buildBadgeTab(String label, IconData icon, int count) {
    return Tab(
      child: Row(
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Text(label),
          if (count > 0) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: const BoxDecoration(color: Colors.red, borderRadius: BorderRadius.all(Radius.circular(10))),
              child: Text('$count', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final kpiAsync = ref.watch(verificationKpiProvider);
    final activeType = _getActiveModuleType();
    final queueKey = '$activeType:${_selectedStatus.toLowerCase()}';
    final dataAsync = ref.watch(verificationQueueProvider(queueKey));

    final kpiData = kpiAsync.value ?? {};
    final elecCount = (kpiData['electricity_pending'] as num?)?.toInt() ?? 0;
    final genCount = (kpiData['generator_pending'] as num?)?.toInt() ?? 0;
    final subCount = (kpiData['subscription_pending'] as num?)?.toInt() ?? 0;

    return EnterpriseMobileScaffold(
      title: 'Enterprise Verification',
      userRole: 'Admin',
      userName: 'Administrator',
      currentTabIndex: 0,
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header title & module tab strip
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFF131722),
                  border: Border(bottom: BorderSide(color: Color(0xFF0D1620))),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Enterprise Verification',
                          style: GoogleFonts.outfit(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh, color: AppTheme.primary, size: 20),
                          onPressed: () => _refreshData(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Smart anomaly detection and bulk approval workflows.',
                      style: GoogleFonts.inter(color: Colors.blueGrey.shade400, fontSize: 12),
                    ),
                    const SizedBox(height: 16),

                    TabBar(
                      controller: _moduleTabController,
                      isScrollable: true,
                      indicatorColor: Color(0xFF1FE0B8),
                      indicatorWeight: 3,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.blueGrey.shade400,
                      labelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12),
                      tabs: [
                        _buildBadgeTab('Electricity', Icons.flash_on, elecCount),
                        _buildBadgeTab('Generator', Icons.power, genCount),
                        _buildBadgeTab('Subscriptions', Icons.receipt_long, subCount),
                        const Tab(child: Row(children: [Icon(Icons.bar_chart, size: 16), SizedBox(width: 6), Text('KPI Dashboard')])),
                        const Tab(child: Row(children: [Icon(Icons.settings_outlined, size: 16), SizedBox(width: 6), Text('Settings')])),
                      ],
                    ),
                  ],
                ),
              ),

              // Filter sub-section: Status tabs + Search bar + Severity chips
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: const Color(0xFF060B10),
                child: Column(
                  children: [
                    // Status pill tabs
                    Row(
                      children: [
                        _buildStatusCapsule('Pending'),
                        const SizedBox(width: 8),
                        _buildStatusCapsule('Approved'),
                        const SizedBox(width: 8),
                        _buildStatusCapsule('Rejected'),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Search Input
                    TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Search building, apartment, agent...',
                        hintStyle: TextStyle(color: Colors.blueGrey.shade400, fontSize: 13),
                        prefixIcon: const Icon(Icons.search, color: Colors.blueGrey, size: 18),
                        filled: true,
                        fillColor: const Color(0xFF0D1620),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF1D3347))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF1D3347))),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Severity level chips
                    SizedBox(
                      height: 34,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _severities.length,
                        itemBuilder: (context, index) {
                          final sev = _severities[index];
                          final isSelected = _selectedSeverity == sev;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(isSelected ? '✓ $sev' : sev),
                              selected: isSelected,
                              selectedColor: Color(0xFF00A884),
                              backgroundColor: const Color(0xFF0D1620),
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.white : Colors.blueGrey.shade300,
                                fontSize: 11,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: isSelected ? Color(0xFF1FE0B8) : const Color(0xFF1D3347)),
                              ),
                              onSelected: (_) => setState(() => _selectedSeverity = sev),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // Queue cards list
              Expanded(
                child: dataAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
                  error: (err, _) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
                  data: (list) {
                    final filtered = list.where((item) {
                      final titleStr = '${item['building_name']} ${item['apartment_code']} ${item['generator_name']} ${item['submitter_name']}'.toLowerCase();
                      final matchesSearch = _searchController.text.isEmpty || titleStr.contains(_searchController.text.toLowerCase());
                      return matchesSearch;
                    }).toList();

                    if (filtered.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle_outline, size: 54, color: Colors.green),
                            const SizedBox(height: 12),
                            Text(
                              'All Clear!',
                              style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Current filters show no outstanding utility readings requiring review.',
                              style: GoogleFonts.inter(color: Colors.blueGrey.shade400, fontSize: 12),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF00A884),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () {
                                setState(() {
                                  _searchController.clear();
                                  _selectedStatus = 'Pending';
                                  _selectedSeverity = 'All';
                                });
                              },
                              child: const Text('Clear Filters', style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final item = filtered[index] as Map<String, dynamic>;
                        final itemId = item['id'];
                        final buildingName = item['building_name'] ?? 'Building';
                        final targetName = item['apartment_code'] ?? item['generator_name'] ?? 'Unit';
                        final submitter = item['submitter_name'] ?? item['user_name'] ?? 'Agent';
                        final statusStr = (item['status'] ?? 'Pending').toString();
                        final isPending = statusStr.toLowerCase().contains('pending');

                        // Metric formatting
                        String metricText = '';
                        if (activeType == 'electricity') {
                          metricText = '${item['current_reading'] ?? item['reading'] ?? 0} kWh';
                        } else if (activeType == 'generator') {
                          metricText = 'Hours: ${item['running_hours'] ?? 0} • Fuel: ${item['fuel_remaining'] ?? 0}L';
                        } else {
                          metricText = '${item['amount'] ?? 'CFA 0'}';
                        }

                        return Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0D1620), Color(0xFF060B10)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFF1D3347)),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4)),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const Icon(Icons.flash_on, color: Colors.amberAccent, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '$buildingName - $targetName',
                                      style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: isPending ? Colors.amber.shade900.withValues(alpha: 0.3) : Colors.green.shade900.withValues(alpha: 0.3),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      statusStr.toUpperCase(),
                                      style: TextStyle(
                                        color: isPending ? Colors.amberAccent : Colors.greenAccent,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              Text(
                                'Reading / Metric: $metricText',
                                style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                              if (item['notes'] != null && item['notes'].toString().isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Notes: ${item['notes']}',
                                  style: TextStyle(color: Colors.blueGrey.shade300, fontSize: 12),
                                ),
                              ],
                              const SizedBox(height: 12),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Submitted by: $submitter',
                                    style: GoogleFonts.inter(color: Colors.blueGrey.shade400, fontSize: 11),
                                  ),
                                  if (isPending)
                                    Row(
                                      children: [
                                        OutlinedButton(
                                          style: OutlinedButton.styleFrom(
                                            side: BorderSide(color: Colors.green.shade500),
                                            backgroundColor: Colors.green.shade900.withValues(alpha: 0.2),
                                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          ),
                                          onPressed: () async {
                                            try {
                                              await ApiService().post('/approval/approve/$activeType/$itemId');
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Approved $targetName ✓'), backgroundColor: Colors.green));
                                                _refreshData();
                                              }
                                            } catch (e) {
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                                              }
                                            }
                                          },
                                          child: const Text('Approve', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                                        ),
                                        const SizedBox(width: 8),
                                        OutlinedButton(
                                          style: OutlinedButton.styleFrom(
                                            side: BorderSide(color: Colors.red.shade500),
                                            backgroundColor: Colors.red.shade900.withValues(alpha: 0.2),
                                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          ),
                                          onPressed: () async {
                                            try {
                                              await ApiService().post('/approval/reject/$activeType/$itemId');
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Rejected $targetName ✓'), backgroundColor: Colors.red));
                                                _refreshData();
                                              }
                                            } catch (e) {
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                                              }
                                            }
                                          },
                                          child: const Text('Reject', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                                        ),
                                      ],
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
              ),
            ],
          ),

          // Floating AI Assistant Button
          Positioned(
            bottom: 16,
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.indigo.withValues(alpha: 0.6), blurRadius: 20, spreadRadius: 4),
                ],
              ),
              child: FloatingActionButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('AI Anomaly Assistant initialized.')),
                  );
                },
                backgroundColor: const Color(0xFF00A884),
                child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 28),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCapsule(String status) {
    final isSelected = _selectedStatus.toLowerCase() == status.toLowerCase();
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedStatus = status;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: isSelected ? Color(0xFF00A884) : const Color(0xFF0D1620),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? Color(0xFF1FE0B8) : const Color(0xFF1D3347)),
            boxShadow: isSelected
                ? [BoxShadow(color: Colors.indigo.withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 2))]
                : null,
          ),
          child: Center(
            child: Text(
              status,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.blueGrey.shade300,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

