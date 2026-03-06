import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../routes/app_routes.dart';

class SplashController extends GetxController {
  SplashController(this._authRepo, this._userRepo);

  final AuthRepository _authRepo;
  final UserRepository _userRepo;

  @override
  void onReady() {
    super.onReady();
    Future.microtask(_checkAuth);
  }

  Future<void> _checkAuth() async {
    try {
      await Future.delayed(const Duration(seconds: 1));

      final userId = _authRepo.currentUserId;

      if (userId == null) {
        Get.offAllNamed(Routes.login);
        return;
      }

      final profile = await _userRepo.fetchProfile(userId);

      if (profile == null) {
        Get.offAllNamed(Routes.profileSetup);
        return;
      }

      if (profile.username.trim().isEmpty) {
        Get.offAllNamed(Routes.profileSetup);
        return;
      }

      Get.offAllNamed(Routes.main);
    } catch (e) {
      debugPrint('Splash error: $e');
      Get.offAllNamed(Routes.login);
    }
  }
}
