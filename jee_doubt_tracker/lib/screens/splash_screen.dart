import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../theme/app_theme.dart';
import '../config/api_config.dart';
import '../widgets/glass_neumorphic_widgets.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _auraController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _auraPulseAnimation;

  double _progressValue = 0.0;
  Timer? _progressTimer;
  String _loadingStatus = 'Initializing doubt engine...';

  final List<String> _statusMessages = [
    'Initializing doubt engine...',
    'Loading physics & math modules...',
    'Connecting to shared batch library...',
    'Syncing chapter PDF collections...',
    'Ready for study!',
  ];

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeOutBack,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeIn,
    );

    _auraController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _auraPulseAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _auraController, curve: Curves.easeInOut),
    );

    _logoController.forward();
    _startSimulatedLoading();
  }

  void _startSimulatedLoading() {
    const totalDurationMs = 2400;
    const stepMs = 50;
    final totalSteps = totalDurationMs ~/ stepMs;
    int currentStep = 0;

    // Backend connectivity check
    http.get(Uri.parse(ApiConfig.uploadsUrl)).timeout(const Duration(seconds: 2)).then((res) {
      if (res.statusCode == 200 && mounted) {
        setState(() {
          _statusMessages[2] = 'Backend connected & verified!';
        });
      }
    }).catchError((_) {});

    _progressTimer = Timer.periodic(const Duration(milliseconds: stepMs), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      currentStep++;
      setState(() {
        _progressValue = (currentStep / totalSteps).clamp(0.0, 1.0);
        int messageIndex = ((_progressValue * (_statusMessages.length - 1)).floor()).clamp(0, _statusMessages.length - 1);
        _loadingStatus = _statusMessages[messageIndex];
      });

      if (currentStep >= totalSteps) {
        _progressTimer?.cancel();
        _navigateToHome();
      }
    });
  }

  void _navigateToHome() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const HomeScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  void dispose() {
    _logoController.dispose();
    _auraController.dispose();
    _progressTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AmbientBackground(
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),

                  // Animated Glass-Neumorphic Logo
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: AnimatedBuilder(
                        animation: _auraPulseAnimation,
                        builder: (context, child) {
                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              // Pulsing Neumorphic Light Aura
                              Container(
                                width: 170 * _auraPulseAnimation.value,
                                height: 170 * _auraPulseAnimation.value,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.primaryAccent.withOpacity(0.35),
                                      blurRadius: 36,
                                      spreadRadius: 8,
                                    ),
                                    BoxShadow(
                                      color: AppTheme.secondaryAccent.withOpacity(0.20),
                                      blurRadius: 42,
                                      spreadRadius: 12,
                                    ),
                                  ],
                                ),
                              ),

                              // Frosted Glass Neumorphic Icon Container
                              GlassNeumorphicCard(
                                borderRadius: 36,
                                padding: const EdgeInsets.all(22),
                                borderColor: Colors.white.withOpacity(0.25),
                                child: SizedBox(
                                  width: 90,
                                  height: 90,
                                  child: Image.asset(
                                    'assets/images/app_icon.png',
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: RadialGradient(
                                            colors: [
                                              AppTheme.primaryAccent.withOpacity(0.4),
                                              AppTheme.secondaryAccent.withOpacity(0.15),
                                            ],
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.auto_stories_rounded,
                                          size: 54,
                                          color: AppTheme.primaryAccent,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 36),

                  // App Title & Subtitle Badge
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: [
                        Text(
                          'JEE DOUBT VAULT',
                          style: Theme.of(context).textTheme.displayLarge?.copyWith(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.textPrimary,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.15),
                              width: 1.0,
                            ),
                          ),
                          child: Text(
                            'Collaborative PDF Question Organizer',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Neumorphic Soft UI Progress Card
                  NeumorphicCard(
                    borderRadius: 24,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                    surfaceColor: AppTheme.surfaceNeumorphic.withOpacity(0.85),
                    distance: 6.0,
                    blurRadius: 16.0,
                    accentBorderColor: Colors.white.withOpacity(0.12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                _loadingStatus,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '${(_progressValue * 100).toInt()}%',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryAccent,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Debossed Inner Track for Progress Bar
                        Container(
                          height: 8,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color(0xFF121319),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: AppTheme.neumorphicPressedShadows(),
                          ),
                          child: Stack(
                            children: [
                              FractionallySizedBox(
                                widthFactor: _progressValue,
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    gradient: AppTheme.primaryGradient,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.primaryAccent.withOpacity(0.5),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
