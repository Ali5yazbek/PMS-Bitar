// ─── Tenants Screen ───────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../config/app_theme.dart';
import '../services/api_service.dart';

final tenantsProvider = FutureProvider<List<dynamic>>((ref) async {
  final res = await ApiService().get('/tenants');
  return res.data as List<dynamic>;
});

class TenantsScreen extends ConsumerStatefulWidget {
  final String? buildingId;
  const TenantsScreen({super.key, this.buildingId});
  @override
  ConsumerState<TenantsScreen> createState() => _TenantsScreenState();
}

class _TenantsScreenState extends ConsumerState<TenantsScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(tenantsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {}, // Future: Add Tenant
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.person_add_rounded, color: Colors.white),
        label: Text('Add Tenant', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: Column(
        children: [
          // Header / Search bar
          Container(
            padding: const EdgeInsets.all(24),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search tenants by name or phone...',
                prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textSecondary),
                filled: true,
                fillColor: AppTheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: AppTheme.primary.withOpacity(0.5), width: 1),
                ),
              ),
              style: GoogleFonts.inter(color: Colors.white),
              onChanged: (v) => setState(() => _search = v.toLowerCase()),
            ),
          ),

          Expanded(
            child: RefreshIndicator(
              color: AppTheme.primary,
              onRefresh: () async => ref.invalidate(tenantsProvider),
              child: async.when(
                loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
                error: (e, _) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: AppTheme.danger, size: 48),
                      const SizedBox(height: 16),
                      Text('Failed to load tenants', style: GoogleFonts.inter(color: Colors.white)),
                    ],
                  ),
                ),
                data: (tenants) {
                  final filtered = tenants.where((t) {
                    final m = t as Map<String, dynamic>;
                    
                    if (widget.buildingId != null && m['building_id']?.toString() != widget.buildingId) {
                      return false;
                    }
                    
                    return _search.isEmpty ||
                        (m['full_name'] ?? '').toString().toLowerCase().contains(_search) ||
                        (m['phone'] ?? '').toString().contains(_search);
                  }).toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_outline_rounded, size: 64, color: AppTheme.textSecondary.withOpacity(0.5)),
                          const SizedBox(height: 16),
                          Text('No tenants found', style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 16)),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) {
                      final t = filtered[i] as Map<String, dynamic>;
                      return _TenantCard(tenant: t);
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

class _TenantCard extends StatefulWidget {
  final Map<String, dynamic> tenant;
  const _TenantCard({required this.tenant});

  @override
  State<_TenantCard> createState() => _TenantCardState();
}

class _TenantCardState extends State<_TenantCard> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
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
            color: isHovered ? AppTheme.primary.withOpacity(0.5) : AppTheme.surfaceHover,
            width: 1,
          ),
          boxShadow: isHovered
              ? [BoxShadow(color: AppTheme.primary.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))]
              : [],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => context.push('/tenants/${widget.tenant['id']}'),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppTheme.primary.withOpacity(0.2),
                    child: Text(
                      (widget.tenant['full_name'] ?? 'T')[0].toUpperCase(),
                      style: GoogleFonts.outfit(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.tenant['full_name'] ?? '',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.phone_rounded, size: 14, color: AppTheme.textSecondary),
                            const SizedBox(width: 6),
                            Text(
                              widget.tenant['phone'] ?? 'No phone',
                              style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 13),
                            ),
                            if (widget.tenant['email'] != null && widget.tenant['email'].toString().isNotEmpty) ...[
                              const SizedBox(width: 12),
                              Icon(Icons.email_rounded, size: 14, color: AppTheme.textSecondary),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  widget.tenant['email'],
                                  style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
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
