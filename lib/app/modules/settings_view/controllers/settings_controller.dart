import 'package:get/get.dart';
import 'package:snapstar_app/app/core/utils/helpers.dart';

import '../../../data/repositories/auth_repository.dart';
import '../../../routes/app_routes.dart';

class SettingsController extends GetxController {
  SettingsController(this._authRepository);

  final AuthRepository _authRepository;

  final RxBool pushLikes = true.obs;
  final RxBool pushComments = true.obs;
  final RxBool pushMessages = true.obs;
  final RxBool highContrast = false.obs;
  final RxBool largerText = false.obs;

  void togglePushLikes(bool value) => pushLikes.value = value;
  void togglePushComments(bool value) => pushComments.value = value;
  void togglePushMessages(bool value) => pushMessages.value = value;

  void toggleHighContrast(bool value) {
    highContrast.value = value;
    AppHelpers.showSnackBar(
      title: 'Accessibility',
      message: 'High contrast ${value ? 'enabled' : 'disabled'}',
      isError: false,
    );
  }

  void toggleLargerText(bool value) {
    largerText.value = value;
    AppHelpers.showSnackBar(
      title: 'Accessibility',
      message: 'Large text ${value ? 'enabled' : 'disabled'}',
      isError: false,
    );
  }

  Future<void> checkForUpdates() async {
    // AppUpdateScreen khud ShorebirdService se directly baat karta hai
    // Yahan sirf navigate karo
    Get.toNamed(Routes.settingsAppUpdate);
  }

  Future<void> logout() async {
    await _authRepository.signOut();
    Get.offAllNamed(Routes.login);
  }
}
