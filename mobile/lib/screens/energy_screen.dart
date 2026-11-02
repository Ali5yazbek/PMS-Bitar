// ─── Energy Screen ────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_theme.dart';
import '../services/api_service.dart';

final energyGeneratorsProvider = FutureProvider<List<dynamic>>((ref) async {
  final res = await ApiService().get('/energy/generators');
  return res.data as List<dynamic>;
});

final energyDashboardProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final res = await ApiService().get('/energy/dashboard');
  return res.data as Map<String, dynamic>;
});

class EnergyScreen extends ConsumerWidget {
  const EnergyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final genAsync = ref.watch(energyGeneratorsProvider);
    final dashAsync = ref.watch(energyDashboardProvider);
    final isMobile = MediaQuery.of(context).size.width <= 600;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        color: AppTheme.primary,
        onRefresh: () async {
          ref.invalidate(energyGeneratorsProvider);
          ref.invalidate(energyDashboardProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dashboard summary
              dashAsync.when(
                loading: () => const SizedBox(),
                error: (_, __) => const SizedBox(),
                data: (stats) => GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.8,
                  children: [
                    _StatCard(
                      title: 'Generators',
                      value: '${stats['total_generators'] ?? 0}',
                      icon: Icons.electric_bolt_rounded,
                      color: AppTheme.warning,
                    ),
                    _StatCard(
                      title: 'Active',
                      value: '${stats['active_generators'] ?? 0}',
                      icon: Icons.check_circle_rounded,
                      color: AppTheme.success,
                    ),
                    _StatCard(
                      title: 'Subscriptions',
                      value: '${stats['total_subscriptions'] ?? stats['active_subscriptions'] ?? 0}',
                      icon: Icons.receipt_outlined,
                      color: AppTheme.info,
                    ),
                    _StatCard(
                      title: 'Fuel Alerts',
                      value: '${stats['fuel_alerts'] ?? stats['alerts_count'] ?? 0}',
                      icon: Icons.warning_rounded,
                      color: AppTheme.danger,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              Text('Generators', style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
              const SizedBox(height: 12),

              // Generator list
              genAsync.when(
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
                      Text('Failed to load generators', style: GoogleFonts.inter(color: Colors.white)),
                      const Spacer(),
                      TextButton(child: const Text('Retry'), onPressed: () => ref.invalidate(energyGeneratorsProvider)),
                    ],
                  ),
                ),
                data: (generators) {
                  if (generators.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text('No generators found', style: GoogleFonts.inter(color: AppTheme.textSecondary)),
                      ),
                    );
                  }
                  return Column(
                    children: generators.map((g) => _GeneratorCard(generator: g as Map<String, dynamic>)).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  const _StatCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.surfaceHover),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 8),
          Text(value, style: GoogleFonts.outfit(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
          Text(title, style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }
}

class _GeneratorCard extends StatelessWidget {
  final Map<String, dynamic> generator;
  const _GeneratorCard({required this.generator});

  @override
  Widget build(BuildContext context) {
    final status = generator['status']?.toString() ?? 'offline';
    final isOnline = status == 'online' || status == 'active';
    final statusColor = isOnline ? AppTheme.success : AppTheme.danger;
    final fuelLevel = generator['current_fuel_level'] ?? generator['fuel_level'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.surfaceHover),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.electric_bolt_rounded, color: statusColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      generator['name']?.toString() ?? 'Generator',
                      style: GoogleFonts.outfit(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    if (generator['location'] != null)
                      Text(generator['location'].toString(), style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 6, height: 6, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text(isOnline ? 'Online' : 'Offline', style: GoogleFonts.inter(color: statusColor, fontSize: 11, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Fuel level bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Fuel Level', style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 12)),
                  Text('${fuelLevel}L', style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _fuelPercent(fuelLevel, generator['tank_capacity']),
                  backgroundColor: AppTheme.surfaceHover,
                  valueColor: AlwaysStoppedAnimation<Color>(_fuelColor(fuelLevel, generator['tank_capacity'])),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  double _fuelPercent(dynamic level, dynamic capacity) {
    final l = double.tryParse(level.toString()) ?? 0.0;
    final c = double.tryParse(capacity?.toString() ?? '1') ?? 1.0;
    if (c == 0) return 0;
    return (l / c).clamp(0.0, 1.0);
  }

  Color _fuelColor(dynamic level, dynamic capacity) {
    final p = _fuelPercent(level, capacity);
    if (p > 0.5) return AppTheme.success;
    if (p > 0.25) return AppTheme.warning;
    return AppTheme.danger;
  }
}
