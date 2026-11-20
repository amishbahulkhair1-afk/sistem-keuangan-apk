import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Colors - GoPay Signature Blue Palette
  static const Color primary = Color(0xFF0081A7); // GoPay Deep Blue
  static const Color primaryDark = Color(0xFF005F7A);
  static const Color primaryDarker = Color(0xFF004457);
  static const Color primaryLight = Color(0xFFE5F7FB); // GoPay Ice Blue
  static const Color primaryAccent = Color(0xFF00AED6); // GoPay Vibrant Electric Cyan-Blue

  // Secondary GoPay Accents
  static const Color gopayBlue = Color(0xFF0081A7);
  static const Color gopayCyan = Color(0xFF00AED6);
  static const Color gopayDarkBlue = Color(0xFF003049);

  // Backgrounds & Surfaces
  static const Color background = Color(0xFFF6F8FB); // Clean fintech light off-white
  static const Color surface = Colors.white;
  static const Color surfaceMuted = Color(0xFFEFF3F8); // Soft grey-blue
  static const Color cardBorder = Color(0xFFE5EBF2);

  // Text Colors
  static const Color textMain = Color(0xFF0B192C); // Deep navy-slate
  static const Color textBody = Color(0xFF1E3E62);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textLight = Color(0xFF94A3B8);

  // Semantic Colors - GoPay Signature
  static const Color income = Color(0xFF00AA13); // Gojek/GoPay vibrant green
  static const Color incomeBg = Color(0xFFEBF9ED);
  static const Color expense = Color(0xFFEE2737); // GoPay vibrant red
  static const Color expenseBg = Color(0xFFFDF0F1);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningBg = Color(0xFFFFFBEB);
  static const Color info = Color(0xFF0081A7); // Blue
  static const Color infoBg = Color(0xFFE5F7FB);
  static const Color purple = Color(0xFF8B5CF6);
  static const Color purpleBg = Color(0xFFF5F3FF);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF0081A7), Color(0xFF00AED6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient walletGradient = LinearGradient(
    colors: [Color(0xFF0077B6), Color(0xFF0096C7), Color(0xFF0081A7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient emeraldCardGradient = LinearGradient(
    colors: [Color(0xFF0081A7), Color(0xFF005F7A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient gopayHeaderGradient = LinearGradient(
    colors: [Color(0xFF0081A7), Color(0xFF00AED6)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Shadows
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: const Color(0xFF0081A7).withValues(alpha: 0.05),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: const Color(0xFF0F172A).withValues(alpha: 0.02),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get floatingShadow => [
        BoxShadow(
          color: const Color(0xFF0081A7).withValues(alpha: 0.10),
          blurRadius: 28,
          offset: const Offset(0, 10),
        ),
      ];

  static List<BoxShadow> glowShadow(Color color) => [
        BoxShadow(
          color: color.withValues(alpha: 0.25),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ];

  static ThemeData get lightTheme {
    final base = ThemeData.light();
    final textTheme = GoogleFonts.plusJakartaSansTextTheme(base.textTheme);

    return base.copyWith(
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      primaryColor: primary,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: primaryAccent,
        surface: surface,
      ),
      textTheme: textTheme.copyWith(
        displayLarge: textTheme.displayLarge?.copyWith(color: textMain, fontWeight: FontWeight.bold),
        titleLarge: textTheme.titleLarge?.copyWith(color: textMain, fontWeight: FontWeight.w700),
        titleMedium: textTheme.titleMedium?.copyWith(color: textMain, fontWeight: FontWeight.w600),
        bodyLarge: textTheme.bodyLarge?.copyWith(color: textBody),
        bodyMedium: textTheme.bodyMedium?.copyWith(color: textBody),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: textMain,
        centerTitle: false,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          color: textMain,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFE5EBF2), width: 1),
        ),
        color: surface,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        hintStyle: GoogleFonts.plusJakartaSans(color: textLight, fontSize: 14),
        labelStyle: GoogleFonts.plusJakartaSans(color: textMuted, fontSize: 14),
      ),
    );
  }
}
