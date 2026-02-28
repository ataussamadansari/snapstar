import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/signup_controller.dart';

class SignupScreen extends GetView<SignupController> {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: controller.formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  const SizedBox(height: 40),

                  /// TITLE
                  const Text(
                    "Create Account",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    "Join SnapStar and start sharing moments",
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),

                  const SizedBox(height: 32),

                  /// NAME
                  _inputField(
                    controller: controller.nameCtrl,
                    label: "Name",
                    icon: Icons.person_outline,
                    validator: (v) =>
                    v == null || v.trim().isEmpty ? "Name is required" : null,
                  ),

                  const SizedBox(height: 16),

                  /// EMAIL
                  _inputField(
                    controller: controller.emailCtrl,
                    label: "Email",
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return "Email is required";
                      }
                      if (!GetUtils.isEmail(v.trim())) {
                        return "Enter valid email";
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  /// PASSWORD
                  Obx(() => _inputField(
                    controller: controller.passCtrl,
                    label: "Password",
                    icon: Icons.lock_outline,
                    obscure: controller.hidePassword.value,
                    suffixIcon: IconButton(
                      icon: Icon(
                        controller.hidePassword.value
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: controller.togglePassword,
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return "Password required";
                      }
                      if (v.length < 6) {
                        return "Minimum 6 characters";
                      }
                      return null;
                    },
                  )),

                  const SizedBox(height: 16),

                  /// CONFIRM PASSWORD
                  Obx(() => _inputField(
                    controller: controller.cPassCtrl,
                    label: "Confirm Password",
                    icon: Icons.lock_outline,
                    obscure: controller.hideCPassword.value,
                    suffixIcon: IconButton(
                      icon: Icon(
                        controller.hideCPassword.value
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: controller.toggleCPassword,
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return "Confirm password required";
                      }
                      if (v != controller.passCtrl.text) {
                        return "Passwords do not match";
                      }
                      return null;
                    },
                  )),

                  const SizedBox(height: 30),

                  /// BUTTON
                  Obx(() => SizedBox(
                    height: 50,
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: controller.isLoading.value
                          ? null
                          : controller.submit,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: controller.isLoading.value
                          ? const CircularProgressIndicator(
                        color: Colors.white,
                      )
                          : const Text(
                        "Next",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )),

                  const SizedBox(height: 20),

                  /// LOGIN TEXT
                  Center(
                    child: TextButton(
                      onPressed: () => Get.back(),
                      child: const Text("Already have an account? Login"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 🔁 REUSABLE INPUT FIELD
  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}


