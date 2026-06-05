import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HashtagProvider {
  HashtagProvider(this._client);

  final SupabaseClient _client;

  /// Hashtag upsert karo aur uska ID return karo
  Future<int?> upsertHashtag(String tag) async {
    try {
      // Tag lowercase + trim
      final normalized = tag.trim().toLowerCase();
      if (normalized.isEmpty) return null;

      final res = await _client
          .from('hashtags')
          .upsert({'tag': normalized}, onConflict: 'tag')
          .select('id')
          .single();

      return res['id'] as int?;
    } catch (error, stackTrace) {
      debugPrint('HashtagProvider.upsertHashtag error: $error');
      debugPrint('HashtagProvider.upsertHashtag stack: $stackTrace');
      return null;
    }
  }

  /// Post ke liye hashtags link karo
  Future<void> linkHashtagsToPost({
    required String postId,
    required List<int> hashtagIds,
  }) async {
    if (hashtagIds.isEmpty) return;

    try {
      final rows = hashtagIds
          .map((id) => {'post_id': postId, 'hashtag_id': id})
          .toList();

      await _client
          .from('post_hashtags')
          .upsert(rows, onConflict: 'post_id,hashtag_id');
    } catch (error, stackTrace) {
      debugPrint('HashtagProvider.linkHashtagsToPost error: $error');
      debugPrint('HashtagProvider.linkHashtagsToPost stack: $stackTrace');
    }
  }

  /// Ek hashtag ke posts fetch karo
  Future<List<Map<String, dynamic>>> fetchPostsByHashtag({
    required String tag,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      // hashtag ID dhundo
      final hashtagRes = await _client
          .from('hashtags')
          .select('id')
          .eq('tag', tag.toLowerCase())
          .maybeSingle();

      if (hashtagRes == null) return [];

      final hashtagId = hashtagRes['id'] as int;

      // post_hashtags join karke posts lo
      final res = await _client
          .from('post_hashtags')
          .select('post_id, posts(*, users(*))')
          .eq('hashtag_id', hashtagId)
          .range(offset, offset + limit - 1);

      final posts = <Map<String, dynamic>>[];
      for (final row in res) {
        final postData = row['posts'];
        if (postData is Map<String, dynamic> &&
            postData['is_deleted'] != true) {
          posts.add(postData);
        }
      }
      return posts;
    } catch (error, stackTrace) {
      debugPrint('HashtagProvider.fetchPostsByHashtag error: $error');
      debugPrint('HashtagProvider.fetchPostsByHashtag stack: $stackTrace');
      return [];
    }
  }

  /// Trending hashtags fetch karo
  Future<List<Map<String, dynamic>>> fetchTrendingHashtags({
    int limit = 20,
  }) async {
    try {
      final res = await _client
          .from('hashtags')
          .select('id, tag, usage_count')
          .order('usage_count', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(res);
    } catch (error, stackTrace) {
      debugPrint('HashtagProvider.fetchTrendingHashtags error: $error');
      debugPrint('HashtagProvider.fetchTrendingHashtags stack: $stackTrace');
      return [];
    }
  }
}
