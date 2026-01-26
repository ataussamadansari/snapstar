import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';

import '../controllers/splash_screen_controller.dart';

class SplashScreen extends GetView<SplashScreenController> {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Determine the file based on the theme
    // context.isDarkMode is a convenient GetX extension
    final lottieFile = context.isDarkMode
        ? "assets/lotties/blinkyzo.json" // Dark Mode
        : "assets/lotties/blinkyzo_2.json"; // Light Mode

    return Scaffold(
      body: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: Stack(
            children: [
              Positioned.fill(
                child: Center(
                  child: Lottie.asset(
                    lottieFile,
                    repeat: false,
                  ),
                ),
              ),
              const Positioned(
                bottom: 32,
                left: 0,
                right: 0,
                child: Center(child: CircularProgressIndicator()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
