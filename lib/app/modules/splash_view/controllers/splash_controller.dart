import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

import '../../../data/auth_repository.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../presentation/controllers/auth_controller.dart';
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
      await Future.delayed(const Duration(seconds: 2));

      final authController = Get.find<AuthController>();
      await authController.ensureSession();

      final userId = _authRepo.currentUserId;
      if (userId == null) {
        Get.offAllNamed(Routes.login);
        return;
      }

      if (!_authRepo.isAnonymous) {
        final profile = await _userRepo.fetchProfile(userId);
        if (profile == null || profile.username.isEmpty) {
          Get.offAllNamed(Routes.profileSetup);
          return;
        }
      }

      Get.offAllNamed(Routes.main);
    } catch (error) {
      debugPrint('Splash error: $error');
      Get.offAllNamed(Routes.login);
    }
  }
}
