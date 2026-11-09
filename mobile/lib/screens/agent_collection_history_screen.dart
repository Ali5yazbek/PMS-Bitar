import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_theme.dart';
import '../providers/currency_provider.dart';
import '../services/agent_api.dart';
import '../widgets/mobile/enterprise_mobile_scaffold.dart';

final rentHistoryProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return AgentApi.instance.getRentHistory();
});

class AgentCollectionHistoryScreen extends ConsumerStatefulWidget {
  const AgentCollectionHistoryScreen({super.key});

  @override
  ConsumerState<AgentCollectionHistoryScreen> createState() => _AgentCollectionHistoryScreenState();
}

class _AgentCollectionHistoryScreenState extends ConsumerState<AgentCollectionHistoryScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(rentHistoryProvider);
    final formatAmount = ref.watch(formatAmountProvider);

    return EnterpriseMobileScaffold(
      title: 'Collection History',
      userRole: 'Agent',
      userName: 'Field Agent',
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(rentHistoryProvider);
        },
        color: AppTheme.primary,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search tenant or building...',
                  hintStyle: const TextStyle(color: Colors.blueGrey),
                  prefixIcon: const Icon(Icons.search, color: Colors.blueGrey),
                  filled: true,
                  fillColor: AppTheme.surface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
              ),
            ),
            
            Expanded(
              child: historyAsync.when(
                loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
                error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
                data: (response) {
                  final rawData = response['data'] as List<dynamic>? ?? [];
                  final data = rawData.cast<Map<String, dynamic>>().where((item) {
                    final building = (item['building_name'] ?? '').toLowerCase();
                    final tenant = (item['tenant_name'] ?? '').toLowerCase();
                    return building.contains(_searchQuery) || tenant.contains(_searchQuery);
                  }).toList();

                  if (data.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history, size: 64, color: Colors.blueGrey.withOpacity(0.5)),
                          const SizedBox(height: 16),
                          Text('No history found', style: GoogleFonts.outfit(color: Colors.white, fontSize: 20)),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: data.length,
                    itemBuilder: (context, index) {
                      final item = data[index];
                      final isFull = item['remaining'] == 0 || item['remaining'] == "0" || item['remaining'] == "0.00";
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF0D1620)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('${item['building_name']} - Apt ${item['apartment_number']}', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                Text(item['date']?.substring(0, 10) ?? '', style: const TextStyle(color: Colors.blueGrey, fontSize: 12)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(item['tenant_name'] ?? 'Unknown', style: const TextStyle(color: Colors.white70, fontSize: 14)),
                            const Divider(color: Color(0xFF0D1620), height: 24),
                            
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Collected', style: TextStyle(color: Colors.blueGrey, fontSize: 10)),
                                    Text(formatAmount(item['amount']), style: GoogleFonts.inter(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                                    Text('via ${item['payment_method']}', style: const TextStyle(color: Colors.blueGrey, fontSize: 10)),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text('Status', style: TextStyle(color: Colors.blueGrey, fontSize: 10)),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isFull ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        isFull ? 'Paid in Full' : 'Partial Payment',
                                        style: TextStyle(color: isFull ? Colors.greenAccent : Colors.orangeAccent, fontSize: 12, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    if (!isFull) 
                                      Text('Rem: ${formatAmount(item['remaining'])}', style: const TextStyle(color: Colors.orangeAccent, fontSize: 10)),
                                  ],
                                ),
                              ],
                            )
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
