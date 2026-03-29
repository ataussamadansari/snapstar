import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:get/get.dart';

class AnalyticsService extends GetxService {
  final _analytics = FirebaseAnalytics.instance;

  FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  // Auth events
  Future<void> logLogin(String method) =>
      _analytics.logLogin(loginMethod: method);

  Future<void> logSignUp(String method) =>
      _analytics.logSignUp(signUpMethod: method);

  // Content events
  Future<void> logViewPost(String postId) => _analytics.logEvent(
        name: 'view_post',
        parameters: {'post_id': postId},
      );

  Future<void> logCreatePost(String type) => _analytics.logEvent(
        name: 'create_post',
        parameters: {'content_type': type},
      );

  Future<void> logViewProfile(String userId) => _analytics.logEvent(
        name: 'view_profile',
        parameters: {'user_id': userId},
      );

  Future<void> logViewReel(String postId) => _analytics.logEvent(
        name: 'view_reel',
        parameters: {'post_id': postId},
      );

  Future<void> logLike(String postId) => _analytics.logEvent(
        name: 'like_post',
        parameters: {'post_id': postId},
      );

  Future<void> logComment(String postId) => _analytics.logEvent(
        name: 'comment_post',
        parameters: {'post_id': postId},
      );

  Future<void> logShare(String postId) => _analytics.logEvent(
        name: 'share_post',
        parameters: {'post_id': postId},
      );

  Future<void> logSubscribe(String targetUserId) => _analytics.logEvent(
        name: 'subscribe_user',
        parameters: {'target_user_id': targetUserId},
      );

  Future<void> logOpenChat() => _analytics.logEvent(name: 'open_chat');

  Future<void> setUserId(String? userId) => _analytics.setUserId(id: userId);
}
