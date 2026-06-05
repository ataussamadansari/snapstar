import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../providers/comment_like_provider.dart';
import 'auth_controller.dart';

class CommentLikeController extends GetxController {
  CommentLikeController(this._provider);

  final CommentLikeProvider _provider;

  // commentId → liked state
  final RxMap<String, bool> _liked = <String, bool>{}.obs;
  // commentId → like count
  final RxMap<String, int> _counts = <String, int>{}.obs;
  // commentId → loading
  final RxSet<String> _loading = <String>{}.obs;

  String? get _myId {
    final auth = Get.find<AuthController>();
    return auth.currentUserId;
  }

  void initComment(String commentId, {int initialCount = 0}) {
    if (_liked.containsKey(commentId)) return;
    _liked[commentId] = false;
    _counts[commentId] = initialCount;
    _syncState(commentId);
  }

  bool isLiked(String commentId) => _liked[commentId] ?? false;
  int likeCount(String commentId) => _counts[commentId] ?? 0;
  bool isLoading(String commentId) => _loading.contains(commentId);

  Future<void> toggleLike(String commentId) async {
    final userId = _myId;
    if (userId == null) return;
    if (_loading.contains(commentId)) return;

    final prev = _liked[commentId] ?? false;
    final prevCount = _counts[commentId] ?? 0;

    // Optimistic
    _liked[commentId] = !prev;
    _counts[commentId] = prevCount + (prev ? -1 : 1);
    _loading.add(commentId);

    try {
      if (prev) {
        await _provider.unlikeComment(commentId: commentId, userId: userId);
      } else {
        await _provider.likeComment(commentId: commentId, userId: userId);
      }
      // Sync real count
      _counts[commentId] = await _provider.fetchLikeCount(commentId);
    } catch (error, stackTrace) {
      // Rollback
      _liked[commentId] = prev;
      _counts[commentId] = prevCount;
      debugPrint('CommentLikeController.toggleLike error: $error');
      debugPrint('CommentLikeController.toggleLike stack: $stackTrace');
    } finally {
      _loading.remove(commentId);
    }
  }

  Future<void> _syncState(String commentId) async {
    final userId = _myId;
    if (userId == null) return;
    try {
      final liked = await _provider.isLiked(
        commentId: commentId,
        userId: userId,
      );
      _liked[commentId] = liked;
      _counts[commentId] = await _provider.fetchLikeCount(commentId);
    } catch (_) {}
  }
}
