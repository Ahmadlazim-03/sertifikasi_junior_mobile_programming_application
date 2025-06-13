// lib/features/auth/screens/splash_screen.dart
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_java_project/core/theme.dart';
import 'package:flutter_java_project/routes/app_routes.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(Duration(seconds: 3), () {
      Navigator.of(context).pushReplacementNamed(AppRoutes.login);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bakery_dining, size: 100, color: Colors.white),
            SizedBox(height: 20),
            Text(
              'Toko Roti Bahagia',
              style: GoogleFonts.pacifico(
                fontSize: 36,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}