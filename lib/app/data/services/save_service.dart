import 'package:flutter/foundation.dart';

import '../providers/save_provider.dart';

class SaveService {
  SaveService(this._provider);

  final SaveProvider _provider;

  Future<bool> isSaved({
    required String postId,
    required String userId,
  }) async {
    try {
      return await _provider.isSaved(postId: postId, userId: userId);
    } catch (error, stackTrace) {
      debugPrint('SaveService.isSaved error: $error');
      debugPrint('SaveService.isSaved stack: $stackTrace');
      return false;
    }
  }

  Future<void> savePost({
    required String postId,
    required String userId,
  }) async {
    try {
      await _provider.savePost(postId: postId, userId: userId);
    } catch (error, stackTrace) {
      debugPrint('SaveService.savePost error: $error');
      debugPrint('SaveService.savePost stack: $stackTrace');
      rethrow;
    }
  }

  Future<void> unsavePost({
    required String postId,
    required String userId,
  }) async {
    try {
      await _provider.unsavePost(postId: postId, userId: userId);
    } catch (error, stackTrace) {
      debugPrint('SaveService.unsavePost error: $error');
      debugPrint('SaveService.unsavePost stack: $stackTrace');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> fetchSavedPosts({
    required String userId,
    int limit = 30,
    int offset = 0,
  }) async {
    try {
      return await _provider.fetchSavedPosts(
        userId: userId,
        limit: limit,
        offset: offset,
      );
    } catch (error, stackTrace) {
      debugPrint('SaveService.fetchSavedPosts error: $error');
      debugPrint('SaveService.fetchSavedPosts stack: $stackTrace');
      return [];
    }
  }
}
