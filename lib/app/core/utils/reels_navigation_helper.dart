import 'package:get/get.dart';

import '../../data/models/post_model.dart';
import '../../modules/main_view/controllers/main_controller.dart';
import '../../modules/reels_view/controllers/reels_controller.dart';
import '../../modules/post_view/views/post_detail_screen.dart';
import '../../routes/app_routes.dart';

class ReelsNavigationHelper {
  static Future<void> openFromPost(
    PostModel post, {
    List<PostModel>? scopedPosts,
    String? scopedUserId,
  }) async {
    if (post.mediaType != MediaType.video) {
      Get.to(() => PostDetailScreen(post: post));
      return;
    }

    if (!Get.isRegistered<MainController>() || !Get.isRegistered<ReelsController>()) {
      Get.to(() => PostDetailScreen(post: post));
      return;
    }

    final reelsController = Get.find<ReelsController>();
    if (scopedPosts != null) {
      reelsController.showScopedFromPosts(
        posts: scopedPosts,
        initialPostId: post.id,
        scopedUserId: scopedUserId,
      );
    } else {
      await reelsController.showGlobalAtPost(post);
    }

    if (Get.currentRoute != Routes.main) {
      Get.until((route) => route.settings.name == Routes.main || route.isFirst);
    }

    final mainController = Get.find<MainController>();
    mainController.changeIndex(3, preserveReelsContext: true);
  }
}
