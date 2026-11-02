import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_theme.dart';
import '../services/daily_report_api.dart';
import '../services/camera_service.dart';
import '../widgets/mobile/enterprise_mobile_scaffold.dart';

class AgentDailyReportScreen extends ConsumerStatefulWidget {
  const AgentDailyReportScreen({super.key});

  @override
  ConsumerState<AgentDailyReportScreen> createState() => _AgentDailyReportScreenState();
}

class _AgentDailyReportScreenState extends ConsumerState<AgentDailyReportScreen> {
  final _buildingCtrl = TextEditingController(text: 'Galaxy');
  final _visitedAptsCtrl = TextEditingController(text: 'A1, A2, A3, B4');
  final _startTimeCtrl = TextEditingController(text: '08:00 AM');
  final _endTimeCtrl = TextEditingController(text: '04:30 PM');
  final _tasksCompletedCtrl = TextEditingController(text: 'All generator & apartment meter readings verified.');
  final _issuesCtrl = TextEditingController(text: 'No major issues detected.');
  final _notesCtrl = TextEditingController();

  List<String> _evidencePhotos = [];

  @override
  void dispose() {
    _buildingCtrl.dispose();
    _visitedAptsCtrl.dispose();
    _startTimeCtrl.dispose();
    _endTimeCtrl.dispose();
    _tasksCompletedCtrl.dispose();
    _issuesCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return EnterpriseMobileScaffold(
      title: 'Submit Daily Report',
      userRole: 'Agent',
      userName: 'Field Agent',
      currentTabIndex: 0,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
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
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.assignment_turned_in, color: Color(0xFF00D4AA)),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Submit Daily Field Report', style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      Text('Location details, work summary & photo evidence.', style: TextStyle(color: Colors.blueGrey.shade400, fontSize: 11)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Location Details
              Text('Location & Shift Details', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              _buildInput('Primary Building', _buildingCtrl),
              _buildInput('Apartments Visited', _visitedAptsCtrl),
              Row(
                children: [
                  Expanded(child: _buildInput('Start Time', _startTimeCtrl)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildInput('End Time', _endTimeCtrl)),
                ],
              ),

              const SizedBox(height: 12),
              Text('Work Summary', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              _buildInput('Tasks Completed', _tasksCompletedCtrl, isMultiline: true),
              _buildInput('Issues / Anomaly Found', _issuesCtrl, isMultiline: true),
              _buildInput('General Notes', _notesCtrl, isMultiline: true),

              const SizedBox(height: 12),
              Text('Photo Evidence (Camera / Gallery)', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),

              Row(
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF00A884)),
                    icon: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                    label: const Text('Camera', style: TextStyle(color: Colors.white)),
                    onPressed: () async {
                      final base64 = await CameraService.instance.capturePhotoFromCamera();
                      if (base64 != null) {
                        setState(() => _evidencePhotos.add(base64));
                      }
                    },
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.photo_library, size: 16, color: Color(0xFF00D4AA)),
                    label: const Text('Gallery', style: TextStyle(color: Colors.white)),
                    onPressed: () async {
                      final list = await CameraService.instance.pickMultipleFromGallery();
                      setState(() => _evidencePhotos.addAll(list));
                    },
                  ),
                ],
              ),

              if (_evidencePhotos.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('✓ ${_evidencePhotos.length} evidence photos attached', style: const TextStyle(color: Colors.greenAccent, fontSize: 11)),
              ],

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.send, color: Colors.white),
                  label: const Text('Submit Daily Report Now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  onPressed: () async {
                    await DailyReportApi.instance.submitDailyReport({
                      'building': _buildingCtrl.text,
                      'visited_apartments': _visitedAptsCtrl.text,
                      'start_time': _startTimeCtrl.text,
                      'end_time': _endTimeCtrl.text,
                      'tasks_completed': _tasksCompletedCtrl.text,
                      'issues_found': _issuesCtrl.text,
                      'notes': _notesCtrl.text,
                      'photos': _evidencePhotos,
                      'timestamp': DateTime.now().toIso8601String(),
                    });

                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Daily Report queued for sync ✓')));
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInput(String label, TextEditingController ctrl, {bool isMultiline = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: ctrl,
        maxLines: isMultiline ? 3 : 1,
        style: const TextStyle(color: Colors.white, fontSize: 13),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.blueGrey.shade400, fontSize: 12),
          filled: true,
          fillColor: const Color(0xFF060B10),
          contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1D3347))),
        ),
      ),
    );
  }
}
