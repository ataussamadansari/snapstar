import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/post_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/post_repository.dart';
import '../../../data/repositories/subscriber_repository.dart';
import '../../../data/repositories/user_repository.dart';

class SearchsController extends GetxController {
  SearchsController(
    this._userRepo,
    this._postRepo,
    this._authRepo,
    this._subscriberRepo,
  );

  final UserRepository _userRepo;
  final PostRepository _postRepo;
  final AuthRepository _authRepo;
  final SubscriberRepository _subscriberRepo;

  final TextEditingController queryCtrl = TextEditingController();

  final RxString query = ''.obs;
  final RxList<UserModel> userResults = <UserModel>[].obs;
  final RxList<PostModel> postResults = <PostModel>[].obs;
  final RxList<Map<String, dynamic>> hashtagResults = <Map<String, dynamic>>[].obs;
  final RxList<UserModel> suggestedUsers = <UserModel>[].obs;
  final RxList<PostModel> suggestedPosts = <PostModel>[].obs;
  final RxList<Map<String, dynamic>> suggestedHashtags = <Map<String, dynamic>>[].obs;

  final RxBool isLoadingSuggestions = false.obs;
  final RxBool isSearching = false.obs;
  final RxnString errorMessage = RxnString();

  Worker? _debounceWorker;
  VoidCallback? _unsubscribeRelationChanges;
  int _searchRunId = 0;

  bool get hasQuery => query.value.trim().isNotEmpty;

  @override
  void onInit() {
    super.onInit();

    _debounceWorker = debounce<String>(
      query,
      (_) => _runSearch(),
      time: const Duration(milliseconds: 350),
    );

    _subscribeToRelationChanges();
    loadSuggestions();
  }

  void onQueryChanged(String value) {
    query.value = value.trim();

    if (query.value.isEmpty) {
      errorMessage.value = null;
      userResults.clear();
      postResults.clear();
      hashtagResults.clear();
    }
  }

  Future<void> loadSuggestions() async {
    if (isLoadingSuggestions.value) {
      return;
    }

    try {
      isLoadingSuggestions.value = true;
      errorMessage.value = null;

      final results = await Future.wait([
        _subscriberRepo.getSuggestedUsers(
          limit: 25,
          offset: 0,
        ),
        _postRepo.fetchExplorePosts(
          limit: 60,
          offset: 0,
        ),
        _postRepo.searchHashtags(
          query: '',
          limit: 10,
        ),
      ]);

      final users = results[0] as List<UserModel>;
      final posts = List<PostModel>.from(results[1] as List<PostModel>)
          ..shuffle();
      final hashtags = List<Map<String, dynamic>>.from(
        results[2] as List<Map<String, dynamic>>,
      );

      suggestedUsers.assignAll(users);
      suggestedPosts.assignAll(posts);
      suggestedHashtags.assignAll(hashtags);
    } catch (error, stackTrace) {
      debugPrint('SearchsController.loadSuggestions error: $error');
      debugPrint('SearchsController.loadSuggestions stack: $stackTrace');
      errorMessage.value = 'Could not load suggestions';
    } finally {
      isLoadingSuggestions.value = false;
    }
  }

  Future<void> refreshCurrent() async {
    if (hasQuery) {
      await _runSearch();
      return;
    }

    await loadSuggestions();
  }

  Future<void> _runSearch() async {
    final searchQuery = query.value.trim();

    if (searchQuery.isEmpty) {
      userResults.clear();
      postResults.clear();
      hashtagResults.clear();
      isSearching.value = false;
      return;
    }

    final runId = ++_searchRunId;

    try {
      isSearching.value = true;
      errorMessage.value = null;

      final results = await Future.wait([
        _userRepo.searchUsers(
          query: searchQuery,
          limit: 20,
          offset: 0,
          excludeUserId: _authRepo.currentUserId,
        ),
        _postRepo.searchPosts(
          query: searchQuery,
          limit: 30,
          offset: 0,
        ),
        _postRepo.searchHashtags(
          query: searchQuery,
          limit: 12,
        ),
      ]);

      if (runId != _searchRunId) {
        return;
      }

      userResults.assignAll(results[0] as List<UserModel>);
      postResults.assignAll(results[1] as List<PostModel>);
      hashtagResults.assignAll(
        List<Map<String, dynamic>>.from(results[2] as List<Map<String, dynamic>>),
      );
    } catch (error, stackTrace) {
      if (runId != _searchRunId) {
        return;
      }

      debugPrint('SearchsController._runSearch error: $error');
      debugPrint('SearchsController._runSearch stack: $stackTrace');

      errorMessage.value = 'Search failed, please try again';
      userResults.clear();
      postResults.clear();
      hashtagResults.clear();
    } finally {
      if (runId == _searchRunId) {
        isSearching.value = false;
      }
    }
  }

  void _subscribeToRelationChanges() {
    final myId = _authRepo.currentUserId;
    if (myId == null) {
      return;
    }

    _unsubscribeRelationChanges = _subscriberRepo.subscribeToUserRelationChanges(
      userId: myId,
      onChanged: () {
        if (!hasQuery) {
          loadSuggestions();
        }
      },
    );
  }

  void clearQuery() {
    queryCtrl.clear();
    query.value = '';
    errorMessage.value = null;
    userResults.clear();
    postResults.clear();
    hashtagResults.clear();
  }

  @override
  void onClose() {
    _debounceWorker?.dispose();
    _unsubscribeRelationChanges?.call();
    _unsubscribeRelationChanges = null;
    queryCtrl.dispose();
    super.onClose();
  }
}

