import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Ambient canvas with continuous breathing light mesh spheres & parallax background support
class AmbientBackground extends StatefulWidget {
  final Widget child;
  final ScrollController? scrollController;

  const AmbientBackground({
    Key? key,
    required this.child,
    this.scrollController,
  }) : super(key: key);

  @override
  State<AmbientBackground> createState() => _AmbientBackgroundState();
}

class _AmbientBackgroundState extends State<AmbientBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _breathingController;
  late Animation<double> _breathingAnimation;
  double _scrollOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);

    _breathingAnimation = CurvedAnimation(
      parent: _breathingController,
      curve: Curves.easeInOutSine,
    );

    widget.scrollController?.addListener(_onScroll);
  }

  void _onScroll() {
    if (widget.scrollController != null && mounted) {
      setState(() {
        _scrollOffset = widget.scrollController!.offset * 0.15; // Parallax factor
      });
    }
  }

  @override
  void dispose() {
    widget.scrollController?.removeListener(_onScroll);
    _breathingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: AppTheme.backgroundDark,
      child: AnimatedBuilder(
        animation: _breathingAnimation,
        builder: (context, child) {
          final t = _breathingAnimation.value;
          final blueX = math.sin(t * math.pi * 2) * 35.0;
          final blueY = math.cos(t * math.pi * 2) * 25.0 - _scrollOffset;
          final amberX = math.cos(t * math.pi * 2) * 35.0;
          final amberY = math.sin(t * math.pi * 2) * 25.0 + _scrollOffset;

          final blueOpacity = 0.16 + (0.12 * t);
          final amberOpacity = 0.14 + (0.12 * (1.0 - t));

          return Stack(
            children: [
              // Top-Left Electric Blue Ambient Light Sphere (Drifting & Breathing)
              Positioned(
                top: -60 + blueY,
                left: -60 + blueX,
                child: Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.primaryAccent.withOpacity(blueOpacity),
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 85, sigmaY: 85),
                    child: const SizedBox(),
                  ),
                ),
              ),
              // Bottom-Right Warm Amber Ambient Light Sphere (Drifting & Breathing)
              Positioned(
                bottom: -60 - amberY,
                right: -60 - amberX,
                child: Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.secondaryAccent.withOpacity(amberOpacity),
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 85, sigmaY: 85),
                    child: const SizedBox(),
                  ),
                ),
              ),
              // Main Child Layer
              widget.child,
            ],
          );
        },
      ),
    );
  }
}

/// Frosted Glassmorphic Card Container with Animated Edge Light Sweeps
class GlassCard extends StatefulWidget {
  final Widget child;
  final double borderRadius;
  final double blur;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color? borderColor;
  final double borderWidth;
  final Color? backgroundColor;
  final List<BoxShadow>? shadows;
  final bool enableLightSweep;

  const GlassCard({
    Key? key,
    required this.child,
    this.borderRadius = 24.0,
    this.blur = 16.0,
    this.padding = const EdgeInsets.all(16.0),
    this.margin,
    this.borderColor,
    this.borderWidth = 1.2,
    this.backgroundColor,
    this.shadows,
    this.enableLightSweep = true,
  }) : super(key: key);

  @override
  State<GlassCard> createState() => _GlassCardState();
}

class _GlassCardState extends State<GlassCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _sweepController;

  @override
  void initState() {
    super.initState();
    _sweepController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    if (widget.enableLightSweep) {
      _sweepController.repeat();
    }
  }

  @override
  void dispose() {
    _sweepController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveBorderColor = widget.borderColor ?? Colors.white.withOpacity(0.18);
    final effectiveBgColor = widget.backgroundColor ?? Colors.white.withOpacity(0.08);

    return Container(
      margin: widget.margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        boxShadow: widget.shadows ?? AppTheme.glassShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: widget.blur, sigmaY: widget.blur),
          child: AnimatedBuilder(
            animation: _sweepController,
            builder: (context, child) {
              final sweepVal = _sweepController.value;
              final Alignment beginAlign = Alignment(-1.5 + (sweepVal * 3.0), -1.0);
              final Alignment endAlign = Alignment(-0.5 + (sweepVal * 3.0), 1.0);

              return Container(
                padding: widget.padding,
                decoration: BoxDecoration(
                  color: effectiveBgColor,
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  border: Border.all(
                    color: effectiveBorderColor,
                    width: widget.borderWidth,
                  ),
                  gradient: LinearGradient(
                    colors: [
                      effectiveBgColor,
                      Colors.white.withOpacity(widget.enableLightSweep ? 0.12 : 0.04),
                      effectiveBgColor.withOpacity(0.02),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                    begin: beginAlign,
                    end: endAlign,
                  ),
                ),
                child: widget.child,
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Neumorphic Soft UI Extruded Container with Squish Feedback & Shadow Cross-fade
class NeumorphicCard extends StatefulWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color? surfaceColor;
  final VoidCallback? onTap;
  final double distance;
  final double blurRadius;
  final Color? accentBorderColor;

  const NeumorphicCard({
    Key? key,
    required this.child,
    this.borderRadius = 22.0,
    this.padding = const EdgeInsets.all(16.0),
    this.margin,
    this.surfaceColor,
    this.onTap,
    this.distance = 5.0,
    this.blurRadius = 12.0,
    this.accentBorderColor,
  }) : super(key: key);

  @override
  State<NeumorphicCard> createState() => _NeumorphicCardState();
}

class _NeumorphicCardState extends State<NeumorphicCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.surfaceColor ?? AppTheme.surfaceNeumorphic;

    return GestureDetector(
      onTapDown: widget.onTap != null ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: widget.onTap != null
          ? (_) {
              setState(() => _isPressed = false);
              widget.onTap!();
            }
          : null,
      onTapCancel: widget.onTap != null ? () => setState(() => _isPressed = false) : null,
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 140),
        curve: _isPressed ? Curves.easeOutCubic : Curves.easeOutBack, // Spring physics
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeInOutCubic,
          margin: widget.margin,
          padding: widget.padding,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: Border.all(
              color: _isPressed
                  ? Colors.white.withOpacity(0.04)
                  : (widget.accentBorderColor ?? Colors.white.withOpacity(0.08)),
              width: 1.0,
            ),
            boxShadow: _isPressed
                ? AppTheme.neumorphicPressedShadows()
                : AppTheme.neumorphicShadows(
                    distance: widget.distance,
                    blurRadius: widget.blurRadius,
                  ),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

/// Glass-Neumorphic Hybrid Card (Frosted Glass + Dual Soft UI Extrusion)
class GlassNeumorphicCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color? borderColor;
  final VoidCallback? onTap;

  const GlassNeumorphicCard({
    Key? key,
    required this.child,
    this.borderRadius = 24.0,
    this.padding = const EdgeInsets.all(16.0),
    this.margin,
    this.borderColor,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: AppTheme.neumorphicShadows(distance: 6.0, blurRadius: 14.0),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(borderRadius),
              child: Container(
                padding: padding,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceNeumorphic.withOpacity(0.70),
                  borderRadius: BorderRadius.circular(borderRadius),
                  border: Border.all(
                    color: borderColor ?? Colors.white.withOpacity(0.18),
                    width: 1.2,
                  ),
                ),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Tactile 3D Extruded Neumorphic Button with Spring Physics & Shadow Cross-fade
class NeumorphicButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final Color? accentColor;
  final Color? surfaceColor;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final bool isGlowing;

  const NeumorphicButton({
    Key? key,
    required this.child,
    this.onPressed,
    this.accentColor,
    this.surfaceColor,
    this.borderRadius = 20.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    this.isGlowing = false,
  }) : super(key: key);

  @override
  State<NeumorphicButton> createState() => _NeumorphicButtonState();
}

class _NeumorphicButtonState extends State<NeumorphicButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final accent = widget.accentColor ?? AppTheme.primaryAccent;
    final bg = widget.surfaceColor ?? AppTheme.surfaceNeumorphic;

    List<BoxShadow> shadows;
    if (_isPressed) {
      shadows = AppTheme.neumorphicPressedShadows();
    } else if (widget.isGlowing) {
      shadows = [
        BoxShadow(
          color: accent.withOpacity(0.4),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
        ...AppTheme.neumorphicShadows(distance: 4.0, blurRadius: 10.0),
      ];
    } else {
      shadows = AppTheme.neumorphicShadows(distance: 4.0, blurRadius: 10.0);
    }

    return GestureDetector(
      onTapDown: widget.onPressed != null ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: widget.onPressed != null
          ? (_) {
              setState(() => _isPressed = false);
              widget.onPressed!();
            }
          : null,
      onTapCancel: widget.onPressed != null ? () => setState(() => _isPressed = false) : null,
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 140),
        curve: _isPressed ? Curves.easeOutCubic : Curves.easeOutBack, // Rubber snap spring physics
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeInOutCubic,
          padding: widget.padding,
          decoration: BoxDecoration(
            color: widget.isGlowing ? accent : bg,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: Border.all(
              color: widget.isGlowing
                  ? Colors.white.withOpacity(0.35)
                  : Colors.white.withOpacity(0.12),
              width: 1.2,
            ),
            boxShadow: shadows,
          ),
          child: Center(
            widthFactor: 1.0,
            heightFactor: 1.0,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// Round / Squircle Tactile Neumorphic Icon Button
class NeumorphicIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? iconColor;
  final Color? surfaceColor;
  final double size;
  final String? tooltip;

  const NeumorphicIconButton({
    Key? key,
    required this.icon,
    this.onPressed,
    this.iconColor,
    this.surfaceColor,
    this.size = 46.0,
    this.tooltip,
  }) : super(key: key);

  @override
  State<NeumorphicIconButton> createState() => _NeumorphicIconButtonState();
}

class _NeumorphicIconButtonState extends State<NeumorphicIconButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    Widget button = GestureDetector(
      onTapDown: widget.onPressed != null ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: widget.onPressed != null
          ? (_) {
              setState(() => _isPressed = false);
              widget.onPressed!();
            }
          : null,
      onTapCancel: widget.onPressed != null ? () => setState(() => _isPressed = false) : null,
      child: AnimatedScale(
        scale: _isPressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 130),
        curve: _isPressed ? Curves.easeOutCubic : Curves.easeOutBack,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeInOutCubic,
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: widget.surfaceColor ?? AppTheme.surfaceNeumorphic,
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withOpacity(0.12),
              width: 1.0,
            ),
            boxShadow: _isPressed
                ? AppTheme.neumorphicPressedShadows()
                : AppTheme.neumorphicShadows(distance: 3.5, blurRadius: 8.0),
          ),
          child: Icon(
            widget.icon,
            size: widget.size * 0.48,
            color: widget.iconColor ?? AppTheme.textPrimary,
          ),
        ),
      ),
    );

    if (widget.tooltip != null) {
      return Tooltip(message: widget.tooltip!, child: button);
    }
    return button;
  }
}

/// Neumorphic Filter Chip Pill with Smooth Selection Transition
class NeumorphicChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const NeumorphicChip({
    Key? key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeInOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryAccent : AppTheme.surfaceNeumorphic,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? Colors.white.withOpacity(0.4) : Colors.white.withOpacity(0.1),
            width: 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primaryAccent.withOpacity(0.45),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ]
              : AppTheme.neumorphicShadows(distance: 3.0, blurRadius: 8.0),
        ),
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : AppTheme.textSecondary,
          ),
          child: Text(label),
        ),
      ),
    );
  }
}

/// Inset / Debossed Soft UI Neumorphic Input Field
class NeumorphicTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData? prefixIcon;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;

  const NeumorphicTextField({
    Key? key,
    required this.controller,
    required this.hintText,
    this.prefixIcon,
    this.onChanged,
    this.onClear,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF14161E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
          width: 1.0,
        ),
        boxShadow: AppTheme.neumorphicPressedShadows(),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          if (prefixIcon != null) ...[
            Icon(
              prefixIcon,
              color: AppTheme.primaryAccent,
              size: 20,
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 14,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          if (controller.text.isNotEmpty && onClear != null)
            GestureDetector(
              onTap: onClear,
              child: Icon(
                Icons.close_rounded,
                color: AppTheme.textMuted,
                size: 18,
              ),
            ),
        ],
      ),
    );
  }
}

/// Staggered Entrance Animation Wrapper
class StaggeredEntrance extends StatefulWidget {
  final Widget child;
  final int index;
  final int baseDelayMs;
  final int stepDelayMs;

  const StaggeredEntrance({
    Key? key,
    required this.child,
    this.index = 0,
    this.baseDelayMs = 40,
    this.stepDelayMs = 60,
  }) : super(key: key);

  @override
  State<StaggeredEntrance> createState() => _StaggeredEntranceState();
}

class _StaggeredEntranceState extends State<StaggeredEntrance>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeAnim = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    final delay = widget.baseDelayMs + (widget.index * widget.stepDelayMs);
    Future.delayed(Duration(milliseconds: delay), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: widget.child,
      ),
    );
  }
}
