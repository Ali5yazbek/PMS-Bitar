// ─── Workshop Screen ──────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../config/app_theme.dart';
import '../services/api_service.dart';

final workshopProvider = FutureProvider<List<dynamic>>((ref) async {
  final res = await ApiService().get('/workshop');
  return res.data as List<dynamic>;
});

class WorkshopScreen extends ConsumerWidget {
  const WorkshopScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(workshopProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {}, // Future: Add Order
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text('New Order', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: RefreshIndicator(
        color: AppTheme.primary,
        onRefresh: () async => ref.invalidate(workshopProvider),
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
          error: (e, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: AppTheme.danger, size: 48),
                const SizedBox(height: 16),
                Text('Failed to load workshop orders', style: GoogleFonts.inter(color: Colors.white)),
              ],
            ),
          ),
          data: (orders) {
            if (orders.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.build_rounded, size: 64, color: AppTheme.textSecondary.withOpacity(0.5)),
                    const SizedBox(height: 16),
                    Text('No workshop orders', style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 16)),
                  ],
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: orders.length,
              itemBuilder: (ctx, i) {
                final o = orders[i] as Map<String, dynamic>;
                return _WorkshopCard(order: o);
              },
            );
          },
        ),
      ),
    );
  }
}

class _WorkshopCard extends StatefulWidget {
  final Map<String, dynamic> order;
  const _WorkshopCard({required this.order});

  @override
  State<_WorkshopCard> createState() => _WorkshopCardState();
}

class _WorkshopCardState extends State<_WorkshopCard> {
  bool isHovered = false;

  Color _priorityColor(String? p) {
    switch (p) {
      case 'High': return AppTheme.danger;
      case 'Medium': return AppTheme.warning;
      default: return AppTheme.success;
    }
  }

  @override
  Widget build(BuildContext context) {
    final priority = widget.order['priority'] as String?;
    final status = widget.order['status'] as String? ?? 'Pending';
    final pColor = _priorityColor(priority);

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
            color: isHovered ? pColor.withOpacity(0.5) : AppTheme.surfaceHover,
            width: 1,
          ),
          boxShadow: isHovered
              ? [BoxShadow(color: pColor.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))]
              : [],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              context.go('/workshop/${widget.order['id']}');
            },
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: pColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.build_rounded, color: pColor, size: 28),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.order['title'] ?? widget.order['description'] ?? 'Order #${widget.order['id']}',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.door_front_door_outlined, size: 14, color: AppTheme.textSecondary),
                            const SizedBox(width: 6),
                            Text(
                              widget.order['apartment_code'] ?? 'General',
                              style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 13),
                            ),
                            const SizedBox(width: 12),
                            Icon(Icons.info_outline_rounded, size: 14, color: AppTheme.textSecondary),
                            const SizedBox(width: 6),
                            Text(
                              status,
                              style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 13),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (priority != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: pColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: pColor.withOpacity(0.3)),
                      ),
                      child: Text(
                        priority,
                        style: GoogleFonts.inter(
                          color: pColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
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
