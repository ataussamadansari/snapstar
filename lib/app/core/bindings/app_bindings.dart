import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:snapstar_app/app/data/controllers/comment_controller.dart';
import 'package:snapstar_app/app/data/controllers/global_media_controller.dart';
import 'package:snapstar_app/app/data/controllers/notification_badge_controller.dart';
import 'package:snapstar_app/app/data/controllers/post_story_style_controller.dart';
import 'package:snapstar_app/app/data/controllers/share_controller.dart';
import 'package:snapstar_app/app/data/controllers/story_controller.dart';
import 'package:snapstar_app/app/data/controllers/subscriber_controller.dart';
import 'package:snapstar_app/app/data/controllers/upload_task_controller.dart';
import 'package:snapstar_app/app/data/providers/auth_provider.dart';
import 'package:snapstar_app/app/data/providers/comment_provider.dart';
import 'package:snapstar_app/app/data/providers/like_provider.dart';
import 'package:snapstar_app/app/data/providers/notification_provider.dart';
import 'package:snapstar_app/app/data/providers/post_provider.dart';
import 'package:snapstar_app/app/data/providers/subscriber_provider.dart';
import 'package:snapstar_app/app/data/providers/user_provider.dart';
import 'package:snapstar_app/app/data/repositories/auth_repository.dart';
import 'package:snapstar_app/app/data/repositories/chat_repository.dart';
import 'package:snapstar_app/app/data/repositories/comment_repository.dart';
import 'package:snapstar_app/app/data/repositories/like_repository.dart';
import 'package:snapstar_app/app/data/repositories/notification_repository.dart';
import 'package:snapstar_app/app/data/repositories/post_repository.dart';
import 'package:snapstar_app/app/data/repositories/story_repository.dart';
import 'package:snapstar_app/app/data/repositories/subscriber_repository.dart';
import 'package:snapstar_app/app/data/repositories/user_repository.dart';
import 'package:snapstar_app/app/data/services/auth_service.dart';
import 'package:snapstar_app/app/data/services/comment_service.dart';
import 'package:snapstar_app/app/data/services/fcm_service.dart';
import 'package:snapstar_app/app/data/services/like_service.dart';
import 'package:snapstar_app/app/data/services/local_cache_service.dart';
import 'package:snapstar_app/app/data/services/notification_service.dart';
import 'package:snapstar_app/app/data/services/post_service.dart';
import 'package:snapstar_app/app/data/services/storage_service.dart';
import 'package:snapstar_app/app/data/services/story_service.dart';
import 'package:snapstar_app/app/data/services/subscriber_service.dart';
import 'package:snapstar_app/app/data/services/user_service.dart';

import '../../data/controllers/auth_controller.dart';
import '../../data/controllers/like_controller.dart';

class AppBindings extends Bindings {
  @override
  void dependencies() {
    final client = Supabase.instance.client;

    Get.put<AuthProvider>(AuthProvider(client), permanent: true);
    Get.put<UserProvider>(UserProvider(client), permanent: true);
    Get.put<SubscriberProvider>(SubscriberProvider(client), permanent: true);
    Get.put<PostProvider>(PostProvider(client), permanent: true);
    Get.put<LikeProvider>(LikeProvider(client), permanent: true);
    Get.put<CommentProvider>(CommentProvider(client), permanent: true);
    Get.put<NotificationProvider>(
      NotificationProvider(client),
      permanent: true,
    );

    Get.put<AuthService>(
      AuthService(Get.find<AuthProvider>()),
      permanent: true,
    );
    Get.put<UserService>(
      UserService(Get.find<UserProvider>()),
      permanent: true,
    );
    Get.put<SubscriberService>(
      SubscriberService(Get.find<SubscriberProvider>(), client),
      permanent: true,
    );
    Get.put<PostService>(
      PostService(Get.find<PostProvider>(), client),
      permanent: true,
    );
    Get.put<LikeService>(
      LikeService(Get.find<LikeProvider>(), client),
      permanent: true,
    );
    Get.put<CommentService>(
      CommentService(Get.find<CommentProvider>(), client),
      permanent: true,
    );
    Get.put<NotificationService>(
      NotificationService(Get.find<NotificationProvider>(), client),
      permanent: true,
    );

    Get.put<AuthRepository>(
      AuthRepository(Get.find<AuthService>()),
      permanent: true,
    );
    Get.put<UserRepository>(
      UserRepository(Get.find<UserService>()),
      permanent: true,
    );
    Get.put<SubscriberRepository>(
      SubscriberRepository(
        Get.find<SubscriberService>(),
        Get.find<AuthRepository>(),
      ),
      permanent: true,
    );
    Get.put<PostRepository>(
      PostRepository(Get.find<PostService>()),
      permanent: true,
    );
    Get.put<LikeRepository>(
      LikeRepository(Get.find<LikeService>(), Get.find<AuthRepository>()),
      permanent: true,
    );
    Get.put<CommentRepository>(
      CommentRepository(Get.find<CommentService>(), Get.find<AuthRepository>()),
      permanent: true,
    );
    Get.put<NotificationRepository>(
      NotificationRepository(Get.find<NotificationService>()),
      permanent: true,
    );
    Get.put<ChatRepository>(
      ChatRepository(client, Get.find<AuthRepository>()),
      permanent: true,
    );

    Get.put<StoryRepository>(StoryRepository(), permanent: true);
    Get.put<StoryService>(
      StoryService(Get.find<StoryRepository>()),
      permanent: true,
    );
    Get.put<StorageService>(StorageService(), permanent: true);
    Get.put<LocalCacheService>(LocalCacheService(), permanent: true);

    Get.put<AuthController>(
      AuthController(Get.find<AuthRepository>()),
      permanent: true,
    );
    Get.put<LikeController>(
      LikeController(Get.find<LikeRepository>()),
      permanent: true,
    );
    Get.put<SubscriberController>(
      SubscriberController(Get.find<SubscriberRepository>()),
      permanent: true,
    );
    Get.put<UploadTaskController>(UploadTaskController(), permanent: true);
    Get.put<StoryController>(
      StoryController(Get.find<StoryService>()),
      permanent: true,
    );
    Get.put<CommentController>(
      CommentController(Get.find<CommentRepository>()),
      permanent: true,
    );
    Get.put<NotificationBadgeController>(
      NotificationBadgeController(
        Get.find<NotificationRepository>(),
        Get.find<AuthRepository>(),
      ),
      permanent: true,
    );
    Get.put<ShareController>(
      ShareController(Get.find<PostRepository>()),
      permanent: true,
    );
    Get.put<PostStoryStyleController>(
      PostStoryStyleController(Get.find<LocalCacheService>()),
      permanent: true,
    );
    Get.put<GlobalMediaController>(GlobalMediaController(), permanent: true);
    Get.put<FcmService>(
      FcmService(client, Get.find<AuthRepository>()),
      permanent: true,
    );
  }
}
