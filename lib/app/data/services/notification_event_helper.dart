import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'push_notification_dispatcher.dart';

class NotificationEventHelper {
  static bool _notificationsSupported = true;

  static Future<void> create({
    required SupabaseClient client,
    required String receiverUserId,
    required String actorUserId,
    required String type,
    required String message,
    String? title,
    String? postId,
    String? conversationId,
    Map<String, dynamic>? data,
  }) async {
    if (!_notificationsSupported) {
      return;
    }

    // REQUIREMENT: Removed the (receiverUserId == actorUserId) check
    // to allow notifications for own posts.

    final now = DateTime.now().toIso8601String();

    final Map<String, dynamic> notificationData = {
      'user_id': receiverUserId,
      'actor_id': actorUserId,
      'type': type,
      'title': title ?? _defaultTitle(type),
      'message': message,
      if (postId != null) 'post_id': postId,
      'is_read': false,
      'is_deleted': false,
      'created_at': now,
      'updated_at': now,
    };

    try {
      // Try to insert using the most complete schema first
      final response = await client
          .from('notifications')
          .insert(notificationData)
          .select('id')
          .maybeSingle();

      // Dispatch Push via FCM/Dispatcher
      await PushNotificationDispatcher.dispatch(
        targetUserId: receiverUserId,
        title: title ?? _defaultTitle(type),
        message: message,
        type: type,
        actorId: actorUserId,
        postId: postId,
        conversationId: conversationId,
        notificationId: response?['id']?.toString(),
        data: data,
      );
    } on PostgrestException catch (error, stackTrace) {
      if (_isMissingNotificationsTable(error)) {
        _notificationsSupported = false;
        return;
      }
      debugPrint('NotificationEventHelper.create DB error: $error');
      debugPrint('NotificationEventHelper.create stack: $stackTrace');
    } catch (error, stackTrace) {
      debugPrint('NotificationEventHelper.create push error: $error');
      debugPrint('NotificationEventHelper.create stack: $stackTrace');
    }
  }

  static bool _isMissingNotificationsTable(Object error) {
    if (error is! PostgrestException) {
      return false;
    }

    final message = error.message.toLowerCase();
    final details = (error.details?.toString() ?? '').toLowerCase();

    return error.code == 'PGRST205' ||
        error.code == '42P01' ||
        message.contains('notifications') ||
        details.contains('notifications');
  }

  static String _defaultTitle(String type) {
    switch (type) {
      case 'like':
        return 'New like';
      case 'comment':
        return 'New comment';
      case 'subscribe':
        return 'New follower';
      case 'unsubscribe':
        return 'Follower update';
      default:
        return 'New activity';
    }
  }
}
