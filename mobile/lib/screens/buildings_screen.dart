// ─── Buildings Screen (Luxury Obsidian & Royal Teal/Gold) ────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_theme.dart';
import '../services/api_service.dart';

final buildingsProvider = FutureProvider<List<dynamic>>((ref) async {
  final res = await ApiService().get('/buildings');
  return res.data as List<dynamic>;
});

class BuildingsScreen extends ConsumerWidget {
  const BuildingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(buildingsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        backgroundColor: AppTheme.primary,
        foregroundColor: const Color(0xFF04130F),
        icon: const Icon(Icons.add_rounded),
        label: Text(
          'Add Building',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w800),
        ),
      ),
      body: RefreshIndicator(
        color: AppTheme.primary,
        backgroundColor: AppTheme.surface,
        onRefresh: () async => ref.invalidate(buildingsProvider),
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
          error: (e, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded, color: AppTheme.danger, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Failed to load buildings',
                  style: GoogleFonts.outfit(color: AppTheme.textPrimary, fontSize: 16),
                ),
              ],
            ),
          ),
          data: (buildings) {
            if (buildings.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.apartment_rounded,
                      size: 64,
                      color: AppTheme.textSecondary.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No buildings yet',
                      style: GoogleFonts.outfit(color: AppTheme.textSecondary, fontSize: 16),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              itemCount: buildings.length,
              itemBuilder: (ctx, i) {
                final b = buildings[i] as Map<String, dynamic>;
                return _BuildingCard(building: b);
              },
            );
          },
        ),
      ),
    );
  }
}

class _BuildingCard extends StatefulWidget {
  final Map<String, dynamic> building;
  const _BuildingCard({required this.building});

  @override
  State<_BuildingCard> createState() => _BuildingCardState();
}

class _BuildingCardState extends State<_BuildingCard> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width <= 600;

    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          gradient: AppTheme.obsidianCardGradient,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isHovered
                ? AppTheme.primary.withValues(alpha: 0.6)
                : AppTheme.border,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isHovered
                  ? AppTheme.primary.withValues(alpha: 0.14)
                  : Colors.black.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              context.go('/buildings/${widget.building['id']}');
            },
            child: Padding(
              padding: EdgeInsets.all(isMobile ? 16 : 20),
              child: Row(
                children: [
                  Container(
                    width: isMobile ? 52 : 58,
                    height: isMobile ? 52 : 58,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primary.withValues(alpha: 0.2),
                          AppTheme.accent.withValues(alpha: 0.15),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: AppTheme.primary.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Icon(
                      Icons.apartment_rounded,
                      color: AppTheme.primary,
                      size: isMobile ? 25 : 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.building['name'] ?? '',
                          style: GoogleFonts.outfit(
                            fontSize: isMobile ? 17 : 19,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppTheme.accent.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppTheme.accent.withValues(alpha: 0.35),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.door_front_door_outlined,
                                    size: 13,
                                    color: AppTheme.accent,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    '${widget.building['total_apartments'] ?? widget.building['apartment_count'] ?? 0} Units',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: AppTheme.accent,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceHover,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: isHovered ? AppTheme.primary : AppTheme.textSecondary,
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
