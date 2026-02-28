import 'dart:io';

import 'package:flutter/foundation.dart';

import '../models/post_model.dart';
import '../services/post_service.dart';

enum PostModelChangeType { insert, update, delete }

class PostModelChange {
  const PostModelChange({
    required this.type,
    required this.postId,
    this.post,
    this.userId,
  });

  final PostModelChangeType type;
  final String postId;
  final PostModel? post;
  final String? userId;
}

class PostRepository {
  PostRepository(this._service);

  final PostService _service;

  Future<void> createPost(PostModel post) async {
    await _service.createPost(post.toCreateJson());
  }

  Future<void> editPost({
    required String postId,
    required String caption,
    String? location,
  }) async {
    await _service.editPost(
      postId: postId,
      data: {
        'caption': caption,
        'location': location,
        'updated_at': DateTime.now().toIso8601String(),
      },
    );
  }

  Future<void> softDeletePost(String postId) {
    return _service.softDeletePost(postId);
  }

  Future<List<PostModel>> fetchFeedPosts({
    int limit = 20,
    int offset = 0,
  }) async {
    final raw = await _service.fetchFeedPosts(limit: limit, offset: offset);

    return raw.map((e) => PostModel.fromJson(e)).toList();
  }

  Future<List<PostModel>> fetchUserPosts(
    String userId, {
    MediaType? type,
    int limit = 50,
    int offset = 0,
  }) async {
    final raw = await _service.fetchUserPosts(
      userId,
      mediaType: type?.name,
      limit: limit,
      offset: offset,
    );

    return raw.map((e) => PostModel.fromJson(e)).toList();
  }

  Future<int> fetchUserPostsCount(String userId) {
    return _service.fetchUserPostsCount(userId);
  }

  Future<List<PostModel>> fetchReels({int limit = 20, int offset = 0}) async {
    final raw = await _service.fetchVideoPosts(limit: limit, offset: offset);
    return raw.map((e) => PostModel.fromJson(e)).toList();
  }

  Future<List<PostModel>> searchPosts({
    required String query,
    int limit = 30,
    int offset = 0,
  }) async {
    final raw = await _service.searchPosts(
      query: query,
      limit: limit,
      offset: offset,
    );

    return raw.map((e) => PostModel.fromJson(e)).toList();
  }

  Future<int> getShareCount(String postId) {
    return _service.fetchShareCount(postId);
  }

  Future<void> incrementShareCount(String postId) {
    return _service.incrementShareCount(postId);
  }

  Future<String> uploadMedia({
    required File file,
    required String userId,
    required MediaType type,
  }) {
    return _service.uploadMedia(file: file, userId: userId, type: type);
  }

  VoidCallback subscribeToFeedChanges({
    required void Function(PostModelChange) onEvent,
  }) {
    return _service.subscribeToPosts(
      onEvent: (change) {
        final converted = _toModelChange(change);
        if (converted != null) {
          onEvent(converted);
        }
      },
    );
  }

  VoidCallback subscribeToUserPostChanges({
    required String userId,
    required void Function(PostModelChange) onEvent,
  }) {
    return _service.subscribeToPosts(
      onEvent: (change) {
        final converted = _toModelChange(change);
        if (converted == null) {
          return;
        }

        if (converted.userId == userId ||
            (converted.type == PostModelChangeType.delete &&
                converted.userId == userId)) {
          onEvent(converted);
        }
      },
    );
  }

  VoidCallback listenToFeedPosts({required VoidCallback onChanged}) {
    return subscribeToFeedChanges(onEvent: (_) => onChanged());
  }

  VoidCallback listenToUserPosts({
    required String userId,
    required VoidCallback onChanged,
  }) {
    return subscribeToUserPostChanges(
      userId: userId,
      onEvent: (_) => onChanged(),
    );
  }

  List<PostModel> mergeFeedPosts({
    required List<PostModel> current,
    required PostModelChange change,
  }) {
    final next = List<PostModel>.from(current);

    switch (change.type) {
      case PostModelChangeType.insert:
        if (change.post == null) {
          return next;
        }

        next.removeWhere((item) => item.id == change.post!.id);
        next.insert(0, change.post!);
        return next;
      case PostModelChangeType.update:
        if (change.post == null) {
          return next;
        }

        final index = next.indexWhere((item) => item.id == change.post!.id);
        if (index >= 0) {
          next[index] = change.post!;
        } else {
          next.insert(0, change.post!);
        }
        return next;
      case PostModelChangeType.delete:
        next.removeWhere((item) => item.id == change.postId);
        return next;
    }
  }

  PostModelChange? _toModelChange(PostRealtimeChange change) {
    try {
      final post = change.postData != null
          ? PostModel.fromJson(change.postData!)
          : null;

      switch (change.type) {
        case PostChangeType.insert:
          return PostModelChange(
            type: PostModelChangeType.insert,
            postId: change.postId,
            post: post,
            userId: change.userId,
          );
        case PostChangeType.update:
          return PostModelChange(
            type: PostModelChangeType.update,
            postId: change.postId,
            post: post,
            userId: change.userId,
          );
        case PostChangeType.delete:
          return PostModelChange(
            type: PostModelChangeType.delete,
            postId: change.postId,
            userId: change.userId,
          );
      }
    } catch (error, stackTrace) {
      debugPrint('PostRepository._toModelChange error: $error');
      debugPrint('PostRepository._toModelChange stack: $stackTrace');
      return null;
    }
  }
}
