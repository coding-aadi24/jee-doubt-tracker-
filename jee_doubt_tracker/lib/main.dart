import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const JeeDoubtTrackerApp());
}

class JeeDoubtTrackerApp extends StatelessWidget {
  const JeeDoubtTrackerApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppThemeMode>(
      valueListenable: AppTheme.activeThemeNotifier,
      builder: (context, mode, child) {
        return MaterialApp(
          title: 'JEE Doubt Vault',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.darkTheme,
          home: const SplashScreen(),
        );
      },
    );
  }
}
