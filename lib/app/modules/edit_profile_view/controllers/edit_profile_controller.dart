import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:snapstar_app/app/core/utils/avatar_cropper.dart';
import 'package:snapstar_app/app/core/utils/helpers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/models/user_model.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/user_repository.dart';
import '../../profile_view/controllers/profile_controller.dart';
import '../../profile_view/controllers/user_profile_controller.dart';

class EditProfileController extends GetxController {
  EditProfileController(this._userRepo, this._authRepo);

  final UserRepository _userRepo;
  final AuthRepository _authRepo;
  final ImagePicker _picker = ImagePicker();

  final formKey = GlobalKey<FormState>();

  late TextEditingController usernameCtrl;
  late TextEditingController nameCtrl;
  late TextEditingController bioCtrl;
  late TextEditingController phoneCtrl;

  Rxn<UserModel> userProfile = Rxn<UserModel>();
  Rx<File?> selectedImage = Rx<File?>(null);
  RxBool isLoading = false.obs;

  RxInt bioLength = 0.obs;

  @override
  void onInit() {
    super.onInit();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final userId = _authRepo.currentUserId;
    if (userId == null) {
      return;
    }

    final profile = await _userRepo.fetchProfile(userId);
    userProfile.value = profile;

    usernameCtrl = TextEditingController(text: profile?.username ?? '');
    nameCtrl = TextEditingController(text: profile?.name ?? '');
    bioCtrl = TextEditingController(text: profile?.bio ?? '');
    phoneCtrl = TextEditingController(text: profile?.phone ?? '');

    bioLength.value = bioCtrl.text.length;

    bioCtrl.addListener(() => bioLength.value = bioCtrl.text.length);
  }

  Future<void> pickImage() async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 60,
    );
    if (pickedFile == null) {
      return;
    }

    final cropped = await AvatarCropper.cropSquare(pickedFile.path);
    if (cropped != null) {
      selectedImage.value = cropped;
    }
  }

  Future<void> updateProfile() async {
    if (!formKey.currentState!.validate()) return;

    try {
      isLoading.value = true;

      final userId = _authRepo.currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final normalizedUsername = usernameCtrl.text.trim().toLowerCase();
      final currentUsername = userProfile.value?.username.trim().toLowerCase();

      if (normalizedUsername != currentUsername) {
        final isAvailable = await _userRepo.checkUsername(normalizedUsername);
        if (!isAvailable) {
          AppHelpers.showSnackBar(
            title: 'Username unavailable',
            message: 'Try a different username',
            isError: true,
          );
          return;
        }
      }

      String? photoUrl = userProfile.value?.avatarUrl;

      if (selectedImage.value != null) {
        photoUrl = await _userRepo.uploadAvatar(
          userId: userId,
          file: selectedImage.value!,
          folder: 'profiles',
        );
      }

      final updateData = {
        'username': normalizedUsername,
        'name': nameCtrl.text.trim(),
        'bio': bioCtrl.text.trim(),
        'phone': phoneCtrl.text.trim(),
        'avatar_url': photoUrl,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _userRepo.updateProfile(userId, updateData);

      // Refresh any active profile-related controllers so the UI shows the
      // latest data. we're cautious and only invoke fetch methods if the
      // controllers are registered (they're lazy-loaded by GetX).
      if (Get.isRegistered<ProfileController>()) {
        Get.find<ProfileController>().fetchMyProfile();
      }
      if (Get.isRegistered<UserProfileController>()) {
        // If the user was editing from their own public profile screen, that
        // controller needs to update as well.
        Get.find<UserProfileController>().fetchProfile();
      }

      Get.back(result: true);
      AppHelpers.showSnackBar(
        title: 'Success',
        message: 'Profile updated successfully',
        isError: false,
      );
    } on PostgrestException catch (e) {
      AppHelpers.showSnackBar(
        title: 'DB Error',
        message: e.message,
        isError: true,
      );
    } catch (e) {
      debugPrint('EditProfile error during update: $e');
      AppHelpers.showSnackBar(
        title: 'Error',
        message: e.toString(),
        isError: true,
      );
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    usernameCtrl.dispose();
    nameCtrl.dispose();
    bioCtrl.dispose();
    phoneCtrl.dispose();
    super.onClose();
  }
}
