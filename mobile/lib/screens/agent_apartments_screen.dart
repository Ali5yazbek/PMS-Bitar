import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../config/app_theme.dart';
import '../services/api_service.dart';
import '../services/subscription_api.dart';
import '../services/camera_service.dart';
import '../widgets/mobile/enterprise_mobile_scaffold.dart';
import '../widgets/mobile/meter_reader_hud.dart';

final buildingsListProvider = FutureProvider<List<dynamic>>((ref) async {
  try {
    final res = await ApiService().get('/buildings');
    final data = res.data;
    if (data is List) return data;
    if (data is Map<String, dynamic>) {
      return (data['buildings'] ?? data['data'] ?? []) as List<dynamic>;
    }
    return [];
  } catch (_) {
    return [];
  }
});

final buildingApartmentsProvider = FutureProvider.family.autoDispose<List<dynamic>, String>((ref, buildingId) async {
  if (buildingId.isEmpty) return [];
  try {
    final res = await ApiService().get('/energy/agent/building-apartments/$buildingId');
    final data = res.data;
    if (data is List) return data;
    return [];
  } catch (_) {
    return [];
  }
});

double _toDouble(dynamic val) {
  if (val == null) return 0.0;
  if (val is double) return val;
  if (val is int) return val.toDouble();
  return double.tryParse(val.toString()) ?? 0.0;
}

class AgentApartmentsScreen extends ConsumerStatefulWidget {
  const AgentApartmentsScreen({super.key});

  @override
  ConsumerState<AgentApartmentsScreen> createState() => _AgentApartmentsScreenState();
}

class _AgentApartmentsScreenState extends ConsumerState<AgentApartmentsScreen> {
  Map<String, dynamic>? _selectedBuilding;

  @override
  Widget build(BuildContext context) {
    final buildingsAsync = ref.watch(buildingsListProvider);

    return EnterpriseMobileScaffold(
      title: 'Apartment Readings',
      userRole: 'Agent',
      userName: 'Field Agent',
      currentTabIndex: 0,
      body: RefreshIndicator(
        color: AppTheme.primary,
        onRefresh: () async {
          ref.invalidate(buildingsListProvider);
          if (_selectedBuilding != null) {
            ref.invalidate(buildingApartmentsProvider(_selectedBuilding!['id'].toString()));
          }
        },
        child: Column(
          children: [
            // Select Building Bar
            Container(
              padding: const EdgeInsets.all(16),
              color: const Color(0xFF0D1620),
              child: Row(
                children: [
                  const Icon(Icons.apartment, color: Color(0xFF00D4AA)),
                  const SizedBox(width: 10),
                  Text('Building:', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(color: const Color(0xFF060B10), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFF1D3347))),
                      child: DropdownButtonHideUnderline(
                        child: buildingsAsync.when(
                          loading: () => const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                          error: (_, __) => const Text('Error loading buildings', style: TextStyle(color: Colors.red)),
                          data: (buildings) {
                            if (buildings.isEmpty) {
                              return const Text('No buildings found', style: TextStyle(color: Colors.blueGrey));
                            }

                            final selectedId = _selectedBuilding?['id']?.toString();
                            final exists = buildings.any((b) => b['id']?.toString() == selectedId);

                            if (!exists) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (mounted) {
                                  setState(() => _selectedBuilding = buildings.first as Map<String, dynamic>);
                                }
                              });
                            }

                            final currentBuilding = exists ? _selectedBuilding : (buildings.first as Map<String, dynamic>);

                            return DropdownButton<String>(
                              value: currentBuilding?['id']?.toString(),
                              dropdownColor: const Color(0xFF060B10),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              isExpanded: true,
                              items: buildings.map((b) {
                                final bMap = b as Map<String, dynamic>;
                                return DropdownMenuItem<String>(
                                  value: bMap['id']?.toString(),
                                  child: Text(bMap['name']?.toString() ?? 'Building'),
                                );
                              }).toList(),
                              onChanged: (val) {
                                final match = buildings.firstWhere(
                                  (b) => b['id']?.toString() == val,
                                  orElse: () => null,
                                );
                                if (match != null) {
                                  setState(() => _selectedBuilding = match as Map<String, dynamic>);
                                }
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // List Apartments in Selected Building
            Expanded(
              child: _selectedBuilding == null
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                  : Consumer(
                      builder: (context, ref, _) {
                        final buildingId = _selectedBuilding!['id'].toString();
                        final aptsAsync = ref.watch(buildingApartmentsProvider(buildingId));

                        return aptsAsync.when(
                          loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
                          error: (e, _) => Center(child: Text('Error loading apartments: $e', style: const TextStyle(color: Colors.red))),
                          data: (apts) {
                            if (apts.isEmpty) {
                              return Center(
                                child: SingleChildScrollView(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.apartment_outlined, size: 64, color: AppTheme.textSecondary.withValues(alpha: 0.4)),
                                      const SizedBox(height: 16),
                                      Text('No apartments found in ${_selectedBuilding!['name']}', style: GoogleFonts.inter(color: Colors.white, fontSize: 16)),
                                    ],
                                  ),
                                ),
                              );
                            }

                            return ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.all(16),
                              itemCount: apts.length,
                              itemBuilder: (context, index) {
                                final apt = apts[index] as Map<String, dynamic>;
                                final aptCode = apt['apartment_code']?.toString() ?? apt['code']?.toString() ?? 'N/A';
                                final tenant = apt['tenant_name']?.toString() ?? 'No active contract';
                                final lastReading = _toDouble(apt['last_reading'] ?? apt['subscription_prev_reading']);
                                final lastDate = apt['last_reading_date']?.toString() ?? 'N/A';
                                final subType = apt['subscription_type']?.toString() ?? 'Meter';

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 14),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0D1620),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: const Color(0xFF1D3347)),
                                  ),
                                  child: Stack(
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  'Apt $aptCode • $tenant',
                                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                decoration: BoxDecoration(color: Color(0xFF073B32), borderRadius: BorderRadius.circular(6)),
                                                child: Text(subType, style: TextStyle(color: Color(0xFF5CEAD0), fontSize: 10, fontWeight: FontWeight.bold)),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Text('Previous Reading: ${lastReading.toStringAsFixed(1)} kWh (Last: $lastDate)', style: TextStyle(color: Colors.blueGrey.shade400, fontSize: 11)),
                                          const SizedBox(height: 12),

                                          Builder(
                                            builder: (context) {
                                              final status = (apt['latest_submission_status'] ?? apt['status'] ?? '').toString();
                                              final isPending = status == 'Pending' || status.toLowerCase().contains('pending') || status.toLowerCase().contains('waiting');
                                              final isSubmitted = isPending || status == 'Approved' || status == 'Completed';
                                              
                                              if (isSubmitted) {
                                                return Container(
                                                  width: double.infinity,
                                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                                  decoration: BoxDecoration(
                                                    color: isPending ? Colors.amber.shade900.withValues(alpha: 0.2) : Colors.green.shade900.withValues(alpha: 0.2),
                                                    borderRadius: BorderRadius.circular(12),
                                                    border: Border.all(color: isPending ? Colors.amber.shade600 : Colors.green.shade600),
                                                  ),
                                                  child: Row(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      Icon(isPending ? Icons.hourglass_top_rounded : Icons.check_circle, color: isPending ? Colors.amberAccent : Colors.greenAccent, size: 18),
                                                      const SizedBox(width: 8),
                                                      Text(
                                                        isPending ? 'Reading Submitted • Pending Admin Approval' : 'Reading Approved & Verified',
                                                        style: TextStyle(color: isPending ? Colors.amberAccent : Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 12),
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
                                                  icon: const Icon(Icons.edit_note, color: Colors.white),
                                                  label: const Text('Open Reading Form', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                                  onPressed: () => _openApartmentReadingModal(context, apt),
                                                ),
                                              );
                                            }
                                          ),
                                        ],
                                      ),
                                      
                                      // Optional: Add a subtle overlay if submitted
                                      Builder(
                                        builder: (context) {
                                          final isSubmitted = apt['latest_submission_status'] == 'Pending' || apt['latest_submission_status'] == 'Approved';
                                          if (!isSubmitted) return const SizedBox.shrink();
                                          return Positioned.fill(
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: Colors.black.withOpacity(0.2),
                                                borderRadius: BorderRadius.circular(14),
                                              ),
                                            ),
                                          );
                                        }
                                      ),
                                    ],
                                  ),
                                );
                              },
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

  void _openApartmentReadingModal(BuildContext context, Map<String, dynamic> apt) {
    final aptCode = apt['apartment_code']?.toString() ?? apt['code']?.toString() ?? 'N/A';
    final prevReading = _toDouble(apt['last_reading'] ?? apt['subscription_prev_reading']);
    final tenantName = apt['tenant_name']?.toString() ?? 'Tenant';
    final aptId = apt['apartment_id'] ?? apt['id'];
    final subId = apt['subscription_id'] ?? apt['id'];
    final bName = _selectedBuilding?['name']?.toString() ?? 'Building';

    final readingCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    double consumption = 0.0;
    String? photoPath;
    bool isSubmitting = false;

    final subTypeStr = apt['subscription_type']?.toString().toLowerCase() ?? '';
    final isFixed = subTypeStr.contains('fixed');
    DateTime? selectedNextDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0B1121),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            void calculate(String val) {
              final curr = double.tryParse(val) ?? 0.0;
              setModalState(() {
                consumption = curr - prevReading;
              });
            }

            final currentVal = double.tryParse(readingCtrl.text.trim()) ?? 0.0;
            final hasInput = readingCtrl.text.trim().isNotEmpty;
            final isLower = !isFixed && hasInput && currentVal < prevReading;
            final canSubmit = isFixed ? (selectedNextDate != null) : (hasInput && !isLower);

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
                                        Text('Tenant: $tenantName', style: GoogleFonts.inter(color: Colors.blueGrey.shade300, fontSize: 12)),
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
                                  child: const Text('Fixed Monthly', style: TextStyle(color: Color(0xFF00D4AA), fontSize: 10, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            GestureDetector(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: selectedNextDate ?? DateTime.now().add(const Duration(days: 30)),
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                                );
                                if (picked != null) {
                                  setModalState(() => selectedNextDate = picked);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0D1620),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFF1D3347)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      selectedNextDate == null 
                                        ? 'Select Next Due Date' 
                                        : 'Next Due Date: ${DateFormat('yyyy-MM-dd').format(selectedNextDate!)}',
                                      style: TextStyle(color: selectedNextDate == null ? Colors.blueGrey : Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                                    ),
                                    const Icon(Icons.calendar_month, color: Colors.cyanAccent),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
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
                      MeterReaderHud(
                        buildingName: bName,
                        apartmentCode: aptCode,
                        tenantName: tenantName,
                        subscriptionType: apt['subscription_type']?.toString() ?? 'Meter',
                        previousReading: prevReading,
                        readingController: readingCtrl,
                        onChanged: calculate,
                        photoPath: photoPath,
                        onPhotoCaptured: (path) => setModalState(() => photoPath = path),
                      ),
                    ],

                    const SizedBox(height: 14),

                    TextField(
                      controller: notesCtrl,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        labelText: 'Observations / Notes (Optional)',
                        labelStyle: GoogleFonts.inter(color: Colors.blueGrey.shade400, fontSize: 12),
                        filled: true,
                        fillColor: const Color(0xFF060B10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),

                    const SizedBox(height: 20),

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
                                  if (isFixed && selectedNextDate == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select the next due date')));
                                    return;
                                  }
                                  if (!isFixed && readingCtrl.text.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please input current reading')));
                                    return;
                                  }
                                  if (isLower) {
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                      content: Text('Reading cannot be lower than baseline counter.'),
                                      backgroundColor: Colors.red,
                                    ));
                                    return;
                                  }
                                  if (photoPath == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please capture a photo as proof')));
                                    return;
                                  }

                                  setModalState(() => isSubmitting = true);
                                  final messenger = ScaffoldMessenger.of(context);

                                  try {
                                    final notes = isFixed 
                                        ? 'Next Due Date: ${DateFormat('yyyy-MM-dd').format(selectedNextDate!)}\n${notesCtrl.text.trim()}'
                                        : notesCtrl.text.trim();

                                    final currentReading = isFixed ? 0.0 : (double.tryParse(readingCtrl.text) ?? 0.0);
                                    final netConsumption = isFixed ? 0.0 : (currentReading - prevReading).clamp(0.0, 99999.0);

                                    final success = await SubscriptionApi.instance.submitSubscriptionReading({
                                      'apartment_id': aptId,
                                      'subscription_id': subId,
                                      'previous_reading': prevReading,
                                      'current_reading': currentReading,
                                      'consumption': netConsumption,
                                      'notes': notes,
                                      if (photoPath != null) 'meter_photo': photoPath,
                                    });

                                    if (context.mounted) {
                                      Navigator.pop(ctx);
                                      if (success) {
                                        messenger.showSnackBar(const SnackBar(content: Text('Apartment reading submitted for admin review ✓'), backgroundColor: Colors.green));
                                        if (_selectedBuilding != null) {
                                          ref.invalidate(buildingApartmentsProvider(_selectedBuilding!['id'].toString()));
                                        }
                                      } else {
                                        messenger.showSnackBar(const SnackBar(content: Text('Saved offline and queued for sync ✓'), backgroundColor: Colors.amber));
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
                                isFixed ? 'Confirm Subscription Due Date' : 'Submit Verified Reading',
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
