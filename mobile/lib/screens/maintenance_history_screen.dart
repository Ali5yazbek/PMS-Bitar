// ─── Maintenance Worker History Screen ──────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../config/app_theme.dart';
import '../services/api_service.dart';

final maintenanceWorkerHistoryProvider = FutureProvider<List<dynamic>>((ref) async {
  final res = await ApiService().get('/maintenance/worker-history');
  final data = res.data;
  if (data is List) return data;
  if (data is Map && data.containsKey('tasks')) return data['tasks'] as List<dynamic>;
  return [];
});

class MaintenanceHistoryScreen extends ConsumerWidget {
  const MaintenanceHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(maintenanceWorkerHistoryProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            alignment: Alignment.centerLeft,
            child: Text(
              'My Work History',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              color: AppTheme.primary,
              onRefresh: () async => ref.invalidate(maintenanceWorkerHistoryProvider),
              child: async.when(
                loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
                error: (e, _) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: AppTheme.danger, size: 48),
                      const SizedBox(height: 16),
                      Text('Failed to load history', style: GoogleFonts.inter(color: Colors.white)),
                      TextButton.icon(
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                        onPressed: () => ref.invalidate(maintenanceWorkerHistoryProvider),
                      ),
                    ],
                  ),
                ),
                data: (tasks) {
                  if (tasks.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history, size: 64, color: AppTheme.textSecondary.withValues(alpha: 0.4)),
                          const SizedBox(height: 16),
                          Text('No completed maintenance tasks', style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 16)),
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: tasks.length,
                    itemBuilder: (ctx, i) => _HistoryCard(task: tasks[i] as Map<String, dynamic>),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final Map<String, dynamic> task;
  const _HistoryCard({required this.task});

  Color _statusColor(String status) {
    final s = status.toLowerCase();
    if (s == 'pending' || s == 'pending_approval') return AppTheme.warning;
    if (s == 'completed' || s == 'approved') return AppTheme.success;
    if (s == 'rejected') return AppTheme.danger;
    return AppTheme.textSecondary;
  }

  @override
  Widget build(BuildContext context) {
    final status = task['status']?.toString() ?? 'completed';
    final statusColor = _statusColor(status);
    final date = task['submission_date']?.toString() ?? task['created_at']?.toString() ?? '';
    String formattedDate = '';
    try {
      formattedDate = DateFormat('d MMM yyyy, HH:mm').format(DateTime.parse(date));
    } catch (_) {
      formattedDate = date;
    }

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
                decoration: BoxDecoration(color: AppTheme.info.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.ac_unit_rounded, color: AppTheme.info, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task['task_type']?.toString() ?? task['type']?.toString() ?? 'Maintenance Task',
                      style: GoogleFonts.outfit(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      'Apt ${task['apartment_code'] ?? task['apartment_number'] ?? ''} — ${task['building_name'] ?? ''}',
                      style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 12),
                    ),
                    if (task['worker_name'] != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.person, size: 12, color: AppTheme.textSecondary),
                          const SizedBox(width: 4),
                          Text('Worker: ${task['worker_name']}', style: GoogleFonts.inter(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
                child: Text(
                  status.replaceAll('_', ' ').toUpperCase(),
                  style: GoogleFonts.inter(color: statusColor, fontSize: 10, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          if (task['description'] != null && task['description'].toString().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(task['description'].toString(), style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 12)),
          ],
          if (task['notes'] != null && task['notes'].toString().isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppTheme.background, borderRadius: BorderRadius.circular(8)),
              child: Text('Notes: ${task['notes']}', style: GoogleFonts.inter(color: Colors.white70, fontSize: 12)),
            )
          ],
          if (task['before_photo'] != null || task['after_photo'] != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (task['before_photo'] != null)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Before', style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 10)),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(task['before_photo'], height: 80, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.grey)),
                        ),
                      ],
                    ),
                  ),
                if (task['before_photo'] != null && task['after_photo'] != null) const SizedBox(width: 8),
                if (task['after_photo'] != null)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('After', style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 10)),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(task['after_photo'], height: 80, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.grey)),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
          if (formattedDate.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 12, color: AppTheme.textSecondary),
                const SizedBox(width: 4),
                Text(formattedDate, style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 11)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
