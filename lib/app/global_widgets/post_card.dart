import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:hugeicons/hugeicons.dart';

import '../data/controllers/global_media_controller.dart';
import '../data/controllers/like_controller.dart';
import '../data/controllers/comment_controller.dart';
import '../data/controllers/share_controller.dart';
import '../data/models/post_model.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/post_repository.dart';
import '../core/utils/date_time_extension.dart';
import '../core/utils/number_formatter.dart';
import '../core/utils/reels_navigation_helper.dart';
import '../routes/app_routes.dart';
import '../modules/post_view/views/post_detail_screen.dart';
import 'auto_play_video.dart';
import 'comment_bottom_sheet.dart';

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
  final _postRepo = Get.find<PostRepository>();
  final _authRepo = Get.find<AuthRepository>();

  late PostModel _post;
  bool _isPostActionLoading = false;

  bool get hasCaption => _post.caption.trim().isNotEmpty;
  bool get _isOwnPost => _authRepo.currentUserId == _post.userId;

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
  void didUpdateWidget(covariant PostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _post = widget.post;

    if (oldWidget.post.id != widget.post.id) {
      _likeController.initializePost(_post.id, _post.likeCount);
      _commentController.initializePost(_post.id, _post.commentCount);
      _shareController.initializePost(_post.id, _post.shareCount);
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height * 0.55;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Column(
            children: [
              _buildGlassUser(),
              ClipRRect(
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                child: SizedBox(
                  height: height,
                  child: Stack(
                    children: [
                      /// MEDIA
                      Positioned.fill(child: _buildMedia()),

                      /// GRADIENT OVERLAY
                      Positioned.fill(
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black38,
                                Colors.transparent,
                                Colors.black54,
                              ],
                            ),
                          ),
                        ),
                      ),

                      /// RIGHT ACTIONS
                      Positioned(
                        right: 0,
                        bottom: height / 4,
                        child: _buildRightActions(),
                      ),

                      if (_post.mediaType == MediaType.video)
                        Positioned(
                          top: 15,
                          right: 15,
                          child: GestureDetector(
                            onTap: _media.toggleMute,
                            child: Obx(
                              () => CircleAvatar(
                                backgroundColor: Colors.black45,
                                radius: 16,
                                child: Icon(
                                  _media.isMuted.value
                                      ? Icons.volume_off
                                      : Icons.volume_up,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                        ),

                      /// BOTTOM GLASS USER INFO
                      if (hasCaption)
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: _buildGlassCaption(),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ================= MEDIA =================

  Widget _buildMedia() {
    if (_post.mediaUrls.isEmpty) return const SizedBox();

    if (_post.mediaType == MediaType.video) {
      return GestureDetector(
        onTap: () {
          if (widget.feedPosts != null && widget.feedPosts!.isNotEmpty) {
            final idx = widget.feedPosts!.indexWhere((p) => p.id == _post.id);
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
      );
    }

    return GestureDetector(
      onDoubleTap: _handleLike,
      child: CachedNetworkImage(
        imageUrl: _post.mediaUrls.first,
        fit: BoxFit.cover,
      ),
    );
  }

  void _handleLike() {
    if (!_likeController.isLiked(_post.id)) {
      _likeController.toggleLike(_post.id);
    }
    _media.triggerDoubleTap(_post.id);
  }

  // ================= RIGHT ACTIONS =================

  Widget _buildRightActions() {
    return Container(
      padding: EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        border: Border.fromBorderSide(
          BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12.0),
          bottomLeft: Radius.circular(12.0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: [
          /// LIKE
          Obx(
            () => _glassAction(
              isM: true,
              mIcon: _likeController.isLiked(_post.id)
                  ? Icons.favorite
                  : Icons.favorite_border,
              icon: HugeIcons.strokeRoundedFavourite,
              count: NumberFormatter.format(
                _likeController.likeCount(_post.id),
              ),
              color: _likeController.isLiked(_post.id)
                  ? Colors.red
                  : Colors.white,
              onTap: () => _likeController.toggleLike(_post.id),
            ),
          ),

          const SizedBox(height: 18),

          /// COMMENT
          Obx(
            () => _glassAction(
              isM: false,
              // icon: Icons.chat_bubble_outline,
              icon: HugeIcons.strokeRoundedComment03,
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

          /// SHARE
          Obx(
            () => _glassAction(
              isM: false,
              // icon: Icons.send_outlined,
              icon: HugeIcons.strokeRoundedShare01,
              count: NumberFormatter.format(
                _shareController.shareCount(_post.id),
              ),
              color: _shareController.isSharing(_post.id)
                  ? Colors.lightBlueAccent
                  : Colors.white,
              onTap: () => _shareController.sharePost(_post),
            ),
          ),
        ],
      ),
    );
  }

  Widget _glassAction({
    required bool isM,
    IconData? mIcon,
    required List<List<dynamic>> icon,
    required String count,
    Color color = Colors.white,
    VoidCallback? onTap,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          // child: Icon(icon, color: color, size: 28),
          child: isM
              ? Icon(mIcon, color: color, size: 28)
              : HugeIcon(icon: icon, color: color, size: 28),
        ),
        const SizedBox(height: 4),
        Text(
          count,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // ================= GLASS CAPTION =================

  Widget _buildGlassUser() {
    final user = _post.user;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userId = user?.id;

    return ClipRRect(
      borderRadius: BorderRadius.only(
        topRight: Radius.circular(20),
        topLeft: Radius.circular(20),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white10.withValues(alpha: 0.05)
                : Colors.black12.withValues(alpha: 0.05),
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(20),
              topLeft: Radius.circular(20),
            ),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: userId == null
                      ? null
                      : () =>
                            Get.toNamed(Routes.userProfile, arguments: userId),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundImage:
                            (user?.avatarUrl != null &&
                                user!.avatarUrl!.isNotEmpty)
                            ? NetworkImage(user.avatarUrl!)
                            : null,
                        child:
                            (user?.avatarUrl == null ||
                                user!.avatarUrl!.isEmpty)
                            ? const Icon(Icons.person, size: 32)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.name.capitalizeFirst ?? '',
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black,
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '@${user?.username} • ${_post.createdAt.timeAgo}',
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_isOwnPost)
                PopupMenuButton<_PostCardAction>(
                  enabled: !_isPostActionLoading,
                  icon: Icon(
                    Icons.more_vert,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
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
        ),
      ),
    );
  }

  Widget _buildGlassCaption() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.only(
        topRight: Radius.circular(20),
        topLeft: Radius.circular(20),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white10.withValues(alpha: 0.05)
                : Colors.black12.withValues(alpha: 0.05),
            // color: Colors.white.withValues(alpha: 0.05),
            // borderRadius: BorderRadius.circular(20),
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(20),
              topLeft: Radius.circular(20),
            ),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: RichText(
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              style: const TextStyle(fontSize: 13),
              children: _buildCaptionSpans(_post.caption),
            ),
          ),
        ),
      ),
    );
  }

  List<TextSpan> _buildCaptionSpans(String caption) {
    final words = caption.split(" ");

    return words.map((word) {
      if (word.startsWith("#")) {
        return TextSpan(
          text: "$word ",
          style: const TextStyle(
            color: Colors.lightBlueAccent,
            fontWeight: FontWeight.w600,
          ),
        );
      } else if (word.startsWith("@")) {
        return TextSpan(
          text: "$word ",
          style: const TextStyle(
            color: Colors.purpleAccent,
            fontWeight: FontWeight.w600,
          ),
        );
      } else {
        return TextSpan(text: "$word ");
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

                              Get.snackbar(
                                'Success',
                                'Post updated successfully',
                                snackPosition: SnackPosition.BOTTOM,
                              );
                            } catch (error) {
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
    } finally {
      // Defer disposal to after frame completes to avoid rebuild issues
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

      Get.snackbar(
        'Success',
        'Post deleted',
        snackPosition: SnackPosition.BOTTOM,
      );

      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    } catch (error) {
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
}
