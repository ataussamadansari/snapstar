import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:snapstar/app/data/repositories/auth_repository.dart';
import 'package:snapstar/app/data/services/storage_services.dart';
import 'package:snapstar/app/routes/app_routes.dart';

class RegisterController extends GetxController {
  final _auth = FirebaseAuth.instance;
  final storage = StorageServices.to;

  final AuthRepository _repository = AuthRepository();

  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final isLoading = false.obs;
  final hasError = false.obs;
  final errorMessage = ''.obs;
  final isPasswordHidden = true.obs;
  final isConfirmPasswordHidden = true.obs;

  // Focus Nodes
  final nameFocusNode = FocusNode();
  final emailFocusNode = FocusNode();
  final passwordFocusNode = FocusNode();
  final confirmPasswordFocusNode = FocusNode();

  // Toggles
  void togglePasswordVisibility() =>
      isPasswordHidden.value = !isPasswordHidden.value;

  void toggleConfirmPasswordVisibility() =>
      isConfirmPasswordHidden.value = !isConfirmPasswordHidden.value;

  Future<void> register() async {
    if (!formKey.currentState!.validate()) return;

    try {
      confirmPasswordFocusNode.unfocus();
      isLoading.value = true;
      hasError.value = false;
      errorMessage.value = "";

      // 1. Firebase Auth Signup
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
            email: emailController.text.trim(),
            password: passwordController.text,
          );

      // 2. Get ID Token
      String? token = await userCredential.user?.getIdToken();

      if (token != null) {
      storage.setToken(token);
      storage.setUserId(userCredential.user!.uid);

        // 3. Sync with Node.js Backend
        final response = await _repository.createProfile(
          name: nameController.text.trim(),
          email: emailController.text.trim(),
        );

        if (response.success == true) {
          Get.offAllNamed(Routes.setupProfile);
        }
      }
    } on FirebaseAuthException catch (e) {
      Get.snackbar('Error', e.message ?? 'Signup failed');
    } catch (e) {
      Get.snackbar('Error', 'Something went wrong');
    } finally {
      isLoading.value = false;
    }
  }

  String? validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();

    nameFocusNode.dispose();
    emailFocusNode.dispose();
    passwordFocusNode.dispose();
    confirmPasswordFocusNode.dispose();
    super.onClose();
  }
}
