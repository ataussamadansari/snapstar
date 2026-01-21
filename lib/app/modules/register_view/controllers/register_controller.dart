import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RegisterController extends GetxController {
  final formKey = GlobalKey<FormState>();

  final usernameController = TextEditingController();
  final nameController = TextEditingController();
  final emailOrMobileController = TextEditingController();
  final passwordController = TextEditingController();

  void register() {
    if (!formKey.currentState!.validate()) return;

    final username = usernameController.text.trim();
    final name = nameController.text.trim();
    final emailOrMobile = emailOrMobileController.text.trim();
    final password = passwordController.text;

    // 🔥 yahin future me Firebase / API call jayega

    Get.snackbar(
      'Success',
      'Registered successfully!',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  @override
  void onClose() {
    usernameController.dispose();
    nameController.dispose();
    emailOrMobileController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
