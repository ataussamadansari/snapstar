import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import 'package:snapstar_app/app/data/controllers/story_controller.dart';
import 'package:snapstar_app/app/data/repositories/auth_repository.dart';
import 'package:snapstar_app/app/data/services/local_cache_service.dart';

import '../../../data/models/post_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/post_repository.dart';
import '../../../data/repositories/subscriber_repository.dart';
import '../../../data/repositories/user_repository.dart';

class HomeController extends GetxController {
  HomeController(
    this.userRepo,
    this.postRepo,
    this.subscriberRepo,
    this.storyController,
    this.authRepository,
    this.cacheService,
  );

  final UserRepository userRepo;
  final PostRepository postRepo;
  final SubscriberRepository subscriberRepo;
  final StoryController storyController;
  final AuthRepository authRepository;
  final LocalCacheService cacheService;

  final RxList<UserModel> users = <UserModel>[].obs;
  final RxList<PostModel> posts = <PostModel>[].obs;
  final RxnString myAvatarUrl = RxnString();

  final RxBool isLoadingUsers = false.obs;
  final RxBool isLoadingPosts = false.obs;
  final RxBool isLoadingMorePosts = false.obs;
  final RxBool hasMorePosts = true.obs;

  final int _feedPageSize = 10;
  DateTime? _feedCursorCreatedAt;
  String? _feedCursorId;
  double? _feedCursorScore;

  VoidCallback? _unsubscribePostChanges;
  VoidCallback? _unsubscribeRelationChanges;

  @override
  void onInit() {
    super.onInit();
    _subscribeToPostChanges();
    _subscribeToRelationChanges();
    _hydrateFromCache();
    refreshAll();
  }

  Future<void> refreshAll() async {
    _feedCursorCreatedAt = null;
    _feedCursorId = null;
    _feedCursorScore = null;
    hasMorePosts.value = true;

    await _loadMyProfile();
    await loadPosts(refresh: true);
    await loadUsers(refresh: true);
    await storyController.fetchStories();
  }

  Future<void> _loadMyProfile() async {
    final userId = authRepository.currentUserId;
    if (userId == null || userId.isEmpty) {
      myAvatarUrl.value = null;
      return;
    }

    try {
      final profile = await userRepo.fetchProfile(userId);
      final avatar = profile?.avatarUrl?.trim();
      myAvatarUrl.value = (avatar != null && avatar.isNotEmpty) ? avatar : null;
    } catch (error, stackTrace) {
      debugPrint('HomeController._loadMyProfile error: $error');
      debugPrint('HomeController._loadMyProfile stack: $stackTrace');
    }
  }

  Future<void> loadUsers({bool refresh = false}) async {
    if (isLoadingUsers.value) return;

    if (refresh) {
      users.clear();
    }

    isLoadingUsers.value = true;

    try {
      final newUsers = await subscriberRepo.getSuggestedUsers(
        limit: 15,
        offset: 0,
      );

      users.assignAll(newUsers);
    } catch (error, stackTrace) {
      debugPrint('HomeController.loadUsers error: $error');
      debugPrint('HomeController.loadUsers stack: $stackTrace');
    } finally {
      isLoadingUsers.value = false;
    }
  }

  Future<void> loadPosts({bool refresh = false}) async {
    if (refresh) {
      _feedCursorCreatedAt = null;
      _feedCursorId = null;
      _feedCursorScore = null;
      hasMorePosts.value = true;
    }

    if (!hasMorePosts.value ||
        isLoadingPosts.value ||
        isLoadingMorePosts.value) {
      return;
    }

    final bool isFirstPage =
        _feedCursorCreatedAt == null || _feedCursorId == null;

    if (isFirstPage) {
      isLoadingPosts.value = true;
    } else {
      isLoadingMorePosts.value = true;
    }

    try {
      final page = await postRepo.fetchFeedPostsByCursor(
        limit: _feedPageSize,
        cursorCreatedAt: _feedCursorCreatedAt,
        cursorId: _feedCursorId,
        cursorScore: _feedCursorScore,
      );
      final fetched = page.items;
      final prepared = fetched;

      if (isFirstPage) {
        posts.assignAll(prepared);
      } else {
        final existingIds = posts.map((post) => post.id).toSet();
        final unique = prepared.where((post) => !existingIds.contains(post.id));
        posts.addAll(unique);
      }

      hasMorePosts.value = page.hasMore;
      _feedCursorCreatedAt = page.nextCursorCreatedAt;
      _feedCursorId = page.nextCursorId;
      _feedCursorScore = page.nextCursorScore;
      _persistFeedCache();
    } catch (error, stackTrace) {
      debugPrint('HomeController.loadPosts error: $error');
      debugPrint('HomeController.loadPosts stack: $stackTrace');
    } finally {
      if (isFirstPage) {
        isLoadingPosts.value = false;
      } else {
        isLoadingMorePosts.value = false;
      }
    }
  }

  Future<void> _hydrateFromCache() async {
    final userId = authRepository.currentUserId;
    if (userId == null) {
      return;
    }

    final payload = await cacheService.getJson('home_feed_$userId');
    final itemsRaw = payload?['items'];
    if (itemsRaw is! List || itemsRaw.isEmpty) {
      return;
    }

    try {
      final restored = itemsRaw
          .whereType<Map>()
          .map((row) => PostModel.fromJson(Map<String, dynamic>.from(row)))
          .toList();
      if (restored.isNotEmpty && posts.isEmpty) {
        posts.assignAll(restored);
      }
    } catch (error, stackTrace) {
      debugPrint('HomeController._hydrateFromCache error: $error');
      debugPrint('HomeController._hydrateFromCache stack: $stackTrace');
    }
  }

  Future<void> _persistFeedCache() async {
    final userId = authRepository.currentUserId;
    if (userId == null || posts.isEmpty) {
      return;
    }

    final payload = <String, dynamic>{
      'items': posts
          .take(40)
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
              if (post.user != null)
                'users': {
                  'id': post.user!.id,
                  'name': post.user!.name,
                  'username': post.user!.username,
                  'email': post.user!.email,
                  'phone': post.user!.phone,
                  'avatar_url': post.user!.avatarUrl,
                  'bio': post.user!.bio,
                  'role': post.user!.role,
                  'posts_count': post.user!.postsCount,
                  'subscriber_count': post.user!.subscriberCount,
                  'subscribing_count': post.user!.subscribingCount,
                  'created_at': post.user!.createdAt.toUtc().toIso8601String(),
                  'updated_at': post.user!.updatedAt.toUtc().toIso8601String(),
                },
            },
          )
          .toList(),
    };

    await cacheService.putJson(
      'home_feed_$userId',
      payload,
      ttl: const Duration(minutes: 3),
    );
  }

  Future<void> loadMorePosts() {
    return loadPosts(refresh: false);
  }

  void _subscribeToPostChanges() {
    _unsubscribePostChanges ??= postRepo.subscribeToFeedChanges(
      onEvent: (change) {
        final current = List<PostModel>.from(posts);
        final index = current.indexWhere((post) => post.id == change.postId);

        switch (change.type) {
          case PostModelChangeType.insert:
            if (change.post == null) {
              return;
            }
            final updated = List<PostModel>.from(current)
              ..removeWhere((post) => post.id == change.postId)
              ..insert(0, change.post!);
            if (updated.length > 80) {
              updated.removeRange(80, updated.length);
            }
            posts.assignAll(updated);
            _persistFeedCache();
            return;
          case PostModelChangeType.update:
            if (index >= 0 && change.post != null) {
              current[index] = change.post!;
              posts.assignAll(current);
            }
            return;
          case PostModelChangeType.delete:
            if (index >= 0) {
              current.removeAt(index);
              posts.assignAll(current);
            }
            return;
        }
      },
    );
  }

  void _subscribeToRelationChanges() {
    if (_unsubscribeRelationChanges != null) {
      return;
    }

    final myId = subscriberRepo.currentUserId;
    if (myId == null) {
      return;
    }

    _unsubscribeRelationChanges = subscriberRepo.subscribeToUserRelationChanges(
      userId: myId,
      onChanged: () => loadUsers(refresh: true),
    );
  }

  @override
  void onClose() {
    _unsubscribePostChanges?.call();
    _unsubscribePostChanges = null;

    _unsubscribeRelationChanges?.call();
    _unsubscribeRelationChanges = null;

    super.onClose();
  }
}
