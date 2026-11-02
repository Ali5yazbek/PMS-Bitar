// ─── Warehouse Screen ─────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_theme.dart';
import '../services/api_service.dart';

final warehouseProvider = FutureProvider<List<dynamic>>((ref) async {
  final res = await ApiService().get('/warehouse');
  return res.data as List<dynamic>;
});

class WarehouseScreen extends ConsumerStatefulWidget {
  const WarehouseScreen({super.key});
  @override
  ConsumerState<WarehouseScreen> createState() => _WarehouseScreenState();
}

class _WarehouseScreenState extends ConsumerState<WarehouseScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(warehouseProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {}, // Future: Add Product
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add_box_rounded, color: Colors.white),
        label: Text('Add Product', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search products by name...',
                prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textSecondary),
                filled: true,
                fillColor: AppTheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: AppTheme.primary.withOpacity(0.5), width: 1),
                ),
              ),
              style: GoogleFonts.inter(color: Colors.white),
              onChanged: (v) => setState(() => _search = v.toLowerCase()),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              color: AppTheme.primary,
              onRefresh: () async => ref.invalidate(warehouseProvider),
              child: async.when(
                loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
                error: (e, _) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: AppTheme.danger, size: 48),
                      const SizedBox(height: 16),
                      Text('Failed to load products', style: GoogleFonts.inter(color: Colors.white)),
                    ],
                  ),
                ),
                data: (items) {
                  final filtered = items.where((item) {
                    final m = item as Map<String, dynamic>;
                    return _search.isEmpty || (m['name'] ?? '').toString().toLowerCase().contains(_search);
                  }).toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inventory_2_rounded, size: 64, color: AppTheme.textSecondary.withOpacity(0.5)),
                          const SizedBox(height: 16),
                          Text('No products found', style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 16)),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) {
                      final item = filtered[i] as Map<String, dynamic>;
                      return _ProductCard(product: item);
                    },
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

class _ProductCard extends StatefulWidget {
  final Map<String, dynamic> product;
  const _ProductCard({required this.product});

  @override
  State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard> {
  bool isHovered = false;

  void _showProductDetails() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _ProductDetailsSheet(product: widget.product),
    );
  }

  @override
  Widget build(BuildContext context) {
    final qty = int.tryParse('${widget.product['quantity'] ?? 0}') ?? 0;
    final minQty = int.tryParse('${widget.product['minimum_quantity'] ?? 0}') ?? 0;
    final isLow = qty <= minQty && minQty > 0;
    
    final color = isLow ? AppTheme.danger : AppTheme.primary;

    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: isHovered ? AppTheme.surfaceHover : AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isHovered ? color.withOpacity(0.5) : AppTheme.surfaceHover,
            width: 1,
          ),
          boxShadow: isHovered
              ? [BoxShadow(color: color.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))]
              : [],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: _showProductDetails,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.inventory_2_rounded, color: color, size: 28),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.product['name'] ?? '',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.category_rounded, size: 14, color: AppTheme.textSecondary),
                            const SizedBox(width: 6),
                            Text(
                              widget.product['category'] ?? 'Uncategorized',
                              style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 13),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$qty',
                        style: GoogleFonts.outfit(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: isLow ? AppTheme.danger : Colors.white,
                        ),
                      ),
                      Text(
                        widget.product['unit'] ?? 'in stock',
                        style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.chevron_right_rounded, color: isHovered ? Colors.white : AppTheme.textSecondary),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProductDetailsSheet extends StatelessWidget {
  final Map<String, dynamic> product;
  const _ProductDetailsSheet({required this.product});

  @override
  Widget build(BuildContext context) {
    final qty = int.tryParse('${product['quantity'] ?? 0}') ?? 0;
    final minQty = int.tryParse('${product['minimum_quantity'] ?? 0}') ?? 0;
    final isLow = qty <= minQty && minQty > 0;
    final color = isLow ? AppTheme.danger : AppTheme.primary;

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceHover,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(Icons.inventory_2_rounded, color: color, size: 32),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product['name'] ?? '',
                        style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                      Text(
                        product['category'] ?? 'Uncategorized',
                        style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.surfaceHover),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _DetailStat('In Stock', '$qty', color: isLow ? AppTheme.danger : Colors.white),
                  Container(width: 1, height: 40, color: AppTheme.surfaceHover),
                  _DetailStat('Minimum Qty', '$minQty', color: AppTheme.textSecondary),
                  Container(width: 1, height: 40, color: AppTheme.surfaceHover),
                  _DetailStat('Unit', product['unit'] ?? 'pcs', color: AppTheme.textSecondary),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context); // Close the detail sheet first
                  String name = product['name'] ?? '';
                  String unit = product['unit'] ?? 'pcs';
                  String minQty = (product['minimum_quantity'] ?? 0).toString();
                  
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => StatefulBuilder(
                      builder: (context, setState) => Container(
                        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                        decoration: const BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                        ),
                        child: SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Edit Product', style: GoogleFonts.outfit(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 24),
                                TextField(
                                  decoration: const InputDecoration(labelText: 'Name', labelStyle: TextStyle(color: AppTheme.textSecondary)),
                                  style: const TextStyle(color: Colors.white),
                                  onChanged: (v) => name = v,
                                  controller: TextEditingController(text: name)..selection = TextSelection.collapsed(offset: name.length),
                                ),
                                const SizedBox(height: 16),
                                TextField(
                                  decoration: const InputDecoration(labelText: 'Unit (e.g. pcs, liters)', labelStyle: TextStyle(color: AppTheme.textSecondary)),
                                  style: const TextStyle(color: Colors.white),
                                  onChanged: (v) => unit = v,
                                  controller: TextEditingController(text: unit)..selection = TextSelection.collapsed(offset: unit.length),
                                ),
                                const SizedBox(height: 16),
                                TextField(
                                  decoration: const InputDecoration(labelText: 'Minimum Quantity', labelStyle: TextStyle(color: AppTheme.textSecondary)),
                                  style: const TextStyle(color: Colors.white),
                                  keyboardType: TextInputType.number,
                                  onChanged: (v) => minQty = v,
                                  controller: TextEditingController(text: minQty)..selection = TextSelection.collapsed(offset: minQty.length),
                                ),
                                const SizedBox(height: 24),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary))),
                                    const SizedBox(width: 8),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                                      onPressed: () async {
                                        Navigator.pop(context);
                                        try {
                                          await ApiService().client.put('/warehouse/products/${product['id']}', data: {
                                            'name': name,
                                            'unit': unit,
                                            'minimum_quantity': minQty,
                                          });
                                          // Note: since this is a stateless widget method, we don't have a ref. We can't invalidate the provider easily from here without passing it.
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product updated. Please refresh.')));
                                          }
                                        } catch (e) {
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update: $e')));
                                          }
                                        }
                                      },
                                      child: const Text('Save', style: TextStyle(color: Colors.white)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.edit_rounded),
                label: const Text('Edit Product'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.surfaceHover,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _DetailStat(this.label, this.value, {required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 12)),
        const SizedBox(height: 8),
        Text(value, style: GoogleFonts.outfit(color: color, fontSize: 24, fontWeight: FontWeight.w700)),
      ],
    );
  }
}
