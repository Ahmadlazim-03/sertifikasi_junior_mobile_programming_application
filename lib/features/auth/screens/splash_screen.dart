import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_java_project/core/theme.dart';
import 'package:flutter_java_project/routes/app_routes.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  // Animation controllers
  late AnimationController _controller;
  late Animation<double> _iconScaleAnimation;
  late Animation<double> _iconRotateAnimation;
  late Animation<double> _textOpacityAnimation;
  late Animation<double> _textSlideAnimation;
  late Animation<double> _backgroundGradientAnimation;
  
  // Particles for bakery-themed floating elements
  final List<Map<String, dynamic>> _particles = List.generate(
    15, 
    (index) => {
      'position': Offset(
        (index * 25) % 400, 
        (index * 30) % 800
      ),
      'size': (index % 3 + 1) * 8.0,
      'speed': (index % 3 + 1) * 1.5,
      'icon': index % 3 == 0 
        ? Icons.bakery_dining 
        : index % 3 == 1 
          ? Icons.breakfast_dining 
          : Icons.coffee,
      'opacity': 0.0,
    }
  );

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controller
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 2500),
    );
    
    // Icon animations
    _iconScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.2)
          .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.2, end: 1.0)
          .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 20,
      ),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: Interval(0.0, 0.6, curve: Curves.easeOut),
    ));
    
    _iconRotateAnimation = Tween<double>(
      begin: 0.0,
      end: 0.1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Interval(0.1, 0.5, curve: Curves.elasticInOut),
    ));
    
    // Text animations
    _textOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Interval(0.4, 0.8, curve: Curves.easeIn),
    ));
    
    _textSlideAnimation = Tween<double>(
      begin: 50.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Interval(0.4, 0.8, curve: Curves.easeOut),
    ));
    
    // Background gradient animation
    _backgroundGradientAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Interval(0.0, 1.0, curve: Curves.easeInOut),
    ));
    
    // Start animation
    _controller.forward();
    
    // Animate particles
    for (int i = 0; i < _particles.length; i++) {
      Future.delayed(Duration(milliseconds: 800 + (i * 100)), () {
        if (mounted) {
          setState(() {
            _particles[i]['opacity'] = 0.7;
          });
        }
      });
    }
    
    // Navigate to login screen after animation completes
    Timer(Duration(milliseconds: 3000), () {
      Navigator.of(context).pushReplacementNamed(AppRoutes.login);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    // Define our color scheme - same as login/register screens
    final primaryColor = Colors.amber[800]!;
    final secondaryColor = Color(0xFF8D6E63); // Brown color
    
    return Scaffold(
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color.lerp(
                    AppTheme.primaryColor,
                    primaryColor, 
                    _backgroundGradientAnimation.value
                  )!,
                  Color.lerp(
                    AppTheme.primaryColor.withOpacity(0.8),
                    secondaryColor, 
                    _backgroundGradientAnimation.value
                  )!,
                ],
              ),
              image: DecorationImage(
                image: AssetImage("assets/images/bread_bg.jpg"),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.6), 
                  BlendMode.darken
                ),
                opacity: _backgroundGradientAnimation.value,
              ),
            ),
            child: Stack(
              children: [
                // Animated particles
                ..._particles.map((particle) {
                  return AnimatedPositioned(
                    duration: Duration(milliseconds: 10000),
                    curve: Curves.easeInOut,
                    top: particle['position'].dy - (particle['speed'] * 100),
                    left: particle['position'].dx,
                    child: AnimatedOpacity(
                      duration: Duration(milliseconds: 1000),
                      opacity: particle['opacity'],
                      child: Icon(
                        particle['icon'],
                        size: particle['size'],
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  );
                }).toList(),
                
                // Main content
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Animated icon
                      Transform.scale(
                        scale: _iconScaleAnimation.value,
                        child: Transform.rotate(
                          angle: _iconRotateAnimation.value,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 15,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.bakery_dining,
                              size: 70,
                              color: primaryColor,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 30),
                      
                      // Animated text
                      Transform.translate(
                        offset: Offset(0, _textSlideAnimation.value),
                        child: Opacity(
                          opacity: _textOpacityAnimation.value,
                          child: Column(
                            children: [
                              Text(
                                'Toko Roti Bahagia',
                                style: GoogleFonts.pacifico(
                                  fontSize: 36,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      blurRadius: 10.0,
                                      color: Colors.black.withOpacity(0.3),
                                      offset: Offset(2.0, 2.0),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 10),
                              Text(
                                'Roti Segar Setiap Hari',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  color: Colors.white.withOpacity(0.9),
                                  fontWeight: FontWeight.w300,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      // Loading indicator
                      SizedBox(height: 50),
                      Opacity(
                        opacity: _textOpacityAnimation.value,
                        child: SizedBox(
                          width: 30,
                          height: 30,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
