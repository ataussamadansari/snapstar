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
    final previousLiked = likedPosts[postId] ?? false;
    final previousCount = likeCounts[postId] ?? 0;

    try {
      final liked = await _likeRepo.checkLikeStatus(postId);
      likedPosts[postId] = liked;

      try {
        likeCounts[postId] = await _likeRepo.getLikeCount(postId);
      } catch (error, stackTrace) {
        likeCounts[postId] = previousCount;
        if (!_isTransientNetworkError(error)) {
          debugPrint('LikeController._syncPostLikeState count error: $error');
          debugPrint(
            'LikeController._syncPostLikeState count stack: $stackTrace',
          );
        }
      }
    } catch (error, stackTrace) {
      likedPosts[postId] = previousLiked;
      likeCounts[postId] = previousCount;

      if (_isTransientNetworkError(error)) {
        return;
      }

      debugPrint('LikeController._syncPostLikeState error: $error');
      debugPrint('LikeController._syncPostLikeState stack: $stackTrace');
    }
  }

  bool _isTransientNetworkError(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('connection reset by peer') ||
        message.contains('connection closed before full header was received') ||
        message.contains('clientexception') ||
        message.contains('socketexception') ||
        message.contains('httpexception');
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
