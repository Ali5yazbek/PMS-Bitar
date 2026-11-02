import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../config/app_theme.dart';
import '../services/api_service.dart';

final financialBuildingsReportProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, query) async {
  final res = await ApiService().get('/reports/detailed-financial-buildings?$query');
  return res.data as Map<String, dynamic>;
});

class FinancialBuildingReportScreen extends ConsumerStatefulWidget {
  const FinancialBuildingReportScreen({super.key});

  @override
  ConsumerState<FinancialBuildingReportScreen> createState() => _FinancialBuildingReportScreenState();
}

class _FinancialBuildingReportScreenState extends ConsumerState<FinancialBuildingReportScreen> {
  DateTime _startDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _endDate = DateTime(DateTime.now().year, DateTime.now().month + 1, 0);

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
    final startStr = DateFormat('yyyy-MM-dd').format(_startDate);
    final endStr = DateFormat('yyyy-MM-dd').format(_endDate);
    
    final query = 'start_date=$startStr&end_date=$endStr';
    final reportAsync = ref.watch(financialBuildingsReportProvider(query));

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('Financial Building Report', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
        backgroundColor: AppTheme.surface,
        elevation: 0,
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: InkWell(
                onTap: () => _pickDateRange(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.surfaceHover)),
                  child: Row(
                    children: [
                      const Icon(Icons.date_range, color: AppTheme.primary),
                      const SizedBox(width: 16),
                      Text('$startStr  →  $endStr', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          reportAsync.when(
            loading: () => const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()))),
            error: (e, _) => SliverToBoxAdapter(child: Center(child: Text('Error: $e', style: const TextStyle(color: AppTheme.danger)))),
            data: (data) {
              final global = data['global'] ?? {};
              final buildings = (data['buildings'] as List<dynamic>?) ?? [];
              
              return SliverList(
                delegate: SliverChildListDelegate([
                  // Global Totals
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [AppTheme.primary.withOpacity(0.2), AppTheme.primaryDark.withOpacity(0.2)]),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
                      ),
                      child: Column(
                        children: [
                          Text('Global Totals All Buildings', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildGlobalStat('Income', global['total_income'], AppTheme.primaryLight),
                              _buildGlobalStat('Received', global['total_received'], AppTheme.success),
                              _buildGlobalStat('Remaining', global['total_remaining'], AppTheme.danger),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Buildings List
                  ...buildings.map((b) {
                    final bName = b['name'] ?? 'Unknown Building';
                    final apts = (b['apartments'] as List<dynamic>?) ?? [];
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      color: AppTheme.surface,
                      child: ExpansionTile(
                        initiallyExpanded: true,
                        title: Text(bName, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                        subtitle: Row(
                          children: [
                            Text('Income: CFA ${_formatNum(b['total_income'])}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                            const SizedBox(width: 8),
                            Text('Received: CFA ${_formatNum(b['total_received'])}', style: const TextStyle(color: AppTheme.success, fontSize: 12)),
                          ],
                        ),
                        children: [
                          if (b['total_remaining'] != null && double.tryParse(b['total_remaining'].toString()) != null && double.parse(b['total_remaining'].toString()) > 0)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              color: AppTheme.danger.withOpacity(0.1),
                              child: Text('Remaining Unpaid: CFA ${_formatNum(b['total_remaining'])}', style: const TextStyle(color: AppTheme.danger, fontWeight: FontWeight.bold, fontSize: 13)),
                            ),
                          const Divider(height: 1, color: AppTheme.surfaceHover),
                          ...apts.map((apt) {
                            final code = apt['code'] ?? '?';
                            final inc = double.tryParse(apt['total_income']?.toString() ?? '0') ?? 0;
                            final rec = double.tryParse(apt['total_received']?.toString() ?? '0') ?? 0;
                            final rem = double.tryParse(apt['total_remaining']?.toString() ?? '0') ?? 0;
                            
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              title: Text('Apartment $code', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              subtitle: Row(
                                children: [
                                  Text('CFA ${_formatNum(rec)}', style: const TextStyle(color: AppTheme.success, fontWeight: FontWeight.bold)),
                                  const Text(' / ', style: TextStyle(color: AppTheme.textSecondary)),
                                  Text('CFA ${_formatNum(inc)}', style: const TextStyle(color: AppTheme.textSecondary)),
                                ],
                              ),
                              trailing: rem > 0
                                ? Text('- CFA ${_formatNum(rem)}', style: const TextStyle(color: AppTheme.danger, fontWeight: FontWeight.bold))
                                : const Icon(Icons.check_circle, color: AppTheme.success, size: 20),
                            );
                          }).toList(),
                        ],
                      ),
                    );
                  }).toList(),
                  const SizedBox(height: 32),
                ]),
              );
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildGlobalStat(String label, dynamic value, Color color) {
    return Column(
      children: [
        Text(label.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textSecondary, letterSpacing: 1)),
        const SizedBox(height: 4),
        Text('CFA ${_formatNum(value)}', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}
