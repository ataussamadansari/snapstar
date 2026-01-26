import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:snapstar/app/data/repositories/user_repository.dart';

import '../../../core/utils/global_user_controller.dart';
import '../../../routes/app_routes.dart';

class SplashScreenController extends GetxController {
  final UserRepository _userRepo = UserRepository(); //

  @override
  void onInit() {
    super.onInit();
    startAppLogic();
  }

  void startAppLogic() async {
    // 1. Token check karein
    String? token = await FirebaseAuth.instance.currentUser?.getIdToken();

    if (token == null || token.isEmpty) {
      Get.offAllNamed(Routes.login);
      return;
    }

    await Future.delayed(const Duration(seconds: 2));
    // 2. Backend API ko call karein (jo check() aapne banaya hai)
    final response = await _userRepo.check();

    if (response.success && response.data != null) {
      // API ka sara data Global Controller mein save kar dein
      Get.find<GlobalUserController>().updateUserData(response.data!.data);

      // 3. Decide karein kahan jana hai
      if (response.data!.hasUsername == true) {
        Get.offAllNamed(Routes.main); // Sab sahi hai -> Main Screen
      } else {
        Get.offAllNamed(Routes.setupProfile); // Username nahi hai -> Setup Screen
      }
    } else {
      Get.offAllNamed(Routes.login); // API fail hui toh wapis Login
    }
  }
}
