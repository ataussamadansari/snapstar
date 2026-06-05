import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/utils/auth_helper.dart';
import '../presentation/controllers/auth_controller.dart';
import '../routes/app_routes.dart';

class AuthMiddleware extends GetMiddleware {
  @override
  int? get priority => 1;

  @override
  RouteSettings? redirect(String? route) {
    final authController = Get.find<AuthController>();

    if (!authController.isLoggedIn.value) {
      return const RouteSettings(name: Routes.login);
    }

    if (authController.isAnonymous.value && _isRestrictedRoute(route)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        AuthHelper.checkAuthAndShowModal(
          message: 'Login with Google to continue',
        );
      });
      return null; // stay on current route, modal handles the UX
    }

    return null;
  }

  bool _isRestrictedRoute(String? route) {
    const restrictedRoutes = [
      Routes.editProfile,
      Routes.profileSetup,
    ];
    return restrictedRoutes.contains(route);
  }
}
