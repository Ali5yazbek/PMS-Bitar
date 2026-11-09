import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/app_theme.dart';

class TimelineStep {
  final String title;
  final String? timestamp;
  final String? actorName;
  final bool isCompleted;
  final bool isCurrent;
  final String? notes;

  TimelineStep({
    required this.title,
    this.timestamp,
    this.actorName,
    this.isCompleted = false,
    this.isCurrent = false,
    this.notes,
  });
}

class AuditTimelineWidget extends StatelessWidget {
  final List<TimelineStep> steps;

  const AuditTimelineWidget({Key? key, required this.steps}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.timeline_rounded,
                size: 15,
                color: AppTheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Progress Timeline',
                style: GoogleFonts.inter(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Column(
            children: List.generate(steps.length, (index) {
              final step = steps[index];
              final isLast = index == steps.length - 1;

              final Color circleColor = step.isCompleted
                  ? AppTheme.success
                  : (step.isCurrent ? AppTheme.accent : AppTheme.borderLight);

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: circleColor.withValues(alpha: 0.14),
                          shape: BoxShape.circle,
                          border: Border.all(color: circleColor, width: 1.5),
                        ),
                        child: step.isCompleted
                            ? const Icon(Icons.check_rounded, size: 11, color: AppTheme.success)
                            : (step.isCurrent
                                ? const Icon(Icons.fiber_manual_record_rounded, size: 9, color: AppTheme.accent)
                                : null),
                      ),
                      if (!isLast)
                        Container(
                          width: 1.5,
                          height: 20,
                          color: step.isCompleted
                              ? AppTheme.success.withValues(alpha: 0.45)
                              : AppTheme.border,
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  step.title,
                                  style: GoogleFonts.inter(
                                    color: step.isCompleted || step.isCurrent
                                        ? AppTheme.textPrimary
                                        : AppTheme.textMuted,
                                    fontWeight: step.isCurrent
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ),
                              if (step.timestamp != null)
                                Text(
                                  step.timestamp!,
                                  style: GoogleFonts.inter(
                                    color: AppTheme.textMuted,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                            ],
                          ),
                          if (step.actorName != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              'By ${step.actorName}',
                              style: GoogleFonts.inter(
                                color: AppTheme.textSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                          if (step.notes != null) ...[
                            const SizedBox(height: 3),
                            Text(
                              step.notes!,
                              style: GoogleFonts.inter(
                                color: AppTheme.textSecondary,
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}
