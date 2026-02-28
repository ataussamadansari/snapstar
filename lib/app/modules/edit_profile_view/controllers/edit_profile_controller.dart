import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:snapstar_app/app/core/utils/helpers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/models/user_model.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/user_repository.dart';
import '../../profile_view/controllers/profile_controller.dart';

class EditProfileController extends GetxController {
  EditProfileController(this._userRepo, this._authRepo);

  final UserRepository _userRepo;
  final AuthRepository _authRepo;

  final formKey = GlobalKey<FormState>();

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

    nameCtrl = TextEditingController(text: profile?.name ?? '');
    bioCtrl = TextEditingController(text: profile?.bio ?? '');
    phoneCtrl = TextEditingController(text: profile?.phone ?? '');

    bioLength.value = bioCtrl.text.length;

    bioCtrl.addListener(() => bioLength.value = bioCtrl.text.length);
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final pickedFile =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 60);
    if (pickedFile != null) {
      selectedImage.value = File(pickedFile.path);
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

      String? photoUrl = userProfile.value?.avatarUrl;

      if (selectedImage.value != null) {
        photoUrl = await _userRepo.uploadAvatar(
          userId: userId,
          file: selectedImage.value!,
          folder: 'profiles',
        );
      }

      final updateData = {
        'name': nameCtrl.text.trim(),
        'bio': bioCtrl.text.trim(),
        'phone': phoneCtrl.text.trim(),
        'avatar_url': photoUrl,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _userRepo.updateProfile(userId, updateData);

      if (Get.isRegistered<ProfileController>()) {
        Get.find<ProfileController>().fetchMyProfile();
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
    nameCtrl.dispose();
    bioCtrl.dispose();
    phoneCtrl.dispose();
    super.onClose();
  }
}
