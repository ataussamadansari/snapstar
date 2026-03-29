import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:snapstar_app/app/global_widgets/app_avatar.dart';
import 'package:snapstar_app/app/global_widgets/loading_skeleton.dart';

import '../controllers/edit_profile_controller.dart';

class EditProfileScreen extends GetView<EditProfileController> {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          Obx(
            () => controller.isLoading.value
                ? const AppShimmer(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: SkeletonBox(width: 46, height: 20),
                    ),
                  )
                : TextButton(
                    onPressed: controller.updateProfile,
                    child: const Text(
                      'Done',
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.userProfile.value == null) {
          return const AppShimmer(child: ProfileHeaderSkeleton());
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Form(
            key: controller.formKey,
            child: Column(
              children: [
                _buildImagePicker(),
                const SizedBox(height: 10),
                _buildSectionHeader('Public Information'),
                _buildInputField(
                  'Username',
                  controller.usernameCtrl,
                  Icons.alternate_email,
                  isUsername: true,
                ),
                _buildInputField(
                  'Name',
                  controller.nameCtrl,
                  Icons.person_outline,
                ),
                _buildBioField(),
                const SizedBox(height: 10),
                _buildSectionHeader('Private Information'),
                _buildInputField(
                  'Phone',
                  controller.phoneCtrl,
                  Icons.phone_android_outlined,
                  isPhoneNumber: true,
                ),
                _buildInputField(
                  'Email',
                  TextEditingController(
                    text: controller.userProfile.value!.email,
                  ),
                  Icons.email_outlined,
                  enabled: false,
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildImagePicker() {
    return Column(
      children: [
        Stack(
          children: [
            Obx(() {
              if (controller.selectedImage.value != null) {
                return CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: FileImage(controller.selectedImage.value!),
                );
              }

              return AppAvatar(
                radius: 50,
                avatarUrl: controller.userProfile.value?.avatarUrl,
                backgroundColor: Colors.grey[200],
                iconColor: Colors.grey,
                iconSize: 50,
              );
            }),
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: controller.pickImage,
                child: const CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.blue,
                  child: Icon(Icons.camera_alt, size: 14, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: controller.pickImage,
          child: const Text(
            'Edit and adjust profile picture',
            style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(
            color: Colors.grey,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(
    String label,
    TextEditingController ctrl,
    IconData icon, {
    bool enabled = true,
    bool isPhoneNumber = false,
    bool isUsername = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextFormField(
        controller: ctrl,
        enabled: enabled,
        keyboardType: isPhoneNumber ? TextInputType.number : TextInputType.text,
        inputFormatters: isPhoneNumber
            ? [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ]
            : isUsername
                ? [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'[a-zA-Z0-9_.]'),
                    ),
                    LengthLimitingTextInputFormatter(30),
                  ]
                : null,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20),
          filled: !enabled,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        validator: (value) {
          final text = (value ?? '').trim();

          if (isUsername) {
            if (text.isEmpty) {
              return 'Username cannot be empty';
            }
            if (text.length < 3) {
              return 'Username must be at least 3 characters';
            }
            if (!RegExp(r'^[a-zA-Z0-9_.]+$').hasMatch(text)) {
              return 'Use only letters, numbers, _ and .';
            }
          }

          if (isPhoneNumber && text.isNotEmpty && text.length != 10) {
            return 'Enter a valid 10-digit phone number';
          }

          if (label == 'Name' && text.isEmpty) {
            return 'Name cannot be empty';
          }

          return null;
        },
      ),
    );
  }

  Widget _buildBioField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          TextFormField(
            controller: controller.bioCtrl,
            maxLines: 3,
            maxLength: 150,
            decoration: InputDecoration(
              labelText: 'Bio',
              alignLabelWithHint: true,
              prefixIcon: const Icon(Icons.info_outline),
              counterText: '',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Obx(
            () => Text(
              '${controller.bioLength.value} / 150',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}
