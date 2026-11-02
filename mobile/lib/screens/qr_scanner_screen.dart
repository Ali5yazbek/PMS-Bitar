// ─── QR Scanner Screen ────────────────────────────────────────────────────────
// Uses mobile_scanner for native camera QR/barcode reading.
// Usage: push this route and await the result — returns the decoded string or null.
//
//   final result = await Navigator.push<String?>(context,
//     MaterialPageRoute(builder: (_) => const QrScannerScreen()));
//   if (result != null) { /* use decoded QR payload */ }

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_theme.dart';

class QrScannerScreen extends StatefulWidget {
  /// Optional hint shown below the viewfinder.
  final String hint;

  const QrScannerScreen({
    super.key,
    this.hint = 'Point the camera at the tenant\'s QR code',
  });

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  bool _hasScanned = false;
  bool _torchOn = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_hasScanned) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final value = barcodes.first.rawValue;
    if (value == null || value.isEmpty) return;

    _hasScanned = true;
    // Short haptic + pop with result
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(null),
        ),
        title: Text(
          'Scan QR Code',
          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _torchOn ? Icons.flashlight_off_rounded : Icons.flashlight_on_rounded,
              color: _torchOn ? AppTheme.warning : Colors.white,
            ),
            onPressed: () {
              setState(() => _torchOn = !_torchOn);
              _controller.toggleTorch();
            },
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios_rounded, color: Colors.white),
            onPressed: () => _controller.switchCamera(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Viewfinder ─────────────────────────────────────────────────
            Expanded(
              flex: 4,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  MobileScanner(
                    controller: _controller,
                    onDetect: _onDetect,
                  ),
                  // Overlay with cutout
                  CustomPaint(
                    painter: _ScannerOverlayPainter(
                      cutoutSize: MediaQuery.of(context).size.width * 0.72,
                    ),
                    child: const SizedBox.expand(),
                  ),
                  // Corner brackets on the cutout
                  _ScannerBrackets(
                    size: MediaQuery.of(context).size.width * 0.72,
                  ),
                ],
              ),
            ),

            // ── Hint section ───────────────────────────────────────────────
            Expanded(
              flex: 1,
              child: Container(
                width: double.infinity,
                color: AppTheme.background,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.qr_code_scanner_rounded,
                        color: AppTheme.primary, size: 32),
                    const SizedBox(height: 10),
                    Text(
                      widget.hint,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Overlay Painter — darkens everything outside the scan cutout ───────────────
class _ScannerOverlayPainter extends CustomPainter {
  final double cutoutSize;
  _ScannerOverlayPainter({required this.cutoutSize});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withOpacity(0.55);
    final cx = size.width / 2;
    final cy = size.height / 2;
    final half = cutoutSize / 2;

    // Draw four dark rectangles around the cutout
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, cy - half), paint);
    canvas.drawRect(Rect.fromLTWH(0, cy + half, size.width, size.height - cy - half), paint);
    canvas.drawRect(Rect.fromLTWH(0, cy - half, cx - half, cutoutSize), paint);
    canvas.drawRect(Rect.fromLTWH(cx + half, cy - half, size.width - cx - half, cutoutSize), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Corner Brackets ──────────────────────────────────────────────────────────
class _ScannerBrackets extends StatelessWidget {
  final double size;
  const _ScannerBrackets({required this.size});

  @override
  Widget build(BuildContext context) {
    const bracketLen = 28.0;
    const bracketThick = 4.0;
    const color = AppTheme.primary;
    const radius = Radius.circular(4);

    Widget corner(AlignmentGeometry alignment, BorderRadius borderRadius) {
      return Align(
        alignment: alignment,
        child: SizedBox(
          width: bracketLen,
          height: bracketLen,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border(
                top: borderRadius.topLeft != Radius.zero
                    ? const BorderSide(color: color, width: bracketThick)
                    : BorderSide.none,
                bottom: borderRadius.bottomLeft != Radius.zero
                    ? const BorderSide(color: color, width: bracketThick)
                    : BorderSide.none,
                left: borderRadius.topLeft != Radius.zero || borderRadius.bottomLeft != Radius.zero
                    ? const BorderSide(color: color, width: bracketThick)
                    : BorderSide.none,
                right: borderRadius.topRight != Radius.zero || borderRadius.bottomRight != Radius.zero
                    ? const BorderSide(color: color, width: bracketThick)
                    : BorderSide.none,
              ),
              borderRadius: borderRadius,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          corner(Alignment.topLeft, const BorderRadius.only(topLeft: radius)),
          corner(Alignment.topRight, const BorderRadius.only(topRight: radius)),
          corner(Alignment.bottomLeft, const BorderRadius.only(bottomLeft: radius)),
          corner(Alignment.bottomRight, const BorderRadius.only(bottomRight: radius)),
        ],
      ),
    );
  }
}
