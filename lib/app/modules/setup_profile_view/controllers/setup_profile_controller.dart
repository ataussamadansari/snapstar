import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:snapstar_app/app/core/utils/helpers.dart';
import 'package:snapstar_app/app/routes/app_routes.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/user_repository.dart';

class SetupProfileController extends GetxController {
  SetupProfileController(this._authRepo, this._userRepo);

  final AuthRepository _authRepo;
  final UserRepository _userRepo;

  final ImagePicker _picker = ImagePicker();

  final formKey = GlobalKey<FormState>();

  final usernameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final bioCtrl = TextEditingController();

  Rx<File?> profileImage = Rx<File?>(null);
  RxBool isLoading = false.obs;

  Future<void> pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (pickedFile != null) {
      profileImage.value = File(pickedFile.path);
    }
  }

  Future<void> submit() async {
    final form = formKey.currentState;
    if (form == null) return;
    if (!form.validate()) return;

    try {
      isLoading.value = true;

      final userId = _authRepo.currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final username = usernameCtrl.text.trim();

      final isAvailable = await _userRepo.checkUsername(username);
      if (!isAvailable) {
        AppHelpers.showSnackBar(
          title: 'Username taken',
          message: 'Please choose another username',
        );
        return;
      }

      String? photoUrl;
      if (profileImage.value != null) {
        photoUrl = await _userRepo.uploadAvatar(
          userId: userId,
          file: profileImage.value!,
          folder: 'profiles',
        );
      }

      await _userRepo.updateProfile(userId, {
        'username': username,
        'phone': phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
        'bio': bioCtrl.text.trim().isEmpty ? null : bioCtrl.text.trim(),
        'avatar_url': photoUrl,
        'updated_at': DateTime.now().toIso8601String(),
      });

      Get.offAllNamed(Routes.main);
    } on PostgrestException catch (e) {
      AppHelpers.showSnackBar(title: 'Database Error', message: e.message);
    } catch (e) {
      AppHelpers.showSnackBar(title: 'Error', message: e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    usernameCtrl.dispose();
    phoneCtrl.dispose();
    bioCtrl.dispose();
    super.onClose();
  }
}
