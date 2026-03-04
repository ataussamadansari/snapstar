import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'notification_event_helper.dart';
import '../providers/like_provider.dart';

class LikeService {
  LikeService(
    this._provider,
    this._client,
  );

  final LikeProvider _provider;
  final SupabaseClient _client;

  final Map<String, Set<VoidCallback>> _postListeners =
      <String, Set<VoidCallback>>{};
  final Map<String, RealtimeChannel> _postChannels = <String, RealtimeChannel>{};

  Future<bool> toggleLike({
    required String postId,
    required String userId,
  }) async {
    try {
      final existing = await _provider.getLike(
        postId: postId,
        userId: userId,
      );

      if (existing != null) {
        await _provider.removeLike(
          postId: postId,
          userId: userId,
        );

        await _updateLikeCount(postId: postId, isLikeAction: false);
        return false;
      }

      try {
        await _provider.insertLike(
          postId: postId,
          userId: userId,
        );
      } on PostgrestException catch (error) {
        if (_isUniqueViolation(error)) {
          return true;
        }
        rethrow;
      }

      await _updateLikeCount(postId: postId, isLikeAction: true);
      await _createLikeNotification(postId: postId, actorUserId: userId);
      return true;
    } catch (error, stackTrace) {
      debugPrint('LikeService.toggleLike error: $error');
      debugPrint('LikeService.toggleLike stack: $stackTrace');
      rethrow;
    }
  }

  Future<bool> isPostLiked(String postId, String userId) async {
    try {
      final existing = await _provider.getLike(
        postId: postId,
        userId: userId,
      );
      return existing != null;
    } catch (error, stackTrace) {
      debugPrint('LikeService.isPostLiked error: $error');
      debugPrint('LikeService.isPostLiked stack: $stackTrace');
      rethrow;
    }
  }

  Future<int> fetchLikeCount(String postId) async {
    try {
      return await _provider.fetchLikeCount(postId);
    } catch (error, stackTrace) {
      debugPrint('LikeService.fetchLikeCount error: $error');
      debugPrint('LikeService.fetchLikeCount stack: $stackTrace');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> fetchLikes(String postId) async {
    try {
      return await _provider.fetchLikes(postId);
    } catch (error, stackTrace) {
      debugPrint('LikeService.fetchLikes error: $error');
      debugPrint('LikeService.fetchLikes stack: $stackTrace');
      rethrow;
    }
  }

  VoidCallback subscribeToPostLikes({
    required String postId,
    required VoidCallback onChanged,
  }) {
    _postListeners.putIfAbsent(postId, () => <VoidCallback>{});
    _postListeners[postId]!.add(onChanged);

    _ensureRealtimeChannelForPost(postId);

    return () {
      final listeners = _postListeners[postId];
      if (listeners == null) {
        return;
      }

      listeners.remove(onChanged);
      if (listeners.isEmpty) {
        _postListeners.remove(postId);
      }

      _disposeChannelIfIdle(postId);
    };
  }

  Future<void> _updateLikeCount({
    required String postId,
    required bool isLikeAction,
  }) async {
    try {
      if (isLikeAction) {
        await _provider.callIncrementLikeRpc(postId);
      } else {
        await _provider.callDecrementLikeRpc(postId);
      }
    } catch (error, stackTrace) {
      debugPrint('LikeService._updateLikeCount rpc error: $error');
      debugPrint('LikeService._updateLikeCount rpc stack: $stackTrace');
      await _syncLikeCountFallback(postId);
    }
  }

  Future<void> _syncLikeCountFallback(String postId) async {
    try {
      final latestLikeCount = await _provider.fetchLikeCount(postId);
      await _provider.updatePostLikeCount(
        postId: postId,
        likeCount: latestLikeCount,
      );
    } catch (error, stackTrace) {
      debugPrint('LikeService._syncLikeCountFallback error: $error');
      debugPrint('LikeService._syncLikeCountFallback stack: $stackTrace');
    }
  }

  bool _isUniqueViolation(PostgrestException error) {
    return error.code == '23505';
  }

  Future<void> _createLikeNotification({
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
        type: 'like',
        title: 'New like',
        message: 'Someone liked your post',
        postId: postId,
      );
    } catch (error, stackTrace) {
      debugPrint('LikeService._createLikeNotification error: $error');
      debugPrint('LikeService._createLikeNotification stack: $stackTrace');
    }
  }

  void _ensureRealtimeChannelForPost(String postId) {
    if (_postChannels.containsKey(postId)) {
      return;
    }

    final channel = _client.channel('likes-posts-realtime-$postId');
    _postChannels[postId] = channel;

    channel
      ..onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'posts',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'id',
          value: postId,
        ),
        callback: _handlePostRealtime,
      )
      ..subscribe();
  }

  void _handlePostRealtime(PostgresChangePayload payload) {
    final postId = payload.newRecord['id']?.toString();
    if (postId == null || postId.isEmpty) {
      return;
    }

    if (payload.newRecord['is_deleted'] == true) {
      return;
    }

    final listeners = _postListeners[postId];
    if (listeners == null || listeners.isEmpty) {
      return;
    }

    for (final listener in listeners.toList()) {
      listener();
    }
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
}
