import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/register_controller.dart';

class RegisterScreen extends GetView<RegisterController> {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SingleChildScrollView(
        // keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: height),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: controller.formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const FlutterLogo(size: 90),

                  const SizedBox(height: 24),

                  Text(
                    "Sign up to see photos and videos from your friends.",
                    textAlign: TextAlign.center,
                    style: context.textTheme.bodyLarge!
                        .copyWith(fontWeight: FontWeight.w600),
                  ),

                  const SizedBox(height: 20),

                  TextFormField(
                    controller: controller.usernameController,
                    decoration:
                    const InputDecoration(labelText: 'Username'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Username is required';
                      }
                      if (value.length < 3) {
                        return 'Username must be at least 3 characters';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 12),

                  TextFormField(
                    controller: controller.nameController,
                    decoration: const InputDecoration(labelText: 'Name'),
                    validator: (value) =>
                    value == null || value.isEmpty
                        ? 'Name is required'
                        : null,
                  ),

                  const SizedBox(height: 12),

                  TextFormField(
                    controller: controller.emailOrMobileController,
                    decoration: const InputDecoration(
                      labelText: 'Mobile number or Email',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Email or mobile is required';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 12),

                  TextFormField(
                    controller: controller.passwordController,
                    obscureText: true,
                    decoration:
                    const InputDecoration(labelText: 'Password'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Password is required';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: controller.register,
                      child: const Text('Register'),
                    ),
                  ),

                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Already have an account?"),
                      const SizedBox(width: 6),
                      InkWell(
                        onTap: () {
                          Get.back();
                        },
                        child: Text(
                          "Login",
                          style: TextStyle(color: Colors.blue),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
