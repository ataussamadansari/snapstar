import 'package:flutter/material.dart';

import '../../../../data/models/post_model.dart';
import '../../../../global_widgets/app_cached_image.dart';

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
          AppCachedImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
          ),
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
