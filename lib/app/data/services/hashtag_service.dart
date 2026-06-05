import 'package:flutter/foundation.dart';

import '../providers/hashtag_provider.dart';

class HashtagService {
  HashtagService(this._provider);

  final HashtagProvider _provider;
  static const Duration _cacheTtl = Duration(minutes: 30);
  final Map<String, _HashtagCacheEntry> _cache = {};
  final Map<String, Future<List<Map<String, dynamic>>>> _inFlight = {};

  /// Post create hone ke baad hashtags process karo
  /// Returns: void — fire and forget safe hai
  Future<void> processPostHashtags({
    required String postId,
    required List<String> tags,
  }) async {
    if (tags.isEmpty) return;

    try {
      final hashtagIds = <int>[];

      for (final tag in tags) {
        final id = await _provider.upsertHashtag(tag);
        if (id != null) hashtagIds.add(id);
      }

      if (hashtagIds.isEmpty) return;

      await _provider.linkHashtagsToPost(
        postId: postId,
        hashtagIds: hashtagIds,
      );
      _cache.clear();
    } catch (error, stackTrace) {
      debugPrint('HashtagService.processPostHashtags error: $error');
      debugPrint('HashtagService.processPostHashtags stack: $stackTrace');
      // Non-critical — hashtag failure se post create fail nahi honi chahiye
    }
  }

  Future<List<Map<String, dynamic>>> fetchPostsByHashtag({
    required String tag,
    int limit = 20,
    int offset = 0,
  }) async {
    final key = 'posts:${tag.trim().toLowerCase()}:$limit:$offset';
    return _cachedRequest(
      key,
      () =>
          _provider.fetchPostsByHashtag(tag: tag, limit: limit, offset: offset),
    );
  }

  Future<List<Map<String, dynamic>>> fetchTrendingHashtags({
    int limit = 20,
  }) async {
    return _cachedRequest(
      'trending:$limit',
      () => _provider.fetchTrendingHashtags(limit: limit),
    );
  }

  Future<List<Map<String, dynamic>>> _cachedRequest(
    String key,
    Future<List<Map<String, dynamic>>> Function() loader,
  ) {
    final cached = _cache[key];
    if (cached != null && DateTime.now().isBefore(cached.expiresAt)) {
      return Future.value(cached.value);
    }

    final existing = _inFlight[key];
    if (existing != null) {
      return existing;
    }

    final request = loader()
        .then((value) {
          _cache[key] = _HashtagCacheEntry(
            value: value,
            expiresAt: DateTime.now().add(_cacheTtl),
          );
          return value;
        })
        .catchError((Object error, StackTrace stackTrace) {
          debugPrint('HashtagService request error: $error');
          debugPrint('HashtagService request stack: $stackTrace');
          return <Map<String, dynamic>>[];
        });

    _inFlight[key] = request;
    return request.whenComplete(() => _inFlight.remove(key));
  }
}

class _HashtagCacheEntry {
  const _HashtagCacheEntry({required this.value, required this.expiresAt});

  final List<Map<String, dynamic>> value;
  final DateTime expiresAt;
}
