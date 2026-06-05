import 'package:get/get.dart';

import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/post_repository.dart';
import '../../../data/repositories/subscriber_repository.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../data/services/local_cache_service.dart';
import '../controllers/user_profile_controller.dart';

class UserProfileBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<UserProfileController>(() {
      final args = Get.arguments;

      String? userId;
      String? usernameArg;

      if (args is String) {
        // UUID format check — 8-4-4-4-12
        final uuidRegex = RegExp(
          r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
        );
        if (uuidRegex.hasMatch(args)) {
          userId = args;
        } else {
          // Username pass hua hai — ID baad mein resolve hoga
          usernameArg = args;
        }
      } else if (args is Map<String, dynamic>) {
        userId = args['userId']?.toString();
        usernameArg = args['username']?.toString();
      }

      userId ??= Get.find<AuthRepository>().currentUserId;

      if (userId == null && usernameArg == null) {
        throw StateError('Missing user id/username for UserProfileController');
      }

      return UserProfileController(
        Get.find<UserRepository>(),
        Get.find<PostRepository>(),
        Get.find<AuthRepository>(),
        Get.find<SubscriberRepository>(),
        userId ?? '', // username resolve hone tak empty
        Get.find<LocalCacheService>(),
        usernameToResolve: usernameArg,
      );
    });
  }
}
