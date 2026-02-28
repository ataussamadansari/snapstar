import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/post_model.dart';

class PostProvider {
  PostProvider(this._client);

  final SupabaseClient _client;

  Future<Map<String, dynamic>> createPost(Map<String, dynamic> data) async {
    final res = await _client
        .from('posts')
        .insert(data)
        .select('*, users(*)')
        .single();

    return Map<String, dynamic>.from(res);
  }

  Future<Map<String, dynamic>> updatePost({
    required String postId,
    required Map<String, dynamic> data,
  }) async {
    final res = await _client
        .from('posts')
        .update(data)
        .eq('id', postId)
        .select('*, users(*)')
        .single();

    return Map<String, dynamic>.from(res);
  }

  Future<void> softDeletePost(String postId) async {
    await _client
        .from('posts')
        .update({
          'is_deleted': true,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', postId);
  }

  Future<List<Map<String, dynamic>>> fetchFeedPosts({
    required int limit,
    required int offset,
  }) async {
    final res = await _client
        .from('posts')
        .select('*, users(*)')
        .eq('is_deleted', false)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return List<Map<String, dynamic>>.from(res);
  }

  Future<List<Map<String, dynamic>>> fetchUserPosts(
    String userId, {
    String? mediaType,
    required int limit,
    required int offset,
  }) async {
    var query = _client
        .from('posts')
        .select('*, users(*)')
        .eq('user_id', userId)
        .eq('is_deleted', false);

    if (mediaType != null) {
      query = query.eq('media_type', mediaType);
    }

    final res = await query
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return List<Map<String, dynamic>>.from(res);
  }

  Future<int> fetchUserPostsCount(String userId) async {
    final res = await _client
        .from('posts')
        .select('id')
        .eq('user_id', userId)
        .eq('is_deleted', false);

    return List<dynamic>.from(res).length;
  }

  Future<List<Map<String, dynamic>>> fetchVideoPosts({
    required int limit,
    required int offset,
  }) async {
    final res = await _client
        .from('posts')
        .select('*, users(*)')
        .eq('media_type', MediaType.video.name)
        .eq('is_deleted', false)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return List<Map<String, dynamic>>.from(res);
  }

  Future<List<Map<String, dynamic>>> searchPosts({
    required String query,
    required int limit,
    required int offset,
  }) async {
    final normalizedQuery = query.trim();
    if (normalizedQuery.isEmpty) {
      return <Map<String, dynamic>>[];
    }

    final res = await _client
        .from('posts')
        .select('*, users(*)')
        .eq('is_deleted', false)
        .or('caption.ilike.%$normalizedQuery%,location.ilike.%$normalizedQuery%')
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return List<Map<String, dynamic>>.from(res);
  }

  Future<Map<String, dynamic>?> fetchPostById(String postId) async {
    final res = await _client
        .from('posts')
        .select('*, users(*)')
        .eq('id', postId)
        .maybeSingle();

    if (res == null) {
      return null;
    }

    return Map<String, dynamic>.from(res);
  }

  Future<int> fetchShareCount(String postId) async {
    final res = await _client
        .from('posts')
        .select('share_count')
        .eq('id', postId)
        .maybeSingle();

    if (res == null) {
      return 0;
    }

    return (res['share_count'] as num?)?.toInt() ?? 0;
  }

  Future<void> incrementShareCount(String postId) async {
    final current = await fetchShareCount(postId);

    await _client
        .from('posts')
        .update({
          'share_count': current + 1,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', postId);
  }

  Future<String> uploadMedia({
    required File file,
    required String userId,
    required MediaType type,
  }) async {
    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}.${file.path.split('.').last}';

    final path = '$userId/${type.name}/$fileName';

    await _client.storage.from('posts').upload(path, file);

    return _client.storage.from('posts').getPublicUrl(path);
  }
}
