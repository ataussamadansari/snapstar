import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../core/utils/date_time_extension.dart';
import '../../../core/utils/number_formatter.dart';
import '../../../data/controllers/comment_controller.dart';
import '../../../data/controllers/global_media_controller.dart';
import '../../../data/controllers/like_controller.dart';
import '../../../data/controllers/share_controller.dart';
import '../../../data/models/post_model.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/post_repository.dart';
import '../../../global_widgets/auto_play_video.dart';
import '../../../global_widgets/comment_bottom_sheet.dart';
import '../../../global_widgets/loading_skeleton.dart';
import '../../../global_widgets/subscribe_button.dart';
import '../../main_view/controllers/main_controller.dart';
import '../../../routes/app_routes.dart';
import '../controllers/reels_controller.dart';

enum _ReelPostAction { edit, delete }

class ReelsScreen extends StatefulWidget {
  const ReelsScreen({super.key});

  @override
  State<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends State<ReelsScreen> {
  late final ReelsController _controller;
  late final MainController _mainController;

  @override
  void initState() {
    super.initState();
    _controller = Get.find<ReelsController>();
    _mainController = Get.find<MainController>();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Obx(() {
        final isReelsScreenActive = _mainController.currentIndex.value == 3;
        final activeReelIndex = _controller.currentPage.value;

        if (_controller.isLoading.value && _controller.reels.isEmpty) {
          return const ReelsSkeleton();
        }

        if (_controller.reels.isEmpty) {
          return RefreshIndicator(
            onRefresh: _controller.refreshReels,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 200),
                Center(
                  child: Text(
                    'No reels available right now',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          );
        }

        return Stack(
          children: [
            RefreshIndicator(
              onRefresh: _controller.refreshReels,
              child: PageView.builder(
                controller: _controller.pageController,
                physics: const AlwaysScrollableScrollPhysics(
                  parent: PageScrollPhysics(),
                ),
                scrollDirection: Axis.vertical,
                onPageChanged: (index) {
                  _controller.onPageChanged(index);
                },
                itemCount: _controller.reels.length,
                itemBuilder: (context, index) {
                  return _ReelView(
                    post: _controller.reels[index],
                    isActive: index == activeReelIndex,
                    isScreenActive: isReelsScreenActive,
                  );
                },
              ),
            ),
            if (_controller.isLoadingMore.value)
              const Positioned(
                left: 0,
                right: 0,
                bottom: 24,
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
          ],
        );
      }),
    );
  }
}

class _ReelView extends StatefulWidget {
  const _ReelView({
    required this.post,
    required this.isActive,
    required this.isScreenActive,
  });

  final PostModel post;
  final bool isActive;
  final bool isScreenActive;

  @override
  State<_ReelView> createState() => _ReelViewState();
}

class _ReelViewState extends State<_ReelView>
    with AutomaticKeepAliveClientMixin {
  final _likeController = Get.find<LikeController>();
  final _commentController = Get.find<CommentController>();
  final _shareController = Get.find<ShareController>();
  final _mediaController = Get.find<GlobalMediaController>();
  final _authRepo = Get.find<AuthRepository>();
  final _postRepo = Get.find<PostRepository>();

  late PostModel _post;

  bool _isCaptionExpanded = false;
  bool _isPostActionLoading = false;

  bool get _isOwnPost => _authRepo.currentUserId == _post.userId;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _post = widget.post;

    Future.microtask(() {
      _likeController.initializePost(_post.id, _post.likeCount);
      _commentController.initializePost(_post.id, _post.commentCount);
      _shareController.initializePost(_post.id, _post.shareCount);
    });
  }

  @override
  void didUpdateWidget(covariant _ReelView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _post = widget.post;

    if (oldWidget.post.id != widget.post.id) {
      _isCaptionExpanded = false;
      _likeController.initializePost(_post.id, _post.likeCount);
      _commentController.initializePost(_post.id, _post.commentCount);
      _shareController.initializePost(_post.id, _post.shareCount);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final user = _post.user;
    final caption = _post.caption.trim();
    final hasCaption = caption.isNotEmpty;
    final avatarUrl = user?.avatarUrl;
    final hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;
    final myId = _authRepo.currentUserId;
    final userId = user?.id;

    return Stack(
      fit: StackFit.expand,
      children: [
        GestureDetector(
          onDoubleTap: () {
            if (!_likeController.isLiked(_post.id)) {
              _likeController.toggleLike(_post.id);
            }
          },
          child: _buildReelMedia(),
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black45,
                Colors.transparent,
                Colors.transparent,
                Colors.black54,
              ],
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopBar(),
                const Spacer(),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: user?.id == null
                                      ? null
                                      : () => Get.toNamed(
                                          Routes.userProfile,
                                          arguments: user!.id,
                                        ),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 16,
                                        backgroundColor: Colors.grey.shade800,
                                        backgroundImage: hasAvatar
                                            ? NetworkImage(avatarUrl)
                                            : null,
                                        child: hasAvatar
                                            ? null
                                            : const Icon(
                                                Icons.person,
                                                color: Colors.white,
                                                size: 18,
                                              ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          '@${user?.username ?? 'snapstar'}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ),
                                      if (userId != null && userId != myId) ...[
                                        const SizedBox(width: 8),
                                        SizedBox(
                                          width: 118,
                                          child: SubscriberButton(
                                            userId: userId,
                                            fullWidth: true,
                                            height: 32,
                                            borderRadius: 9,
                                            fontSize: 12,
                                            horizontalPadding:
                                                const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                              if (_isOwnPost)
                                PopupMenuButton<_ReelPostAction>(
                                  enabled: !_isPostActionLoading,
                                  icon: const Icon(
                                    Icons.more_vert,
                                    color: Colors.white,
                                  ),
                                  onSelected: (action) {
                                    if (_isPostActionLoading) {
                                      return;
                                    }

                                    switch (action) {
                                      case _ReelPostAction.edit:
                                        _openEditPostDialog();
                                        break;
                                      case _ReelPostAction.delete:
                                        _confirmDeletePost();
                                        break;
                                    }
                                  },
                                  itemBuilder: (context) => const [
                                    PopupMenuItem<_ReelPostAction>(
                                      value: _ReelPostAction.edit,
                                      child: Text('Edit'),
                                    ),
                                    PopupMenuItem<_ReelPostAction>(
                                      value: _ReelPostAction.delete,
                                      child: Text('Delete'),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                          if (hasCaption) ...[
                            const SizedBox(height: 10),
                            _buildCaption(caption),
                          ],
                          const SizedBox(height: 6),
                          Text(
                            _post.createdAt.timeAgo,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.75),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildActionColumn(),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopBar() {
    final reelsController = Get.find<ReelsController>();

    return Row(
      children: [
        const Text(
          'Reels',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: reelsController.refreshReels,
          icon: const Icon(Icons.refresh_rounded, color: Colors.white),
        ),
        Obx(
          () => IconButton(
            onPressed: _mediaController.toggleMute,
            icon: Icon(
              _mediaController.isMuted.value
                  ? Icons.volume_off_rounded
                  : Icons.volume_up_rounded,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReelMedia() {
    if (_post.mediaUrls.isEmpty) {
      return const SizedBox.shrink();
    }

    final shouldPlay = widget.isScreenActive && widget.isActive;

    if (!shouldPlay) {
      final thumbnailUrl = _post.thumbnailUrls.isNotEmpty
          ? _post.thumbnailUrls.first
          : null;

      if (thumbnailUrl != null && thumbnailUrl.isNotEmpty) {
        return CachedNetworkImage(imageUrl: thumbnailUrl, fit: BoxFit.cover);
      }

      return const ColoredBox(color: Colors.black);
    }

    return Obx(
      () => AutoPlayVideo(
        videoUrl: _post.mediaUrls.first,
        videoId: _post.id,
        isMuted: _mediaController.isMuted.value,
        isActive: true,
        respectVisibility: false,
        enforceSinglePlayback: false,
        keepAlive: false,
      ),
    );
  }

  Widget _buildActionColumn() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Obx(
          () => _ActionButton(
            icon: _likeController.isLiked(_post.id)
                ? Icons.favorite
                : Icons.favorite_border,
            color: _likeController.isLiked(_post.id)
                ? Colors.redAccent
                : Colors.white,
            count: NumberFormatter.format(_likeController.likeCount(_post.id)),
            onTap: () => _likeController.toggleLike(_post.id),
          ),
        ),
        const SizedBox(height: 18),
        Obx(
          () => _ActionButton(
            hugeIcon: HugeIcons.strokeRoundedComment03,
            count: NumberFormatter.format(
              _commentController.commentCount(_post.id),
            ),
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
        const SizedBox(height: 18),
        Obx(
          () => _ActionButton(
            hugeIcon: HugeIcons.strokeRoundedShare01,
            color: _shareController.isSharing(_post.id)
                ? Colors.lightBlueAccent
                : Colors.white,
            count: NumberFormatter.format(
              _shareController.shareCount(_post.id),
            ),
            onTap: () => _shareController.sharePost(_post),
          ),
        ),
        const SizedBox(height: 18),
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.white70),
            image: _post.thumbnailUrls.isNotEmpty
                ? DecorationImage(
                    image: CachedNetworkImageProvider(
                      _post.thumbnailUrls.first,
                    ),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: _post.thumbnailUrls.isEmpty
              ? const Icon(
                  Icons.music_note_rounded,
                  color: Colors.white,
                  size: 18,
                )
              : null,
        ),
      ],
    );
  }

  Future<void> _openEditPostDialog() async {
    final captionController = TextEditingController(text: _post.caption);
    final locationController = TextEditingController(
      text: _post.location ?? '',
    );
    bool isSaving = false;

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

                            Get.snackbar(
                              'Success',
                              'Post updated successfully',
                              snackPosition: SnackPosition.BOTTOM,
                            );
                          } catch (_) {
                            Get.snackbar(
                              'Error',
                              'Unable to update post',
                              snackPosition: SnackPosition.BOTTOM,
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

    // delay disposal until after the dialog's closing animation completes to
    // avoid using a disposed controller inside the widget tree. This mirrors the
    // pattern used elsewhere (see post_card.dart).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      captionController.dispose();
      locationController.dispose();
    });
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

      Get.snackbar(
        'Success',
        'Post deleted',
        snackPosition: SnackPosition.BOTTOM,
      );

      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    } catch (_) {
      Get.snackbar(
        'Error',
        'Unable to delete post',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isPostActionLoading = false;
        });
      }
    }
  }

  Widget _buildCaption(String caption) {
    const minExpandableLength = 85;
    final canExpand = caption.length > minExpandableLength;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          caption,
          maxLines: _isCaptionExpanded ? 8 : 2,
          overflow: _isCaptionExpanded
              ? TextOverflow.visible
              : TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            height: 1.3,
          ),
        ),
        if (canExpand)
          GestureDetector(
            onTap: () {
              setState(() {
                _isCaptionExpanded = !_isCaptionExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                _isCaptionExpanded ? 'See less' : 'See more',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    this.icon,
    this.hugeIcon,
    this.count,
    this.color = Colors.white,
    this.onTap,
  });

  final IconData? icon;
  final List<List<dynamic>>? hugeIcon;
  final String? count;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          if (icon != null) Icon(icon, color: color, size: 30),
          if (icon == null && hugeIcon != null)
            HugeIcon(icon: hugeIcon!, color: color, size: 30),
          if (count != null) ...[
            const SizedBox(height: 4),
            Text(
              count!,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
