import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:snapstar/app/data/repositories/user_repository.dart';
import 'package:snapstar/app/routes/app_routes.dart';

import '../../../core/utils/global_user_controller.dart';

class LoginController extends GetxController {
  final _auth = FirebaseAuth.instance;

  final UserRepository _repository = UserRepository();

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

      // 1. Firebase Login
      final userCred = await _auth.signInWithEmailAndPassword(
        email: emailOrMobileController.text.trim(),
        password: passwordController.text,
      );

      // 2. Fresh Token lijiye
      String? token = await userCred.user?.getIdToken();

      if (token != null) {
        // 3. Backend Sync
        final response = await _repository.check();

        if (response.success && response.data != null) {
          // Data update karein
          Get.find<GlobalUserController>().updateUserData(response.data!.data);

          // 4. Decision Logic (Ye perfect hai)
          if (response.data!.hasUsername == true) {
            Get.offAllNamed(Routes.main);
          } else {
            // Agar profile complete nahi hai toh setup par bhejega
            Get.offAllNamed(Routes.setupProfile);
          }
        } else {
          Get.snackbar(
            'Error',
            response.message,
          );
        }
      }

    } on FirebaseAuthException catch (e) {
      Get.snackbar('Login Failed', e.message ?? 'Check your credentials');
    } catch (e) {
      Get.snackbar('Error', 'Something went wrong');
    } finally {
      isLoading.value = false;
    }
  }

  /*void login() async {
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
        debugPrint("Login Token: $token");

        Get.offAllNamed(Routes.main);
      }
    } on FirebaseAuthException catch (e) {
      Get.snackbar('Login Failed', e.message ?? 'Check your credentials');
    } finally {
      isLoading.value = false;
    }
  }*/

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
