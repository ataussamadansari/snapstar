import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:snapstar_app/app/core/utils/date_time_extension.dart';
import 'package:snapstar_app/app/core/utils/video_cache_manager.dart';
import 'package:snapstar_app/app/global_widgets/app_avatar.dart';

import '../../../data/models/story_model.dart';
import '../controllers/story_viewer_controller.dart';

class StoryViewerScreen extends GetView<StoryViewerController> {
  const StoryViewerScreen({super.key});
  static const double _topControlsHitArea = 120;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Obx(() {
          if (controller.userStories.isEmpty) {
            return const SizedBox();
          }

          final story = controller.userStories[controller.currentIndex.value];

          return GestureDetector(
            onTapUp: (details) {
              if (details.localPosition.dy <= _topControlsHitArea) {
                return;
              }

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
              clipBehavior: Clip.none,
              children: [
                Center(
                  child: _StoryMedia(
                    key: ValueKey(story.id),
                    story: story,
                    isPaused: controller.isPaused.value,
                    onVideoProgress: controller.updateVideoProgress,
                    onVideoCompleted: controller.onVideoCompleted,
                    onImageReady: controller.onImageReady,
                    onBufferingChanged: controller.onMediaBufferingChanged,
                    onMediaLoadError: controller.onMediaLoadError,
                  ),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.only(
                      top: 20,
                      left: 16,
                      right: 16,
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: List.generate(
                            controller.userStories.length,
                            (index) {
                              final progress =
                                  index == controller.currentIndex.value
                                  ? controller.progress.value
                                  : index < controller.currentIndex.value
                                  ? 1.0
                                  : 0.0;
                              return Expanded(
                                child: Container(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 2,
                                  ),
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.28),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(999),
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: FractionallySizedBox(
                                        widthFactor: progress.clamp(0.0, 1.0),
                                        child: Container(color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            AppAvatar(
                              radius: 18,
                              avatarUrl: story.user?.avatarUrl,
                              backgroundColor: Colors.grey.shade800,
                              iconColor: Colors.white,
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
                            if (controller.canDeleteCurrentStory)
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.35),
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  icon: controller.isDeleting.value
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.delete_outline,
                                          color: Colors.white,
                                        ),
                                  onPressed: controller.isDeleting.value
                                      ? null
                                      : () async {
                                          final shouldDelete =
                                              await Get.dialog<bool>(
                                                AlertDialog(
                                                  title: const Text(
                                                    'Delete story?',
                                                  ),
                                                  content: const Text(
                                                    'This story will be removed for everyone.',
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () => Get.back(
                                                        result: false,
                                                      ),
                                                      child: const Text(
                                                        'Cancel',
                                                      ),
                                                    ),
                                                    TextButton(
                                                      onPressed: () => Get.back(
                                                        result: true,
                                                      ),
                                                      child: const Text(
                                                        'Delete',
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );

                                          if (shouldDelete == true) {
                                            await controller
                                                .deleteCurrentStory();
                                          }
                                        },
                                ),
                              ),
                            const SizedBox(width: 6),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.35),
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                ),
                                onPressed: () => Get.back(),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
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
    required this.onImageReady,
    required this.onBufferingChanged,
    required this.onMediaLoadError,
  });

  final StoryModel story;
  final bool isPaused;
  final ValueChanged<double> onVideoProgress;
  final VoidCallback onVideoCompleted;
  final VoidCallback onImageReady;
  final ValueChanged<bool> onBufferingChanged;
  final VoidCallback onMediaLoadError;

  @override
  State<_StoryMedia> createState() => _StoryMediaState();
}

class _StoryMediaState extends State<_StoryMedia> {
  static final Set<String> _queuedDownloads = <String>{};
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _videoHasError = false;
  bool _completionSent = false;
  bool _isImageLoaded = false;
  bool _imageHasError = false;
  bool _readyDispatched = false;
  bool _lastVideoBuffering = false;
  int _controllerVersion = 0;

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
    widget.onBufferingChanged(true);
    _initVideoIfNeeded();
  }

  @override
  void didUpdateWidget(covariant _StoryMedia oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.story.id != widget.story.id) {
      _isImageLoaded = false;
      _imageHasError = false;
      _readyDispatched = false;
      _lastVideoBuffering = false;
      widget.onBufferingChanged(true);
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

    final currentVersion = ++_controllerVersion;
    VideoPlayerController? nextController;

    try {
      _videoHasError = false;
      _isVideoInitialized = false;
      _completionSent = false;
      final videoUrl = widget.story.mediaUrls.first;
      final fileInfo = await VideoCacheManager.instance.getFileFromCache(
        videoUrl,
      );

      if (fileInfo != null) {
        nextController = VideoPlayerController.file(fileInfo.file);
      } else {
        nextController = VideoPlayerController.networkUrl(
          Uri.parse(videoUrl),
        );
        _queueDownload(videoUrl);
      }

      await nextController.initialize();
      await nextController.setLooping(false);

      if (!mounted || currentVersion != _controllerVersion) {
        await nextController.dispose();
        return;
      }

      if (widget.isPaused) {
        await nextController.pause();
      } else {
        await nextController.play();
      }

      final previousController = _videoController;
      _videoController = nextController;
      _videoController!.addListener(_onVideoTick);

      if (previousController != null && previousController != nextController) {
        previousController.removeListener(_onVideoTick);
        await previousController.pause();
        await previousController.dispose();
      }

      setState(() {
        _isVideoInitialized = true;
        _videoHasError = false;
      });
      _dispatchReadyOnce();
      widget.onBufferingChanged(false);
    } catch (_) {
      if (nextController != null) {
        await nextController.dispose();
      }
      if (!mounted || currentVersion != _controllerVersion) {
        return;
      }
      if (!mounted) {
        return;
      }

      setState(() {
        _videoHasError = true;
        _isVideoInitialized = false;
      });
      widget.onBufferingChanged(false);
      widget.onMediaLoadError();
    }
  }

  void _onVideoTick() {
    final controller = _videoController;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    final durationMs = controller.value.duration.inMilliseconds;
    final positionMs = controller.value.position.inMilliseconds;
    final buffering = controller.value.isBuffering;
    if (buffering != _lastVideoBuffering) {
      _lastVideoBuffering = buffering;
      widget.onBufferingChanged(buffering);
    }

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
    _controllerVersion++;
    final controller = _videoController;
    _videoController = null;
    if (controller == null) {
      return;
    }

    controller.removeListener(_onVideoTick);
    controller.pause();
    controller.dispose();
  }

  void _queueDownload(String url) {
    if (_queuedDownloads.contains(url)) {
      return;
    }

    _queuedDownloads.add(url);
    _downloadForCache(url);
  }

  Future<void> _downloadForCache(String url) async {
    try {
      await VideoCacheManager.instance.downloadFile(url);
    } catch (_) {
      _queuedDownloads.remove(url);
    }
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
      return Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: widget.story.mediaUrls.first,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            imageBuilder: (context, imageProvider) {
              if (!_isImageLoaded && !_imageHasError) {
                _isImageLoaded = true;
                widget.onBufferingChanged(false);
                _dispatchReadyOnce();
              }

              return Image(
                image: imageProvider,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              );
            },
            placeholder: (context, url) {
              if (!_imageHasError && !_isImageLoaded) {
                widget.onBufferingChanged(true);
              }
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            },
            errorWidget: (context, url, error) {
              if (!_imageHasError) {
                _imageHasError = true;
                widget.onBufferingChanged(false);
                widget.onMediaLoadError();
              }
              return const Center(
                child: Icon(
                  Icons.broken_image,
                  color: Colors.white70,
                  size: 40,
                ),
              );
            },
          ),
          if (!_isImageLoaded && !_imageHasError)
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
        ],
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
      child: Stack(
        fit: StackFit.expand,
        children: [
          FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: size.width,
              height: size.height,
              child: VideoPlayer(_videoController!),
            ),
          ),
          if (_videoController!.value.isBuffering)
            const Center(child: CircularProgressIndicator(color: Colors.white)),
        ],
      ),
    );
  }

  void _dispatchReadyOnce() {
    if (_readyDispatched) {
      return;
    }
    _readyDispatched = true;
    widget.onImageReady();
  }
}
