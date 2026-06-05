import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../repositories/story_like_repository.dart';

/// Global controller — story likes + view counts manage karta hai.
/// LikeController jaisa hi pattern, sirf stories ke liye.
class StoryLikeController extends GetxController {
  StoryLikeController(this._repo);

  final StoryLikeRepository _repo;

  // storyId → liked state
  final RxMap<String, bool> likedStories = <String, bool>{}.obs;
  // storyId → like count
  final RxMap<String, int> likeCounts = <String, int>{}.obs;
  // storyId → view count
  final RxMap<String, int> viewCounts = <String, int>{}.obs;

  // ─── Initialize ────────────────────────────────────────────────────────────

  /// Story card / viewer mein call karo — ek baar per story.
  void initializeStory(String storyId, {int dbLikeCount = 0, int dbViewCount = 0}) {
    likedStories[storyId] ??= false;
    likeCounts[storyId] ??= dbLikeCount;
    viewCounts[storyId] ??= dbViewCount;

    // Background mein fresh state lo
    _syncStoryState(storyId);
  }

  // ─── Toggle Like ───────────────────────────────────────────────────────────

  Future<void> toggleLike(String storyId) async {
    final wasLiked = likedStories[storyId] ?? false;

    // Optimistic update
    likedStories[storyId] = !wasLiked;
    likeCounts[storyId] = (likeCounts[storyId] ?? 0) + (wasLiked ? -1 : 1);

    try {
      final nowLiked = await _repo.toggleLike(storyId);
      likedStories[storyId] = nowLiked;
      likeCounts[storyId] = await _repo.getLikeCount(storyId);
    } catch (error, stackTrace) {
      // Rollback on error
      likedStories[storyId] = wasLiked;
      likeCounts[storyId] = (likeCounts[storyId] ?? 0) + (wasLiked ? 1 : -1);
      debugPrint('StoryLikeController.toggleLike error: $error');
      debugPrint('StoryLikeController.toggleLike stack: $stackTrace');
    }
  }

  // ─── Getters ───────────────────────────────────────────────────────────────

  bool isLiked(String storyId) => likedStories[storyId] ?? false;
  int likeCount(String storyId) => likeCounts[storyId] ?? 0;
  int viewCount(String storyId) => viewCounts[storyId] ?? 0;

  // ─── Sync ──────────────────────────────────────────────────────────────────

  Future<void> _syncStoryState(String storyId) async {
    try {
      final results = await Future.wait([
        _repo.isLiked(storyId),
        _repo.getLikeCount(storyId),
        _repo.getViewCount(storyId),
      ]);

      likedStories[storyId] = results[0] as bool;
      likeCounts[storyId] = results[1] as int;
      viewCounts[storyId] = results[2] as int;
    } catch (error, stackTrace) {
      debugPrint('StoryLikeController._syncStoryState error: $error');
      debugPrint('StoryLikeController._syncStoryState stack: $stackTrace');
    }
  }

  /// View count manually refresh karo (story viewer close hone ke baad).
  Future<void> refreshViewCount(String storyId) async {
    try {
      viewCounts[storyId] = await _repo.getViewCount(storyId);
    } catch (_) {}
  }
}
