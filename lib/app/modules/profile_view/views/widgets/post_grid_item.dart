import 'package:flutter/material.dart';

import '../../../../data/models/post_model.dart';

class PostGridItem extends StatelessWidget {
  final PostModel post;
  final VoidCallback? onTap;

  const PostGridItem({
    super.key,
    required this.post,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isVideo = post.mediaType == MediaType.video;

    final imageUrl = isVideo
        ? (post.thumbnailUrls.isNotEmpty
        ? post.thumbnailUrls.first
        : post.mediaUrls.first)
        : post.mediaUrls.first;

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          /// 📷 IMAGE / THUMBNAIL
          Image.network(
            imageUrl,
            fit: BoxFit.cover,
          ),

          /// 🎬 VIDEO ICON (top right)
          if (isVideo)
            const Positioned(
              top: 6,
              right: 6,
              child: Icon(
                Icons.play_circle_fill,
                color: Colors.white,
                size: 22,
              ),
            ),
        ],
      ),
    );
  }
}
