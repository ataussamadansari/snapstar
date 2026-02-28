import 'package:supabase_flutter/supabase_flutter.dart';

class CommentProvider {
  CommentProvider(this._client);

  final SupabaseClient _client;
  bool _supportsSoftDelete = true;

  Future<void> createComment(Map<String, dynamic> data) async {
    await _client.from('comments').insert(data);
  }

  Future<List<Map<String, dynamic>>> fetchComments(String postId) async {
    try {
      if (_supportsSoftDelete) {
        final response = await _client
            .from('comments')
            .select('*, users(*)')
            .eq('post_id', postId)
            .eq('is_deleted', false)
            .order('created_at', ascending: true);

        return List<Map<String, dynamic>>.from(response);
      }
    } on PostgrestException catch (error) {
      if (_isMissingSoftDeleteColumn(error)) {
        _supportsSoftDelete = false;
      } else {
        rethrow;
      }
    }

    final response = await _client
        .from('comments')
        .select('*, users(*)')
        .eq('post_id', postId)
        .order('created_at', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<int> fetchCommentCount(String postId) async {
    try {
      if (_supportsSoftDelete) {
        final response = await _client
            .from('comments')
            .select('id')
            .eq('post_id', postId)
            .eq('is_deleted', false);

        return (response as List).length;
      }
    } on PostgrestException catch (error) {
      if (_isMissingSoftDeleteColumn(error)) {
        _supportsSoftDelete = false;
      } else {
        rethrow;
      }
    }

    final response = await _client
        .from('comments')
        .select('id')
        .eq('post_id', postId);

    return (response as List).length;
  }

  Future<Map<String, dynamic>?> fetchCommentById(String commentId) async {
    try {
      if (_supportsSoftDelete) {
        final response = await _client
            .from('comments')
            .select('*, users(*)')
            .eq('id', commentId)
            .eq('is_deleted', false)
            .maybeSingle();

        if (response == null) {
          return null;
        }

        return Map<String, dynamic>.from(response);
      }
    } on PostgrestException catch (error) {
      if (_isMissingSoftDeleteColumn(error)) {
        _supportsSoftDelete = false;
      } else {
        rethrow;
      }
    }

    final response = await _client
        .from('comments')
        .select('*, users(*)')
        .eq('id', commentId)
        .maybeSingle();

    if (response == null) {
      return null;
    }

    return Map<String, dynamic>.from(response);
  }

  Future<void> updateComment(String id, String newText) async {
    await _client
        .from('comments')
        .update({
          'comment_text': newText,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id);
  }

  Future<void> softDeleteComment(String id) async {
    if (!_supportsSoftDelete) {
      throw PostgrestException(message: 'Soft delete column unavailable');
    }

    await _client
        .from('comments')
        .update({
          'is_deleted': true,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id);
  }

  Future<void> hardDeleteComment(String id) async {
    await _client.from('comments').delete().eq('id', id);
  }

  Future<void> callIncrementCommentRpc(String postId) async {
    await _client.rpc(
      'increment_post_comment_count',
      params: {'p_post_id': postId},
    );
  }

  Future<void> callDecrementCommentRpc(String postId) async {
    await _client.rpc(
      'decrement_post_comment_count',
      params: {'p_post_id': postId},
    );
  }

  Future<void> updatePostCommentCount({
    required String postId,
    required int commentCount,
  }) async {
    await _client
        .from('posts')
        .update({
          'comment_count': commentCount,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', postId);
  }

  bool _isMissingSoftDeleteColumn(PostgrestException error) {
    final message = error.message.toLowerCase();
    final details = (error.details?.toString() ?? '').toLowerCase();

    return error.code == '42703' ||
        message.contains('is_deleted') ||
        details.contains('is_deleted');
  }
}
