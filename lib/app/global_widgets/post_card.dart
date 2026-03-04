import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';

import '../core/utils/helpers.dart';
import '../core/utils/date_time_extension.dart';
import '../core/utils/number_formatter.dart';
import '../core/utils/reels_navigation_helper.dart';
import '../data/controllers/comment_controller.dart';
import '../data/controllers/global_media_controller.dart';
import '../data/controllers/like_controller.dart';
import '../data/controllers/post_story_style_controller.dart';
import '../data/controllers/share_controller.dart';
import '../data/models/post_model.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/post_repository.dart';
import '../modules/post_view/views/post_detail_screen.dart';
import '../routes/app_routes.dart';
import 'auto_play_video.dart';
import 'comment_bottom_sheet.dart';
import 'share_post_bottom_sheet.dart';

enum _PostCardAction { edit, delete }

class PostCard extends StatefulWidget {
  final PostModel post;

  /// when true (default) tapping a video opens the reels section; otherwise
  /// opens post detail directly. Set to false in profile feed to avoid
  /// jumping into reels.
  final bool allowReelsNavigation;
  final List<PostModel>? feedPosts;

  const PostCard({
    super.key,
    required this.post,
    this.allowReelsNavigation = true,
    this.feedPosts,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  final _media = Get.find<GlobalMediaController>();
  final _commentController = Get.find<CommentController>();
  final _likeController = Get.find<LikeController>();
  final _shareController = Get.find<ShareController>();
  final _styleController = Get.find<PostStoryStyleController>();
  final _postRepo = Get.find<PostRepository>();
  final _authRepo = Get.find<AuthRepository>();

  late PostModel _post;
  late final PageController _mediaPageController;
  int _currentMediaIndex = 0;
  bool _isPostActionLoading = false;
  final Map<String, double> _resolvedAspectRatios = <String, double>{};

  bool get hasCaption => _post.caption.trim().isNotEmpty;
  bool get _isOwnPost => _authRepo.currentUserId == _post.userId;

  @override
  void initState() {
    super.initState();
    _post = widget.post;
    _mediaPageController = PageController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _likeController.initializePost(_post.id, _post.likeCount);
      _commentController.initializePost(_post.id, _post.commentCount);
      _shareController.initializePost(_post.id, _post.shareCount);
    });

    _primeInitialMediaRatios();
  }

  @override
  void didUpdateWidget(covariant PostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _post = widget.post;

    if (oldWidget.post.id != widget.post.id) {
      _currentMediaIndex = 0;
      if (_mediaPageController.hasClients) {
        _mediaPageController.jumpToPage(0);
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _likeController.initializePost(_post.id, _post.likeCount);
        _commentController.initializePost(_post.id, _post.commentCount);
        _shareController.initializePost(_post.id, _post.shareCount);
      });
    }

    _primeInitialMediaRatios();
  }

  @override
  void dispose() {
    _mediaPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final cornerRadius = _styleController.postCornerRadius.value;
      final cardBg = _styleController.postBackgroundColor;

      return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(cornerRadius),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              _buildMedia(),
              _buildActionRow(),
              _buildLikeSummary(),
              if (hasCaption) _buildCaptionSection(),
              _buildPostMeta(),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildHeader() {
    final user = _post.user;
    final userId = user?.id;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
      child: Row(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: userId == null
                ? null
                : () => Get.toNamed(Routes.userProfile, arguments: userId),
            child: CircleAvatar(
              radius: 18,
              backgroundImage:
                  (user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty)
                  ? NetworkImage(user.avatarUrl!)
                  : null,
              child: (user?.avatarUrl == null || user!.avatarUrl!.isEmpty)
                  ? const Icon(Icons.person, size: 20)
                  : null,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: userId == null
                  ? null
                  : () => Get.toNamed(Routes.userProfile, arguments: userId),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user?.username ?? user?.name ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if ((_post.location ?? '').trim().isNotEmpty)
                    Text(
                      _post.location!.trim(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                ],
              ),
            ),
          ),
          if (_isOwnPost)
            PopupMenuButton<_PostCardAction>(
              enabled: !_isPostActionLoading,
              onSelected: (action) {
                if (_isPostActionLoading) {
                  return;
                }

                switch (action) {
                  case _PostCardAction.edit:
                    _openEditPostDialog();
                    break;
                  case _PostCardAction.delete:
                    _confirmDeletePost();
                    break;
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem<_PostCardAction>(
                  value: _PostCardAction.edit,
                  child: Text('Edit'),
                ),
                PopupMenuItem<_PostCardAction>(
                  value: _PostCardAction.delete,
                  child: Text('Delete'),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildMedia() {
    if (_post.mediaUrls.isEmpty) {
      return const SizedBox.shrink();
    }

    final aspectRatio = _currentAspectRatio();

    if (_post.mediaType == MediaType.video) {
      return Stack(
        children: [
          AspectRatio(
            aspectRatio: aspectRatio,
            child: GestureDetector(
              onTap: () {
                if (widget.feedPosts != null && widget.feedPosts!.isNotEmpty) {
                  final idx = widget.feedPosts!.indexWhere(
                    (p) => p.id == _post.id,
                  );
                  Get.to(
                    () => PostDetailScreen(
                      posts: widget.feedPosts,
                      initialIndex: idx < 0 ? 0 : idx,
                    ),
                  );
                  return;
                }

                if (widget.allowReelsNavigation) {
                  ReelsNavigationHelper.openFromPost(_post);
                } else {
                  Get.to(() => PostDetailScreen(post: _post));
                }
              },
              onDoubleTap: _handleLike,
              child: Obx(
                () => AutoPlayVideo(
                  videoUrl: _post.mediaUrls.first,
                  videoId: _post.id,
                  isMuted: _media.isMuted.value,
                ),
              ),
            ),
          ),
          Positioned(
            right: 10,
            top: 10,
            child: GestureDetector(
              onTap: _media.toggleMute,
              child: Obx(
                () => CircleAvatar(
                  backgroundColor: Colors.black45,
                  radius: 16,
                  child: Icon(
                    _media.isMuted.value ? Icons.volume_off : Icons.volume_up,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (_post.mediaUrls.length == 1) {
      final imageUrl = _post.mediaUrls.first;
      _resolveAspectRatioFor(imageUrl);

      return Stack(
        children: [
          AspectRatio(
            aspectRatio: aspectRatio,
            child: GestureDetector(
              onDoubleTap: _handleLike,
              child: CachedNetworkImage(imageUrl: imageUrl, fit: BoxFit.cover),
            ),
          ),
          Positioned(
            top: 10,
            left: 10,
            child: _buildZoomButton(onTap: () => _openImagePreview(imageUrl)),
          ),
        ],
      );
    }

    return Stack(
      children: [
        AspectRatio(
          aspectRatio: aspectRatio,
          child: GestureDetector(
            onDoubleTap: _handleLike,
            child: PageView.builder(
              controller: _mediaPageController,
              itemCount: _post.mediaUrls.length,
              onPageChanged: (index) {
                if (!mounted) return;
                setState(() {
                  _currentMediaIndex = index;
                });
                _resolveAspectRatioFor(_post.mediaUrls[index]);
              },
              itemBuilder: (context, index) {
                return CachedNetworkImage(
                  imageUrl: _post.mediaUrls[index],
                  fit: BoxFit.cover,
                );
              },
            ),
          ),
        ),
        Positioned(
          top: 10,
          right: 10,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.68),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${_currentMediaIndex + 1}/${_post.mediaUrls.length}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        Positioned(
          top: 10,
          left: 10,
          child: _buildZoomButton(
            onTap: () => _openImagePreview(_post.mediaUrls[_currentMediaIndex]),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 12,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.38),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _post.mediaUrls.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    width: _currentMediaIndex == index ? 14 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: _currentMediaIndex == index
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: _currentMediaIndex == index
                          ? const [
                              BoxShadow(
                                color: Colors.black45,
                                blurRadius: 2,
                                offset: Offset(0, 1),
                              ),
                            ]
                          : null,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      child: Row(
        children: [
          Obx(
            () => _buildActionButton(
              icon: _likeController.isLiked(_post.id) ? Icons.favorite : null,
              hugeIcon: _likeController.isLiked(_post.id)
                  ? null
                  : HugeIcons.strokeRoundedFavourite,
              color: _likeController.isLiked(_post.id) ? Colors.red : null,
              count: _likeController.likeCount(_post.id),
              onTap: () => _likeController.toggleLike(_post.id),
            ),
          ),
          Obx(
            () => _buildActionButton(
              hugeIcon: HugeIcons.strokeRoundedComment03,
              count: _commentController.commentCount(_post.id),
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => CommentBottomSheet(postId: _post.id),
                );
              },
            ),
          ),
          Obx(
            () => _buildActionButton(
              hugeIcon: HugeIcons.strokeRoundedShare01,
              color: _shareController.isSharing(_post.id)
                  ? Colors.lightBlueAccent
                  : null,
              count: _shareController.shareCount(_post.id),
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => SharePostBottomSheet(post: _post),
                );
              },
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    IconData? icon,
    List<List<dynamic>>? hugeIcon,
    Color? color,
    int count = 0,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    final iconSize = _styleController.postActionIconSize.value;
    final buttonRadius = (iconSize / 2) + 12;
    final hasCount = count > 0;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(buttonRadius),
      child: Padding(
        padding: const EdgeInsets.only(right: 14, top: 4, bottom: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            hugeIcon != null
                ? HugeIcon(
                    icon: hugeIcon,
                    size: iconSize,
                    color: color ?? theme.iconTheme.color ?? Colors.black,
                  )
                : Icon(icon, size: iconSize, color: color),
            if (hasCount) ...[
              const SizedBox(width: 4),
              Text(
                NumberFormatter.format(count),
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildZoomButton({required VoidCallback onTap}) {
    return Material(
      color: Colors.black.withValues(alpha: 0.68),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: const Padding(
            padding: EdgeInsets.all(6),
            child: Icon(
              Icons.zoom_out_map_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLikeSummary() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Obx(() {
        final likeCount = _likeController.likeCount(_post.id);
        if (likeCount <= 0) {
          return const SizedBox.shrink();
        }
        return Text(
          '${NumberFormatter.format(likeCount)} likes',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        );
      }),
    );
  }

  Widget _buildCaptionSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 2),
      child: RichText(
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        text: TextSpan(
          style: DefaultTextStyle.of(context).style.copyWith(fontSize: 13),
          children: [
            TextSpan(
              text: '${_post.user?.username ?? ''} ',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            ..._buildCaptionSpans(_post.caption),
          ],
        ),
      ),
    );
  }

  Widget _buildPostMeta() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 3, 12, 0),
      child: Obx(
        () => Text(
          '${NumberFormatter.format(_commentController.commentCount(_post.id))} comments • ${_post.createdAt.timeAgo}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
    );
  }

  void _handleLike() {
    if (!_likeController.isLiked(_post.id)) {
      _likeController.toggleLike(_post.id);
    }
    _media.triggerDoubleTap(_post.id);
  }

  void _openImagePreview(String imageUrl) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black,
      builder: (dialogContext) {
        return Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: Stack(
              children: [
                Center(
                  child: InteractiveViewer(
                    minScale: 1,
                    maxScale: 5,
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.68),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.22),
                      ),
                    ),
                    child: IconButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _primeInitialMediaRatios() {
    if (_post.mediaType == MediaType.video || _post.mediaUrls.isEmpty) {
      return;
    }

    final upto = _post.mediaUrls.length > 2 ? 2 : _post.mediaUrls.length;
    for (var i = 0; i < upto; i++) {
      _resolveAspectRatioFor(_post.mediaUrls[i]);
    }
  }

  double _currentAspectRatio() {
    if (_post.mediaType == MediaType.video) {
      return 4 / 5;
    }

    final mediaUrl = _currentMediaUrl();
    if (mediaUrl == null) {
      return 1;
    }

    return _resolvedAspectRatios[mediaUrl] ?? 1;
  }

  String? _currentMediaUrl() {
    if (_post.mediaUrls.isEmpty) {
      return null;
    }

    final safeIndex = _currentMediaIndex.clamp(0, _post.mediaUrls.length - 1);
    return _post.mediaUrls[safeIndex];
  }

  void _resolveAspectRatioFor(String mediaUrl) {
    if (_post.mediaType == MediaType.video ||
        _resolvedAspectRatios.containsKey(mediaUrl)) {
      return;
    }

    final imageProvider = CachedNetworkImageProvider(mediaUrl);
    final stream = imageProvider.resolve(const ImageConfiguration());

    late final ImageStreamListener listener;
    listener = ImageStreamListener(
      (ImageInfo image, bool synchronousCall) {
        final width = image.image.width.toDouble();
        final height = image.image.height.toDouble();
        if (width <= 0 || height <= 0) {
          stream.removeListener(listener);
          return;
        }

        final ratio = (width / height).clamp(0.8, 1.91);
        if (mounted) {
          setState(() {
            _resolvedAspectRatios[mediaUrl] = ratio;
          });
        } else {
          _resolvedAspectRatios[mediaUrl] = ratio;
        }

        stream.removeListener(listener);
      },
      onError: (dynamic _, StackTrace? __) {
        _resolvedAspectRatios[mediaUrl] = 1;
        stream.removeListener(listener);
      },
    );

    stream.addListener(listener);
  }

  List<TextSpan> _buildCaptionSpans(String caption) {
    final words = caption.split(' ');

    return words.map((word) {
      if (word.startsWith('#')) {
        return TextSpan(
          text: '$word ',
          style: const TextStyle(
            color: Colors.lightBlueAccent,
            fontWeight: FontWeight.w600,
          ),
        );
      } else if (word.startsWith('@')) {
        return TextSpan(
          text: '$word ',
          style: const TextStyle(
            color: Colors.purpleAccent,
            fontWeight: FontWeight.w600,
          ),
        );
      } else {
        return TextSpan(text: '$word ');
      }
    }).toList();
  }

  Future<void> _openEditPostDialog() async {
    final captionController = TextEditingController(text: _post.caption);
    final locationController = TextEditingController(
      text: _post.location ?? '',
    );
    bool isSaving = false;

    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (dialogContext, setDialogState) {
              return AlertDialog(
                title: const Text('Edit post'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: captionController,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: 'Caption'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: locationController,
                      decoration: const InputDecoration(
                        labelText: 'Location (optional)',
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: isSaving
                        ? null
                        : () => Navigator.of(dialogContext).pop(),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: isSaving
                        ? null
                        : () async {
                            final nextCaption = captionController.text.trim();
                            final rawLocation = locationController.text.trim();
                            final nextLocation = rawLocation.isEmpty
                                ? null
                                : rawLocation;
                            final hasChanges =
                                nextCaption != _post.caption ||
                                nextLocation != _post.location;

                            if (!hasChanges) {
                              Navigator.of(dialogContext).pop();
                              return;
                            }

                            setDialogState(() {
                              isSaving = true;
                            });

                            try {
                              await _postRepo.editPost(
                                postId: _post.id,
                                caption: nextCaption,
                                location: nextLocation,
                              );

                              if (!mounted) {
                                return;
                              }

                              setState(() {
                                _post = PostModel(
                                  id: _post.id,
                                  userId: _post.userId,
                                  mediaType: _post.mediaType,
                                  caption: nextCaption,
                                  mediaUrls: _post.mediaUrls,
                                  thumbnailUrls: _post.thumbnailUrls,
                                  likeCount: _post.likeCount,
                                  commentCount: _post.commentCount,
                                  shareCount: _post.shareCount,
                                  isDeleted: _post.isDeleted,
                                  location: nextLocation,
                                  createdAt: _post.createdAt,
                                  updatedAt: DateTime.now(),
                                  user: _post.user,
                                );
                              });

                              if (dialogContext.mounted) {
                                Navigator.of(dialogContext).pop();
                              }

                              AppHelpers.showSnackBar(
                                title: 'Success',
                                message: 'Post updated successfully',
                                isError: false,
                              );
                            } catch (error) {
                              AppHelpers.showSnackBar(
                                title: 'Error',
                                message: 'Unable to update post',
                                isError: true,
                              );
                            } finally {
                              if (dialogContext.mounted) {
                                setDialogState(() {
                                  isSaving = false;
                                });
                              }
                            }
                          },
                    child: isSaving
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save'),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        captionController.dispose();
        locationController.dispose();
      });
    }
  }

  Future<void> _confirmDeletePost() async {
    final shouldDelete =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: const Text('Delete post?'),
              content: const Text(
                'This post will be removed from your profile and feed.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('Delete'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!shouldDelete || _isPostActionLoading) {
      return;
    }

    setState(() {
      _isPostActionLoading = true;
    });

    try {
      await _postRepo.softDeletePost(_post.id);

      if (!mounted) {
        return;
      }

      AppHelpers.showSnackBar(
        title: 'Success',
        message: 'Post deleted',
        isError: false,
      );

      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    } catch (error) {
      AppHelpers.showSnackBar(
        title: 'Error',
        message: 'Unable to delete post',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isPostActionLoading = false;
        });
      }
    }
  }
}
