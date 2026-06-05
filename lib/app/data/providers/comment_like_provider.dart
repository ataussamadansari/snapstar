import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CommentLikeProvider {
  CommentLikeProvider(this._client);

  final SupabaseClient _client;

  Future<bool> isLiked({
    required String commentId,
    required String userId,
  }) async {
    final res = await _client
        .from('comment_likes')
        .select('id')
        .eq('comment_id', commentId)
        .eq('user_id', userId)
        .maybeSingle();
    return res != null;
  }

  Future<void> likeComment({
    required String commentId,
    required String userId,
  }) async {
    await _client.from('comment_likes').insert({
      'comment_id': commentId,
      'user_id': userId,
    });
  }

  Future<void> unlikeComment({
    required String commentId,
    required String userId,
  }) async {
    await _client
        .from('comment_likes')
        .delete()
        .eq('comment_id', commentId)
        .eq('user_id', userId);
  }

  Future<int> fetchLikeCount(String commentId) async {
    try {
      final res = await _client
          .from('comment_likes')
          .select('id')
          .eq('comment_id', commentId);
      return (res as List).length;
    } catch (error, stackTrace) {
      debugPrint('CommentLikeProvider.fetchLikeCount error: $error');
      debugPrint('CommentLikeProvider.fetchLikeCount stack: $stackTrace');
      return 0;
    }
  }
}
