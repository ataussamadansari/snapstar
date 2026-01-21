import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:snapstar/app/routes/app_routes.dart';

class LoginController extends GetxController {
  final formKey = GlobalKey<FormState>();

  final emailOrMobileController = TextEditingController();
  final passwordController = TextEditingController();

  // Observables
  final isPasswordHidden = true.obs;
  final isLoading = false.obs;


  // Toggle Password Visibility
  void togglePasswordVisibility() =>
      isPasswordHidden.value = !isPasswordHidden.value;

  void login() {
    if (!formKey.currentState!.validate()) return;

    isLoading.value = true;

    // 🔥 yahin Firebase Auth / API call aayega
    Future.delayed(const Duration(seconds: 1), () {
      isLoading.value = false;
      // Get.snackbar('Success', 'Logged in successfully!');
      Get.offAllNamed(Routes.main);
    });
  }

  void navigateToSignUpScreen() {
    Get.toNamed(Routes.register);
  }

  @override
  void onClose() {
    emailOrMobileController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
