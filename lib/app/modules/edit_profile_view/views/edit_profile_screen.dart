import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Numbers only restriction ke liye zaruri hai
import 'package:get/get.dart';
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
            onPressed: () => Get.back()),
        title: const Text("Edit Profile",
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          Obx(() => controller.isLoading.value
              ? const Center(
              child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))))
              : TextButton(
            onPressed: controller.updateProfile,
            child: const Text("Done",
                style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
          )),
        ],
      ),
      body: Obx(() {
        if (controller.userProfile.value == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Form(
            key: controller.formKey,
            child: Column(
              children: [
                _buildImagePicker(),
                const SizedBox(height: 10),

                _buildSectionHeader("Public Information"),
                _buildInputField("Name", controller.nameCtrl, Icons.person_outline),
                _buildBioField(),

                const SizedBox(height: 10),
                _buildSectionHeader("Private Information"),

                // 📱 Phone Field with 10 digit & number only restriction
                _buildInputField(
                  "Phone",
                  controller.phoneCtrl,
                  Icons.phone_android_outlined,
                  isPhoneNumber: true,
                ),

                _buildInputField(
                  "Email",
                  TextEditingController(text: controller.userProfile.value!.email),
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
            Obx(() => CircleAvatar(
              radius: 50,
              backgroundColor: Colors.grey[200],
              backgroundImage: controller.selectedImage.value != null
                  ? FileImage(controller.selectedImage.value!)
                  : (controller.userProfile.value?.avatarUrl != null
                  ? NetworkImage(controller.userProfile.value!.avatarUrl!)
                  : null) as ImageProvider?,
              child: (controller.selectedImage.value == null &&
                  controller.userProfile.value?.avatarUrl == null)
                  ? const Icon(Icons.person, size: 50, color: Colors.grey)
                  : null,
            )),
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
            )
          ],
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: controller.pickImage,
          child: const Text("Edit profile picture",
              style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Align(
          alignment: Alignment.centerLeft,
          child: Text(title,
              style: const TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontSize: 13))),
    );
  }

  Widget _buildInputField(
      String label,
      TextEditingController ctrl,
      IconData icon, {
        bool enabled = true,
        bool isPhoneNumber = false,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextFormField(
        controller: ctrl,
        enabled: enabled,
        // 🔢 Phone number ke liye numeric keyboard
        keyboardType: isPhoneNumber ? TextInputType.number : TextInputType.text,
        inputFormatters: isPhoneNumber
            ? [
          FilteringTextInputFormatter.digitsOnly, // Sirf digits allow karega
          LengthLimitingTextInputFormatter(10), // 10 characters se zyada nahi
        ]
            : null,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20),
          filled: !enabled,
          // fillColor: enabled ? Colors.transparent : Colors.grey[100],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        // ⚠️ Validation logic
        validator: (value) {
          if (isPhoneNumber && value != null && value.isNotEmpty) {
            if (value.length != 10) {
              return "Enter a valid 10-digit phone number";
            }
          }
          if (label == "Name" && (value == null || value.isEmpty)) {
            return "Name cannot be empty";
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
              labelText: "Bio",
              alignLabelWithHint: true,
              prefixIcon: const Icon(Icons.info_outline),
              counterText: "",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 4),
          Obx(() => Text("${controller.bioLength.value} / 150",
              style: const TextStyle(fontSize: 12, color: Colors.grey))),
        ],
      ),
    );
  }
}