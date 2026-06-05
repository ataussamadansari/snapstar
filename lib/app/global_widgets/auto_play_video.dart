import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';
import '../core/utils/video_cache_manager.dart';

class AutoPlayVideo extends StatefulWidget {
  final String videoUrl;
  final String videoId;
  final bool isMuted;
  final bool isActive;
  final bool isPaused;
  final bool resetOnDeactivate;
  final bool respectVisibility;
  final bool enforceSinglePlayback;
  final bool keepAlive;

  /// Watch time callback — jab video deactivate ho (page change/navigate away)
  /// [watchedSeconds] aur [totalSeconds] milte hain
  final void Function(double watchedSeconds, double totalSeconds)? onWatchTime;

  const AutoPlayVideo({
    super.key,
    required this.videoUrl,
    required this.videoId,
    required this.isMuted,
    this.isActive = true,
    this.isPaused = false,
    this.resetOnDeactivate = true,
    this.respectVisibility = true,
    this.enforceSinglePlayback = false,
    this.keepAlive = true,
    this.onWatchTime,
  });

  static void setActiveSinglePlaybackVideo(
    String? videoId, {
    bool resetInactive = true,
  }) {
    _AutoPlayVideoState.setSinglePlaybackActiveVideo(
      videoId,
      resetInactive: resetInactive,
    );
  }

  @override
  State<AutoPlayVideo> createState() => _AutoPlayVideoState();
}

class _AutoPlayVideoState extends State<AutoPlayVideo>
    with AutomaticKeepAliveClientMixin {
  static final Set<String> _queuedDownloads = <String>{};
  static final Map<String, VideoPlayerController> _singlePlaybackControllers =
      <String, VideoPlayerController>{};
  static String? _singlePlaybackActiveId;

  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  bool _isVisibleEnough = false;
  int _controllerVersion = 0;

  // Watch time tracking
  DateTime? _playStartTime;
  double _totalWatchedSeconds = 0.0;

  @override
  bool get wantKeepAlive => widget.keepAlive;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final currentVersion = ++_controllerVersion;
    VideoPlayerController? nextController;

    try {
      final fileInfo = await VideoCacheManager.instance.getFileFromCache(
        widget.videoUrl,
      );

      if (fileInfo != null) {
        nextController = VideoPlayerController.file(fileInfo.file);
      } else {
        nextController = VideoPlayerController.networkUrl(
          Uri.parse(widget.videoUrl),
        );
        _queueDownload(widget.videoUrl);
      }

      await nextController.initialize();
      await nextController.setLooping(true);
      await nextController.setVolume(widget.isMuted ? 0 : 1);

      if (!mounted || currentVersion != _controllerVersion) {
        await nextController.dispose();
        return;
      }

      final previousController = _controller;
      _controller = nextController;
      _hasError = false;
      _isInitialized = true;

      if (previousController != null && previousController != nextController) {
        await previousController.pause();
        await previousController.dispose();
      }

      if (widget.enforceSinglePlayback) {
        _singlePlaybackControllers[widget.videoId] = nextController;
      }

      setState(() {});
      _syncPlaybackState();
    } catch (_) {
      if (nextController != null) {
        await nextController.dispose();
      }
      if (!mounted || currentVersion != _controllerVersion) return;
      setState(() {
        _hasError = true;
        _isInitialized = false;
      });
    }
  }

  @override
  void didUpdateWidget(covariant AutoPlayVideo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.keepAlive != widget.keepAlive) {
      updateKeepAlive();
    }
    _controller?.setVolume(widget.isMuted ? 0 : 1);

    if ((oldWidget.enforceSinglePlayback || widget.enforceSinglePlayback) &&
        oldWidget.videoId != widget.videoId) {
      _singlePlaybackControllers.remove(oldWidget.videoId);
      if (widget.enforceSinglePlayback && _controller != null) {
        _singlePlaybackControllers[widget.videoId] = _controller!;
      }
    }

    if (!oldWidget.enforceSinglePlayback &&
        widget.enforceSinglePlayback &&
        _controller != null) {
      _singlePlaybackControllers[widget.videoId] = _controller!;
    } else if (oldWidget.enforceSinglePlayback && !widget.enforceSinglePlayback) {
      _singlePlaybackControllers.remove(oldWidget.videoId);
    }

    if (oldWidget.isActive && !widget.isActive && widget.resetOnDeactivate) {
      // Page change — watch time report karo phir pause karo
      _reportWatchTime();
      _controller?.pause();
      _controller?.seekTo(Duration.zero);
    }

    if (widget.enforceSinglePlayback && widget.isActive) {
      setSinglePlaybackActiveVideo(widget.videoId);
    }

    _syncPlaybackState();
  }

  @override
  void dispose() {
    _controllerVersion++;
    // Widget destroy hone se pehle watch time report karo
    _reportWatchTime();
    if (widget.enforceSinglePlayback) {
      _singlePlaybackControllers.remove(widget.videoId);
      if (_singlePlaybackActiveId == widget.videoId) {
        _singlePlaybackActiveId = null;
      }
    }
    final controller = _controller;
    _controller = null;
    if (controller != null) {
      controller.pause();
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_hasError) {
      return const Center(
        child: Icon(Icons.error_outline, color: Colors.white70, size: 30),
      );
    }

    return VisibilityDetector(
      key: Key(widget.videoId),
      onVisibilityChanged: (info) {
        if (!_isInitialized) return;
        _isVisibleEnough = info.visibleFraction > 0.8;
        _syncPlaybackState();
      },
      child: _isInitialized
          ? Center(
              child: AspectRatio(
                aspectRatio: _controller!.value.aspectRatio,
                child: VideoPlayer(_controller!),
              ),
            )
          : const Center(child: CircularProgressIndicator()),
    );
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

  void _syncPlaybackState() {
    if (!_isInitialized || _controller == null) {
      return;
    }

    if (widget.enforceSinglePlayback &&
        widget.isActive &&
        _singlePlaybackActiveId != widget.videoId) {
      setSinglePlaybackActiveVideo(widget.videoId);
    }

    final visibilityPass = widget.respectVisibility ? _isVisibleEnough : true;
    final singlePlaybackPass =
        !widget.enforceSinglePlayback ||
        _singlePlaybackActiveId == null ||
        _singlePlaybackActiveId == widget.videoId;
    final shouldPlay =
        visibilityPass && widget.isActive && !widget.isPaused && singlePlaybackPass;

    if (shouldPlay) {
      if (!_controller!.value.isPlaying) {
        // Video play shuru ho rahi hai — start time note karo
        _playStartTime = DateTime.now();
        _controller!.play();
      }
    } else if (_controller!.value.isPlaying) {
      // Video ruk rahi hai — watch time accumulate karo
      _accumulateWatchTime();
      _controller!.pause();
    }
  }

  void _accumulateWatchTime() {
    if (_playStartTime == null) return;
    final elapsed = DateTime.now().difference(_playStartTime!).inMilliseconds / 1000.0;
    if (elapsed > 0) {
      _totalWatchedSeconds += elapsed;
    }
    _playStartTime = null;
  }

  void _reportWatchTime() {
    if (widget.onWatchTime == null) return;
    // Agar abhi bhi play ho raha hai to final chunk accumulate karo
    if (_controller?.value.isPlaying == true) {
      _accumulateWatchTime();
    }
    final total = _controller?.value.duration.inSeconds.toDouble() ?? 0.0;
    if (_totalWatchedSeconds > 0 && total > 0) {
      widget.onWatchTime!(_totalWatchedSeconds, total);
    }
    // Reset
    _totalWatchedSeconds = 0.0;
  }

  static void setSinglePlaybackActiveVideo(
    String? videoId, {
    bool resetInactive = true,
  }) {
    _singlePlaybackActiveId = videoId;

    for (final entry in _singlePlaybackControllers.entries.toList()) {
      final controller = entry.value;

      if (!controller.value.isInitialized) {
        continue;
      }

      if (videoId != null && entry.key == videoId) {
        if (!controller.value.isPlaying) {
          controller.play();
        }
      } else {
        if (controller.value.isPlaying) {
          controller.pause();
        }
        if (resetInactive) {
          controller.seekTo(Duration.zero);
        }
      }
    }
  }
}

/*class AutoPlayVideo extends StatefulWidget {
  final String videoUrl;
  const AutoPlayVideo({super.key, required this.videoUrl});

  @override
  State<AutoPlayVideo> createState() => _AutoPlayVideoState();
}

class _AutoPlayVideoState extends State<AutoPlayVideo> with AutomaticKeepAliveClientMixin {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _showReplayBtn = false;
  static bool _globalMuted = true;

  @override
  bool get wantKeepAlive => true; // State ko destroy nahi hone dega

  @override
  void initState() {
    super.initState();
    _initializeWithCache();
  }

  // 🟢 Step 1: Cache se file uthao ya download karo
  Future<void> _initializeWithCache() async {
    try {
      final fileInfo = await VideoCacheManager.instance.getFileFromCache(widget.videoUrl);

      if (fileInfo != null) {
        // Cache mein file mil gayi (Instant Play)
        _controller = VideoPlayerController.file(fileInfo.file);
      } else {
        // Cache mein nahi hai, Network se chalao aur sath mein download karo
        _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
        VideoCacheManager.instance.downloadFile(widget.videoUrl); // Background download
      }

      await _controller!.initialize();
      _controller!.setVolume(_globalMuted ? 0 : 1);
      _controller!.setLooping(false); // Khatam hone par replay btn dikhana hai

      if (mounted) {
        setState(() => _isInitialized = true);
        _controller!.addListener(_videoListener);
      }
    } catch (e) {
      debugPrint("Streaming Error: $e");
    }
  }

  void _videoListener() {
    if (!mounted || _controller == null) return;
    if (_controller!.value.position >= _controller!.value.duration && _isInitialized) {
      if (!_showReplayBtn) setState(() => _showReplayBtn = true);
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_videoListener);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Mixin ke liye zaruri hai

    return VisibilityDetector(
      key: Key(widget.videoUrl),
      onVisibilityChanged: (info) {
        if (!mounted || !_isInitialized || _controller == null) return;

        if (info.visibleFraction > 0.8) {
          if (!_controller!.value.isPlaying) {
            _controller!.play();
            if (_showReplayBtn) setState(() => _showReplayBtn = false);
          }
        } else if (info.visibleFraction < 0.2) {
          if (_controller!.value.isPlaying) {
            _controller!.pause();
          }
        }
      },
      child: GestureDetector(
        onTap: () {
          setState(() {
            _globalMuted = !_globalMuted;
            _controller?.setVolume(_globalMuted ? 0 : 1);
          });
        },
        child: Container(
          height: 400,
          width: double.infinity,
          color: Colors.black,
          child: _isInitialized && _controller != null
              ? Stack(
            alignment: Alignment.center,
            children: [
              AspectRatio(
                aspectRatio: _controller!.value.aspectRatio,
                child: VideoPlayer(_controller!),
              ),
              // Mute Icon
              Positioned(
                top: 15, right: 15,
                child: CircleAvatar(
                  backgroundColor: Colors.black45,
                  radius: 15,
                  child: Icon(_globalMuted ? Icons.volume_off : Icons.volume_up,
                      color: Colors.white, size: 16),
                ),
              ),
              // Replay Button
              if (_showReplayBtn)
                CircleAvatar(
                  backgroundColor: Colors.black54,
                  radius: 30,
                  child: IconButton(
                    icon: const Icon(Icons.replay, color: Colors.white, size: 30),
                    onPressed: () {
                      _controller!.seekTo(Duration.zero);
                      _controller!.play();
                      setState(() => _showReplayBtn = false);
                    },
                  ),
                ),
            ],
          )
              : const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      ),
    );
  }
}*/

/*
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

// auto_play_video.dart

class AutoPlayVideo extends StatefulWidget {
  final String videoUrl;
  const AutoPlayVideo({super.key, required this.videoUrl});

  @override
  State<AutoPlayVideo> createState() => _AutoPlayVideoState();
}

// 🟢 Step 1: Add AutomaticKeepAliveClientMixin
class _AutoPlayVideoState extends State<AutoPlayVideo> with AutomaticKeepAliveClientMixin {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _showReplayBtn = false;
  static bool _globalMuted = true; // 🟢 Saare videos ka mute status sync rakhega

  @override
  bool get wantKeepAlive => true; // 🟢 Step 2: Keep the state alive

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  Future<void> _initializeController() async {
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
    try {
      // 🟢 Instagram style streaming speed ke liye
      await _controller.initialize();
      _controller.setVolume(_globalMuted ? 0 : 1);

      if (mounted) {
        setState(() => _isInitialized = true);
        _controller.addListener(_videoListener);
      }
    } catch (e) {
      debugPrint("Video Init Error: $e");
    }
  }

  void _videoListener() {
    if (!mounted) return;
    if (_controller.value.position >= _controller.value.duration && _isInitialized) {
      if (!_showReplayBtn) setState(() => _showReplayBtn = true);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_videoListener);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // 🟢 Step 3: Required for Mixin

    if (!_isInitialized) {
      return Container(
        height: 400,
        color: Colors.black12,
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    return VisibilityDetector(
      key: Key(widget.videoUrl),
      onVisibilityChanged: (info) {
        if (!mounted || !_isInitialized) return;

        // 🟢 Logic: Agar 80% dikh rahi hai toh play
        if (info.visibleFraction > 0.8) {
          if (!_controller.value.isPlaying) {
            _controller.play();
            setState(() => _showReplayBtn = false);
          }
        }
        // 🟢 Logic: Agar 20% se kam dikhe toh sirf Pause (Dispose nahi)
        // Isse wapas aane par loading nahi hogi, turant resume hoga
        else if (info.visibleFraction < 0.2) {
          if (_controller.value.isPlaying) {
            _controller.pause();
          }
        }
      },
      child: GestureDetector(
        onTap: () {
          setState(() {
            _globalMuted = !_globalMuted;
            _controller.setVolume(_globalMuted ? 0 : 1);
          });
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: VideoPlayer(_controller),
            ),
            // Mute/Unmute Indicator
            Positioned(
              bottom: 15,
              right: 15,
              child: CircleAvatar(
                backgroundColor: Colors.black45,
                radius: 15,
                child: Icon(_globalMuted ? Icons.volume_off : Icons.volume_up,
                    color: Colors.white, size: 18),
              ),
            ),
            // Replay Overlay
            if (_showReplayBtn)
              Container(
                color: Colors.black26,
                child: IconButton(
                  icon: const Icon(Icons.replay, color: Colors.white, size: 40),
                  onPressed: () {
                    _controller.seekTo(Duration.zero);
                    _controller.play();
                    setState(() => _showReplayBtn = false);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
*/
