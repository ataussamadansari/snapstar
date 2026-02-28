import 'package:get/get.dart';

import '../../../data/controllers/story_controller.dart';
import '../../../data/repositories/post_repository.dart';
import '../../../data/repositories/subscriber_repository.dart';
import '../../../data/repositories/user_repository.dart';
import '../controllers/home_controller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HomeController>(
      () => HomeController(
        Get.find<UserRepository>(),
        Get.find<PostRepository>(),
        Get.find<SubscriberRepository>(),
        Get.find<StoryController>(),
      ),
    );
  }
}
