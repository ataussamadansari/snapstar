import 'package:get/get.dart';

import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/post_repository.dart';
import '../../../data/repositories/subscriber_repository.dart';
import '../../../data/repositories/user_repository.dart';
import '../controllers/search_controller.dart';

class SearchBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SearchsController>(
      () => SearchsController(
        Get.find<UserRepository>(),
        Get.find<PostRepository>(),
        Get.find<AuthRepository>(),
        Get.find<SubscriberRepository>(),
      ),
    );
  }
}
