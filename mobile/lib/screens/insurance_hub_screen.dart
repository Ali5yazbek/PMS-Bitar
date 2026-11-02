import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../config/app_theme.dart';
import '../services/api_service.dart';

final insuranceDashboardProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, query) async {
  final res = await ApiService().get('/insurance/dashboard?$query');
  return res.data as Map<String, dynamic>;
});

final insuranceAccountsProvider = FutureProvider.family<List<dynamic>, String>((ref, query) async {
  final res = await ApiService().get('/insurance/accounts?$query');
  return res.data as List<dynamic>;
});

class InsuranceHubScreen extends ConsumerStatefulWidget {
  const InsuranceHubScreen({super.key});

  @override
  ConsumerState<InsuranceHubScreen> createState() => _InsuranceHubScreenState();
}

class _InsuranceHubScreenState extends ConsumerState<InsuranceHubScreen> {
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  String _formatNum(dynamic value) {
    if (value == null) return '0';
    try {
      final double val = value is String ? double.parse(value) : value.toDouble();
      return NumberFormat('#,##0').format(val);
    } catch (e) {
      return '0';
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = 'month=$_selectedMonth&year=$_selectedYear';
    final dashboardAsync = ref.watch(insuranceDashboardProvider(query));
    final accountsAsync = ref.watch(insuranceAccountsProvider(query));

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('Insurance Hub', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
        backgroundColor: AppTheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_rounded, color: AppTheme.primary),
            onPressed: _showDatePicker,
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: dashboardAsync.when(
              loading: () => const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator())),
              error: (e, _) => Center(child: Text('Error loading stats: $e', style: const TextStyle(color: AppTheme.danger))),
              data: (stats) => _buildDashboardCards(stats),
            ),
          ),
          SliverToBoxAdapter(
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text('Insurance by Property', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
          accountsAsync.when(
            loading: () => const SliverToBoxAdapter(child: SizedBox()),
            error: (e, _) => SliverToBoxAdapter(child: Text('Error: $e', style: const TextStyle(color: AppTheme.danger))),
            data: (accounts) {
              final grouped = <String, List<dynamic>>{};
              for (var acc in accounts) {
                final bName = acc['building_name'] ?? 'Unknown Building';
                grouped.putIfAbsent(bName, () => []).add(acc);
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final buildingName = grouped.keys.elementAt(index);
                    final bAccounts = grouped[buildingName]!;
                    
                    double totalRequired = 0;
                    double totalHeld = 0;
                    for (var a in bAccounts) {
                      totalRequired += double.tryParse(a['monthly_insurance']?.toString() ?? '0') ?? 0;
                      totalHeld += double.tryParse(a['total_saved']?.toString() ?? '0') ?? 0;
                    }

                    final heldPercent = totalRequired > 0 ? (totalHeld / totalRequired) * 100 : 0;

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      color: AppTheme.surface,
                      child: ExpansionTile(
                        title: Text(buildingName, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                        subtitle: Text('${bAccounts.length} Active Accounts', style: const TextStyle(color: AppTheme.textSecondary)),
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.background,
                              border: Border(top: BorderSide(color: AppTheme.surfaceHover)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildStatColumn('Total Required', totalRequired, AppTheme.textSecondary),
                                _buildStatColumn('Total Held', totalHeld, AppTheme.primary),
                                Column(
                                  children: [
                                    const Text('STATUS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                                    const SizedBox(height: 4),
                                    Text('${heldPercent.toStringAsFixed(0)}%', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: heldPercent >= 100 ? AppTheme.success : AppTheme.warning)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          ...bAccounts.map((acc) => ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                leading: const CircleAvatar(backgroundColor: AppTheme.surfaceHover, child: Icon(Icons.person, color: AppTheme.textSecondary)),
                                title: Text(acc['tenant_name'] ?? 'Unknown Tenant', style: const TextStyle(color: Colors.white)),
                                subtitle: Text('Apt ${acc['apartment_code'] ?? '-'}', style: const TextStyle(color: AppTheme.textSecondary)),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text('CFA ${_formatNum(acc['total_saved'])}', style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
                                    Text('of CFA ${_formatNum(acc['monthly_insurance'])}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
                                  ],
                                ),
                              )).toList(),
                        ],
                      ),
                    );
                  },
                  childCount: grouped.keys.length,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardCards(Map<String, dynamic> stats) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isTablet = constraints.maxWidth > 500;
          return GridView.count(
            crossAxisCount: isTablet ? 4 : 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: isTablet ? 1.5 : 1.2,
            children: [
              _buildMetricCard('Net Collected', stats['net_insurance'], AppTheme.success, Icons.account_balance_wallet_rounded),
              _buildMetricCard('Refunded', stats['total_refunds'], AppTheme.warning, Icons.replay_rounded),
              _buildMetricCard('Deducted', stats['total_deducts'], AppTheme.danger, Icons.error_outline_rounded),
              _buildMetricCard('Total Held', stats['current_balance'], AppTheme.primary, Icons.shield_rounded),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMetricCard(String title, dynamic value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(title, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const Spacer(),
          Text('CFA', style: TextStyle(color: color.withOpacity(0.7), fontSize: 10, fontWeight: FontWeight.bold)),
          Text(_formatNum(value), style: GoogleFonts.outfit(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, double amount, Color color) {
    return Column(
      children: [
        Text(label.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
        const SizedBox(height: 4),
        Text('CFA ${_formatNum(amount)}', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  void _showDatePicker() {
    // Simple bottom sheet to pick month and year
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Select Date', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    DropdownButton<int>(
                      value: _selectedMonth,
                      dropdownColor: AppTheme.surface,
                      items: List.generate(12, (i) => i + 1).map((m) {
                        return DropdownMenuItem(
                          value: m,
                          child: Text(DateFormat('MMMM').format(DateTime(2000, m)), style: const TextStyle(color: Colors.white)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedMonth = val);
                        Navigator.pop(context);
                      },
                    ),
                    DropdownButton<int>(
                      value: _selectedYear,
                      dropdownColor: AppTheme.surface,
                      items: [2023, 2024, 2025, 2026, 2027].map((y) {
                        return DropdownMenuItem(
                          value: y,
                          child: Text(y.toString(), style: const TextStyle(color: Colors.white)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedYear = val);
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
