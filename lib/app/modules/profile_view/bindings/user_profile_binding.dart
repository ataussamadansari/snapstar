import 'package:get/get.dart';

import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/post_repository.dart';
import '../../../data/repositories/subscriber_repository.dart';
import '../../../data/repositories/user_repository.dart';
import '../controllers/user_profile_controller.dart';

class UserProfileBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<UserProfileController>(() {
      final args = Get.arguments;

      String? userId;
      if (args is String) {
        userId = args;
      } else if (args is Map<String, dynamic>) {
        userId = args['userId']?.toString();
      }

      userId ??= Get.find<AuthRepository>().currentUserId;

      if (userId == null || userId.isEmpty) {
        throw StateError('Missing user id for UserProfileController');
      }

      return UserProfileController(
        Get.find<UserRepository>(),
        Get.find<PostRepository>(),
        Get.find<AuthRepository>(),
        Get.find<SubscriberRepository>(),
        userId,
      );
    });
  }
}
