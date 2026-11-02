import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../config/app_theme.dart';
import '../../services/camera_service.dart';

/// Ergonomic, high-contrast digital meter reading HUD tailored for field agents
/// working in low-light corridors, basements, and outdoor meter banks.
class MeterReaderHud extends StatelessWidget {
  final String buildingName;
  final String apartmentCode;
  final String tenantName;
  final String subscriptionType;
  final double previousReading;
  final double pricePerKwh;
  final TextEditingController readingController;
  final ValueChanged<String> onChanged;
  final String? photoPath;
  final ValueChanged<String?> onPhotoCaptured;
  final VoidCallback? onQuickAdd;

  const MeterReaderHud({
    super.key,
    required this.buildingName,
    required this.apartmentCode,
    required this.tenantName,
    required this.subscriptionType,
    required this.previousReading,
    this.pricePerKwh = 250.0,
    required this.readingController,
    required this.onChanged,
    required this.photoPath,
    required this.onPhotoCaptured,
    this.onQuickAdd,
  });

  String _formatNum(num val) {
    return NumberFormat('#,##0.0').format(val);
  }

  String _formatCurrency(num val) {
    return NumberFormat('#,##0').format(val);
  }

  @override
  Widget build(BuildContext context) {
    final currentVal = double.tryParse(readingController.text.trim()) ?? 0.0;
    final hasInput = readingController.text.trim().isNotEmpty;
    final delta = (currentVal - previousReading);
    final isLower = hasInput && currentVal < previousReading;
    final isSpike = hasInput && delta > 350.0;
    final estimatedCfa = (delta > 0 ? delta * pricePerKwh : 0.0).round();

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF060B10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isLower
              ? Colors.redAccent.withValues(alpha: 0.6)
              : (isSpike
                  ? Colors.amber.withValues(alpha: 0.6)
                  : Colors.cyan.withValues(alpha: 0.25)),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (isLower ? Colors.redAccent : (isSpike ? Colors.amber : Colors.cyan))
                .withValues(alpha: 0.08),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: Apartment & Tenant Identity ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.bolt, color: Colors.amber, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                'Apt $apartmentCode',
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            buildingName,
                            style: GoogleFonts.inter(
                              color: Colors.blueGrey.shade300,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tenant: $tenantName',
                      style: GoogleFonts.inter(
                        color: Colors.blueGrey.shade400,
                        fontSize: 11,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D1620),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF1D3347)),
                ),
                child: Text(
                  '${pricePerKwh.toInt()} CFA/kWh',
                  style: GoogleFonts.inter(
                    color: Colors.cyanAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── Digital Dual-Gauge HUD (High-Contrast for Dim Field Conditions) ──
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF030712), // Deep black-slate for maximum contrast
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF0D1620)),
            ),
            child: Row(
              children: [
                // Gauge A: Baseline / Previous Counter
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0B132B),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PREVIOUS / BASELINE',
                          style: GoogleFonts.inter(
                            color: Colors.blue.shade300,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            _formatNum(previousReading),
                            style: GoogleFonts.spaceMono(
                              color: Colors.blue.shade100,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          'kWh starting',
                          style: GoogleFonts.inter(color: Colors.blueGrey.shade400, fontSize: 9),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_rounded, color: Colors.blueGrey, size: 18),
                const SizedBox(width: 8),

                // Gauge B: New Current Reading Display
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                    decoration: BoxDecoration(
                      color: isLower
                          ? const Color(0xFF450A0A).withValues(alpha: 0.4)
                          : const Color(0xFF064E3B).withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isLower ? Colors.redAccent : const Color(0xFF34D399).withValues(alpha: 0.4),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'NEW READING',
                          style: GoogleFonts.inter(
                            color: isLower ? Colors.redAccent : Colors.greenAccent,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            hasInput ? _formatNum(currentVal) : '---.-',
                            style: GoogleFonts.spaceMono(
                              color: isLower ? Colors.redAccent : Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          'kWh counter',
                          style: GoogleFonts.inter(color: Colors.blueGrey.shade400, fontSize: 9),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Quick-Entry Digit Keypad / Input Box ──
          TextField(
            controller: readingController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: onChanged,
            style: GoogleFonts.spaceMono(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
            decoration: InputDecoration(
              labelText: 'Enter Current Meter Counter (kWh)',
              labelStyle: GoogleFonts.inter(color: Colors.blueGrey.shade300, fontSize: 13),
              hintText: 'e.g. ${_formatNum(previousReading + 50.0)}',
              hintStyle: GoogleFonts.spaceMono(color: Colors.blueGrey.shade600, fontSize: 14),
              filled: true,
              fillColor: const Color(0xFF0D1620),
              prefixIcon: const Icon(Icons.speed, color: Colors.cyanAccent),
              suffixText: 'kWh',
              suffixStyle: GoogleFonts.spaceMono(color: Colors.cyanAccent, fontWeight: FontWeight.bold),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Colors.cyanAccent, width: 1.5),
              ),
            ),
          ),

          // Quick Stepper helpers for field agent convenience
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Text(
                  'Quick Adjust:',
                  style: GoogleFonts.inter(color: Colors.blueGrey.shade400, fontSize: 11),
                ),
                const SizedBox(width: 8),
                for (final step in [5, 10, 50, 100])
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        final base = currentVal > 0 ? currentVal : previousReading;
                        final next = (base + step);
                        readingController.text = next.toStringAsFixed(1);
                        onChanged(readingController.text);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D1620),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF1D3347)),
                        ),
                        child: Text(
                          '+$step kWh',
                          style: GoogleFonts.spaceMono(
                            color: Colors.cyanAccent,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ── Live Calculation Strip: Delta & Est. Invoice Amount ──
          if (hasInput && !isLower) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF064E3B).withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.trending_up, color: Colors.greenAccent, size: 18),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Net Consumption', style: GoogleFonts.inter(color: Colors.blueGrey.shade300, fontSize: 10)),
                          Text(
                            '+${_formatNum(delta)} kWh',
                            style: GoogleFonts.spaceMono(
                              color: Colors.greenAccent,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(height: 24, width: 1, color: const Color(0xFF10B981).withValues(alpha: 0.2)),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Est. Usage Bill', style: GoogleFonts.inter(color: Colors.blueGrey.shade300, fontSize: 10)),
                      Text(
                        'CFA ${_formatCurrency(estimatedCfa)}',
                        style: GoogleFonts.outfit(
                          color: Colors.amberAccent,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],

          // ── Intelligent Safety Warnings ──
          if (isLower) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF450A0A).withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.cancel_rounded, color: Colors.redAccent, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Invalid reading: Counter (${_formatNum(currentVal)}) cannot be lower than the starting baseline (${_formatNum(previousReading)} kWh).',
                      style: GoogleFonts.inter(
                        color: Colors.red.shade200,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (isSpike) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF451A03).withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.amberAccent, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Notice: Consumption spike (+${_formatNum(delta)} kWh) exceeds typical threshold. Double check meter dial and photo.',
                      style: GoogleFonts.inter(
                        color: Colors.amber.shade200,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 14),

          // ── High-Definition Photo Proof Box ──
          if (photoPath != null) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF0D1620),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      width: 60,
                      height: 60,
                      child: _buildPhotoThumbnail(photoPath!),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.greenAccent, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              'Meter Photo Verified',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'Ready for admin submission',
                          style: GoogleFonts.inter(color: Colors.blueGrey.shade400, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.blueGrey.shade300,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    ),
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Retake', style: TextStyle(fontSize: 11)),
                    onPressed: () async {
                      final path = await CameraService.instance.capturePhotoFromCamera();
                      if (path != null) onPhotoCaptured(path);
                    },
                  ),
                ],
              ),
            ),
          ] else ...[
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D1620),
                  side: BorderSide(color: Colors.indigo.withValues(alpha: 0.5)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.camera_alt_rounded, color: Color(0xFF00D4AA)),
                label: Text(
                  'Capture Meter Counter Photo (Required)',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                onPressed: () async {
                  final path = await CameraService.instance.capturePhotoFromCamera();
                  if (path != null) onPhotoCaptured(path);
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPhotoThumbnail(String path) {
    try {
      if (path.startsWith('base64:')) {
        return Image.memory(
          base64Decode(path.substring(7)),
          fit: BoxFit.cover,
        );
      }
      return Image.file(
        File(path),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(Icons.image, color: Colors.blueGrey),
      );
    } catch (_) {
      return const Icon(Icons.image, color: Colors.blueGrey);
    }
  }
}
