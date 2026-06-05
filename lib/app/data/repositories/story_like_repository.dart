import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Handles all story-like DB operations.
class StoryLikeRepository {
  StoryLikeRepository();

  final _client = Supabase.instance.client;

  String? get _myId => _client.auth.currentUser?.id;

  // ─── Toggle ────────────────────────────────────────────────────────────────

  /// Like karo agar nahi kiya, unlike karo agar pehle se kiya hua hai.
  /// Returns the new liked state.
  Future<bool> toggleLike(String storyId) async {
    final myId = _myId;
    if (myId == null) return false;

    final existing = await _client
        .from('story_likes')
        .select('id')
        .eq('story_id', storyId)
        .eq('user_id', myId)
        .maybeSingle();

    if (existing != null) {
      await _client
          .from('story_likes')
          .delete()
          .eq('story_id', storyId)
          .eq('user_id', myId);
      return false;
    } else {
      await _client.from('story_likes').insert({
        'story_id': storyId,
        'user_id': myId,
      });
      return true;
    }
  }

  // ─── Check ─────────────────────────────────────────────────────────────────

  Future<bool> isLiked(String storyId) async {
    final myId = _myId;
    if (myId == null) return false;

    final row = await _client
        .from('story_likes')
        .select('id')
        .eq('story_id', storyId)
        .eq('user_id', myId)
        .maybeSingle();

    return row != null;
  }

  // ─── Count ─────────────────────────────────────────────────────────────────

  /// Denormalised column se fast read.
  Future<int> getLikeCount(String storyId) async {
    try {
      final row = await _client
          .from('stories')
          .select('like_count')
          .eq('id', storyId)
          .maybeSingle();
      return (row?['like_count'] as num?)?.toInt() ?? 0;
    } catch (e, st) {
      debugPrint('StoryLikeRepository.getLikeCount error: $e\n$st');
      return 0;
    }
  }

  // ─── View Count ────────────────────────────────────────────────────────────

  Future<int> getViewCount(String storyId) async {
    try {
      final rows = await _client
          .from('story_views')
          .select('id')
          .eq('story_id', storyId);
      return (rows as List).length;
    } catch (e, st) {
      debugPrint('StoryLikeRepository.getViewCount error: $e\n$st');
      return 0;
    }
  }
}
