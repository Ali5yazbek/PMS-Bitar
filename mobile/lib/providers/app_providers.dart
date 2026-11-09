import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../core/network/realtime_service.dart';

// ── Dashboard Operational Stats State ───────────────────────────────────────
class DashboardStatsState {
  final int assignedBuildings;
  final int pendingGenReadings;
  final int submittedGenToday;
  final int rejectedGen;
  final int totalApartments;
  final int pendingAptReadings;
  final int completedAptMonth;
  final int rejectedApt;
  final int pendingSubTasks;
  final int missedReadings;
  final double completionPercentage;
  final String lastSyncTime;
  final bool isLoading;

  const DashboardStatsState({
    this.assignedBuildings = 0,
    this.pendingGenReadings = 0,
    this.submittedGenToday = 0,
    this.rejectedGen = 0,
    this.totalApartments = 0,
    this.pendingAptReadings = 0,
    this.completedAptMonth = 0,
    this.rejectedApt = 0,
    this.pendingSubTasks = 0,
    this.missedReadings = 0,
    this.completionPercentage = 100.0,
    this.lastSyncTime = 'Just now',
    this.isLoading = false,
  });

  DashboardStatsState copyWith({
    int? assignedBuildings,
    int? pendingGenReadings,
    int? submittedGenToday,
    int? rejectedGen,
    int? totalApartments,
    int? pendingAptReadings,
    int? completedAptMonth,
    int? rejectedApt,
    int? pendingSubTasks,
    int? missedReadings,
    double? completionPercentage,
    String? lastSyncTime,
    bool? isLoading,
  }) {
    return DashboardStatsState(
      assignedBuildings: assignedBuildings ?? this.assignedBuildings,
      pendingGenReadings: pendingGenReadings ?? this.pendingGenReadings,
      submittedGenToday: submittedGenToday ?? this.submittedGenToday,
      rejectedGen: rejectedGen ?? this.rejectedGen,
      totalApartments: totalApartments ?? this.totalApartments,
      pendingAptReadings: pendingAptReadings ?? this.pendingAptReadings,
      completedAptMonth: completedAptMonth ?? this.completedAptMonth,
      rejectedApt: rejectedApt ?? this.rejectedApt,
      pendingSubTasks: pendingSubTasks ?? this.pendingSubTasks,
      missedReadings: missedReadings ?? this.missedReadings,
      completionPercentage: completionPercentage ?? this.completionPercentage,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class DashboardStatsNotifier extends Notifier<DashboardStatsState> {
  @override
  DashboardStatsState build() {
    return const DashboardStatsState();
  }

  void updateStats(Map<String, dynamic> json) {
    state = state.copyWith(
      assignedBuildings: json['assignedBuildings'] ?? 0,
      pendingGenReadings: json['pendingGenReadings'] ?? 0,
      submittedGenToday: json['submittedGenToday'] ?? 0,
      rejectedGen: json['rejectedGen'] ?? 0,
      totalApartments: json['totalApartments'] ?? 0,
      pendingAptReadings: json['pendingAptReadings'] ?? 0,
      completedAptMonth: json['completedAptMonth'] ?? 0,
      rejectedApt: json['rejectedApt'] ?? 0,
      pendingSubTasks: json['pendingSubTasks'] ?? 0,
      missedReadings: json['missedReadings'] ?? 0,
      completionPercentage: ((json['completionPercentage'] ?? 100.0) as num).toDouble(),
      lastSyncTime: DateTime.now().toLocal().toString().substring(11, 16),
      isLoading: false,
    );
  }
}

final dashboardStatsProvider = NotifierProvider<DashboardStatsNotifier, DashboardStatsState>(
  DashboardStatsNotifier.new,
);

// ── Notification Item & State ──────────────────────────────────────────────
class NotificationItem {
  final String id;
  final String title;
  final String message;
  final String category; // Tasks, Approvals, Rejections, Tenant Requests, Generator, Maintenance, Electricity, Contracts, System
  final bool isRead;
  final DateTime createdAt;
  final String? route;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.category,
    this.isRead = false,
    required this.createdAt,
    this.route,
  });

  NotificationItem copyWith({bool? isRead}) {
    return NotificationItem(
      id: id,
      title: title,
      message: message,
      category: category,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
      route: route,
    );
  }
}

class CategorizedNotificationsNotifier extends Notifier<List<NotificationItem>> {
  @override
  List<NotificationItem> build() {
    return [];
  }

  /// Fetch all role-specific operational tasks, requests, collections, and unread notifications
  /// from the live PHP backend (bypassing cache).
  Future<void> loadFromApi() async {
    try {
      final list = await NotificationService().fetchComprehensiveRoleNotifications();
      state = list.map((n) => NotificationItem(
        id: n['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: n['title']?.toString() ?? 'Notification',
        message: n['message']?.toString() ?? '',
        category: _mapCategory(n['type']?.toString() ?? ''),
        isRead: (n['is_read'] == 1 || n['is_read'] == true),
        createdAt: n['created_at'] != null
            ? DateTime.tryParse(n['created_at'].toString()) ?? DateTime.now()
            : DateTime.now(),
        route: n['route']?.toString(),
      )).toList();

      // Also pass to NotificationService so native push banner triggers if new
      await NotificationService().processUnreadNotifications(list);
    } catch (_) {}
  }

  Future<void> markAsRead(String id) async {
    NotificationService().markDismissed(id);
    state = state.map((item) => item.id == id ? item.copyWith(isRead: true) : item).toList();
    if (int.tryParse(id) != null) {
      try {
        await ApiService().post('/notifications/$id/read');
      } catch (_) {}
    }
  }

  Future<void> markAllAsRead() async {
    final unreadIds = state.where((i) => !i.isRead).map((i) => i.id).toList();
    state = state.map((item) => item.copyWith(isRead: true)).toList();
    for (final id in unreadIds) {
      NotificationService().markDismissed(id);
      if (int.tryParse(id) != null) {
        try {
          await ApiService().post('/notifications/$id/read');
        } catch (_) {}
      }
    }
  }

  void clearOld() {
    state = state.where((item) => !item.isRead).toList();
  }

  void addRealtimeNotification(RealtimeEvent event) {
    final newItem = NotificationItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: event.type.replaceAll('_', ' ').toUpperCase(),
      message: event.data['message'] ?? 'New operational alert received.',
      category: _mapCategory(event.type),
      createdAt: event.timestamp,
    );
    state = [newItem, ...state];
  }

  String _mapCategory(String type) {
    final t = type.toLowerCase();
    if (t == 'maintenance_request' || t.contains('tenant')) return 'Tenant Requests';
    if (t.contains('maint') || t.contains('ac_')) return 'Maintenance';
    if (t.contains('elec') || t.contains('meter') || t.contains('sub')) return 'Electricity';
    if (t.contains('contract') || t.contains('rent')) return 'Contracts';
    if (t.contains('purchase') || t.contains('approv') || t.contains('accept')) return 'Approvals';
    if (t.contains('reject')) return 'Rejections';
    if (t.contains('gen')) return 'Generator';
    if (t.contains('task')) return 'Tasks';
    return 'System';
  }
}

final notificationsProvider = NotifierProvider<CategorizedNotificationsNotifier, List<NotificationItem>>(
  CategorizedNotificationsNotifier.new,
);
