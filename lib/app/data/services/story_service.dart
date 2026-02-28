import 'dart:io';
import 'package:get/get.dart';
import '../models/story_model.dart';
import '../repositories/story_repository.dart';

class StoryService extends GetxService {

   StoryRepository _repository;
   StoryService(this._repository);

  // =========================
  // 🔹 ADD STORY (Single)
  // =========================
  Future<void> addStory({
    required String userId,
    required File file,
    required StoryMediaType mediaType,
  }) async {

    final mediaUrl = await _repository.uploadMedia(
      file: file,
      userId: userId,
    );

    final story = StoryModel(
      id: '',
      userId: userId,
      mediaUrls: [mediaUrl],
      mediaTypes: [mediaType],
      expiresAt: DateTime.now().add(const Duration(hours: 24)),
      createdAt: DateTime.now(),
    );

    await _repository.createStory(story);
  }

  // =========================
  // 🔹 ADD MULTIPLE STORIES (Batch Upload)
  // =========================
  Future<void> addMultipleStories({
    required String userId,
    required List<File> files,
    required List<StoryMediaType> mediaTypes,
  }) async {

    if (files.isEmpty) return;

    for (int i = 0; i < files.length; i++) {
      await addStory(
        userId: userId,
        file: files[i],
        mediaType: mediaTypes[i],
      );
    }
  }

  // =========================
  // 🔹 GET ACTIVE STORIES
  // =========================
  Future<List<StoryModel>> getActiveStories() async {

    final stories = await _repository.fetchActiveStories();

    return stories
        .where((story) => !story.isExpired)
        .toList();
  }

  // =========================
  // 🔹 GET STORIES BY USER
  // =========================
  Future<List<StoryModel>> getUserStories(String userId) async {

    final stories = await _repository.fetchUserStories(userId);

    return stories
        .where((story) => !story.isExpired)
        .toList();
  }

  // =========================
  // 🔹 DELETE STORY
  // =========================
  Future<void> deleteStory(String storyId) async {
    await _repository.deleteStory(storyId);
  }

  // =========================
  // 🔹 MARK STORY AS VIEWED
  // =========================
  Future<bool> markStoryViewed({
    required String storyId,
    required String viewerId,
  }) async {

    final alreadyViewed = await _repository.isStoryViewed(
      storyId,
      viewerId,
    );

    if (!alreadyViewed) {
      await _repository.insertStoryView(
        storyId: storyId,
        viewerId: viewerId,
      );
    }

    return alreadyViewed;
  }

  // =========================
  // 🔹 GET VIEW COUNT
  // =========================
  Future<int> getStoryViewCount(String storyId) async {
    return await _repository.getStoryViewCount(storyId);
  }

  // =========================
  // 🔹 CLEANUP EXPIRED (Optional Cron)
  // =========================
  Future<void> cleanupExpiredStories() async {
    await _repository.deleteExpiredStories();
  }

   Future<bool> isStoryViewed({
     required String storyId,
     required String viewerId,
   }) async {
     return await _repository.isStoryViewed(
       storyId,
       viewerId,
     );
   }

}