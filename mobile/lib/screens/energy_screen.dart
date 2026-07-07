// ─── Energy Screen ────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_theme.dart';
import '../services/api_service.dart';

final energyDashboardProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final res = await ApiService().get('/energy/dashboard');
  return res.data as Map<String, dynamic>;
});

final generatorsProvider = FutureProvider<List<dynamic>>((ref) async {
  final res = await ApiService().get('/energy/generators');
  return res.data as List<dynamic>;
});

class EnergyScreen extends ConsumerWidget {
  const EnergyScreen({super.key});

  Color _statusColor(String? s) {
    switch (s) {
      case 'Running': return AppTheme.success;
      case 'Stopped': return AppTheme.danger;
      case 'Maintenance': return AppTheme.warning;
      default: return AppTheme.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final genAsync = ref.watch(generatorsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(generatorsProvider);
        ref.invalidate(energyDashboardProvider);
      },
      child: genAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (generators) => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: generators.length,
          itemBuilder: (ctx, i) {
            final g = generators[i] as Map<String, dynamic>;
            final status = g['status'] as String?;
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _statusColor(status).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.bolt_outlined,
                              color: _statusColor(status), size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(g['name'] ?? 'Generator ${g['id']}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16)),
                              Text(g['model'] ?? '',
                                  style: const TextStyle(
                                      color: AppTheme.textSecondary)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _statusColor(status).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            status ?? 'Unknown',
                            style: TextStyle(
                                color: _statusColor(status),
                                fontWeight: FontWeight.w600,
                                fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _InfoChip(label: 'Capacity',
                            value: '${g['capacity_kva'] ?? 0} KVA'),
                        const SizedBox(width: 12),
                        _InfoChip(label: 'Fuel',
                            value: '${g['current_fuel_liters'] ?? 0} L'),
                      ],
                    ),
                  ],
                ),
              ),
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
  const _InfoChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 10, color: AppTheme.textSecondary)),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }
}
