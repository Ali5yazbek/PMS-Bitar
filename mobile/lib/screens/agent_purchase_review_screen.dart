import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../config/app_theme.dart';
import '../services/api_service.dart';
import '../widgets/mobile/enterprise_mobile_scaffold.dart';
import '../widgets/mobile/receipt_image_viewer.dart';

/// Fetches and merges agent purchase submissions & apartment cost deployments
/// from all backend tables so both Pending Review and All History are complete.
final agentPurchasesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  Future<dynamic> safeFetch(Future<dynamic> future, Duration timeout) async {
    try {
      final res = await future.timeout(timeout);
      return res.data;
    } catch (_) {
      return null;
    }
  }

  final results = await Future.wait([
    safeFetch(
      ApiService().get('/agent-purchases?all=1').catchError((_) => ApiService().get('/agent-purchases')),
      const Duration(seconds: 5),
    ),
    safeFetch(
      ApiService().get('/energy/agent/apartment-purchases/pending'),
      const Duration(seconds: 4),
    ),
    safeFetch(
      ApiService().get('/energy/agent/apartment-purchases'),
      const Duration(seconds: 4),
    ),
    safeFetch(
      ApiService().get('/apartment-costs/report', queryParameters: {
        'start_date': '2020-01-01',
        'end_date': '2030-12-31',
      }),
      const Duration(seconds: 3),
    ),
  ]);

  final List<Map<String, dynamic>> merged = [];
  final Set<String> seenKeys = {};
  final Map<String, int> sigToIndex = {};

  double parseAmount(dynamic raw) {
    if (raw == null) return 0;
    if (raw is num) return raw.toDouble();
    final cleaned = raw.toString().replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(cleaned) ?? 0;
  }

  String normalizeStatus(dynamic raw) {
    final s = (raw ?? '').toString().trim().toLowerCase();
    if (s.contains('pend')) return 'Pending Review';
    if (s.contains('approv') || s.contains('accept')) return 'Approved';
    if (s.contains('reject')) return 'Rejected';
    return 'Approved';
  }

  String? extractReceipt(Map<String, dynamic> item) {
    final direct = item['receipt_image'] ?? item['receipt_path'] ?? item['photo_path'];
    if (direct != null && direct.toString().trim().isNotEmpty) {
      return direct.toString().trim();
    }
    final receipts = item['receipts'];
    if (receipts is List && receipts.isNotEmpty) {
      final first = receipts.first?.toString().trim() ?? '';
      if (first.isNotEmpty) return first;
    }
    return null;
  }

  String buildSig(String bld, String apt, String sup, double amt, String date) {
    return '${bld.trim().toLowerCase()}_${apt.trim().toLowerCase()}_${sup.trim().toLowerCase()}_${amt.round()}_$date';
  }

  // 1. Primary: From /energy/agent/apartment-purchases/pending (apartment_cost_deployments with receipt_image)
  if (results[1] is List) {
    for (final raw in (results[1] as List)) {
      if (raw is! Map) continue;
      final item = Map<String, dynamic>.from(raw);
      final bld = (item['building_name'] ?? 'Building').toString();
      final apt = (item['apartment_code'] ?? item['apartment_number'] ?? '').toString();
      final supplier = (item['supplier_name'] ?? item['supplier'] ?? 'Supplier').toString();
      final numAmt = parseAmount(item['amount']);
      final dedup = 'acd_${item['id']}';
      if (seenKeys.contains(dedup)) continue;
      seenKeys.add(dedup);

      final dateOnly = (item['date'] ?? item['created_at'] ?? '').toString().split(' ').first;
      final sig = buildSig(bld, apt, supplier, numAmt, dateOnly);
      sigToIndex[sig] = merged.length;

      merged.add({
        'id': item['id'],
        'source_table': 'apartment_cost_deployments',
        'source_type': 'Agent Purchase',
        'building_name': bld,
        'apartment_number': apt,
        'supplier': supplier,
        'amount_num': numAmt,
        'amount': 'CFA ${NumberFormat('#,##0').format(numAmt)}',
        'items': (item['notes'] ?? 'Apartment Purchase').toString(),
        'notes': (item['notes'] ?? '').toString(),
        'status': 'Pending Review',
        'submitter_name': (item['submitter_name'] ?? 'Field Agent').toString(),
        'date': dateOnly,
        'receipt_image': extractReceipt(item),
      });
    }
  }

  // 2. Primary History: From /energy/agent/apartment-purchases (history with receipt_image)
  final histList = (results[2] is Map && results[2]['history'] is List)
      ? (results[2]['history'] as List)
      : (results[2] is List ? results[2] as List : const []);
  for (final raw in histList) {
    if (raw is! Map) continue;
    final item = Map<String, dynamic>.from(raw);
    final dedup = 'acd_${item['id']}';
    if (seenKeys.contains(dedup)) continue;
    seenKeys.add(dedup);

    final bld = (item['building_name'] ?? 'Building').toString();
    final apt = (item['apartment_code'] ?? item['apartment_number'] ?? '').toString();
    final supplier = (item['supplier_name'] ?? item['supplier'] ?? 'Supplier').toString();
    final numAmt = parseAmount(item['amount']);
    final dateOnly = (item['date'] ?? item['created_at'] ?? '').toString().split(' ').first;
    final sig = buildSig(bld, apt, supplier, numAmt, dateOnly);
    sigToIndex[sig] = merged.length;

    merged.add({
      'id': item['id'],
      'source_table': 'apartment_cost_deployments',
      'source_type': 'Agent Purchase',
      'building_name': bld,
      'apartment_number': apt,
      'supplier': supplier,
      'amount_num': numAmt,
      'amount': 'CFA ${NumberFormat('#,##0').format(numAmt)}',
      'items': (item['notes'] ?? 'Apartment Purchase').toString(),
      'notes': (item['notes'] ?? '').toString(),
      'status': normalizeStatus(item['status'] ?? 'Approved'),
      'submitter_name': (item['submitter_name'] ?? 'Field Agent').toString(),
      'date': dateOnly,
      'receipt_image': extractReceipt(item),
    });
  }

  // 3. Secondary: From /agent-purchases?all=1 (deduplicated against apartment_cost_deployments)
  if (results[0] is List) {
    for (final raw in (results[0] as List)) {
      if (raw is! Map) continue;
      final item = Map<String, dynamic>.from(raw);
      final bld = (item['building_name'] ?? 'Galaxy').toString();
      final apt = (item['apartment_number'] ?? item['apartment_code'] ?? 'A1').toString();
      final supplier = (item['supplier'] ?? item['supplier_name'] ?? 'General').toString();
      final numAmt = parseAmount(item['amount']);
      final dateStr = (item['created_at'] ?? item['date'] ?? '').toString();
      final dateOnly = dateStr.isNotEmpty ? dateStr.split(' ').first : '';
      final receipt = extractReceipt(item);

      final sig = buildSig(bld, apt, supplier, numAmt, dateOnly);
      if (sigToIndex.containsKey(sig)) {
        final idx = sigToIndex[sig]!;
        if ((merged[idx]['receipt_image'] == null ||
                merged[idx]['receipt_image'].toString().isEmpty) &&
            receipt != null) {
          merged[idx]['receipt_image'] = receipt;
        }
        continue;
      }

      final key = 'ap_${item['id']}_${bld}_${apt}_$numAmt';
      if (seenKeys.contains(key)) continue;
      seenKeys.add(key);
      sigToIndex[sig] = merged.length;

      merged.add({
        'id': item['id'],
        'source_table': 'agent_purchases',
        'source_type': 'Agent Purchase',
        'building_name': bld,
        'apartment_number': apt,
        'supplier': supplier,
        'amount_num': numAmt,
        'amount': 'CFA ${NumberFormat('#,##0').format(numAmt)}',
        'items': (item['items'] ?? 'General Material').toString(),
        'notes': (item['notes'] ?? '').toString(),
        'status': normalizeStatus(item['status'] ?? 'Pending Review'),
        'submitter_name': (item['submitter_name'] ?? 'Field Agent').toString(),
        'date': dateOnly,
        'receipt_image': receipt,
      });
    }
  }

  // 4. From /apartment-costs/report (all apartment expenses/deployments)
  if (results[3] is List) {
    for (final raw in (results[3] as List)) {
      if (raw is! Map) continue;
      final item = Map<String, dynamic>.from(raw);
      final rawId = (item['id'] ?? '').toString();
      if (rawId.startsWith('dep_')) {
        final realId = rawId.replaceFirst('dep_', '');
        if (seenKeys.contains('acd_$realId')) continue;
        seenKeys.add('acd_$realId');
      } else {
        if (seenKeys.contains(rawId)) continue;
        seenKeys.add(rawId);
      }

      final bld = (item['building_name'] ?? 'Building').toString();
      final apt = (item['apartment_code'] ?? item['apartment_number'] ?? '').toString();
      final supplier = (item['supplier_name'] ?? 'Supplier').toString();
      final numAmt = parseAmount(item['amount']);
      final type = (item['type'] ?? 'Deployment').toString();
      final dateOnly = (item['date'] ?? '').toString().split(' ').first;
      final receipt = extractReceipt(item);

      final sig = buildSig(bld, apt, supplier, numAmt, dateOnly);
      if (sigToIndex.containsKey(sig)) {
        final idx = sigToIndex[sig]!;
        if ((merged[idx]['receipt_image'] == null ||
                merged[idx]['receipt_image'].toString().isEmpty) &&
            receipt != null) {
          merged[idx]['receipt_image'] = receipt;
        }
        continue;
      }

      merged.add({
        'id': item['id'],
        'source_table': 'report',
        'source_type': type,
        'building_name': bld,
        'apartment_number': apt,
        'supplier': supplier,
        'amount_num': numAmt,
        'amount': 'CFA ${NumberFormat('#,##0').format(numAmt)}',
        'items': (item['notes'] ?? type).toString(),
        'notes': (item['notes'] ?? '').toString(),
        'status': 'Approved',
        'submitter_name': type,
        'date': dateOnly,
        'receipt_image': receipt,
      });
    }
  }

  // Sort newest first
  merged.sort((a, b) => (b['date'] ?? '').toString().compareTo((a['date'] ?? '').toString()));
  return merged;
});

class AgentPurchaseReviewScreen extends ConsumerStatefulWidget {
  const AgentPurchaseReviewScreen({super.key});

  @override
  ConsumerState<AgentPurchaseReviewScreen> createState() => _AgentPurchaseReviewScreenState();
}

class _AgentPurchaseReviewScreenState extends ConsumerState<AgentPurchaseReviewScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  String _selectedBuilding = 'All Buildings';
  String _selectedStatus = 'All'; // All, Pending Review, Approved, Rejected
  String _selectedDateRange = 'All Time'; // All Time, This Month, Last 30 Days

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _applyFilters(
    List<Map<String, dynamic>> items, {
    required bool isPendingTab,
  }) {
    final now = DateTime.now();
    return items.where((item) {
      final status = (item['status'] ?? 'Approved').toString();
      if (isPendingTab && status != 'Pending Review') return false;

      if (!isPendingTab && _selectedStatus != 'All') {
        if (status != _selectedStatus) return false;
      }

      if (_selectedBuilding != 'All Buildings') {
        if ((item['building_name'] ?? '').toString().toLowerCase() !=
            _selectedBuilding.toLowerCase()) {
          return false;
        }
      }

      if (_selectedDateRange != 'All Time') {
        final dateStr = (item['date'] ?? '').toString();
        final parsed = DateTime.tryParse(dateStr);
        if (parsed != null) {
          if (_selectedDateRange == 'This Month') {
            if (parsed.year != now.year || parsed.month != now.month) return false;
          } else if (_selectedDateRange == 'Last 30 Days') {
            if (now.difference(parsed).inDays > 30) return false;
          }
        }
      }

      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchBld = (item['building_name'] ?? '').toString().toLowerCase().contains(q);
        final matchApt = (item['apartment_number'] ?? '').toString().toLowerCase().contains(q);
        final matchSup = (item['supplier'] ?? '').toString().toLowerCase().contains(q);
        final matchItems = (item['items'] ?? '').toString().toLowerCase().contains(q);
        final matchNotes = (item['notes'] ?? '').toString().toLowerCase().contains(q);
        final matchAgent = (item['submitter_name'] ?? '').toString().toLowerCase().contains(q);
        if (!matchBld && !matchApt && !matchSup && !matchItems && !matchNotes && !matchAgent) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  Future<void> _handleDecision(Map<String, dynamic> item, bool approve) async {
    final id = item['id'];
    final sourceTable = item['source_table'];
    try {
      if (sourceTable == 'apartment_cost_deployments') {
        await ApiService().post(
          '/energy/agent/apartment-purchases/$id/verify',
          data: {
            'status': approve ? 'Accepted' : 'Rejected',
            if (!approve) 'rejection_reason': 'Rejected by Administrator',
          },
        );
      } else {
        await ApiService().post('/agent-purchases/$id/${approve ? 'approve' : 'reject'}');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(approve ? 'Purchase Approved ✓' : 'Purchase Rejected ✓'),
            backgroundColor: approve ? AppTheme.primary : AppTheme.danger,
          ),
        );
        ref.invalidate(agentPurchasesProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.danger),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final purchasesAsync = ref.watch(agentPurchasesProvider);
    final isLoading = purchasesAsync.isLoading && !purchasesAsync.hasValue;
    final allItems = purchasesAsync.value ?? const <Map<String, dynamic>>[];

    // Extract unique buildings for filter dropdown
    final buildingsSet = <String>{'All Buildings'};
    for (final p in allItems) {
      final b = (p['building_name'] ?? '').toString().trim();
      if (b.isNotEmpty) buildingsSet.add(b);
    }
    final buildingOptions = buildingsSet.toList();
    if (!buildingOptions.contains(_selectedBuilding)) {
      _selectedBuilding = 'All Buildings';
    }

    final pendingFiltered = _applyFilters(allItems, isPendingTab: true);
    final historyFiltered = _applyFilters(allItems, isPendingTab: false);

    final totalHistoryAmount = historyFiltered.fold<double>(
      0,
      (sum, item) => sum + ((item['amount_num'] as num?)?.toDouble() ?? 0),
    );

    return EnterpriseMobileScaffold(
      title: 'Agent Purchase Review',
      userRole: 'Admin',
      userName: 'Administrator',
      currentTabIndex: 0,
      body: Column(
        children: [
          // ── Header + Search + Filters Panel (Always rendered in 0ms) ──
          Container(
            margin: const EdgeInsets.fromLTRB(16, 6, 16, 8),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            decoration: AppTheme.glassCardDecoration(borderRadius: 22),
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
                          decoration: BoxDecoration(
                            color: AppTheme.accent.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.accent.withValues(alpha: 0.35)),
                          ),
                          child: const Icon(Icons.shopping_cart_checkout_rounded, color: AppTheme.accent, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Purchase & Cost Center',
                              style: GoogleFonts.outfit(
                                color: AppTheme.textPrimary,
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              isLoading
                                  ? 'Syncing latest records...'
                                  : '${historyFiltered.length} records • CFA ${NumberFormat('#,##0').format(totalHistoryAmount)}',
                              style: GoogleFonts.plusJakartaSans(
                                color: AppTheme.primary,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded, color: AppTheme.primary, size: 22),
                      onPressed: () {
                        ApiService().clearCache();
                        ref.invalidate(agentPurchasesProvider);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Search Field
                SizedBox(
                  height: 42,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _searchQuery = v.trim()),
                    style: GoogleFonts.plusJakartaSans(color: AppTheme.textPrimary, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Search building, apt, supplier, item or agent...',
                      hintStyle: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontSize: 12),
                      prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primary, size: 18),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close_rounded, size: 16, color: AppTheme.textSecondary),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                      filled: true,
                      fillColor: AppTheme.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(13),
                        borderSide: const BorderSide(color: AppTheme.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(13),
                        borderSide: const BorderSide(color: AppTheme.border),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Filter Chips Row (Building + Status + Date Range)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Building Dropdown Pill
                      Container(
                        height: 32,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: _selectedBuilding != 'All Buildings'
                              ? AppTheme.primary.withValues(alpha: 0.16)
                              : AppTheme.background,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _selectedBuilding != 'All Buildings'
                                ? AppTheme.primary
                                : AppTheme.border,
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedBuilding,
                            dropdownColor: AppTheme.surface,
                            icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: AppTheme.primary),
                            style: GoogleFonts.plusJakartaSans(
                              color: AppTheme.textPrimary,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                            items: buildingOptions
                                .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedBuilding = val);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Date Range Filter Chips
                      for (final range in ['All Time', 'This Month', 'Last 30 Days']) ...[
                        _buildFilterChip(
                          label: range,
                          selected: _selectedDateRange == range,
                          onTap: () => setState(() => _selectedDateRange = range),
                        ),
                        const SizedBox(width: 6),
                      ],

                      // Status Filter Chips
                      for (final st in ['All', 'Approved', 'Pending Review', 'Rejected']) ...[
                        _buildFilterChip(
                          label: st == 'Pending Review' ? 'Pending' : st,
                          selected: _selectedStatus == st,
                          accentColor: AppTheme.accent,
                          onTap: () => setState(() => _selectedStatus = st),
                        ),
                        const SizedBox(width: 6),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Tabs
                TabBar(
                  controller: _tabController,
                  indicatorColor: AppTheme.accent,
                  labelColor: AppTheme.accent,
                  unselectedLabelColor: AppTheme.textSecondary,
                  dividerColor: AppTheme.border,
                  labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 13.5),
                  tabs: [
                    Tab(text: 'Pending Review (${pendingFiltered.length})'),
                    Tab(text: 'All History (${historyFiltered.length})'),
                  ],
                ),
              ],
            ),
          ),

          // ── Tab Views ─────────────────────────────────────────────────
          Expanded(
            child: isLoading
                ? ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: 3,
                    itemBuilder: (_, __) => Container(
                      height: 112,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppTheme.border),
                      ),
                    ),
                  )
                : TabBarView(
                    controller: _tabController,
                    children: [
                      // Tab 1: Pending Review
                      pendingFiltered.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(18),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primary.withValues(alpha: 0.12),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.verified_rounded, size: 42, color: AppTheme.primary),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No Pending Purchases — All Clear!',
                                    style: GoogleFonts.outfit(
                                      color: AppTheme.textPrimary,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Switch to "All History" to browse ${historyFiltered.length} recorded costs.',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: AppTheme.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                              itemCount: pendingFiltered.length,
                              itemBuilder: (context, index) =>
                                  _buildPurchaseCard(pendingFiltered[index], showActions: true),
                            ),

                      // Tab 2: All History
                      historyFiltered.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.search_off_rounded, size: 42, color: AppTheme.textMuted),
                                  const SizedBox(height: 10),
                                  Text(
                                    'No purchases match the active filter.',
                                    style: GoogleFonts.outfit(
                                      color: AppTheme.textSecondary,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {
                                        _searchQuery = '';
                                        _selectedBuilding = 'All Buildings';
                                        _selectedStatus = 'All';
                                        _selectedDateRange = 'All Time';
                                      });
                                    },
                                    child: const Text('Reset Filters', style: TextStyle(color: AppTheme.primary)),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                              itemCount: historyFiltered.length,
                              itemBuilder: (context, index) =>
                                  _buildPurchaseCard(historyFiltered[index], showActions: false),
                            ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    Color accentColor = AppTheme.primary,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 11),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? accentColor.withValues(alpha: 0.18) : AppTheme.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? accentColor : AppTheme.border),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            color: selected ? accentColor : AppTheme.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildPurchaseCard(Map<String, dynamic> item, {required bool showActions}) {
    final building = item['building_name'] ?? 'Building';
    final apt = item['apartment_number'] ?? '';
    final supplier = item['supplier'] ?? 'General';
    final amount = item['amount'] ?? 'CFA 0';
    final items = item['items'] ?? '';
    final submitter = item['submitter_name'] ?? 'Agent';
    final date = item['date'] ?? '';
    final status = (item['status'] ?? 'Approved').toString();
    final sourceType = (item['source_type'] ?? 'Purchase').toString();
    final receiptImg = (item['receipt_image'] ?? '').toString().trim();

    final Color statusColor = status == 'Approved'
        ? AppTheme.primary
        : (status == 'Rejected' ? AppTheme.danger : AppTheme.accent);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: AppTheme.glassCardDecoration(borderRadius: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.35)),
                      ),
                      child: Text(
                        '$building • Apt $apt',
                        style: GoogleFonts.outfit(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: GoogleFonts.plusJakartaSans(
                          color: statusColor,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                amount,
                style: GoogleFonts.outfit(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Supplier: $supplier',
            style: GoogleFonts.plusJakartaSans(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 12.5,
            ),
          ),
          if (items.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              items,
              style: GoogleFonts.plusJakartaSans(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Source: $sourceType • By: $submitter',
                style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.textMuted,
                  fontSize: 11,
                ),
              ),
              if (date.isNotEmpty)
                Text(
                  date,
                  style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
          if (receiptImg.isNotEmpty) ...[
            const SizedBox(height: 10),
            InkWell(
              onTap: () => ReceiptImageViewer.showLightbox(
                context,
                receiptImg,
                title: '$building • Apt $apt Receipt',
                subtitle: 'Supplier: $supplier • $amount • By: $submitter',
              ),
              borderRadius: BorderRadius.circular(13),
              child: Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: AppTheme.primary.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(9),
                      child: SizedBox(
                        width: 60,
                        height: 60,
                        child: ReceiptImageViewer.buildImage(receiptImg, width: 60, height: 60),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.verified_outlined, color: AppTheme.primary, size: 15),
                              const SizedBox(width: 5),
                              Text(
                                'Receipt Photo Attached',
                                style: GoogleFonts.outfit(
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Tap to inspect full-size receipt photo',
                            style: GoogleFonts.plusJakartaSans(
                              color: AppTheme.textSecondary,
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: const Icon(Icons.zoom_in_rounded, color: AppTheme.primary, size: 20),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (showActions || status == 'Pending Review') ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.danger,
                      side: const BorderSide(color: AppTheme.danger),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => _handleDecision(item, false),
                    icon: const Icon(Icons.close_rounded, size: 16),
                    label: const Text('Reject', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: const Color(0xFF04130F),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => _handleDecision(item, true),
                    icon: const Icon(Icons.check_rounded, size: 16),
                    label: const Text('Approve', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
