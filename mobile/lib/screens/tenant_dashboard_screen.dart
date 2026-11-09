// ─── Tenant Portal Dashboard Screen ──────────────────────────────────────────
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

    final primaryContract = contractsList.isNotEmpty
        ? (contractsList.first as Map<String, dynamic>)
        : null;

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

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: RefreshIndicator(
        color: AppTheme.primary,
        backgroundColor: AppTheme.surface,
        onRefresh: () async => ref.invalidate(tenantPortalDashboardProvider),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Resident Welcome Card ────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(11),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.home_outlined,
                        color: AppTheme.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome, ${user?.name ?? 'Resident'}',
                            style: GoogleFonts.outfit(
                              color: AppTheme.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Resident lease, payments, and maintenance portal',
                            style: GoogleFonts.inter(
                              color: AppTheme.textSecondary,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              async.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(
                      color: AppTheme.primary,
                      strokeWidth: 2.5,
                    ),
                  ),
                ),
                error: (e, _) => Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: AppTheme.danger),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Unable to load resident dashboard data.',
                          style: GoogleFonts.inter(color: AppTheme.textPrimary, fontSize: 13),
                        ),
                      ),
                      TextButton(
                        onPressed: () => ref.invalidate(tenantPortalDashboardProvider),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
                data: (data) {
                  final primaryContract = data['primaryContract'] as Map<String, dynamic>?;
                  final totalOutstanding = (data['totalOutstanding'] as num?)?.toDouble() ?? 0.0;
                  final lastPayment = data['lastPayment'] as Map<String, dynamic>?;

                  final aptCode = primaryContract?['apartment_code']?.toString() ??
                      primaryContract?['apartment_number']?.toString();
                  final bldName = primaryContract?['building_name']?.toString();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 2-Column Summary Grid
                      GridView(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          mainAxisExtent: 88,
                        ),
                        children: [
                          _TenantStatCard(
                            title: 'Outstanding Balance',
                            value: 'CFA ${NumberFormat('#,##0').format(totalOutstanding)}',
                            icon: Icons.payments_outlined,
                            color: totalOutstanding > 0 ? AppTheme.danger : AppTheme.success,
                          ),
                          _TenantStatCard(
                            title: bldName ?? 'Residence',
                            value: aptCode != null ? 'Apt $aptCode' : 'Assigned Unit',
                            icon: Icons.meeting_room_outlined,
                            color: AppTheme.info,
                          ),
                        ],
                      ),

                      if (primaryContract != null) ...[
                        const SizedBox(height: 22),
                        AppTheme.sectionHeader('Lease Summary'),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: Column(
                            children: [
                              _ContractRow(
                                'Building',
                                primaryContract['building_name']?.toString() ?? 'N/A',
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 10),
                                child: Divider(color: AppTheme.border, height: 1),
                              ),
                              _ContractRow('Apartment', 'Apt ${aptCode ?? 'N/A'}'),
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 10),
                                child: Divider(color: AppTheme.border, height: 1),
                              ),
                              _ContractRow(
                                'Monthly Rent',
                                'CFA ${NumberFormat('#,##0').format(_parseNum(primaryContract['monthly_rent'] ?? primaryContract['rent_amount']))}',
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 10),
                                child: Divider(color: AppTheme.border, height: 1),
                              ),
                              _ContractRow(
                                'Status',
                                primaryContract['status']?.toString().replaceAll('_', ' ') ?? 'Active',
                                highlight: true,
                              ),
                            ],
                          ),
                        ),
                      ],

                      if (lastPayment != null) ...[
                        const SizedBox(height: 22),
                        AppTheme.sectionHeader('Most Recent Payment'),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(9),
                                decoration: BoxDecoration(
                                  color: AppTheme.success.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.check_circle_outline_rounded,
                                  color: AppTheme.success,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'CFA ${NumberFormat('#,##0').format(_parseNum(lastPayment['paid_amount'] ?? lastPayment['amount']))}',
                                      style: GoogleFonts.outfit(
                                        color: AppTheme.textPrimary,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Invoice #${lastPayment['invoice_number'] ?? lastPayment['id']} • ${lastPayment['due_date'] ?? ''}',
                                      style: GoogleFonts.inter(
                                        color: AppTheme.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 22),
                      AppTheme.sectionHeader('Quick Actions'),
                      Row(
                        children: [
                          Expanded(
                            child: _buildActionButton(
                              title: 'Payments',
                              subtitle: 'Invoices & history',
                              icon: Icons.payments_outlined,
                              onTap: () => context.push('/tenant-payments'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildActionButton(
                              title: 'Maintenance',
                              subtitle: 'Request service',
                              icon: Icons.build_circle_outlined,
                              onTap: () => _showNewRequestSheet(context, primaryContract),
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

  void _showNewRequestSheet(BuildContext context, Map<String, dynamic>? primaryContract) {
    String title = '';
    String description = '';
    String urgency = 'Medium';
    String category = 'General Maintenance';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (sheetCtx, setState) => Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(sheetCtx).viewInsets.bottom),
          decoration: const BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(top: BorderSide(color: AppTheme.borderLight)),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.borderLight,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'New Maintenance Request',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(sheetCtx),
                        icon: const Icon(Icons.close_rounded, color: AppTheme.textSecondary, size: 20),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Issue Summary',
                      hintText: 'e.g. AC unit not cooling',
                    ),
                    style: GoogleFonts.inter(color: AppTheme.textPrimary, fontSize: 13.5),
                    onChanged: (v) => title = v,
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    value: category,
                    dropdownColor: AppTheme.surface,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: const [
                      'General Maintenance',
                      'Plumbing',
                      'Electrical',
                      'AC / HVAC',
                      'Carpentry',
                      'Doors & Windows',
                      'Appliance',
                    ]
                        .map(
                          (e) => DropdownMenuItem(
                            value: e,
                            child: Text(
                              e,
                              style: GoogleFonts.inter(
                                color: AppTheme.textPrimary,
                                fontSize: 13.5,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => category = v);
                    },
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Problem Description',
                      hintText: 'Provide details about the issue and location...',
                    ),
                    style: GoogleFonts.inter(color: AppTheme.textPrimary, fontSize: 13.5),
                    maxLines: 3,
                    onChanged: (v) => description = v,
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    value: urgency,
                    dropdownColor: AppTheme.surface,
                    decoration: const InputDecoration(labelText: 'Urgency'),
                    items: const ['Low', 'Medium', 'High', 'Critical']
                        .map(
                          (e) => DropdownMenuItem(
                            value: e,
                            child: Text(
                              e,
                              style: GoogleFonts.inter(
                                color: AppTheme.textPrimary,
                                fontSize: 13.5,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => urgency = v);
                    },
                  ),
                  const SizedBox(height: 22),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(sheetCtx),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.inter(
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: const Color(0xFF04130F),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () async {
                          if (title.trim().isEmpty || description.trim().isEmpty) return;
                          Navigator.pop(sheetCtx);
                          try {
                            final tenantId = primaryContract?['tenant_id'];
                            final apartmentId = primaryContract?['apartment_id'];
                            await ApiService().post('/maintenance/requests', data: {
                              'tenant_id': tenantId,
                              'apartment_id': apartmentId,
                              'title': title.trim(),
                              'description': description.trim(),
                              'category': category,
                              'urgency': urgency,
                              'priority': urgency == 'Critical' ? 'Urgent' : urgency,
                              'status': 'Open',
                            });
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Maintenance request submitted successfully.'),
                                  backgroundColor: AppTheme.success,
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              if (e.toString().contains('OFFLINE_QUEUED')) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Saved offline and queued for synchronization.'),
                                    backgroundColor: AppTheme.warning,
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Failed to submit: $e'),
                                    backgroundColor: AppTheme.danger,
                                  ),
                                );
                              }
                            }
                          }
                        },
                        child: Text(
                          'Submit Request',
                          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
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

  Widget _buildActionButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          border: Border.all(color: AppTheme.border),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppTheme.primary, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13.5,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      color: AppTheme.textMuted,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TenantStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  const _TenantStatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(7),
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: color, size: 14),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Text(
            value,
            style: GoogleFonts.outfit(
              color: AppTheme.textPrimary,
              fontSize: 16.5,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
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
        Text(
          label,
          style: GoogleFonts.inter(
            color: AppTheme.textSecondary,
            fontSize: 13,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            color: highlight ? AppTheme.success : AppTheme.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
