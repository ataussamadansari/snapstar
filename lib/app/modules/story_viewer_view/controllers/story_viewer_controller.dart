import 'dart:async';

import 'package:get/get.dart';

import '../../../core/utils/auth_helper.dart';
import '../../../data/controllers/story_controller.dart';
import '../../../data/models/story_model.dart';

class StoryViewerController extends GetxController {
  final StoryController storyController = Get.find();

  final RxList<StoryModel> userStories = <StoryModel>[].obs;

  final RxInt currentIndex = 0.obs;
  final RxDouble progress = 0.0.obs;
  final RxBool isPaused = false.obs;

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

  @override
  void onInit() {
    super.onInit();
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

    await markCurrentViewed();
    _startCurrentStory();
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
    _timer?.cancel();

    if (!isCurrentVideo) {
      startProgress();
    }
  }

  void startProgress() {
    progress.value = 0;
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (isPaused.value) {
        return;
      }

      progress.value += 0.01;

      if (progress.value >= 1) {
        nextStory();
      }
    });
  }

  void nextStory() {
    if (currentIndex.value < userStories.length - 1) {
      currentIndex.value++;
      _startCurrentStory();
      markCurrentViewed();
    } else {
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

    if (!isCurrentVideo) {
      startProgress();
    }
  }

  void updateVideoProgress(double value) {
    if (!isCurrentVideo || isPaused.value) {
      return;
    }

    final normalized = value.clamp(0.0, 1.0);
    progress.value = normalized;
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

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }
}

