import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum AppThemeMode {
  whiteOrange,    // Default: White & Orange
  darkObsidian,   // Dark Obsidian & Electric Blue
  midnightPurple, // Midnight Purple & Neon Violet
  freshMint,      // Fresh Mint & Emerald Green
  goldVault,      // Gold Vault & Luxury Gold
}

class AppThemeData {
  final String name;
  final String description;
  final Color background;
  final Color surfaceDark;
  final Color surfaceNeumorphic;
  final Color surfaceCard;
  final Color primaryAccent;
  final Color secondaryAccent;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color lightShadow;
  final Color darkShadow;

  const AppThemeData({
    required this.name,
    required this.description,
    required this.background,
    required this.surfaceDark,
    required this.surfaceNeumorphic,
    required this.surfaceCard,
    required this.primaryAccent,
    required this.secondaryAccent,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.lightShadow,
    required this.darkShadow,
  });
}

class AppTheme {
  static final ValueNotifier<AppThemeMode> activeThemeNotifier =
      ValueNotifier<AppThemeMode>(AppThemeMode.whiteOrange);

  static final Map<AppThemeMode, AppThemeData> themes = {
    AppThemeMode.whiteOrange: const AppThemeData(
      name: 'White & Orange (Default)',
      description: 'Clean bright canvas with vibrant orange primary accents',
      background: Color(0xFFF3F5F7), // Softer, cooler light gray
      surfaceDark: Color(0xFFE2E6EB),
      surfaceNeumorphic: Color(0xFFF3F5F7), // Match background for seamless neumorphism
      surfaceCard: Color(0xFFFFFFFF), // Pure white for floating cards
      primaryAccent: Color(0xFFFF6B00), // Vibrant but refined orange
      secondaryAccent: Color(0xFFFF9F1C), // Warm amber secondary
      textPrimary: Color(0xFF1E293B), // Deep slate for high contrast readability
      textSecondary: Color(0xFF64748B),
      textMuted: Color(0xFF94A3B8),
      lightShadow: Color(0xFFFFFFFF),
      darkShadow: Color(0xFFD4D9E2), // Very subtle, well-blended dark shadow
    ),
    AppThemeMode.darkObsidian: const AppThemeData(
      name: 'Dark Obsidian',
      description: 'Deep obsidian dark mode with electric blue highlights',
      background: Color(0xFF0F111A), // Very deep blue-tinted black
      surfaceDark: Color(0xFF171A26),
      surfaceNeumorphic: Color(0xFF131520),
      surfaceCard: Color(0xFF1E2233),
      primaryAccent: Color(0xFF3B82F6), // Premium electric blue
      secondaryAccent: Color(0xFF0EA5E9), // Cyan-blue secondary
      textPrimary: Color(0xFFF8FAFC),
      textSecondary: Color(0xFF94A3B8),
      textMuted: Color(0xFF475569),
      lightShadow: Color(0x19FFFFFF), // Very subtle light reflection
      darkShadow: Color(0x9905060A), // Deep, soft shadow
    ),
    AppThemeMode.midnightPurple: const AppThemeData(
      name: 'Midnight Purple',
      description: 'Cosmic purple night aesthetic with neon violet vibes',
      background: Color(0xFF130E1F),
      surfaceDark: Color(0xFF1D152F),
      surfaceNeumorphic: Color(0xFF171126),
      surfaceCard: Color(0xFF231A38),
      primaryAccent: Color(0xFFA855F7), // Smooth neon purple
      secondaryAccent: Color(0xFFD946EF), // Fuchsia pink secondary
      textPrimary: Color(0xFFFAF5FF),
      textSecondary: Color(0xFFA894C7),
      textMuted: Color(0xFF6E5E8A),
      lightShadow: Color(0x14E9D5FF),
      darkShadow: Color(0x9908050D),
    ),
    AppThemeMode.freshMint: const AppThemeData(
      name: 'Fresh Mint',
      description: 'Refreshing light mint theme with emerald green tones',
      background: Color(0xFFF0FDF4), // Very soft mint white
      surfaceDark: Color(0xFFDCFCE7),
      surfaceNeumorphic: Color(0xFFF0FDF4),
      surfaceCard: Color(0xFFFFFFFF),
      primaryAccent: Color(0xFF10B981), // Vibrant emerald
      secondaryAccent: Color(0xFF06B6D4), // Cyan secondary
      textPrimary: Color(0xFF064E3B), // Deep forest green for text
      textSecondary: Color(0xFF047857),
      textMuted: Color(0xFF6EE7B7),
      lightShadow: Color(0xFFFFFFFF),
      darkShadow: Color(0xFFD1E6D9), // Soft minty shadow
    ),
    AppThemeMode.goldVault: const AppThemeData(
      name: 'Gold Vault',
      description: 'Luxurious charcoal background infused with metallic gold',
      background: Color(0xFF18181B), // Zinc/Charcoal dark
      surfaceDark: Color(0xFF27272A),
      surfaceNeumorphic: Color(0xFF1C1C1F),
      surfaceCard: Color(0xFF2C2C30),
      primaryAccent: Color(0xFFF59E0B), // Premium gold
      secondaryAccent: Color(0xFFFCD34D), // Light gold
      textPrimary: Color(0xFFFFFBEB),
      textSecondary: Color(0xFFD4D4D8),
      textMuted: Color(0xFF71717A),
      lightShadow: Color(0x0FFFFF7ED), // Warm light reflection
      darkShadow: Color(0xCC09090B),
    ),
  };

  static AppThemeData get current => themes[activeThemeNotifier.value]!;

  static Color get backgroundDark => current.background;
  static Color get surfaceDark => current.surfaceDark;
  static Color get surfaceNeumorphic => current.surfaceNeumorphic;
  static Color get surfaceGlassCard => current.background.withOpacity(0.35);
  static Color get surfaceGlassDark => current.surfaceDark.withOpacity(0.85);
  static Color get surfaceCard => current.surfaceCard;

  static Color get primaryAccent => current.primaryAccent;
  static Color get primaryOrange => current.primaryAccent;
  static Color get primaryViolet => current.primaryAccent;
  static Color get primaryPurple => current.primaryAccent;

  static Color get secondaryAccent => current.secondaryAccent;
  static Color get accentAmber => current.secondaryAccent;
  static Color get accentGold => current.secondaryAccent;
  static Color get accentCyan => current.primaryAccent;
  static Color get accentEmerald => current.primaryAccent;

  static Color get textPrimary => current.textPrimary;
  static Color get textSecondary => current.textSecondary;
  static Color get textMuted => current.textMuted;

  static Color get glassBorder => current.primaryAccent.withOpacity(0.25);
  static Color get glassBlueBorder => current.primaryAccent.withOpacity(0.40);
  static Color get glassAmberBorder => current.secondaryAccent.withOpacity(0.40);

  static List<BoxShadow> get glassShadow => [
        BoxShadow(
          color: current.primaryAccent.withOpacity(0.20),
          blurRadius: 28,
          spreadRadius: 0,
          offset: const Offset(0, 10),
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.15),
          blurRadius: 16,
          spreadRadius: 0,
          offset: const Offset(0, 6),
        ),
      ];

  static List<BoxShadow> neumorphicShadows({
    double distance = 5.0,
    double blurRadius = 12.0,
    Color? lightHighlight,
    Color? darkShadow,
  }) {
    return [
      BoxShadow(
        color: lightHighlight ?? current.lightShadow,
        offset: Offset(-distance, -distance),
        blurRadius: blurRadius,
      ),
      BoxShadow(
        color: darkShadow ?? current.darkShadow,
        offset: Offset(distance, distance),
        blurRadius: blurRadius,
      ),
    ];
  }

  static List<BoxShadow> neumorphicPressedShadows({
    Color? lightHighlight,
    Color? darkShadow,
  }) {
    return [
      BoxShadow(
        color: darkShadow ?? current.darkShadow.withOpacity(0.5),
        offset: const Offset(2, 2),
        blurRadius: 4,
      ),
      BoxShadow(
        color: lightHighlight ?? current.lightShadow.withOpacity(0.5),
        offset: const Offset(-2, -2),
        blurRadius: 4,
      ),
    ];
  }

  static LinearGradient get glassGradient => LinearGradient(
        colors: [
          current.surfaceCard.withOpacity(0.85),
          current.surfaceNeumorphic.withOpacity(0.65),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get glassDarkGradient => LinearGradient(
        colors: [
          current.surfaceDark.withOpacity(0.85),
          current.background.withOpacity(0.75),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get primaryGradient => LinearGradient(
        colors: [current.primaryAccent, current.secondaryAccent],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get secondaryGradient => LinearGradient(
        colors: [current.secondaryAccent, current.primaryAccent],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get backgroundGradient => LinearGradient(
        colors: [current.background, current.surfaceDark],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );

  static LinearGradient get logoAuraGradient => LinearGradient(
        colors: [
          current.primaryAccent.withOpacity(0.4),
          current.secondaryAccent.withOpacity(0.2),
          Colors.transparent,
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomRight,
      );

  static ThemeData get darkTheme {
    final isLight = current.background.computeLuminance() > 0.5;
    final baseTheme = isLight ? ThemeData.light() : ThemeData.dark();

    return baseTheme.copyWith(
      scaffoldBackgroundColor: current.background,
      primaryColor: current.primaryAccent,
      colorScheme: (isLight ? const ColorScheme.light() : const ColorScheme.dark()).copyWith(
        primary: current.primaryAccent,
        secondary: current.secondaryAccent,
        surface: current.surfaceDark,
      ),
      textTheme: GoogleFonts.outfitTextTheme(baseTheme.textTheme).copyWith(
        displayLarge: GoogleFonts.outfit(
          color: current.textPrimary,
          fontSize: 32,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
        titleLarge: GoogleFonts.outfit(
          color: current.textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: GoogleFonts.outfit(
          color: current.textPrimary,
          fontSize: 16,
        ),
        bodyMedium: GoogleFonts.outfit(
          color: current.textSecondary,
          fontSize: 14,
        ),
      ),
    );
  }

  static ThemeData get lightTheme => darkTheme;
}
