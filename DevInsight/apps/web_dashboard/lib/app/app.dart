import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../features/landing/presentation/pages/landing_page.dart';
import '../features/splash/presentation/pages/splash_page.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DevInsight',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primaryBlue),
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
      ),
      home: const SplashPage(),
      routes: {
        '/landing': (_) => const LandingPage(),
      },
    );
  }
}
