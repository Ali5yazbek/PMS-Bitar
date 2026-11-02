// ─── Apartments Screen ────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_theme.dart';
import '../services/api_service.dart';

final apartmentsProvider = FutureProvider<List<dynamic>>((ref) async {
  final res = await ApiService().get('/apartments');
  return res.data as List<dynamic>;
});

class ApartmentsScreen extends ConsumerStatefulWidget {
  final String? buildingId;
  const ApartmentsScreen({super.key, this.buildingId});
  @override
  ConsumerState<ApartmentsScreen> createState() => _ApartmentsScreenState();
}

class _ApartmentsScreenState extends ConsumerState<ApartmentsScreen> {
  String _search = '';
  String _filterStatus = 'all'; // all, occupied, vacant

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(apartmentsProvider);
    final isMobile = MediaQuery.of(context).size.width <= 600;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // Search + Filter Header
          Container(
            padding: EdgeInsets.fromLTRB(isMobile ? 16 : 24, 8, isMobile ? 16 : 24, 8),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search by apartment or building...',
                    prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textSecondary),
                    filled: true,
                    fillColor: AppTheme.surface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppTheme.primary)),
                  ),
                  style: GoogleFonts.inter(color: Colors.white),
                  onChanged: (v) => setState(() => _search = v.toLowerCase()),
                ),
                const SizedBox(height: 12),
                // Status filter chips
                Row(
                  children: [
                    _FilterChip(label: 'All', value: 'all', selected: _filterStatus == 'all', onTap: () => setState(() => _filterStatus = 'all')),
                    const SizedBox(width: 8),
                    _FilterChip(label: 'Occupied', value: 'occupied', selected: _filterStatus == 'occupied', onTap: () => setState(() => _filterStatus = 'occupied'), color: AppTheme.success),
                    const SizedBox(width: 8),
                    _FilterChip(label: 'Vacant', value: 'vacant', selected: _filterStatus == 'vacant', onTap: () => setState(() => _filterStatus = 'vacant'), color: AppTheme.warning),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: RefreshIndicator(
              color: AppTheme.primary,
              onRefresh: () async => ref.invalidate(apartmentsProvider),
              child: async.when(
                loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
                error: (e, _) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: AppTheme.danger, size: 48),
                      const SizedBox(height: 16),
                      Text('Failed to load apartments', style: GoogleFonts.inter(color: Colors.white)),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                        onPressed: () => ref.invalidate(apartmentsProvider),
                      ),
                    ],
                  ),
                ),
                data: (apartments) {
                  final filtered = apartments.where((a) {
                    final m = a as Map<String, dynamic>;
                    
                    if (widget.buildingId != null && m['building_id']?.toString() != widget.buildingId) {
                      return false;
                    }
                    
                    final matchSearch = _search.isEmpty ||
                        (m['apartment_number'] ?? '').toString().toLowerCase().contains(_search) ||
                        (m['building_name'] ?? '').toString().toLowerCase().contains(_search);
                    final matchStatus = _filterStatus == 'all' || (m['status'] ?? '') == _filterStatus;
                    return matchSearch && matchStatus;
                  }).toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.meeting_room_outlined, size: 64, color: AppTheme.textSecondary.withValues(alpha: 0.4)),
                          const SizedBox(height: 16),
                          Text('No apartments found', style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 16)),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24, vertical: 8),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) {
                      final apt = filtered[i] as Map<String, dynamic>;
                      return _ApartmentCard(apartment: apt);
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final String value;
  final bool selected;
  final VoidCallback onTap;
  final Color color;

  const _FilterChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
    this.color = AppTheme.primary,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.2) : AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? color : AppTheme.surfaceHover),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: selected ? color : AppTheme.textSecondary,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _ApartmentCard extends StatefulWidget {
  final Map<String, dynamic> apartment;
  const _ApartmentCard({required this.apartment});

  @override
  State<_ApartmentCard> createState() => _ApartmentCardState();
}

class _ApartmentCardState extends State<_ApartmentCard> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    final status = widget.apartment['status']?.toString() ?? 'vacant';
    final isOccupied = status == 'occupied';
    final statusColor = isOccupied ? AppTheme.success : AppTheme.warning;

    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isHovered ? AppTheme.surfaceHover : AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isHovered ? AppTheme.primary.withValues(alpha: 0.4) : AppTheme.surfaceHover,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {},
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Icon + status indicator
                  Stack(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.meeting_room_outlined, color: AppTheme.primary, size: 26),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppTheme.surface, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Apt ${widget.apartment['apartment_number'] ?? widget.apartment['number'] ?? ''}',
                              style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                isOccupied ? 'Occupied' : 'Vacant',
                                style: GoogleFonts.inter(color: statusColor, fontSize: 11, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.apartment_outlined, size: 13, color: AppTheme.textSecondary),
                            const SizedBox(width: 4),
                            Text(
                              widget.apartment['building_name']?.toString() ?? 'N/A',
                              style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 12),
                            ),
                            const SizedBox(width: 12),
                            Icon(Icons.layers_outlined, size: 13, color: AppTheme.textSecondary),
                            const SizedBox(width: 4),
                            Text(
                              'Floor ${widget.apartment['floor'] ?? '?'}',
                              style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 12),
                            ),
                          ],
                        ),
                        if (isOccupied && (widget.apartment['current_tenant'] ?? widget.apartment['tenant_name']) != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.person_outline, size: 13, color: AppTheme.info),
                              const SizedBox(width: 4),
                              Text(
                                widget.apartment['current_tenant']?.toString() ?? widget.apartment['tenant_name']?.toString() ?? '',
                                style: GoogleFonts.inter(color: AppTheme.info, fontSize: 12, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ],
                      ],
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
