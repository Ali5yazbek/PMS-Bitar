// ─── App Theme ────────────────────────────────────────────────────────────────
// Modern, premium dark theme matching the React website

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand colors
  static const Color primary = Color(0xFF6366F1);      // Indigo 500
  static const Color primaryDark = Color(0xFF4F46E5);  // Indigo 600
  static const Color primaryLight = Color(0xFF312E81); // Indigo 900
  static const Color accent = Color(0xFF8B5CF6);       // Violet 500
  
  // Status Colors
  static const Color success = Color(0xFF10B981);      // Emerald 500
  static const Color warning = Color(0xFFF59E0B);      // Amber 500
  static const Color danger = Color(0xFFEF4444);       // Red 500
  static const Color info = Color(0xFF3B82F6);         // Blue 500

  // Background & Surface
  static const Color background = Color(0xFF0B1121);   // Very deep slate/blue
  static const Color surface = Color(0xFF151D30);      // Lighter slate for cards
  static const Color surfaceHover = Color(0xFF1E293B); // Even lighter for hover/selection

  // Typography Colors
  static const Color textPrimary = Color(0xFFF8FAFC);  // Crisp white
  static const Color textSecondary = Color(0xFF94A3B8);// Slate 400

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
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: textPrimary,
          onBackground: textPrimary,
          onError: Colors.white,
        ),
        
        // Typography based on Google Fonts (Inter)
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
          headlineLarge: GoogleFonts.inter(color: textPrimary, fontWeight: FontWeight.w700),
          headlineMedium: GoogleFonts.inter(color: textPrimary, fontWeight: FontWeight.w600),
          headlineSmall: GoogleFonts.inter(color: textPrimary, fontWeight: FontWeight.w600),
          titleLarge: GoogleFonts.inter(color: textPrimary, fontWeight: FontWeight.w600),
          titleMedium: GoogleFonts.inter(color: textPrimary, fontWeight: FontWeight.w500),
          bodyLarge: GoogleFonts.inter(color: textPrimary, fontWeight: FontWeight.w400),
          bodyMedium: GoogleFonts.inter(color: textSecondary, fontWeight: FontWeight.w400),
          labelLarge: GoogleFonts.inter(color: textPrimary, fontWeight: FontWeight.w600),
        ),

        // App Bar Theme
        appBarTheme: AppBarTheme(
          backgroundColor: surface.withOpacity(0.9), // Glass effect later
          elevation: 0,
          centerTitle: true,
          scrolledUnderElevation: 0,
          iconTheme: const IconThemeData(color: textPrimary),
          titleTextStyle: GoogleFonts.inter(
            color: textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),



        // Button Theme
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ),

        // Text Field Theme
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: background,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF1E293B)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF1E293B)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primary, width: 2),
          ),
          hintStyle: GoogleFonts.inter(color: textSecondary),
          labelStyle: GoogleFonts.inter(color: textSecondary),
        ),

        // Divider Theme
        dividerTheme: const DividerThemeData(
          color: Color(0xFF1E293B),
          thickness: 1,
          space: 24,
        ),
      );
}
