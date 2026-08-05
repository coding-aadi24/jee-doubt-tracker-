import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_neumorphic_widgets.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppThemeMode>(
      valueListenable: AppTheme.activeThemeNotifier,
      builder: (context, currentMode, child) {
        return Scaffold(
          body: AmbientBackground(
            child: SafeArea(
              child: Column(
                children: [
                  // Top Glass Navigation Bar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: GlassCard(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      borderRadius: 22,
                      child: Row(
                        children: [
                          NeumorphicIconButton(
                            icon: Icons.arrow_back_rounded,
                            size: 38,
                            onPressed: () => Navigator.pop(context),
                          ),
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'App Theme Settings',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              Text(
                                'Customize color scheme & layout aesthetics',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Main Scrollable Theme Selector List
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.palette_rounded, color: AppTheme.primaryAccent, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Select Color Theme',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Choose your favorite color palette for EduSync:',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Render 5 Theme Options
                          ...AppThemeMode.values.map((mode) {
                            final themeData = AppTheme.themes[mode]!;
                            final isSelected = currentMode == mode;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 14.0),
                              child: GestureDetector(
                                onTap: () {
                                  AppTheme.activeThemeNotifier.value = mode;
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  curve: Curves.easeInOut,
                                  decoration: BoxDecoration(
                                    color: themeData.surfaceCard,
                                    borderRadius: BorderRadius.circular(22),
                                    border: Border.all(
                                      color: isSelected
                                          ? themeData.primaryAccent
                                          : AppTheme.textMuted.withOpacity(0.2),
                                      width: isSelected ? 2.5 : 1.0,
                                    ),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: themeData.primaryAccent.withOpacity(0.35),
                                              blurRadius: 16,
                                              spreadRadius: 1,
                                              offset: const Offset(0, 4),
                                            ),
                                          ]
                                        : AppTheme.neumorphicShadows(distance: 4, blurRadius: 10),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Row(
                                      children: [
                                        // Color Preview Swatch Badges
                                        Container(
                                          width: 52,
                                          height: 52,
                                          decoration: BoxDecoration(
                                            color: themeData.background,
                                            borderRadius: BorderRadius.circular(16),
                                            border: Border.all(
                                              color: themeData.primaryAccent.withOpacity(0.4),
                                              width: 1.5,
                                            ),
                                          ),
                                          child: Stack(
                                            alignment: Alignment.center,
                                            children: [
                                              Positioned(
                                                top: 8,
                                                left: 8,
                                                child: Container(
                                                  width: 18,
                                                  height: 18,
                                                  decoration: BoxDecoration(
                                                    color: themeData.primaryAccent,
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                              ),
                                              Positioned(
                                                bottom: 8,
                                                right: 8,
                                                child: Container(
                                                  width: 18,
                                                  height: 18,
                                                  decoration: BoxDecoration(
                                                    color: themeData.secondaryAccent,
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 16),

                                        // Theme Details Text
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Text(
                                                    themeData.name,
                                                    style: TextStyle(
                                                      fontSize: 15,
                                                      fontWeight: FontWeight.bold,
                                                      color: themeData.textPrimary,
                                                    ),
                                                  ),
                                                  if (mode == AppThemeMode.whiteOrange) ...[
                                                    const SizedBox(width: 8),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(
                                                          horizontal: 8, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: themeData.primaryAccent.withOpacity(0.18),
                                                        borderRadius: BorderRadius.circular(10),
                                                        border: Border.all(
                                                          color: themeData.primaryAccent.withOpacity(0.4),
                                                        ),
                                                      ),
                                                      child: Text(
                                                        'Default',
                                                        style: TextStyle(
                                                          fontSize: 10,
                                                          fontWeight: FontWeight.bold,
                                                          color: themeData.primaryAccent,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                themeData.description,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: themeData.textSecondary,
                                                  height: 1.3,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 12),

                                        // Selection Radio Checkmark
                                        Container(
                                          width: 26,
                                          height: 26,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: isSelected
                                                ? themeData.primaryAccent
                                                : Colors.transparent,
                                            border: Border.all(
                                              color: isSelected
                                                  ? themeData.primaryAccent
                                                  : themeData.textMuted.withOpacity(0.5),
                                              width: 2.0,
                                            ),
                                          ),
                                          child: isSelected
                                              ? const Icon(
                                                  Icons.check_rounded,
                                                  size: 16,
                                                  color: Colors.white,
                                                )
                                              : null,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
