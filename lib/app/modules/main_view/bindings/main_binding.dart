import 'package:get/get.dart';

import '../../../data/controllers/story_controller.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/post_repository.dart';
import '../../../data/repositories/save_repository.dart';
import '../../../data/repositories/subscriber_repository.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../data/services/local_cache_service.dart';
import '../../add_post_view/controllers/add_post_controller.dart';
import '../../home_view/controllers/home_controller.dart';
import '../../profile_view/controllers/profile_controller.dart';
import '../../reels_view/controllers/reels_controller.dart';
import '../../search_view/controllers/search_controller.dart';
import '../controllers/main_controller.dart';

class MainBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MainController>(() => MainController());

    Get.lazyPut<HomeController>(
      () => HomeController(
        Get.find<UserRepository>(),
        Get.find<PostRepository>(),
        Get.find<SubscriberRepository>(),
        Get.find<StoryController>(),
        Get.find<AuthRepository>(),
        Get.find<LocalCacheService>(),
      ),
    );
    Get.lazyPut<SearchsController>(
      () => SearchsController(
        Get.find<UserRepository>(),
        Get.find<PostRepository>(),
        Get.find<AuthRepository>(),
        Get.find<SubscriberRepository>(),
      ),
    );
    Get.lazyPut<AddPostController>(
      () => AddPostController(
        Get.find<PostRepository>(),
        Get.find<AuthRepository>(),
      ),
    );
    Get.lazyPut<ReelsController>(
      () => ReelsController(
        Get.find<PostRepository>(),
        Get.find<AuthRepository>(),
        Get.find<LocalCacheService>(),
      ),
    );
    Get.lazyPut<ProfileController>(
      () => ProfileController(
        Get.find<UserRepository>(),
        Get.find<PostRepository>(),
        Get.find<AuthRepository>(),
        Get.find<SubscriberRepository>(),
        Get.find<LocalCacheService>(),
        Get.find<SaveRepository>(),
      ),
    );
  }
}
