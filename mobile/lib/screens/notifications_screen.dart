import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../providers/app_providers.dart';
import '../widgets/mobile/enterprise_mobile_scaffold.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    // Load live notifications from the API on screen open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationsProvider.notifier).loadFromApi();
    });
  }


  final List<String> _categories = [
    'All',
    'Tasks',
    'Approvals',
    'Rejections',
    'Tenant Requests',
    'Generator',
    'Maintenance',
    'Electricity',
    'Contracts',
    'System',
  ];

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final allNotifications = ref.watch(notificationsProvider);
    final notifier = ref.read(notificationsProvider.notifier);

    final filtered = _selectedCategory == 'All'
        ? allNotifications
        : allNotifications.where((n) => n.category == _selectedCategory).toList();

    final unreadCount = allNotifications.where((n) => !n.isRead).length;

    return EnterpriseMobileScaffold(
      title: 'Categorized Notification Center',
      userRole: user?.role ?? 'User',
      userName: user?.name ?? 'User',
      unreadNotifications: unreadCount,
      currentTabIndex: 3,
      onTabSelected: (index) {
        if (index == 0) context.go('/dashboard');
        if (index == 1) context.go('/agent-subscriptions');
        if (index == 2) context.go('/agent-history');
        if (index == 4) context.go('/settings');
      },
      body: Column(
        children: [
          // Header Action Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: const Color(0xFF0D1620),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Notifications ($unreadCount Unread)',
                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () => notifier.markAllAsRead(),
                      icon: const Icon(Icons.done_all, size: 16, color: Color(0xFF00D4AA)),
                      label: const Text('Mark All Read', style: TextStyle(color: Color(0xFF00D4AA), fontSize: 11)),
                    ),
                    TextButton.icon(
                      onPressed: () => notifier.clearOld(),
                      icon: const Icon(Icons.delete_sweep, size: 16, color: Colors.blueGrey),
                      label: const Text('Clear Read', style: TextStyle(color: Colors.blueGrey, fontSize: 11)),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Category Chips Bar
          SizedBox(
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = _selectedCategory == cat;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(cat),
                    selected: isSelected,
                    selectedColor: Color(0xFF00A884),
                    backgroundColor: const Color(0xFF0D1620),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.blueGrey.shade300,
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: isSelected ? Color(0xFF1FE0B8) : const Color(0xFF1D3347)),
                    ),
                    onSelected: (_) => setState(() => _selectedCategory = cat),
                  ),
                );
              },
            ),
          ),

          // Notification List
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      'No notifications in $_selectedCategory category.',
                      style: GoogleFonts.inter(color: Colors.blueGrey.shade400),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final notif = filtered[index];

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: notif.isRead ? const Color(0xFF0D1620).withOpacity(0.5) : const Color(0xFF0D1620),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: notif.isRead ? const Color(0xFF1D3347) : Color(0xFF00D4AA).withOpacity(0.5)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: _getCategoryColor(notif.category).withOpacity(0.2),
                              child: Icon(_getCategoryIcon(notif.category), size: 18, color: _getCategoryColor(notif.category)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        notif.title,
                                        style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF060B10),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          notif.category,
                                          style: TextStyle(color: Colors.blueGrey.shade400, fontSize: 9),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    notif.message,
                                    style: GoogleFonts.inter(color: Colors.blueGrey.shade300, fontSize: 12),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    notif.createdAt.toLocal().toString().substring(11, 16),
                                    style: TextStyle(color: Colors.blueGrey.shade500, fontSize: 10),
                                  ),
                                ],
                              ),
                            ),
                            if (!notif.isRead)
                              IconButton(
                                icon: const Icon(Icons.check_circle_outline, color: Color(0xFF00D4AA), size: 20),
                                onPressed: () => notifier.markAsRead(notif.id),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String cat) {
    switch (cat) {
      case 'Approvals':
        return Colors.green;
      case 'Rejections':
        return Colors.red;
      case 'Tasks':
        return Color(0xFF00D4AA);
      case 'Tenant Requests':
        return Colors.amber;
      case 'Generator':
        return Colors.orange;
      case 'Maintenance':
        return Colors.blue;
      default:
        return Colors.purple;
    }
  }

  IconData _getCategoryIcon(String cat) {
    switch (cat) {
      case 'Approvals':
        return Icons.check_circle;
      case 'Rejections':
        return Icons.cancel;
      case 'Tasks':
        return Icons.task_alt;
      case 'Tenant Requests':
        return Icons.person_pin;
      case 'Generator':
        return Icons.electric_bolt;
      case 'Maintenance':
        return Icons.build;
      default:
        return Icons.notifications;
    }
  }
}
