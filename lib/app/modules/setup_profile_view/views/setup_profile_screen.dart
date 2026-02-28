import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/setup_profile_controller.dart';

class SetupProfileScreen extends GetView<SetupProfileController> {
  const SetupProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: controller.formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [

                /// PROFILE IMAGE
                /// PROFILE IMAGE SECTION
                Obx(() => Column(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.grey.shade300,
                          backgroundImage: controller.profileImage.value != null
                              ? FileImage(controller.profileImage.value!)
                              : null,
                          child: controller.profileImage.value == null
                              ? const Icon(Icons.person, size: 50, color: Colors.white)
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: controller.pickImage, // 🟢 Image pick function call
                            child: CircleAvatar(
                              radius: 18,
                              backgroundColor: Theme.of(context).primaryColor,
                              child: const Icon(Icons.camera_alt_outlined, size: 14, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text("Upload Profile Picture", style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                )),

                const SizedBox(height: 24),

                /// USERNAME
                TextFormField(
                  controller: controller.usernameCtrl,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: "Username",
                    hintText: "samad_07",
                    helperText: "Only letters, numbers & _ (no spaces)",
                    prefixIcon: Icon(Icons.alternate_email),
                  ),
                  validator: (v) {
                    final value = v?.trim() ?? '';

                    if (value.isEmpty) {
                      return "Username is required";
                    }

                    if (value.contains(' ')) {
                      return "Spaces are not allowed";
                    }

                    final regex = RegExp(r'^[a-z][a-z0-9_]{2,19}$');
                    if (!regex.hasMatch(value)) {
                      return "3–20 chars, start with letter, use a-z 0-9 _";
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 16),

                /// PHONE
                TextFormField(
                  controller: controller.phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: "Phone (optional)",
                    prefixIcon: Icon(Icons.phone),
                  ),
                ),

                const SizedBox(height: 16),

                /// BIO
                TextFormField(
                  controller: controller.bioCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: "Bio (optional)",
                    prefixIcon: Icon(Icons.info_outline),
                  ),
                ),

                const SizedBox(height: 30),

                /// SUBMIT BUTTON
                Obx(() => SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: controller.isLoading.value
                        ? null
                        : controller.submit,
                    child: controller.isLoading.value
                        ? const CircularProgressIndicator(
                      color: Colors.white,
                    )
                        : const Text(
                      "Continue",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
