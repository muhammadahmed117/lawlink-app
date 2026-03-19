import 'package:flutter/material.dart';
import 'screens/onboarding_screen.dart';

void main() {
  runApp(const LawLinkApp());
}

class LawLinkApp extends StatelessWidget {
  const LawLinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LawLink',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF0D1B2A),
        primaryColor: const Color(0xFFFF6B35),
        colorScheme: ColorScheme.fromSwatch().copyWith(
          secondary: const Color(0xFFFF6B35),
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
          titleMedium: TextStyle(
            color: Colors.white70,
            fontWeight: FontWeight.w300,
            fontSize: 16,
          ),
        ),
      ),
      home: const OnboardingScreen(),
    );
  }
}
