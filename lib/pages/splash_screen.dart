import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
import 'package:wall/auth/auth.dart';

class SplashScreen extends StatelessWidget {
  final int duration;
  const SplashScreen({super.key, required this.duration});

  @override
  Widget build(BuildContext context) {
    return AnimatedSplashScreen(
      duration: duration,
      splash: Image.asset('assets/images/test.png'),
      nextScreen: const AuthPage(),
      splashTransition: SplashTransition.fadeTransition,
      pageTransitionType: PageTransitionType.fade,
      backgroundColor: Colors.blue,
    );
  }
}
