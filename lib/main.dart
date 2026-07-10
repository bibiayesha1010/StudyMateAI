import 'package:flutter/material.dart';
import 'screens/welcome_screen.dart';

void main() {
  runApp(const StudyMateAI());
}

class StudyMateAI extends StatelessWidget {
  const StudyMateAI({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      title: "StudyMateAI",

      home: const WelcomeScreen(),
    );
  }
}