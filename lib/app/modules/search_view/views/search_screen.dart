import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/utils/reels_navigation_helper.dart';
import '../../../data/models/post_model.dart';
import '../../post_view/views/post_detail_screen.dart';
import '../../../data/models/user_model.dart';
import '../../../global_widgets/loading_skeleton.dart';
import '../../../global_widgets/subscribe_button.dart';
import '../../../routes/app_routes.dart';
import '../controllers/search_controller.dart';

class SearchScreen extends GetView<SearchsController> {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Obx(
                () => TextField(
                  controller: controller.queryCtrl,
                  onChanged: controller.onQueryChanged,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Search users and posts',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: controller.hasQuery
                        ? IconButton(
                            onPressed: controller.clearQuery,
                            icon: const Icon(Icons.close),
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(child: Obx(() => _buildBody())),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (controller.hasQuery && controller.isSearching.value) {
      return const SearchSkeleton();
    }

    final error = controller.errorMessage.value;
    if (error != null) {
      return _StateMessage(
        icon: Icons.error_outline,
        title: error,
        buttonLabel: 'Retry',
        onPressed: controller.refreshCurrent,
      );
    }

    if (controller.hasQuery) {
      if (controller.userResults.isEmpty && controller.postResults.isEmpty) {
        return const _StateMessage(
          icon: Icons.search_off,
          title: 'No users or posts found',
          subtitle: 'Try a different keyword',
        );
      }

      return RefreshIndicator(
        onRefresh: controller.refreshCurrent,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            if (controller.userResults.isNotEmpty) ...[
              const _SectionTitle(title: 'Users'),
              ...controller.userResults.map(
                (user) => _UserListItem(user: user),
              ),
            ],
            if (controller.postResults.isNotEmpty) ...[
              const _SectionTitle(title: 'Posts'),
              ...controller.postResults.map(
                (post) => _PostListItem(post: post),
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      );
    }

    if (controller.isLoadingSuggestions.value) {
      return const SearchSkeleton();
    }

    if (controller.suggestedUsers.isEmpty &&
        controller.suggestedPosts.isEmpty) {
      return const _StateMessage(
        icon: Icons.group_outlined,
        title: 'No suggestions available',
      );
    }

    final suggestedUsers = controller.suggestedUsers.take(8).toList();

    return RefreshIndicator(
      onRefresh: controller.refreshCurrent,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          if (suggestedUsers.isNotEmpty)
            const SliverToBoxAdapter(
              child: _SectionTitle(title: 'Suggested people'),
            ),
          if (suggestedUsers.isNotEmpty)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _UserListItem(user: suggestedUsers[index]),
                childCount: suggestedUsers.length,
              ),
            ),
          if (controller.suggestedPosts.isNotEmpty)
            const SliverToBoxAdapter(
              child: _SectionTitle(title: 'Suggested posts'),
            ),
          if (controller.suggestedPosts.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.only(bottom: 16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 2,
                  mainAxisSpacing: 2,
                  childAspectRatio: 1,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _SuggestedPostTile(
                    post: controller.suggestedPosts[index],
                  ),
                  childCount: controller.suggestedPosts.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
      ),
    );
  }
}

class _UserListItem extends StatelessWidget {
  const _UserListItem({required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    final avatarUrl = user.avatarUrl;
    final hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;
    final displayName = user.name.trim().isEmpty ? user.username : user.name;

    return InkWell(
      onTap: () => Get.toNamed(Routes.userProfile, arguments: user.id),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: Colors.grey.shade200,
              backgroundImage: hasAvatar ? NetworkImage(avatarUrl) : null,
              child: hasAvatar
                  ? null
                  : Icon(Icons.person, color: Colors.grey.shade600),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '@${user.username}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            SubscriberButton(userId: user.id),
          ],
        ),
      ),
    );
  }
}

class _PostListItem extends StatelessWidget {
  const _PostListItem({required this.post});

  final PostModel post;

  @override
  Widget build(BuildContext context) {
    final hasThumb = post.thumbnailUrls.isNotEmpty;
    final hasMedia = post.mediaUrls.isNotEmpty;

    final previewUrl = hasThumb
        ? post.thumbnailUrls.first
        : (hasMedia ? post.mediaUrls.first : null);

    final caption = post.caption.trim();
    final subtitle = caption.isEmpty
        ? '@${post.user?.username ?? 'user'}'
        : caption;

    return InkWell(
      onTap: () {
        final ctrl = Get.find<SearchsController>();
        final feed = ctrl.suggestedPosts.toList();
        final idx = feed.indexWhere((p) => p.id == post.id);
        Get.to(
          () => PostDetailScreen(posts: feed, initialIndex: idx < 0 ? 0 : idx),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 64,
                height: 64,
                color: Colors.grey.shade200,
                child: previewUrl == null
                    ? Icon(
                        post.mediaType == MediaType.video
                            ? Icons.play_circle_outline
                            : Icons.image_outlined,
                        color: Colors.grey.shade600,
                      )
                    : Image.network(previewUrl, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '@${post.user?.username ?? 'user'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
            Icon(
              post.mediaType == MediaType.video
                  ? Icons.play_circle_fill_rounded
                  : Icons.photo,
              color: Colors.grey.shade600,
            ),
          ],
        ),
      ),
    );
  }
}

class _SuggestedPostTile extends StatelessWidget {
  const _SuggestedPostTile({required this.post});

  final PostModel post;

  @override
  Widget build(BuildContext context) {
    final isVideo = post.mediaType == MediaType.video;
    final thumbnail = post.thumbnailUrls.isNotEmpty
        ? post.thumbnailUrls.first
        : null;
    final media = post.mediaUrls.isNotEmpty ? post.mediaUrls.first : null;
    final previewUrl = isVideo ? (thumbnail ?? media) : (media ?? thumbnail);

    return InkWell(
      onTap: () {
        final ctrl = Get.find<SearchsController>();
        final feed = ctrl.suggestedPosts.toList();
        final idx = feed.indexWhere((p) => p.id == post.id);
        Get.to(
          () => PostDetailScreen(posts: feed, initialIndex: idx < 0 ? 0 : idx),
        );
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(color: Colors.grey.shade200),
          if (previewUrl != null)
            Image.network(
              previewUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Icon(
                isVideo ? Icons.play_circle_outline : Icons.image_outlined,
                color: Colors.grey.shade600,
              ),
            )
          else
            Icon(
              isVideo ? Icons.play_circle_outline : Icons.image_outlined,
              color: Colors.grey.shade600,
            ),
          if (isVideo)
            const Positioned(
              top: 6,
              right: 6,
              child: Icon(
                Icons.play_circle_fill_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
        ],
      ),
    );
  }
}

class _StateMessage extends StatelessWidget {
  const _StateMessage({
    required this.icon,
    required this.title,
    this.subtitle,
    this.buttonLabel,
    this.onPressed,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? buttonLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 32, color: Colors.grey.shade500),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
            if (buttonLabel != null && onPressed != null) ...[
              const SizedBox(height: 12),
              OutlinedButton(onPressed: onPressed, child: Text(buttonLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
