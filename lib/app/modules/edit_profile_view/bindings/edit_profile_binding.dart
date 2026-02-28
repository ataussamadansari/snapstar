import 'package:get/get.dart';

import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/user_repository.dart';
import '../controllers/edit_profile_controller.dart';

class EditProfileBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<EditProfileController>(
      () => EditProfileController(
        Get.find<UserRepository>(),
        Get.find<AuthRepository>(),
      ),
    );
  }
}
