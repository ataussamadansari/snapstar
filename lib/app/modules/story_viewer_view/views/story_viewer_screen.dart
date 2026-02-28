import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';

import 'package:snapstar_app/app/core/utils/date_time_extension.dart';

import '../../../data/models/story_model.dart';
import '../controllers/story_viewer_controller.dart';

class StoryViewerScreen extends GetView<StoryViewerController> {
  const StoryViewerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Obx(() {
          if (controller.userStories.isEmpty) {
            return const SizedBox();
          }

          final story = controller.userStories[controller.currentIndex.value];

          return GestureDetector(
            onTapUp: (details) {
              final width = MediaQuery.of(context).size.width;

              if (details.globalPosition.dx < width / 2) {
                controller.previousStory();
              } else {
                controller.nextStory();
              }
            },
            onLongPress: controller.pause,
            onLongPressUp: controller.resume,
            child: Stack(
              children: [
                Center(
                  child: _StoryMedia(
                    key: ValueKey(story.id),
                    story: story,
                    isPaused: controller.isPaused.value,
                    onVideoProgress: controller.updateVideoProgress,
                    onVideoCompleted: controller.onVideoCompleted,
                  ),
                ),
                Positioned(
                  top: 10,
                  left: 10,
                  right: 10,
                  child: Row(
                    children: List.generate(controller.userStories.length, (
                      index,
                    ) {
                      return Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          height: 3,
                          child: LinearProgressIndicator(
                            value: index == controller.currentIndex.value
                                ? controller.progress.value
                                : index < controller.currentIndex.value
                                ? 1
                                : 0,
                            backgroundColor: Colors.white30,
                            valueColor: const AlwaysStoppedAnimation(
                              Colors.white,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                Positioned(
                  top: 20,
                  left: 16,
                  right: 16,
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.grey.shade800,
                        backgroundImage:
                            (story.user?.avatarUrl != null &&
                                story.user!.avatarUrl!.isNotEmpty)
                            ? NetworkImage(story.user!.avatarUrl!)
                            : null,
                        child:
                            (story.user?.avatarUrl == null ||
                                story.user!.avatarUrl!.isEmpty)
                            ? const Icon(Icons.person, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            story.user?.username ?? '',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            story.createdAt.timeAgo,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Get.back(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _StoryMedia extends StatefulWidget {
  const _StoryMedia({
    super.key,
    required this.story,
    required this.isPaused,
    required this.onVideoProgress,
    required this.onVideoCompleted,
  });

  final StoryModel story;
  final bool isPaused;
  final ValueChanged<double> onVideoProgress;
  final VoidCallback onVideoCompleted;

  @override
  State<_StoryMedia> createState() => _StoryMediaState();
}

class _StoryMediaState extends State<_StoryMedia> {
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _videoHasError = false;
  bool _completionSent = false;

  bool get _isVideo {
    if (widget.story.mediaTypes.isNotEmpty) {
      return widget.story.mediaTypes.first == StoryMediaType.video;
    }

    final url = widget.story.mediaUrls.isNotEmpty
        ? widget.story.mediaUrls.first.toLowerCase()
        : '';

    return url.endsWith('.mp4') ||
        url.endsWith('.mov') ||
        url.endsWith('.mkv') ||
        url.endsWith('.webm');
  }

  @override
  void initState() {
    super.initState();
    _initVideoIfNeeded();
  }

  @override
  void didUpdateWidget(covariant _StoryMedia oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.story.id != widget.story.id) {
      _disposeVideo();
      _initVideoIfNeeded();
      return;
    }

    if (_videoController != null && _isVideoInitialized) {
      if (widget.isPaused) {
        _videoController!.pause();
      } else if (!_videoController!.value.isPlaying) {
        _videoController!.play();
      }
    }
  }

  Future<void> _initVideoIfNeeded() async {
    if (!_isVideo || widget.story.mediaUrls.isEmpty) {
      return;
    }

    try {
      _videoHasError = false;
      _isVideoInitialized = false;
      _completionSent = false;

      _videoController = VideoPlayerController.networkUrl(
        Uri.parse(widget.story.mediaUrls.first),
      );

      await _videoController!.initialize();
      await _videoController!.setLooping(false);

      _videoController!.addListener(_onVideoTick);

      if (widget.isPaused) {
        await _videoController!.pause();
      } else {
        await _videoController!.play();
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _isVideoInitialized = true;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _videoHasError = true;
      });
    }
  }

  void _onVideoTick() {
    final controller = _videoController;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    final durationMs = controller.value.duration.inMilliseconds;
    final positionMs = controller.value.position.inMilliseconds;

    if (durationMs > 0) {
      widget.onVideoProgress(positionMs / durationMs);
    }

    if (_completionSent || durationMs <= 0) {
      return;
    }

    if (positionMs >= durationMs - 200) {
      _completionSent = true;
      widget.onVideoCompleted();
    }
  }

  void _disposeVideo() {
    _videoController?.removeListener(_onVideoTick);
    _videoController?.dispose();
    _videoController = null;
  }

  @override
  void dispose() {
    _disposeVideo();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.story.mediaUrls.isEmpty) {
      return const Center(
        child: Icon(Icons.broken_image, color: Colors.white70, size: 40),
      );
    }

    if (!_isVideo) {
      return Image.network(
        widget.story.mediaUrls.first,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) {
          return const Center(
            child: Icon(Icons.broken_image, color: Colors.white70, size: 40),
          );
        },
      );
    }

    if (_videoHasError) {
      return const Center(
        child: Icon(Icons.error_outline, color: Colors.white70, size: 40),
      );
    }

    if (!_isVideoInitialized || _videoController == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    final size = _videoController!.value.size;

    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: size.width,
          height: size.height,
          child: VideoPlayer(_videoController!),
        ),
      ),
    );
  }
}
