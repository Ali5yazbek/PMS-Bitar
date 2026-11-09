import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_theme.dart';
import '../services/history_api.dart';
import '../widgets/mobile/enterprise_mobile_scaffold.dart';

final historyDataProvider = FutureProvider<Map<String, List<dynamic>>>((ref) async {
  return await HistoryApi.instance.getReadingHistory();
});

class AgentHistoryScreen extends ConsumerStatefulWidget {
  const AgentHistoryScreen({super.key});

  @override
  ConsumerState<AgentHistoryScreen> createState() => _AgentHistoryScreenState();
}

class _AgentHistoryScreenState extends ConsumerState<AgentHistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedStatus = 'All';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(historyDataProvider);

    return EnterpriseMobileScaffold(
      title: 'Reading History',
      userRole: 'Agent',
      userName: 'Field Agent',
      currentTabIndex: 0,
      body: Column(
        children: [
          // 4 Categorized Tabs: Generator, Apartment, Daily Reports, Apartment Costs
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
                Tab(text: 'Generator Readings'),
                Tab(text: 'Apartment Readings'),
                Tab(text: 'Daily Reports'),
                Tab(text: 'Apartment Costs'),
              ],
            ),
          ),

          // Search & Filter sub-bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: const Color(0xFF060B10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    decoration: InputDecoration(
                      hintText: 'Search building, apt, date...',
                      hintStyle: TextStyle(color: Colors.blueGrey.shade400, fontSize: 12),
                      prefixIcon: const Icon(Icons.search, color: Colors.blueGrey, size: 16),
                      filled: true,
                      fillColor: const Color(0xFF0D1620),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF1D3347))),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(color: const Color(0xFF0D1620), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFF1D3347))),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedStatus,
                      dropdownColor: const Color(0xFF0D1620),
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      items: ['All', 'Pending', 'Approved', 'Rejected', 'Under Review'].map((s) {
                        return DropdownMenuItem(value: s, child: Text(s));
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedStatus = val!),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: historyAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
              error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
              data: (historyMap) {
                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildHistoryListView(historyMap['generator'] ?? [], 'Generator'),
                    _buildHistoryListView(historyMap['apartment'] ?? [], 'Apartment'),
                    _buildHistoryListView(historyMap['daily_reports'] ?? [], 'Daily Report'),
                    _buildHistoryListView(historyMap['purchases'] ?? [], 'Apartment Cost'),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryListView(List<dynamic> rawList, String category) {
    final filtered = rawList.where((item) {
      final matchesSearch = _searchController.text.isEmpty ||
          '${item['building_name']} ${item['apartment_number']} ${item['date']} ${item['notes']}'
              .toLowerCase()
              .contains(_searchController.text.toLowerCase());
      final matchesStatus = _selectedStatus == 'All' ||
          (item['status'] ?? 'Pending').toString().toLowerCase() == _selectedStatus.toLowerCase();

      return matchesSearch && matchesStatus;
    }).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Text('No $category history records found.', style: GoogleFonts.inter(color: Colors.blueGrey.shade400)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final item = filtered[index];
        final status = item['status'] ?? 'Pending';
        Color statusColor = status == 'Approved' ? Colors.green : (status == 'Rejected' ? Colors.red : Colors.amber);

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
                  Text(
                    '${item['building_name'] ?? 'Galaxy'} ${item['apartment_number'] != null ? 'Apt ' + item['apartment_number'] : ''}',
                    style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: statusColor.withOpacity(0.2), borderRadius: BorderRadius.circular(8), border: Border.all(color: statusColor.withOpacity(0.5))),
                    child: Text(status, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text('Submitted: ${item['date'] ?? 'Aug 5, 2026'} • By Agent ID #${item['submitted_by'] ?? '1'}', style: TextStyle(color: Colors.blueGrey.shade400, fontSize: 11)),
              if (item['notes'] != null && item['notes'].toString().isNotEmpty) ...[
                const SizedBox(height: 6),
                Text('Notes: ${item['notes']}', style: TextStyle(color: Colors.blueGrey.shade300, fontSize: 12)),
              ],
              if (item['admin_comment'] != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Color(0xFF073B32).withOpacity(0.3), borderRadius: BorderRadius.circular(8)),
                  child: Text('Admin Comment: ${item['admin_comment']}', style: TextStyle(color: Color(0xFF99F3E2), fontSize: 11)),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
