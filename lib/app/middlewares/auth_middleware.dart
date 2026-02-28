import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../data/repositories/auth_repository.dart';
import '../data/repositories/user_repository.dart';
import '../routes/app_routes.dart';

class AuthMiddleware extends GetMiddleware {
  AuthRepository get _authRepo => Get.find<AuthRepository>();
  UserRepository get _userRepo => Get.find<UserRepository>();

  @override
  int? get priority => 1;

  @override
  Future<GetNavConfig?> redirectDelegate(GetNavConfig route) async {
    if (!Get.isRegistered<AuthRepository>() ||
        !Get.isRegistered<UserRepository>()) {
      return GetNavConfig.fromRoute(Routes.login);
    }

    final userId = _authRepo.currentUserId;

    if (userId == null) {
      return GetNavConfig.fromRoute(Routes.login);
    }

    try {
      final profile = await _userRepo.fetchProfile(userId);

      if (profile == null) {
        return GetNavConfig.fromRoute(Routes.signup);
      }

      if (profile.username.trim().isEmpty) {
        final currentPath = route.uri.path;

        if (currentPath != Routes.profileSetup) {
          return GetNavConfig.fromRoute(Routes.profileSetup);
        }
      }
    } catch (e) {
      debugPrint('AuthMiddleware error: $e');
      return GetNavConfig.fromRoute(Routes.login);
    }

    return route;
  }
}
