import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/utils/cursor_page.dart';
import '../models/post_model.dart';

class PostProvider {
  PostProvider(this._client);

  final SupabaseClient _client;

  Future<List<String>?> _buildFeedAuthorIds() async {
    final myId = _client.auth.currentUser?.id;
    if (myId == null) {
      return null;
    }

    final subscribedRows = await _client
        .from('subscribes')
        .select('subscribed_id')
        .eq('subscriber_id', myId);

    final ids = <String>{myId};
    for (final row in subscribedRows) {
      final id = row['subscribed_id']?.toString();
      if (id != null && id.isNotEmpty) {
        ids.add(id);
      }
    }
    return ids.toList();
  }

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
    final feedAuthorIds = await _buildFeedAuthorIds();
    var query = _client
        .from('posts')
        .select('*, users(*)')
        .eq('is_deleted', false);
    if (feedAuthorIds != null && feedAuthorIds.isNotEmpty) {
      query = query.inFilter('user_id', feedAuthorIds);
    }

    final res = await query
        .order('created_at', ascending: false)
        .order('id', ascending: false)
        .range(offset, offset + limit - 1);

    return List<Map<String, dynamic>>.from(res);
  }

  Future<List<Map<String, dynamic>>> fetchExplorePosts({
    required int limit,
    required int offset,
  }) async {
    final res = await _client
        .from('posts')
        .select('*, users(*)')
        .eq('is_deleted', false)
        .order('created_at', ascending: false)
        .order('id', ascending: false)
        .range(offset, offset + limit - 1);

    return List<Map<String, dynamic>>.from(res);
  }

  Future<List<Map<String, dynamic>>> fetchTrendingPosts({
    required int limit,
    required int offset,
  }) async {
    final res = await _client
        .from('posts')
        .select('*, users(*)')
        .eq('is_deleted', false)
        .order('share_count', ascending: false)
        .order('comment_count', ascending: false)
        .order('like_count', ascending: false)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return List<Map<String, dynamic>>.from(res);
  }

  Future<CursorPage<Map<String, dynamic>>> fetchFeedPostsByCursor({
    required int limit,
    DateTime? cursorCreatedAt,
    String? cursorId,
    double? cursorScore,
  }) async {
    try {
      final myId = _client.auth.currentUser?.id;
      final rpc = await _client.rpc(
        'get_ranked_feed',
        params: {
          'p_user_id': myId,
          'p_limit': limit,
          'p_cursor_score': cursorScore,
          'p_cursor_created_at': cursorCreatedAt?.toUtc().toIso8601String(),
          'p_cursor_id': cursorId,
        },
      );

      final rows = List<Map<String, dynamic>>.from(rpc);
      DateTime? nextCreatedAt;
      String? nextId;
      double? nextScore;
      if (rows.isNotEmpty) {
        final last = rows.last;
        nextCreatedAt = DateTime.tryParse(last['created_at']?.toString() ?? '');
        nextId = last['id']?.toString();
        nextScore = (last['rank_score'] as num?)?.toDouble();
      }

      return CursorPage<Map<String, dynamic>>(
        items: rows,
        nextCursorCreatedAt: nextCreatedAt?.toUtc(),
        nextCursorId: nextId,
        nextCursorScore: nextScore,
        hasMore:
            rows.length >= limit && nextCreatedAt != null && nextId != null,
      );
    } catch (_) {
      final feedAuthorIds = await _buildFeedAuthorIds();
      var query = _client
          .from('posts')
          .select('*, users(*)')
          .eq('is_deleted', false);
      if (feedAuthorIds != null && feedAuthorIds.isNotEmpty) {
        query = query.inFilter('user_id', feedAuthorIds);
      }

      if (cursorCreatedAt != null && cursorId != null) {
        final cursorIso = cursorCreatedAt.toUtc().toIso8601String();
        query = query.or(
          'created_at.lt.$cursorIso,and(created_at.eq.$cursorIso,id.lt.$cursorId)',
        );
      }

      final res = await query
          .order('created_at', ascending: false)
          .order('id', ascending: false)
          .limit(limit);

      final rows = List<Map<String, dynamic>>.from(res);
      return _toCursorPage(rows, limit);
    }
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

  Future<CursorPage<Map<String, dynamic>>> fetchVideoPostsByCursor({
    required int limit,
    DateTime? cursorCreatedAt,
    String? cursorId,
  }) async {
    var query = _client
        .from('posts')
        .select('*, users(*)')
        .eq('media_type', MediaType.video.name)
        .eq('is_deleted', false);

    if (cursorCreatedAt != null && cursorId != null) {
      final cursorIso = cursorCreatedAt.toUtc().toIso8601String();
      query = query.or(
        'created_at.lt.$cursorIso,and(created_at.eq.$cursorIso,id.lt.$cursorId)',
      );
    }

    final res = await query
        .order('created_at', ascending: false)
        .order('id', ascending: false)
        .limit(limit);

    final rows = List<Map<String, dynamic>>.from(res);
    return _toCursorPage(rows, limit);
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

    try {
      final rpc = await _client.rpc(
        'search_posts_with_hashtags',
        params: {
          'p_query': normalizedQuery,
          'p_limit': limit,
          'p_offset': offset,
        },
      );
      return List<Map<String, dynamic>>.from(rpc);
    } catch (_) {
      final res = await _client
          .from('posts')
          .select('*, users(*)')
          .eq('is_deleted', false)
          .or(
            'caption.ilike.%$normalizedQuery%,location.ilike.%$normalizedQuery%',
          )
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return List<Map<String, dynamic>>.from(res);
    }
  }

  Future<List<Map<String, dynamic>>> searchHashtags({
    required String query,
    int limit = 20,
  }) async {
    final normalizedQuery = query.trim();
    if (normalizedQuery.isEmpty) {
      try {
        final top = await _client
            .from('hashtags')
            .select('tag, usage_count')
            .order('usage_count', ascending: false)
            .order('tag', ascending: true)
            .limit(limit);
        return List<Map<String, dynamic>>.from(top).map((row) {
          final mapped = Map<String, dynamic>.from(row);
          mapped['post_count'] = mapped['usage_count'] ?? 0;
          return mapped;
        }).toList();
      } catch (_) {
        return <Map<String, dynamic>>[];
      }
    }

    try {
      final rpc = await _client.rpc(
        'search_hashtags',
        params: {'p_query': normalizedQuery, 'p_limit': limit},
      );
      return List<Map<String, dynamic>>.from(rpc);
    } catch (_) {
      return <Map<String, dynamic>>[];
    }
  }

  CursorPage<Map<String, dynamic>> _toCursorPage(
    List<Map<String, dynamic>> rows,
    int limit,
  ) {
    DateTime? nextCreatedAt;
    String? nextId;
    if (rows.isNotEmpty) {
      final last = rows.last;
      nextCreatedAt = DateTime.tryParse(last['created_at']?.toString() ?? '');
      nextId = last['id']?.toString();
    }

    return CursorPage<Map<String, dynamic>>(
      items: rows,
      nextCursorCreatedAt: nextCreatedAt?.toUtc(),
      nextCursorId: nextId,
      nextCursorScore: null,
      hasMore: rows.length >= limit && nextCreatedAt != null && nextId != null,
    );
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
