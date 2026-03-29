import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class PushNotificationDispatcher {
  static Uri? get _endpointUri {
    final raw = dotenv.env['FIREBASE_NOTIFICATION_URL']?.trim();
    if (raw == null || raw.isEmpty) {
      return null;
    }

    return Uri.tryParse(raw);
  }

  static Future<void> dispatch({
    required String targetUserId,
    required String title,
    required String message,
    required String type,
    String? actorId,
    String? postId,
    String? conversationId,
    String? notificationId,
    Map<String, dynamic>? data,
  }) async {
    final uri = _endpointUri;
    if (uri == null) {
      debugPrint('PushNotificationDispatcher: FIREBASE_NOTIFICATION_URL missing');
      return;
    }

    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    final apiKey = dotenv.env['FIREBASE_NOTIFICATION_API_KEY']?.trim();
    if (apiKey != null && apiKey.isNotEmpty) {
      headers['x-api-key'] = apiKey;
    }

    final payload = <String, dynamic>{
      'targetUserId': targetUserId,
      'target_user_id': targetUserId,
      'title': title,
      'body': message,
      'message': message,
      'type': type,
      if (actorId != null) 'actorId': actorId,
      if (actorId != null) 'actor_id': actorId,
      if (postId != null) 'postId': postId,
      if (postId != null) 'post_id': postId,
      if (conversationId != null) 'conversationId': conversationId,
      if (conversationId != null) 'conversation_id': conversationId,
      'data': <String, dynamic>{
        'type': type,
        if (notificationId != null) 'notification_id': notificationId,
        if (actorId != null) 'actor_id': actorId,
        if (postId != null) 'post_id': postId,
        if (conversationId != null) 'conversation_id': conversationId,
        ...?data,
      },
    };

    try {
      final response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode(payload),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        debugPrint(
          'PushNotificationDispatcher: request failed '
          '${response.statusCode} ${response.body}',
        );
      }
    } catch (error, stackTrace) {
      debugPrint('PushNotificationDispatcher: dispatch failed: $error');
      debugPrint('PushNotificationDispatcher: stack: $stackTrace');
    }
  }
}
