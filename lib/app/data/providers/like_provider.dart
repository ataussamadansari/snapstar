import 'package:supabase_flutter/supabase_flutter.dart';

class LikeProvider {
  LikeProvider(this._client);

  final SupabaseClient _client;

  Future<Map<String, dynamic>?> getLike({
    required String postId,
    required String userId,
  }) async {
    final res = await _client
        .from('likes')
        .select('id, post_id, user_id')
        .eq('post_id', postId)
        .eq('user_id', userId)
        .maybeSingle();

    if (res == null) {
      return null;
    }

    return Map<String, dynamic>.from(res);
  }

  Future<void> insertLike({
    required String postId,
    required String userId,
  }) async {
    await _client.from('likes').insert({
      'post_id': postId,
      'user_id': userId,
    });
  }

  Future<void> removeLike({
    required String postId,
    required String userId,
  }) async {
    await _client.from('likes').delete().match({
      'post_id': postId,
      'user_id': userId,
    });
  }

  Future<int> fetchLikeCount(String postId) async {
    final res = await _client.from('likes').select('id').eq('post_id', postId);
    return (res as List).length;
  }

  Future<List<Map<String, dynamic>>> fetchLikes(String postId) async {
    final res = await _client
        .from('likes')
        .select('*, users(*)')
        .eq('post_id', postId)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(res);
  }

  Future<void> callIncrementLikeRpc(String postId) async {
    await _client.rpc('increment_post_like_count', params: {
      'p_post_id': postId,
    });
  }

  Future<void> callDecrementLikeRpc(String postId) async {
    await _client.rpc('decrement_post_like_count', params: {
      'p_post_id': postId,
    });
  }

  Future<void> updatePostLikeCount({
    required String postId,
    required int likeCount,
  }) async {
    await _client.from('posts').update({
      'like_count': likeCount,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', postId);
  }
}
