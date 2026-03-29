import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../core/utils/video_cache_manager.dart';
import '../../../data/models/post_model.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/post_repository.dart';
import '../../../data/services/local_cache_service.dart';

class ReelsController extends GetxController {
  ReelsController(
    this._postRepo,
    this._authRepo,
    this._cacheService,
  );

  final PostRepository _postRepo;
  final AuthRepository _authRepo;
  final LocalCacheService _cacheService;

  final RxList<PostModel> reels = <PostModel>[].obs;
  final PageController pageController = PageController();
  final RxInt currentPage = 0.obs;

  final RxBool isLoading = false.obs;
  final RxBool isLoadingMore = false.obs;
  final RxBool hasMore = true.obs;

  final int _pageSize = 10;
  DateTime? _cursorCreatedAt;
  String? _cursorId;
  double? _cursorScore;
  int _reelsSessionSalt = DateTime.now().millisecondsSinceEpoch;
  final Set<String> _prefetchedUrls = <String>{};
  bool _isScopedMode = false;
  String? _scopedUserId;

  VoidCallback? _unsubscribePostChanges;

  bool get isScopedMode => _isScopedMode;
  String? get scopedUserId => _scopedUserId;

  @override
  void onInit() {
    super.onInit();
    _subscribeToPostChanges();
    _hydrateFromCache();
    refreshReels();
  }

  Future<void> refreshReels() async {
    if (_isScopedMode) {
      await _refreshScopedReels();
      return;
    }

    _cursorCreatedAt = null;
    _cursorId = null;
    _cursorScore = null;
    _reelsSessionSalt = DateTime.now().microsecondsSinceEpoch;
    hasMore.value = true;
    currentPage.value = 0;
    await loadReels(refresh: true);
  }

  Future<void> loadMoreReels() async {
    return loadReels(refresh: false);
  }

  Future<void> loadReels({bool refresh = false}) async {
    if (_isScopedMode) {
      return;
    }

    if (refresh) {
      _cursorCreatedAt = null;
      _cursorId = null;
      _cursorScore = null;
      hasMore.value = true;
    }

    if (!hasMore.value || isLoading.value || isLoadingMore.value) {
      return;
    }

    final isFirstPage = _cursorCreatedAt == null || _cursorId == null;

    if (isFirstPage) {
      isLoading.value = true;
    } else {
      isLoadingMore.value = true;
    }

    try {
      final page = await _postRepo.fetchReelsByCursor(
        limit: _pageSize,
        cursorCreatedAt: _cursorCreatedAt,
        cursorId: _cursorId,
        cursorScore: _cursorScore,
      );
      final fetched = page.items;
      final prepared = isFirstPage ? _diversifyReels(fetched) : fetched;

      if (isFirstPage) {
        reels.assignAll(prepared);
      } else {
        final existingIds = reels.map((post) => post.id).toSet();
        final unique = prepared.where((post) => !existingIds.contains(post.id));
        reels.addAll(unique);
      }

      hasMore.value = page.hasMore;
      _cursorCreatedAt = page.nextCursorCreatedAt;
      _cursorId = page.nextCursorId;
      _cursorScore = page.nextCursorScore;
      _persistCache();

      _prefetchAround(currentPage.value);
    } catch (error, stackTrace) {
      debugPrint('ReelsController.loadReels error: $error');
      debugPrint('ReelsController.loadReels stack: $stackTrace');
    } finally {
      if (isFirstPage) {
        isLoading.value = false;
      } else {
        isLoadingMore.value = false;
      }
    }
  }

  List<PostModel> _diversifyReels(List<PostModel> source) {
    if (source.length < 3) {
      return source;
    }

    final sorted = List<PostModel>.from(source)
      ..sort((a, b) => _reelMixScore(b).compareTo(_reelMixScore(a)));

    final queueByUser = <String, List<PostModel>>{};
    for (final post in sorted) {
      queueByUser.putIfAbsent(post.userId, () => <PostModel>[]).add(post);
    }

    final result = <PostModel>[];
    String? lastUserId;
    while (result.length < sorted.length) {
      MapEntry<String, List<PostModel>>? pickedEntry;
      double pickedScore = -1;

      for (final entry in queueByUser.entries) {
        if (entry.value.isEmpty || entry.key == lastUserId) {
          continue;
        }
        final score = _reelMixScore(entry.value.first);
        if (score > pickedScore) {
          pickedScore = score;
          pickedEntry = entry;
        }
      }

      if (pickedEntry == null) {
        for (final entry in queueByUser.entries) {
          if (entry.value.isNotEmpty) {
            pickedEntry = entry;
            break;
          }
        }
      }

      if (pickedEntry == null) {
        break;
      }

      final picked = pickedEntry.value.removeAt(0);
      result.add(picked);
      lastUserId = picked.userId;
    }

    return result.isEmpty ? source : result;
  }

  double _reelMixScore(PostModel post) {
    final ageHours = DateTime.now().difference(post.createdAt).inMinutes / 60.0;
    final recency = 1 / (1 + (ageHours / 14.0).clamp(0, 200));
    final engagement =
        (post.likeCount * 1.2) + (post.commentCount * 1.8) + (post.shareCount * 2.2);
    final randomBoost = _stableRandom01('${post.id}_${post.userId}', _reelsSessionSalt);
    return (engagement * 0.05) + (recency * 1.0) + (randomBoost * 0.95);
  }

  double _stableRandom01(String key, int salt) {
    final hash = Object.hash(key, salt) & 0x7fffffff;
    return hash / 0x7fffffff;
  }

  void _subscribeToPostChanges() {
    if (_unsubscribePostChanges != null) {
      return;
    }

    _unsubscribePostChanges = _postRepo.subscribeToFeedChanges(
      onEvent: (change) {
        final next = List<PostModel>.from(reels);

        switch (change.type) {
          case PostModelChangeType.insert:
          case PostModelChangeType.update:
            final updated = change.post;
            if (updated == null) {
              break;
            }

            if (_isScopedMode &&
                _scopedUserId != null &&
                updated.userId != _scopedUserId) {
              break;
            }

            final index = next.indexWhere((post) => post.id == updated.id);
            if (updated.mediaType != MediaType.video) {
              if (index >= 0) {
                next.removeAt(index);
              }
              break;
            }

            if (index >= 0) {
              next[index] = updated;
            } else {
              if (!_isScopedMode || _scopedUserId != null) {
                next.insert(0, updated);
              }
            }
            break;
          case PostModelChangeType.delete:
            next.removeWhere((post) => post.id == change.postId);
            break;
        }

        reels.assignAll(next);
      },
    );
  }

  void onPageChanged(int index) {
    currentPage.value = index;

    if (!_isScopedMode && index >= reels.length - 3) {
      loadMoreReels();
    }

    _prefetchAround(index);
  }

  Future<void> showGlobalAtPost(PostModel post) async {
    if (post.mediaType != MediaType.video) {
      return;
    }

    _isScopedMode = false;
    _scopedUserId = null;

    if (reels.isEmpty) {
      await refreshReels();
    }

    int index = reels.indexWhere((item) => item.id == post.id);
    if (index < 0) {
      reels.removeWhere((item) => item.id == post.id);
      reels.insert(0, post);
      index = 0;
    }

    currentPage.value = index;
    _jumpToPage(index);
    _prefetchAround(index);
  }

  void showScopedFromPosts({
    required List<PostModel> posts,
    required String initialPostId,
    String? scopedUserId,
  }) {
    final scopedReels = posts
        .where(
          (post) =>
              post.mediaType == MediaType.video &&
              !post.isDeleted &&
              post.mediaUrls.isNotEmpty,
        )
        .toList();

    _isScopedMode = true;
    _scopedUserId = scopedUserId;
    hasMore.value = false;
    reels.assignAll(scopedReels);

    if (scopedReels.isEmpty) {
      currentPage.value = 0;
      return;
    }

    final initialIndex = scopedReels.indexWhere((item) => item.id == initialPostId);
    final targetIndex = initialIndex >= 0 ? initialIndex : 0;
    currentPage.value = targetIndex;
    _jumpToPage(targetIndex);
    _prefetchAround(targetIndex);
  }

  Future<void> switchToGlobalFeedIfNeeded() async {
    if (!_isScopedMode) {
      return;
    }

    _isScopedMode = false;
    _scopedUserId = null;
    await refreshReels();
  }

  void _prefetchAround(int index) {
    if (reels.isEmpty) {
      return;
    }

    final start = index - 1 < 0 ? 0 : index - 1;
    final end = index + 2 >= reels.length ? reels.length - 1 : index + 2;

    for (int i = start; i <= end; i++) {
      final post = reels[i];
      if (post.mediaUrls.isEmpty) {
        continue;
      }

      final url = post.mediaUrls.first;
      if (_prefetchedUrls.contains(url)) {
        continue;
      }

      _prefetchedUrls.add(url);
      _prefetchUrl(url);
    }
  }

  Future<void> _prefetchUrl(String url) async {
    try {
      await VideoCacheManager.instance.downloadFile(url);
    } catch (_) {
      _prefetchedUrls.remove(url);
    }
  }

  Future<void> _refreshScopedReels() async {
    if (_scopedUserId == null || _scopedUserId!.isEmpty) {
      return;
    }

    final currentId = currentPage.value < reels.length
        ? reels[currentPage.value].id
        : null;

    isLoading.value = true;
    try {
      final fetched = await _postRepo.fetchUserPosts(
        _scopedUserId!,
        type: MediaType.video,
        limit: 100,
        offset: 0,
      );

      final scopedReels = fetched
          .where((post) => !post.isDeleted && post.mediaUrls.isNotEmpty)
          .toList();

      reels.assignAll(scopedReels);
      hasMore.value = false;
      _cursorCreatedAt = null;
      _cursorId = null;

      if (scopedReels.isEmpty) {
        currentPage.value = 0;
        return;
      }

      final nextIndex = currentId == null
          ? 0
          : scopedReels.indexWhere((post) => post.id == currentId);
      final targetIndex = nextIndex >= 0 ? nextIndex : 0;

      currentPage.value = targetIndex;
      _jumpToPage(targetIndex);
      _prefetchAround(targetIndex);
    } catch (error, stackTrace) {
      debugPrint('ReelsController._refreshScopedReels error: $error');
      debugPrint('ReelsController._refreshScopedReels stack: $stackTrace');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _hydrateFromCache() async {
    final userId = _authRepo.currentUserId;
    if (userId == null) {
      return;
    }

    final payload = await _cacheService.getJson('reels_feed_$userId');
    final itemsRaw = payload?['items'];
    if (itemsRaw is! List || itemsRaw.isEmpty) {
      return;
    }

    try {
      final restored = itemsRaw
          .whereType<Map>()
          .map((row) => PostModel.fromJson(Map<String, dynamic>.from(row)))
          .toList();
      if (restored.isNotEmpty && reels.isEmpty) {
        reels.assignAll(restored);
      }
    } catch (_) {}
  }

  Future<void> _persistCache() async {
    final userId = _authRepo.currentUserId;
    if (userId == null || reels.isEmpty) {
      return;
    }

    final payload = <String, dynamic>{
      'items': reels
          .take(30)
          .map(
            (post) => {
              'id': post.id,
              'user_id': post.userId,
              'media_type': post.mediaType.name,
              'caption': post.caption,
              'media_urls': post.mediaUrls,
              'thumbnail_urls': post.thumbnailUrls,
              'like_count': post.likeCount,
              'comment_count': post.commentCount,
              'share_count': post.shareCount,
              'is_deleted': post.isDeleted,
              'location': post.location,
              'created_at': post.createdAt.toUtc().toIso8601String(),
              'updated_at': post.updatedAt.toUtc().toIso8601String(),
            },
          )
          .toList(),
    };

    await _cacheService.putJson(
      'reels_feed_$userId',
      payload,
      ttl: const Duration(minutes: 3),
    );
  }

  void _jumpToPage(int index) {
    if (index < 0) {
      return;
    }

    void jump() {
      if (!pageController.hasClients || index >= reels.length) {
        return;
      }
      if (pageController.page?.round() == index) {
        return;
      }
      pageController.jumpToPage(index);
    }

    if (pageController.hasClients) {
      jump();
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => jump());
  }

  @override
  void onClose() {
    _unsubscribePostChanges?.call();
    _unsubscribePostChanges = null;
    pageController.dispose();
    super.onClose();
  }
}
