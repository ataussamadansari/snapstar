import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/models/post_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/post_repository.dart';
import '../../../data/repositories/save_repository.dart';
import '../../../data/repositories/subscriber_repository.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../data/services/local_cache_service.dart';
import '../../../routes/app_routes.dart';

class ProfileController extends GetxController with GetSingleTickerProviderStateMixin {
  ProfileController(
    this._userRepo,
    this._postRepo,
    this._authRepo,
    this._subscriberRepo,
    this._cacheService,
    this._saveRepo,
  );

  final UserRepository _userRepo;
  final PostRepository _postRepo;
  final AuthRepository _authRepo;
  final SubscriberRepository _subscriberRepo;
  final LocalCacheService _cacheService;
  final SaveRepository _saveRepo;

  static const Duration _profileCacheTtl = Duration(minutes: 30);
  static const Duration _postsCacheTtl = Duration(minutes: 5);

  late TabController tabController;

  final RxList<PostModel> allPosts = <PostModel>[].obs;
  final RxList<PostModel> imagePosts = <PostModel>[].obs;
  final RxList<PostModel> videoPosts = <PostModel>[].obs;
  final RxList<PostModel> savedPosts = <PostModel>[].obs;

  final RxBool isPostLoading = false.obs;
  final RxBool isSavedLoading = false.obs;
  final RxInt postsCount = 0.obs;

  final Rxn<UserModel> userProfile = Rxn<UserModel>();
  final RxBool isLoading = true.obs;
  final RxInt subscriberCount = 0.obs;
  final RxInt subscribingCount = 0.obs;

  VoidCallback? _unsubscribeUserPostChanges;
  VoidCallback? _unsubscribeUserSubscribeChanges;
  RealtimeChannel? _userProfileChannel;

  @override
  void onInit() {
    super.onInit();

    tabController = TabController(length: 4, vsync: this);

    // Pehle cache se instantly dikhao, phir background mein fresh data lo
    _hydrateFromCache().then((_) {
      fetchMyProfile();
      fetchAllMyPosts();
      fetchSavedPosts();
      _refreshFollowCounts();
    });

    _subscribeToUserPostChanges();
    _subscribeToSubscriberChanges();
    _subscribeToUserProfileChanges();
  }

  // ─── Cache: Hydrate ────────────────────────────────────────────────────────

  Future<void> _hydrateFromCache() async {
    final userId = _authRepo.currentUserId;
    if (userId == null) return;

    // Profile cache
    final profilePayload = await _cacheService.getJson('profile_user_$userId');
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
    final postsPayload = await _cacheService.getJson('profile_posts_$userId');
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
      'profile_user_${profile.id}',
      profile.toJson(),
      ttl: _profileCacheTtl,
    );
  }

  Future<void> _persistPostsCache(String userId) async {
    if (allPosts.isEmpty) return;
    final payload = <String, dynamic>{
      'items': allPosts.map((post) => _postToJson(post)).toList(),
    };
    await _cacheService.putJson(
      'profile_posts_$userId',
      payload,
      ttl: _postsCacheTtl,
    );
  }

  // ─── Fetch ─────────────────────────────────────────────────────────────────

  Future<void> fetchAllMyPosts() async {
    try {
      isPostLoading.value = true;

      final userId = _authRepo.currentUserId;
      if (userId == null) return;

      final posts = await _postRepo.fetchUserPosts(userId);
      _applyPostBuckets(posts);
      _refreshPostCount();
      await _persistPostsCache(userId);
    } catch (error, stackTrace) {
      debugPrint('ProfileController.fetchAllMyPosts error: $error');
      debugPrint('ProfileController.fetchAllMyPosts stack: $stackTrace');
    } finally {
      isPostLoading.value = false;
    }
  }

  Future<void> fetchSavedPosts() async {
    try {
      isSavedLoading.value = true;
      final posts = await _saveRepo.fetchSavedPosts(limit: 60);
      savedPosts.assignAll(posts);
    } catch (error, stackTrace) {
      debugPrint('ProfileController.fetchSavedPosts error: $error');
      debugPrint('ProfileController.fetchSavedPosts stack: $stackTrace');
    } finally {
      isSavedLoading.value = false;
    }
  }

  Future<void> fetchMyProfile() async {
    try {
      isLoading.value = true;
      final userId = _authRepo.currentUserId;
      if (userId != null) {
        final profile = await _userRepo.fetchProfile(userId);
        userProfile.value = profile;
        if (profile != null) {
          subscriberCount.value = profile.subscriberCount;
          subscribingCount.value = profile.subscribingCount;
          await _persistProfileCache(profile);
        }
      }
    } catch (error, stackTrace) {
      debugPrint('ProfileController.fetchMyProfile error: $error');
      debugPrint('ProfileController.fetchMyProfile stack: $stackTrace');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _refreshFollowCounts() async {
    final userId = _authRepo.currentUserId;
    if (userId == null) {
      return;
    }

    try {
      final counts = await Future.wait<int>([
        _subscriberRepo.fetchSubscriberCount(userId),
        _subscriberRepo.fetchSubscribingCount(userId),
      ]);

      subscriberCount.value = counts[0];
      subscribingCount.value = counts[1];
    } catch (error, stackTrace) {
      debugPrint('ProfileController._refreshFollowCounts error: $error');
      debugPrint('ProfileController._refreshFollowCounts stack: $stackTrace');
    }
  }

  Future<void> refreshFollowCounts() {
    return _refreshFollowCounts();
  }

  Future<void> _refreshPostCount() async {
    final userId = _authRepo.currentUserId;
    if (userId == null) {
      return;
    }

    try {
      final dbCount = await _postRepo.fetchUserPostsCount(userId);
      postsCount.value = math.max(dbCount, allPosts.length);
    } catch (error, stackTrace) {
      debugPrint('ProfileController._refreshPostCount error: $error');
      debugPrint('ProfileController._refreshPostCount stack: $stackTrace');
      postsCount.value = allPosts.length;
    }
  }

  Future<void> refreshProfileData() async {
    await Future.wait<void>([
      fetchMyProfile(),
      fetchAllMyPosts(),
      fetchSavedPosts(),
      _refreshFollowCounts(),
    ]);
  }

  Future<void> logout() async {
    try {
      await _authRepo.signOut();
      Get.offAllNamed(Routes.login);
    } catch (error, stackTrace) {
      debugPrint('ProfileController.logout error: $error');
      debugPrint('ProfileController.logout stack: $stackTrace');
    }
  }

  void _subscribeToUserPostChanges() {
    if (_unsubscribeUserPostChanges != null) {
      return;
    }

    final userId = _authRepo.currentUserId;
    if (userId == null) {
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
        _persistPostsCache(userId); // cache bhi update karo
      },
    );
  }

  void _subscribeToSubscriberChanges() {
    if (_unsubscribeUserSubscribeChanges != null) {
      return;
    }

    final userId = _authRepo.currentUserId;
    if (userId == null) {
      return;
    }

    _unsubscribeUserSubscribeChanges = _subscriberRepo.subscribeToUserRelationChanges(
      userId: userId,
      onChanged: _refreshFollowCounts,
    );
  }

  void _applyPostBuckets(List<PostModel> posts) {
    allPosts.assignAll(posts);
    imagePosts.assignAll(posts.where((post) => post.mediaType == MediaType.image));
    videoPosts.assignAll(posts.where((post) => post.mediaType == MediaType.video));
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

    final userId = _authRepo.currentUserId;
    if (userId == null || userId.isEmpty) {
      return;
    }

    final client = Supabase.instance.client;
    _userProfileChannel = client.channel('profile-users-$userId');

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
          fetchMyProfile();
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
