import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:snapstar/app/routes/app_routes.dart';

class LoginController extends GetxController {
  final _auth = FirebaseAuth.instance;

  final formKey = GlobalKey<FormState>();
  final emailOrMobileController = TextEditingController();
  final passwordController = TextEditingController();

  // Observables
  final isPasswordHidden = true.obs;
  final isLoading = false.obs;

  // Toggle Password Visibility
  void togglePasswordVisibility() =>
      isPasswordHidden.value = !isPasswordHidden.value;

  void login() async {
    if (!formKey.currentState!.validate()) return;

    try {
      isLoading.value = true;

      // Firebase Login
      final userCred = await _auth.signInWithEmailAndPassword(
        email: emailOrMobileController.text.trim(),
        password: passwordController.text,
      );

      String? token = await userCred.user?.getIdToken();

      if (token != null) {
        // 3. Sync with Node.js Backend
        /*await _repository.syncUser(
          token,
          usernameController.text.trim(),
          nameController.text.trim(),
        );*/

        debugPrint("Login Token: $token");

        Get.offAllNamed(Routes.main);
      }
    } on FirebaseAuthException catch (e) {
      Get.snackbar('Login Failed', e.message ?? 'Check your credentials');
    } finally {
      isLoading.value = false;
    }
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
