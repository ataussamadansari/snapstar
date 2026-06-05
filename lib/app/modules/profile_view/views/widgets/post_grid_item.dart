import 'package:flutter/material.dart';

import '../../../../core/utils/number_formatter.dart';
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

          // Video indicator — top right
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

          // Watch count — images aur videos dono ke liye
          if (post.watchCount > 0)
            Positioned(
              bottom: 5,
              left: 5,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.visibility,
                    color: Colors.white,
                    size: 13,
                    shadows: [Shadow(blurRadius: 4, color: Colors.black87)],
                  ),
                  const SizedBox(width: 3),
                  Text(
                    NumberFormatter.format(post.watchCount),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      shadows: [Shadow(blurRadius: 4, color: Colors.black87)],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
