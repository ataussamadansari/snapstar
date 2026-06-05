import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../core/utils/auth_helper.dart';
import '../../../data/controllers/story_controller.dart';
import '../../../data/controllers/story_like_controller.dart';
import '../../../data/models/story_model.dart';

class StoryViewerController extends GetxController {
  final StoryController storyController = Get.find();
  final StoryLikeController storyLikeController = Get.find();

  final RxList<StoryModel> userStories = <StoryModel>[].obs;

  final RxInt currentIndex = 0.obs;
  final RxDouble progress = 0.0.obs;
  final RxBool isPaused = false.obs;
  final RxBool isDeleting = false.obs;
  final RxBool isBuffering = true.obs;

  Timer? _timer;
  late String userId;

  StoryModel? get currentStory {
    if (userStories.isEmpty) {
      return null;
    }

    if (currentIndex.value < 0 || currentIndex.value >= userStories.length) {
      return null;
    }

    return userStories[currentIndex.value];
  }

  bool get isCurrentVideo {
    final story = currentStory;
    if (story == null) {
      return false;
    }

    if (story.mediaTypes.isNotEmpty) {
      return story.mediaTypes.first == StoryMediaType.video;
    }

    final mediaUrl = story.mediaUrls.isNotEmpty
        ? story.mediaUrls.first.toLowerCase()
        : '';

    return mediaUrl.endsWith('.mp4') ||
        mediaUrl.endsWith('.mov') ||
        mediaUrl.endsWith('.mkv') ||
        mediaUrl.endsWith('.webm');
  }

  bool get canDeleteCurrentStory {
    final story = currentStory;
    if (story == null) {
      return false;
    }
    return story.userId == AuthHelper.currentUserId;
  }

  bool get isMyStory => currentStory?.userId == AuthHelper.currentUserId;

  // ─── Like helpers ──────────────────────────────────────────────────────────

  bool get isCurrentLiked {
    final id = currentStory?.id;
    if (id == null) return false;
    return storyLikeController.isLiked(id);
  }

  int get currentLikeCount {
    final id = currentStory?.id;
    if (id == null) return 0;
    return storyLikeController.likeCount(id);
  }

  int get currentViewCount {
    final id = currentStory?.id;
    if (id == null) return 0;
    return storyLikeController.viewCount(id);
  }

  Future<void> toggleLike() async {
    final id = currentStory?.id;
    if (id == null) return;
    await storyLikeController.toggleLike(id);
  }

  @override
  void onInit() {
    super.onInit();
    // Don't await here, let it run async
    _initialize();
  }

  Future<void> _initialize() async {
    final StoryModel tappedStory = Get.arguments;

    userId = tappedStory.userId;

    userStories.assignAll(
      storyController.stories.where((s) => s.userId == userId).toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt)),
    );

    currentIndex.value = userStories.indexWhere((s) => s.id == tappedStory.id);

    if (currentIndex.value < 0) {
      currentIndex.value = 0;
    }

    // Har story ke liye like/view state initialize karo
    for (final story in userStories) {
      storyLikeController.initializeStory(
        story.id,
        dbLikeCount: story.likeCount,
        dbViewCount: story.viewCount,
      );
    }

    // Mark as viewed first
    markCurrentViewed();

    // Wait for next frame to ensure UI is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startCurrentStory();
    });
  }

  void loadUserStories() {
    userStories.assignAll(
      storyController.stories.where((s) => s.userId == userId).toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt)),
    );

    _startCurrentStory();
    markCurrentViewed();
  }

  void _startCurrentStory() {
    progress.value = 0;
    isPaused.value = false;
    isBuffering.value = true;
    _timer?.cancel();
  }

  void startProgress({bool reset = true}) {
    if (reset) {
      progress.value = 0;
    }
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (isPaused.value) {
        return;
      }

      progress.value += 0.01;

      if (progress.value >= 1.0) {
        progress.value = 1.0;
        nextStory();
      }
    });
  }

  void nextStory() {
    _timer?.cancel();

    if (currentIndex.value < userStories.length - 1) {
      currentIndex.value++;
      _startCurrentStory();
      markCurrentViewed();
    } else {
      // Last story finished, close viewer
      Get.back();
    }
  }

  void previousStory() {
    if (currentIndex.value > 0) {
      currentIndex.value--;
      _startCurrentStory();
      markCurrentViewed();
    }
  }

  void pause() {
    isPaused.value = true;
    _timer?.cancel();
  }

  void resume() {
    if (!isPaused.value) {
      return;
    }

    isPaused.value = false;

    if (!isCurrentVideo && !isBuffering.value) {
      startProgress(reset: false);
    }
  }

  void updateVideoProgress(double value) {
    if (!isCurrentVideo) {
      return;
    }

    // Cancel timer for videos - video player controls progress
    _timer?.cancel();

    final normalized = value.clamp(0.0, 1.0);
    progress.value = normalized;
  }

  void onMediaBufferingChanged(bool buffering) {
    isBuffering.value = buffering;

    if (buffering) {
      _timer?.cancel();
      return;
    }

    if (!isCurrentVideo && !isPaused.value && progress.value < 1.0) {
      startProgress(reset: false);
    }
  }

  void onImageReady() {
    if (isCurrentVideo) {
      return;
    }

    isBuffering.value = false;
    if (!isPaused.value && progress.value < 1.0) {
      startProgress(reset: false);
    }
  }

  void onMediaLoadError() {
    isBuffering.value = false;
    if (!isCurrentVideo && !isPaused.value && progress.value < 1.0) {
      startProgress(reset: false);
    }
  }

  void onVideoCompleted() {
    if (isCurrentVideo && !isPaused.value) {
      nextStory();
    }
  }

  Future<void> markCurrentViewed() async {
    final story = currentStory;
    if (story == null) {
      return;
    }

    if (story.isViewed) {
      return;
    }

    await storyController.markViewed(
      storyId: story.id,
      viewerId: AuthHelper.currentUserId,
    );
  }

  Future<void> deleteCurrentStory() async {
    final story = currentStory;
    if (story == null || !canDeleteCurrentStory || isDeleting.value) {
      return;
    }

    try {
      isDeleting.value = true;
      _timer?.cancel();

      await storyController.deleteStory(story.id);
      userStories.removeWhere((s) => s.id == story.id);

      if (userStories.isEmpty) {
        Get.back();
        return;
      }

      if (currentIndex.value >= userStories.length) {
        currentIndex.value = userStories.length - 1;
      }

      _startCurrentStory();
      await markCurrentViewed();
    } finally {
      isDeleting.value = false;
    }
  }

  @override
  void onClose() {
    _timer?.cancel();
    // Refresh stories to update "already seen" state in home screen
    storyController.stories.refresh();
    super.onClose();
  }
}
