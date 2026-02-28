import 'package:get/get.dart';

import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/user_repository.dart';
import '../controllers/splash_controller.dart';

class SplashBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<SplashController>(
      SplashController(Get.find<AuthRepository>(), Get.find<UserRepository>()),
    );
  }
}
