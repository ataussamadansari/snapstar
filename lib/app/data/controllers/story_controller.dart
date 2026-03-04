import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:snapstar_app/app/core/utils/auth_helper.dart';
import 'package:snapstar_app/app/core/utils/helpers.dart';
import 'package:snapstar_app/app/data/controllers/upload_task_controller.dart';
import '../models/story_model.dart';
import '../services/story_service.dart';

class StoryController extends GetxController {
  StoryController(this._service);

  final StoryService _service;

  RxList<StoryModel> stories = <StoryModel>[].obs;

  RxBool isLoading = false.obs;
  RxBool isUploading = false.obs;
  final UploadTaskController _uploadTaskController = Get.find();

  // Already viewed in current session
  final Set<String> _locallyViewed = {};

  // ===============================
  // 🔹 INIT
  // ===============================
  @override
  void onInit() {
    fetchStories();
    super.onInit();
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
    // 1. Apne alawa baaki sabki stories nikalein
    final otherStories = stories.where((s) => s.userId != currentUserId).toList();

    // 2. Stories ko userId ke basis par group karein
    final Map<String, List<StoryModel>> grouped = {};
    for (var story in otherStories) {
      grouped.putIfAbsent(story.userId, () => []);
      grouped[story.userId]!.add(story);
    }

    final result = <StoryModel>[];

    grouped.forEach((userId, userStories) {
      userStories.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      final latestStory = userStories.first;

      // User-level seen state: ek baar user ki koi story dekh lo to ring remove.
      final hasSeenAny = userStories.any((s) => s.isViewed);

      result.add(
        StoryModel(
          id: latestStory.id,
          userId: latestStory.userId,
          mediaUrls: List<String>.from(latestStory.mediaUrls),
          mediaTypes: List<StoryMediaType>.from(latestStory.mediaTypes),
          expiresAt: latestStory.expiresAt,
          createdAt: latestStory.createdAt,
          user: latestStory.user,
          isViewed: hasSeenAny,
        ),
      );
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

      stories.assignAll(data);

      final viewerId = AuthHelper.currentUserId;
      if (viewerId.isNotEmpty && stories.isNotEmpty) {
        await Future.wait(
          stories.map((story) async {
            if (story.userId == viewerId) {
              story.isViewed = true;
              return;
            }

            try {
              story.isViewed = await _service.isStoryViewed(
                storyId: story.id,
                viewerId: viewerId,
              );
            } catch (_) {
              story.isViewed = false;
            }
          }),
        );
      }

      stories.sort(
            (a, b) => b.createdAt.compareTo(a.createdAt),
      );

      stories.refresh();

    } catch (e) {
      debugPrint('Fetch Story Error: $e');
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
      debugPrint('Fetch Story Error: $e');
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
    if (isUploading.value) {
      return;
    }
    isUploading.value = true;

    AppHelpers.showSnackBar(
      title: 'Uploading',
      message: 'Story upload started in background',
      isError: false,
    );

    Future<void>.microtask(() async {
      final taskId = _uploadTaskController.start(
        type: UploadTaskType.story,
        label: 'Uploading story...',
      );
      try {
        _uploadTaskController.updateTask(taskId, progress: 0.2, label: 'Preparing story...');
        await _service.addStory(
          userId: userId,
          file: file,
          mediaType: mediaType,
        );
        _uploadTaskController.updateTask(taskId, progress: 0.9, label: 'Publishing story...');
        await fetchStories();
        _uploadTaskController.complete(taskId);
      } catch (e) {
        _uploadTaskController.fail(taskId, 'Story upload failed');
        AppHelpers.showSnackBar(
          title: 'Error',
          message: 'Story upload failed',
          isError: true,
        );
      } finally {
        isUploading.value = false;
      }
    });
  }

  // ===============================
  // 🔹 ADD MULTIPLE STORIES
  // ===============================
  Future<void> uploadMultipleStories({
    required String userId,
    required List<File> files,
    required List<StoryMediaType> mediaTypes,
  }) async {

    if (isUploading.value) {
      return;
    }

    isUploading.value = true;

    Future<void>.microtask(() async {
      final taskId = _uploadTaskController.start(
        type: UploadTaskType.story,
        label: 'Uploading stories...',
      );
      try {
        final total = files.isEmpty ? 1 : files.length;
        for (var i = 0; i < files.length; i++) {
          _uploadTaskController.updateTask(
            taskId,
            label: 'Uploading story ${i + 1}/$total',
            progress: (i / total) * 0.9,
          );
          await _service.addStory(
            userId: userId,
            file: files[i],
            mediaType: mediaTypes[i],
          );
        }
        _uploadTaskController.updateTask(taskId, label: 'Publishing stories...', progress: 0.95);
        await fetchStories();
        _uploadTaskController.complete(taskId);
      } catch (e) {
        _uploadTaskController.fail(taskId, 'Story upload failed');
        AppHelpers.showSnackBar(
          title: 'Error',
          message: 'Story upload failed',
          isError: true,
        );
      } finally {
        isUploading.value = false;
      }
    });
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

    // 🔥 1. Already locally viewed? Skip everything
    if (_locallyViewed.contains(storyId)) {
      return;
    }

    final story = stories.firstWhereOrNull((s) => s.id == storyId);
    if (story == null) return;

    // 🔥 2. Apni story ho to skip
    if (story.userId == viewerId) {
      return;
    }

    // 🔥 3. Agar DB me pehle se viewed hai
    if (story.isViewed) {
      _locallyViewed.add(storyId);
      return;
    }

    // 🔥 4. First time view → insert
    await _service.markStoryViewed(
      storyId: storyId,
      viewerId: viewerId,
    );

    story.isViewed = true;

    _locallyViewed.add(storyId);

    stories.refresh();
  }

  Future<void> markViewedV0({
    required String storyId,
    required String viewerId,
  }) async {
    await _service.markStoryViewed(
      storyId: storyId,
      viewerId: viewerId,
    );
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


