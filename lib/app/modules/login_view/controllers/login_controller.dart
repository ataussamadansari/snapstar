import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:snapstar_app/app/core/utils/helpers.dart';
import 'package:snapstar_app/app/routes/app_routes.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/user_repository.dart';

class LoginController extends GetxController {
  LoginController(this._authRepo, this._userRepo);

  final AuthRepository _authRepo;
  final UserRepository _userRepo;

  final formKey = GlobalKey<FormState>();
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  RxBool isLoading = false.obs;
  RxBool hidePassword = true.obs;

  void togglePassword() => hidePassword.toggle();

  Future<void> login() async {
    final form = formKey.currentState;
    if (form == null) return;
    if (!form.validate()) return;

    try {
      isLoading.value = true;

      final userId = await _authRepo.signIn(
        email: emailCtrl.text.trim(),
        password: passCtrl.text.trim(),
      );

      if (userId == null) {
        throw Exception('Login failed');
      }

      final profile = await _userRepo.fetchProfile(userId);

      if (profile == null) {
        Get.offAllNamed(Routes.signup);
        return;
      }

      if (profile.username.trim().isEmpty) {
        Get.offAllNamed(Routes.profileSetup);
        return;
      }

      Get.offAllNamed(Routes.main);
    } on PostgrestException catch (e) {
      debugPrint('Login Failed: $e');
      AppHelpers.showSnackBar(
        title: 'Login Failed',
        message: e.message,
      );
    } on AuthException catch (e) {
      debugPrint('Login Failed: $e');
      AppHelpers.showSnackBar(
        title: 'Login Failed',
        message: e.message,
      );
    } catch (e) {
      debugPrint('Login Failed: $e');
      AppHelpers.showSnackBar(
        title: 'Error',
        message: e.toString(),
      );
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    emailCtrl.dispose();
    passCtrl.dispose();
    super.onClose();
  }
}
