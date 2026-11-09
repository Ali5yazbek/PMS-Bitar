// ─── Tenant Payments Screen ───────────────────────────────────────────────────

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../config/app_theme.dart';
import '../services/api_service.dart';

final tenantRentHistoryProvider = FutureProvider<List<dynamic>>((ref) async {
  final res = await ApiService().get('/tenant-portal/rent-history');
  final data = res.data;
  if (data is List) return data;
  if (data is Map<String, dynamic>) {
    return (data['invoices'] ?? data['data'] ?? data['history'] ?? []) as List<dynamic>;
  }
  return [];
});

final tenantDashboardProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final res = await ApiService().get('/tenant-portal/dashboard');
  return (res.data as Map<String, dynamic>?) ?? {};
});

final tenantElectricityInvoicesProvider = FutureProvider<List<dynamic>>((ref) async {
  final dashAsync = await ref.watch(tenantDashboardProvider.future);
  final rentAsync = await ref.watch(tenantRentHistoryProvider.future);

  final Set<int> apartmentIds = {};

  final contracts = (dashAsync['contracts'] as List<dynamic>?) ?? [];
  for (final c in contracts) {
    if (c is Map<String, dynamic> && c['apartment_id'] != null) {
      final id = int.tryParse(c['apartment_id'].toString());
      if (id != null) apartmentIds.add(id);
    }
  }

  for (final r in rentAsync) {
    if (r is Map<String, dynamic> && r['apartment_id'] != null) {
      final id = int.tryParse(r['apartment_id'].toString());
      if (id != null) apartmentIds.add(id);
    }
  }

  if (apartmentIds.isEmpty) return [];

  final List<dynamic> allElectricityInvoices = [];
  await Future.wait(apartmentIds.map((aptId) async {
    try {
      final res = await ApiService().get('/electricity/apartments/$aptId/invoices');
      if (res.data is List) {
        for (final item in res.data as List) {
          if (item is Map<String, dynamic>) {
            final contractMatch = contracts.firstWhere(
              (c) => c['apartment_id']?.toString() == aptId.toString(),
              orElse: () => null,
            );
            item['building_name'] = contractMatch?['building_name'] ?? 'Building';
            item['apartment_code'] = contractMatch?['apartment_code'] ?? 'Apt';
            item['is_electricity'] = true;
            allElectricityInvoices.add(item);
          }
        }
      }
    } catch (_) {}
  }));

  allElectricityInvoices.sort((a, b) {
    final dA = a['due_date']?.toString() ?? '';
    final dB = b['due_date']?.toString() ?? '';
    return dB.compareTo(dA);
  });

  return allElectricityInvoices;
});

class TenantPaymentsScreen extends ConsumerStatefulWidget {
  const TenantPaymentsScreen({super.key});

  @override
  ConsumerState<TenantPaymentsScreen> createState() => _TenantPaymentsScreenState();
}

class _TenantPaymentsScreenState extends ConsumerState<TenantPaymentsScreen> with WidgetsBindingObserver {
  Timer? _pollTimer;
  String _activeTab = 'rent'; // 'rent' or 'electricity'
  Map<String, dynamic>? _selectedQrInvoice;
  Map<String, dynamic>? _pendingAgentRequest;
  final Set<String> _acknowledgedRequests = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startPolling();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    // Poll every 25 seconds while active (replaces aggressive 3s invalidation loop)
    _pollTimer = Timer.periodic(const Duration(seconds: 25), (_) {
      if (mounted) {
        ref.invalidate(tenantRentHistoryProvider);
        ref.invalidate(tenantElectricityInvoicesProvider);
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startPolling();
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      _pollTimer?.cancel();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollTimer?.cancel();
    super.dispose();
  }

  double _parse(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  void _checkAgentRequests(List<dynamic> rentInvoices, List<dynamic> elecInvoices) {
    if (_pendingAgentRequest != null || _selectedQrInvoice != null) return;

    final allInvoices = [...rentInvoices, ...elecInvoices];
    final now = DateTime.now();

    for (final inv in allInvoices) {
      if (inv is! Map<String, dynamic>) continue;

      final qrRequestedAt = inv['qr_requested_at']?.toString();
      final isElec = inv['is_electricity'] == true;
      final rawId = inv['id']?.toString() ?? inv['invoice_number']?.toString();
      if (qrRequestedAt == null || qrRequestedAt.isEmpty || rawId == null) continue;

      final idKey = isElec ? 'elec_$rawId' : 'rent_$rawId';
      if (_acknowledgedRequests.contains(idKey)) continue;

      try {
        final reqTime = DateTime.parse(qrRequestedAt);
        final diffMinutes = now.difference(reqTime).inMinutes;
        if (diffMinutes.abs() <= 2) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _pendingAgentRequest == null && _selectedQrInvoice == null) {
              setState(() {
                _pendingAgentRequest = inv;
              });
            }
          });
          break;
        }
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final rentAsync = ref.watch(tenantRentHistoryProvider);
    final elecAsync = ref.watch(tenantElectricityInvoicesProvider);

    final rentInvoices = rentAsync.value ?? [];
    final elecInvoices = elecAsync.value ?? [];

    _checkAgentRequests(rentInvoices, elecInvoices);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          RefreshIndicator(
            color: AppTheme.primary,
            onRefresh: () async {
              ref.invalidate(tenantRentHistoryProvider);
              ref.invalidate(tenantElectricityInvoicesProvider);
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // Top Tab Switcher Bar
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Tab Selector
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D1620),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () => setState(() => _activeTab = 'rent'),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    decoration: BoxDecoration(
                                      color: _activeTab == 'rent' ? AppTheme.primary : Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: _activeTab == 'rent'
                                          ? [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))]
                                          : null,
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      'Rent Payments',
                                      style: TextStyle(
                                        color: _activeTab == 'rent' ? Colors.white : AppTheme.textSecondary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: InkWell(
                                  onTap: () => setState(() => _activeTab = 'electricity'),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    decoration: BoxDecoration(
                                      color: _activeTab == 'electricity' ? AppTheme.primary : Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: _activeTab == 'electricity'
                                          ? [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))]
                                          : null,
                                    ),
                                    alignment: Alignment.center,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.bolt, size: 16, color: _activeTab == 'electricity' ? Colors.amber : AppTheme.textSecondary),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Electricity Subscriptions',
                                          style: TextStyle(
                                            color: _activeTab == 'electricity' ? Colors.white : AppTheme.textSecondary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Render active tab summary cards & list header
                        if (_activeTab == 'rent')
                          _buildSummaryAndListHeader(rentInvoices, isElectricity: false)
                        else
                          _buildSummaryAndListHeader(elecInvoices, isElectricity: true),
                      ],
                    ),
                  ),
                ),

                // Invoice Items List
                if (_activeTab == 'rent')
                  _buildInvoiceSliverList(rentAsync, isElectricity: false)
                else
                  _buildInvoiceSliverList(elecAsync, isElectricity: true),
              ],
            ),
          ),

          // QR Code Modal Overlay
          if (_selectedQrInvoice != null)
            _buildQrModal(_selectedQrInvoice!),

          // Agent Push Request Authorization Modal Overlay
          if (_pendingAgentRequest != null)
            _buildAgentAuthModal(_pendingAgentRequest!),
        ],
      ),
    );
  }

  Widget _buildSummaryAndListHeader(List<dynamic> invoices, {required bool isElectricity}) {
    double totalPaid = 0.0;
    double totalOutstanding = 0.0;

    for (final inv in invoices) {
      if (inv is Map<String, dynamic>) {
        final amount = _parse(inv['amount']);
        final paidAmount = _parse(inv['paid_amount'] ?? (inv['status'] == 'Paid' ? amount : 0));
        final status = inv['status']?.toString() ?? 'Unpaid';
        
        final debt = isElectricity
            ? (status.toLowerCase() != 'paid' ? (amount - paidAmount) : 0.0)
            : _parse(inv['outstanding_debt']);

        totalPaid += paidAmount;
        totalOutstanding += debt;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                label: 'Total Paid',
                value: 'CFA ${NumberFormat('#,##0').format(totalPaid)}',
                color: AppTheme.success,
                icon: Icons.check_circle_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryCard(
                label: 'Outstanding',
                value: 'CFA ${NumberFormat('#,##0').format(totalOutstanding)}',
                color: totalOutstanding > 0 ? AppTheme.danger : AppTheme.success,
                icon: totalOutstanding > 0 ? Icons.warning_rounded : Icons.check_circle_rounded,
              ),
            ),
          ],
        ),

        if (totalOutstanding > 0) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.danger.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.danger.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppTheme.danger, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isElectricity
                        ? 'You have an unpaid electricity subscription balance. Generate your Payment QR code for field agent scanning.'
                        : 'You have an outstanding rent balance. Present your Payment QR code to the field agent for quick collection.',
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 20),
        Text(
          isElectricity ? 'ELECTRICITY INVOICES & READINGS' : 'RENT PAYMENT HISTORY',
          style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildInvoiceSliverList(AsyncValue<List<dynamic>> async, {required bool isElectricity}) {
    return async.when(
      loading: () => const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      ),
      error: (e, _) => SliverFillRemaining(
        child: Center(
          child: Text('Failed to load invoices: $e', style: GoogleFonts.inter(color: Colors.white)),
        ),
      ),
      data: (invoices) {
        if (invoices.isEmpty) {
          return SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isElectricity ? Icons.bolt_outlined : Icons.receipt_long_outlined,
                    size: 64,
                    color: AppTheme.textSecondary.withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isElectricity ? 'No electricity invoices found.' : 'No rent payment records found.',
                    style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 16),
                  ),
                ],
              ),
            ),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (ctx, i) {
              final inv = invoices[i] as Map<String, dynamic>;
              final rawId = inv['id'];
              final invNum = inv['invoice_number']?.toString() ?? (isElectricity ? 'Elec-$rawId' : 'INV-$rawId');
              final status = inv['status']?.toString() ?? 'Unpaid';
              final statusLower = status.toLowerCase();
              final isPaid = statusLower == 'paid';
              final isPartial = statusLower == 'partial' || statusLower == 'partially paid';

              final amount = _parse(inv['amount']);
              final paidAmount = _parse(inv['paid_amount'] ?? (isPaid ? amount : 0));
              final debt = isElectricity
                  ? (!isPaid ? (amount - paidAmount) : 0.0)
                  : _parse(inv['outstanding_debt']);

              final dueDate = inv['due_date']?.toString() ?? '';
              final building = inv['building_name']?.toString() ?? 'N/A';
              final aptCode = inv['apartment_code']?.toString() ?? 'N/A';
              final elecType = inv['type']?.toString() ?? 'Subscription';

              String formattedDate = dueDate;
              try { formattedDate = DateFormat('d MMM yyyy').format(DateTime.parse(dueDate)); } catch (_) {}

              return Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isPaid
                        ? AppTheme.success.withValues(alpha: 0.2)
                        : (isPartial ? AppTheme.warning.withValues(alpha: 0.3) : AppTheme.danger.withValues(alpha: 0.3)),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: (isPaid ? AppTheme.success : (isPartial ? AppTheme.warning : AppTheme.danger)).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            isPaid ? Icons.check_circle_rounded : (isElectricity ? Icons.bolt : Icons.pending_outlined),
                            color: isPaid ? AppTheme.success : (isPartial ? AppTheme.warning : AppTheme.danger),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(invNum, style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                  if (isElectricity) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
                                      child: Text(elecType, style: const TextStyle(color: Colors.amber, fontSize: 9, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ],
                              ),
                              Text('$building • Apt $aptCode', style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 12)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: (isPaid ? AppTheme.success : (isPartial ? AppTheme.warning : AppTheme.danger)).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            status.toUpperCase(),
                            style: TextStyle(
                              color: isPaid ? AppTheme.success : (isPartial ? AppTheme.warning : AppTheme.danger),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Show Meter Readings if type is Meter
                    if (isElectricity && elecType == 'Meter' && inv['previous_reading'] != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D1620),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${inv['previous_reading']} → ${inv['current_reading']} kWh  (${inv['consumption'] ?? 0} kWh used)',
                          style: GoogleFonts.inter(color: Colors.amber.shade200, fontSize: 11, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],

                    const SizedBox(height: 12),
                    Divider(color: Colors.white.withValues(alpha: 0.05), height: 1),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Due Date', style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 10)),
                            Text(formattedDate, style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text('Amount (Paid)', style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 10)),
                            Text('CFA ${NumberFormat('#,##0').format(amount)} (${NumberFormat('#,##0').format(paidAmount)})', style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('Balance Owed', style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 10)),
                            Text('CFA ${NumberFormat('#,##0').format(debt)}', style: GoogleFonts.outfit(color: debt > 0 ? AppTheme.danger : AppTheme.success, fontSize: 13, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),

                    if (!isPaid) ...[
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          icon: const Icon(Icons.qr_code_2_rounded, size: 18, color: Colors.white),
                          label: const Text('Generate Payment QR', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                          onPressed: () {
                            setState(() {
                              _selectedQrInvoice = inv;
                            });
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
            childCount: invoices.length,
          ),
        );
      },
    );
  }

  Widget _buildQrModal(Map<String, dynamic> inv) {
    final isElectricity = inv['is_electricity'] == true;
    final rawId = inv['id'];
    final invNum = inv['invoice_number']?.toString() ?? (isElectricity ? 'Elec-$rawId' : 'INV-$rawId');
    final status = inv['status']?.toString() ?? 'Unpaid';
    final isPaid = status.toLowerCase() == 'paid';
    final amount = _parse(inv['amount']);
    final paidAmount = _parse(inv['paid_amount'] ?? (isPaid ? amount : 0));
    final debt = isElectricity
        ? (!isPaid ? (amount - paidAmount) : 0.0)
        : _parse(inv['outstanding_debt']);

    final qrPayload = jsonEncode({
      'tenantId': inv['tenant_id'],
      'buildingId': inv['building_id'] ?? inv['building_name'],
      'apartmentId': inv['apartment_id'],
      'paymentType': isElectricity ? 'Electricity Subscription' : 'Rent Apartment',
      'status': status,
      'invoiceId': rawId,
      'invoiceNumber': invNum,
      'amountOwed': debt,
    });

    return Container(
      color: Colors.black.withValues(alpha: 0.8),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      child: Material(
        color: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 380),
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFF060B10),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.primary.withValues(alpha: 0.4)),
            boxShadow: [
              BoxShadow(color: AppTheme.primary.withValues(alpha: 0.2), blurRadius: 30, offset: const Offset(0, 10)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: const BoxDecoration(
                  color: Color(0xFF0D1620),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(isPaid ? Icons.check_circle_rounded : (isElectricity ? Icons.bolt : Icons.qr_code_2_rounded), color: isPaid ? AppTheme.success : AppTheme.primary, size: 22),
                        const SizedBox(width: 8),
                        Text(isPaid ? 'Payment Successful' : (isElectricity ? 'Electricity QR Receipt' : 'Rent Payment QR'), style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.blueGrey),
                      onPressed: () => setState(() => _selectedQrInvoice = null),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    if (isPaid) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: AppTheme.success.withValues(alpha: 0.15), shape: BoxShape.circle),
                        child: const Icon(Icons.check_rounded, color: AppTheme.success, size: 48),
                      ),
                      const SizedBox(height: 16),
                      Text('Thank You!', style: GoogleFonts.outfit(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('Your payment for Invoice #$invNum was successfully processed.', style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 13), textAlign: TextAlign.center),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.surfaceHover, padding: const EdgeInsets.symmetric(vertical: 12)),
                          onPressed: () => setState(() => _selectedQrInvoice = null),
                          child: const Text('Close Receipt', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ] else ...[
                      // Render QR Code
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3), width: 3),
                        ),
                        child: QrImageView(
                          data: qrPayload,
                          version: QrVersions.auto,
                          size: 190.0,
                          backgroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text('Invoice #$invNum', style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('Present this QR code to the field agent for scanning.', style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 12), textAlign: TextAlign.center),
                      const SizedBox(height: 4),
                      Text('Verification Code: $invNum', style: GoogleFonts.inter(color: AppTheme.primary, fontSize: 13, fontWeight: FontWeight.bold)),

                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(color: const Color(0xFF0D1620), borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Remaining Due', style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 13)),
                            Text('CFA ${NumberFormat('#,##0').format(debt)}', style: GoogleFonts.outfit(color: AppTheme.danger, fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAgentAuthModal(Map<String, dynamic> inv) {
    final isElectricity = inv['is_electricity'] == true;
    final rawId = inv['id']?.toString() ?? '1';
    final invNum = inv['invoice_number']?.toString() ?? (isElectricity ? 'Elec-$rawId' : 'INV-$rawId');
    final idKey = isElectricity ? 'elec_$rawId' : 'rent_$rawId';

    return Container(
      color: Colors.black.withValues(alpha: 0.85),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      child: Material(
        color: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFF060B10),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.primary.withValues(alpha: 0.6)),
            boxShadow: [
              BoxShadow(color: AppTheme.primary.withValues(alpha: 0.3), blurRadius: 30, offset: const Offset(0, 10)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.15),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.qr_code_scanner_rounded, color: AppTheme.primary, size: 24),
                    const SizedBox(width: 10),
                    Expanded(child: Text('Authorization Required', style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.blueGrey),
                      onPressed: () {
                        setState(() {
                          _acknowledgedRequests.add(idKey);
                          _pendingAgentRequest = null;
                        });
                      },
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.2), shape: BoxShape.circle),
                      child: const Icon(Icons.warning_amber_rounded, color: AppTheme.primary, size: 40),
                    ),
                    const SizedBox(height: 16),
                    Text('Payment Collection Request', style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(
                      'An agent is requesting to collect payment for ${isElectricity ? "Electricity " : ""}Invoice #$invNum.',
                      style: GoogleFonts.inter(color: Colors.white70, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Do you want to accept this request and display your QR code for scanning?',
                      style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppTheme.textSecondary),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () {
                              setState(() {
                                _acknowledgedRequests.add(idKey);
                                _pendingAgentRequest = null;
                              });
                            },
                            child: const Text('Decline', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, padding: const EdgeInsets.symmetric(vertical: 12)),
                            onPressed: () {
                              final currentInv = _pendingAgentRequest;
                              setState(() {
                                _acknowledgedRequests.add(idKey);
                                _pendingAgentRequest = null;
                                _selectedQrInvoice = currentInv;
                              });
                            },
                            child: const Text('Accept & Show QR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  const _SummaryCard({required this.label, required this.value, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(value, style: GoogleFonts.outfit(color: color, fontSize: 15, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(label, style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }
}
