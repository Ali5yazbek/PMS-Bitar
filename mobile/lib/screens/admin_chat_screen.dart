import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../config/app_theme.dart';
import '../services/api_service.dart';

class AdminChatScreen extends ConsumerStatefulWidget {
  const AdminChatScreen({super.key});

  @override
  ConsumerState<AdminChatScreen> createState() => _AdminChatScreenState();
}

class _AdminChatScreenState extends ConsumerState<AdminChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = false;
  bool _toolBusy = false;
  bool _dbSynced = false;
  Map<String, dynamic> _memoryContext = {};

  // Live Full-Database Knowledge Graph in memory
  Map<String, dynamic> _financialSummary = {};
  List<dynamic> _alerts = [];
  List<dynamic> _buildings = [];
  List<dynamic> _apartments = [];
  List<dynamic> _aptFinancials = [];
  List<dynamic> _tenants = [];
  List<dynamic> _contracts = [];
  List<dynamic> _tenantTickets = [];
  List<dynamic> _acTasks = [];
  List<dynamic> _purchases = [];
  List<dynamic> _generators = [];
  List<dynamic> _subscriptions = [];
  List<dynamic> _users = [];
  List<dynamic> _suppliers = [];

  final List<Map<String, dynamic>> _messages = [
    {
      'isMe': false,
      'text':
          'Hello! I am **Agency AI** — your autonomous cross-platform executive intelligence & action engine.\n\n'
          'I am connected live to every building, apartment, tenant, contract, payment, maintenance ticket, generator, and purchase, and I can also **execute authorized approvals** and **run live diagnostics** (in English, Français, or العربية):\n'
          '• 💡 **"Proactive insights"** (Anomalies & Priorities)\n'
          '• 🩺 **"Run system diagnostics"** (Live Health Check)\n'
          '• 🛒 **"Show pending purchases"** (Approve / Reject in Chat)\n'
          '• 💰 **"How much rent did we collect and what is unpaid?"**\n'
          '• 👤 **"Tell me everything about [Tenant Name]"**\n'
          '• 🏠 **"Which apartments are vacant right now?"**',
      'type': 'text',
    }
  ];

  final List<String> _suggestions = const [
    'Proactive insights',
    'Run system diagnostics',
    'Pending purchases',
    'Full agency summary',
    'How much rent is unpaid?',
    'Vacant apartments',
    'Open maintenance issues',
    'Expiring contracts',
    'Generator & energy status',
  ];

  @override
  void initState() {
    super.initState();
    _loadSyncedHistory();
    _syncDatabaseKnowledgeGraph();
  }

  Future<void> _loadSyncedHistory() async {
    try {
      final res = await ApiService().get('/ai/history');
      if (!mounted || res.data is! Map) return;
      final data = Map<String, dynamic>.from(res.data as Map);
      if (data['context'] is Map) {
        _memoryContext = Map<String, dynamic>.from(data['context'] as Map);
      }
      if (data['messages'] is List && (data['messages'] as List).isNotEmpty) {
        final synced = <Map<String, dynamic>>[];
        for (final raw in data['messages'] as List) {
          if (raw is! Map) continue;
          synced.add({
            'isMe': raw['role'] == 'user',
            'text': (raw['text'] ?? '').toString(),
            'type': (raw['type'] ?? 'text').toString(),
            'data': raw['data'],
            'actions': raw['actions'],
            'requires_confirmation': raw['requires_confirmation'] == true,
            'pending_tool': raw['pending_tool'],
          });
        }
        if (synced.isNotEmpty) {
          setState(() {
            _messages
              ..clear()
              ..addAll(synced);
          });
          _scrollToBottom();
        }
      }
    } catch (_) {}
  }

  Future<void> _clearConversationHistory() async {
    try {
      await ApiService().post('/ai/clear');
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _memoryContext = {};
      _messages
        ..clear()
        ..add({
          'isMe': false,
          'text': '🔄 **Conversation Memory Reset.** Ready for new questions or autonomous commands.',
          'type': 'text',
        });
    });
  }

  Future<void> _executeBackendTool(String toolName, dynamic targetId, Map<String, dynamic> params) async {
    if (_toolBusy) return;
    setState(() => _toolBusy = true);
    try {
      final res = await ApiService().post('/ai/execute-tool', data: {
        'tool_name': toolName,
        'target_id': targetId,
        'parameters': params,
      });
      if (!mounted) return;
      final out = res.data is Map ? Map<String, dynamic>.from(res.data as Map) : <String, dynamic>{};
      setState(() {
        _messages.add({
          'isMe': false,
          'text': (out['reply'] ?? '✅ Action executed successfully.').toString(),
          'type': (out['type'] ?? 'text').toString(),
          'data': out['data'],
        });
      });
      _scrollToBottom();
      ApiService().clearCache();
      _syncDatabaseKnowledgeGraph();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add({
          'isMe': false,
          'text': '❌ **Tool Execution Error:** $e',
          'type': 'text',
        });
      });
      _scrollToBottom();
    } finally {
      if (mounted) setState(() => _toolBusy = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _syncDatabaseKnowledgeGraph() async {
    try {
      final res = await Future.wait([
        ApiService().get('/dashboard/financial-summary').then<dynamic>((r) => r.data).catchError((_) => <String, dynamic>{}),
        ApiService().get('/dashboard/alerts').then<dynamic>((r) => r.data).catchError((_) => <String, dynamic>{}),
        ApiService().get('/buildings').then<dynamic>((r) => r.data).catchError((_) => []),
        ApiService().get('/apartments').then<dynamic>((r) => r.data).catchError((_) => []),
        ApiService().get('/tenants').then<dynamic>((r) => r.data).catchError((_) => []),
        ApiService().get('/contracts').then<dynamic>((r) => r.data).catchError((_) => []),
        ApiService().get('/maintenance-tickets/all').then<dynamic>((r) => r.data).catchError((_) => []),
        ApiService().get('/maintenance/admin/tasks').then<dynamic>((r) => r.data).catchError((_) => []),
        ApiService()
            .get('/apartment-costs/report', queryParameters: {'start_date': '2020-01-01', 'end_date': '2030-12-31'})
            .then<dynamic>((r) => r.data)
            .catchError((_) => []),
        ApiService().get('/energy/generators').then<dynamic>((r) => r.data).catchError((_) => []),
        ApiService().get('/agent-purchases?all=1').then<dynamic>((r) => r.data).catchError((_) => []),
        ApiService().get('/apartments/financials').then<dynamic>((r) => r.data).catchError((_) => []),
        ApiService().get('/users').then<dynamic>((r) => r.data).catchError((_) => []),
        ApiService().get('/suppliers').then<dynamic>((r) => r.data).catchError((_) => []),
        ApiService().get('/electricity/subscriptions').then<dynamic>((r) => r.data).catchError((_) => []),
        ApiService().get('/energy/agent/apartment-purchases/pending').then<dynamic>((r) => r.data).catchError((_) => []),
        ApiService().get('/energy/agent/apartment-purchases').then<dynamic>((r) => r.data).catchError((_) => <String, dynamic>{}),
      ]);

      if (!mounted) return;
      setState(() {
        _financialSummary = (res[0] is Map) ? Map<String, dynamic>.from(res[0]) : {};
        _alerts = (res[1] is Map && res[1]['alerts'] is List) ? res[1]['alerts'] as List : [];
        _buildings = (res[2] is List) ? res[2] as List : [];
        _apartments = (res[3] is List) ? res[3] as List : [];
        _tenants = (res[4] is List) ? res[4] as List : [];
        _contracts = (res[5] is List) ? res[5] as List : [];
        _tenantTickets = (res[6] is List)
            ? res[6] as List
            : (res[6] is Map && res[6]['tickets'] is List ? res[6]['tickets'] as List : []);
        _acTasks = (res[7] is List)
            ? res[7] as List
            : (res[7] is Map && res[7]['tasks'] is List ? res[7]['tasks'] as List : []);
        final costReport = (res[8] is List) ? res[8] as List : [];
        final agentPurch = (res[10] is List) ? res[10] as List : [];
        final pendingAptPurch = (res[15] is List) ? res[15] as List : [];
        final histAptPurch = (res[16] is Map && res[16]['history'] is List) ? res[16]['history'] as List : [];
        _purchases = [...agentPurch, ...pendingAptPurch, ...histAptPurch, ...costReport];
        _generators = (res[9] is List) ? res[9] as List : [];
        _aptFinancials = (res[11] is List) ? res[11] as List : [];
        _users = (res[12] is List) ? res[12] as List : [];
        _suppliers = (res[13] is List) ? res[13] as List : [];
        _subscriptions = (res[14] is List) ? res[14] as List : [];
        _dbSynced = true;
      });
    } catch (_) {}
  }

  String _nonEmpty(dynamic val, String fallback) {
    if (val == null) return fallback;
    final s = val.toString().trim();
    return s.isNotEmpty ? s : fallback;
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 120), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  double _parseNum(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString().replaceAll(RegExp(r'[^0-9.-]'), '')) ?? 0;
  }

  Future<void> _sendMessage({String? customText}) async {
    final text = (customText ?? _controller.text).trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({'isMe': true, 'text': text, 'type': 'text'});
      _isLoading = true;
    });
    if (customText == null) _controller.clear();
    _scrollToBottom();

    // Ensure knowledge graph is loaded
    if (!_dbSynced) {
      await _syncDatabaseKnowledgeGraph();
    }

    // Run local 360-degree dossier engine AND backend /ai/chat (for cross-platform memory & autonomous tools) in parallel
    final results = await Future.wait<dynamic>([
      _analyzeHumanQuestion(text),
      ApiService()
          .post('/ai/chat', data: {'message': text, 'current_page': '/admin-chat'})
          .then<dynamic>((r) => r.data)
          .catchError((_) => null),
    ]);

    if (!mounted) return;

    final localAnswer = results[0] as Map<String, dynamic>?;
    final backendData = results[1] is Map ? Map<String, dynamic>.from(results[1] as Map) : null;

    final backendReply = (backendData?['reply'] ?? backendData?['response'] ?? '').toString();
    final backendType = (backendData?['type'] ?? 'text').toString();
    final isBackendAutonomousToolOrDiag = backendData?['requires_confirmation'] == true ||
        const {
          'tool_confirmation',
          'proactive_insights',
          'system_diagnostics',
          'pending_purchases',
          'worker_reports',
          'navigation',
        }.contains(backendType);

    final backendIsFallback = backendReply.isEmpty ||
        backendReply.contains('found no exact matches') ||
        backendReply.contains("couldn't find") ||
        backendReply.contains('Nova AI');

    if (isBackendAutonomousToolOrDiag && backendData != null && backendReply.isNotEmpty) {
      setState(() {
        _messages.add({
          'isMe': false,
          'text': backendReply,
          'type': backendType,
          'data': backendData['data'],
          'actions': backendData['actions'],
          'requires_confirmation': backendData['requires_confirmation'] == true,
          'pending_tool': backendData['pending_tool'],
        });
        _isLoading = false;
      });
    } else if (localAnswer != null && (localAnswer['preferLocal'] == true || backendIsFallback)) {
      setState(() {
        _messages.add({
          'isMe': false,
          'text': localAnswer['reply'],
          'type': localAnswer['type'] ?? 'text',
          'data': localAnswer['data'],
          'actions': backendData?['actions'],
        });
        _isLoading = false;
      });
    } else if (backendData != null && backendReply.isNotEmpty) {
      setState(() {
        _messages.add({
          'isMe': false,
          'text': backendReply.replaceAll('Nova AI', 'Agency AI'),
          'type': backendType,
          'data': backendData['data'],
          'actions': backendData['actions'],
          'requires_confirmation': backendData['requires_confirmation'] == true,
          'pending_tool': backendData['pending_tool'],
        });
        _isLoading = false;
      });
    } else if (localAnswer != null) {
      setState(() {
        _messages.add({
          'isMe': false,
          'text': localAnswer['reply'],
          'type': localAnswer['type'] ?? 'text',
          'data': localAnswer['data'],
        });
        _isLoading = false;
      });
    } else {
      setState(() {
        _messages.add({
          'isMe': false,
          'text': _buildFullExecutiveBrief(),
          'type': 'text',
        });
        _isLoading = false;
      });
    }
    _scrollToBottom();
  }

  static const Set<String> _stopWords = {
    'the', 'and', 'for', 'are', 'but', 'not', 'you', 'all', 'any', 'can', 'had', 'her', 'was', 'one',
    'our', 'out', 'day', 'get', 'has', 'him', 'his', 'how', 'man', 'new', 'now', 'old', 'see', 'two',
    'way', 'who', 'boy', 'did', 'its', 'let', 'put', 'say', 'she', 'too', 'use', 'want', 'everything',
    'about', 'abot', 'tell', 'show', 'give', 'find', 'what', 'where', 'when', 'which', 'with', 'from',
    'that', 'this', 'have', 'does', 'rent', 'info', 'information', 'details', 'status', 'report', 'full',
    'summary', 'tenant', 'apartment', 'building', 'contract', 'lease', 'paid', 'unpaid', 'owe', 'owes',
    'money', 'history', 'profile', 'les', 'des', 'une', 'pour', 'dans', 'sur', 'tout', 'avec',
  };

  /// Natural-language human question analyzer connected to the full live database.
  /// Checks SPECIFIC entities (Tenants, Apartments, Buildings, Staff, Suppliers) FIRST
  /// so questions like "i want everything abot ali yazbek" return the full dossier for Ali Yazbek.
  Future<Map<String, dynamic>?> _analyzeHumanQuestion(String rawQuestion) async {
    final q = rawQuestion.toLowerCase().trim();
    final qWords = q
        .replaceAll(RegExp(r'[^\w\s\u0600-\u06FF]'), ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();

    // ═══════════════════════════════════════════════════════════════════════
    // 1. SPECIFIC TENANT MATCH (Highest Priority — e.g. "everything abot ali yazbek")
    // ═══════════════════════════════════════════════════════════════════════
    Map<String, dynamic>? matchedTenant;
    int bestTenantScore = 0;

    for (final tRaw in _tenants) {
      if (tRaw is! Map) continue;
      final fullName = (tRaw['full_name'] ?? tRaw['name'] ?? '').toString().trim();
      if (fullName.isEmpty) continue;
      final fullLower = fullName.toLowerCase();

      int score = 0;
      if (q.contains(fullLower)) {
        score = 100;
      } else {
        final nameParts = fullLower
            .split(RegExp(r'\s+'))
            .where((p) => p.length >= 3 && !_stopWords.contains(p))
            .toList();
        for (final part in nameParts) {
          if (qWords.contains(part) || q.contains(part)) {
            score += 20;
          }
        }
      }

      if (score > 0) {
        // Prioritize Active tenants over Terminated ones when two records share a name
        final tStatus = (tRaw['status'] ?? tRaw['contract_status'] ?? 'Active').toString().toLowerCase();
        if (tStatus == 'active' || tStatus == 'approved') {
          score += 5;
        }
        if (score > bestTenantScore) {
          bestTenantScore = score;
          matchedTenant = Map<String, dynamic>.from(tRaw);
        }
      }
    }

    if (matchedTenant != null && bestTenantScore >= 15) {
      return await _buildCompleteTenantDossier(matchedTenant);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // 2. SPECIFIC APARTMENT CODE MATCH (e.g. "Apt A1", "everything about B2")
    // ═══════════════════════════════════════════════════════════════════════
    final aptRegexMatch = RegExp(
      r'\b(?:apt|apartment|unit|flat|شقة|appartement)?\s*([a-z]\d{1,3}|\d{1,3}[a-z])\b',
      caseSensitive: false,
    ).firstMatch(rawQuestion);

    String? matchedAptCode = aptRegexMatch?.group(1)?.toLowerCase();
    if (matchedAptCode == null) {
      for (final aRaw in _apartments) {
        if (aRaw is! Map) continue;
        final code = (aRaw['code'] ?? aRaw['apartment_number'] ?? '').toString().trim().toLowerCase();
        if (code.isNotEmpty && qWords.contains(code)) {
          matchedAptCode = code;
          break;
        }
      }
    }

    if (matchedAptCode != null) {
      final matchedApts = _apartments.where((a) {
        if (a is! Map) return false;
        final code = (a['code'] ?? a['apartment_number'] ?? '').toString().toLowerCase();
        return code == matchedAptCode || code.contains(matchedAptCode!);
      }).toList();

      if (matchedApts.isNotEmpty) {
        return await _buildCompleteApartmentDossier(matchedAptCode, matchedApts);
      }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // 3. SPECIFIC BUILDING MATCH (e.g. "everything about Galaxy", "Bitar building")
    // ═══════════════════════════════════════════════════════════════════════
    for (final bRaw in _buildings) {
      if (bRaw is! Map) continue;
      final bName = (bRaw['name'] ?? '').toString().trim();
      if (bName.isNotEmpty && q.contains(bName.toLowerCase())) {
        return _buildCompleteBuildingDossier(Map<String, dynamic>.from(bRaw));
      }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // 4. SPECIFIC WORKER / AGENT / USER MATCH
    // ═══════════════════════════════════════════════════════════════════════
    for (final uRaw in _users) {
      if (uRaw is! Map) continue;
      final uName = (uRaw['name'] ?? uRaw['full_name'] ?? '').toString().trim();
      if (uName.isEmpty) continue;
      final uLower = uName.toLowerCase();
      final uParts = uLower.split(RegExp(r'\s+')).where((p) => p.length >= 3 && !_stopWords.contains(p)).toList();
      if (q.contains(uLower) || (uParts.isNotEmpty && uParts.every((p) => qWords.contains(p)))) {
        final role = (uRaw['role'] ?? 'staff').toString().toUpperCase();
        final email = uRaw['email'] ?? 'N/A';
        final phone = uRaw['phone'] ?? 'N/A';
        final userTasks = _acTasks.where((t) => t is Map && (t['worker_name'] ?? '').toString().toLowerCase().contains(uLower)).toList();
        final userTickets = _tenantTickets.where((t) => t is Map && (t['worker_name'] ?? '').toString().toLowerCase().contains(uLower)).toList();
        final userPurchases = _purchases.where((p) => p is Map && (p['submitter_name'] ?? '').toString().toLowerCase().contains(uLower)).toList();

        return {
          'preferLocal': true,
          'reply': '👷 **Complete Staff Dossier — $uName ($role):**\n\n'
              '• **Role:** $role\n'
              '• **Email:** $email | **Phone:** $phone\n'
              '• **AC Maintenance Tasks:** ${userTasks.length} task(s)\n'
              '• **Assigned Tenant Tickets:** ${userTickets.length} ticket(s)\n'
              '• **Submitted Purchases:** ${userPurchases.length} submission(s)',
          'type': 'text',
        };
      }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // 5. ALL TENANTS DIRECTORY (e.g. "list all tenants", "who are our tenants")
    // ═══════════════════════════════════════════════════════════════════════
    if (q.contains('tenant') || q.contains('resident') || q.contains('locataire') || q.contains('مستأجر')) {
      final lines = <String>['👥 **All Registered Tenants (${_tenants.length} Total):**\n'];
      final enrichedTenants = <Map<String, dynamic>>[];

      for (final raw in _tenants) {
        if (raw is! Map) continue;
        final t = Map<String, dynamic>.from(raw);
        final name = t['full_name'] ?? t['name'] ?? 'Tenant';
        final bld = t['building_name'] ?? 'Unassigned';
        final apt = t['apartment_code'] ?? 'N/A';
        final phone = t['phone'] ?? 'N/A';
        final status = t['contract_status'] ?? t['status'] ?? 'Active';

        // Match financial ledger if available
        final fin = _aptFinancials.cast<Map?>().firstWhere(
              (f) =>
                  f != null &&
                  ((f['tenant_name'] ?? '').toString().toLowerCase() == name.toString().toLowerCase() ||
                      ((f['code'] ?? '').toString() == apt.toString() && (f['building_name'] ?? '').toString() == bld.toString())),
              orElse: () => null,
            );
        final unpaid = _parseNum(fin?['total_unpaid_rent']);
        t['total_debt'] = unpaid;
        enrichedTenants.add(t);

        lines.add(
          '• **$name** — **$bld • Apt $apt** ($status)\n'
          '  📞 $phone | ${unpaid > 0 ? "🔴 Unpaid: **CFA ${NumberFormat('#,##0').format(unpaid)}**" : "✅ Paid Up"}',
        );
      }

      return {
        'preferLocal': true,
        'reply': lines.join('\n'),
        'type': 'widget_tenant_info',
        'data': enrichedTenants,
      };
    }

    // ═══════════════════════════════════════════════════════════════════════
    // 6. PURCHASES / APARTMENT COSTS / EXPENSES
    // ═══════════════════════════════════════════════════════════════════════
    if (q.contains('purchase') ||
        q.contains('bought') ||
        q.contains('cost') ||
        q.contains('supplier') ||
        q.contains('expense') ||
        q.contains('مشتريات') ||
        q.contains('تكاليف') ||
        q.contains('achat')) {
      if (_purchases.isEmpty) {
        return {
          'preferLocal': true,
          'reply': '🛒 There are currently **0** purchase or apartment cost submissions recorded in the database.',
          'type': 'text',
        };
      }
      final totalCost = _purchases.fold<double>(0, (s, p) => s + _parseNum((p as Map)['amount']));
      final normalizedList = _purchases.take(12).map((raw) {
        final p = Map<String, dynamic>.from(raw as Map);
        return {
          'building_name': p['building_name'] ?? 'Building',
          'apartment_number': p['apartment_number'] ?? p['apartment_code'] ?? '',
          'supplier': p['supplier'] ?? p['supplier_name'] ?? 'Supplier',
          'items': p['items'] ?? p['notes'] ?? p['type'] ?? 'Expense',
          'submitter_name': p['submitter_name'] ?? p['type'] ?? 'Agent',
          'amount': 'CFA ${NumberFormat('#,##0').format(_parseNum(p['amount']))}',
          'status': p['status'] ?? 'Approved',
        };
      }).toList();

      return {
        'preferLocal': true,
        'reply':
            '🛒 **Purchases & Apartment Costs:** Found **${_purchases.length}** records totaling **CFA ${NumberFormat('#,##0').format(totalCost)}**:',
        'type': 'widget_purchases_list',
        'data': normalizedList,
      };
    }

    // ═══════════════════════════════════════════════════════════════════════
    // 7. MAINTENANCE / AC / REPAIRS / TICKETS
    // ═══════════════════════════════════════════════════════════════════════
    if (q.contains('maint') ||
        q.contains('ac ') ||
        q.contains('air cond') ||
        q.contains('repair') ||
        q.contains('ticket') ||
        q.contains('issue') ||
        q.contains('problem') ||
        q.contains('broken') ||
        q.contains('صيانة') ||
        q.contains('مكيف')) {
      final combined = <Map<String, dynamic>>[];
      for (final raw in _tenantTickets.take(10)) {
        if (raw is! Map) continue;
        combined.add({
          'building_name': raw['building_name'] ?? 'Building',
          'apartment_code': raw['apartment_code'] ?? raw['apartment_number'] ?? '',
          'worker_name': raw['worker_name'] ?? raw['tenant_name'] ?? 'Tenant Request',
          'scheduled_date': raw['title'] ?? raw['category'] ?? raw['created_at'] ?? '',
          'status': raw['status'] ?? 'Open',
        });
      }
      for (final raw in _acTasks.take(10)) {
        if (raw is! Map) continue;
        combined.add({
          'building_name': raw['building_name'] ?? 'Building',
          'apartment_code': raw['apartment_code'] ?? '',
          'worker_name': raw['worker_name'] ?? 'Technician',
          'scheduled_date': raw['scheduled_date'] ?? raw['submission_date'] ?? '',
          'status': raw['status'] ?? 'Pending',
        });
      }

      return {
        'preferLocal': true,
        'reply': '🔧 **Maintenance & Field Operations:**\n'
            '• **Tenant Maintenance Requests:** ${_tenantTickets.length} ticket(s)\n'
            '• **AC Maintenance Tasks:** ${_acTasks.length} task(s)',
        'type': combined.isNotEmpty ? 'widget_maintenance_tasks' : 'text',
        'data': combined,
      };
    }

    // ═══════════════════════════════════════════════════════════════════════
    // 8. VACANT / EMPTY / AVAILABLE APARTMENTS
    // ═══════════════════════════════════════════════════════════════════════
    if (q.contains('vacant') ||
        q.contains('empty') ||
        q.contains('available') ||
        q.contains('free apt') ||
        q.contains('شاغر') ||
        q.contains('فارغ') ||
        q.contains('disponible')) {
      final vacant = _apartments.where((a) {
        if (a is! Map) return false;
        final st = (a['status'] ?? '').toString().toLowerCase();
        return st.contains('vacant') || st.contains('empty') || st.contains('available');
      }).toList();

      if (vacant.isEmpty) {
        return {
          'preferLocal': true,
          'reply': '✅ **100% Occupancy!** There are currently no vacant apartments across your ${_buildings.length} buildings.',
          'type': 'text',
        };
      }
      final lines = <String>['🏠 **Found ${vacant.length} Vacant Apartment(s) Ready for Leasing:**\n'];
      for (final raw in vacant.take(15)) {
        final a = raw as Map;
        final bld = a['building_name'] ?? _findBuildingName(a['building_id']) ?? 'Building';
        final code = a['code'] ?? a['apartment_number'] ?? '';
        final rent = NumberFormat('#,##0').format(_parseNum(a['monthly_rent']));
        lines.add('• **$bld — Apt $code** | Monthly Rent: **CFA $rent**');
      }
      return {
        'preferLocal': true,
        'reply': lines.join('\n'),
        'type': 'text',
      };
    }

    // ═══════════════════════════════════════════════════════════════════════
    // 9. FINANCIAL / RENT / UNPAID / DEBTORS
    // ═══════════════════════════════════════════════════════════════════════
    if (q.contains('rent') ||
        q.contains('money') ||
        q.contains('collect') ||
        q.contains('income') ||
        q.contains('revenue') ||
        q.contains('unpaid') ||
        q.contains('debt') ||
        q.contains('owe') ||
        q.contains('overdue') ||
        q.contains('financial') ||
        q.contains('cash')) {
      final due = _financialSummary['total_rent_due'] ?? 'CFA 0';
      final collected = _financialSummary['total_rent_collected'] ?? 'CFA 0';
      final outstanding = _financialSummary['outstanding_rent_balance'] ?? 'CFA 0';
      final unpaidCount = _financialSummary['unpaid_rent_invoices'] ?? 0;
      final elec = _financialSummary['electricity_collected'] ?? 'CFA 0';
      final gen = _financialSummary['generator_collected'] ?? 'CFA 0';
      final ins = _financialSummary['insurance_collected'] ?? 'CFA 0';

      final debtorLines = <String>[];
      final debtorsData = <Map<String, dynamic>>[];
      for (final fRaw in _aptFinancials) {
        if (fRaw is! Map) continue;
        final unpaid = _parseNum(fRaw['total_unpaid_rent']);
        if (unpaid > 0) {
          final tName = fRaw['tenant_name'] ?? 'Tenant';
          final bld = fRaw['building_name'] ?? 'Building';
          final code = fRaw['code'] ?? '';
          final overdueMonths = fRaw['overdue_months'] ?? 0;
          debtorLines.add(
            '• **$tName** ($bld • Apt $code): **CFA ${NumberFormat('#,##0').format(unpaid)}** unpaid ($overdueMonths overdue invoice(s))',
          );
          debtorsData.add({
            'full_name': tName,
            'building_name': bld,
            'apartment_code': code,
            'total_debt': unpaid,
          });
        }
      }

      return {
        'preferLocal': true,
        'reply': '💰 **Live Financial & Rent Telemetry:**\n\n'
            '• **Total Rent Billed:** $due\n'
            '• **Total Rent Collected:** $collected\n'
            '• **Outstanding Rent Balance:** **$outstanding** (**$unpaidCount** unpaid invoices)\n'
            '• **Electricity Collected:** $elec\n'
            '• **Generator Pool Collected:** $gen\n'
            '• **Insurance Pool Collected:** $ins'
            '${debtorLines.isNotEmpty ? "\n\n🔴 **Tenants with Unpaid Balances:**\n${debtorLines.join('\n')}" : ""}',
        'type': debtorsData.isNotEmpty ? 'widget_tenant_info' : 'text',
        'data': debtorsData,
      };
    }

    // ═══════════════════════════════════════════════════════════════════════
    // 9B. GENERATOR / ELECTRICITY / FUEL / ENERGY SUBSCRIPTIONS
    // ═══════════════════════════════════════════════════════════════════════
    if (q.contains('generator') ||
        q.contains('electricity') ||
        q.contains('energy') ||
        q.contains('fuel') ||
        q.contains('meter') ||
        q.contains('subscription') ||
        q.contains('مولد') ||
        q.contains('كهرباء')) {
      final genLines = <String>['⚡ **Live Generator, Fuel & Electricity Telemetry:**\n'];
      genLines.add('🔋 **1. Generators (${_generators.length} Total):**');
      for (final gRaw in _generators) {
        if (gRaw is! Map) continue;
        final gName = _nonEmpty(gRaw['name'] ?? gRaw['generator_name'], 'Generator');
        final gBld = _nonEmpty(gRaw['building_name'] ?? _findBuildingName(gRaw['building_id']), 'Main Grid');
        final gStatus = _nonEmpty(gRaw['status'], 'Active');
        final gKva = _nonEmpty(gRaw['capacity_kva'] ?? gRaw['kva'], 'N/A');
        final gFuel = _nonEmpty(gRaw['current_fuel_level'] ?? gRaw['fuel_level'] ?? gRaw['current_stock'], '0');
        genLines.add('• **$gName** ($gBld) — Status: **$gStatus** | Capacity: **$gKva KVA** | Fuel: **$gFuel L**');
      }

      genLines.add('\n🔌 **2. Apartment Generator/Electricity Subscriptions (${_subscriptions.length} Total):**');
      for (final sRaw in _subscriptions.take(12)) {
        if (sRaw is! Map) continue;
        final bld = _nonEmpty(sRaw['building_name'], 'Building');
        final apt = _nonEmpty(sRaw['apartment_code'], 'N/A');
        final type = _nonEmpty(sRaw['type'], 'Meter');
        final st = _nonEmpty(sRaw['status'], 'Active');
        final fee = NumberFormat('#,##0').format(_parseNum(sRaw['monthly_fee']));
        final kwhRate = _parseNum(sRaw['price_per_kwh']);
        final amps = _parseNum(sRaw['amps']);
        final lastRead = _nonEmpty(sRaw['last_meter_reading'], '0');
        genLines.add(
          '• **$bld • Apt $apt** [$st] — Plan: **$type** '
          '${amps > 0 ? "(${amps.toStringAsFixed(0)}A • CFA $fee/mo)" : (kwhRate > 0 ? "(CFA ${NumberFormat('#,##0').format(kwhRate)}/kWh • Last: $lastRead kWh)" : "(CFA $fee/mo)")}',
        );
      }

      final elecCollected = _nonEmpty(_financialSummary['electricity_collected'], 'CFA 0');
      final genCollected = _nonEmpty(_financialSummary['generator_collected'], 'CFA 0');
      genLines.add('\n💰 **3. Energy Collections (Current Month):**');
      genLines.add('• **Generator Pool Collected:** **$genCollected**');
      genLines.add('• **Electricity Collected:** **$elecCollected**');

      return {
        'preferLocal': true,
        'reply': genLines.join('\n'),
        'type': 'text',
      };
    }

    // ═══════════════════════════════════════════════════════════════════════
    // 10. GREETING / FULL AGENCY SUMMARY
    // ═══════════════════════════════════════════════════════════════════════
    if (RegExp(r'^(hi|hello|hey|bonjour|salut|مرحبا|اهلا|who are you|what can you do)$').hasMatch(q)) {
      return {
        'preferLocal': true,
        'reply': _buildFullExecutiveBrief(isGreeting: true),
        'type': 'text',
      };
    }

    if (q.contains('full') ||
        q.contains('everything') ||
        q.contains('agency summary') ||
        q.contains('all data') ||
        q.contains('how is the') ||
        q.contains('company') ||
        q.contains('general report') ||
        q.contains('overview') ||
        q.contains('ملخص') ||
        q.contains('كل شيء') ||
        q.contains('résumé')) {
      return {
        'preferLocal': true,
        'reply': _buildFullExecutiveBrief(),
        'type': 'text',
      };
    }

    return null;
  }

  /// Builds a complete 360-degree intelligence dossier for a single tenant
  Future<Map<String, dynamic>> _buildCompleteTenantDossier(Map<String, dynamic> tenant) async {
    final tenantId = tenant['id'];
    final fullName = _nonEmpty(tenant['full_name'] ?? tenant['name'], 'Tenant');
    final phone = _nonEmpty(tenant['phone'], 'N/A');
    final email = _nonEmpty(tenant['email'], 'N/A');
    final nationalId = _nonEmpty(tenant['national_id'], 'N/A');
    final accountStatus = _nonEmpty(tenant['status'], 'Active');

    // Match contracts for this tenant
    final tenantContracts = _contracts.where((c) {
      if (c is! Map) return false;
      return c['tenant_id']?.toString() == tenantId?.toString() ||
          (c['tenant_name'] ?? c['full_name'] ?? '').toString().toLowerCase() == fullName.toLowerCase();
    }).toList();

    final primaryContract = tenantContracts.isNotEmpty ? Map<String, dynamic>.from(tenantContracts.first as Map) : null;
    final bldName = _nonEmpty(tenant['building_name'] ?? primaryContract?['building_name'], 'Unassigned');
    final aptCode = _nonEmpty(tenant['apartment_code'] ?? primaryContract?['apartment_code'], 'N/A');
    final contractStatus = _nonEmpty(tenant['contract_status'] ?? primaryContract?['status'], accountStatus);
    final rentStatus = _nonEmpty(tenant['rent_status'] ?? primaryContract?['rent_status'], contractStatus);
    final startDate = _nonEmpty(tenant['start_date'] ?? primaryContract?['start_date'], 'N/A');
    final endDate = _nonEmpty(tenant['end_date'] ?? primaryContract?['end_date'], 'N/A');
    final billingFreq = _nonEmpty(tenant['billing_frequency'] ?? primaryContract?['payment_frequency'], 'Monthly');
    final nextBilling = _nonEmpty(tenant['next_billing_date'], 'N/A');

    // Match apartment object & ID
    final aptObj = _apartments.cast<Map?>().firstWhere(
          (a) =>
              a != null &&
              (a['id']?.toString() == primaryContract?['apartment_id']?.toString() ||
                  ((a['code'] ?? '').toString().toLowerCase() == aptCode.toLowerCase() &&
                      ((a['building_name'] ?? '').toString().toLowerCase() == bldName.toLowerCase() || bldName == 'Unassigned'))),
          orElse: () => null,
        );
    final aptId = aptObj?['id'] ?? primaryContract?['apartment_id'] ?? tenant['apartment_id'];
    final monthlyRent = _parseNum(primaryContract?['monthly_rent'] ?? aptObj?['monthly_rent']);
    final monthlyInsurance = _parseNum(primaryContract?['monthly_insurance'] ?? aptObj?['monthly_insurance']);

    // Fetch live rent history, documents, generator/electricity subscriptions, electricity invoices, meter readings, and apartment costs in parallel
    List<dynamic> rentInvoices = [];
    List<dynamic> documents = [];
    Map<String, dynamic> aptSubscription = {};
    List<dynamic> elecInvoices = [];
    List<dynamic> meterReadings = [];
    List<dynamic> directAptCosts = [];

    final futures = <Future<dynamic>>[
      tenantId != null
          ? ApiService().get('/tenants/$tenantId/rent-history').then<dynamic>((r) => r.data).catchError((_) => [])
          : Future.value([]),
      tenantId != null
          ? ApiService().get('/tenants/$tenantId/documents').then<dynamic>((r) => r.data).catchError((_) => [])
          : Future.value([]),
      aptId != null
          ? ApiService().get('/energy/apartments/$aptId/subscriptions').then<dynamic>((r) => r.data).catchError((_) => <String, dynamic>{})
          : Future.value(<String, dynamic>{}),
      aptId != null
          ? ApiService().get('/electricity/apartments/$aptId/invoices').then<dynamic>((r) => r.data).catchError((_) => [])
          : Future.value([]),
      aptId != null
          ? ApiService().get('/energy/apartments/$aptId/meter-readings').then<dynamic>((r) => r.data).catchError((_) => [])
          : Future.value([]),
      aptId != null
          ? ApiService().get('/apartments/$aptId/costs').then<dynamic>((r) => r.data).catchError((_) => [])
          : Future.value([]),
    ];

    final extra = await Future.wait(futures);
    if (extra[0] is List) rentInvoices = extra[0] as List;
    if (extra[1] is List) documents = extra[1] as List;
    if (extra[2] is Map) aptSubscription = Map<String, dynamic>.from(extra[2] as Map);
    if (extra[3] is List) elecInvoices = extra[3] as List;
    if (extra[4] is List) meterReadings = extra[4] as List;
    if (extra[5] is List) directAptCosts = extra[5] as List;

    // Fallback subscription from _subscriptions if needed
    if (aptSubscription.isEmpty || aptSubscription['status'] == 'None') {
      final cachedSub = _subscriptions.cast<Map?>().firstWhere(
            (s) =>
                s != null &&
                (s['apartment_id']?.toString() == aptId?.toString() ||
                    ((s['apartment_code'] ?? '').toString().toLowerCase() == aptCode.toLowerCase() &&
                        (s['building_name'] ?? '').toString().toLowerCase() == bldName.toLowerCase())),
            orElse: () => null,
          );
      if (cachedSub != null) {
        aptSubscription = Map<String, dynamic>.from(cachedSub);
      }
    }

    // Compute rent invoice totals (including Voided invoices so 1 Invoice never shows CFA 0!)
    double totalBilled = 0;
    double totalPaid = 0;
    double totalOutstanding = 0;
    double totalVoided = 0;
    int paidCount = 0;
    int unpaidCount = 0;
    int voidedCount = 0;
    final invoiceDetailLines = <String>[];

    for (final invRaw in rentInvoices) {
      if (invRaw is! Map) continue;
      final st = _nonEmpty(invRaw['status'], 'Unpaid');
      final amt = _parseNum(invRaw['amount']);
      final paid = _parseNum(invRaw['paid_amount']);
      final debt = _parseNum(invRaw['outstanding_debt']);
      final invNo = _nonEmpty(invRaw['invoice_number'], 'INV');
      final due = _nonEmpty(invRaw['due_date'], 'N/A');

      totalBilled += amt;
      totalPaid += paid;
      if (st == 'Voided') {
        voidedCount++;
        totalVoided += amt;
      } else if (st == 'Paid' || (amt > 0 && debt <= 0)) {
        paidCount++;
      } else {
        unpaidCount++;
        totalOutstanding += debt > 0 ? debt : amt;
      }

      if (invoiceDetailLines.length < 5) {
        invoiceDetailLines.add(
          '  - **$invNo** (Due: $due): Billed **CFA ${NumberFormat('#,##0').format(amt)}** | Paid **CFA ${NumberFormat('#,##0').format(paid)}** [$st]',
        );
      }
    }

    // Fallback to _aptFinancials if rentInvoices was empty
    if (rentInvoices.isEmpty) {
      final fin = _aptFinancials.cast<Map?>().firstWhere(
            (f) =>
                f != null &&
                ((f['tenant_name'] ?? '').toString().toLowerCase() == fullName.toLowerCase() ||
                    ((f['code'] ?? '').toString().toLowerCase() == aptCode.toLowerCase() &&
                        (f['building_name'] ?? '').toString().toLowerCase() == bldName.toLowerCase())),
            orElse: () => null,
          );
      if (fin != null) {
        totalBilled = _parseNum(fin['total_expected_rent']);
        totalPaid = _parseNum(fin['total_paid_rent']);
        totalOutstanding = _parseNum(fin['total_unpaid_rent']);
        unpaidCount = int.tryParse((fin['overdue_months'] ?? 0).toString()) ?? 0;
      } else if (monthlyRent > 0) {
        totalBilled = monthlyRent;
      }
    }

    // Generator & Electricity calculations for this tenant/apartment
    final bldGenerators = _generators.where((g) {
      if (g is! Map) return false;
      final gBld = (g['building_name'] ?? _findBuildingName(g['building_id']) ?? '').toString().toLowerCase();
      return gBld == bldName.toLowerCase() || g['building_id']?.toString() == aptObj?['building_id']?.toString();
    }).toList();
    final genSummary = bldGenerators.isNotEmpty
        ? bldGenerators
            .map((g) => '${_nonEmpty((g as Map)['name'] ?? g['generator_name'], 'Generator')} (${_nonEmpty(g['status'], 'Active')})')
            .join(', ')
        : (_generators.isNotEmpty
            ? '${_nonEmpty((_generators.first as Map)['name'] ?? _generators.first['generator_name'], 'Main Generator')} (Shared Grid)'
            : 'No Generator Assigned');

    final subStatus = _nonEmpty(aptSubscription['status'], 'No Active Subscription');
    final subType = _nonEmpty(aptSubscription['type'], 'N/A');
    final subFee = _parseNum(aptSubscription['monthly_fee']);
    final subAmps = _parseNum(aptSubscription['amps']);
    final subKwhPrice = _parseNum(aptSubscription['price_per_kwh']);
    final latestReading = meterReadings.isNotEmpty && meterReadings.first is Map
        ? _parseNum((meterReadings.first as Map)['current_reading'])
        : _parseNum(aptSubscription['last_meter_reading']);

    double elecBilled = 0;
    double elecPaid = 0;
    double elecUnpaid = 0;
    for (final eInv in elecInvoices) {
      if (eInv is! Map) continue;
      final amt = _parseNum(eInv['amount']);
      final paid = _parseNum(eInv['amount_paid']);
      elecBilled += amt;
      elecPaid += paid;
      if ((eInv['status'] ?? '').toString() != 'Paid') {
        elecUnpaid += (amt - paid) > 0 ? (amt - paid) : 0;
      }
    }

    // Maintenance tickets for this tenant or apartment
    final tenantMaint = _tenantTickets.where((t) {
      if (t is! Map) return false;
      final tName = (t['tenant_name'] ?? '').toString().toLowerCase();
      final tApt = (t['apartment_code'] ?? t['apartment_number'] ?? '').toString().toLowerCase();
      return t['tenant_id']?.toString() == tenantId?.toString() ||
          tName == fullName.toLowerCase() ||
          (aptCode != 'N/A' && tApt == aptCode.toLowerCase());
    }).toList();

    // Merge direct apartment costs + global _purchases for this apartment
    final allAptPurchases = <Map<String, dynamic>>[];
    final seenCostIds = <String>{};
    for (final c in [...directAptCosts, ..._purchases]) {
      if (c is! Map) continue;
      final cApt = (c['apartment_code'] ?? c['apartment_number'] ?? '').toString().toLowerCase();
      final isDirect = directAptCosts.contains(c);
      if (isDirect || (aptCode != 'N/A' && cApt == aptCode.toLowerCase())) {
        final key = '${c['supplier'] ?? c['supplier_name']}_${c['amount']}_${c['date'] ?? c['created_at']}';
        if (seenCostIds.add(key)) {
          allAptPurchases.add(Map<String, dynamic>.from(c));
        }
      }
    }
    final totalPurchasesAmount = allAptPurchases.fold<double>(0, (s, p) => s + _parseNum(p['amount']));

    final lines = <String>[
      '👤 **Complete 360° Database Dossier — $fullName:**\n',
      '📋 **1. Personal & Contact Profile:**',
      '• **Full Name:** $fullName (ID: #$tenantId • Status: **$accountStatus**)',
      '• **Phone:** $phone | **Email:** $email',
      '• **National ID / Passport:** $nationalId\n',
      '🏢 **2. Property & Lease Contract:**',
      '• **Assigned Unit:** **$bldName • Apt $aptCode**',
      '• **Contract Status:** **$contractStatus** (Rent Status: **$rentStatus**)',
      '• **Lease Period:** **$startDate** to **$endDate**',
      '• **Monthly Rent:** **CFA ${NumberFormat('#,##0').format(monthlyRent)}** | **Insurance Deposit:** **CFA ${NumberFormat('#,##0').format(monthlyInsurance)}**',
      '• **Billing Cycle:** $billingFreq (Next Billing: **$nextBilling**)\n',
      '💰 **3. Financial & Rent Ledger (${rentInvoices.length} Invoice(s)):**',
      '• **Total Billed:** **CFA ${NumberFormat('#,##0').format(totalBilled)}**${voidedCount > 0 ? " ($voidedCount voided on termination: CFA ${NumberFormat('#,##0').format(totalVoided)})" : ""}',
      '• **Total Paid:** **CFA ${NumberFormat('#,##0').format(totalPaid)}** (**$paidCount** paid invoice(s))',
      '• **Outstanding Debt:** **CFA ${NumberFormat('#,##0').format(totalOutstanding)}** (**$unpaidCount** unpaid/overdue invoice(s))',
    ];

    if (invoiceDetailLines.isNotEmpty) {
      lines.add('• **Invoice History Breakdown:**');
      lines.addAll(invoiceDetailLines);
    }

    lines.add('\n⚡ **4. Generator & Electricity Telemetry:**');
    lines.add('• **Building Generator:** **$genSummary**');
    lines.add(
      '• **Subscription Status:** **$subStatus** ${subType != "N/A" ? "(Plan: **$subType**)" : ""}',
    );
    if (subFee > 0 || subAmps > 0 || subKwhPrice > 0 || latestReading > 0) {
      lines.add(
        '• **Tariff & Meter:** '
        '${subAmps > 0 ? "**${subAmps.toStringAsFixed(0)} Amps** • " : ""}'
        '${subFee > 0 ? "Monthly Fee: **CFA ${NumberFormat('#,##0').format(subFee)}** • " : ""}'
        '${subKwhPrice > 0 ? "Rate: **CFA ${NumberFormat('#,##0').format(subKwhPrice)}/kWh** • " : ""}'
        'Last Meter Reading: **${latestReading.toStringAsFixed(1)} kWh** (${meterReadings.length} reading(s))',
      );
    }
    lines.add(
      '• **Generator/Electricity Invoices (${elecInvoices.length}):** '
      'Billed **CFA ${NumberFormat('#,##0').format(elecBilled)}** | '
      'Paid **CFA ${NumberFormat('#,##0').format(elecPaid)}** | '
      'Unpaid **CFA ${NumberFormat('#,##0').format(elecUnpaid)}**',
    );

    lines.add('\n🔧 **5. Maintenance, Purchases & Documents:**');
    lines.add('• **Maintenance Tickets:** **${tenantMaint.length}** request(s)');
    for (final m in tenantMaint.take(4)) {
      if (m is Map) {
        lines.add('  - ${_nonEmpty(m['title'] ?? m['category'], 'Issue')} [${_nonEmpty(m['status'], 'Open')}]');
      }
    }
    lines.add(
      '• **Apartment Purchases/Expenses:** **${allAptPurchases.length}** record(s) '
      '${totalPurchasesAmount > 0 ? "(Total: **CFA ${NumberFormat('#,##0').format(totalPurchasesAmount)}**)" : ""}',
    );
    for (final p in allAptPurchases.take(3)) {
      final sup = _nonEmpty(p['supplier'] ?? p['supplier_name'], 'Supplier');
      final item = _nonEmpty(p['items'] ?? p['notes'] ?? p['type'], 'Expense');
      final pAmt = NumberFormat('#,##0').format(_parseNum(p['amount']));
      lines.add('  - **$sup** ($item): **CFA $pAmt**');
    }
    lines.add('• **Uploaded Documents:** **${documents.length}** file(s) on record');

    final cardData = Map<String, dynamic>.from(tenant);
    cardData['building_name'] = bldName;
    cardData['apartment_code'] = aptCode;
    cardData['total_debt'] = totalOutstanding + elecUnpaid;

    return {
      'preferLocal': true,
      'reply': lines.join('\n'),
      'type': 'widget_tenant_info',
      'data': [cardData],
    };
  }

  /// Builds a complete 360-degree dossier for a specific apartment code
  Future<Map<String, dynamic>> _buildCompleteApartmentDossier(String codeQuery, List<dynamic> matchedApts) async {
    final lines = <String>['🏠 **Complete 360° Database Dossier for Apartment ${codeQuery.toUpperCase()}:**\n'];
    for (final raw in matchedApts.take(6)) {
      final a = Map<String, dynamic>.from(raw as Map);
      final code = (a['code'] ?? a['apartment_number'] ?? '').toString();
      final bld = (a['building_name'] ?? _findBuildingName(a['building_id']) ?? 'Building').toString();
      final status = (a['status'] ?? 'Unknown').toString();
      final rent = NumberFormat('#,##0').format(_parseNum(a['monthly_rent']));
      final ins = NumberFormat('#,##0').format(_parseNum(a['monthly_insurance']));

      final contract = _contracts.cast<Map?>().firstWhere(
            (c) =>
                c != null &&
                ((c['apartment_id']?.toString() == a['id']?.toString()) ||
                    ((c['apartment_code'] ?? '').toString().toLowerCase() == code.toLowerCase() &&
                        (c['building_name'] ?? '').toString().toLowerCase() == bld.toLowerCase())),
            orElse: () => null,
          );
      final tenantName = (contract?['tenant_name'] ?? contract?['full_name'] ?? a['tenant_name'] ?? 'Vacant / No Active Tenant').toString();
      final startDate = contract?['start_date'] ?? 'N/A';
      final endDate = contract?['end_date'] ?? 'N/A';

      final fin = _aptFinancials.cast<Map?>().firstWhere(
            (f) =>
                f != null &&
                (f['id']?.toString() == a['id']?.toString() ||
                    ((f['code'] ?? '').toString().toLowerCase() == code.toLowerCase() &&
                        (f['building_name'] ?? '').toString().toLowerCase() == bld.toLowerCase())),
            orElse: () => null,
          );
      final paidRent = _parseNum(fin?['total_paid_rent']);
      final unpaidRent = _parseNum(fin?['total_unpaid_rent']);

      final aptCosts = _purchases.where((p) {
        if (p is! Map) return false;
        final pApt = (p['apartment_code'] ?? p['apartment_number'] ?? '').toString().toLowerCase();
        return pApt == code.toLowerCase();
      }).toList();

      final aptTickets = _tenantTickets.where((t) {
        if (t is! Map) return false;
        final tApt = (t['apartment_code'] ?? t['apartment_number'] ?? '').toString().toLowerCase();
        return tApt == code.toLowerCase();
      }).toList();

      lines.add('• **$bld — Apt $code** (Status: **$status**)');
      lines.add('  👤 **Current Tenant:** $tenantName');
      lines.add('  📅 **Lease Period:** $startDate → $endDate');
      lines.add('  💵 **Monthly Rent:** CFA $rent | **Insurance:** CFA $ins');
      lines.add('  💰 **Ledger:** Paid **CFA ${NumberFormat('#,##0').format(paidRent)}** | Unpaid **CFA ${NumberFormat('#,##0').format(unpaidRent)}**');
      lines.add('  🔧 **Maintenance Tickets:** ${aptTickets.length} | 🛒 **Purchases/Costs:** ${aptCosts.length} item(s)');
      lines.add('');
    }
    return {
      'preferLocal': true,
      'reply': lines.join('\n').trim(),
      'type': 'text',
    };
  }

  /// Builds a complete 360-degree dossier for a specific building
  Map<String, dynamic> _buildCompleteBuildingDossier(Map<String, dynamic> bRaw) {
    final bName = (bRaw['name'] ?? 'Building').toString().trim();
    final bId = bRaw['id']?.toString();
    final bLocation = (bRaw['location'] ?? 'N/A').toString();
    final bApts = _apartments
        .where((a) =>
            a is Map &&
            (a['building_id']?.toString() == bId ||
                (a['building_name'] ?? '').toString().toLowerCase() == bName.toLowerCase()))
        .toList();
    final rentedCount = bApts
        .where((a) =>
            (a['status'] ?? '').toString().toLowerCase() == 'rented' ||
            (a['status'] ?? '').toString().toLowerCase() == 'occupied')
        .length;
    final vacantCount = bApts.length - rentedCount;
    final bContracts = _contracts
        .where((c) => c is Map && (c['building_name'] ?? '').toString().toLowerCase() == bName.toLowerCase())
        .toList();
    final bTickets = _tenantTickets
        .where((t) => t is Map && (t['building_name'] ?? '').toString().toLowerCase() == bName.toLowerCase())
        .toList();
    final bCosts = _purchases
        .where((p) => p is Map && (p['building_name'] ?? '').toString().toLowerCase().contains(bName.toLowerCase()))
        .toList();
    final totalMonthlyRent = bContracts.fold<double>(0, (s, c) => s + _parseNum(c['monthly_rent']));

    final unitLines = <String>[];
    for (final rawApt in bApts) {
      if (rawApt is! Map) continue;
      final code = rawApt['code'] ?? '';
      final st = rawApt['status'] ?? 'Vacant';
      final tName = rawApt['tenant_name'] ?? 'Vacant';
      final r = NumberFormat('#,##0').format(_parseNum(rawApt['monthly_rent']));
      unitLines.add('  - **Apt $code** ($st): **$tName** — CFA $r/mo');
    }

    return {
      'preferLocal': true,
      'reply': '🏢 **Complete 360° Intelligence Dossier — $bName:**\n\n'
          '• **Location:** $bLocation\n'
          '• **Total Units:** ${bApts.isNotEmpty ? bApts.length : (bRaw['total_apartments'] ?? bRaw['apartment_count'] ?? 0)} apartments (**$rentedCount** Occupied, **$vacantCount** Vacant)\n'
          '• **Active Contracts:** ${bContracts.length} contracts (**CFA ${NumberFormat('#,##0').format(totalMonthlyRent)}/mo** billed)\n'
          '• **Maintenance Tickets:** ${bTickets.length} request(s)\n'
          '• **Purchases & Cost Logs:** ${bCosts.length} entry(s)'
          '${unitLines.isNotEmpty ? "\n\n🏠 **Unit-by-Unit Roster:**\n${unitLines.join('\n')}" : ""}',
      'type': 'text',
    };
  }

  String? _findBuildingName(dynamic buildingId) {
    if (buildingId == null) return null;
    for (final b in _buildings) {
      if (b is Map && b['id']?.toString() == buildingId.toString()) {
        return b['name']?.toString();
      }
    }
    return null;
  }

  String _buildFullExecutiveBrief({bool isGreeting = false}) {
    final rentCollected = _financialSummary['total_rent_collected'] ?? 'CFA 0';
    final rentOutstanding = _financialSummary['outstanding_rent_balance'] ?? 'CFA 0';
    final unpaidInvoices = _financialSummary['unpaid_rent_invoices'] ?? 0;
    final vacantCount = _apartments.where((a) => a is Map && (a['status'] ?? '').toString().toLowerCase() == 'vacant').length;

    return '${isGreeting ? "Hello! I am **Agency AI**, connected live to every table in your SOCIMCO database.\n\n" : ""}'
        '📊 **Live Agency Executive Snapshot:**\n'
        '• 🏢 **Portfolio:** **${_buildings.length}** Buildings | **${_apartments.length}** Apartments (**$vacantCount** Vacant)\n'
        '• 👥 **Tenants & Leases:** **${_tenants.length}** Registered Tenants | **${_contracts.length}** Contracts\n'
        '• 💰 **Monthly Rent:** **$rentCollected** Collected | **$rentOutstanding** Outstanding (**$unpaidInvoices** unpaid invoices)\n'
        '• 🔧 **Maintenance:** **${_tenantTickets.length}** Tenant Tickets | **${_acTasks.length}** AC Tasks\n'
        '• 🛒 **Purchases & Costs:** **${_purchases.length}** Recorded Entries\n'
        '• ⚡ **Generators & Alerts:** **${_generators.length}** Generators | **${_alerts.length}** Active Alerts\n\n'
        'Ask me about any specific building, apartment code (e.g. "Apt A1"), tenant name, overdue rent, or maintenance ticket!';
  }

  /// Renders Markdown-style `**bold**` cleanly without showing raw asterisks (with RTL Arabic support)
  Widget _buildFormattedText(String text, {required bool isMe}) {
    final baseColor = isMe ? const Color(0xFF04130F) : AppTheme.textPrimary;
    final boldColor = isMe ? const Color(0xFF04130F) : AppTheme.primary;
    final isRtl = RegExp(r'[\u0600-\u06FF]').hasMatch(text);

    final spans = <TextSpan>[];
    final regex = RegExp(r'\*\*(.+?)\*\*');
    int lastEnd = 0;

    for (final match in regex.allMatches(text)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(text: text.substring(lastEnd, match.start)));
      }
      spans.add(
        TextSpan(
          text: match.group(1),
          style: GoogleFonts.plusJakartaSans(
            color: boldColor,
            fontWeight: FontWeight.w800,
            fontSize: 14,
            height: 1.45,
          ),
        ),
      );
      lastEnd = match.end;
    }
    if (lastEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastEnd)));
    }

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: RichText(
        text: TextSpan(
          style: GoogleFonts.plusJakartaSans(
            color: baseColor,
            fontSize: 14,
            fontWeight: isMe ? FontWeight.w700 : FontWeight.w500,
            height: 1.45,
          ),
          children: spans,
        ),
      ),
    );
  }

  Widget _buildWidget(Map<String, dynamic> msg) {
    final type = msg['type'];
    final data = msg['data'];

    // 1. Autonomous Tool Confirmation Guard Card
    if (type == 'tool_confirmation' && msg['pending_tool'] is Map) {
      final tool = Map<String, dynamic>.from(msg['pending_tool'] as Map);
      return Container(
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.accent),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.verified_user_rounded, color: AppTheme.accent, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    (tool['summary'] ?? 'Confirm Action').toString(),
                    style: GoogleFonts.outfit(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 13.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: const Color(0xFF04130F),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _toolBusy
                        ? null
                        : () => _executeBackendTool(
                              (tool['tool_name'] ?? '').toString(),
                              tool['target_id'],
                              tool['parameters'] is Map
                                  ? Map<String, dynamic>.from(tool['parameters'] as Map)
                                  : <String, dynamic>{},
                            ),
                    icon: const Icon(Icons.check_circle_rounded, size: 16),
                    label: Text(
                      _toolBusy ? 'Executing...' : 'Confirm & Execute',
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.danger,
                    side: const BorderSide(color: AppTheme.danger),
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _toolBusy ? null : () => _sendMessage(customText: 'Proactive insights'),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // 2. Proactive Insights Cards
    if (type == 'proactive_insights' && data is List) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: data.take(8).map((raw) {
          final ins = Map<String, dynamic>.from(raw as Map);
          final isHigh = ins['severity'] == 'high';
          return Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isHigh ? AppTheme.danger : AppTheme.primary.withValues(alpha: 0.45)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        (ins['title'] ?? 'Insight').toString(),
                        style: GoogleFonts.outfit(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 13.5,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: (isHigh ? AppTheme.danger : AppTheme.primary).withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        (ins['metric'] ?? '').toString(),
                        style: GoogleFonts.outfit(
                          color: isHigh ? AppTheme.danger : AppTheme.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  (ins['description'] ?? '').toString(),
                  style: GoogleFonts.plusJakartaSans(color: AppTheme.textSecondary, fontSize: 11.5),
                ),
                if (ins['suggested_prompt'] != null) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: InkWell(
                      onTap: () => _sendMessage(customText: ins['suggested_prompt'].toString()),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Inspect Details →',
                          style: GoogleFonts.plusJakartaSans(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        }).toList(),
      );
    }

    // 3. Purchases & Pending Purchase Review Cards (With Interactive Approve/Reject)
    if ((type == 'widget_purchases_list' || type == 'pending_purchases') && data is List) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: data.take(10).map((item) {
          final p = Map<String, dynamic>.from(item as Map);
          final isPending = (p['status'] ?? '').toString().contains('Pending');
          final purchaseId = p['id'];
          final amtDisplay = p['amount']?.toString().startsWith('CFA') == true
              ? p['amount'].toString()
              : 'CFA ${NumberFormat('#,##0').format(_parseNum(p['amount']))}';

          return Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isPending ? AppTheme.accent : AppTheme.border,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.accent.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.shopping_cart_rounded, color: AppTheme.accent, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${p['building_name'] ?? 'Building'} • Apt ${p['apartment_number'] ?? p['apartment_code'] ?? ''}',
                            style: GoogleFonts.outfit(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 13.5,
                            ),
                          ),
                          Text(
                            'Supplier: ${p['supplier'] ?? 'N/A'} • ${p['items'] ?? 'Expense'}',
                            style: GoogleFonts.plusJakartaSans(color: AppTheme.textSecondary, fontSize: 11.5),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      amtDisplay,
                      style: GoogleFonts.outfit(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 13.5,
                      ),
                    ),
                  ],
                ),
                if (isPending && purchaseId != null) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: _toolBusy
                              ? null
                              : () => _executeBackendTool('review_purchase', purchaseId, {'status': 'Approved'}),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 7),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppTheme.primary.withValues(alpha: 0.5)),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '✓ Approve Purchase',
                              style: GoogleFonts.plusJakartaSans(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.w800,
                                fontSize: 11.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: InkWell(
                          onTap: _toolBusy
                              ? null
                              : () => _executeBackendTool('review_purchase', purchaseId, {'status': 'Rejected'}),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 7),
                            decoration: BoxDecoration(
                              color: AppTheme.danger.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppTheme.danger.withValues(alpha: 0.45)),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '✕ Reject',
                              style: GoogleFonts.plusJakartaSans(
                                color: AppTheme.danger,
                                fontWeight: FontWeight.w800,
                                fontSize: 11.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          );
        }).toList(),
      );
    }

    if ((type == 'widget_maintenance_tasks' || type == 'maintenance_tasks') && data != null) {
      final List<dynamic> list = data is List
          ? data
          : (data is Map && data['tasks'] is List ? data['tasks'] as List : []);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: list.take(10).map((item) {
          final m = item as Map<String, dynamic>;
          final isPending = (m['status'] ?? '').toString().toLowerCase().contains('pend') ||
              (m['status'] ?? '').toString().toLowerCase().contains('open');
          return Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isPending ? AppTheme.primary.withValues(alpha: 0.5) : AppTheme.border,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.engineering_rounded, color: AppTheme.primary, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${m['building_name'] ?? 'Building'} • Apt ${m['apartment_code'] ?? ''}',
                        style: GoogleFonts.outfit(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                        ),
                      ),
                      Text(
                        '${m['worker_name'] ?? 'Assigned'} • ${m['scheduled_date'] ?? ''}',
                        style: GoogleFonts.plusJakartaSans(color: AppTheme.textSecondary, fontSize: 11.5),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: (isPending ? AppTheme.accent : AppTheme.primary).withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    (m['status'] ?? 'Active').toString().toUpperCase(),
                    style: GoogleFonts.plusJakartaSans(
                      color: isPending ? AppTheme.accent : AppTheme.primary,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      );
    }

    if ((type == 'widget_expiring_rent' || type == 'expiring_contracts') && data is List) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: data.take(10).map((item) {
          final t = item as Map<String, dynamic>;
          final dateStr = t['end_date']?.toString() ?? '';
          String formatted = dateStr;
          try {
            formatted = DateFormat('dd MMM yyyy').format(DateTime.parse(dateStr));
          } catch (_) {}

          return Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.danger.withValues(alpha: 0.45)),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: AppTheme.danger, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t['full_name'] ?? 'Tenant',
                        style: GoogleFonts.outfit(color: AppTheme.textPrimary, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        '${t['building_name'] ?? ''} • Apt ${t['apartment_code'] ?? ''}',
                        style: GoogleFonts.plusJakartaSans(color: AppTheme.textSecondary, fontSize: 12),
                      ),
                      Text(
                        'Expires: $formatted',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppTheme.danger,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      );
    }

    if ((type == 'widget_tenant_info' || type == 'tenant_info' || type == 'top_debtors' || type == 'overdue_rent') &&
        data is List) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: data.take(10).map((item) {
          final t = item as Map<String, dynamic>;
          final debt = _parseNum(t['total_debt'] ?? t['outstanding']);

          return Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.primary.withValues(alpha: 0.35)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.person_pin_rounded, color: AppTheme.primary, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t['full_name'] ?? 'Tenant',
                            style: GoogleFonts.outfit(color: AppTheme.textPrimary, fontWeight: FontWeight.w700),
                          ),
                          Text(
                            '${t['building_name'] ?? ''} • Apt ${t['apartment_code'] ?? ''}',
                            style: GoogleFonts.plusJakartaSans(color: AppTheme.textSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    if (debt > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.danger.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'CFA ${NumberFormat('#,##0').format(debt)}',
                          style: GoogleFonts.outfit(
                            color: AppTheme.danger,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      );
    }

    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textPrimary, size: 18),
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.accent]),
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(Icons.psychology_rounded, color: Color(0xFF04130F), size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Agency AI',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: _dbSynced ? AppTheme.primary : AppTheme.accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _dbSynced
                          ? 'Full Database Connected (${_buildings.length} Bldgs • ${_apartments.length} Apts • ${_tenants.length} Tenants)'
                          : 'Synchronizing Full Database...',
                      style: GoogleFonts.plusJakartaSans(
                        color: AppTheme.textSecondary,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'System Diagnostics',
            icon: const Icon(Icons.health_and_safety_rounded, color: AppTheme.accent, size: 21),
            onPressed: () => _sendMessage(customText: 'Run system diagnostics'),
          ),
          IconButton(
            tooltip: 'Reset Conversation Memory',
            icon: const Icon(Icons.restart_alt_rounded, color: AppTheme.textSecondary, size: 21),
            onPressed: _clearConversationHistory,
          ),
          IconButton(
            tooltip: 'Sync Database',
            icon: const Icon(Icons.sync_rounded, color: AppTheme.primary, size: 21),
            onPressed: () {
              ApiService().clearCache();
              _loadSyncedHistory();
              _syncDatabaseKnowledgeGraph();
            },
          ),
        ],
      ),
      body: AmbientLuxuryBackground(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  final isMe = msg['isMe'] == true;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (!isMe) ...[
                          Container(
                            width: 34,
                            height: 34,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(colors: [AppTheme.primary, AppTheme.accent]),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.psychology_rounded, color: Color(0xFF04130F), size: 18),
                          ),
                          const SizedBox(width: 10),
                        ],
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: isMe ? AppTheme.primaryGradient : AppTheme.obsidianCardGradient,
                              borderRadius: BorderRadius.circular(20).copyWith(
                                bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(20),
                                bottomLeft: !isMe ? const Radius.circular(4) : const Radius.circular(20),
                              ),
                              border: isMe
                                  ? null
                                  : Border.all(color: AppTheme.primary.withValues(alpha: 0.25)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFormattedText(msg['text']?.toString() ?? '', isMe: isMe),
                                if (msg['type'] != null && msg['type'] != 'text') ...[
                                  const SizedBox(height: 10),
                                  _buildWidget(msg),
                                ],
                                if (!isMe && msg['actions'] is List && (msg['actions'] as List).isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 6,
                                    children: (msg['actions'] as List).map((actRaw) {
                                      if (actRaw is! Map) return const SizedBox.shrink();
                                      final label = (actRaw['label'] ?? 'Open').toString();
                                      final route = (actRaw['mobile_route'] ?? actRaw['route'] ?? '').toString();
                                      if (route.isEmpty) return const SizedBox.shrink();
                                      return InkWell(
                                        onTap: () => context.push(route),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primary.withValues(alpha: 0.14),
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(color: AppTheme.primary.withValues(alpha: 0.4)),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.open_in_new_rounded, color: AppTheme.primary, size: 13),
                                              const SizedBox(width: 5),
                                              Text(
                                                label,
                                                style: GoogleFonts.plusJakartaSans(
                                                  color: AppTheme.primary,
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        if (isMe) const SizedBox(width: 36),
                      ],
                    ),
                  );
                },
              ),
            ),
            if (_isLoading)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(colors: [AppTheme.primary, AppTheme.accent]),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.psychology_rounded, color: Color(0xFF04130F), size: 16),
                    ),
                    const SizedBox(width: 10),
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Agency AI is analyzing database...',
                      style: GoogleFonts.plusJakartaSans(color: AppTheme.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
            // Quick suggestion chips
            Container(
              height: 46,
              decoration: const BoxDecoration(
                color: AppTheme.surface,
                border: Border(top: BorderSide(color: AppTheme.border)),
              ),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                itemCount: _suggestions.length,
                itemBuilder: (ctx, i) => GestureDetector(
                  onTap: () => _sendMessage(customText: _suggestions[i]),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppTheme.background,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.primary.withValues(alpha: 0.35)),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _suggestions[i],
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Input Area
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              decoration: const BoxDecoration(
                color: AppTheme.surface,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: GoogleFonts.plusJakartaSans(color: AppTheme.textPrimary, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Ask Agency AI anything in natural language...',
                        hintStyle: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontSize: 13),
                        filled: true,
                        fillColor: AppTheme.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: AppTheme.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: AppTheme.border),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(colors: [AppTheme.primary, AppTheme.accent]),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded, color: Color(0xFF04130F), size: 20),
                      onPressed: _sendMessage,
                    ),
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
