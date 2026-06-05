import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/post_model.dart';
import '../../../data/services/hashtag_service.dart';
import '../../../global_widgets/app_cached_image.dart';
import '../../../global_widgets/loading_skeleton.dart';
import '../../post_view/views/post_detail_screen.dart';

class HashtagPostsScreen extends StatefulWidget {
  const HashtagPostsScreen({super.key});

  @override
  State<HashtagPostsScreen> createState() => _HashtagPostsScreenState();
}

class _HashtagPostsScreenState extends State<HashtagPostsScreen> {
  late final String _tag;
  late final HashtagService _hashtagService;

  final RxList<PostModel> _posts = <PostModel>[].obs;
  final RxBool _isLoading = true.obs;
  final RxBool _isLoadingMore = false.obs;
  bool _hasMore = true;
  int _offset = 0;
  static const _pageSize = 24;

  @override
  void initState() {
    super.initState();
    // Route argument se tag lo — '#' strip karo agar hai
    final arg = Get.arguments?.toString() ?? '';
    _tag = arg.startsWith('#') ? arg.substring(1) : arg;
    _hashtagService = Get.find<HashtagService>();
    _loadPosts(refresh: true);
  }

  Future<void> _loadPosts({bool refresh = false}) async {
    if (refresh) {
      _offset = 0;
      _hasMore = true;
      _isLoading.value = true;
    } else {
      if (!_hasMore || _isLoadingMore.value) return;
      _isLoadingMore.value = true;
    }

    try {
      final raw = await _hashtagService.fetchPostsByHashtag(
        tag: _tag,
        limit: _pageSize,
        offset: _offset,
      );

      final fetched = raw.map((e) => PostModel.fromJson(e)).toList();

      if (refresh) {
        _posts.assignAll(fetched);
      } else {
        _posts.addAll(fetched);
      }

      _hasMore = fetched.length >= _pageSize;
      _offset += fetched.length;
    } catch (_) {
    } finally {
      _isLoading.value = false;
      _isLoadingMore.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '#$_tag',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Obx(() {
        if (_isLoading.value) {
          return const _HashtagGridSkeleton();
        }

        if (_posts.isEmpty) {
          return Center(
            child: Text(
              'No posts found for this hashtag',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => _loadPosts(refresh: true),
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification.metrics.pixels >=
                  notification.metrics.maxScrollExtent - 300) {
                _loadPosts();
              }
              return false;
            },
            child: CustomScrollView(
              slivers: [
                // Post count header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Text(
                      '${_posts.length}${_hasMore ? '+' : ''} posts',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
                          ),
                    ),
                  ),
                ),

                SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final post = _posts[index];
                      return GestureDetector(
                        onTap: () => Get.to(
                          () => PostDetailScreen(
                            posts: _posts,
                            initialIndex: index,
                          ),
                        ),
                        child: _PostThumbnail(post: post),
                      );
                    },
                    childCount: _posts.length,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 2,
                    crossAxisSpacing: 2,
                  ),
                ),

                if (_isLoadingMore.value)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    ),
                  ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

class _PostThumbnail extends StatelessWidget {
  const _PostThumbnail({required this.post});
  final PostModel post;

  @override
  Widget build(BuildContext context) {
    final thumbnailUrl = post.thumbnailUrls.isNotEmpty
        ? post.thumbnailUrls.first
        : post.mediaUrls.isNotEmpty
            ? post.mediaUrls.first
            : null;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (thumbnailUrl != null)
          AppCachedImage(imageUrl: thumbnailUrl, fit: BoxFit.cover)
        else
          Container(color: Theme.of(context).colorScheme.surfaceContainerHighest),

        // Video indicator
        if (post.mediaType == MediaType.video)
          const Positioned(
            top: 6,
            right: 6,
            child: Icon(Icons.play_circle_fill, color: Colors.white, size: 20),
          ),

        // Multi-image indicator
        if (post.mediaType == MediaType.image && post.mediaUrls.length > 1)
          const Positioned(
            top: 6,
            right: 6,
            child: Icon(Icons.collections, color: Colors.white, size: 20),
          ),
      ],
    );
  }
}

class _HashtagGridSkeleton extends StatelessWidget {
  const _HashtagGridSkeleton();

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: GridView.builder(
        padding: EdgeInsets.zero,
        itemCount: 12,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 2,
          crossAxisSpacing: 2,
        ),
        itemBuilder: (_, __) => const SkeletonBox(
          height: double.infinity,
          width: double.infinity,
          radius: 0,
        ),
      ),
    );
  }
}
