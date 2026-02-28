import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/splash_controller.dart';

class SplashScreen extends GetView<SplashController> {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFAFAFA),
      body: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image(image: AssetImage("assets/images/logo.png")),
          ],
        ),
      ),
    );
  }
}
