import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../config/app_theme.dart';

class UnifiedTaskCenterScreen extends ConsumerStatefulWidget {
  const UnifiedTaskCenterScreen({super.key});

  @override
  ConsumerState<UnifiedTaskCenterScreen> createState() => _UnifiedTaskCenterScreenState();
}

class _UnifiedTaskCenterScreenState extends ConsumerState<UnifiedTaskCenterScreen> {
  List<dynamic> _tasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTasks();
  }

  Future<void> _fetchTasks() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService().get('/tasks/me?user_id=1');
      final data = res.data;
      if (data is Map && data['status'] == 'success') {
        setState(() {
          _tasks = data['data'] ?? [];
        });
      } else if (data is List) {
        setState(() {
          _tasks = data;
        });
      }
    } catch (e) {
      debugPrint('Error fetching tasks: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStatus(int taskId, String status) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final res = await ApiService().post('/tasks/$taskId/status', data: {'status': status, 'user_id': 1});
      final data = res.data;
      if (data is Map && data['status'] == 'success') {
        messenger.showSnackBar(
          SnackBar(content: Text('Task marked as $status')),
        );
        _fetchTasks();
      }
    } catch (e) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Failed to update task')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060B10),
      appBar: AppBar(
        title: Text(
          'Unified Inbox',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF0D1620),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchTasks,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : _tasks.isEmpty
              ? Center(
                  child: Text(
                    'No tasks assigned to you today! 🎉',
                    style: GoogleFonts.inter(fontSize: 16, color: Colors.blueGrey),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _tasks.length,
                  itemBuilder: (context, index) {
                    final task = _tasks[index] as Map<String, dynamic>;
                    return Card(
                      color: const Color(0xFF0D1620),
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    task['title'] ?? 'Task',
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                _buildPriorityBadge(task['priority']?.toString()),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Type: ${task['type'] ?? 'General'}',
                              style: GoogleFonts.inter(color: Colors.blueGrey),
                            ),
                            Text(
                              'Due: ${task['due_date'] ?? 'N/A'}',
                              style: GoogleFonts.inter(color: Colors.blueGrey),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (task['status'] == 'Pending')
                                  ElevatedButton(
                                    onPressed: () => _updateStatus(task['id'], 'In Progress'),
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                                    child: const Text('Start Task'),
                                  )
                                else if (task['status'] == 'In Progress')
                                  ElevatedButton(
                                    onPressed: () => _updateStatus(task['id'], 'Completed'),
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                    child: const Text('Mark Complete'),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildPriorityBadge(String? priority) {
    Color color;
    switch (priority) {
      case 'Urgent':
        color = Colors.red;
        break;
      case 'High':
        color = Colors.orange;
        break;
      default:
        color = Colors.blue;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Text(
        priority ?? 'Normal',
        style: GoogleFonts.inter(color: color, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}
