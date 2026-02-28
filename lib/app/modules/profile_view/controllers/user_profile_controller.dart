import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/models/post_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/post_repository.dart';
import '../../../data/repositories/subscriber_repository.dart';
import '../../../data/repositories/user_repository.dart';

class UserProfileController extends GetxController
    with GetSingleTickerProviderStateMixin {
  UserProfileController(
    this._userRepo,
    this._postRepo,
    this._authRepo,
    this._subscriberRepo,
    this.userId,
  );

  final UserRepository _userRepo;
  final PostRepository _postRepo;
  final AuthRepository _authRepo;
  final SubscriberRepository _subscriberRepo;

  final String userId;

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

    fetchProfile();
    fetchPosts();
    _refreshPostCount();
    _refreshFollowCounts();
    _subscribeToUserPostChanges();
    _subscribeToSubscriberChanges();
    _subscribeToUserProfileChanges();
  }

  Future<void> fetchProfile() async {
    try {
      isLoading.value = true;
      final profile = await _userRepo.fetchProfile(userId);
      userProfile.value = profile;
      if (profile != null) {
        subscriberCount.value = profile.subscriberCount;
        subscribingCount.value = profile.subscribingCount;
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
