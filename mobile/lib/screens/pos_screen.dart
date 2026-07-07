// ─── POS Screen ───────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_theme.dart';
import '../services/api_service.dart';

final posInvoicesProvider = FutureProvider<List<dynamic>>((ref) async {
  final res = await ApiService().get('/pos/invoices');
  return res.data as List<dynamic>;
});

class POSScreen extends ConsumerWidget {
  const POSScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(posInvoicesProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(posInvoicesProvider),
      child: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (invoices) => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: invoices.length,
          itemBuilder: (ctx, i) {
            final inv = invoices[i] as Map<String, dynamic>;
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppTheme.primaryLight,
                  child: Icon(Icons.point_of_sale, color: AppTheme.primary),
                ),
                title: Text(inv['invoice_number'] ?? '',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('${inv['date'] ?? ''} • ${inv['customer_name'] ?? 'Walk-In'}'),
                trailing: Text(
                  '\$${inv['final_amount'] ?? 0}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: AppTheme.primary),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
