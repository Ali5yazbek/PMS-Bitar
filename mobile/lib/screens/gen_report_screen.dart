// ─── Generator Report Screen ──────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_theme.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../widgets/date_filter_bar.dart';

class GenReportDateFilterNotifier extends Notifier<DateTimeRange?> {
  @override
  DateTimeRange? build() => null;
  void updateFilter(DateTimeRange? range) => state = range;
}
final genReportDateFilterProvider = NotifierProvider<GenReportDateFilterNotifier, DateTimeRange?>(GenReportDateFilterNotifier.new);

final genReportProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final dateFilter = ref.watch(genReportDateFilterProvider);
  String query = '';
  if (dateFilter != null) {
    final start = DateFormat('yyyy-MM-dd').format(dateFilter.start);
    final end = DateFormat('yyyy-MM-dd').format(dateFilter.end);
    query = '?start_date=$start&end_date=$end';
  }
  final res = await ApiService().get('/reports/generator-subscriptions$query');
  final data = res.data;
  if (data is Map<String, dynamic>) return data;
  return {'global': {}, 'buildings': []};
});

class GenReportScreen extends ConsumerWidget {
  const GenReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(genReportProvider);
    final isMobile = MediaQuery.of(context).size.width <= 600;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        color: AppTheme.primary,
        onRefresh: () async => ref.invalidate(genReportProvider),
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
          error: (e, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: AppTheme.danger, size: 48),
                const SizedBox(height: 16),
                Text('Failed to load generator report', style: GoogleFonts.inter(color: Colors.white)),
                const SizedBox(height: 8),
                TextButton.icon(icon: const Icon(Icons.refresh), label: const Text('Retry'), onPressed: () => ref.invalidate(genReportProvider)),
              ],
            ),
          ),
          data: (data) {
            final global = data['global'] as Map<String, dynamic>? ?? {};
            final buildings = (data['buildings'] as List<dynamic>?) ?? [];
            if (buildings.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.assignment_outlined, size: 64, color: AppTheme.textSecondary.withValues(alpha: 0.4)),
                    const SizedBox(height: 16),
                    Text('No generator subscription data', style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 16)),
                  ],
                ),
              );
            }
            return ListView(
              padding: EdgeInsets.all(isMobile ? 16 : 24),
              children: [
                Consumer(
                  builder: (context, ref, child) {
                    return DateFilterBar(
                      dateRange: ref.watch(genReportDateFilterProvider),
                      onChanged: (range) => ref.read(genReportDateFilterProvider.notifier).updateFilter(range),
                    );
                  },
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.surfaceHover),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _GlobalStat(label: 'Total Income', value: global['total_income'], color: AppTheme.info),
                      _GlobalStat(label: 'Total Received', value: global['total_received'], color: AppTheme.success),
                      _GlobalStat(label: 'Total Remaining', value: global['total_remaining'], color: AppTheme.danger),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ...buildings.map((b) {
                  final bMap = b as Map<String, dynamic>;
                  final apts = (bMap['apartments'] as List<dynamic>?) ?? [];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 8, bottom: 8, top: 16),
                        child: Text(
                          bMap['name']?.toString() ?? 'Unknown Building',
                          style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                      ),
                      ...apts.map((a) {
                        final aMap = a as Map<String, dynamic>;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.surfaceHover),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(color: AppTheme.warning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                                    child: const Icon(Icons.electric_bolt_rounded, color: AppTheme.warning, size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          aMap['tenant_name']?.toString() ?? 'N/A',
                                          style: GoogleFonts.outfit(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                                        ),
                                        Text(
                                          'Apt ${aMap['name'] ?? ''}',
                                          style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  _InfoChip(label: 'Income', value: 'CFA ${aMap['total_income'] ?? 0}', icon: Icons.payments_outlined),
                                  const SizedBox(width: 16),
                                  _InfoChip(label: 'Received', value: 'CFA ${aMap['total_received'] ?? 0}', icon: Icons.check_circle_outline),
                                  const SizedBox(width: 16),
                                  _InfoChip(label: 'Remaining', value: 'CFA ${aMap['total_remaining'] ?? 0}', icon: Icons.warning_amber_rounded),
                                ],
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  );
                }),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _InfoChip({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: AppTheme.textSecondary),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 10)),
            Text(value, style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }
}
class _GlobalStat extends StatelessWidget {
  final String label;
  final dynamic value;
  final Color color;

  const _GlobalStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 11)),
        const SizedBox(height: 4),
        Text('CFA $value', style: GoogleFonts.outfit(color: color, fontSize: 14, fontWeight: FontWeight.w700)),
      ],
    );
  }
}
