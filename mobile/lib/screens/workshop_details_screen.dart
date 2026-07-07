// ─── Workshop Details Screen ──────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../config/app_theme.dart';
import '../services/api_service.dart';

final workshopDetailsProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, id) async {
  final res = await ApiService().get('/workshop/$id');
  return res.data as Map<String, dynamic>;
});

class WorkshopDetailsScreen extends ConsumerWidget {
  final String id;
  const WorkshopDetailsScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(workshopDetailsProvider(id));

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: AppTheme.danger, size: 48),
              const SizedBox(height: 16),
              Text('Failed to load order details', style: GoogleFonts.inter(color: Colors.white)),
              TextButton(
                onPressed: () => ref.invalidate(workshopDetailsProvider(id)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (data) {
          final project = data['project'] ?? {};
          final estimates = data['estimates'] as List<dynamic>? ?? [];
          
          double totalCost = 0;
          for (var e in estimates) {
            totalCost += double.tryParse(e['total_price']?.toString() ?? '0') ?? 0;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                      onPressed: () => context.pop(),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.build_rounded, color: AppTheme.primary, size: 32),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            project['title'] ?? project['description'] ?? 'Order Details',
                            style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w700, color: Colors.white),
                          ),
                          Text(
                            'Status: ${project['status'] ?? 'Pending'} | Total Est: CFA ${NumberFormat('#,##0.00').format(totalCost)}',
                            style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                
                Text('Material & Labor Estimates', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.white)),
                const SizedBox(height: 16),
                
                if (estimates.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Text('No estimates found.', style: GoogleFonts.inter(color: AppTheme.textSecondary)),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: estimates.length,
                    itemBuilder: (ctx, i) {
                      final est = estimates[i] as Map<String, dynamic>;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.surfaceHover),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppTheme.warning.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.inventory_2_rounded, color: AppTheme.warning, size: 20),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(est['product_name'] ?? 'Item', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white)),
                                  Text('${est['category']} • Qty: ${est['quantity']}', style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 12)),
                                ],
                              ),
                            ),
                            Text('CFA ${NumberFormat('#,##0.00').format(double.tryParse(est['total_price']?.toString() ?? '0') ?? 0)}', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 16)),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
