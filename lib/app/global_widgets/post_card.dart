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
import '../core/utils/date_time_extension.dart';
import '../core/utils/number_formatter.dart';
import '../core/utils/reels_navigation_helper.dart';
import '../routes/app_routes.dart';
import 'auto_play_video.dart';
import 'comment_bottom_sheet.dart';

class PostCard extends StatefulWidget {
  final PostModel post;

  const PostCard({super.key, required this.post});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  final _media = Get.find<GlobalMediaController>();
  final _commentController = Get.find<CommentController>();
  final _likeController = Get.find<LikeController>();
  final _shareController = Get.find<ShareController>();

  bool get hasCaption => widget.post.caption.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      _likeController.initializePost(widget.post.id, widget.post.likeCount);

      _commentController.initializePost(
        widget.post.id,
        widget.post.commentCount,
      );
      _shareController.initializePost(widget.post.id, widget.post.shareCount);
    });
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height * 0.45;

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

                      if (widget.post.mediaType == MediaType.video)
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
    if (widget.post.mediaUrls.isEmpty) return const SizedBox();

    if (widget.post.mediaType == MediaType.video) {
      return GestureDetector(
        onTap: () => ReelsNavigationHelper.openFromPost(widget.post),
        onDoubleTap: _handleLike,
        child: Obx(
          () => AutoPlayVideo(
            videoUrl: widget.post.mediaUrls.first,
            videoId: widget.post.id,
            isMuted: _media.isMuted.value,
          ),
        ),
      );
    }

    return GestureDetector(
      onDoubleTap: _handleLike,
      child: CachedNetworkImage(
        imageUrl: widget.post.mediaUrls.first,
        fit: BoxFit.cover,
      ),
    );
  }

  void _handleLike() {
    if (!_likeController.isLiked(widget.post.id)) {
      _likeController.toggleLike(widget.post.id);
    }
    _media.triggerDoubleTap(widget.post.id);
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
              mIcon: _likeController.isLiked(widget.post.id)
                  ? Icons.favorite
                  : Icons.favorite_border,
              icon: HugeIcons.strokeRoundedFavourite,
              count: NumberFormatter.format(
                _likeController.likeCount(widget.post.id),
              ),
              color: _likeController.isLiked(widget.post.id)
                  ? Colors.red
                  : Colors.white,
              onTap: () => _likeController.toggleLike(widget.post.id),
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
                _commentController.commentCount(widget.post.id),
              ),
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => CommentBottomSheet(postId: widget.post.id),
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
                _shareController.shareCount(widget.post.id),
              ),
              color: _shareController.isSharing(widget.post.id)
                  ? Colors.lightBlueAccent
                  : Colors.white,
              onTap: () => _shareController.sharePost(widget.post),
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
    final user = widget.post.user;
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
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: userId == null
                ? null
                : () => Get.toNamed(
                      Routes.userProfile,
                      arguments: userId,
                    ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage:
                      (user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty)
                      ? NetworkImage(user.avatarUrl!)
                      : null,
                  child: (user?.avatarUrl == null || user!.avatarUrl!.isEmpty)
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
                        '@${user?.username} • ${widget.post.createdAt.timeAgo}',
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
              children: _buildCaptionSpans(widget.post.caption),
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
}


