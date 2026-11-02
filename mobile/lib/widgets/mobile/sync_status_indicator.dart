import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/app_theme.dart';
import '../../core/network/request_queue.dart';

class SyncStatusIndicator extends StatelessWidget {
  final SyncStatusInfo status;

  const SyncStatusIndicator({Key? key, required this.status}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color accentColor;
    IconData icon;

    switch (status.state) {
      case SyncStatusState.synchronized:
        accentColor = AppTheme.primary;
        icon = Icons.verified_rounded;
        break;
      case SyncStatusState.uploading:
        accentColor = AppTheme.accent;
        icon = Icons.cloud_sync_rounded;
        break;
      case SyncStatusState.offline:
        accentColor = AppTheme.danger;
        icon = Icons.wifi_off_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.35),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.12),
            blurRadius: 10,
            spreadRadius: -2,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: accentColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.8),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Icon(icon, size: 12, color: accentColor),
          const SizedBox(width: 4),
          Text(
            status.label,
            style: GoogleFonts.plusJakartaSans(
              color: accentColor,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
