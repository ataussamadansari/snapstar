import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/models/post_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/post_repository.dart';
import '../../../data/repositories/subscriber_repository.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../data/services/local_cache_service.dart';

class UserProfileController extends GetxController
    with GetSingleTickerProviderStateMixin {
  UserProfileController(
    this._userRepo,
    this._postRepo,
    this._authRepo,
    this._subscriberRepo,
    this.userId,
    this._cacheService, {
    this.usernameToResolve,
  });

  final UserRepository _userRepo;
  final PostRepository _postRepo;
  final AuthRepository _authRepo;
  final SubscriberRepository _subscriberRepo;
  final LocalCacheService _cacheService;

  String userId;
  final String? usernameToResolve;

  static const Duration _profileCacheTtl = Duration(minutes: 30);
  static const Duration _postsCacheTtl = Duration(minutes: 5);

  late TabController tabController;

  final RxList<PostModel> allPosts = <PostModel>[].obs;
  final RxList<PostModel> imagePosts = <PostModel>[].obs;
  final RxList<PostModel> videoPosts = <PostModel>[].obs;

  final RxBool isPostLoading = false.obs;
  final RxInt postsCount = 0.obs;
  final Rxn<UserModel> userProfile = Rxn<UserModel>();
  final RxBool isLoading = true.obs;
  final RxInt subscriberCount = 0.obs;
  final RxInt subscribingCount = 0.obs;

  VoidCallback? _unsubscribeUserPostChanges;
  VoidCallback? _unsubscribeUserSubscribeChanges;
  RealtimeChannel? _userProfileChannel;

  bool get isMyProfile => _authRepo.currentUserId == userId;

  @override
  void onInit() {
    super.onInit();
    tabController = TabController(length: 3, vsync: this);

    // Agar username pass hua hai to pehle resolve karo
    if (usernameToResolve != null && usernameToResolve!.isNotEmpty && userId.isEmpty) {
      _resolveUsername(usernameToResolve!);
    } else {
      // Pehle cache se instantly dikhao, phir background mein fresh data lo
      _hydrateFromCache().then((_) {
        fetchProfile();
        fetchPosts();
        _refreshFollowCounts();
      });

      _subscribeToUserPostChanges();
      _subscribeToSubscriberChanges();
      _subscribeToUserProfileChanges();
    }
  }

  Future<void> _resolveUsername(String username) async {
    isLoading.value = true;
    try {
      final profile = await _userRepo.fetchProfileByUsername(username);
      if (profile == null) {
        isLoading.value = false;
        return;
      }
      userId = profile.id;
      userProfile.value = profile;
      subscriberCount.value = profile.subscriberCount;
      subscribingCount.value = profile.subscribingCount;
      isLoading.value = false;

      // Baaki data load karo
      fetchPosts();
      _refreshFollowCounts();
      _subscribeToUserPostChanges();
      _subscribeToSubscriberChanges();
      _subscribeToUserProfileChanges();
    } catch (e, st) {
      debugPrint('UserProfileController._resolveUsername error: $e\n$st');
      isLoading.value = false;
    }
  }

  // ─── Cache: Hydrate ────────────────────────────────────────────────────────

  Future<void> _hydrateFromCache() async {
    // Profile cache
    final profilePayload = await _cacheService.getJson('uprofile_user_$userId');
    if (profilePayload != null) {
      try {
        final profile = UserModel.fromJson(profilePayload);
        userProfile.value = profile;
        subscriberCount.value = profile.subscriberCount;
        subscribingCount.value = profile.subscribingCount;
        isLoading.value = false;
      } catch (_) {}
    }

    // Posts cache
    final postsPayload = await _cacheService.getJson('uprofile_posts_$userId');
    final itemsRaw = postsPayload?['items'];
    if (itemsRaw is List && itemsRaw.isNotEmpty) {
      try {
        final restored = itemsRaw
            .whereType<Map>()
            .map((row) => PostModel.fromJson(Map<String, dynamic>.from(row)))
            .toList();
        if (restored.isNotEmpty && allPosts.isEmpty) {
          _applyPostBuckets(restored);
          isPostLoading.value = false;
        }
      } catch (_) {}
    }
  }

  // ─── Cache: Persist ────────────────────────────────────────────────────────

  Future<void> _persistProfileCache(UserModel profile) async {
    await _cacheService.putJson(
      'uprofile_user_$userId',
      profile.toJson(),
      ttl: _profileCacheTtl,
    );
  }

  Future<void> _persistPostsCache() async {
    if (allPosts.isEmpty) return;
    final payload = <String, dynamic>{
      'items': allPosts.map((post) => _postToJson(post)).toList(),
    };
    await _cacheService.putJson(
      'uprofile_posts_$userId',
      payload,
      ttl: _postsCacheTtl,
    );
  }

  // ─── Fetch ─────────────────────────────────────────────────────────────────

  Future<void> fetchProfile() async {
    try {
      isLoading.value = true;
      final profile = await _userRepo.fetchProfile(userId);
      userProfile.value = profile;
      if (profile != null) {
        subscriberCount.value = profile.subscriberCount;
        subscribingCount.value = profile.subscribingCount;
        await _persistProfileCache(profile);
      }
    } catch (error, stackTrace) {
      debugPrint('UserProfileController.fetchProfile error: $error');
      debugPrint('UserProfileController.fetchProfile stack: $stackTrace');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _refreshFollowCounts() async {
    try {
      final counts = await Future.wait<int>([
        _subscriberRepo.fetchSubscriberCount(userId),
        _subscriberRepo.fetchSubscribingCount(userId),
      ]);

      subscriberCount.value = counts[0];
      subscribingCount.value = counts[1];
    } catch (error, stackTrace) {
      debugPrint('UserProfileController._refreshFollowCounts error: $error');
      debugPrint('UserProfileController._refreshFollowCounts stack: $stackTrace');
    }
  }

  Future<void> refreshFollowCounts() {
    return _refreshFollowCounts();
  }

  Future<void> _refreshPostCount() async {
    try {
      postsCount.value = await _postRepo.fetchUserPostsCount(userId);
    } catch (error, stackTrace) {
      debugPrint('UserProfileController._refreshPostCount error: $error');
      debugPrint('UserProfileController._refreshPostCount stack: $stackTrace');
      postsCount.value = allPosts.length;
    }
  }

  Future<void> fetchPosts() async {
    try {
      isPostLoading.value = true;
      final posts = await _postRepo.fetchUserPosts(userId);
      _applyPostBuckets(posts);
      _refreshPostCount();
      await _persistPostsCache();
    } catch (error, stackTrace) {
      debugPrint('UserProfileController.fetchPosts error: $error');
      debugPrint('UserProfileController.fetchPosts stack: $stackTrace');
    } finally {
      isPostLoading.value = false;
    }
  }

  void _subscribeToUserPostChanges() {
    if (_unsubscribeUserPostChanges != null) {
      return;
    }

    _unsubscribeUserPostChanges = _postRepo.subscribeToUserPostChanges(
      userId: userId,
      onEvent: (change) {
        final next = _postRepo.mergeFeedPosts(
          current: allPosts.toList(),
          change: change,
        );
        _applyPostBuckets(next);
        _refreshPostCount();
        _persistPostsCache(); // cache bhi update karo
      },
    );
  }

  void _subscribeToSubscriberChanges() {
    if (_unsubscribeUserSubscribeChanges != null) {
      return;
    }

    _unsubscribeUserSubscribeChanges = _subscriberRepo.subscribeToUserRelationChanges(
      userId: userId,
      onChanged: _refreshFollowCounts,
    );
  }

  void _applyPostBuckets(List<PostModel> posts) {
    allPosts.assignAll(posts);
    imagePosts.assignAll(
      posts.where((post) => post.mediaType == MediaType.image),
    );
    videoPosts.assignAll(
      posts.where((post) => post.mediaType == MediaType.video),
    );
    if (postsCount.value == 0 && posts.isNotEmpty) {
      postsCount.value = posts.length;
    }
  }

  // ─── Cache Helper ──────────────────────────────────────────────────────────

  Map<String, dynamic> _postToJson(PostModel post) => {
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
      };

  void _subscribeToUserProfileChanges() {
    if (_userProfileChannel != null) {
      return;
    }

    if (userId.isEmpty) {
      return;
    }

    final client = Supabase.instance.client;
    _userProfileChannel = client.channel('user-profile-users-$userId');

    _userProfileChannel!
      ..onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'users',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'id',
          value: userId,
        ),
        callback: (_) {
          fetchProfile();
          _refreshPostCount();
          _refreshFollowCounts();
        },
      )
      ..subscribe();
  }

  @override
  void onClose() {
    _unsubscribeUserPostChanges?.call();
    _unsubscribeUserPostChanges = null;

    _unsubscribeUserSubscribeChanges?.call();
    _unsubscribeUserSubscribeChanges = null;

    if (_userProfileChannel != null) {
      Supabase.instance.client.removeChannel(_userProfileChannel!);
      _userProfileChannel = null;
    }

    tabController.dispose();
    super.onClose();
  }
}
