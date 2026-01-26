import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/setup_profile_controller.dart';

class SetupProfileScreen extends GetView<SetupProfileController> {
  const SetupProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Setup Profile")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: controller.formKey,
          child: Column(
            children: [
              // Image Picker Circle
              Center(
                child: Stack(
                  children: [
                    Obx(() => Container(
                      padding: EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey
                      ),
                      child: CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.grey,
                        backgroundImage: controller.selectedImagePath.isEmpty
                            ? const AssetImage('assets/images/default_user.png') as ImageProvider
                            : FileImage(File(controller.selectedImagePath.value)),
                      ),
                    )),
                    Positioned(
                      bottom: 5,
                      right: 5,
                      child: GestureDetector(
                        onTap: controller.pickImage,
                        child: const CircleAvatar(
                          radius: 15,
                          backgroundColor: Colors.blue,
                          child: Icon(Icons.edit, color: Colors.white, size: 18),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              TextFormField(
                controller: controller.usernameController,
                decoration: const InputDecoration(labelText: "Username"),
                validator: (v) => v!.isEmpty ? "Username is required" : null,
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: controller.bioController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: "Bio"),
              ),
              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                child: Obx(() => ElevatedButton(
                  onPressed: controller.isLoading.value ? null : controller.submitProfile,
                  child: controller.isLoading.value
                      ? const CircularProgressIndicator()
                      : const Text("Complete Setup"),
                )),
              ),
            ],
          ),
        ),
      ),
    );
  }
}