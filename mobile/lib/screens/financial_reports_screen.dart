import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../config/app_theme.dart';
import '../services/api_service.dart';

final frBuildingsProvider = FutureProvider<List<dynamic>>((ref) async {
  final res = await ApiService().get('/buildings');
  return res.data as List<dynamic>;
});

final financialReportProvider = FutureProvider.family<List<dynamic>, String>((ref, query) async {
  final res = await ApiService().get('/financial-reports/generate?$query');
  return res.data as List<dynamic>;
});

class FinancialReportsScreen extends ConsumerStatefulWidget {
  const FinancialReportsScreen({super.key});

  @override
  ConsumerState<FinancialReportsScreen> createState() => _FinancialReportsScreenState();
}

class _FinancialReportsScreenState extends ConsumerState<FinancialReportsScreen> {
  DateTime _startDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _endDate = DateTime(DateTime.now().year, DateTime.now().month + 1, 0);
  String? _selectedBuildingId;
  
  String _formatNum(dynamic value) {
    if (value == null) return '0';
    try {
      final double val = value is String ? double.parse(value) : value.toDouble();
      return NumberFormat('#,##0').format(val);
    } catch (e) {
      return '0';
    }
  }

  Future<void> _pickDateRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(primary: AppTheme.primary, surface: AppTheme.surface),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bAsync = ref.watch(frBuildingsProvider);
    
    final startStr = DateFormat('yyyy-MM-dd').format(_startDate);
    final endStr = DateFormat('yyyy-MM-dd').format(_endDate);
    
    final query = 'start_date=$startStr&end_date=$endStr&building_id=${_selectedBuildingId ?? ''}';
    final reportAsync = ref.watch(financialReportProvider(query));

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('Financial Reports', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
        backgroundColor: AppTheme.surface,
        elevation: 0,
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.surfaceHover),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Filters', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () => _pickDateRange(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(color: AppTheme.background, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.surfaceHover)),
                      child: Row(
                        children: [
                          const Icon(Icons.date_range, color: AppTheme.primary, size: 20),
                          const SizedBox(width: 12),
                          Text('$startStr  →  $endStr', style: const TextStyle(color: Colors.white, fontSize: 14)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  bAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Text('Error: $e', style: const TextStyle(color: AppTheme.danger)),
                    data: (buildings) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(color: AppTheme.background, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.surfaceHover)),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            dropdownColor: AppTheme.surface,
                            hint: const Text('Select Building', style: TextStyle(color: AppTheme.textSecondary)),
                            value: _selectedBuildingId,
                            items: [
                              const DropdownMenuItem(value: null, child: Text('All Buildings', style: TextStyle(color: Colors.white))),
                              ...buildings.map((b) => DropdownMenuItem(
                                value: b['id'].toString(),
                                child: Text(b['name'] ?? 'Unknown', style: const TextStyle(color: Colors.white)),
                              ))
                            ],
                            onChanged: (val) {
                              setState(() {
                                _selectedBuildingId = val;
                              });
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          
          if (_selectedBuildingId == null)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: Text('Select a building to generate report', style: TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
                ),
              ),
            )
          else
            reportAsync.when(
              loading: () => const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()))),
              error: (e, _) => SliverToBoxAdapter(child: Center(child: Text('Error: $e', style: const TextStyle(color: AppTheme.danger)))),
              data: (data) {
                if (data.isEmpty) return const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(32), child: Text('No data found for this period.', style: TextStyle(color: AppTheme.textSecondary)))));
                
                double totalRent = 0;
                double totalOutstanding = 0;
                double totalExpenses = 0;
                double netIncome = 0;
                
                for (var r in data) {
                  final s = r['summary'];
                  if (s != null) {
                    totalRent += double.tryParse(s['total_rent_collected']?.toString() ?? '0') ?? 0;
                    totalOutstanding += double.tryParse(s['total_rent_outstanding']?.toString() ?? '0') ?? 0;
                    totalExpenses += double.tryParse(s['total_expenses']?.toString() ?? '0') ?? 0;
                    netIncome += double.tryParse(s['net_income']?.toString() ?? '0') ?? 0;
                  }
                }
                
                return SliverList(
                  delegate: SliverChildListDelegate([
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: GridView.count(
                        crossAxisCount: MediaQuery.of(context).size.width > 500 ? 4 : 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.3,
                        children: [
                          _buildStatCard('Rent Collected', totalRent, AppTheme.success, Icons.check_circle_outline),
                          _buildStatCard('Rent Outstanding', totalOutstanding, AppTheme.danger, Icons.warning_amber_rounded),
                          _buildStatCard('Total Expenses', totalExpenses, AppTheme.warning, Icons.shopping_cart_outlined),
                          _buildStatCard('Net Income', netIncome, AppTheme.primary, Icons.account_balance_wallet_outlined),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text('Apartment Breakdown', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                    const SizedBox(height: 12),
                    ...data.map((r) {
                      final aptCode = r['apartment_code'] ?? '-';
                      final tenant = r['tenant_name'] ?? 'Vacant';
                      final s = r['summary'] ?? {};
                      final rentPaid = double.tryParse(s['total_rent_collected']?.toString() ?? '0') ?? 0;
                      final rentOwe = double.tryParse(s['total_rent_outstanding']?.toString() ?? '0') ?? 0;
                      final net = double.tryParse(s['net_income']?.toString() ?? '0') ?? 0;
                      
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.surfaceHover)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Apt $aptCode', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                                  child: Text('Net: CFA ${_formatNum(net)}', style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                                ),
                              ],
                            ),
                            Text(tenant, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildMiniStat('Paid', rentPaid, AppTheme.success),
                                _buildMiniStat('Owes', rentOwe, rentOwe > 0 ? AppTheme.danger : AppTheme.textSecondary),
                              ],
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    const SizedBox(height: 24),
                  ]),
                );
              },
            ),
        ],
      ),
    );
  }
  
  Widget _buildStatCard(String title, double value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color.withOpacity(0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withOpacity(0.3))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Expanded(child: Text(title, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
            ],
          ),
          const Spacer(),
          Text('CFA', style: TextStyle(color: color.withOpacity(0.7), fontSize: 10, fontWeight: FontWeight.bold)),
          Text(_formatNum(value), style: GoogleFonts.outfit(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
  
  Widget _buildMiniStat(String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
        Text('CFA ${_formatNum(value)}', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}
