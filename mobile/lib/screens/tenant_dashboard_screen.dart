// ─── Tenant Dashboard Screen ──────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../config/app_theme.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';

final tenantPortalDashboardProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  try {
    final results = await Future.wait([
      ApiService().get('/tenant-portal/dashboard'),
      ApiService().get('/tenant-portal/rent-history'),
    ]);

    final dashData = (results[0].data as Map<String, dynamic>?) ?? {};
    final contractsList = (dashData['contracts'] as List<dynamic>?) ?? [];

    final rentHistoryList = (results[1].data as List<dynamic>?) ?? [];

    double totalOutstanding = 0.0;
    Map<String, dynamic>? lastPayment;

    for (final inv in rentHistoryList) {
      if (inv is Map<String, dynamic>) {
        final debt = _parseNum(inv['outstanding_debt']);
        totalOutstanding += debt;

        final paidAmount = _parseNum(inv['paid_amount']);
        if (paidAmount > 0) {
          lastPayment ??= inv;
        }
      }
    }

    final primaryContract = contractsList.isNotEmpty ? (contractsList.first as Map<String, dynamic>) : null;

    return {
      'contracts': contractsList,
      'primaryContract': primaryContract,
      'rentHistory': rentHistoryList,
      'totalOutstanding': totalOutstanding,
      'lastPayment': lastPayment,
    };
  } catch (e) {
    throw Exception('Failed to load dashboard data: $e');
  }
});

double _parseNum(dynamic v) {
  if (v == null) return 0.0;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0.0;
}

class TenantDashboardScreen extends ConsumerWidget {
  const TenantDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(tenantPortalDashboardProvider);
    final user = ref.watch(authProvider).user;
    final isMobile = MediaQuery.of(context).size.width <= 600;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        color: AppTheme.primary,
        onRefresh: () async => ref.invalidate(tenantPortalDashboardProvider),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0E2925), Color(0xFF0B1926)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: AppTheme.info.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 8))],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
                      child: const Icon(Icons.home_rounded, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Welcome, ${user?.name ?? 'Tenant'}', style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                          Text('Tenant Portal', style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.7), fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              async.when(
                loading: () => const Center(child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(color: AppTheme.primary),
                )),
                error: (e, _) => Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppTheme.danger.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppTheme.danger),
                      const SizedBox(width: 12),
                      Expanded(child: Text('Failed to load dashboard data', style: GoogleFonts.inter(color: Colors.white))),
                      TextButton(child: const Text('Retry'), onPressed: () => ref.invalidate(tenantPortalDashboardProvider)),
                    ],
                  ),
                ),
                data: (data) {
                  final primaryContract = data['primaryContract'] as Map<String, dynamic>?;
                  final totalOutstanding = (data['totalOutstanding'] as num?)?.toDouble() ?? 0.0;
                  final lastPayment = data['lastPayment'] as Map<String, dynamic>?;

                  final aptCode = primaryContract?['apartment_code']?.toString() ?? primaryContract?['apartment_number']?.toString();
                  final bldName = primaryContract?['building_name']?.toString();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Summary cards
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.5,
                        children: [
                          _TenantStatCard(
                            title: 'Outstanding',
                            value: 'CFA ${NumberFormat('#,##0').format(totalOutstanding)}',
                            icon: Icons.payment_outlined,
                            color: totalOutstanding > 0 ? AppTheme.danger : AppTheme.success,
                          ),
                          _TenantStatCard(
                            title: 'Apartment',
                            value: aptCode != null ? 'Apt $aptCode' : 'N/A',
                            subtitle: bldName,
                            icon: Icons.meeting_room_outlined,
                            color: AppTheme.info,
                          ),
                        ],
                      ),

                      if (primaryContract != null) ...[
                        const SizedBox(height: 20),
                        Text('MY CONTRACT', style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.surfaceHover),
                          ),
                          child: Column(
                            children: [
                              _ContractRow('Building', primaryContract['building_name']?.toString() ?? 'N/A'),
                              const SizedBox(height: 8),
                              _ContractRow('Apartment', 'Apt ${aptCode ?? 'N/A'}'),
                              const SizedBox(height: 8),
                              _ContractRow('Monthly Rent', 'CFA ${NumberFormat('#,##0').format(_parseNum(primaryContract['monthly_rent'] ?? primaryContract['rent_amount']))}'),
                              const SizedBox(height: 8),
                              _ContractRow('Status', primaryContract['status']?.toString().replaceAll('_', ' ') ?? 'N/A', highlight: true),
                            ],
                          ),
                        ),
                      ],

                      if (lastPayment != null) ...[
                        const SizedBox(height: 20),
                        Text('LAST PAYMENT', style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.success.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.success.withValues(alpha: 0.2)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(color: AppTheme.success.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                                child: const Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 24),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'CFA ${NumberFormat('#,##0').format(_parseNum(lastPayment['paid_amount'] ?? lastPayment['amount']))}',
                                      style: GoogleFonts.outfit(color: AppTheme.success, fontSize: 18, fontWeight: FontWeight.w700),
                                    ),
                                    Text(
                                      'Invoice #${lastPayment['invoice_number'] ?? lastPayment['id']} • ${lastPayment['due_date'] ?? ''}',
                                      style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      Text('QUICK ACTIONS', style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildActionButton(
                              title: 'Pay Rent',
                              icon: Icons.payment_rounded,
                              onTap: () => context.push('/tenant-payments'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildActionButton(
                              title: 'Maintenance',
                              icon: Icons.build_rounded,
                              onTap: () {
                                String title = '';
                                String description = '';
                                String urgency = 'Medium';
                                String category = 'General Maintenance';
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
                                              Text('New Maintenance Request', style: GoogleFonts.outfit(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold)),
                                              const SizedBox(height: 24),
                                              TextField(
                                                decoration: const InputDecoration(labelText: 'Title / Issue Summary', labelStyle: TextStyle(color: AppTheme.textSecondary)),
                                                style: const TextStyle(color: Colors.white),
                                                onChanged: (v) => title = v,
                                              ),
                                              const SizedBox(height: 16),
                                              DropdownButtonFormField<String>(
                                                value: category,
                                                dropdownColor: AppTheme.surface,
                                                decoration: const InputDecoration(labelText: 'Category', labelStyle: TextStyle(color: AppTheme.textSecondary)),
                                                items: ['General Maintenance', 'Plumbing', 'Electrical', 'AC / HVAC', 'Carpentry', 'Doors & Windows', 'Appliance'].map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(color: Colors.white)))).toList(),
                                                onChanged: (v) {
                                                  if (v != null) setState(() => category = v);
                                                },
                                              ),
                                              const SizedBox(height: 16),
                                              TextField(
                                                decoration: const InputDecoration(labelText: 'Problem Details & Description', labelStyle: TextStyle(color: AppTheme.textSecondary)),
                                                style: const TextStyle(color: Colors.white),
                                                maxLines: 3,
                                                onChanged: (v) => description = v,
                                              ),
                                              const SizedBox(height: 16),
                                              DropdownButtonFormField<String>(
                                                value: urgency,
                                                dropdownColor: AppTheme.surface,
                                                decoration: const InputDecoration(labelText: 'Urgency', labelStyle: TextStyle(color: AppTheme.textSecondary)),
                                                items: ['Low', 'Medium', 'High', 'Critical'].map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(color: Colors.white)))).toList(),
                                                onChanged: (v) {
                                                  if (v != null) setState(() => urgency = v);
                                                },
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
                                                      if (title.isEmpty || description.isEmpty) return;
                                                      Navigator.pop(context);
                                                      try {
                                                        final tenantId = primaryContract?['tenant_id'];
                                                        final apartmentId = primaryContract?['apartment_id'];
                                                        await ApiService().post('/maintenance/requests', data: {
                                                          'tenant_id': tenantId,
                                                          'apartment_id': apartmentId,
                                                          'title': title,
                                                          'description': description,
                                                          'category': category,
                                                          'urgency': urgency,
                                                          'priority': urgency == 'Critical' ? 'Urgent' : urgency,
                                                          'status': 'Open',
                                                        });
                                                        if (context.mounted) {
                                                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request submitted successfully.')));
                                                        }
                                                      } catch (e) {
                                                        if (context.mounted) {
                                                          if (e.toString().contains('OFFLINE_QUEUED')) {
                                                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved offline and queued for sync ✓'), backgroundColor: Colors.amber));
                                                          } else {
                                                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to submit: $e')));
                                                          }
                                                        }
                                                      }
                                                    },
                                                    child: const Text('Submit', style: TextStyle(color: Colors.white)),
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
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({required String title, required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppTheme.primary.withValues(alpha: 0.1),
          border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.primary, size: 28),
            const SizedBox(height: 8),
            Text(title, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class _TenantStatCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color color;
  const _TenantStatCard({required this.title, required this.value, this.subtitle, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(value, style: GoogleFonts.outfit(color: color, fontSize: 16, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(subtitle != null ? '$title • $subtitle' : title, style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _ContractRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;
  const _ContractRow(this.label, this.value, {this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 13)),
        Text(value, style: GoogleFonts.inter(color: highlight ? AppTheme.success : Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
