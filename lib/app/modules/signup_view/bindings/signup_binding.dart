import 'package:get/get.dart';

import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/user_repository.dart';
import '../controllers/signup_controller.dart';

class SignupBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SignupController>(
      () => SignupController(
        Get.find<AuthRepository>(),
        Get.find<UserRepository>(),
      ),
    );
  }
}
