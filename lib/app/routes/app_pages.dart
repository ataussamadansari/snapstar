import 'package:get/get.dart';
import 'package:snapstar_app/app/middlewares/auth_middleware.dart';
import 'package:snapstar_app/app/modules/chat_view/bindings/chat_detail_binding.dart';
import 'package:snapstar_app/app/modules/chat_view/bindings/chat_list_binding.dart';
import 'package:snapstar_app/app/modules/chat_view/views/chat_detail_screen.dart';
import 'package:snapstar_app/app/modules/chat_view/views/chat_list_screen.dart';
import 'package:snapstar_app/app/modules/edit_profile_view/bindings/edit_profile_binding.dart';
import 'package:snapstar_app/app/modules/edit_profile_view/views/edit_profile_screen.dart';
import 'package:snapstar_app/app/modules/login_view/views/login_screen.dart';
import 'package:snapstar_app/app/modules/main_view/bindings/main_binding.dart';
import 'package:snapstar_app/app/modules/main_view/views/main_screen.dart';
import 'package:snapstar_app/app/modules/notification_view/bindings/notification_binding.dart';
import 'package:snapstar_app/app/modules/notification_view/views/notification_screen.dart';
import 'package:snapstar_app/app/modules/profile_view/bindings/user_profile_binding.dart';
import 'package:snapstar_app/app/modules/profile_view/views/user_profile_screen.dart';
import 'package:snapstar_app/app/modules/setup_profile_view/bindings/setup_profile_binding.dart';
import 'package:snapstar_app/app/modules/setup_profile_view/views/setup_profile_screen.dart';
import 'package:snapstar_app/app/modules/splash_view/bindings/splash_binding.dart';
import 'package:snapstar_app/app/modules/splash_view/views/splash_screen.dart';
import 'package:snapstar_app/app/modules/settings_view/bindings/settings_binding.dart';
import 'package:snapstar_app/app/modules/settings_view/views/accessibility_settings_screen.dart';
import 'package:snapstar_app/app/modules/settings_view/views/app_update_screen.dart';
import 'package:snapstar_app/app/modules/settings_view/views/content_style_settings_screen.dart';
import 'package:snapstar_app/app/modules/settings_view/views/help_feedback_screen.dart';
import 'package:snapstar_app/app/modules/settings_view/views/notification_settings_screen.dart';
import 'package:snapstar_app/app/modules/settings_view/views/privacy_policy_screen.dart';
import 'package:snapstar_app/app/modules/settings_view/views/settings_screen.dart';
import 'package:snapstar_app/app/modules/story_viewer_view/bindings/story_viewer_binding.dart';
import 'package:snapstar_app/app/modules/story_viewer_view/views/story_viewer_screen.dart';
import 'package:snapstar_app/app/modules/subscribe_list_view/bindings/subscribe_list_binding.dart';
import 'package:snapstar_app/app/modules/subscribe_list_view/views/subscribe_list_screen.dart';
import 'package:snapstar_app/app/modules/search_view/bindings/search_binding.dart';
import 'package:snapstar_app/app/modules/search_view/views/suggested_hashtags_screen.dart';
import 'package:snapstar_app/app/modules/search_view/views/suggested_users_screen.dart';

import 'app_routes.dart';

class AppPages {
  static final routes = [
    GetPage(
      name: Routes.splash,
      page: () => SplashScreen(),
      binding: SplashBinding(),
    ),
    GetPage(
      name: Routes.login,
      page: () => LoginScreen(),
    ),
    GetPage(
      name: Routes.profileSetup,
      page: () => SetupProfileScreen(),
      binding: SetupProfileBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.main,
      page: () => MainScreen(),
      binding: MainBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.userProfile,
      page: () => const UserProfileScreen(),
      binding: UserProfileBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.editProfile,
      page: () => EditProfileScreen(),
      binding: EditProfileBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.subscriberList,
      page: () => SubscriberListScreen(),
      binding: SubscriberListBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.storyViewer,
      page: () => StoryViewerScreen(),
      binding: StoryViewerBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.notifications,
      page: () => const NotificationScreen(),
      binding: NotificationBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.chatList,
      page: () => const ChatListScreen(),
      binding: ChatListBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.chatDetail,
      page: () => const ChatDetailScreen(),
      binding: ChatDetailBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.searchSuggestedUsers,
      page: () => const SuggestedUsersScreen(),
      binding: SearchBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.searchSuggestedHashtags,
      page: () => const SuggestedHashtagsScreen(),
      binding: SearchBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.settings,
      page: () => const SettingsScreen(),
      binding: SettingsBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.settingsPrivacyPolicy,
      page: () => const PrivacyPolicyScreen(),
      binding: SettingsBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.settingsNotifications,
      page: () => const NotificationSettingsScreen(),
      binding: SettingsBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.settingsHelpFeedback,
      page: () => const HelpFeedbackScreen(),
      binding: SettingsBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.settingsAppUpdate,
      page: () => const AppUpdateScreen(),
      binding: SettingsBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.settingsAccessibility,
      page: () => const AccessibilitySettingsScreen(),
      binding: SettingsBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: Routes.settingsContentStyle,
      page: () => const ContentStyleSettingsScreen(),
      binding: SettingsBinding(),
      middlewares: [AuthMiddleware()],
    ),
  ];
}
