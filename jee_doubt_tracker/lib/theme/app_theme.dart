import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // User Specified iOS Dark Color Palette:
  // Surface: #1C1C1E | Text: #F5F5F7 | Primary Accent: #0A84FF | Secondary Accent: #FF9F0A
  
  static const Color backgroundDark = Color(0xFF0A0A0C);      // Deep Apple OLED Obsidian Black
  static const Color surfaceDark = Color(0xFF1C1C1E);         // Apple Dark Surface (#1C1C1E)
  static const Color surfaceGlassCard = Color(0xCC1C1C1E);     // Translucent Dark Glass Surface (#1C1C1E at 80% opacity)
  static const Color surfaceCard = Color(0xFF2C2C2E);          // Elevated Secondary Surface (#2C2C2E)
  
  static const Color primaryAccent = Color(0xFF0A84FF);        // Apple Electric Blue Primary Accent (#0A84FF)
  static const Color primaryOrange = Color(0xFF0A84FF);        // Alias for compatibility
  static const Color primaryViolet = Color(0xFF0A84FF);        // Alias for compatibility
  static const Color primaryPurple = Color(0xFF5E5CE6);        // iOS Indigo Accent
  
  static const Color secondaryAccent = Color(0xFFFF9F0A);      // Apple Warm Amber Secondary Accent (#FF9F0A)
  static const Color accentAmber = Color(0xFFFF9F0A);          // Alias for compatibility
  static const Color accentGold = Color(0xFFFFD60A);           // Apple Gold Accent
  static const Color accentCyan = Color(0xFF64D2FF);           // Apple Light Cyan Accent
  
  static const Color textPrimary = Color(0xFFF5F5F7);          // Apple Platinum Text (#F5F5F7)
  static const Color textSecondary = Color(0xFF8E8E93);        // Subtitle Apple Neutral Gray
  static const Color textMuted = Color(0xFF636366);            // Muted Dark Gray

  // Glassmorphic iOS Borders & Shadows
  static Color glassBorder = Colors.white.withOpacity(0.12);
  static Color glassBlueBorder = const Color(0x400A84FF);
  
  static List<BoxShadow> glassShadow = [
    BoxShadow(
      color: const Color(0x250A84FF),
      blurRadius: 24,
      spreadRadius: 0,
      offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.4),
      blurRadius: 12,
      spreadRadius: 0,
      offset: const Offset(0, 4),
    ),
  ];

  // Electric Blue to Warm Amber Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryAccent, Color(0xFF0066CC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [secondaryAccent, Color(0xFFFF7A00)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [backgroundDark, surfaceDark, Color(0xFF141416)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient logoAuraGradient = LinearGradient(
    colors: [
      Color(0x600A84FF),
      Color(0x30FF9F0A),
      Color(0x101C1C1E),
      Color(0x000A0A0C),
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static ThemeData get darkTheme {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: backgroundDark,
      primaryColor: primaryAccent,
      colorScheme: const ColorScheme.dark(
        primary: primaryAccent,
        secondary: secondaryAccent,
        surface: surfaceDark,
      ),
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: GoogleFonts.outfit(
          color: textPrimary,
          fontSize: 32,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
        titleLarge: GoogleFonts.outfit(
          color: textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: GoogleFonts.outfit(
          color: textPrimary,
          fontSize: 16,
        ),
        bodyMedium: GoogleFonts.outfit(
          color: textSecondary,
          fontSize: 14,
        ),
      ),
    );
  }

  // Alias getters for full compatibility
  static ThemeData get lightTheme => darkTheme;
}
