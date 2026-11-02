import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_theme.dart';
import '../providers/currency_provider.dart';
import '../services/api_service.dart';
import '../services/agent_api.dart';
import '../widgets/mobile/enterprise_mobile_scaffold.dart';

// ─── Providers ────────────────────────────────────────────────────────────────

final buildingsListProvider = FutureProvider<List<dynamic>>((ref) async {
  try {
    final res = await ApiService().get('/buildings');
    final data = res.data;
    if (data is List) return data;
    if (data is Map<String, dynamic>) {
      return (data['buildings'] ?? data['data'] ?? []) as List<dynamic>;
    }
    return [];
  } catch (_) {
    return [];
  }
});

final buildingApartmentsProvider = FutureProvider.family.autoDispose<List<dynamic>, String>((ref, buildingId) async {
  if (buildingId.isEmpty) return [];
  try {
    final res = await ApiService().get('/energy/agent/building-apartments/$buildingId');
    final data = res.data;
    if (data is List) return data;
    return [];
  } catch (_) {
    return [];
  }
});

final rentTasksProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return AgentApi.instance.getRentTasks();
});

/// Fetch collected history from the agent's rent history endpoint by date
final rentHistoryByDateProvider = FutureProvider.family.autoDispose<List<dynamic>, DateTime>((ref, date) async {
  try {
    final res = await ApiService().get('/agent/rent/history');
    final data = res.data as Map<String, dynamic>?;
    final history = (data != null && data['status'] == 'success' && data['data'] != null)
        ? List<dynamic>.from(data['data'])
        : [];
        
    final prefs = await SharedPreferences.getInstance();
    final cacheStr = prefs.getString('local_elec_history');
    if (cacheStr != null) {
      history.addAll(jsonDecode(cacheStr));
    }
    
    final selectedDateStr = DateFormat('yyyy-MM-dd').format(date);
    return history.where((item) {
      final itemDateStr = (item['date'] ?? '').toString();
      return itemDateStr.startsWith(selectedDateStr);
    }).toList();
  } catch (_) {
    return [];
  }
});

double _toDouble(dynamic val) {
  if (val == null) return 0.0;
  if (val is double) return val;
  if (val is int) return val.toDouble();
  return double.tryParse(val.toString()) ?? 0.0;
}

// ─── Main Screen ──────────────────────────────────────────────────────────────

class AgentRentCollectionScreen extends ConsumerStatefulWidget {
  const AgentRentCollectionScreen({super.key});

  @override
  ConsumerState<AgentRentCollectionScreen> createState() => _AgentRentCollectionScreenState();
}

class _AgentRentCollectionScreenState extends ConsumerState<AgentRentCollectionScreen> {
  DateTime _selectedDate = DateTime.now();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(rentTasksProvider);
    final historyAsync = ref.watch(rentHistoryByDateProvider(_selectedDate));
    final formatAmount = ref.watch(formatAmountProvider);

    // Calculate total collected today from history endpoint
    double totalCollectedToday = 0.0;
    final historyList = historyAsync.value ?? [];
    for (final item in historyList) {
      totalCollectedToday += _toDouble(item['amount']);
    }

    return EnterpriseMobileScaffold(
      title: 'Rent Collection',
      userRole: 'Agent',
      userName: 'Field Agent',
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primary,
        onPressed: () => _openAddCollectionWizard(context),
        icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.white),
        label: const Text('Add Collection', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: RefreshIndicator(
        color: AppTheme.primary,
        onRefresh: () async {
          ref.invalidate(rentTasksProvider);
          ref.invalidate(rentHistoryByDateProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0D1620), Color(0xFF060B10)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 5)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('DAILY COLLECTION LEDGER', style: GoogleFonts.inter(color: AppTheme.primary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                            const SizedBox(height: 2),
                            Text('Date: ${DateFormat('M/d/yyyy').format(_selectedDate)}', style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 12)),
                          ],
                        ),
                        InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _selectedDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                            );
                            if (picked != null) setState(() => _selectedDate = picked);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(color: const Color(0xFF0D1620), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFF1D3347))),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today_rounded, size: 14, color: Colors.blueGrey),
                                const SizedBox(width: 6),
                                Text(DateFormat('MM/dd/yyyy').format(_selectedDate), style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text('Total Remittance Today', style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 12)),
                    Text(formatAmount(totalCollectedToday), style: GoogleFonts.outfit(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('${historyList.length} collection(s)', style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 12)),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, padding: const EdgeInsets.symmetric(vertical: 12)),
                        icon: const Icon(Icons.add_circle_outline, size: 18, color: Colors.white),
                        label: const Text('+ Add Collection Wizard', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        onPressed: () => _openAddCollectionWizard(context),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Collected Today Section
              if (historyList.isNotEmpty) ...[
                Text('Collected Today', style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...historyList.map((item) => _buildCollectedTile(item, formatAmount)),
                const SizedBox(height: 16),
              ],

              // Ledger Transactions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Pending Collections', style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, color: Colors.blueGrey),
                    onPressed: () {
                      ref.invalidate(rentTasksProvider);
                      ref.invalidate(rentHistoryByDateProvider);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Search Bar
              TextField(
                onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search tenant, apt, or ID...',
                  hintStyle: const TextStyle(color: Colors.blueGrey, fontSize: 13),
                  prefixIcon: const Icon(Icons.search, color: Colors.blueGrey, size: 20),
                  filled: true,
                  fillColor: const Color(0xFF0D1620),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1D3347))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1D3347))),
                ),
              ),

              const SizedBox(height: 16),

              tasksAsync.when(
                loading: () => const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator(color: AppTheme.primary))),
                error: (e, _) => Center(child: Padding(padding: const EdgeInsets.all(20), child: Text('Error loading tasks: $e', style: const TextStyle(color: Colors.red)))),
                data: (response) {
                  final rawData = response['data'] as Map<String, dynamic>? ?? {};

                  if (rawData.isEmpty) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(40),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D1620),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF1D3347)),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.check_circle_outline, size: 48, color: Colors.greenAccent.withValues(alpha: 0.6)),
                          const SizedBox(height: 12),
                          Text('No pending collections!', style: GoogleFonts.inter(color: Colors.greenAccent, fontSize: 14, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text('All invoices are paid or no records found.', style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 12)),
                        ],
                      ),
                    );
                  }

                  return Column(
                    children: rawData.entries.map((entry) {
                      final buildingName = entry.key;
                      final apartments = (entry.value as List<dynamic>).cast<Map<String, dynamic>>();

                      final filteredApts = apartments.where((apt) {
                        if (_searchQuery.isEmpty) return true;
                        final tenant = (apt['tenant_name'] ?? '').toString().toLowerCase();
                        final aptCode = (apt['apartment_number'] ?? apt['apartment_code'] ?? '').toString().toLowerCase();
                        final invId = (apt['invoice_id'] ?? '').toString().toLowerCase();
                        return tenant.contains(_searchQuery) || aptCode.contains(_searchQuery) || invId.contains(_searchQuery);
                      }).toList();

                      if (filteredApts.isEmpty) return const SizedBox.shrink();

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
                                Row(
                                  children: [
                                    const Icon(Icons.apartment_rounded, color: Color(0xFF00D4AA), size: 20),
                                    const SizedBox(width: 8),
                                    Text(buildingName, style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(color: Color(0xFF073B32).withValues(alpha: 0.4), borderRadius: BorderRadius.circular(8)),
                                  child: Text('${filteredApts.length} Tasks', style: TextStyle(color: Color(0xFF5CEAD0), fontSize: 10, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ...filteredApts.map((apt) => _buildCollectionTaskTile(context, apt, buildingName, formatAmount)),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCollectedTile(Map<String, dynamic> item, String Function(dynamic) formatAmount) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade900.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${item['tenant_name'] ?? 'Tenant'}', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                Text('${item['building_name'] ?? ''} - Apt ${item['apartment_number'] ?? item['apartment_code'] ?? ''}', style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 11)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(formatAmount(item['amount']), style: GoogleFonts.outfit(color: Colors.greenAccent, fontSize: 14, fontWeight: FontWeight.bold)),
              const Icon(Icons.check_circle, color: Colors.greenAccent, size: 14),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCollectionTaskTile(BuildContext context, Map<String, dynamic> apt, String buildingName, String Function(dynamic) formatAmount) {
    final tenant = apt['tenant_name']?.toString() ?? 'Tenant';
    final aptCode = apt['apartment_number']?.toString() ?? apt['apartment_code']?.toString() ?? 'N/A';
    final remaining = _toDouble(apt['remaining'] ?? apt['amount']);
    final isPartial = (apt['invoice_status'] ?? '').toString() == 'Partial';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF060B10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isPartial ? Colors.amber.withValues(alpha: 0.3) : const Color(0xFF0D1620)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$tenant (Apt $aptCode)', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                Text('Invoice #${apt['invoice_id'] ?? 'INV'}', style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 11)),
                if (isPartial)
                  Text('Partial payment', style: GoogleFonts.inter(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(formatAmount(remaining), style: GoogleFonts.outfit(color: isPartial ? Colors.amber : Colors.greenAccent, fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              InkWell(
                onTap: () => _openReviewAndPayModal(context, {
                  'tenant_name': tenant,
                  'apartment_code': aptCode,
                  'building_name': buildingName,
                  'invoice_id': apt['invoice_id'],
                  'remaining': remaining,
                  'invoice_number': apt['invoice_number'] ?? '',
                  'type': (apt['invoice_type'] == 'electricity') ? 'Electricity Subscription' : 'Rent Apartment',
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(6)),
                  child: const Text('Collect', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openAddCollectionWizard(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddCollectionWizardModal(onRefresh: () {
        ref.invalidate(rentTasksProvider);
        ref.invalidate(rentHistoryByDateProvider);
      }),
    );
  }

  void _openReviewAndPayModal(BuildContext context, Map<String, dynamic> details) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ReviewAndPayModal(details: details, onRefresh: () {
        ref.invalidate(rentTasksProvider);
        ref.invalidate(rentHistoryByDateProvider);
      }),
    );
  }
}

// ─── Add Collection Wizard Modal (5-Step FSM) ─────────────────────────────────
// Step 1: Identify (QR Scan or Manual code)
// Step 2: Select Building (manual path)
// Step 3: Select Tenant / Apartment
// Step 4: Review Tenant Details
// Step 4.5 (step=5): Select Unpaid Invoice
// Step 5 (step=6): QR/Code Authorization
// → Pay Modal opens

class _AddCollectionWizardModal extends ConsumerStatefulWidget {
  final VoidCallback onRefresh;
  const _AddCollectionWizardModal({required this.onRefresh});

  @override
  ConsumerState<_AddCollectionWizardModal> createState() => _AddCollectionWizardModalState();
}

class _AddCollectionWizardModalState extends ConsumerState<_AddCollectionWizardModal> {
  int _step = 1;
  String? _collectionType;
  Map<String, dynamic>? _selectedBuilding;
  Map<String, dynamic>? _selectedTenantApt;
  Map<String, dynamic>? _selectedInvoice;
  List<dynamic> _unpaidInvoices = [];
  bool _loadingInvoices = false;
  bool _loadingLookup = false;

  // Step 6: QR authorization
  final TextEditingController _qrAuthCtrl = TextEditingController();
  bool _validatingQr = false;
  String? _qrError;

  final TextEditingController _invoiceCodeCtrl = TextEditingController();
  final TextEditingController _searchTenantCtrl = TextEditingController();
  String _tenantSearchQuery = '';

  @override
  void dispose() {
    _invoiceCodeCtrl.dispose();
    _searchTenantCtrl.dispose();
    _qrAuthCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final buildingsAsync = ref.watch(buildingsListProvider);

    String stepTitle = 'Add Collection';
    switch (_step) {
      case 1: stepTitle = 'Identify Payment'; break;
      case 2: stepTitle = 'Select Building'; break;
      case 3: stepTitle = 'Select Tenant'; break;
      case 4: stepTitle = 'Review Details'; break;
      case 5: stepTitle = 'Select Invoice'; break;
      case 6: stepTitle = 'Authorize Collection'; break;
    }

    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: Color(0xFF060B10),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      if (_step > 1)
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => setState(() {
                            if (_step == 5) { _step = 4; }
                            else if (_step == 6) { _step = 5; }
                            else { _step--; }
                            _qrError = null;
                          }),
                        ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(stepTitle, style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          Text('Step $_step of 6', style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 11)),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.blueGrey),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),

              // Progress indicator
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: LinearProgressIndicator(
                  value: _step / 6.0,
                  backgroundColor: const Color(0xFF0D1620),
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 10),

              // ── Step 1: Identify ──────────────────────────────────────────
              if (_step == 1) ...[
                Text('Scan the tenant\'s QR code or enter the manual invoice code, or use manual search.', style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 12)),
                const SizedBox(height: 16),

                InkWell(
                  onTap: () async {
                    final result = await context.push<String?>('/qr-scanner');
                    if (result != null && result.isNotEmpty && mounted) {
                      _processQrResult(result);
                    }
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D1620),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.primary.withValues(alpha: 0.4), width: 1.5),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.qr_code_scanner_rounded, size: 40, color: AppTheme.primary),
                        const SizedBox(height: 8),
                        Text('Scan QR Code', style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        Text('Scan tenant\'s invoice QR code', style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 12)),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                Row(children: [const Expanded(child: Divider(color: Color(0xFF0D1620))), Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text('OR', style: GoogleFonts.inter(color: Colors.blueGrey, fontSize: 11, fontWeight: FontWeight.bold))), const Expanded(child: Divider(color: Color(0xFF0D1620)))]),
                const SizedBox(height: 16),

                Text('Manual Invoice Code', style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _invoiceCodeCtrl,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'E.g., INV-202610-18',
                          hintStyle: const TextStyle(color: Colors.blueGrey, fontSize: 13),
                          filled: true,
                          fillColor: const Color(0xFF0D1620),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1D3347))),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1D3347))),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    if (_loadingLookup)
                      const SizedBox(width: 50, child: Center(child: CircularProgressIndicator(color: AppTheme.primary)))
                    else
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14)),
                        onPressed: () => _findManualInvoice(_invoiceCodeCtrl.text.trim()),
                        child: const Text('Find', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),

                const SizedBox(height: 20),
                Text('OR MANUAL SEARCH', style: GoogleFonts.inter(color: Colors.blueGrey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                const SizedBox(height: 10),

                _buildManualSearchOption('Rent Apartment', Icons.home_work_outlined, () {
                  setState(() { _collectionType = 'Rent Apartment'; _step = 2; });
                }),
                _buildManualSearchOption('Electricity Subscription', Icons.bolt, () {
                  setState(() { _collectionType = 'Electricity Subscription'; _step = 2; });
                }),
              ],

              // ── Step 2: Select Building ────────────────────────────────────
              if (_step == 2) ...[
                Text('Select the building for this collection.', style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 12)),
                const SizedBox(height: 16),
                buildingsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
                  error: (e, _) => Text('Error loading buildings: $e', style: const TextStyle(color: Colors.red)),
                  data: (buildings) {
                    if (buildings.isEmpty) {
                      return const Text('No buildings available.', style: TextStyle(color: Colors.blueGrey));
                    }
                    return Expanded(
                      child: ListView.builder(
                        itemCount: buildings.length,
                        itemBuilder: (ctx, i) {
                          final b = buildings[i] as Map<String, dynamic>;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(color: const Color(0xFF0D1620), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF1D3347))),
                            child: ListTile(
                              leading: const Icon(Icons.apartment, color: Color(0xFF00D4AA)),
                              title: Text(b['name']?.toString() ?? 'Building', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
                              trailing: const Icon(Icons.chevron_right, color: Colors.blueGrey),
                              onTap: () => setState(() { _selectedBuilding = b; _step = 3; }),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ],

              // ── Step 3: Select Tenant / Apartment ─────────────────────────
              if (_step == 3) ...[
                Text('Scoped to: ${_selectedBuilding?['name'] ?? ''}', style: GoogleFonts.inter(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                TextField(
                  controller: _searchTenantCtrl,
                  onChanged: (v) => setState(() => _tenantSearchQuery = v.toLowerCase()),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search by name or apt #...',
                    hintStyle: const TextStyle(color: Colors.blueGrey, fontSize: 13),
                    prefixIcon: const Icon(Icons.person_search, color: Colors.blueGrey),
                    filled: true,
                    fillColor: const Color(0xFF0D1620),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1D3347))),
                  ),
                ),
                const SizedBox(height: 12),
                Consumer(builder: (context, ref, _) {
                  final bId = _selectedBuilding?['id']?.toString() ?? '';
                  final aptsAsync = ref.watch(buildingApartmentsProvider(bId));
                  return aptsAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
                    error: (e, _) => Text('Error: $e', style: const TextStyle(color: Colors.red)),
                    data: (apts) {
                      final filtered = apts.where((apt) {
                        if (_tenantSearchQuery.isEmpty) return true;
                        final name = (apt['tenant_name'] ?? '').toString().toLowerCase();
                        final code = (apt['apartment_code'] ?? apt['code'] ?? '').toString().toLowerCase();
                        return name.contains(_tenantSearchQuery) || code.contains(_tenantSearchQuery);
                      }).toList();
                      if (filtered.isEmpty) {
                        return const Center(child: Text('No active tenants found.', style: TextStyle(color: Colors.blueGrey)));
                      }
                      return Expanded(
                        child: ListView.builder(
                          itemCount: filtered.length,
                          itemBuilder: (ctx, i) {
                            final item = filtered[i] as Map<String, dynamic>;
                            final tenantName = item['tenant_name']?.toString() ?? 'No active tenant';
                            final aptCode = item['apartment_code']?.toString() ?? item['code']?.toString() ?? 'N/A';
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(color: const Color(0xFF0D1620), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF1D3347))),
                              child: ListTile(
                                leading: const Icon(Icons.person, color: AppTheme.primary),
                                title: Text(tenantName, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
                                subtitle: Text('Apt $aptCode', style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 12)),
                                onTap: () async {
                                  setState(() { _selectedTenantApt = item; _step = 4; });
                                },
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                }),
              ],

              // ── Step 4: Review Tenant Details ──────────────────────────────
              if (_step == 4) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: const Color(0xFF0D1620), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3))),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [const Icon(Icons.info_outline, color: AppTheme.primary, size: 18), const SizedBox(width: 8), Text('Tenant Information', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))]),
                      const SizedBox(height: 12),
                      _buildDetailRow('Name:', _selectedTenantApt?['tenant_name']?.toString() ?? 'N/A'),
                      _buildDetailRow('Apartment:', _selectedTenantApt?['apartment_code']?.toString() ?? 'N/A'),
                      _buildDetailRow('Building:', _selectedBuilding?['name']?.toString() ?? 'N/A'),
                      _buildDetailRow('Lease Status:', 'Active', isSuccess: true),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: _loadingInvoices
                      ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                      : ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, padding: const EdgeInsets.symmetric(vertical: 14)),
                          onPressed: _loadUnpaidInvoices,
                          child: const Text('View Unpaid Invoices →', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                ),
              ],

              // ── Step 5: Select Invoice ─────────────────────────────────────
              if (_step == 5) ...[
                Text('Select which invoice to collect payment for:', style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 12)),
                const SizedBox(height: 12),
                if (_unpaidInvoices.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: const Color(0xFF0D1620), borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      children: [
                        const Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 36),
                        const SizedBox(height: 8),
                        Text('No unpaid invoices found!', style: GoogleFonts.inter(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                        Text('This tenant has no outstanding rent invoices.', style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 12)),
                      ],
                    ),
                  )
                else
                  Expanded(
                    child: Consumer(builder: (ctx, ref, _) {
                      final formatAmount = ref.watch(formatAmountProvider);
                      return ListView.builder(
                        itemCount: _unpaidInvoices.length,
                        itemBuilder: (ctx, i) {
                          final inv = _unpaidInvoices[i] as Map<String, dynamic>;
                          final remaining = _toDouble(inv['remaining']);
                          final dueDate = inv['due_date']?.toString() ?? '';
                          final period = (inv['period_start'] != null && inv['period_end'] != null)
                              ? '${inv['period_start']} → ${inv['period_end']}'
                              : dueDate;
                          final isPartial = (inv['invoice_status'] ?? '').toString() == 'Partial';
                          bool isPastDue = false;
                          if (dueDate.isNotEmpty) {
                            try {
                              final parsedDate = DateTime.parse(dueDate);
                              final now = DateTime.now();
                              final today = DateTime(now.year, now.month, now.day);
                              if (parsedDate.isBefore(today)) {
                                isPastDue = true;
                              }
                            } catch (_) {}
                          }

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0D1620),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: isPartial ? Colors.amber.withValues(alpha: 0.4) : const Color(0xFF1D3347)),
                            ),
                            child: ListTile(
                              title: Text(inv['invoice_number']?.toString() ?? 'Invoice', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                              subtitle: Row(
                                children: [
                                  if (isPastDue) ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                      margin: const EdgeInsets.only(right: 6),
                                      decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                                      child: const Text('EXPIRED', style: TextStyle(color: Colors.redAccent, fontSize: 9, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                  Text(period, style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 11)),
                                ],
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(formatAmount(remaining), style: GoogleFonts.outfit(color: isPartial ? Colors.amber : (isPastDue ? Colors.redAccent : Colors.greenAccent), fontSize: 13, fontWeight: FontWeight.bold)),
                                  if (isPartial) Text('Partial', style: TextStyle(color: Colors.amber, fontSize: 10)),
                                ],
                              ),
                              onTap: () => setState(() { _selectedInvoice = inv; _step = 6; _qrError = null; }),
                            ),
                          );
                        },
                      );
                    }),
                  ),
              ],

              // ── Step 6: QR / Code Authorization ───────────────────────────
              if (_step == 6) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: const Color(0xFF0D1620), borderRadius: BorderRadius.circular(12)),
                  child: Consumer(builder: (ctx, ref, _) {
                    final formatAmount = ref.watch(formatAmountProvider);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Selected Invoice', style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 11)),
                        const SizedBox(height: 4),
                        Text(_selectedInvoice?['invoice_number']?.toString() ?? '', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
                        Text('Due: ${formatAmount(_selectedInvoice?['remaining'])}', style: GoogleFonts.inter(color: Colors.greenAccent, fontSize: 12)),
                      ],
                    );
                  }),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade900.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.security, color: Colors.amber, size: 20),
                      const SizedBox(width: 10),
                      Expanded(child: Text('Security Check: Ask the tenant to show their QR code for this invoice, or enter the invoice number for verification.', style: GoogleFonts.inter(color: Colors.amber, fontSize: 12))),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Scan QR button
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(foregroundColor: AppTheme.primary, side: BorderSide(color: AppTheme.primary.withValues(alpha: 0.5))),
                  icon: const Icon(Icons.qr_code_scanner_rounded),
                  label: const Text('Scan Tenant QR'),
                  onPressed: () async {
                    final result = await context.push<String?>('/qr-scanner');
                    if (result != null && result.isNotEmpty && mounted) {
                      _qrAuthCtrl.text = result;
                    }
                  },
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _qrAuthCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Invoice Code / QR Value',
                    labelStyle: const TextStyle(color: Colors.blueGrey),
                    hintText: 'Or type invoice number here...',
                    hintStyle: const TextStyle(color: Colors.blueGrey, fontSize: 13),
                    filled: true,
                    fillColor: const Color(0xFF0D1620),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1D3347))),
                  ),
                ),
                if (_qrError != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: AppTheme.danger.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: AppTheme.danger.withValues(alpha: 0.3))),
                    child: Text(_qrError!, style: const TextStyle(color: AppTheme.danger, fontSize: 12)),
                  ),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: _validatingQr
                      ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                      : ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 14)),
                          icon: const Icon(Icons.verified_outlined, color: Colors.white),
                          label: const Text('Verify & Proceed to Payment', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          onPressed: _validateAndProceed,
                        ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildManualSearchOption(String label, IconData icon, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(color: const Color(0xFF0D1620), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF1D3347))),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primary),
        title: Text(label, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
        trailing: const Icon(Icons.chevron_right, color: Colors.blueGrey),
        onTap: onTap,
      ),
    );
  }

  Widget _buildDetailRow(String label, String val, {bool isSuccess = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text(label, style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 12))),
          Expanded(child: Text(val, style: GoogleFonts.inter(color: isSuccess ? AppTheme.success : Colors.white, fontSize: 13, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  void _processQrResult(String payload) {
    // QR codes from tenant portal may be JSON or plain invoice number
    try {
      final decoded = jsonDecode(payload) as Map<String, dynamic>;
      final invId = decoded['invoiceId'] ?? decoded['invoice_number'] ?? decoded['id'];
      if (invId != null) {
        _findManualInvoice(invId.toString());
        return;
      }
    } catch (_) {}
    _findManualInvoice(payload);
  }

  /// Real API lookup — replaces the old hardcoded fake data
  Future<void> _findManualInvoice(String code) async {
    if (code.isEmpty) return;
    setState(() => _loadingLookup = true);
    try {
      final invoice = await AgentApi.instance.lookupInvoice(code);
      if (!mounted) return;
      if (invoice == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invoice not found or already paid.', style: TextStyle(color: Colors.white)), backgroundColor: Colors.red),
        );
        setState(() => _loadingLookup = false);
        return;
      }
      setState(() => _loadingLookup = false);
      // Found → go directly to QR auth step with this invoice pre-selected
      Navigator.pop(context);
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => _ReviewAndPayModal(
          details: {
            'tenant_name': invoice['tenant_name'] ?? 'Tenant',
            'apartment_code': invoice['apartment_code'] ?? 'N/A',
            'building_name': invoice['building_name'] ?? 'Property',
            'invoice_id': invoice['invoice_id'],
            'invoice_number': invoice['invoice_number'] ?? code,
            'remaining': _toDouble(invoice['remaining']),
            'type': (invoice['invoice_type'] == 'electricity') ? 'Electricity Subscription' : 'Rent Apartment',
          },
          onRefresh: widget.onRefresh,
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _loadingLookup = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e', style: const TextStyle(color: Colors.white)), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _loadUnpaidInvoices() async {
    final aptId = _selectedTenantApt?['apartment_id'];
    if (aptId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Apartment ID not found.')));
      return;
    }
    setState(() => _loadingInvoices = true);
    final invoices = await AgentApi.instance.getApartmentUnpaidInvoices(int.parse(aptId.toString()));
    if (mounted) {
      setState(() {
        _unpaidInvoices = invoices;
        _loadingInvoices = false;
        _step = 5;
      });
    }
  }

  Future<void> _validateAndProceed() async {
    final qrVal = _qrAuthCtrl.text.trim();
    if (qrVal.isEmpty) {
      setState(() => _qrError = 'Please scan or enter the invoice code to verify.');
      return;
    }
    final invoiceId = _selectedInvoice?['invoice_id'];
    if (invoiceId == null) {
      setState(() => _qrError = 'No invoice selected.');
      return;
    }

    setState(() { _validatingQr = true; _qrError = null; });
    final result = await AgentApi.instance.validateQrCode(invoiceId: int.parse(invoiceId.toString()), qrCode: qrVal);
    if (!mounted) return;
    setState(() => _validatingQr = false);

    if (result['valid'] == true) {
      Navigator.pop(context);
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => _ReviewAndPayModal(
          details: {
            'tenant_name': _selectedTenantApt?['tenant_name'] ?? 'Tenant',
            'apartment_code': _selectedTenantApt?['apartment_code'] ?? 'N/A',
            'building_name': _selectedBuilding?['name'] ?? 'Building',
            'invoice_id': _selectedInvoice?['invoice_id'],
            'invoice_number': _selectedInvoice?['invoice_number'] ?? '',
            'remaining': _toDouble(_selectedInvoice?['remaining']),
            'type': (_selectedInvoice?['invoice_type'] == 'electricity') ? 'Electricity Subscription' : (_collectionType ?? 'Rent Apartment'),
          },
          onRefresh: widget.onRefresh,
        ),
      );
    } else {
      setState(() => _qrError = result['message']?.toString() ?? 'QR code does not match. Please ask the tenant to show the correct QR.');
    }
  }
}

// ─── Payment Collection Modal ─────────────────────────────────────────────────

class _ReviewAndPayModal extends ConsumerStatefulWidget {
  final Map<String, dynamic> details;
  final VoidCallback onRefresh;

  const _ReviewAndPayModal({required this.details, required this.onRefresh});

  @override
  ConsumerState<_ReviewAndPayModal> createState() => _ReviewAndPayModalState();
}

class _ReviewAndPayModalState extends ConsumerState<_ReviewAndPayModal> {
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  String _paymentMethod = 'Cash';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final rem = _toDouble(widget.details['remaining']);
    _amountController.text = rem > 0 ? rem.toStringAsFixed(0) : '';
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitPayment() async {
    setState(() => _isLoading = true);
    try {
      final amount = double.tryParse(_amountController.text.trim());
      if (amount == null || amount <= 0) throw Exception('Please enter a valid amount');

      await AgentApi.instance.collectRent({
        'invoice_id': widget.details['invoice_id'],
        'amount': amount,
        'method': _paymentMethod,
        'notes': _notesController.text,
        'type': widget.details['type'] ?? 'rent',
      });

      if (widget.details['type'] == 'Electricity Subscription') {
        final prefs = await SharedPreferences.getInstance();
        final cacheStr = prefs.getString('local_elec_history');
        final List<dynamic> elecHistory = cacheStr != null ? jsonDecode(cacheStr) : [];
        elecHistory.add({
          'date': DateTime.now().toIso8601String(),
          'amount': amount,
          'tenant_name': widget.details['tenant_name'],
          'building_name': widget.details['building_name'],
          'apartment_number': widget.details['apartment_code'] ?? widget.details['apartment_number'] ?? '',
          'type': 'electricity'
        });
        await prefs.setString('local_elec_history', jsonEncode(elecHistory));
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment collected successfully ✓', style: TextStyle(color: Colors.white)), backgroundColor: Colors.green),
        );
        widget.onRefresh();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e', style: const TextStyle(color: Colors.white)), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.details;
    final formatAmount = ref.watch(formatAmountProvider);
    final remaining = _toDouble(d['remaining']);

    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 20, left: 20, right: 20, top: 20),
      decoration: const BoxDecoration(
        color: Color(0xFF060B10),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Collect Payment', style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.close, color: Colors.blueGrey), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 12),

            // Invoice Info
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: const Color(0xFF0D1620), borderRadius: BorderRadius.circular(14)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(d['tenant_name']?.toString() ?? 'Tenant', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                          Text('Apt ${d['apartment_code']} • ${d['building_name']}', style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 12)),
                        ],
                      ),
                      Text(formatAmount(remaining), style: GoogleFonts.outfit(color: Colors.greenAccent, fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  if (d['invoice_number'] != null && d['invoice_number'].toString().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text('Invoice: ${d['invoice_number']}', style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 11)),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Amount input
            Text('Amount Received', style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: '0',
                hintStyle: const TextStyle(color: Colors.blueGrey),
                filled: true,
                fillColor: const Color(0xFF0D1620),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1D3347))),
              ),
            ),
            const SizedBox(height: 16),

            // Payment method
            Text('Payment Method', style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Row(
              children: ['Cash', 'Bank Transfer', 'Mobile Money'].map((method) {
                final isSelected = _paymentMethod == method;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _paymentMethod = method),
                    child: Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.primary : const Color(0xFF0D1620),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text(method, style: TextStyle(color: isSelected ? Colors.white : Colors.blueGrey, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 16),
            Text('Notes / Receipt Number', style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            TextField(
              controller: _notesController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Receipt number or notes...',
                hintStyle: const TextStyle(color: Colors.blueGrey, fontSize: 13),
                filled: true,
                fillColor: const Color(0xFF0D1620),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1D3347))),
              ),
            ),

            const SizedBox(height: 24),
            if (_isLoading)
              const Center(child: CircularProgressIndicator(color: AppTheme.primary))
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 14)),
                  onPressed: _submitPayment,
                  child: const Text('Confirm Payment', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
