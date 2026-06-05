import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'notification_event_helper.dart';
import '../providers/comment_provider.dart';

enum CommentChangeType { insert, update, delete }

class CommentRealtimeChange {
  const CommentRealtimeChange({
    required this.type,
    required this.commentId,
    required this.postId,
    this.commentData,
  });

  final CommentChangeType type;
  final String commentId;
  final String postId;
  final Map<String, dynamic>? commentData;
}

class CommentService {
  CommentService(this._provider, this._client);

  final CommentProvider _provider;
  final SupabaseClient _client;

  final Map<String, Set<void Function(CommentRealtimeChange)>> _postListeners =
      <String, Set<void Function(CommentRealtimeChange)>>{};
  final Map<String, RealtimeChannel> _postChannels =
      <String, RealtimeChannel>{};
  final Map<String, String> _commentPostMap = <String, String>{};

  Future<void> createComment(Map<String, dynamic> data) async {
    try {
      await _provider.createComment(data);
      final postId = data['post_id']?.toString();
      final actorUserId = data['user_id']?.toString();
      if (postId != null && postId.isNotEmpty) {
        if (actorUserId != null && actorUserId.isNotEmpty) {
          await _createCommentNotification(
            postId: postId,
            actorUserId: actorUserId,
          );
        }
      }
    } catch (error, stackTrace) {
      debugPrint('CommentService.createComment error: $error');
      debugPrint('CommentService.createComment stack: $stackTrace');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> fetchComments(String postId) async {
    try {
      return await _provider.fetchComments(postId);
    } catch (error, stackTrace) {
      debugPrint('CommentService.fetchComments error: $error');
      debugPrint('CommentService.fetchComments stack: $stackTrace');
      rethrow;
    }
  }

  Future<int> fetchCommentCount(String postId) async {
    try {
      return await _provider.fetchCommentCount(postId);
    } catch (error, stackTrace) {
      debugPrint('CommentService.fetchCommentCount error: $error');
      debugPrint('CommentService.fetchCommentCount stack: $stackTrace');
      rethrow;
    }
  }

  Future<void> updateComment(String id, String newText) async {
    try {
      await _provider.updateComment(id, newText);
    } catch (error, stackTrace) {
      debugPrint('CommentService.updateComment error: $error');
      debugPrint('CommentService.updateComment stack: $stackTrace');
      rethrow;
    }
  }

  Future<void> deleteComment({
    required String id,
    required String postId,
  }) async {
    try {
      try {
        await _provider.softDeleteComment(id);
      } on PostgrestException {
        await _provider.hardDeleteComment(id);
      }
    } catch (error, stackTrace) {
      debugPrint('CommentService.deleteComment error: $error');
      debugPrint('CommentService.deleteComment stack: $stackTrace');
      rethrow;
    }
  }

  VoidCallback subscribeToPostComments({
    required String postId,
    required void Function(CommentRealtimeChange) onEvent,
  }) {
    _postListeners.putIfAbsent(
      postId,
      () => <void Function(CommentRealtimeChange)>{},
    );
    _postListeners[postId]!.add(onEvent);

    _ensureRealtimeChannelForPost(postId);

    return () {
      final listeners = _postListeners[postId];
      if (listeners == null) {
        return;
      }

      listeners.remove(onEvent);
      if (listeners.isEmpty) {
        _postListeners.remove(postId);
      }

      _disposeChannelIfIdle(postId);
    };
  }

  void _ensureRealtimeChannelForPost(String postId) {
    if (_postChannels.containsKey(postId)) {
      return;
    }

    final channel = _client.channel('comments-realtime-$postId');
    _postChannels[postId] = channel;

    channel
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'comments',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'post_id',
          value: postId,
        ),
        callback: _handleCommentRealtime,
      )
      ..subscribe();
  }

  void _handleCommentRealtime(PostgresChangePayload payload) {
    _processCommentRealtime(payload);
  }

  Future<void> _processCommentRealtime(PostgresChangePayload payload) async {
    try {
      final change = await _toRealtimeChange(payload);
      if (change == null) {
        return;
      }

      final listeners = _postListeners[change.postId];
      if (listeners == null || listeners.isEmpty) {
        return;
      }

      for (final listener in listeners.toList()) {
        listener(change);
      }
    } catch (error, stackTrace) {
      debugPrint('CommentService._processCommentRealtime error: $error');
      debugPrint('CommentService._processCommentRealtime stack: $stackTrace');
    }
  }

  Future<CommentRealtimeChange?> _toRealtimeChange(
    PostgresChangePayload payload,
  ) async {
    final eventType = payload.eventType;

    if (eventType == PostgresChangeEvent.delete) {
      final commentId =
          payload.oldRecord['id']?.toString() ??
          payload.newRecord['id']?.toString();
      final postId =
          payload.oldRecord['post_id']?.toString() ??
          (commentId != null ? _commentPostMap.remove(commentId) : null);

      if (commentId == null || postId == null) {
        return null;
      }

      return CommentRealtimeChange(
        type: CommentChangeType.delete,
        commentId: commentId,
        postId: postId,
      );
    }

    final commentId = payload.newRecord['id']?.toString();
    final postId = payload.newRecord['post_id']?.toString();

    if (commentId == null || postId == null) {
      return null;
    }

    _commentPostMap[commentId] = postId;

    Map<String, dynamic>? latestComment;
    try {
      latestComment = await _provider.fetchCommentById(commentId);
    } catch (_) {
      latestComment = null;
    }

    if (latestComment == null) {
      final payloadRecord = Map<String, dynamic>.from(payload.newRecord);
      final isSoftDeleted = payloadRecord['is_deleted'] == true;
      if (isSoftDeleted) {
        return CommentRealtimeChange(
          type: CommentChangeType.delete,
          commentId: commentId,
          postId: postId,
        );
      }

      if (payloadRecord.isNotEmpty) {
        return CommentRealtimeChange(
          type: eventType == PostgresChangeEvent.insert
              ? CommentChangeType.insert
              : CommentChangeType.update,
          commentId: commentId,
          postId: postId,
          commentData: payloadRecord,
        );
      }

      return CommentRealtimeChange(
        type: CommentChangeType.delete,
        commentId: commentId,
        postId: postId,
      );
    }

    return CommentRealtimeChange(
      type: eventType == PostgresChangeEvent.insert
          ? CommentChangeType.insert
          : CommentChangeType.update,
      commentId: commentId,
      postId: postId,
      commentData: latestComment,
    );
  }

  void _disposeChannelIfIdle(String postId) {
    final listeners = _postListeners[postId];
    if (listeners != null && listeners.isNotEmpty) {
      return;
    }

    final channel = _postChannels.remove(postId);
    if (channel == null) {
      return;
    }

    _client.removeChannel(channel);
  }

  Future<void> _createCommentNotification({
    required String postId,
    required String actorUserId,
  }) async {
    try {
      final post = await _client
          .from('posts')
          .select('id, user_id')
          .eq('id', postId)
          .maybeSingle();

      final receiverUserId = post?['user_id']?.toString();
      if (receiverUserId == null || receiverUserId.isEmpty) {
        return;
      }

      await NotificationEventHelper.create(
        client: _client,
        receiverUserId: receiverUserId,
        actorUserId: actorUserId,
        type: 'comment',
        title: 'New comment',
        message: 'Someone commented on your post',
        postId: postId,
      );
    } catch (error, stackTrace) {
      debugPrint('CommentService._createCommentNotification error: $error');
      debugPrint(
        'CommentService._createCommentNotification stack: $stackTrace',
      );
    }
  }
}
