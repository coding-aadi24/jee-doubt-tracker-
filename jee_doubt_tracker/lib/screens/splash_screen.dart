import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../theme/app_theme.dart';
import '../config/api_config.dart';
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

    // Real backend connectivity check
    http.get(Uri.parse(ApiConfig.uploadsUrl)).timeout(const Duration(seconds: 2)).then((res) {
      if (res.statusCode == 200 && mounted) {
        setState(() {
          _statusMessages[2] = 'Backend connected & verified!';
        });
      }
    }).catchError((_) {});

    _progressTimer = Timer.periodic(const Duration(milliseconds: stepMs), (timer) {
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
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: Stack(
          children: [
            // Electric Blue & Warm Amber Ambient Glow Orbs
            Positioned(
              top: -size.height * 0.1,
              right: -size.width * 0.15,
              child: Container(
                width: size.width * 0.75,
                height: size.width * 0.75,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primaryAccent.withOpacity(0.2),
                ),
              ),
            ),
            Positioned(
              bottom: -size.height * 0.1,
              left: -size.width * 0.15,
              child: Container(
                width: size.width * 0.75,
                height: size.width * 0.75,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.secondaryAccent.withOpacity(0.18),
                ),
              ),
            ),

            // Main Centered Glass Content (#1C1C1E Surface)
            SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Spacer(),

                      // Animated Logo Frame with #1C1C1E Glass Surface
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
                                  // Glow Aura
                                  Container(
                                    width: 160 * _auraPulseAnimation.value,
                                    height: 160 * _auraPulseAnimation.value,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppTheme.primaryAccent.withOpacity(0.35),
                                          blurRadius: 32,
                                          spreadRadius: 6,
                                        ),
                                      ],
                                    ),
                                  ),

                                  // #1C1C1E Glass Icon Card
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(32),
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                                      child: Container(
                                        width: 140,
                                        height: 140,
                                        decoration: BoxDecoration(
                                          color: AppTheme.surfaceGlassCard,
                                          borderRadius: BorderRadius.circular(32),
                                          border: Border.all(
                                            color: AppTheme.glassBorder,
                                            width: 1.5,
                                          ),
                                          boxShadow: AppTheme.glassShadow,
                                        ),
                                        padding: const EdgeInsets.all(16),
                                        child: Image.asset(
                                          'assets/images/app_icon.png',
                                          fit: BoxFit.contain,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Container(
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                gradient: RadialGradient(
                                                  colors: [
                                                    AppTheme.primaryAccent.withOpacity(0.3),
                                                    AppTheme.secondaryAccent.withOpacity(0.1),
                                                  ],
                                                ),
                                              ),
                                              child: const Icon(
                                                Icons.auto_stories_rounded,
                                                size: 56,
                                                color: AppTheme.primaryAccent,
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // App Title & Tagline (#F5F5F7 Text)
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Column(
                          children: [
                            Text(
                              'JEE DOUBT VAULT',
                              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textPrimary,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Collaborative PDF Question Organizer',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.textSecondary,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Spacer(),

                      // Glass Progress Container (#1C1C1E Surface)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceGlassCard,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: AppTheme.glassBorder),
                              boxShadow: AppTheme.glassShadow,
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _loadingStatus,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.textPrimary,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(
                                      '${(_progressValue * 100).toInt()}%',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primaryAccent,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: LinearProgressIndicator(
                                    value: _progressValue,
                                    minHeight: 6,
                                    backgroundColor: AppTheme.primaryAccent.withOpacity(0.15),
                                    valueColor: const AlwaysStoppedAnimation<Color>(
                                      AppTheme.primaryAccent,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
