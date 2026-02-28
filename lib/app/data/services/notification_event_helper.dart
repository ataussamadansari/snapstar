import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  }) async {
    if (!_notificationsSupported) {
      return;
    }

    if (receiverUserId == actorUserId) {
      return;
    }

    final now = DateTime.now().toIso8601String();

    final candidates = <Map<String, dynamic>>[
      {
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
      },
      {
        'user_id': receiverUserId,
        'actor_id': actorUserId,
        'type': type,
        'body': message,
        if (postId != null) 'post_id': postId,
        'is_read': false,
        'is_deleted': false,
      },
      {
        'user_id': receiverUserId,
        'actor_id': actorUserId,
        'type': type,
        'message': message,
        'is_read': false,
        'is_deleted': false,
      },
      {
        'user_id': receiverUserId,
        'actor_id': actorUserId,
        'type': type,
        'message': message,
      },
      {
        'user_id': receiverUserId,
        'type': type,
        'message': message,
      },
      {
        'user_id': receiverUserId,
        'message': message,
      },
    ];

    for (var i = 0; i < candidates.length; i++) {
      try {
        await client.from('notifications').insert(candidates[i]);
        return;
      } catch (error, stackTrace) {
        if (_isMissingNotificationsTable(error)) {
          _notificationsSupported = false;
          return;
        }

        final isLastAttempt = i == candidates.length - 1;
        if (isLastAttempt) {
          debugPrint('NotificationEventHelper.create failed: $error');
          debugPrint('NotificationEventHelper.create stack: $stackTrace');
        }
      }
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
