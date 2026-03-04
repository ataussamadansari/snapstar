import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/models/post_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/post_repository.dart';
import '../../../data/repositories/subscriber_repository.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../routes/app_routes.dart';

class ProfileController extends GetxController with GetSingleTickerProviderStateMixin {
  ProfileController(
    this._userRepo,
    this._postRepo,
    this._authRepo,
    this._subscriberRepo,
  );

  final UserRepository _userRepo;
  final PostRepository _postRepo;
  final AuthRepository _authRepo;
  final SubscriberRepository _subscriberRepo;

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

  @override
  void onInit() {
    super.onInit();

    tabController = TabController(length: 3, vsync: this);

    fetchMyProfile();
    fetchAllMyPosts();
    _refreshPostCount();
    _refreshFollowCounts();
    _subscribeToUserPostChanges();
    _subscribeToSubscriberChanges();
    _subscribeToUserProfileChanges();
  }

  Future<void> fetchAllMyPosts() async {
    try {
      isPostLoading.value = true;

      final userId = _authRepo.currentUserId;
      if (userId == null) return;

      final posts = await _postRepo.fetchUserPosts(userId);
      _applyPostBuckets(posts);
      _refreshPostCount();
    } catch (error, stackTrace) {
      debugPrint('ProfileController.fetchAllMyPosts error: $error');
      debugPrint('ProfileController.fetchAllMyPosts stack: $stackTrace');
    } finally {
      isPostLoading.value = false;
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
      _refreshPostCount(),
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
