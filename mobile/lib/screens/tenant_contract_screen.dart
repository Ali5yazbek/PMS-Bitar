// ─── Tenant Contract Screen ───────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../config/app_theme.dart';
import '../services/api_service.dart';

final tenantContractProvider = FutureProvider<List<dynamic>>((ref) async {
  final res = await ApiService().get('/tenant-portal/dashboard');
  final data = res.data as Map<String, dynamic>;
  return (data['contracts'] as List<dynamic>?) ?? [];
});

class TenantContractScreen extends ConsumerWidget {
  const TenantContractScreen({super.key});

  String _fmtDate(String? d) {
    if (d == null || d.isEmpty) return 'N/A';
    try { return DateFormat('d MMM yyyy').format(DateTime.parse(d)); } catch (_) { return d; }
  }

  Color _statusColor(String status) {
    final s = status.toLowerCase();
    if (s == 'active' || s == 'approved') return AppTheme.success;
    if (s == 'pending_signature' || s == 'signed' || s == 'renewal_pending') return AppTheme.warning;
    if (s == 'expired' || s == 'terminated' || s == 'rejected') return AppTheme.danger;
    return AppTheme.textSecondary;
  }

  double _parse(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(tenantContractProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        color: AppTheme.primary,
        onRefresh: () async => ref.invalidate(tenantContractProvider),
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
          error: (e, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: AppTheme.danger, size: 48),
                const SizedBox(height: 16),
                Text('Failed to load contract details', style: GoogleFonts.inter(color: Colors.white)),
                TextButton.icon(icon: const Icon(Icons.refresh), label: const Text('Retry'), onPressed: () => ref.invalidate(tenantContractProvider)),
              ],
            ),
          ),
          data: (contracts) {
            if (contracts.isEmpty) {
              return Center(
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.description_outlined, size: 64, color: AppTheme.textSecondary.withValues(alpha: 0.4)),
                        const SizedBox(height: 16),
                        Text('No active contract found', style: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Text('You do not have any active rental contracts assigned to your account.', style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 13), textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                ),
              );
            }

            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: contracts.length,
              itemBuilder: (context, index) {
                final contract = contracts[index] as Map<String, dynamic>;
                final contractId = contract['id'];
                final status = contract['status']?.toString() ?? 'unknown';
                final statusColor = _statusColor(status);
                final buildingName = contract['building_name']?.toString() ?? 'N/A';
                final apartmentCode = contract['apartment_code']?.toString() ?? contract['apartment_number']?.toString() ?? 'N/A';
                final rentAmount = _parse(contract['monthly_rent'] ?? contract['rent_amount']);

                return Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  child: Column(
                    children: [
                      // Contract header
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF0E2925), Color(0xFF0B1926)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), shape: BoxShape.circle),
                              child: const Icon(Icons.description_rounded, color: Colors.white, size: 36),
                            ),
                            const SizedBox(height: 12),
                            Text('Rental Contract', style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                            Text('$buildingName • Apt $apartmentCode', style: GoogleFonts.inter(color: Colors.white70, fontSize: 14)),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20), border: Border.all(color: statusColor.withValues(alpha: 0.4))),
                              child: Text(status.replaceAll('_', ' ').toUpperCase(), style: GoogleFonts.inter(color: statusColor, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1)),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Contract details
                      _SectionCard(
                        title: 'PROPERTY DETAILS',
                        children: [
                          _DetailRow(label: 'Building', value: buildingName),
                          _DetailRow(label: 'Apartment', value: 'Apt $apartmentCode'),
                          if (contract['floor'] != null)
                            _DetailRow(label: 'Floor', value: '${contract['floor']}'),
                          if (contract['apartment_type'] != null)
                            _DetailRow(label: 'Type', value: contract['apartment_type']?.toString() ?? 'N/A'),
                        ],
                      ),

                      const SizedBox(height: 12),

                      _SectionCard(
                        title: 'CONTRACT PERIOD',
                        children: [
                          _DetailRow(label: 'Start Date', value: _fmtDate(contract['start_date']?.toString())),
                          _DetailRow(label: 'End Date', value: _fmtDate(contract['end_date']?.toString())),
                        ],
                      ),

                      const SizedBox(height: 12),

                      _SectionCard(
                        title: 'FINANCIAL',
                        children: [
                          _DetailRow(
                            label: 'Monthly Rent',
                            value: 'CFA ${NumberFormat('#,##0').format(rentAmount)}',
                            highlight: true,
                          ),
                          if (contract['monthly_insurance'] != null || contract['insurance_amount'] != null)
                            _DetailRow(
                              label: 'Security Deposit / Insurance',
                              value: 'CFA ${NumberFormat('#,##0').format(_parse(contract['monthly_insurance'] ?? contract['insurance_amount']))}',
                            ),
                        ],
                      ),

                      if (status == 'Pending_Signature') ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: AppTheme.warning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.warning.withValues(alpha: 0.3))),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.warning_amber_rounded, color: AppTheme.warning),
                                  const SizedBox(width: 12),
                                  Expanded(child: Text('Contract Signature Required', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold))),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.warning, foregroundColor: Colors.black, minimumSize: const Size.fromHeight(44)),
                                icon: const Icon(Icons.draw),
                                label: const Text('Sign Contract', style: TextStyle(fontWeight: FontWeight.bold)),
                                onPressed: () async {
                                  try {
                                    final fakeBase64 = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=";
                                    await ApiService().post('/tenant-portal/contract/sign', data: {
                                      'contract_id': contractId,
                                      'document_url': fakeBase64,
                                    });
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Contract signed successfully!')));
                                      ref.invalidate(tenantContractProvider);
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
                                    }
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ],

                      if (status.toLowerCase() == 'active' || status.toLowerCase() == 'approved') ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.surfaceHover)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('CONTRACT RENEWAL', style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                                      onPressed: () async {
                                        try {
                                          await ApiService().post('/tenant-portal/renewal/request', data: {'contract_id': contractId});
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Renewal request submitted!')));
                                          }
                                        } catch (e) {
                                          if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                                        }
                                      },
                                      child: const Text('Request Renewal', style: TextStyle(color: Colors.white, fontSize: 12)),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: OutlinedButton(
                                      style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.textSecondary)),
                                      onPressed: () async {
                                        try {
                                          await ApiService().post('/tenant-portal/renewal/decline', data: {'contract_id': contractId});
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Renewal declined.')));
                                          }
                                        } catch (e) {
                                          if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                                        }
                                      },
                                      child: const Text('Decline Renewal', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.surfaceHover),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;
  const _DetailRow({required this.label, required this.value, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 13)),
          Text(value, style: GoogleFonts.inter(color: highlight ? AppTheme.success : Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
