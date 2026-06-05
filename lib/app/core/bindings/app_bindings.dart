import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:snapstar_app/app/data/auth_repository.dart';
import 'package:snapstar_app/app/data/controllers/comment_controller.dart';
import 'package:snapstar_app/app/data/controllers/global_media_controller.dart';
import 'package:snapstar_app/app/data/controllers/notification_badge_controller.dart';
import 'package:snapstar_app/app/data/controllers/post_story_style_controller.dart';
import 'package:snapstar_app/app/data/controllers/share_controller.dart';
import 'package:snapstar_app/app/data/controllers/story_controller.dart';
import 'package:snapstar_app/app/data/controllers/story_like_controller.dart';
import 'package:snapstar_app/app/data/repositories/story_like_repository.dart';
import 'package:snapstar_app/app/data/controllers/subscriber_controller.dart';
import 'package:snapstar_app/app/data/controllers/upload_task_controller.dart';
import 'package:snapstar_app/app/data/providers/auth_provider.dart';
import 'package:snapstar_app/app/data/providers/comment_provider.dart';
import 'package:snapstar_app/app/data/providers/like_provider.dart';
import 'package:snapstar_app/app/data/providers/notification_provider.dart';
import 'package:snapstar_app/app/data/providers/post_provider.dart';
import 'package:snapstar_app/app/data/providers/subscriber_provider.dart';
import 'package:snapstar_app/app/data/providers/user_provider.dart';
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
import 'package:snapstar_app/app/data/services/shorebird_service.dart';
import 'package:snapstar_app/app/data/services/analytics_service.dart';
import 'package:snapstar_app/app/data/services/like_service.dart';
import 'package:snapstar_app/app/data/services/local_cache_service.dart';
import 'package:snapstar_app/app/data/services/notification_service.dart';
import 'package:snapstar_app/app/data/services/post_service.dart';
import 'package:snapstar_app/app/data/services/storage_service.dart';
import 'package:snapstar_app/app/data/services/story_service.dart';
import 'package:snapstar_app/app/data/services/subscriber_service.dart';
import 'package:snapstar_app/app/data/services/user_service.dart';
import 'package:snapstar_app/app/data/services/hashtag_service.dart';
import 'package:snapstar_app/app/data/providers/hashtag_provider.dart';
import 'package:snapstar_app/app/data/providers/save_provider.dart';
import 'package:snapstar_app/app/data/services/save_service.dart';
import 'package:snapstar_app/app/data/repositories/save_repository.dart';
import 'package:snapstar_app/app/data/controllers/save_controller.dart';
import 'package:snapstar_app/app/data/providers/comment_like_provider.dart';
import 'package:snapstar_app/app/data/controllers/comment_like_controller.dart';
import 'package:snapstar_app/app/domain/usecases/login_anonymously_usecase.dart';
import 'package:snapstar_app/app/domain/usecases/login_with_google_usecase.dart';
import 'package:snapstar_app/app/domain/usecases/logout_usecase.dart';
import 'package:snapstar_app/app/domain/usecases/observe_auth_state_usecase.dart';
import 'package:snapstar_app/app/domain/usecases/upgrade_anonymous_to_google_usecase.dart';
import 'package:snapstar_app/app/presentation/controllers/auth_controller.dart';

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
    Get.put<LoginWithGoogleUseCase>(
      LoginWithGoogleUseCase(Get.find<AuthRepository>()),
      permanent: true,
    );
    Get.put<LoginAnonymouslyUseCase>(
      LoginAnonymouslyUseCase(Get.find<AuthRepository>()),
      permanent: true,
    );
    Get.put<LogoutUseCase>(
      LogoutUseCase(Get.find<AuthRepository>()),
      permanent: true,
    );
    Get.put<UpgradeAnonymousToGoogleUseCase>(
      UpgradeAnonymousToGoogleUseCase(Get.find<AuthRepository>()),
      permanent: true,
    );
    Get.put<ObserveAuthStateUseCase>(
      ObserveAuthStateUseCase(Get.find<AuthRepository>()),
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

    // Hashtag system
    Get.put<HashtagProvider>(HashtagProvider(client), permanent: true);
    Get.put<HashtagService>(
      HashtagService(Get.find<HashtagProvider>()),
      permanent: true,
    );

    // Save / Bookmark system
    Get.put<SaveProvider>(SaveProvider(client), permanent: true);
    Get.put<SaveService>(
      SaveService(Get.find<SaveProvider>()),
      permanent: true,
    );
    Get.put<SaveRepository>(
      SaveRepository(Get.find<SaveService>(), Get.find<AuthRepository>()),
      permanent: true,
    );
    Get.put<SaveController>(
      SaveController(Get.find<SaveRepository>()),
      permanent: true,
    );

    // Comment Like system
    Get.put<CommentLikeProvider>(CommentLikeProvider(client), permanent: true);
    Get.put<CommentLikeController>(
      CommentLikeController(Get.find<CommentLikeProvider>()),
      permanent: true,
    );

    Get.put<AuthController>(
      AuthController(
        authRepository: Get.find<AuthRepository>(),
        userRepository: Get.find<UserRepository>(),
        loginWithGoogleUseCase: Get.find<LoginWithGoogleUseCase>(),
        loginAnonymouslyUseCase: Get.find<LoginAnonymouslyUseCase>(),
        logoutUseCase: Get.find<LogoutUseCase>(),
        upgradeAnonymousToGoogleUseCase:
            Get.find<UpgradeAnonymousToGoogleUseCase>(),
        observeAuthStateUseCase: Get.find<ObserveAuthStateUseCase>(),
      ),
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
    Get.put<ShorebirdService>(ShorebirdService(), permanent: true);
    Get.put<AnalyticsService>(AnalyticsService(), permanent: true);

    // Story likes
    Get.put<StoryLikeRepository>(
      StoryLikeRepository(),
      permanent: true,
    );
    Get.put<StoryLikeController>(
      StoryLikeController(Get.find<StoryLikeRepository>()),
      permanent: true,
    );
  }
}
