// ─── Enterprise Architectural Design System (AppTheme) ────────────────────────
// Human-crafted, high-contrast dark slate palette with refined emerald-teal
// and warm amber accents, crisp 1px hairlines, and balanced typography.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Core Brand & Semantic Accents ──────────────────────────────────────────
  static const Color primary = Color(0xFF14B8A6);       // Refined Teal 500
  static const Color primaryDark = Color(0xFF0D9488);   // Deep Teal 600
  static const Color primaryLight = Color(0xFF2DD4BF);  // Teal 400 Accent
  static const Color secondary = Color(0xFF8B5CF6);     // Violet 500 Accent
  static const Color accent = Color(0xFFF59E0B);        // Warm Amber 500
  static const Color gold = Color(0xFFD97706);          // Rich Amber 600

  // ── Semantic Status Palette ────────────────────────────────────────────────
  static const Color success = Color(0xFF10B981);       // Emerald 500
  static const Color warning = Color(0xFFF59E0B);       // Amber 500
  static const Color danger = Color(0xFFEF4444);        // Red 500
  static const Color info = Color(0xFF3B82F6);          // Blue 500

  // ── Architectural Slate Surfaces & Borders ─────────────────────────────────
  static const Color background = Color(0xFF090D14);    // Deep Slate-Obsidian Canvas
  static const Color surface = Color(0xFF111722);       // Primary Card Surface
  static const Color surfaceHover = Color(0xFF17202E);  // Elevated / Interactive Surface
  static const Color border = Color(0xFF1E293B);        // Crisp Slate Hairline Border
  static const Color borderLight = Color(0xFF2D3D54);   // Subtle Highlight Border

  // ── Typography Hierarchy Colors ────────────────────────────────────────────
  static const Color textPrimary = Color(0xFFF8FAFC);   // Slate 50
  static const Color textSecondary = Color(0xFF94A3B8); // Slate 400
  static const Color textMuted = Color(0xFF64748B);     // Slate 500

  // ── Subtle Gradients (Used Sparingly for Primary CTAs & Accents) ───────────
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF14B8A6), Color(0xFF0D9488)],
  );

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
  );

  static const LinearGradient obsidianCardGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF131A26), Color(0xFF101620)],
  );

  /// Clean, architectural card decoration with crisp 1px border and subtle elevation.
  static BoxDecoration glassCardDecoration({
    Color? borderColor,
    double borderRadius = 16,
    bool hasGlow = false,
  }) {
    return BoxDecoration(
      color: surface,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: borderColor ?? border,
        width: 1.0,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.22),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ],
    );
  }

  /// Section header with a clean vertical accent indicator and optional trailing widget.
  static Widget sectionHeader(
    String title, {
    String? subtitle,
    Color indicatorColor = primary,
    Widget? trailing,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              Container(
                width: 3.5,
                height: 16,
                decoration: BoxDecoration(
                  color: indicatorColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  title,
                  style: GoogleFonts.outfit(
                    color: textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (subtitle != null && subtitle.isNotEmpty) ...[
                const SizedBox(width: 8),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    color: textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  // ── Material 3 ThemeData ───────────────────────────────────────────────────
  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: background,
        primaryColor: primary,
        colorScheme: const ColorScheme.dark(
          primary: primary,
          secondary: accent,
          surface: surface,
          error: danger,
          onPrimary: Color(0xFF041512),
          onSecondary: Color(0xFF1C1102),
          onSurface: textPrimary,
          onError: Colors.white,
        ),

        // Consistent Typography System
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
          headlineLarge: GoogleFonts.outfit(
            color: textPrimary,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
          headlineMedium: GoogleFonts.outfit(
            color: textPrimary,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
          headlineSmall: GoogleFonts.outfit(
            color: textPrimary,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
          titleLarge: GoogleFonts.outfit(
            color: textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
          titleMedium: GoogleFonts.inter(
            color: textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
          bodyLarge: GoogleFonts.inter(
            color: textPrimary,
            fontWeight: FontWeight.w400,
            fontSize: 14,
          ),
          bodyMedium: GoogleFonts.inter(
            color: textSecondary,
            fontWeight: FontWeight.w400,
            fontSize: 13,
          ),
          labelLarge: GoogleFonts.inter(
            color: textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          labelMedium: GoogleFonts.inter(
            color: textSecondary,
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
          labelSmall: GoogleFonts.inter(
            color: textMuted,
            fontWeight: FontWeight.w500,
            fontSize: 11,
          ),
        ),

        // AppBar Theme
        appBarTheme: AppBarTheme(
          backgroundColor: background,
          elevation: 0,
          centerTitle: false,
          scrolledUnderElevation: 0,
          iconTheme: const IconThemeData(color: textPrimary, size: 20),
          titleTextStyle: GoogleFonts.outfit(
            color: textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),

        // Card Theme
        cardTheme: CardThemeData(
          color: surface,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: border, width: 1),
          ),
        ),

        // Navigation Bar Theme
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: surface,
          indicatorColor: primary.withValues(alpha: 0.14),
          elevation: 0,
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: primary);
            }
            return GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: textSecondary);
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: primary, size: 22);
            }
            return const IconThemeData(color: textSecondary, size: 20);
          }),
        ),

        // Bottom Sheet Theme
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: surface,
          modalBackgroundColor: surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            side: BorderSide(color: border, width: 1),
          ),
          clipBehavior: Clip.antiAlias,
        ),

        // Dialog Theme
        dialogTheme: DialogThemeData(
          backgroundColor: surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: border, width: 1),
          ),
          titleTextStyle: GoogleFonts.outfit(
            color: textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
          contentTextStyle: GoogleFonts.inter(
            color: textSecondary,
            fontSize: 13.5,
            height: 1.45,
          ),
        ),

        // SnackBar Theme
        snackBarTheme: SnackBarThemeData(
          backgroundColor: surfaceHover,
          contentTextStyle: GoogleFonts.inter(
            color: textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: borderLight, width: 1),
          ),
        ),

        // Elevated Button Theme
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: const Color(0xFF041512),
            disabledBackgroundColor: surfaceHover,
            disabledForegroundColor: textMuted,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              letterSpacing: 0.1,
            ),
          ),
        ),

        // Outlined Button Theme
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: textPrimary,
            side: const BorderSide(color: borderLight, width: 1),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              fontSize: 13.5,
            ),
          ),
        ),

        // Text Button Theme
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            textStyle: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),

        // Chip Theme
        chipTheme: ChipThemeData(
          backgroundColor: surface,
          selectedColor: primary.withValues(alpha: 0.16),
          side: const BorderSide(color: border),
          labelStyle: GoogleFonts.inter(color: textPrimary, fontSize: 12, fontWeight: FontWeight.w500),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),

        // Input Decoration Theme
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF0C111A),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primary, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: danger, width: 1.2),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: danger, width: 1.5),
          ),
          hintStyle: GoogleFonts.inter(color: textMuted, fontSize: 13),
          labelStyle: GoogleFonts.inter(color: textSecondary, fontSize: 13),
        ),

        // Divider Theme
        dividerTheme: const DividerThemeData(
          color: border,
          thickness: 1,
          space: 20,
        ),
      );
}

/// Clean, lightweight architectural background container.
/// Avoids floating neon radial orbs for a distraction-free professional interface.
class AmbientLuxuryBackground extends StatelessWidget {
  final Widget child;

  const AmbientLuxuryBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppTheme.background,
      child: child,
    );
  }
}
