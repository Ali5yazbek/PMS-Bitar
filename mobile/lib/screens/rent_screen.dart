// ─── Rent Screen ──────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../config/app_theme.dart';
import '../services/api_service.dart';

final rentInvoicesProvider = FutureProvider<List<dynamic>>((ref) async {
  final res = await ApiService().get('/rent/invoices');
  return res.data as List<dynamic>;
});

class RentScreen extends ConsumerStatefulWidget {
  final String? buildingId;
  final String? tenantId;
  const RentScreen({super.key, this.buildingId, this.tenantId});
  @override
  ConsumerState<RentScreen> createState() => _RentScreenState();
}

class _RentScreenState extends ConsumerState<RentScreen> {
  String _filterStatus = 'All';

  static const _statuses = ['All', 'Unpaid', 'Partial', 'Paid', 'Overdue'];

  Color _statusColor(String status) {
    switch (status) {
      case 'Paid': return AppTheme.success;
      case 'Partial': return AppTheme.warning;
      case 'Overdue': return AppTheme.danger;
      default: return AppTheme.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(rentInvoicesProvider);

    final isIsolated = widget.buildingId != null || widget.tenantId != null;

    final bodyContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
          // Filter chips
          Container(
            height: 70,
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              children: _statuses.map((s) {
                final selected = _filterStatus == s;
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: ChoiceChip(
                    label: Text(s, style: GoogleFonts.inter(
                      color: selected ? Colors.white : AppTheme.textSecondary,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    )),
                    selected: selected,
                    onSelected: (_) => setState(() => _filterStatus = s),
                    backgroundColor: AppTheme.surface,
                    selectedColor: AppTheme.primary,
                    side: BorderSide(
                      color: selected ? AppTheme.primary : AppTheme.surfaceHover,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              }).toList(),
            ),
          ),

          Expanded(
            child: RefreshIndicator(
              color: AppTheme.primary,
              onRefresh: () async => ref.invalidate(rentInvoicesProvider),
              child: async.when(
                loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
                error: (e, _) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: AppTheme.danger, size: 48),
                      const SizedBox(height: 16),
                      Text('Failed to load invoices', style: GoogleFonts.inter(color: Colors.white)),
                    ],
                  ),
                ),
                data: (invoices) {
                  final filtered = invoices.where((inv) {
                    final m = inv as Map<String, dynamic>;
                    return _filterStatus == 'All' || m['status'] == _filterStatus;
                  }).toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.receipt_long_rounded, size: 64, color: AppTheme.textSecondary.withOpacity(0.5)),
                          const SizedBox(height: 16),
                          Text('No invoices found', style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 16)),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) {
                      final inv = filtered[i] as Map<String, dynamic>;
                      return _InvoiceCard(
                        invoice: inv,
                        statusColor: _statusColor(inv['status'] ?? 'Unpaid'),
                      );
                    },
                  );
                },
              ),
            ),
          ),
      ],
    );

    if (isIsolated) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          backgroundColor: AppTheme.surface,
          title: Text(widget.buildingId != null ? 'Building Rent' : 'Tenant Rent', style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: Colors.white)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {}, // Future: Generate Invoice
          backgroundColor: AppTheme.primary,
          icon: const Icon(Icons.receipt_rounded, color: Colors.white),
          label: Text('New Invoice', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
        ),
        body: bodyContent,
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {}, // Future: Generate Invoice
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.receipt_rounded, color: Colors.white),
        label: Text('New Invoice', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: bodyContent,
    );
  }
}

class _InvoiceCard extends StatefulWidget {
  final Map<String, dynamic> invoice;
  final Color statusColor;

  const _InvoiceCard({required this.invoice, required this.statusColor});

  @override
  State<_InvoiceCard> createState() => _InvoiceCardState();
}

class _InvoiceCardState extends State<_InvoiceCard> {
  bool isHovered = false;

  String _formatNum(dynamic value) {
    if (value == null) return '0.00';
    try {
      final double val = value is String ? double.parse(value) : value.toDouble();
      return NumberFormat('#,##0.00').format(val);
    } catch (e) {
      return '0.00';
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.invoice['status'] ?? 'Unpaid';
    
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
            color: isHovered ? widget.statusColor.withOpacity(0.5) : AppTheme.surfaceHover,
            width: 1,
          ),
          boxShadow: isHovered
              ? [BoxShadow(color: widget.statusColor.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))]
              : [],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {}, // Future: View invoice details
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: widget.statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.receipt_long_rounded, color: widget.statusColor, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.invoice['invoice_number'] ?? '#INV-0000',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.person_outline_rounded, size: 14, color: AppTheme.textSecondary),
                            const SizedBox(width: 6),
                            Text(
                              widget.invoice['tenant_name'] ?? 'Unknown Tenant',
                              style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 13),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.event_rounded, size: 14, color: AppTheme.textSecondary),
                            const SizedBox(width: 6),
                            Text(
                              'Due: ${widget.invoice['due_date'] ?? 'N/A'}',
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
                        'CFA ${_formatNum(widget.invoice['amount'])}',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: widget.statusColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: widget.statusColor.withOpacity(0.3)),
                        ),
                        child: Text(
                          status,
                          style: GoogleFonts.inter(
                            color: widget.statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
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
  }
}
