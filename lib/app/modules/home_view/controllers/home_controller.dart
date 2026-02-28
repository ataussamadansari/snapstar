import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import 'package:snapstar_app/app/data/controllers/story_controller.dart';

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
  );

  final UserRepository userRepo;
  final PostRepository postRepo;
  final SubscriberRepository subscriberRepo;
  final StoryController storyController;

  final RxList<UserModel> users = <UserModel>[].obs;
  final RxList<PostModel> posts = <PostModel>[].obs;

  final RxBool isLoadingUsers = false.obs;
  final RxBool isLoadingPosts = false.obs;
  final RxBool isLoadingMorePosts = false.obs;
  final RxBool hasMorePosts = true.obs;

  final int _feedPageSize = 10;
  int _feedOffset = 0;

  VoidCallback? _unsubscribePostChanges;
  VoidCallback? _unsubscribeRelationChanges;

  @override
  void onInit() {
    super.onInit();
    _subscribeToPostChanges();
    _subscribeToRelationChanges();
    refreshAll();
  }

  Future<void> refreshAll() async {
    _feedOffset = 0;
    hasMorePosts.value = true;
    posts.clear();

    await loadPosts(refresh: true);
    await loadUsers(refresh: true);
    await storyController.fetchStories();
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
      _feedOffset = 0;
      hasMorePosts.value = true;
      posts.clear();
    }

    if (!hasMorePosts.value || isLoadingPosts.value || isLoadingMorePosts.value) {
      return;
    }

    final bool isFirstPage = _feedOffset == 0;

    if (isFirstPage) {
      isLoadingPosts.value = true;
    } else {
      isLoadingMorePosts.value = true;
    }

    try {
      final feed = await postRepo.fetchFeedPosts(
        limit: _feedPageSize,
        offset: _feedOffset,
      );
      final randomized = List<PostModel>.from(feed)..shuffle();

      if (isFirstPage) {
        posts.assignAll(randomized);
      } else {
        final existingIds = posts.map((post) => post.id).toSet();
        final unique = randomized.where((post) => !existingIds.contains(post.id));
        posts.addAll(unique);
      }

      if (randomized.length < _feedPageSize) {
        hasMorePosts.value = false;
      } else {
        _feedOffset += randomized.length;
      }
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

  Future<void> loadMorePosts() {
    return loadPosts(refresh: false);
  }

  void _subscribeToPostChanges() {
    _unsubscribePostChanges ??= postRepo.subscribeToFeedChanges(
      onEvent: (change) {
        final next = postRepo.mergeFeedPosts(
          current: posts.toList(),
          change: change,
        );
        posts.assignAll(next);
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
