// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_java_project/core/theme.dart';
import 'package:flutter_java_project/features/auth/screens/splash_screen.dart';
import 'package:flutter_java_project/routes/app_routes.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Toko Roti Bahagia',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}