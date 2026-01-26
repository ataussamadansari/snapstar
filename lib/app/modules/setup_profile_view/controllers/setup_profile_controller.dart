import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:snapstar/app/core/utils/global_user_controller.dart';
import 'package:snapstar/app/data/repositories/user_repository.dart';

import 'package:snapstar/app/routes/app_routes.dart';
import '../../../data/repositories/auth_repository.dart';

class SetupProfileController extends GetxController {
  final AuthRepository _repository = AuthRepository();
  final UserRepository _userRepo = UserRepository();

  final usernameController = TextEditingController();
  final bioController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  var selectedImagePath = ''.obs;
  var isLoading = false.obs;

  // Image Pick karne ka function
  Future<void> pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      selectedImagePath.value = pickedFile.path;
    }
  }

  Future<void> submitProfile() async {
    if (!formKey.currentState!.validate()) return;
    if (selectedImagePath.isEmpty) {
      Get.snackbar("Required", "Please select a profile picture");
      return;
    }

    try {
      isLoading.value = true;
      final response = await _repository.setupProfile(
        username: usernameController.text.trim(),
        bio: bioController.text.trim(),
        imagePath: selectedImagePath.value,
      );

      if (response.success) {
        final res = await _userRepo.check();
        if (res.success && res.data != null) {
          Get.find<GlobalUserController>().updateUserData(res.data!.data);
          Get.offAllNamed(Routes.main);
        }
      } else {
        Get.snackbar("Error", response.message);
      }
    } finally {
      isLoading.value = false;
    }
  }
}
