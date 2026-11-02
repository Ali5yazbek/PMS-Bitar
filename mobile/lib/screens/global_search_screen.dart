import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../config/app_theme.dart';
import '../services/api_service.dart';

class GlobalSearchScreen extends StatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  State<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends State<GlobalSearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _allIndexedItems = [];
  bool _isLoading = true;
  String _query = '';
  String _selectedCategory = 'All'; // All, Tenant, Apartment, Building, Contract, Maintenance
  String _selectedBuilding = 'All Buildings';

  @override
  void initState() {
    super.initState();
    _loadSearchIndex();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSearchIndex() async {
    setState(() => _isLoading = true);
    try {
      final responses = await Future.wait([
        ApiService().get('/buildings').then<dynamic>((r) => r.data).catchError((_) => []),
        ApiService().get('/tenants').then<dynamic>((r) => r.data).catchError((_) => []),
        ApiService().get('/apartments').then<dynamic>((r) => r.data).catchError((_) => []),
        ApiService().get('/contracts').then<dynamic>((r) => r.data).catchError((_) => []),
        ApiService().get('/maintenance-tickets/all').then<dynamic>((r) => r.data).catchError((_) => []),
      ]);

      final List<Map<String, dynamic>> index = [];
      final Map<String, String> buildingIdToName = {};

      // 1. Buildings
      if (responses[0] is List) {
        for (final raw in (responses[0] as List)) {
          if (raw is! Map) continue;
          final id = raw['id']?.toString() ?? '';
          final name = (raw['name'] ?? 'Building').toString();
          final aptCount = raw['total_apartments'] ?? raw['apartment_count'] ?? 0;
          buildingIdToName[id] = name;

          index.add({
            'id': id,
            'type': 'Building',
            'title': name,
            'subtitle': '$aptCount Units • ${raw['location'] ?? 'Property'}',
            'badge': '$aptCount Apts',
            'building': name,
            'path': '/buildings/$id',
            'searchBlob': '$name ${raw['location'] ?? ''} building'.toLowerCase(),
          });
        }
      }

      // 2. Apartments
      if (responses[2] is List) {
        for (final raw in (responses[2] as List)) {
          if (raw is! Map) continue;
          final id = raw['id']?.toString() ?? '';
          final code = (raw['code'] ?? raw['apartment_number'] ?? '').toString();
          final bId = raw['building_id']?.toString() ?? '';
          final bldName = (raw['building_name'] ?? buildingIdToName[bId] ?? 'Building').toString();
          final status = (raw['status'] ?? 'Vacant').toString();
          final rent = double.tryParse((raw['monthly_rent'] ?? '0').toString()) ?? 0;
          final tenantName = (raw['tenant_name'] ?? '').toString();

          index.add({
            'id': id,
            'type': 'Apartment',
            'title': '$bldName • Apt $code',
            'subtitle':
                '${tenantName.isNotEmpty ? "Tenant: $tenantName • " : ""}Rent: CFA ${NumberFormat('#,##0').format(rent)}',
            'badge': status,
            'building': bldName,
            'path': bId.isNotEmpty ? '/buildings/$bId' : '/buildings',
            'searchBlob': '$bldName apt $code $status $tenantName $rent apartment'.toLowerCase(),
          });
        }
      }

      // 3. Tenants
      if (responses[1] is List) {
        for (final raw in (responses[1] as List)) {
          if (raw is! Map) continue;
          final id = raw['id']?.toString() ?? '';
          final name = (raw['full_name'] ?? raw['name'] ?? 'Tenant').toString();
          final phone = (raw['phone'] ?? '').toString();
          final email = (raw['email'] ?? '').toString();
          final apt = (raw['apartment_code'] ?? raw['apartment_number'] ?? '').toString();
          final bld = (raw['building_name'] ?? '').toString();

          index.add({
            'id': id,
            'type': 'Tenant',
            'title': name,
            'subtitle': [
              if (bld.isNotEmpty || apt.isNotEmpty) '$bld ${apt.isNotEmpty ? "Apt $apt" : ""}'.trim(),
              if (phone.isNotEmpty) 'Tel: $phone',
              if (email.isNotEmpty) email,
            ].join(' • '),
            'badge': apt.isNotEmpty ? 'Apt $apt' : 'Resident',
            'building': bld,
            'path': '/tenants/$id',
            'searchBlob': '$name $phone $email $bld $apt tenant'.toLowerCase(),
          });
        }
      }

      // 4. Contracts
      if (responses[3] is List) {
        for (final raw in (responses[3] as List)) {
          if (raw is! Map) continue;
          final id = raw['id']?.toString() ?? '';
          final tenant = (raw['tenant_name'] ?? raw['full_name'] ?? 'Tenant').toString();
          final apt = (raw['apartment_code'] ?? raw['apartment_number'] ?? '').toString();
          final bld = (raw['building_name'] ?? '').toString();
          final status = (raw['status'] ?? 'Active').toString();
          final endDate = (raw['end_date'] ?? '').toString();
          final rent = double.tryParse((raw['monthly_rent'] ?? '0').toString()) ?? 0;

          index.add({
            'id': id,
            'type': 'Contract',
            'title': '$tenant • $bld Apt $apt',
            'subtitle': 'CFA ${NumberFormat('#,##0').format(rent)}/mo • Ends: ${endDate.isEmpty ? "N/A" : endDate}',
            'badge': status,
            'building': bld,
            'path': '/contracts',
            'searchBlob': '$tenant $bld $apt $status $endDate contract'.toLowerCase(),
          });
        }
      }

      // 5. Maintenance Requests
      final maintList = responses[4] is List
          ? (responses[4] as List)
          : (responses[4] is Map && responses[4]['tickets'] is List
              ? responses[4]['tickets'] as List
              : const []);
      for (final raw in maintList) {
        if (raw is! Map) continue;
        final id = raw['id']?.toString() ?? '';
        final title = (raw['title'] ?? raw['category'] ?? 'Maintenance').toString();
        final bld = (raw['building_name'] ?? '').toString();
        final apt = (raw['apartment_code'] ?? raw['apartment_number'] ?? '').toString();
        final status = (raw['status'] ?? 'Open').toString();
        final tenant = (raw['tenant_name'] ?? '').toString();

        index.add({
          'id': id,
          'type': 'Maintenance',
          'title': '$title ($bld Apt $apt)',
          'subtitle': '${tenant.isNotEmpty ? "Reported by $tenant • " : ""}${raw['description'] ?? ''}',
          'badge': status,
          'building': bld,
          'path': '/ac-maintenance',
          'searchBlob': '$title $bld $apt $status $tenant ${raw['description'] ?? ''} maintenance'.toLowerCase(),
        });
      }

      if (mounted) {
        setState(() {
          _allIndexedItems = index;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredResults {
    return _allIndexedItems.where((item) {
      if (_selectedCategory != 'All' && item['type'] != _selectedCategory) {
        return false;
      }
      if (_selectedBuilding != 'All Buildings') {
        if ((item['building'] ?? '').toString().toLowerCase() !=
            _selectedBuilding.toLowerCase()) {
          return false;
        }
      }
      if (_query.isNotEmpty) {
        final tokens = _query.toLowerCase().split(RegExp(r'\s+')).where((t) => t.isNotEmpty);
        final blob = (item['searchBlob'] ?? '').toString();
        for (final token in tokens) {
          if (!blob.contains(token)) return false;
        }
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final buildingsSet = <String>{'All Buildings'};
    for (final item in _allIndexedItems) {
      final b = (item['building'] ?? '').toString().trim();
      if (b.isNotEmpty) buildingsSet.add(b);
    }
    final buildingList = buildingsSet.toList();
    if (!buildingList.contains(_selectedBuilding)) {
      _selectedBuilding = 'All Buildings';
    }

    final results = _filteredResults;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: AmbientLuxuryBackground(
        child: SafeArea(
          child: Column(
            children: [
              // ── Top Search & Filter Header ────────────────────────────────
              Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                padding: const EdgeInsets.all(14),
                decoration: AppTheme.glassCardDecoration(borderRadius: 22),
                child: Column(
                  children: [
                    Row(
                      children: [
                        InkWell(
                          onTap: () => context.pop(),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceHover,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.border),
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              size: 16,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: SizedBox(
                            height: 44,
                            child: TextField(
                              controller: _searchController,
                              autofocus: true,
                              onChanged: (v) => setState(() => _query = v.trim()),
                              style: GoogleFonts.plusJakartaSans(
                                color: AppTheme.textPrimary,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Search tenants, apartments, buildings, contracts...',
                                hintStyle: GoogleFonts.plusJakartaSans(
                                  color: AppTheme.textMuted,
                                  fontSize: 12.5,
                                ),
                                prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primary, size: 19),
                                suffixIcon: _query.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.close_rounded, size: 17, color: AppTheme.textSecondary),
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(() => _query = '');
                                        },
                                      )
                                    : null,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                                filled: true,
                                fillColor: AppTheme.background,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(color: AppTheme.primary),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(color: AppTheme.border),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Category + Building Filter Bar
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          // Building Dropdown
                          Container(
                            height: 32,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: _selectedBuilding != 'All Buildings'
                                  ? AppTheme.accent.withValues(alpha: 0.16)
                                  : AppTheme.background,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _selectedBuilding != 'All Buildings'
                                    ? AppTheme.accent
                                    : AppTheme.border,
                              ),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedBuilding,
                                dropdownColor: AppTheme.surface,
                                icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: AppTheme.accent),
                                style: GoogleFonts.plusJakartaSans(
                                  color: AppTheme.textPrimary,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                ),
                                items: buildingList
                                    .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                                    .toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => _selectedBuilding = val);
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),

                          for (final cat in [
                            ('All', 'All (${_allIndexedItems.length})'),
                            ('Tenant', 'Tenants'),
                            ('Apartment', 'Apartments'),
                            ('Building', 'Buildings'),
                            ('Contract', 'Contracts'),
                            ('Maintenance', 'Maintenance'),
                          ]) ...[
                            GestureDetector(
                              onTap: () => setState(() => _selectedCategory = cat.$1),
                              child: Container(
                                height: 32,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  gradient: _selectedCategory == cat.$1 ? AppTheme.primaryGradient : null,
                                  color: _selectedCategory == cat.$1 ? null : AppTheme.background,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: _selectedCategory == cat.$1 ? AppTheme.primary : AppTheme.border,
                                  ),
                                ),
                                child: Text(
                                  cat.$2,
                                  style: GoogleFonts.plusJakartaSans(
                                    color: _selectedCategory == cat.$1
                                        ? const Color(0xFF04130F)
                                        : AppTheme.textSecondary,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── Results List ──────────────────────────────────────────────
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                    : results.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.search_off_rounded, size: 48, color: AppTheme.textMuted),
                                const SizedBox(height: 12),
                                Text(
                                  'No matching records found',
                                  style: GoogleFonts.outfit(
                                    color: AppTheme.textPrimary,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Try a different keyword or reset the filters above.',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: AppTheme.textSecondary,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                            itemCount: results.length,
                            itemBuilder: (context, index) {
                              final item = results[index];
                              final type = (item['type'] ?? '').toString();
                              final accent = _getColorForType(type);

                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                decoration: AppTheme.glassCardDecoration(borderRadius: 18),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                  leading: Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: accent.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: accent.withValues(alpha: 0.35)),
                                    ),
                                    child: Icon(_getIconForType(type), color: accent, size: 20),
                                  ),
                                  title: Text(
                                    item['title'] ?? '',
                                    style: GoogleFonts.outfit(
                                      color: AppTheme.textPrimary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14.5,
                                    ),
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 3),
                                    child: Text(
                                      item['subtitle'] ?? type,
                                      style: GoogleFonts.plusJakartaSans(
                                        color: AppTheme.textSecondary,
                                        fontSize: 12,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  trailing: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: accent.withValues(alpha: 0.14),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: accent.withValues(alpha: 0.35)),
                                    ),
                                    child: Text(
                                      (item['badge'] ?? type).toString().toUpperCase(),
                                      style: GoogleFonts.plusJakartaSans(
                                        color: accent,
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  onTap: () {
                                    final path = item['path']?.toString();
                                    if (path != null && path.isNotEmpty) {
                                      context.push(path);
                                    }
                                  },
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'Tenant':
        return Icons.person_rounded;
      case 'Apartment':
        return Icons.meeting_room_rounded;
      case 'Building':
        return Icons.apartment_rounded;
      case 'Contract':
        return Icons.description_rounded;
      case 'Maintenance':
        return Icons.engineering_rounded;
      default:
        return Icons.search_rounded;
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'Tenant':
        return AppTheme.primary;
      case 'Apartment':
        return const Color(0xFF38BDF8);
      case 'Building':
        return AppTheme.accent;
      case 'Contract':
        return const Color(0xFFA78BFA);
      case 'Maintenance':
        return AppTheme.danger;
      default:
        return AppTheme.primary;
    }
  }
}
