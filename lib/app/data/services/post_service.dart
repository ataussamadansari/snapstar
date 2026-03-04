import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/utils/cursor_page.dart';
import '../models/post_model.dart';
import '../providers/post_provider.dart';

enum PostChangeType { insert, update, delete }

class PostRealtimeChange {
  const PostRealtimeChange({
    required this.type,
    required this.postId,
    this.userId,
    this.postData,
  });

  final PostChangeType type;
  final String postId;
  final String? userId;
  final Map<String, dynamic>? postData;
}

class PostService {
  PostService(this._provider, this._client);

  final PostProvider _provider;
  final SupabaseClient _client;

  RealtimeChannel? _channel;
  final Set<void Function(PostRealtimeChange)> _listeners =
      <void Function(PostRealtimeChange)>{};

  Future<Map<String, dynamic>> createPost(Map<String, dynamic> data) async {
    try {
      return await _provider.createPost(data);
    } catch (error, stackTrace) {
      debugPrint('PostService.createPost error: $error');
      debugPrint('PostService.createPost stack: $stackTrace');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> editPost({
    required String postId,
    required Map<String, dynamic> data,
  }) async {
    try {
      return await _provider.updatePost(postId: postId, data: data);
    } catch (error, stackTrace) {
      debugPrint('PostService.editPost error: $error');
      debugPrint('PostService.editPost stack: $stackTrace');
      rethrow;
    }
  }

  Future<void> softDeletePost(String postId) async {
    try {
      await _provider.softDeletePost(postId);
    } catch (error, stackTrace) {
      debugPrint('PostService.softDeletePost error: $error');
      debugPrint('PostService.softDeletePost stack: $stackTrace');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> fetchFeedPosts({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      return await _provider.fetchFeedPosts(limit: limit, offset: offset);
    } catch (error, stackTrace) {
      debugPrint('PostService.fetchFeedPosts error: $error');
      debugPrint('PostService.fetchFeedPosts stack: $stackTrace');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> fetchExplorePosts({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      return await _provider.fetchExplorePosts(limit: limit, offset: offset);
    } catch (error, stackTrace) {
      debugPrint('PostService.fetchExplorePosts error: $error');
      debugPrint('PostService.fetchExplorePosts stack: $stackTrace');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> fetchTrendingPosts({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      return await _provider.fetchTrendingPosts(limit: limit, offset: offset);
    } catch (error, stackTrace) {
      debugPrint('PostService.fetchTrendingPosts error: $error');
      debugPrint('PostService.fetchTrendingPosts stack: $stackTrace');
      rethrow;
    }
  }

  Future<CursorPage<Map<String, dynamic>>> fetchFeedPostsByCursor({
    int limit = 20,
    DateTime? cursorCreatedAt,
    String? cursorId,
    double? cursorScore,
  }) async {
    try {
      return await _provider.fetchFeedPostsByCursor(
        limit: limit,
        cursorCreatedAt: cursorCreatedAt,
        cursorId: cursorId,
        cursorScore: cursorScore,
      );
    } catch (error, stackTrace) {
      debugPrint('PostService.fetchFeedPostsByCursor error: $error');
      debugPrint('PostService.fetchFeedPostsByCursor stack: $stackTrace');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> fetchUserPosts(
    String userId, {
    String? mediaType,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      return await _provider.fetchUserPosts(
        userId,
        mediaType: mediaType,
        limit: limit,
        offset: offset,
      );
    } catch (error, stackTrace) {
      debugPrint('PostService.fetchUserPosts error: $error');
      debugPrint('PostService.fetchUserPosts stack: $stackTrace');
      rethrow;
    }
  }

  Future<int> fetchUserPostsCount(String userId) async {
    try {
      return await _provider.fetchUserPostsCount(userId);
    } catch (error, stackTrace) {
      debugPrint('PostService.fetchUserPostsCount error: $error');
      debugPrint('PostService.fetchUserPostsCount stack: $stackTrace');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> fetchVideoPosts({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      return await _provider.fetchVideoPosts(limit: limit, offset: offset);
    } catch (error, stackTrace) {
      debugPrint('PostService.fetchVideoPosts error: $error');
      debugPrint('PostService.fetchVideoPosts stack: $stackTrace');
      rethrow;
    }
  }

  Future<CursorPage<Map<String, dynamic>>> fetchVideoPostsByCursor({
    int limit = 20,
    DateTime? cursorCreatedAt,
    String? cursorId,
  }) async {
    try {
      return await _provider.fetchVideoPostsByCursor(
        limit: limit,
        cursorCreatedAt: cursorCreatedAt,
        cursorId: cursorId,
      );
    } catch (error, stackTrace) {
      debugPrint('PostService.fetchVideoPostsByCursor error: $error');
      debugPrint('PostService.fetchVideoPostsByCursor stack: $stackTrace');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> searchPosts({
    required String query,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      return await _provider.searchPosts(
        query: query,
        limit: limit,
        offset: offset,
      );
    } catch (error, stackTrace) {
      debugPrint('PostService.searchPosts error: $error');
      debugPrint('PostService.searchPosts stack: $stackTrace');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> searchHashtags({
    required String query,
    int limit = 20,
  }) async {
    try {
      return await _provider.searchHashtags(query: query, limit: limit);
    } catch (error, stackTrace) {
      debugPrint('PostService.searchHashtags error: $error');
      debugPrint('PostService.searchHashtags stack: $stackTrace');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> fetchPostById(String postId) async {
    try {
      return await _provider.fetchPostById(postId);
    } catch (error, stackTrace) {
      debugPrint('PostService.fetchPostById error: $error');
      debugPrint('PostService.fetchPostById stack: $stackTrace');
      rethrow;
    }
  }

  Future<int> fetchShareCount(String postId) async {
    try {
      return await _provider.fetchShareCount(postId);
    } catch (error, stackTrace) {
      debugPrint('PostService.fetchShareCount error: $error');
      debugPrint('PostService.fetchShareCount stack: $stackTrace');
      rethrow;
    }
  }

  Future<void> incrementShareCount(String postId) async {
    try {
      await _provider.incrementShareCount(postId);
    } catch (error, stackTrace) {
      debugPrint('PostService.incrementShareCount error: $error');
      debugPrint('PostService.incrementShareCount stack: $stackTrace');
      rethrow;
    }
  }

  Future<String> uploadMedia({
    required File file,
    required String userId,
    required MediaType type,
  }) async {
    try {
      return await _provider.uploadMedia(
        file: file,
        userId: userId,
        type: type,
      );
    } catch (error, stackTrace) {
      debugPrint('PostService.uploadMedia error: $error');
      debugPrint('PostService.uploadMedia stack: $stackTrace');
      rethrow;
    }
  }

  VoidCallback subscribeToPosts({
    required void Function(PostRealtimeChange) onEvent,
  }) {
    _listeners.add(onEvent);
    _ensureChannel();

    return () {
      _listeners.remove(onEvent);
      _disposeChannelIfIdle();
    };
  }

  void _ensureChannel() {
    if (_channel != null) {
      return;
    }

    _channel = _client.channel('posts-realtime-channel');

    _channel!
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'posts',
        callback: _handleRealtimePayload,
      )
      ..subscribe();
  }

  void _disposeChannelIfIdle() {
    if (_channel == null || _listeners.isNotEmpty) {
      return;
    }

    _client.removeChannel(_channel!);
    _channel = null;
  }

  void _handleRealtimePayload(PostgresChangePayload payload) {
    _processRealtimePayload(payload);
  }

  Future<void> _processRealtimePayload(PostgresChangePayload payload) async {
    try {
      final change = await _toRealtimeChange(payload);
      if (change == null) {
        return;
      }

      for (final listener in _listeners.toList()) {
        listener(change);
      }
    } catch (error, stackTrace) {
      debugPrint('PostService._processRealtimePayload error: $error');
      debugPrint('PostService._processRealtimePayload stack: $stackTrace');
    }
  }

  Future<PostRealtimeChange?> _toRealtimeChange(
    PostgresChangePayload payload,
  ) async {
    final eventType = payload.eventType;

    if (eventType == PostgresChangeEvent.delete) {
      final id = payload.oldRecord['id']?.toString();
      if (id == null || id.isEmpty) {
        return null;
      }

      return PostRealtimeChange(
        type: PostChangeType.delete,
        postId: id,
        userId: payload.oldRecord['user_id']?.toString(),
      );
    }

    final id = payload.newRecord['id']?.toString();
    if (id == null || id.isEmpty) {
      return null;
    }

    final latestPost = await fetchPostById(id);

    if (latestPost == null || latestPost['is_deleted'] == true) {
      return PostRealtimeChange(
        type: PostChangeType.delete,
        postId: id,
        userId: payload.newRecord['user_id']?.toString(),
      );
    }

    return PostRealtimeChange(
      type: eventType == PostgresChangeEvent.insert
          ? PostChangeType.insert
          : PostChangeType.update,
      postId: id,
      userId: latestPost['user_id']?.toString(),
      postData: latestPost,
    );
  }
}
