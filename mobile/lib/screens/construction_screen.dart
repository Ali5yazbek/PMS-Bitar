// ─── Construction Screen ──────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_theme.dart';
import '../services/api_service.dart';

final constructionsProvider = FutureProvider<List<dynamic>>((ref) async {
  final res = await ApiService().get('/constructions');
  return res.data as List<dynamic>;
});

class ConstructionScreen extends ConsumerWidget {
  const ConstructionScreen({super.key});

  Color _statusColor(String? s) {
    switch (s) {
      case 'Completed': return AppTheme.success;
      case 'In Progress': return AppTheme.primary;
      case 'On Hold': return AppTheme.warning;
      case 'Cancelled': return AppTheme.danger;
      default: return AppTheme.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(constructionsProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(constructionsProvider),
      child: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (projects) => projects.isEmpty
            ? const Center(child: Text('No construction projects'))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: projects.length,
                itemBuilder: (ctx, i) {
                  final p = projects[i] as Map<String, dynamic>;
                  final status = p['status'] as String?;
                  final progress = (double.tryParse('${p['progress'] ?? 0}') ?? 0) / 100;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(p['name'] ?? 'Project ${p['id']}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16)),
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
                                      fontSize: 11),
                                ),
                              ),
                            ],
                          ),
                          if (p['description'] != null) ...[
                            const SizedBox(height: 6),
                            Text(p['description'],
                                style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 13),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis),
                          ],
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Progress',
                                  style: const TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 12)),
                              Text('${(progress * 100).toInt()}%',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          LinearProgressIndicator(
                            value: progress,
                            color: _statusColor(status),
                            backgroundColor: _statusColor(status).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                            minHeight: 6,
                          ),
                          if (p['budget'] != null) ...[
                            const SizedBox(height: 10),
                            Text('Budget: \$${p['budget']}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textPrimary)),
                          ],
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
