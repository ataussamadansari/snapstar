import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:snapstar/app/data/repositories/auth_repository.dart';
import 'package:snapstar/app/routes/app_routes.dart';

class RegisterController extends GetxController {
  final _auth = FirebaseAuth.instance;
  final _repository = AuthRepository();

  final formKey = GlobalKey<FormState>();
  final usernameController = TextEditingController();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final isLoading = false.obs;

  void register() async {
    if (!formKey.currentState!.validate()) return;

    try {
      isLoading.value = true;

      // 1. Firebase Auth Signup
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      // 2. Get ID Token
      String? token = await userCredential.user?.getIdToken();
      String? token1 = await _auth.currentUser?.getIdToken();

      if (token != null) {
        // 3. Sync with Node.js Backend
        /*await _repository.syncUser(
          token,
          usernameController.text.trim(),
          nameController.text.trim(),
        );*/

        debugPrint("SignUp: Token: $token \nToken1: $token1");

        Get.offAllNamed(Routes.main);
      }
    } on FirebaseAuthException catch (e) {
      Get.snackbar('Error', e.message ?? 'Signup failed');
    } catch (e) {
      Get.snackbar('Error', 'Something went wrong');
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    usernameController.dispose();
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
