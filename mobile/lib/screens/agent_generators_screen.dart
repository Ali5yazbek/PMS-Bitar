import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_theme.dart';
import '../services/generator_api.dart';
import '../services/camera_service.dart';
import '../widgets/mobile/enterprise_mobile_scaffold.dart';

final generatorTasksProvider = FutureProvider<List<dynamic>>((ref) async {
  return await GeneratorApi.instance.getAssignedGenerators();
});

class AgentGeneratorsScreen extends ConsumerStatefulWidget {
  const AgentGeneratorsScreen({super.key});

  @override
  ConsumerState<AgentGeneratorsScreen> createState() => _AgentGeneratorsScreenState();
}

class _AgentGeneratorsScreenState extends ConsumerState<AgentGeneratorsScreen> with WidgetsBindingObserver {
  String? _selectedBuilding;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(generatorTasksProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final bool isLockedBefore7AM = now.hour < 7;
    final genAsync = ref.watch(generatorTasksProvider);

    return EnterpriseMobileScaffold(
      title: 'Building Generators',
      userRole: 'Agent',
      userName: 'Field Agent',
      currentTabIndex: 0,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(generatorTasksProvider);
          await ref.read(generatorTasksProvider.future);
        },
        color: AppTheme.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Building Selector Dropdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFF0D1620), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFF1D3347))),
                child: DropdownButtonHideUnderline(
                  child: genAsync.when(
                    loading: () => const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                    error: (_, __) => const Text('Error loading buildings', style: TextStyle(color: Colors.red)),
                    data: (list) {
                      final buildings = list
                          .map((g) => g['building_name']?.toString() ?? '')
                          .where((b) => b.isNotEmpty)
                          .toSet()
                          .toList();

                      if (buildings.isEmpty) {
                        return const Text('No assigned generators found', style: TextStyle(color: Colors.blueGrey));
                      }

                      if (_selectedBuilding == null || !buildings.contains(_selectedBuilding)) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) setState(() => _selectedBuilding = buildings.first);
                        });
                      }

                      return DropdownButton<String>(
                        value: buildings.contains(_selectedBuilding) ? _selectedBuilding : buildings.first,
                        dropdownColor: const Color(0xFF0D1620),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        isExpanded: true,
                        items: buildings.map((b) {
                          return DropdownMenuItem(value: b, child: Text('Building: $b'));
                        }).toList(),
                        onChanged: (val) => setState(() => _selectedBuilding = val),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Pre-7 AM Time Lock Banner
              if (isLockedBefore7AM)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade900.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.amber.shade600),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lock_clock, color: Colors.amber, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Task Locked Until 07:00 AM', style: GoogleFonts.outfit(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 14)),
                            Text('Daily generator readings unlock automatically at 7:00 AM every morning.', style: GoogleFonts.inter(color: Colors.amber.shade100, fontSize: 11)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              genAsync.when(
                loading: () => const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator(color: AppTheme.primary))),
                error: (e, _) => Center(child: Padding(padding: EdgeInsets.all(20), child: Text('Error: $e', style: const TextStyle(color: Colors.red)))),
                data: (list) {
                  if (list.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          children: [
                            Icon(Icons.power_off_outlined, color: AppTheme.textSecondary.withValues(alpha: 0.4), size: 64),
                            const SizedBox(height: 16),
                            Text('No active generators found in database.', style: GoogleFonts.inter(color: Colors.white, fontSize: 16)),
                          ],
                        ),
                      ),
                    );
                  }

                  final gen = list.firstWhere(
                    (g) => (g['building_name'] ?? '').toString().toLowerCase() == (_selectedBuilding ?? '').toLowerCase(),
                    orElse: () => list.first,
                  ) as Map<String, dynamic>;

                  final status = gen['status'] ?? 'Due';
                  if (status == 'Completed') {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          children: [
                            const Icon(Icons.check_circle_outline, color: Colors.green, size: 64),
                            const SizedBox(height: 16),
                            Text('Reading Submitted for Today', style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    );
                  }

                  return _buildGeneratorReadingForm(context, gen, isLockedBefore7AM);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGeneratorReadingForm(BuildContext context, Map<String, dynamic> gen, bool isLocked) {
    return _GeneratorFormWidget(key: ValueKey(gen['id']), gen: gen, isLocked: isLocked);
  }
}

class _GeneratorFormWidget extends ConsumerStatefulWidget {
  final Map<String, dynamic> gen;
  final bool isLocked;
  const _GeneratorFormWidget({super.key, required this.gen, required this.isLocked});

  @override
  ConsumerState<_GeneratorFormWidget> createState() => _GeneratorFormWidgetState();
}

class _GeneratorFormWidgetState extends ConsumerState<_GeneratorFormWidget> {
  late TextEditingController runningHoursCtrl;
  late TextEditingController fuelRemainingCtrl;
  late TextEditingController fuelAddedCtrl;
  late TextEditingController spareFuelCtrl;
  late TextEditingController notesCtrl;
  late TextEditingController hoursWorkedCtrl;
  List<String> photoList = [];
  bool _submittedLocally = false;
  String _inputMode = 'meter'; // 'meter', 'hours', 'both'

  @override
  void initState() {
    super.initState();
    final gen = widget.gen;
    final runningHours = gen['running_hours']?.toString() ?? '0';
    final fuelRemaining = gen['current_fuel']?.toString() ?? gen['fuel_remaining']?.toString() ?? '0';
    final spareFuel = gen['spare_fuel']?.toString() ?? '0';
    
    runningHoursCtrl = TextEditingController(text: runningHours);
    hoursWorkedCtrl = TextEditingController();
    fuelRemainingCtrl = TextEditingController(text: fuelRemaining);
    fuelAddedCtrl = TextEditingController(text: '0');
    spareFuelCtrl = TextEditingController(text: spareFuel);
    notesCtrl = TextEditingController();
  }

  @override
  void dispose() {
    runningHoursCtrl.dispose();
    hoursWorkedCtrl.dispose();
    fuelRemainingCtrl.dispose();
    fuelAddedCtrl.dispose();
    spareFuelCtrl.dispose();
    notesCtrl.dispose();
    super.dispose();
  }

  Widget _buildMetricChip(String label, String val) {
    if (val.trim().isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: const Color(0xFF060B10), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFF1D3347))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.blueGrey, fontSize: 10)),
          Text(val, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gen = widget.gen;
    final isLocked = widget.isLocked;
    final genName = gen['name']?.toString() ?? gen['generator_name']?.toString() ?? 'Generator';
    final lastReading = gen['updated_at']?.toString() ?? gen['last_reading_time']?.toString() ?? 'N/A';
    final rawStatus = (gen['status'] ?? gen['reading_status'] ?? '').toString();
    final bool isSubmitted = _submittedLocally ||
        rawStatus == 'Completed' ||
        rawStatus == 'Approved' ||
        rawStatus.toLowerCase().contains('pending') ||
        rawStatus.toLowerCase().contains('waiting') ||
        rawStatus == 'Submitted';

    if (isSubmitted) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF0D1620),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.orange.shade500.withValues(alpha: 0.6), width: 1.5),
          boxShadow: [
            BoxShadow(color: Colors.orange.withValues(alpha: 0.1), blurRadius: 16, spreadRadius: 2),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.hourglass_top_rounded, color: Colors.orangeAccent, size: 24),
                    const SizedBox(width: 10),
                    Text(genName, style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.orange.shade800, borderRadius: BorderRadius.circular(8)),
                  child: const Text('PENDING APPROVAL', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(color: Color(0xFF1D3347)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF060B10),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF1D3347)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lock_clock, color: Colors.amberAccent, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Reading saved & locked until Admin approves or rejects it.',
                      style: GoogleFonts.inter(color: Colors.blueGrey.shade200, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text('Submitted Reading Metrics:', style: GoogleFonts.inter(color: Colors.blueGrey.shade400, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _buildMetricChip('Running Hours', runningHoursCtrl.text),
                _buildMetricChip('Fuel Remaining', '${fuelRemainingCtrl.text} L'),
                _buildMetricChip('Fuel Added', '${fuelAddedCtrl.text} L'),
                _buildMetricChip('Spare Fuel', '${spareFuelCtrl.text} L'),
              ],
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1620),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1D3347)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(genName, style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: isLocked ? Colors.red.shade900.withValues(alpha: 0.4) : Colors.green.shade900.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(8)),
                child: Text(isLocked ? 'LOCKED' : 'READY', style: TextStyle(color: isLocked ? Colors.redAccent : Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          Text('Last Reading: $lastReading', style: TextStyle(color: Colors.blueGrey.shade400, fontSize: 11)),
          const SizedBox(height: 16),

          // Input Mode Selector
          Text('Logging Method', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildModeToggle('meter', 'Meter', Icons.speed_rounded, isLocked),
              const SizedBox(width: 8),
              _buildModeToggle('hours', 'Hours', Icons.timer_outlined, isLocked),
              const SizedBox(width: 8),
              _buildModeToggle('both', 'Both', Icons.layers_outlined, isLocked),
            ],
          ),
          const SizedBox(height: 16),

          // Inputs
          if (_inputMode == 'meter' || _inputMode == 'both')
            _buildFormInput('Generator Counter', runningHoursCtrl, isLocked, hintText: gen['last_meter_hours'] != null ? 'Previous: ${gen['last_meter_hours']}' : 'e.g. 1966.50'),
          if (_inputMode == 'hours' || _inputMode == 'both')
            _buildFormInput('Hours Worked Today', hoursWorkedCtrl, isLocked, hintText: 'Auto-calculated if blank'),

          _buildFormInput('Fuel Remaining (Dipstick Liters)', fuelRemainingCtrl, isLocked, hintText: 'e.g. 840'),
          _buildFormInput('Fuel Added (Liters)', fuelAddedCtrl, isLocked, hintText: 'e.g. 0'),
          _buildFormInput('Spare Fuel (Liters)', spareFuelCtrl, isLocked, hintText: 'e.g. 200'),
          _buildFormInput('Notes / Observations', notesCtrl, isLocked, isMultiline: true),

          const SizedBox(height: 16),
          Text('Photo Evidence (Camera / Gallery)', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),

          Row(
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF00A884)),
                icon: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                label: const Text('Camera', style: TextStyle(color: Colors.white)),
                onPressed: isLocked
                    ? null
                    : () async {
                        final base64 = await CameraService.instance.capturePhotoFromCamera();
                        if (base64 != null) {
                          setState(() => photoList.add(base64));
                        }
                      },
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                icon: const Icon(Icons.photo_library, size: 16, color: Color(0xFF00D4AA)),
                label: const Text('Gallery', style: TextStyle(color: Colors.white)),
                onPressed: isLocked
                    ? null
                    : () async {
                        final list = await CameraService.instance.pickMultipleFromGallery();
                        setState(() => photoList.addAll(list));
                      },
              ),
            ],
          ),

          if (photoList.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('✓ ${photoList.length} photos selected', style: const TextStyle(color: Colors.greenAccent, fontSize: 11)),
          ],

          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: isLocked ? Colors.grey : AppTheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.send, color: Colors.white),
              label: Text(isLocked ? 'Locked Before 07:00 AM' : 'Submit Generator Reading', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              onPressed: isLocked
                  ? null
                  : () async {
                      final fuelAdded = double.tryParse(fuelAddedCtrl.text) ?? 0.0;
                      final bool hasAnomaly = fuelAdded > 50;

                      if (hasAnomaly && photoList.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Anomaly Detected (Fuel > 50L). Photo evidence is required.'),
                          backgroundColor: Colors.red,
                        ));
                        return;
                      }

                      final messenger = ScaffoldMessenger.of(context);
                      try {
                        messenger.showSnackBar(const SnackBar(content: Text('Submitting...')));
                        await GeneratorApi.instance.submitGeneratorReading({
                          'building_id': gen['building_id'],
                          'building': gen['building_name'] ?? 'Generator',
                          'generator_id': gen['id'],
                          'generator': genName,
                          'input_method': _inputMode,
                          'submitted_hours': runningHoursCtrl.text,
                          'manual_hours': hoursWorkedCtrl.text,
                          'running_hours': runningHoursCtrl.text, // legacy support
                          'remaining_fuel': fuelRemainingCtrl.text,
                          'fuel_added': fuelAddedCtrl.text,
                          'spare_fuel': spareFuelCtrl.text,
                          'notes': notesCtrl.text,
                          'status': 'Pending Verification',
                        });
                        
                        if (mounted) {
                          messenger.hideCurrentSnackBar();
                          messenger.showSnackBar(const SnackBar(content: Text('Generator reading submitted ✓'), backgroundColor: Colors.green));
                          setState(() {
                            _submittedLocally = true;
                          });
                          ref.invalidate(generatorTasksProvider);
                        }
                      } catch (e) {
                        messenger.hideCurrentSnackBar();
                        messenger.showSnackBar(SnackBar(content: Text('Status: $e'), backgroundColor: Colors.amber));
                        if (mounted) {
                          setState(() {
                            _submittedLocally = true;
                          });
                          ref.invalidate(generatorTasksProvider);
                        }
                      }
                    },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormInput(String label, TextEditingController ctrl, bool disabled, {bool isMultiline = false, String? hintText}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 6),
            child: Text(
              label,
              style: TextStyle(color: Colors.blueGrey.shade300, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
          TextField(
            controller: ctrl,
            enabled: !disabled,
            maxLines: isMultiline ? 3 : 1,
            style: const TextStyle(color: Colors.white, fontSize: 15),
            keyboardType: isMultiline ? TextInputType.multiline : const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(color: Colors.blueGrey.shade600, fontSize: 14),
              filled: true,
              fillColor: disabled ? const Color(0xFF060B10) : const Color(0xFF0D1620),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1D3347))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1D3347))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF00D4AA), width: 1.5)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeToggle(String mode, String label, IconData icon, bool disabled) {
    final isSelected = _inputMode == mode;
    return Expanded(
      child: InkWell(
        onTap: disabled ? null : () => setState(() => _inputMode = mode),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primary.withValues(alpha: 0.14) : AppTheme.background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppTheme.primary : AppTheme.border,
              width: 1.0,
            ),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: GoogleFonts.inter(
                  color: isSelected ? AppTheme.textPrimary : AppTheme.textSecondary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
