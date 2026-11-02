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
      padding: const EdgeInsets.all(18),
      decoration: AppTheme.glassCardDecoration(borderRadius: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppTheme.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: const Icon(
                  Icons.timeline_rounded,
                  size: 16,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Lifecycle Audit Timeline',
                style: GoogleFonts.outfit(
                  color: AppTheme.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: steps.length,
            itemBuilder: (context, index) {
              final step = steps[index];
              final isLast = index == steps.length - 1;

              final Color circleColor = step.isCompleted
                  ? AppTheme.primary
                  : (step.isCurrent ? AppTheme.accent : AppTheme.borderLight);

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: circleColor.withValues(alpha: 0.16),
                          shape: BoxShape.circle,
                          border: Border.all(color: circleColor, width: 1.8),
                          boxShadow: (step.isCompleted || step.isCurrent)
                              ? [
                                  BoxShadow(
                                    color: circleColor.withValues(alpha: 0.35),
                                    blurRadius: 8,
                                  ),
                                ]
                              : null,
                        ),
                        child: step.isCompleted
                            ? const Icon(Icons.check_rounded, size: 13, color: AppTheme.primary)
                            : (step.isCurrent
                                ? const Icon(Icons.bolt_rounded, size: 13, color: AppTheme.accent)
                                : null),
                      ),
                      if (!isLast)
                        Container(
                          width: 2,
                          height: 38,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: step.isCompleted
                                  ? [
                                      AppTheme.primary.withValues(alpha: 0.7),
                                      AppTheme.primary.withValues(alpha: 0.2),
                                    ]
                                  : [
                                      AppTheme.border,
                                      AppTheme.border.withValues(alpha: 0.3),
                                    ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  step.title,
                                  style: GoogleFonts.plusJakartaSans(
                                    color: step.isCompleted || step.isCurrent
                                        ? AppTheme.textPrimary
                                        : AppTheme.textMuted,
                                    fontWeight: step.isCurrent
                                        ? FontWeight.w700
                                        : FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              if (step.timestamp != null)
                                Text(
                                  step.timestamp!,
                                  style: GoogleFonts.plusJakartaSans(
                                    color: AppTheme.textMuted,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                            ],
                          ),
                          if (step.actorName != null) ...[
                            const SizedBox(height: 3),
                            Text(
                              'By ${step.actorName}',
                              style: GoogleFonts.plusJakartaSans(
                                color: AppTheme.accent,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                          if (step.notes != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              step.notes!,
                              style: GoogleFonts.plusJakartaSans(
                                color: AppTheme.textSecondary,
                                fontSize: 11.5,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
