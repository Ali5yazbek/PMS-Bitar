// ─── Building Details Screen ───────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../config/app_theme.dart';
import '../services/api_service.dart';

final buildingDetailsProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, id) async {
  final buildingRes = await ApiService().get('/buildings/$id');
  final aptRes = await ApiService().get('/apartments?building=$id');
  
  return {
    'buildingData': buildingRes.data,
    'apartments': aptRes.data,
  };
});

class BuildingDetailsScreen extends ConsumerWidget {
  final String id;
  const BuildingDetailsScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(buildingDetailsProvider(id));

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
              Text('Failed to load building details', style: GoogleFonts.inter(color: Colors.white)),
              TextButton(
                onPressed: () => ref.invalidate(buildingDetailsProvider(id)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (data) {
          final buildingData = data['buildingData'] ?? {};
          final building = buildingData['building'] ?? {};
          final expenses = buildingData['expenses'] as List<dynamic>? ?? [];
          final apartments = data['apartments'] as List<dynamic>? ?? [];
          
          return _BuildingDetailsContent(
            building: building,
            expenses: expenses,
            apartments: apartments,
          );
        },
      ),
    );
  }
}

class _BuildingDetailsContent extends StatelessWidget {
  final Map<String, dynamic> building;
  final List<dynamic> expenses;
  final List<dynamic> apartments;

  const _BuildingDetailsContent({
    required this.building,
    required this.expenses,
    required this.apartments,
  });

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
    double totalSpent = 0;
    for (var e in expenses) {
      totalSpent += double.tryParse(e['amount']?.toString() ?? '0') ?? 0;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
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
                child: const Icon(Icons.apartment_rounded, color: AppTheme.primary, size: 32),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      building['name'] ?? 'Building Details',
                      style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                    Text(
                      '${apartments.length} Apartments | Total Expenses: CFA ${_formatNum(totalSpent)}',
                      style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          
          // Action Cards
          GridView.count(
            crossAxisCount: MediaQuery.of(context).size.width > 800 ? 4 : MediaQuery.of(context).size.width > 600 ? 2 : 1,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 2.5,
            children: [
              _ActionCard(
                title: 'Apartments',
                subtitle: 'Manage units',
                icon: Icons.door_front_door_rounded,
                color: AppTheme.info,
                onTap: () {}, // Future implementation
              ),
              _ActionCard(
                title: 'Tenants',
                subtitle: 'Manage residents',
                icon: Icons.people_alt_rounded,
                color: AppTheme.warning,
                onTap: () {},
              ),
              _ActionCard(
                title: 'Rent',
                subtitle: 'Track payments',
                icon: Icons.attach_money_rounded,
                color: AppTheme.success,
                onTap: () {},
              ),
              _ActionCard(
                title: 'Insurance',
                subtitle: 'Deposits & deductions',
                icon: Icons.shield_rounded,
                color: AppTheme.accent,
                onTap: () {},
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Ledger section
          Text('Cost History (Ledger)', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.white)),
          const SizedBox(height: 16),
          
          if (expenses.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Text('No expenses recorded for this building.', style: GoogleFonts.inter(color: AppTheme.textSecondary)),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: expenses.length,
              itemBuilder: (ctx, i) {
                final exp = expenses[i] as Map<String, dynamic>;
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
                          color: AppTheme.danger.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.money_off_rounded, color: AppTheme.danger, size: 20),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(exp['target_name'] ?? 'Building Wide', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white)),
                            Text('${exp['category']} • ${exp['date']}', style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 12)),
                          ],
                        ),
                      ),
                      Text('CFA ${_formatNum(exp['amount'])}', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: AppTheme.danger, fontSize: 16)),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({required this.title, required this.subtitle, required this.icon, required this.color, required this.onTap});

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
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isHovered ? widget.color.withOpacity(0.5) : AppTheme.surfaceHover,
            width: 1,
          ),
          boxShadow: isHovered
              ? [BoxShadow(color: widget.color.withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 4))]
              : [],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: widget.onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: widget.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(widget.icon, color: widget.color, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(widget.title, style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 16)),
                        Text(widget.subtitle, style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 12)),
                      ],
                    ),
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
