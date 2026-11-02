// ─── Reports Screen ───────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../config/app_theme.dart';
import '../services/api_service.dart';
import '../widgets/date_filter_bar.dart';

class DateFilterNotifier extends Notifier<DateTimeRange?> {
  @override
  DateTimeRange? build() => null;
  void updateFilter(DateTimeRange? range) => state = range;
}
final reportsDateFilterProvider = NotifierProvider<DateFilterNotifier, DateTimeRange?>(DateFilterNotifier.new);

// Providers for each report type
final rentCollectionProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final dateFilter = ref.watch(reportsDateFilterProvider);
  String query = '';
  if (dateFilter != null) {
    final start = DateFormat('yyyy-MM-dd').format(dateRangeStart(dateFilter));
    final end = DateFormat('yyyy-MM-dd').format(dateRangeEnd(dateFilter));
    query = '?start_date=$start&end_date=$end';
  }
  final res = await ApiService().get('/reports/rent-collection$query');
  final list = res.data as List<dynamic>;
  
  double totalInvoiced = 0;
  double totalPaid = 0;
  for (var item in list) {
    double amt = double.tryParse(item['amount']?.toString() ?? '0') ?? 0;
    totalPaid += amt;
    totalInvoiced += amt; // Assuming amount is what was paid and invoiced for this simple list
  }
  
  return {
    'summary': {
      'total_invoiced': totalInvoiced,
      'total_paid': totalPaid,
      'total_outstanding': 0,
    },
    'items': list,
  };
});

final outstandingBalanceProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  // Doesn't strictly need date filter but we can pass it if building is added later
  final res = await ApiService().get('/reports/outstanding-balance');
  final list = res.data as List<dynamic>;
  return {
    'items': list,
  };
});

DateTime dateRangeStart(DateTimeRange range) => range.start;
DateTime dateRangeEnd(DateTimeRange range) => range.end;

final contractExpirationProvider = FutureProvider<List<dynamic>>((ref) async {
  final res = await ApiService().get('/reports/contract-expiration');
  final data = res.data;
  if (data is List) return data;
  if (data is Map && data.containsKey('data')) return data['data'] as List<dynamic>;
  return [];
});

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});
  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          Consumer(
            builder: (context, ref, child) {
              return DateFilterBar(
                dateRange: ref.watch(reportsDateFilterProvider),
                onChanged: (range) => ref.read(reportsDateFilterProvider.notifier).updateFilter(range),
              );
            },
          ),
          // Tab bar
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
              ),
              labelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
              unselectedLabelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
              labelColor: Colors.white,
              unselectedLabelColor: AppTheme.textSecondary,
              dividerHeight: 0,
              tabs: const [
                Tab(text: 'Rent'),
                Tab(text: 'Outstanding'),
                Tab(text: 'Expiring'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _RentCollectionTab(),
                _OutstandingBalanceTab(),
                _ContractExpirationTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Tab 1: Rent Collection ────────────────────────────────────────────────────
class _RentCollectionTab extends ConsumerWidget {
  final fmt = NumberFormat('#,##0.00');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(rentCollectionProvider);
    return RefreshIndicator(
      color: AppTheme.primary,
      onRefresh: () async => ref.invalidate(rentCollectionProvider),
      child: async.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
        error: (e, _) => _ErrorWidget(onRetry: () => ref.invalidate(rentCollectionProvider)),
        data: (data) {
          final items = data['items'] as List<dynamic>;
          final summary = data['summary'] as Map<String, dynamic>?;
          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              if (summary != null) ...[
                _SummaryCard(
                  items: [
                    _SummaryItem('Total Invoiced', 'CFA ${fmt.format(_parse(summary['total_invoiced']))}', AppTheme.info),
                    _SummaryItem('Total Collected', 'CFA ${fmt.format(_parse(summary['total_paid']))}', AppTheme.success),
                    _SummaryItem('Outstanding', 'CFA ${fmt.format(_parse(summary['total_outstanding']))}', AppTheme.danger),
                  ],
                ),
                const SizedBox(height: 16),
              ],
              ...items.map((item) {
                final m = item as Map<String, dynamic>;
                return _ReportRow(
                  title: m['tenant_name']?.toString() ?? 'N/A',
                  subtitle: 'Apt ${m['apartment_number'] ?? ''} — ${m['building_name'] ?? ''}',
                  trailing: 'CFA ${fmt.format(_parse(m['amount']))}',
                  status: 'paid',
                );
              }),
            ],
          );
        },
      ),
    );
  }

  double _parse(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }
}

// ─── Tab 2: Outstanding Balances ──────────────────────────────────────────────
class _OutstandingBalanceTab extends ConsumerWidget {
  final fmt = NumberFormat('#,##0.00');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(outstandingBalanceProvider);
    return RefreshIndicator(
      color: AppTheme.primary,
      onRefresh: () async => ref.invalidate(outstandingBalanceProvider),
      child: async.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
        error: (e, _) => _ErrorWidget(onRetry: () => ref.invalidate(outstandingBalanceProvider)),
        data: (data) {
          final items = data['items'] as List<dynamic>;
          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              ...items.map((item) {
                final m = item as Map<String, dynamic>;
                final balance = _parse(m['outstanding_balance']);
                return _ReportRow(
                  title: m['tenant_name']?.toString() ?? 'N/A',
                  subtitle: 'Apt ${m['apartment_code'] ?? ''} — ${m['building_name'] ?? ''}',
                  trailing: 'CFA ${fmt.format(balance)}',
                  status: balance > 0 ? 'unpaid' : 'paid',
                );
              }),
            ],
          );
        },
      ),
    );
  }

  double _parse(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }
}

// ─── Tab 3: Contract Expiration ───────────────────────────────────────────────
class _ContractExpirationTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(contractExpirationProvider);
    return RefreshIndicator(
      color: AppTheme.primary,
      onRefresh: () async => ref.invalidate(contractExpirationProvider),
      child: async.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
        error: (e, _) => _ErrorWidget(onRetry: () => ref.invalidate(contractExpirationProvider)),
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, size: 64, color: AppTheme.success.withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  Text('No expiring contracts', style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 16)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: items.length,
            itemBuilder: (ctx, i) {
              final m = items[i] as Map<String, dynamic>;
              final expiry = m['end_date']?.toString() ?? m['expiry_date']?.toString() ?? '';
              String daysLeft = '';
              try {
                final d = DateTime.parse(expiry);
                final diff = d.difference(DateTime.now()).inDays;
                daysLeft = diff >= 0 ? '$diff days left' : 'Expired ${diff.abs()} days ago';
              } catch (_) {}
              return _ReportRow(
                title: m['tenant_name']?.toString() ?? 'N/A',
                subtitle: 'Apt ${m['apartment_number'] ?? ''} — ${m['building_name'] ?? ''}',
                trailing: daysLeft,
                status: daysLeft.contains('Expired') ? 'expired' : 'expiring',
              );
            },
          );
        },
      ),
    );
  }
}

// ─── Shared Widgets ────────────────────────────────────────────────────────────
class _SummaryCard extends StatelessWidget {
  final List<_SummaryItem> items;
  const _SummaryCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.surfaceHover),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: items.map((item) => Column(
          children: [
            Text(item.label, style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 11)),
            const SizedBox(height: 4),
            Text(item.value, style: GoogleFonts.outfit(color: item.color, fontSize: 14, fontWeight: FontWeight.w700)),
          ],
        )).toList(),
      ),
    );
  }
}

class _SummaryItem {
  final String label;
  final String value;
  final Color color;
  const _SummaryItem(this.label, this.value, this.color);
}

class _ReportRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final String trailing;
  final String status;

  const _ReportRow({required this.title, required this.subtitle, required this.trailing, required this.status});

  Color _statusColor() {
    switch (status) {
      case 'paid': return AppTheme.success;
      case 'unpaid': return AppTheme.danger;
      case 'partial': return AppTheme.warning;
      case 'expired': return AppTheme.danger;
      case 'expiring': return AppTheme.warning;
      default: return AppTheme.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.surfaceHover),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.outfit(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(subtitle, style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 12)),
                ],
              ],
            ),
          ),
          Text(trailing, style: GoogleFonts.outfit(color: _statusColor(), fontSize: 14, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _ErrorWidget extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorWidget({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: AppTheme.danger, size: 48),
          const SizedBox(height: 16),
          Text('Failed to load report', style: GoogleFonts.inter(color: Colors.white)),
          const SizedBox(height: 8),
          TextButton.icon(icon: const Icon(Icons.refresh), label: const Text('Retry'), onPressed: onRetry),
        ],
      ),
    );
  }
}
