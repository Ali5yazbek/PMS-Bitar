import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../config/app_theme.dart';

class DateFilterBar extends StatelessWidget {
  final DateTimeRange? dateRange;
  final ValueChanged<DateTimeRange?> onChanged;
  
  const DateFilterBar({super.key, required this.dateRange, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final hasFilter = dateRange != null;
    
    String label = 'Filter by Date';
    if (hasFilter) {
      final start = DateFormat('MMM d, yyyy').format(dateRange!.start);
      final end = DateFormat('MMM d, yyyy').format(dateRange!.end);
      label = '$start - $end';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () async {
                final result = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                  initialDateRange: dateRange,
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: const ColorScheme.dark(
                          primary: AppTheme.primary,
                          onPrimary: Colors.white,
                          surface: AppTheme.surface,
                          onSurface: Colors.white,
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (result != null) {
                  onChanged(result);
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: hasFilter ? AppTheme.primary.withOpacity(0.15) : AppTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: hasFilter ? AppTheme.primary : AppTheme.surfaceHover),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_month_rounded, size: 20, color: hasFilter ? AppTheme.primary : AppTheme.textSecondary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        label,
                        style: GoogleFonts.inter(
                          color: hasFilter ? Colors.white : AppTheme.textSecondary,
                          fontWeight: hasFilter ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                    ),
                    if (hasFilter)
                      GestureDetector(
                        onTap: () => onChanged(null),
                        child: const Icon(Icons.close_rounded, size: 20, color: AppTheme.textSecondary),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
