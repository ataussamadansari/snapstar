import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:snapstar_app/app/routes/app_routes.dart';

import '../controllers/login_controller.dart';

class LoginScreen extends GetView<LoginController> {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: controller.formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                const SizedBox(height: 40),

                /// TITLE
                const Text(
                  "Welcome Back",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  "Login to continue",
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 32),

                /// EMAIL
                TextFormField(
                  controller: controller.emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: "Email",
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return "Email required";
                    }
                    if (!GetUtils.isEmail(v.trim())) {
                      return "Enter valid email";
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                /// PASSWORD
                Obx(() => TextFormField(
                  controller: controller.passCtrl,
                  obscureText: controller.hidePassword.value,
                  decoration: InputDecoration(
                    labelText: "Password",
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        controller.hidePassword.value
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: controller.togglePassword,
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return "Password required";
                    }
                    return null;
                  },
                )),

                const SizedBox(height: 30),

                /// LOGIN BUTTON
                Obx(() => SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed:
                    controller.isLoading.value ? null : controller.login,
                    child: controller.isLoading.value
                        ? const CircularProgressIndicator(
                      color: Colors.white,
                    )
                        : const Text(
                      "Login",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )),

                const SizedBox(height: 20),

                /// SIGNUP LINK
                Center(
                  child: TextButton(
                    onPressed: () => Get.toNamed(Routes.signup),
                    child: const Text("Don’t have an account? Sign up"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
