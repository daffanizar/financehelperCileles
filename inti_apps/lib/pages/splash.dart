import 'dart:async';

import 'package:flutter/material.dart';
import 'package:inti_apps/pages/main_page.dart';
import 'package:inti_apps/pages/splash2.dart';

void main() {
  runApp(Splash());
}

class Splash extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: AnimatedSplashScreen(),
      // Set your main route or any other configurations here
    );
  }
}

class AnimatedSplashScreen extends StatefulWidget {
  @override
  _AnimatedSplashScreenState createState() => _AnimatedSplashScreenState();
}

class _AnimatedSplashScreenState extends State<AnimatedSplashScreen> {
  double opacity = 0.0;

  @override
  void initState() {
    super.initState();
    // Add a delay before starting the fade-in animation
    Timer(Duration(seconds: 2), () {
      setState(() {
        opacity = 1.0;
      });

      // Add a delay before navigating to the main screen
      Timer(Duration(seconds: 3), () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => Splash2()),
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: TweenAnimationBuilder(
          duration: Duration(seconds: 1),
          tween: Tween<double>(begin: 0.0, end: opacity),
          builder: (BuildContext context, double value, Widget? child) {
            return Opacity(
              opacity: value,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/logo_hima.png',
                      width: 200, height: 200), // Replace with your logo image
                  SizedBox(height: 16),
                  Text(
                    'HIMATIF FMIPA UNPAD',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
