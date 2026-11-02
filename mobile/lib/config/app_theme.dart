// ─── Luxury Obsidian & Royal Teal/Gold App Theme ──────────────────────────────
// Signature dark luxury design system with deep obsidian-emerald surfaces,
// frosted glass cards, glowing royal teal & gold accents, and crisp typography.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand & Luxury Accents
  static const Color primary = Color(0xFF00D4AA);       // Royal Emerald-Teal Glow
  static const Color primaryDark = Color(0xFF00A884);   // Deep Royal Teal
  static const Color primaryLight = Color(0xFF073B32);  // Deep Emerald Tint
  static const Color accent = Color(0xFFF5B041);        // Royal Warm Gold
  static const Color gold = Color(0xFFD4AF37);          // Metallic Gold

  // Status Colors
  static const Color success = Color(0xFF10B981);       // Emerald 500
  static const Color warning = Color(0xFFF59E0B);       // Amber 500
  static const Color danger = Color(0xFFF43F5E);        // Rose Crimson
  static const Color info = Color(0xFF06B6D4);          // Electric Cyan

  // Background & Obsidian Surfaces
  static const Color background = Color(0xFF060B10);    // Deep Obsidian Black-Teal
  static const Color surface = Color(0xFF0D1620);       // Frosted Obsidian Card
  static const Color surfaceHover = Color(0xFF142232);  // Elevated Obsidian Surface
  static const Color border = Color(0xFF1D3347);        // Subtle Teal-Obsidian Hairline
  static const Color borderLight = Color(0xFF284660);   // Highlighted Obsidian Border

  // Typography Colors
  static const Color textPrimary = Color(0xFFF8FAFC);   // Crisp Pearl White
  static const Color textSecondary = Color(0xFF8DA2B5); // Muted Silver-Slate
  static const Color textMuted = Color(0xFF5E748A);     // Deep Muted Slate

  // Reusable Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF00D4AA), Color(0xFF009677)],
  );

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF5B041), Color(0xFFD4AF37)],
  );

  static const LinearGradient obsidianCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF111E2C), Color(0xFF0B131C)],
  );

  static BoxDecoration glassCardDecoration({
    Color? borderColor,
    double borderRadius = 20,
    bool hasGlow = false,
  }) {
    return BoxDecoration(
      gradient: obsidianCardGradient,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: borderColor ?? border.withValues(alpha: 0.7),
        width: 1.0,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.4),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
        if (hasGlow)
          BoxShadow(
            color: (borderColor ?? primary).withValues(alpha: 0.12),
            blurRadius: 24,
            spreadRadius: 1,
          ),
      ],
    );
  }

  // The actual ThemeData object
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
          onPrimary: Color(0xFF04120E),
          onSecondary: Color(0xFF1A1102),
          onSurface: textPrimary,
          onError: Colors.white,
        ),

        // Typography based on Google Fonts (Plus Jakarta Sans / Outfit / Inter)
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
          headlineLarge: GoogleFonts.outfit(color: textPrimary, fontWeight: FontWeight.w800, letterSpacing: -0.5),
          headlineMedium: GoogleFonts.outfit(color: textPrimary, fontWeight: FontWeight.w700, letterSpacing: -0.3),
          headlineSmall: GoogleFonts.outfit(color: textPrimary, fontWeight: FontWeight.w700),
          titleLarge: GoogleFonts.outfit(color: textPrimary, fontWeight: FontWeight.w600),
          titleMedium: GoogleFonts.inter(color: textPrimary, fontWeight: FontWeight.w600),
          bodyLarge: GoogleFonts.inter(color: textPrimary, fontWeight: FontWeight.w400),
          bodyMedium: GoogleFonts.inter(color: textSecondary, fontWeight: FontWeight.w400),
          labelLarge: GoogleFonts.inter(color: textPrimary, fontWeight: FontWeight.w600),
          labelMedium: GoogleFonts.inter(color: textSecondary, fontWeight: FontWeight.w500),
          labelSmall: GoogleFonts.inter(color: textSecondary, fontWeight: FontWeight.w500),
        ),

        // App Bar Theme
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
          scrolledUnderElevation: 0,
          iconTheme: const IconThemeData(color: textPrimary),
          titleTextStyle: GoogleFonts.outfit(
            color: textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),

        // Card Theme
        cardTheme: CardThemeData(
          color: surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: border, width: 1),
          ),
        ),

        // Navigation Bar Theme
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: surface.withValues(alpha: 0.92),
          indicatorColor: primary.withValues(alpha: 0.18),
          elevation: 0,
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.w700, color: primary);
            }
            return GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: textSecondary);
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: primary, size: 24);
            }
            return const IconThemeData(color: textSecondary, size: 22);
          }),
        ),

        // Bottom Sheet Theme
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: Color(0xFF0A121A),
          modalBackgroundColor: Color(0xFF0A121A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          clipBehavior: Clip.antiAlias,
        ),

        // Dialog Theme
        dialogTheme: DialogThemeData(
          backgroundColor: const Color(0xFF0D1620),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: border, width: 1),
          ),
        ),

        // Button Theme
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: const Color(0xFF041511),
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: GoogleFonts.outfit(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              letterSpacing: 0.3,
            ),
          ),
        ),

        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: primary,
            side: const BorderSide(color: primary, width: 1.2),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: GoogleFonts.outfit(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),

        // Chip Theme
        chipTheme: ChipThemeData(
          backgroundColor: surface,
          selectedColor: primary.withValues(alpha: 0.2),
          side: const BorderSide(color: border),
          labelStyle: GoogleFonts.inter(color: textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),

        // Text Field Theme
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF091119),
          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: primary, width: 1.8),
          ),
          hintStyle: GoogleFonts.inter(color: textSecondary.withValues(alpha: 0.7), fontSize: 13),
          labelStyle: GoogleFonts.inter(color: textSecondary, fontSize: 13),
        ),

        // Divider Theme
        dividerTheme: const DividerThemeData(
          color: border,
          thickness: 1,
          space: 24,
        ),
      );
}

/// Ambient Luxury Obsidian Background with glowing Royal Teal & Gold light orbs
class AmbientLuxuryBackground extends StatelessWidget {
  final Widget child;

  const AmbientLuxuryBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base Deep Obsidian Gradient
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF04080C),
                  Color(0xFF08131C),
                  Color(0xFF050A0F),
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),
        ),
        // Top-right Royal Teal ambient aura
        Positioned(
          top: -110,
          right: -90,
          child: IgnorePointer(
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.primary.withValues(alpha: 0.13),
                    AppTheme.primary.withValues(alpha: 0.03),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),
        // Bottom-left Warm Royal Gold ambient aura
        Positioned(
          bottom: -120,
          left: -100,
          child: IgnorePointer(
            child: Container(
              width: 340,
              height: 340,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.accent.withValues(alpha: 0.09),
                    AppTheme.accent.withValues(alpha: 0.02),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),
        // Foreground content
        Positioned.fill(child: child),
      ],
    );
  }
}
