import 'package:get/get.dart';

import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/post_repository.dart';
import '../controllers/add_post_controller.dart';

class AddPostBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AddPostController>(
      () => AddPostController(
        Get.find<PostRepository>(),
        Get.find<AuthRepository>(),
      ),
    );
  }
}
