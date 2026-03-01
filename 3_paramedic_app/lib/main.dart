import 'package:flutter/material.dart';
import 'screens/paramedic_dashboard.dart';

void main() {
  runApp(const LifeLinkApp());
}

class LifeLinkApp extends StatelessWidget {
  const LifeLinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LifeLink Paramedic Console',
      theme: ThemeData(
        primarySwatch: Colors.red,
        scaffoldBackgroundColor: Colors.grey[100],
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFC62828), // Deep emergency red
          foregroundColor: Colors.white,
          elevation: 4,
        ),
      ),
      home: const ParamedicDashboard(),
      debugShowCheckedModeBanner: false, // Hides the annoying "DEBUG" banner for your presentation!
    );
  }
}