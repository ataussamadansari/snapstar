import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SaveProvider {
  SaveProvider(this._client);

  final SupabaseClient _client;

  Future<bool> isSaved({
    required String postId,
    required String userId,
  }) async {
    final res = await _client
        .from('saved_posts')
        .select('id')
        .eq('post_id', postId)
        .eq('user_id', userId)
        .maybeSingle();
    return res != null;
  }

  Future<void> savePost({
    required String postId,
    required String userId,
  }) async {
    await _client.from('saved_posts').insert({
      'post_id': postId,
      'user_id': userId,
    });
  }

  Future<void> unsavePost({
    required String postId,
    required String userId,
  }) async {
    await _client
        .from('saved_posts')
        .delete()
        .eq('post_id', postId)
        .eq('user_id', userId);
  }

  Future<List<Map<String, dynamic>>> fetchSavedPosts({
    required String userId,
    int limit = 30,
    int offset = 0,
  }) async {
    try {
      final res = await _client
          .from('saved_posts')
          .select('post_id, created_at, posts(*, users(*))')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
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
      debugPrint('SaveProvider.fetchSavedPosts error: $error');
      debugPrint('SaveProvider.fetchSavedPosts stack: $stackTrace');
      return [];
    }
  }
}
