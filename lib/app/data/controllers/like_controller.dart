import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../data/repositories/like_repository.dart';

class LikeController extends GetxController {
  LikeController(this._likeRepo);

  final LikeRepository _likeRepo;

  final RxMap<String, bool> likedPosts = <String, bool>{}.obs;
  final RxMap<String, int> likeCounts = <String, int>{}.obs;

  final Map<String, VoidCallback> _likeListeners = {};

  void initializePost(String postId, int dbLikeCount) {
    likedPosts[postId] ??= false;
    likeCounts[postId] ??= dbLikeCount;

    _syncPostLikeState(postId);
    _ensureRealtime(postId);
  }

  Future<void> toggleLike(String postId) async {
    final wasLiked = likedPosts[postId] ?? false;

    likedPosts[postId] = !wasLiked;
    likeCounts[postId] = (likeCounts[postId] ?? 0) + (wasLiked ? -1 : 1);

    try {
      await _likeRepo.toggleLike(postId);
      await _syncPostLikeState(postId);
    } catch (error, stackTrace) {
      likedPosts[postId] = wasLiked;
      likeCounts[postId] = (likeCounts[postId] ?? 0) + (wasLiked ? 1 : -1);

      debugPrint('LikeController.toggleLike error: $error');
      debugPrint('LikeController.toggleLike stack: $stackTrace');
    }
  }

  bool isLiked(String postId) {
    return likedPosts[postId] ?? false;
  }

  int likeCount(String postId) {
    return likeCounts[postId] ?? 0;
  }

  void _ensureRealtime(String postId) {
    if (_likeListeners.containsKey(postId)) return;

    _likeListeners[postId] = _likeRepo.subscribeToPostLikes(
      postId: postId,
      onChanged: () => _syncPostLikeState(postId),
    );
  }

  Future<void> _syncPostLikeState(String postId) async {
    try {
      final results = await Future.wait([
        _likeRepo.checkLikeStatus(postId),
        _likeRepo.getLikeCount(postId),
      ]);

      likedPosts[postId] = results[0] as bool;
      likeCounts[postId] = results[1] as int;
    } catch (error, stackTrace) {
      debugPrint('LikeController._syncPostLikeState error: $error');
      debugPrint('LikeController._syncPostLikeState stack: $stackTrace');
    }
  }

  @override
  void onClose() {
    for (final unsubscribe in _likeListeners.values) {
      unsubscribe();
    }
    _likeListeners.clear();
    super.onClose();
  }
}