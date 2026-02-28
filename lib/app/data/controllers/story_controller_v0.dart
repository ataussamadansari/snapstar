import 'dart:io';
import 'package:get/get.dart';
import '../../core/utils/auth_helper.dart';
import '../models/story_model.dart';
import '../services/story_service.dart';

class StoryController extends GetxController {

  final StoryService _service = Get.find<StoryService>();

  RxList<StoryModel> stories = <StoryModel>[].obs;

  RxBool isLoading = false.obs;
  RxBool isUploading = false.obs;

  // ===============================
  // 🔹 INIT
  // ===============================
  @override
  void onInit() {
    fetchStories();
    super.onInit();
  }

  bool? getIsViewed() {

  }

  StoryModel? getMyLatestStory(String currentUserId) {
    final myStories = stories
        .where((s) => s.userId == currentUserId)
        .toList();

    if (myStories.isEmpty) return null;

    myStories.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return myStories.first;
  }

  List<StoryModel> getOtherUsersStories(String currentUserId) {

    final otherStories =
    stories.where((s) => s.userId != currentUserId).toList();

    final Map<String, List<StoryModel>> grouped = {};

    for (var story in otherStories) {
      grouped.putIfAbsent(story.userId, () => []);
      grouped[story.userId]!.add(story);
    }

    final result = <StoryModel>[];

    grouped.forEach((userId, userStories) {

      // latest story
      userStories.sort(
            (a, b) => b.createdAt.compareTo(a.createdAt),
      );

      final latestStory = userStories.first;

      // 🔥 check if ANY story unseen
      final hasUnseen =
      userStories.any((s) => !s.isViewed);

      latestStory.isViewed = !hasUnseen;

      result.add(latestStory);
    });

    return result;
  }

  List<StoryModel> getOtherUsersStoriesV1(String currentUserId) {

    final otherStories = stories
        .where((s) => s.userId != currentUserId)
        .toList();

    final Map<String, StoryModel> uniqueUsers = {};

    for (var story in otherStories) {
      // Only first story per user (latest because sorted)
      if (!uniqueUsers.containsKey(story.userId)) {
        uniqueUsers[story.userId] = story;
      }
    }

    return uniqueUsers.values.toList();
  }

  // ===============================
  // 🔹 FETCH ALL ACTIVE STORIES
  // ===============================
  Future<void> fetchStories() async {
    try {
      isLoading.value = true;

      final data = await _service.getActiveStories();
      final currentUserId = AuthHelper.currentUserId;

      for (var story in data) {
        final viewed = await _service.isStoryViewed(
          storyId: story.id,
          viewerId: currentUserId,
        );

        story.isViewed = viewed;
      }

      stories.assignAll(data);

      stories.sort(
            (a, b) => b.createdAt.compareTo(a.createdAt),
      );

    } catch (e) {
      print("Fetch Story Error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchStoriesV1() async {
    try {
      isLoading.value = true;

      final data = await _service.getActiveStories();

      stories.assignAll(data);

      // latest first
      stories.sort((a, b) =>
          b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      print("Fetch Story Error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  // ===============================
  // 🔹 ADD SINGLE STORY
  // ===============================
  Future<void> uploadStory({
    required String userId,
    required File file,
    required StoryMediaType mediaType,
  }) async {

    try {
      isUploading.value = true;

      await _service.addStory(
        userId: userId,
        file: file,
        mediaType: mediaType,
      );

      await fetchStories();

    } catch (e) {
      print("Upload Story Error: $e");
    } finally {
      isUploading.value = false;
    }
  }

  // ===============================
  // 🔹 ADD MULTIPLE STORIES
  // ===============================
  Future<void> uploadMultipleStories({
    required String userId,
    required List<File> files,
    required List<StoryMediaType> mediaTypes,
  }) async {

    try {
      isUploading.value = true;

      await _service.addMultipleStories(
        userId: userId,
        files: files,
        mediaTypes: mediaTypes,
      );

      await fetchStories();

    } catch (e) {
      print("Batch Upload Error: $e");
    } finally {
      isUploading.value = false;
    }
  }

  // ===============================
  // 🔹 DELETE STORY
  // ===============================
  Future<void> deleteStory(String storyId) async {
    await _service.deleteStory(storyId);
    stories.removeWhere((story) => story.id == storyId);
  }

  // ===============================
  // 🔹 MARK AS VIEWED
  // ===============================
  Future<void> markViewed({
    required String storyId,
    required String viewerId,
  }) async {
    await _service.markStoryViewed(
      storyId: storyId,
      viewerId: viewerId,
    );
  }

  Future<void> isViewed({
    required String storyId,
    required String viewerId,
  }) async {
    bool res = await _service.markStoryViewed(
      storyId: storyId,
      viewerId: viewerId,
    );
    print("result isViewed: $res");
  }

  // ===============================
  // 🔹 GET VIEW COUNT
  // ===============================
  Future<int> getViewCount(String storyId) async {
    return await _service.getStoryViewCount(storyId);
  }

  // ===============================
  // 🔹 REFRESH
  // ===============================
  Future<void> refreshStories() async {
    await fetchStories();
  }
}

/*
import 'dart:io';

import 'package:get/get.dart';
import 'package:snapstar_app/app/core/utils/auth_helper.dart';
import '../models/story_model.dart';
import '../models/story_user_model.dart';
import '../models/story_view_model.dart';
import '../repositories/story_repository.dart';
import '../models/user_model.dart';

class StoryController extends GetxController {

  final StoryRepository repo = Get.find();

  RxList<StoryModel> stories = <StoryModel>[].obs;
  RxList<StoryUserModel> groupedStories = <StoryUserModel>[].obs;

  RxBool isLoading = false.obs;


  Future<void> postStory({
    required File file,
    required bool isVideo,
    required List<UserModel> users,
  }) async {

    if (AuthHelper.currentUserId.isEmpty) return;

    isLoading.value = true;

    await repo.uploadStory(
      file: file,
      userId: AuthHelper.currentUserId,
      isVideo: isVideo,
    );

    // Refresh stories after upload
    await loadStories(users, AuthHelper.currentUserId);

    isLoading.value = false;
  }


  Future<void> loadStories(List<UserModel> users, String currentUserId) async {
    isLoading.value = true;

    final fetchedStories = await repo.getActiveStories();
    stories.assignAll(fetchedStories);

    final storyIds = fetchedStories.map((e) => e.id).toList();
    final views = await repo.getViews(storyIds);

    _groupStories(users, views, currentUserId);

    isLoading.value = false;
  }

  void _groupStories(
      List<UserModel> users,
      List<StoryViewModel> views,
      String currentUserId,
      ) {

    final Map<String, List<StoryModel>> map = {};

    for (var story in stories) {
      map.putIfAbsent(story.userId, () => []);
      map[story.userId]!.add(story);
    }

    final result = map.entries.map((entry) {

      final user = users.firstWhere(
            (u) => u.id == entry.key,
        orElse: () => users.first,
      );

      final userStories = entry.value;

      final hasUnseen = userStories.any((story) =>
      !views.any((view) =>
      view.storyId == story.id &&
          view.viewerId == currentUserId));

      return StoryUserModel(
        userId: entry.key,
        userName: user.name,
        avatarUrl: user.avatarUrl,
        stories: userStories,
        hasUnseen: hasUnseen,
      );
    }).toList();

    groupedStories.assignAll(result);
  }
}
*/
