// ─── Tenant Details Screen ──────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/app_theme.dart';
import '../services/api_service.dart';
import '../utils/pdf_generator.dart';
import 'package:printing/printing.dart';

final tenantDetailsProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, id) async {
  final res = await ApiService().get('/tenants/$id');
  return res.data as Map<String, dynamic>;
});

final tenantContractsProvider = FutureProvider.family<List<dynamic>, String>((ref, id) async {
  final res = await ApiService().get('/tenants/$id/apartments');
  return res.data as List<dynamic>;
});

final tenantRentHistoryProvider = FutureProvider.family<List<dynamic>, String>((ref, id) async {
  final res = await ApiService().get('/tenants/$id/rent-history');
  return res.data as List<dynamic>;
});

final tenantInsuranceProvider = FutureProvider.family<List<dynamic>, String>((ref, id) async {
  final res = await ApiService().get('/insurance/by-tenant/$id');
  return res.data as List<dynamic>;
});

final tenantElectricityInvoicesAdminProvider = FutureProvider.family<List<dynamic>, String>((ref, id) async {
  final contracts = await ref.watch(tenantContractsProvider(id).future);
  
  final Set<int> apartmentIds = {};
  for (final c in contracts) {
    if (c is Map<String, dynamic> && c['apartment_id'] != null) {
      final aptId = int.tryParse(c['apartment_id'].toString());
      if (aptId != null) apartmentIds.add(aptId);
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

final tenantElectricitySubscriptionProvider = FutureProvider.family<Map<String, dynamic>?, String>((ref, id) async {
  final contracts = await ref.watch(tenantContractsProvider(id).future);
  if (contracts.isEmpty) return null;
  final first = contracts.first;
  final aptId = first['apartment_id'];
  if (aptId == null) return null;
  try {
    final res = await ApiService().get('/energy/apartments/$aptId/subscriptions');
    if (res.data is Map<String, dynamic>) {
      final data = res.data as Map<String, dynamic>;
      if (data['status'] != null && data['status'] != 'None') {
        data['apartment_code'] = first['apartment_code'];
        data['building_name'] = first['building_name'];
        return data;
      }
    }
  } catch (_) {}
  return null;
});

final tenantRentProfileProvider = FutureProvider.family<Map<String, dynamic>?, String>((ref, id) async {
  try {
    final res = await ApiService().get('/rent-profiles/tenant/$id');
    return res.data as Map<String, dynamic>?;
  } catch (e) {
    return null;
  }
});

class TenantDetailsScreen extends ConsumerStatefulWidget {
  final String id;
  const TenantDetailsScreen({super.key, required this.id});

  @override
  ConsumerState<TenantDetailsScreen> createState() => _TenantDetailsScreenState();
}

class _TenantDetailsScreenState extends ConsumerState<TenantDetailsScreen> with WidgetsBindingObserver {
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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(tenantDetailsProvider(widget.id));
      ref.invalidate(tenantContractsProvider(widget.id));
      ref.invalidate(tenantRentHistoryProvider(widget.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(tenantDetailsProvider(widget.id));
    final isMobile = MediaQuery.of(context).size.width <= 600;

    return DefaultTabController(
      length: 7,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: async.when(
          loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
          error: (e, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: AppTheme.danger, size: 48),
                const SizedBox(height: 16),
                Text('Failed to load tenant details', style: GoogleFonts.inter(color: Colors.white)),
                TextButton(
                  onPressed: () => ref.invalidate(tenantDetailsProvider(widget.id)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
          data: (tenant) {
            return Padding(
              padding: EdgeInsets.all(isMobile ? 16 : 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                        onPressed: () => context.pop(),
                      ),
                      const SizedBox(width: 8),
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: AppTheme.primary.withOpacity(0.2),
                        child: Text(
                          (tenant['full_name'] ?? 'T')[0].toUpperCase(),
                          style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.primary),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tenant['full_name'] ?? 'Unknown Tenant',
                              style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w700, color: Colors.white),
                            ),
                            Row(
                              children: [
                                Icon(Icons.phone_rounded, size: 14, color: AppTheme.textSecondary),
                                const SizedBox(width: 6),
                                Text(tenant['phone'] ?? 'No phone', style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 14)),
                                if (tenant['email'] != null && tenant['email'].toString().isNotEmpty) ...[
                                  const SizedBox(width: 16),
                                  Icon(Icons.email_rounded, size: 14, color: AppTheme.textSecondary),
                                  const SizedBox(width: 6),
                                  Expanded(child: Text(tenant['email'], style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 14), overflow: TextOverflow.ellipsis)),
                                ]
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // TabBar
                  Container(
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: AppTheme.surfaceHover, width: 2)),
                    ),
                    child: TabBar(
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      indicatorColor: AppTheme.primary,
                      indicatorWeight: 3,
                      labelColor: AppTheme.primary,
                      unselectedLabelColor: AppTheme.textSecondary,
                      labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
                      unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 14),
                      tabs: const [
                        Tab(text: 'Overview'),
                        Tab(text: 'Contracts'),
                        Tab(text: 'Payment History'),
                        Tab(text: 'Electricity'),
                        Tab(text: 'Insurance'),
                        Tab(text: 'Maintenance'),
                        Tab(text: 'Documents'),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Tab Views
                  Expanded(
                    child: TabBarView(
                      children: [
                        _OverviewTab(tenant: tenant, tenantId: widget.id),
                        _ContractsTab(tenantId: widget.id),
                        _PaymentHistoryTab(tenantId: widget.id),
                        _ElectricityTab(tenantId: widget.id),
                        _InsuranceTab(tenantId: widget.id),
                        const _PlaceholderTab(title: 'Maintenance Requests', message: 'No maintenance requests found.'),
                        const _PlaceholderTab(title: 'Documents', message: 'No documents uploaded.'),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
// ─── Tab Views ───────────────────────────────────────────────────────────────

class _PlaceholderTab extends StatelessWidget {
  final String title;
  final String message;
  const _PlaceholderTab({required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_rounded, size: 64, color: AppTheme.surfaceHover),
          const SizedBox(height: 16),
          Text(title, style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white)),
          const SizedBox(height: 8),
          Text(message, style: GoogleFonts.inter(color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}

class _OverviewTab extends ConsumerWidget {
  final Map<String, dynamic> tenant;
  final String tenantId;

  const _OverviewTab({required this.tenant, required this.tenantId});

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
  Widget build(BuildContext context, WidgetRef ref) {
    final isContractActive = tenant['contract_status'] == 'Active' || tenant['contract_status'] == 'Approved';
    
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.only(top: 24),
          child: Flex(
            direction: constraints.maxWidth > 800 ? Axis.horizontal : Axis.vertical,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Column (Contract Details)
              Expanded(
                flex: constraints.maxWidth > 800 ? 2 : 0,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.surfaceHover),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Lease Information', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: isContractActive ? AppTheme.success.withOpacity(0.15) : AppTheme.textSecondary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              tenant['contract_status'] ?? 'No Contract',
                              style: GoogleFonts.inter(color: isContractActive ? AppTheme.success : AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      _InfoRow(icon: Icons.apartment_rounded, label: 'Building', value: tenant['building_name'] ?? 'N/A'),
                      const SizedBox(height: 16),
                      _InfoRow(icon: Icons.meeting_room_rounded, label: 'Apartment', value: 'Apt ${tenant['apartment_code'] ?? 'N/A'}'),
                      const SizedBox(height: 16),
                      _InfoRow(icon: Icons.payments_rounded, label: 'Monthly Rent', value: 'CFA ${_formatNum(tenant['monthly_rent'])}'),
                      const SizedBox(height: 16),
                      _InfoRow(icon: Icons.calendar_today_rounded, label: 'Start Date', value: tenant['start_date'] ?? 'N/A'),
                      const SizedBox(height: 16),
                      _InfoRow(icon: Icons.event_available_rounded, label: 'End Date', value: tenant['end_date'] ?? 'N/A'),
                      const SizedBox(height: 16),
                      _InfoRow(icon: Icons.electric_bolt_rounded, label: 'Generator Status', value: tenant['generator_subscription'] ?? 'None'),
                    ],
                  ),
                ),
              ),
              
              if (constraints.maxWidth > 800) const SizedBox(width: 24) else const SizedBox(height: 24),
              
              // Right Column (Actions)
              Expanded(
                flex: constraints.maxWidth > 800 ? 1 : 0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Quick Actions', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white)),
                    const SizedBox(height: 16),
                    _ActionCard(
                      title: 'Add Payment',
                      icon: Icons.payments_rounded,
                      color: AppTheme.success,
                      onTap: () {
                        String date = DateTime.now().toString().split(' ')[0];
                        String amount = '';
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
                                      Text('Add Historical Payment', style: GoogleFonts.outfit(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 24),
                                      TextField(
                                        decoration: const InputDecoration(labelText: 'Due Date (YYYY-MM-DD)', labelStyle: TextStyle(color: AppTheme.textSecondary)),
                                        style: const TextStyle(color: Colors.white),
                                        onChanged: (v) => date = v,
                                        controller: TextEditingController(text: date)..selection = TextSelection.collapsed(offset: date.length),
                                      ),
                                      const SizedBox(height: 16),
                                      TextField(
                                        decoration: const InputDecoration(labelText: 'Amount (CFA)', labelStyle: TextStyle(color: AppTheme.textSecondary)),
                                        style: const TextStyle(color: Colors.white),
                                        keyboardType: TextInputType.number,
                                        onChanged: (v) => amount = v,
                                        controller: TextEditingController(text: amount)..selection = TextSelection.collapsed(offset: amount.length),
                                      ),
                                      const SizedBox(height: 24),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary))),
                                          const SizedBox(width: 8),
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
                                            onPressed: () async {
                                              Navigator.pop(context);
                                              try {
                                                await ApiService().post('/rent/historical', data: {
                                                  'tenant_id': tenantId,
                                                  'due_date': date,
                                                  'amount': amount,
                                                  'is_paid': true,
                                                });
                                                if (context.mounted) {
                                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment added successfully.')));
                                                  ref.invalidate(tenantRentHistoryProvider(tenantId));
                                                }
                                              } catch (e) {
                                                if (context.mounted) {
                                                  if (e.toString().contains('OFFLINE_QUEUED')) {
                                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved offline and queued for sync ✓'), backgroundColor: Colors.amber));
                                                    ref.invalidate(tenantRentHistoryProvider(tenantId));
                                                  } else {
                                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to add payment: $e')));
                                                  }
                                                }
                                              }
                                            },
                                            child: const Text('Add Payment', style: TextStyle(color: Colors.white)),
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
                    const SizedBox(height: 12),
                    _ActionCard(
                      title: 'Renew Contract',
                      icon: Icons.autorenew_rounded,
                      color: AppTheme.primary,
                      onTap: () {
                        String start = tenant['start_date'] ?? '';
                        String end = tenant['end_date'] ?? '';
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => StatefulBuilder(
                            builder: (context, setState) {
                              return Container(
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
                                        Text('Renew Contract', style: GoogleFonts.outfit(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 24),
                                        TextField(
                                          decoration: const InputDecoration(labelText: 'Start Date (YYYY-MM-DD)', labelStyle: TextStyle(color: AppTheme.textSecondary)),
                                          style: const TextStyle(color: Colors.white),
                                          onChanged: (v) => start = v,
                                          controller: TextEditingController(text: start)..selection = TextSelection.collapsed(offset: start.length),
                                        ),
                                        const SizedBox(height: 16),
                                        TextField(
                                          decoration: const InputDecoration(labelText: 'End Date (YYYY-MM-DD)', labelStyle: TextStyle(color: AppTheme.textSecondary)),
                                          style: const TextStyle(color: Colors.white),
                                          onChanged: (v) => end = v,
                                          controller: TextEditingController(text: end)..selection = TextSelection.collapsed(offset: end.length),
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
                                                  await ApiService().post('/contracts/${tenant['contract_id']}/renew', data: {
                                                    'start_date': start,
                                                    'end_date': end,
                                                  });
                                                  if (context.mounted) {
                                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Contract renewed successfully.')));
                                                    ref.invalidate(tenantDetailsProvider(tenantId));
                                                    ref.invalidate(tenantContractsProvider(tenantId));
                                                  }
                                                } catch (e) {
                                                  if (context.mounted) {
                                                    if (e.toString().contains('OFFLINE_QUEUED')) {
                                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved offline and queued for sync ✓'), backgroundColor: Colors.amber));
                                                      ref.invalidate(tenantDetailsProvider(tenantId));
                                                      ref.invalidate(tenantContractsProvider(tenantId));
                                                    } else {
                                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to renew: $e')));
                                                    }
                                                  }
                                                }
                                              },
                                              child: const Text('Renew', style: TextStyle(color: Colors.white)),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _ActionCard(
                      title: 'Update Details',
                      icon: Icons.edit_rounded,
                      color: AppTheme.warning,
                      onTap: () {
                        String name = tenant['full_name'] ?? '';
                        String phone = tenant['phone'] ?? '';
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => StatefulBuilder(
                            builder: (context, setState) {
                              return Container(
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
                                        Text('Update Details', style: GoogleFonts.outfit(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 24),
                                        TextField(
                                          decoration: const InputDecoration(labelText: 'Full Name', labelStyle: TextStyle(color: AppTheme.textSecondary)),
                                          style: const TextStyle(color: Colors.white),
                                          onChanged: (v) => name = v,
                                          controller: TextEditingController(text: name)..selection = TextSelection.collapsed(offset: name.length),
                                        ),
                                        const SizedBox(height: 16),
                                        TextField(
                                          decoration: const InputDecoration(labelText: 'Phone', labelStyle: TextStyle(color: AppTheme.textSecondary)),
                                          style: const TextStyle(color: Colors.white),
                                          onChanged: (v) => phone = v,
                                          controller: TextEditingController(text: phone)..selection = TextSelection.collapsed(offset: phone.length),
                                        ),
                                        const SizedBox(height: 24),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary))),
                                            const SizedBox(width: 8),
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.warning),
                                              onPressed: () async {
                                                Navigator.pop(context);
                                                try {
                                                  await ApiService().put('/tenants/$tenantId', data: {
                                                    'full_name': name,
                                                    'phone': phone,
                                                  });
                                                  if (context.mounted) {
                                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tenant updated successfully.')));
                                                    ref.invalidate(tenantDetailsProvider(tenantId));
                                                  }
                                                } catch (e) {
                                                  if (context.mounted) {
                                                    if (e.toString().contains('OFFLINE_QUEUED')) {
                                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved offline and queued for sync ✓'), backgroundColor: Colors.amber));
                                                      ref.invalidate(tenantDetailsProvider(tenantId));
                                                    } else {
                                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update: $e')));
                                                    }
                                                  }
                                                }
                                              },
                                              child: const Text('Update', style: TextStyle(color: Colors.white)),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _ActionCard(
                      title: 'Print Invoice',
                      icon: Icons.print_rounded,
                      color: Colors.purple,
                      onTap: () async {
                        final pdf = await PdfGenerator.generateRentInvoice(tenant, null);
                        await Printing.layoutPdf(onLayout: (format) async => pdf.save());
                      },
                    ),
                    const SizedBox(height: 12),
                    _ActionCard(
                      title: 'Contact Tenant',
                      icon: Icons.chat_bubble_outline_rounded,
                      color: AppTheme.info,
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: AppTheme.surface,
                          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
                          builder: (context) => SafeArea(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Contact ${tenant['full_name']}', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white)),
                                  const SizedBox(height: 16),
                                  if (tenant['phone'] != null)
                                    ListTile(
                                      leading: const Icon(Icons.phone_rounded, color: AppTheme.primary),
                                      title: Text(tenant['phone'], style: GoogleFonts.inter(color: Colors.white)),
                                      subtitle: Text('Call Tenant', style: GoogleFonts.inter(color: AppTheme.textSecondary)),
                                      onTap: () async {
                                        context.pop();
                                        final url = Uri.parse('tel:${tenant['phone']}');
                                        if (await canLaunchUrl(url)) await launchUrl(url);
                                      },
                                    ),
                                  if (tenant['email'] != null && tenant['email'].toString().isNotEmpty)
                                    ListTile(
                                      leading: const Icon(Icons.email_rounded, color: AppTheme.primary),
                                      title: Text(tenant['email'], style: GoogleFonts.inter(color: Colors.white)),
                                      subtitle: Text('Email Tenant', style: GoogleFonts.inter(color: AppTheme.textSecondary)),
                                      onTap: () async {
                                        context.pop();
                                        final url = Uri.parse('mailto:${tenant['email']}');
                                        if (await canLaunchUrl(url)) await launchUrl(url);
                                      },
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _ActionCard(
                      title: 'Terminate Lease',
                      icon: Icons.block_rounded,
                      color: AppTheme.danger,
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: Colors.transparent,
                          builder: (context) => Container(
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
                                    Text('Terminate Lease', style: GoogleFonts.outfit(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 16),
                                    Text('Are you sure you want to terminate this lease? This will mark the apartment as vacant and end the current contract.', style: GoogleFonts.inter(color: AppTheme.textSecondary)),
                                    const SizedBox(height: 24),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        TextButton(
                                          onPressed: () => context.pop(),
                                          child: Text('Cancel', style: GoogleFonts.inter(color: AppTheme.textSecondary)),
                                        ),
                                        const SizedBox(width: 8),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
                                          onPressed: () async {
                                            context.pop();
                                            try {
                                              await ApiService().post('/tenants/$tenantId/terminate');
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lease terminated successfully.')));
                                                context.pop(); 
                                                ref.invalidate(tenantDetailsProvider(tenantId));
                                                ref.invalidate(tenantContractsProvider(tenantId));
                                              }
                                            } catch (e) {
                                              if (context.mounted) {
                                                if (e.toString().contains('OFFLINE_QUEUED')) {
                                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved offline and queued for sync ✓'), backgroundColor: Colors.amber));
                                                  context.pop();
                                                  ref.invalidate(tenantDetailsProvider(tenantId));
                                                  ref.invalidate(tenantContractsProvider(tenantId));
                                                } else {
                                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to terminate lease: $e')));
                                                }
                                              }
                                            }
                                          },
                                          child: Text('Terminate', style: GoogleFonts.inter(color: Colors.white)),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.textSecondary),
        const SizedBox(width: 12),
        Text('$label: ', style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 14)),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

class _ActionCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({required this.title, required this.icon, required this.color, required this.onTap});

  @override
  State<_ActionCard> createState() => _ActionCardState();
}

class _ActionCardState extends State<_ActionCard> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isHovered ? widget.color.withOpacity(0.1) : AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isHovered ? widget.color.withOpacity(0.5) : AppTheme.surfaceHover),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: widget.onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  Icon(widget.icon, color: widget.color, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(widget.title, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w500)),
                  ),
                  Icon(Icons.chevron_right_rounded, color: AppTheme.textSecondary, size: 18),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ContractsTab extends ConsumerWidget {
  final String tenantId;
  const _ContractsTab({required this.tenantId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(tenantContractsProvider(tenantId));

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      error: (e, _) => Center(child: Text('Failed to load contracts: $e', style: GoogleFonts.inter(color: AppTheme.danger))),
      data: (contracts) {
        if (contracts.isEmpty) {
          return const _PlaceholderTab(title: 'Contracts', message: 'No contracts found for this tenant.');
        }
        
        return ListView.builder(
          padding: const EdgeInsets.only(top: 24),
          itemCount: contracts.length,
          itemBuilder: (context, index) {
            final c = contracts[index] as Map<String, dynamic>;
            final isActive = c['contract_status'] == 'Active' || c['contract_status'] == 'Approved';
            
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.surfaceHover),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.description_rounded, color: AppTheme.primary),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${c['building_name']} - Apt ${c['apartment_code']}', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                        const SizedBox(height: 4),
                        Text('${c['start_date']} to ${c['end_date']}', style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isActive ? AppTheme.success.withOpacity(0.15) : AppTheme.textSecondary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      c['contract_status'] ?? 'Unknown',
                      style: GoogleFonts.inter(color: isActive ? AppTheme.success : AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _PaymentHistoryTab extends ConsumerStatefulWidget {
  final String tenantId;
  const _PaymentHistoryTab({required this.tenantId});

  @override
  ConsumerState<_PaymentHistoryTab> createState() => _PaymentHistoryTabState();
}

class _PaymentHistoryTabState extends ConsumerState<_PaymentHistoryTab> {
  String _dateFilter = '';

  String _formatNum(dynamic value) {
    if (value == null) return '0.00';
    try {
      final double val = value is String ? double.parse(value) : value.toDouble();
      return NumberFormat('#,##0.00').format(val);
    } catch (e) {
      return '0.00';
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Paid': return AppTheme.success;
      case 'Partial': return AppTheme.warning;
      case 'Overdue': return AppTheme.danger;
      default: return AppTheme.textSecondary;
    }
  }

  void _showRentProfileSettings(BuildContext context, Map<String, dynamic> profile) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
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
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.flash_on_rounded, color: AppTheme.primary),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Rent Profile Settings', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: profile['status'] == 'Active' ? AppTheme.success.withOpacity(0.15) : AppTheme.warning.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                profile['status'] ?? 'Unknown',
                                style: GoogleFonts.inter(color: profile['status'] == 'Active' ? AppTheme.success : AppTheme.warning, fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: AppTheme.textSecondary),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildSettingRow('Auto Renewal', (profile['auto_renewal'].toString() == '1') ? 'Enabled' : 'Disabled'),
                  _buildSettingRow('Billing Frequency', profile['billing_frequency'] ?? 'N/A'),
                  _buildSettingRow('Next Billing Date', profile['next_billing_date'] ?? 'N/A'),
                  _buildSettingRow('Default Payment Method', profile['default_payment_method'] ?? 'N/A'),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSettingRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textSecondary)),
          Text(value, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(tenantRentHistoryProvider(widget.tenantId));
    final profileAsync = ref.watch(tenantRentProfileProvider(widget.tenantId));

    return historyAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      error: (e, _) => Center(child: Text('Failed to load rent history: $e', style: GoogleFonts.inter(color: AppTheme.danger))),
      data: (allInvoices) {
        
        final invoices = allInvoices.where((inv) {
          if (_dateFilter.isEmpty) return true;
          return inv['due_date'].toString().startsWith(_dateFilter);
        }).toList();

        double totalPaid = 0;
        double totalUnpaid = 0;
        for (var inv in allInvoices) {
          totalPaid += double.tryParse(inv['paid_amount']?.toString() ?? '0') ?? 0;
          totalUnpaid += double.tryParse(inv['outstanding_debt']?.toString() ?? '0') ?? 0;
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.surfaceHover),
                ),
                child: Column(
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isTablet = constraints.maxWidth > 400;
                        if (isTablet) {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildTotalStat('Total Paid', totalPaid, AppTheme.success),
                              Container(width: 1, height: 40, color: AppTheme.surfaceHover),
                              _buildTotalStat('Total Unpaid', totalUnpaid, AppTheme.danger),
                            ],
                          );
                        } else {
                          return Column(
                            children: [
                              _buildTotalStat('Total Paid', totalPaid, AppTheme.success),
                              const Divider(color: AppTheme.surfaceHover, height: 32),
                              _buildTotalStat('Total Unpaid', totalUnpaid, AppTheme.danger),
                            ],
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () async {
                              final dt = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                              );
                              if (dt != null) {
                                final m = dt.month.toString().padLeft(2, '0');
                                setState(() {
                                  _dateFilter = '${dt.year}-$m';
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: AppTheme.background,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppTheme.surfaceHover),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_month_rounded, color: AppTheme.textSecondary, size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    _dateFilter.isEmpty ? 'Filter by Month' : _dateFilter,
                                    style: GoogleFonts.inter(color: _dateFilter.isEmpty ? AppTheme.textSecondary : Colors.white, fontSize: 14),
                                  ),
                                  if (_dateFilter.isNotEmpty) ...[
                                    const Spacer(),
                                    GestureDetector(
                                      onTap: () {
                                        setState(() => _dateFilter = '');
                                      },
                                      child: const Icon(Icons.close_rounded, color: AppTheme.textSecondary, size: 18),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        profileAsync.when(
                          loading: () => const SizedBox(width: 48, child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))),
                          error: (e, _) => const SizedBox(),
                          data: (profile) {
                            if (profile == null) return const SizedBox();
                            return InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => _showRentProfileSettings(context, profile),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
                                ),
                                child: const Icon(Icons.settings_rounded, color: AppTheme.primary, size: 20),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            Expanded(
              child: invoices.isEmpty
                ? const _PlaceholderTab(title: 'No Invoices', message: 'No rent invoices match this filter.')
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: invoices.length,
                    itemBuilder: (context, index) {
                      final inv = invoices[index] as Map<String, dynamic>;
                      final status = inv['status'] ?? 'Unpaid';
                      final color = _statusColor(status);
                      final outstanding = double.tryParse(inv['outstanding_debt']?.toString() ?? '0') ?? 0;
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: outstanding > 0 ? AppTheme.danger.withOpacity(0.05) : AppTheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: outstanding > 0 ? AppTheme.danger.withOpacity(0.3) : AppTheme.surfaceHover),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                              child: Icon(Icons.receipt_rounded, color: color, size: 20),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(inv['due_date'] ?? 'N/A', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                                  const SizedBox(height: 2),
                                  Text('Paid: CFA ${_formatNum(inv['paid_amount'])}', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.success)),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    status,
                                    style: GoogleFonts.inter(color: color, fontSize: 11, fontWeight: FontWeight.w600),
                                  ),
                                ),
                                if (outstanding > 0)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text('Owes: CFA ${_formatNum(inv['outstanding_debt'])}', style: GoogleFonts.inter(color: AppTheme.danger, fontSize: 12, fontWeight: FontWeight.w600)),
                                  ),
                                if (outstanding > 0)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.success,
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                        minimumSize: const Size(0, 30),
                                      ),
                                      onPressed: () {
                                        String amt = outstanding.toString();
                                        String method = 'Cash';
                                        String notes = 'Paid via App';
                                        showModalBottomSheet(
                                          context: context,
                                          isScrollControlled: true,
                                          backgroundColor: Colors.transparent,
                                          builder: (context) => StatefulBuilder(
                                            builder: (context, setState) {
                                              return Container(
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
                                                        Text('Pay Rent - CFA ${_formatNum(outstanding)}', style: GoogleFonts.outfit(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold)),
                                                        const SizedBox(height: 24),
                                                        TextField(
                                                          decoration: const InputDecoration(labelText: 'Amount to Pay', labelStyle: TextStyle(color: AppTheme.textSecondary)),
                                                          style: const TextStyle(color: Colors.white),
                                                          keyboardType: TextInputType.number,
                                                          onChanged: (v) => amt = v,
                                                          controller: TextEditingController(text: amt)..selection = TextSelection.collapsed(offset: amt.length),
                                                        ),
                                                        const SizedBox(height: 16),
                                                        DropdownButtonFormField<String>(
                                                          value: method,
                                                          dropdownColor: AppTheme.surface,
                                                          decoration: const InputDecoration(labelText: 'Payment Method', labelStyle: TextStyle(color: AppTheme.textSecondary)),
                                                          items: ['Cash', 'Bank Transfer', 'Mobile Money', 'Cheque'].map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(color: Colors.white)))).toList(),
                                                          onChanged: (v) {
                                                            if (v != null) setState(() => method = v);
                                                          },
                                                        ),
                                                        const SizedBox(height: 16),
                                                        TextField(
                                                          decoration: const InputDecoration(labelText: 'Notes', labelStyle: TextStyle(color: AppTheme.textSecondary)),
                                                          style: const TextStyle(color: Colors.white),
                                                          onChanged: (v) => notes = v,
                                                          controller: TextEditingController(text: notes)..selection = TextSelection.collapsed(offset: notes.length),
                                                        ),
                                                        const SizedBox(height: 24),
                                                        Row(
                                                          mainAxisAlignment: MainAxisAlignment.end,
                                                          children: [
                                                            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary))),
                                                            const SizedBox(width: 8),
                                                            ElevatedButton(
                                                              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
                                                              onPressed: () async {
                                                                Navigator.pop(context);
                                                                try {
                                                                  await ApiService().post('/rent/payment', data: {
                                                                    'invoice_id': inv['id'],
                                                                    'amount': amt,
                                                                    'payment_method': method,
                                                                    'notes': notes,
                                                                  });
                                                                  if (context.mounted) {
                                                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment processed successfully.')));
                                                                    ref.invalidate(tenantRentHistoryProvider(widget.tenantId));
                                                                  }
                                                                } catch (e) {
                                                                  if (context.mounted) {
                                                                    if (e.toString().contains('OFFLINE_QUEUED')) {
                                                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved offline and queued for sync ✓'), backgroundColor: Colors.amber));
                                                                      ref.invalidate(tenantRentHistoryProvider(widget.tenantId));
                                                                    } else {
                                                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to process payment: $e')));
                                                                    }
                                                                  }
                                                                }
                                                              },
                                                              child: const Text('Confirm Payment', style: TextStyle(color: Colors.white)),
                                                            ),
                                                          ],
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              );
                                            }
                                          ),
                                        );
                                      },
                                      child: Text('Pay', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTotalStat(String label, double amount, Color color) {
    return Column(
      children: [
        Text(label.toUpperCase(), style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textSecondary, letterSpacing: 1)),
        const SizedBox(height: 4),
        Text('CFA ${_formatNum(amount)}', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}

class _ElectricityTab extends ConsumerWidget {
  final String tenantId;
  const _ElectricityTab({required this.tenantId});

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
  Widget build(BuildContext context, WidgetRef ref) {
    final invoicesAsync = ref.watch(tenantElectricityInvoicesAdminProvider(tenantId));
    final subAsync = ref.watch(tenantElectricitySubscriptionProvider(tenantId));

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Active Electricity Plan Hero Card ──
          subAsync.when(
            loading: () => Container(
              height: 100,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: const Color(0xFF060B10),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary)),
            ),
            error: (_, __) => const SizedBox.shrink(),
            data: (sub) {
              if (sub == null || sub['status'] == 'None') {
                return Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF060B10),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.bolt_outlined, color: Colors.amber, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'No Active Electricity Plan',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Apartment has no active meter or subscription plan configured.',
                              style: GoogleFonts.inter(color: Colors.blueGrey.shade400, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }

              final isMeter = (sub['type'] ?? '').toString().toLowerCase().contains('meter');
              final status = sub['status']?.toString() ?? 'Active';
              final priceKwh = sub['price_per_kwh'] != null ? '${sub['price_per_kwh']} CFA / kWh' : '250 CFA / kWh';
              final monthlyFee = sub['monthly_fee'] != null ? 'CFA ${_formatNum(sub['monthly_fee'])}' : 'N/A';
              final lastReading = sub['last_meter_reading'] != null ? '${sub['last_meter_reading']} kWh' : '0.0 kWh';
              final nextDate = sub['next_billing_date']?.toString() ?? sub['end_date']?.toString() ?? 'Month End';

              return Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isMeter
                        ? [const Color(0xFF060B10), const Color(0xFF0D1620)]
                        : [const Color(0xFF060B10), const Color(0xFF072621)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isMeter ? Colors.amber.withValues(alpha: 0.4) : Colors.indigo.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (isMeter ? Colors.amber : Color(0xFF00D4AA)).withValues(alpha: 0.08),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Plan Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: (isMeter ? Colors.amber : Color(0xFF00D4AA)).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                isMeter ? Icons.speed : Icons.calendar_month,
                                color: isMeter ? Colors.amber : Color(0xFF00D4AA),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isMeter ? 'Meter Reading Plan' : 'Fixed Monthly Subscription',
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  isMeter ? 'Pay per actual kWh consumed' : 'Flat rate billed every cycle',
                                  style: GoogleFonts.inter(color: Colors.blueGrey.shade400, fontSize: 11),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            status.toUpperCase(),
                            style: const TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF030712).withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF0D1620)),
                      ),
                      child: Row(
                        children: [
                          if (isMeter) ...[
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('STARTING / BASELINE', style: GoogleFonts.inter(color: Colors.blueGrey.shade400, fontSize: 9, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 2),
                                  Text(lastReading, style: GoogleFonts.spaceMono(color: Colors.cyanAccent, fontSize: 13, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                            Container(width: 1, height: 26, color: const Color(0xFF1D3347)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('UNIT RATE', style: GoogleFonts.inter(color: Colors.blueGrey.shade400, fontSize: 9, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 2),
                                  Text(priceKwh, style: GoogleFonts.inter(color: Colors.amberAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ] else ...[
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('MONTHLY RATE', style: GoogleFonts.inter(color: Colors.blueGrey.shade400, fontSize: 9, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 2),
                                  Text(monthlyFee, style: GoogleFonts.outfit(color: Colors.amberAccent, fontSize: 15, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ],
                          Container(width: 1, height: 26, color: const Color(0xFF1D3347)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('NEXT CYCLE DUE', style: GoogleFonts.inter(color: Colors.blueGrey.shade400, fontSize: 9, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 2),
                                Text(nextDate, style: GoogleFonts.inter(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // ── Invoices Section Header ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Electricity Invoices',
                style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const Icon(Icons.receipt_long, color: Colors.blueGrey, size: 18),
            ],
          ),
          const SizedBox(height: 12),

          // ── Invoices List ──
          invoicesAsync.when(
            loading: () => const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator(color: AppTheme.primary))),
            error: (e, _) => Center(child: Text('Failed to load electricity invoices: $e', style: GoogleFonts.inter(color: AppTheme.danger))),
            data: (invoices) {
              if (invoices.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text('No electricity invoices recorded yet.', style: GoogleFonts.inter(color: Colors.blueGrey.shade400, fontSize: 13)),
                  ),
                );
              }

              return Column(
                children: invoices.map((invItem) {
                  final inv = invItem as Map<String, dynamic>;
                  final rawId = inv['id'];
                  final invNum = inv['invoice_number']?.toString() ?? 'Elec-$rawId';
                  final status = inv['status']?.toString() ?? 'Unpaid';
                  final statusLower = status.toLowerCase();
                  final isPaid = statusLower == 'paid';
                  final isPartial = statusLower == 'partial' || statusLower == 'partially paid';

                  final amount = double.tryParse(inv['amount']?.toString() ?? '0') ?? 0;
                  final paidAmount = double.tryParse(inv['paid_amount']?.toString() ?? (isPaid ? amount.toString() : '0')) ?? 0;
                  final debt = !isPaid ? (amount - paidAmount) : 0.0;

                  final dueDate = inv['due_date']?.toString() ?? '';
                  final building = inv['building_name']?.toString() ?? 'N/A';
                  final aptCode = inv['apartment_code']?.toString() ?? 'N/A';
                  final elecType = inv['type']?.toString() ?? 'Subscription';

                  String formattedDate = dueDate;
                  try { formattedDate = DateFormat('d MMM yyyy').format(DateTime.parse(dueDate)); } catch (_) {}

                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isPaid
                            ? AppTheme.success.withOpacity(0.2)
                            : (isPartial ? AppTheme.warning.withOpacity(0.3) : AppTheme.danger.withOpacity(0.3)),
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
                                color: (isPaid ? AppTheme.success : (isPartial ? AppTheme.warning : AppTheme.danger)).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                isPaid ? Icons.check_circle_rounded : Icons.bolt,
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
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(color: Colors.amber.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
                                        child: Text(elecType, style: const TextStyle(color: Colors.amber, fontSize: 9, fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ),
                                  Text('$building • Apt $aptCode', style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 12)),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: (isPaid ? AppTheme.success : (isPartial ? AppTheme.warning : AppTheme.danger)).withOpacity(0.2),
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

                        if (elecType == 'Meter' && inv['previous_reading'] != null) ...[
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
                        Divider(color: Colors.white.withOpacity(0.05), height: 1),
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
                                Text('Amount', style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 10)),
                                Text('CFA ${_formatNum(amount)}', style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('Balance Owed', style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 10)),
                                Text('CFA ${_formatNum(debt)}', style: GoogleFonts.outfit(color: debt > 0 ? AppTheme.danger : AppTheme.success, fontSize: 13, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _InsuranceTab extends ConsumerWidget {
  final String tenantId;
  const _InsuranceTab({required this.tenantId});

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
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(tenantInsuranceProvider(tenantId));

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      error: (e, _) => Center(child: Text('Failed to load insurance data: $e', style: GoogleFonts.inter(color: AppTheme.danger))),
      data: (insuranceAccounts) {
        if (insuranceAccounts.isEmpty) {
          return const _PlaceholderTab(title: 'Insurance & Deposit', message: 'No insurance/deposit was recorded for this tenant.');
        }

        return ListView.builder(
          padding: const EdgeInsets.only(top: 24),
          itemCount: insuranceAccounts.length,
          itemBuilder: (context, index) {
            final account = insuranceAccounts[index] as Map<String, dynamic>;
            final isActive = account['contract_status'] == 'Active' || account['contract_status'] == 'Approved';
            final isPaid = account['insurance_status'] == 'Paid';
            
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.surfaceHover),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF9C27B0).withOpacity(0.05),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      border: const Border(bottom: BorderSide(color: AppTheme.surfaceHover)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: const Color(0xFF9C27B0).withOpacity(0.15), shape: BoxShape.circle),
                          child: const Icon(Icons.shield_rounded, color: Color(0xFF9C27B0)),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text('${account['building_name']} — Apt ${account['apartment_code']}', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isActive ? AppTheme.success.withOpacity(0.15) : AppTheme.textSecondary.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      account['contract_status'] ?? 'Unknown',
                                      style: GoogleFonts.inter(color: isActive ? AppTheme.success : AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text('Contract: ${account['start_date']} to ${account['end_date']}', style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Body stats
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            Text('REQUIRED DEPOSIT', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textSecondary, letterSpacing: 1)),
                            const SizedBox(height: 8),
                            Text('CFA ${_formatNum(account['required_deposit'])}', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                          ],
                        ),
                        Container(width: 1, height: 40, color: AppTheme.surfaceHover),
                        Column(
                          children: [
                            Text('TOTAL SAVED', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textSecondary, letterSpacing: 1)),
                            const SizedBox(height: 8),
                            Text('CFA ${_formatNum(account['total_saved'])}', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFFCE93D8))),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: isPaid ? AppTheme.success.withOpacity(0.15) : AppTheme.warning.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                account['insurance_status'] ?? 'Pending Payment',
                                style: GoogleFonts.inter(color: isPaid ? AppTheme.success : AppTheme.warning, fontSize: 10, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (account['transactions'] != null && (account['transactions'] as List).isNotEmpty) ...[
                    const Divider(color: AppTheme.surfaceHover, height: 1),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('PAYMENT RECORD', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textSecondary, letterSpacing: 1)),
                          const SizedBox(height: 12),
                          ...(account['transactions'] as List).map((tx) {
                            final date = tx['date'] ?? 'N/A';
                            final amount = _formatNum(tx['amount']);
                            final type = tx['type'] ?? 'Unknown';
                            final color = type == 'Deposit' ? AppTheme.success : (type == 'Refund' ? AppTheme.warning : AppTheme.danger);
                            final icon = type == 'Deposit' ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded;
                            
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                                    child: Icon(icon, color: color, size: 14),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(type, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 13)),
                                        if (tx['notes'] != null && tx['notes'].toString().isNotEmpty)
                                          Text(tx['notes'], style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 11)),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text('CFA $amount', style: GoogleFonts.outfit(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
                                      Text(date, style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 11)),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
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
    );
  }
}
