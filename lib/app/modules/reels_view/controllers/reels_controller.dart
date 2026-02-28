import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../core/utils/video_cache_manager.dart';
import '../../../data/models/post_model.dart';
import '../../../data/repositories/post_repository.dart';

class ReelsController extends GetxController {
  ReelsController(this._postRepo);

  final PostRepository _postRepo;

  final RxList<PostModel> reels = <PostModel>[].obs;
  final PageController pageController = PageController();
  final RxInt currentPage = 0.obs;

  final RxBool isLoading = false.obs;
  final RxBool isLoadingMore = false.obs;
  final RxBool hasMore = true.obs;

  final int _pageSize = 10;
  int _offset = 0;
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
    refreshReels();
  }

  Future<void> refreshReels() async {
    if (_isScopedMode) {
      await _refreshScopedReels();
      return;
    }

    _offset = 0;
    hasMore.value = true;
    currentPage.value = 0;
    reels.clear();
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
      _offset = 0;
      hasMore.value = true;
      reels.clear();
    }

    if (!hasMore.value || isLoading.value || isLoadingMore.value) {
      return;
    }

    final isFirstPage = _offset == 0;

    if (isFirstPage) {
      isLoading.value = true;
    } else {
      isLoadingMore.value = true;
    }

    try {
      final fetched = await _postRepo.fetchReels(
        limit: _pageSize,
        offset: _offset,
      );
      final randomized = List<PostModel>.from(fetched)..shuffle();

      if (isFirstPage) {
        reels.assignAll(randomized);
      } else {
        final existingIds = reels.map((post) => post.id).toSet();
        final unique = randomized.where((post) => !existingIds.contains(post.id));
        reels.addAll(unique);
      }

      if (randomized.length < _pageSize) {
        hasMore.value = false;
      } else {
        _offset += randomized.length;
      }

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
    _offset = 0;
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
      _offset = 0;

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
