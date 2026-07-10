import 'package:flutter/material.dart';

import 'package:studymate_ai/themes/app_theme.dart';
import 'package:studymate_ai/routes/app_routes.dart';
import 'package:studymate_ai/screens/splash_screen.dart';

class StudyMateAI extends StatelessWidget {
  const StudyMateAI({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "StudyMateAI",

      debugShowCheckedModeBanner: false,

      theme: AppTheme.lightTheme,

      initialRoute: AppRoutes.splash,

      routes: {
        AppRoutes.splash: (context) => const SplashScreen(),
      },
    );
  }
}