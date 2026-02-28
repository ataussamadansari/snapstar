import 'package:get/get.dart';

import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/post_repository.dart';
import '../../../data/repositories/subscriber_repository.dart';
import '../../../data/repositories/user_repository.dart';
import '../controllers/profile_controller.dart';

class ProfileBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ProfileController>(
      () => ProfileController(
        Get.find<UserRepository>(),
        Get.find<PostRepository>(),
        Get.find<AuthRepository>(),
        Get.find<SubscriberRepository>(),
      ),
    );
  }
}
