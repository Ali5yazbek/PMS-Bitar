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
        accentColor = AppTheme.success;
        icon = Icons.check_circle_outline_rounded;
        break;
      case SyncStatusState.uploading:
        accentColor = AppTheme.accent;
        icon = Icons.sync_rounded;
        break;
      case SyncStatusState.offline:
        accentColor = AppTheme.danger;
        icon = Icons.cloud_off_rounded;
        break;
    }

    final cleanLabel = status.label.replaceAll('✓', '').trim();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: accentColor),
          const SizedBox(width: 5),
          Text(
            cleanLabel,
            style: GoogleFonts.inter(
              color: accentColor,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
