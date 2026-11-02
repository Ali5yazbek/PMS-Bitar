import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_theme.dart';
import '../services/subscription_api.dart';
import '../services/camera_service.dart';
import '../widgets/mobile/enterprise_mobile_scaffold.dart';
import '../widgets/mobile/meter_reader_hud.dart';
import 'package:go_router/go_router.dart';
import '../screens/agent_dashboard_screen.dart';

final subscriptionTasksProvider = FutureProvider<List<dynamic>>((ref) async {
  return await SubscriptionApi.instance.getSubscriptionTasks();
});

double _toDouble(dynamic val) {
  if (val == null) return 0.0;
  if (val is double) return val;
  if (val is int) return val.toDouble();
  return double.tryParse(val.toString()) ?? 0.0;
}

class AgentSubscriptionsScreen extends ConsumerStatefulWidget {
  const AgentSubscriptionsScreen({super.key});

  @override
  ConsumerState<AgentSubscriptionsScreen> createState() => _AgentSubscriptionsScreenState();
}

class _AgentSubscriptionsScreenState extends ConsumerState<AgentSubscriptionsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedStatus = 'Pending';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(subscriptionTasksProvider);

    return EnterpriseMobileScaffold(
      title: 'Subscription Tasks',
      userRole: 'Agent',
      userName: 'Field Agent',
      currentTabIndex: 1,
      body: RefreshIndicator(
        color: AppTheme.primary,
        onRefresh: () async => ref.invalidate(subscriptionTasksProvider),
        child: Column(
          children: [
            // Header tabs: Pending Tasks, Under Review, Accepted, Rejected
            Container(
              color: const Color(0xFF0D1620),
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                indicatorColor: AppTheme.primary,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.blueGrey.shade400,
                labelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12),
                onTap: (index) {
                  final statuses = ['Pending', 'Under Review', 'Accepted', 'Rejected'];
                  setState(() => _selectedStatus = statuses[index]);
                },
                tabs: const [
                  Tab(text: 'All Pending'),
                  Tab(text: 'Under Review'),
                  Tab(text: 'Accepted'),
                  Tab(text: 'Rejected'),
                ],
              ),
            ),

            Expanded(
              child: _selectedStatus == 'Pending' ? Consumer(builder: (context, ref, child) {
                  final smartTasksAsync = ref.watch(agentSmartTasksStreamProvider);
                  return smartTasksAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
                    error: (e, _) => Center(child: Text('Error loading tasks: $e', style: const TextStyle(color: Colors.red))),
                    data: (tasks) {
                      if (tasks.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.assignment_turned_in_outlined, size: 48, color: Colors.blueGrey),
                              const SizedBox(height: 12),
                              Text('No Pending Tasks', style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                              Text('All urgent tasks have been completed.', style: GoogleFonts.inter(color: Colors.blueGrey.shade400, fontSize: 12)),
                            ],
                          ),
                        );
                      }
                      return ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        itemCount: tasks.length,
                        itemBuilder: (context, index) {
                          final taskMap = tasks[index] as Map<String, dynamic>;
                          final title = taskMap['title']?.toString() ?? 'Task';
                          final tag = taskMap['task_tag']?.toString() ?? '';
                          final desc = taskMap['description']?.toString() ?? 
                              (taskMap['unpaid_count'] != null ? '${taskMap['unpaid_count']} unpaid invoice(s) • Apt: ${taskMap['apartments_list'] ?? ''}' : tag);
                          final actionText = taskMap['action_text']?.toString() ?? taskMap['action_label']?.toString() ?? 'Open';
                          final actionType = taskMap['action_type']?.toString() ?? '';

                          return Card(
                            color: const Color(0xFF0D1620),
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: Colors.blue.withValues(alpha: 0.2))),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.15), shape: BoxShape.circle),
                                    child: const Icon(Icons.task_alt_rounded, color: AppTheme.primary, size: 22),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Directionality(
                                          textDirection: TextDirection.ltr,
                                          child: Row(
                                            children: [
                                              if (tag.isNotEmpty) ...[
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(color: Colors.indigo.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(6)),
                                                  child: Text(tag, style: const TextStyle(color: Color(0xFF00D4AA), fontSize: 9, fontWeight: FontWeight.bold)),
                                                ),
                                                const SizedBox(width: 6),
                                              ],
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Directionality(
                                          textDirection: TextDirection.ltr,
                                          child: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14), overflow: TextOverflow.ellipsis, maxLines: 2),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(desc, style: TextStyle(color: Colors.grey[400], fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primary,
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    onPressed: () {
                                      if (actionType == 'GENERATOR_LOG') {
                                        context.push('/agent-generators');
                                      } else if (actionType == 'SUBSCRIPTION_REVIEW') {
                                        context.push('/agent-subscriptions');
                                      } else if (actionType == 'RENT_COLLECTION' || actionType == 'ELECTRICITY_COLLECTION') {
                                        context.push('/agent-rent-collection');
                                      } else if (actionType == 'METER_READING' || actionType == 'EXPIRING_CONTRACT') {
                                        context.push('/agent-apartments');
                                      } else {
                                        final route = taskMap['action_route']?.toString();
                                        if (route != null && route.isNotEmpty) {
                                          context.push(route);
                                        } else {
                                          context.push('/agent-subscriptions');
                                        }
                                      }
                                    },
                                    child: Text(actionText.length > 12 ? 'Open' : actionText, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    }
                  );
              }) : tasksAsync.when(
                loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
                error: (e, _) => Center(child: Text('Error loading tasks: $e', style: const TextStyle(color: Colors.red))),
                data: (list) {
                  final filtered = list.where((item) {
                    final status = (item['latest_submission_status'] ?? item['status'] ?? 'Pending').toString();
                    if (_selectedStatus == 'Pending') {
                      return status.isEmpty || status.toLowerCase() == 'pending' || status.toLowerCase() == 'due';
                    }
                    if (_selectedStatus == 'Under Review') {
                      return status.toLowerCase() == 'under review' || status.toLowerCase() == 'pending verification';
                    }
                    return status.toLowerCase() == _selectedStatus.toLowerCase();
                  }).toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.assignment_turned_in_outlined, size: 48, color: Colors.blueGrey),
                            const SizedBox(height: 12),
                            Text(
                              'No $_selectedStatus Subscription Tasks',
                              style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            Text('Tasks in this section will appear automatically as billing dates approach.', style: GoogleFonts.inter(color: Colors.blueGrey.shade400, fontSize: 12)),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final task = filtered[index] as Map<String, dynamic>;
                      final bName = task['building_name']?.toString() ?? 'Building';
                      final aptCode = task['apartment_code']?.toString() ?? task['apartment_number']?.toString() ?? 'N/A';
                      final tenant = task['tenant_name']?.toString() ?? 'Tenant';
                      final subType = task['subscription_type']?.toString() ?? task['meter_type']?.toString() ?? 'Meter';
                      final remainingDays = task['days_until_expiry'] ?? task['remaining_days'] ?? 0;
                      final prevReading = _toDouble(task['previous_reading']);
                      final monthlyFee = task['monthly_fee']?.toString() ?? '0';

                      return InkWell(
                        onTap: () => _openSubmitReadingModal(task),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D1620),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFF1D3347)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header row: Building & Apt + Countdown badge
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                                          child: const Icon(Icons.bolt, color: Colors.redAccent, size: 16),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            '$bName • Apt $aptCode',
                                            style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Remaining Days Badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade900.withValues(alpha: 0.4),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.red.shade500),
                                    ),
                                    child: Text(
                                      '${remainingDays}d left',
                                      style: const TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),

                              // Tenant & Meter Type Badge
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Tenant: $tenant', style: GoogleFonts.inter(color: Colors.blueGrey.shade300, fontSize: 12)),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(color: Color(0xFF073B32), borderRadius: BorderRadius.circular(6)),
                                    child: Text(subType, style: TextStyle(color: Color(0xFF5CEAD0), fontSize: 9, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              const Divider(color: Color(0xFF1D3347), height: 1),
                              const SizedBox(height: 10),

                              // Metric values: Prev reading & Monthly fee
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Previous Reading: ${prevReading.toStringAsFixed(1)} kWh', style: TextStyle(color: Colors.blueGrey.shade400, fontSize: 11)),
                                  Text('Monthly Fee: CFA $monthlyFee', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                ],
                              ),

                              if (task['rejection_reason'] != null) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(color: Colors.red.shade900.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                                  child: Text('Rejection Reason: ${task['rejection_reason']}', style: const TextStyle(color: Colors.redAccent, fontSize: 11)),
                                ),
                              ],

                              const SizedBox(height: 12),
                              Builder(
                                builder: (context) {
                                  final status = task['latest_submission_status']?.toString();
                                  final isSubmitted = status == 'Pending' || status == 'Approved';
                                  
                                  if (isSubmitted) {
                                    return Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: Colors.green.withOpacity(0.3)),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.check_circle, color: Colors.greenAccent, size: 16),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Already Submitted ($status)',
                                            style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 12)
                                          ),
                                        ],
                                      ),
                                    );
                                  }
                                  
                                  return SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.primary,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                      icon: const Icon(Icons.speed, size: 16, color: Colors.white),
                                      label: const Text('Submit Meter Reading', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                      onPressed: () => _openSubmitReadingModal(task),
                                    ),
                                  );
                                }
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openSubmitReadingModal(Map<String, dynamic> task) {
    final bName = task['building_name']?.toString() ?? 'Building';
    final aptCode = task['apartment_code']?.toString() ?? task['apartment_number']?.toString() ?? 'N/A';
    final tenant = task['tenant_name']?.toString() ?? 'Active Tenant';
    final subType = task['subscription_type']?.toString() ?? 'Meter';
    final prevReading = _toDouble(task['previous_reading']);
    final monthlyFee = _toDouble(task['monthly_fee']);
    final aptId = task['apartment_id'] ?? task['id'];
    final subId = task['subscription_id'] ?? task['id'];
    final isFixed = subType.toLowerCase().contains('fixed');

    final readingController = TextEditingController();
    final notesController = TextEditingController();
    String? photoPath;
    double calculatedConsumption = 0.0;
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0B1121),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            void updateConsumption(String val) {
              final current = double.tryParse(val) ?? 0.0;
              setModalState(() {
                calculatedConsumption = (current - prevReading);
              });
            }

            final currentVal = double.tryParse(readingController.text.trim()) ?? 0.0;
            final hasInput = readingController.text.trim().isNotEmpty;
            final isLower = !isFixed && hasInput && currentVal < prevReading;
            final canSubmit = isFixed || (hasInput && !isLower);

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                top: 20,
                left: 16,
                right: 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle Bar
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.blueGrey.shade700,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (isFixed) ...[
                      // Fixed Subscription Inspector Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF060B10),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.indigo.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.indigo.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(Icons.calendar_month, color: Color(0xFF00D4AA), size: 20),
                                    ),
                                    const SizedBox(width: 10),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('$bName • Apt $aptCode', style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                        Text('Tenant: $tenant', style: GoogleFonts.inter(color: Colors.blueGrey.shade300, fontSize: 12)),
                                      ],
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Color(0xFF073B32),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text('Flat Monthly', style: TextStyle(color: Color(0xFF00D4AA), fontSize: 10, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0D1620),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Monthly Subscription Fee', style: TextStyle(color: Colors.blueGrey, fontSize: 13)),
                                  Text(
                                    'CFA ${monthlyFee.toInt()}',
                                    style: GoogleFonts.outfit(color: Colors.amberAccent, fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Photo Proof Box
                            if (photoPath != null)
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0D1620),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.check_circle, color: Colors.greenAccent, size: 18),
                                    const SizedBox(width: 8),
                                    const Expanded(child: Text('Inspection Photo Attached', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))),
                                    TextButton(
                                      onPressed: () async {
                                        final path = await CameraService.instance.capturePhotoFromCamera();
                                        if (path != null) setModalState(() => photoPath = path);
                                      },
                                      child: const Text('Retake', style: TextStyle(fontSize: 11)),
                                    ),
                                  ],
                                ),
                              )
                            else
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(color: Colors.indigo.withValues(alpha: 0.5)),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  icon: const Icon(Icons.camera_alt, color: Color(0xFF00D4AA)),
                                  label: const Text('Capture Apartment / Meter Photo', style: TextStyle(color: Colors.white)),
                                  onPressed: () async {
                                    final path = await CameraService.instance.capturePhotoFromCamera();
                                    if (path != null) setModalState(() => photoPath = path);
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                    ] else ...[
                      // Intelligent Meter Reading HUD
                      MeterReaderHud(
                        buildingName: bName,
                        apartmentCode: aptCode,
                        tenantName: tenant,
                        subscriptionType: subType,
                        previousReading: prevReading,
                        readingController: readingController,
                        onChanged: updateConsumption,
                        photoPath: photoPath,
                        onPhotoCaptured: (path) => setModalState(() => photoPath = path),
                      ),
                    ],

                    const SizedBox(height: 14),

                    // Agent Notes input
                    TextField(
                      controller: notesController,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        labelText: 'Field Notes / Observations (Optional)',
                        labelStyle: GoogleFonts.inter(color: Colors.blueGrey.shade400, fontSize: 12),
                        filled: true,
                        fillColor: const Color(0xFF060B10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Submit Action Button
                    if (isSubmitting)
                      const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                    else
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: canSubmit ? AppTheme.primary : Colors.blueGrey.shade800,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: !canSubmit
                              ? null
                              : () async {
                                  if (!isFixed && readingController.text.trim().isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter current reading')));
                                    return;
                                  }
                                  if (isLower) {
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                      content: Text('Current reading cannot be lower than baseline counter.'),
                                      backgroundColor: Colors.red,
                                    ));
                                    return;
                                  }
                                  if (photoPath == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                      content: Text('Please capture a meter photo proof before submitting.'),
                                      backgroundColor: Colors.amber,
                                    ));
                                    return;
                                  }

                                  setModalState(() => isSubmitting = true);
                                  final messenger = ScaffoldMessenger.of(context);

                                  try {
                                    final currentReading = isFixed ? 0.0 : (double.tryParse(readingController.text.trim()) ?? 0.0);
                                    final consumption = isFixed ? 0.0 : (currentReading - prevReading).clamp(0.0, 99999.0);

                                    final success = await SubscriptionApi.instance.submitSubscriptionReading({
                                      'apartment_id': aptId,
                                      'subscription_id': subId,
                                      'previous_reading': prevReading,
                                      'current_reading': currentReading,
                                      'consumption': consumption,
                                      'notes': notesController.text.trim(),
                                      if (photoPath != null) 'meter_photo': photoPath,
                                    });

                                    if (context.mounted) {
                                      Navigator.pop(ctx);
                                      ref.invalidate(subscriptionTasksProvider);
                                      if (success) {
                                        messenger.showSnackBar(const SnackBar(
                                          content: Text('Reading submitted & logged for admin review ✓'),
                                          backgroundColor: Colors.green,
                                        ));
                                      } else {
                                        messenger.showSnackBar(const SnackBar(
                                          content: Text('Saved offline and queued for automatic sync ✓'),
                                          backgroundColor: Colors.amber,
                                        ));
                                      }
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      setModalState(() => isSubmitting = false);
                                      messenger.showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                                    }
                                  }
                                },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                isFixed ? 'Confirm Subscription Inspection' : 'Submit Verified Reading',
                                style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
