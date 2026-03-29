import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/utils/reels_navigation_helper.dart';
import '../../../data/models/post_model.dart';
import '../../post_view/views/post_detail_screen.dart';
import '../../../data/models/user_model.dart';
import '../../../global_widgets/app_avatar.dart';
import '../../../global_widgets/loading_skeleton.dart';
import '../../../global_widgets/app_cached_image.dart';
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
      if (controller.userResults.isEmpty &&
          controller.postResults.isEmpty &&
          controller.hashtagResults.isEmpty) {
        return const _StateMessage(
          icon: Icons.search_off,
          title: 'No users, posts or hashtags found',
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
            if (controller.hashtagResults.isNotEmpty) ...[
              const _SectionTitle(title: 'Hashtags'),
              ...controller.hashtagResults.map(
                (tag) => _HashtagListItem(tag: tag),
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
        controller.suggestedPosts.isEmpty &&
        controller.suggestedHashtags.isEmpty) {
      return const _StateMessage(
        icon: Icons.group_outlined,
        title: 'No suggestions available',
      );
    }

    final suggestedUsers = controller.suggestedUsers.take(8).toList();
    final suggestedHashtags = controller.suggestedHashtags.take(6).toList();

    return RefreshIndicator(
      onRefresh: controller.refreshCurrent,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          if (suggestedUsers.isNotEmpty)
            SliverToBoxAdapter(
              child: _SectionTitle(
                title: 'Suggested people',
                actionLabel: 'See all',
                onActionPressed: () =>
                    Get.toNamed(Routes.searchSuggestedUsers),
              ),
            ),
          if (suggestedUsers.isNotEmpty)
            SliverToBoxAdapter(
              child: SizedBox(
                height: 198,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: suggestedUsers.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) =>
                      _SuggestedUserCard(user: suggestedUsers[index]),
                ),
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
          if (suggestedHashtags.isNotEmpty)
            SliverToBoxAdapter(
              child: _SectionTitle(
                title: 'Trending hashtags',
                actionLabel: 'Show more',
                onActionPressed: () =>
                    Get.toNamed(Routes.searchSuggestedHashtags),
              ),
            ),
          if (suggestedHashtags.isNotEmpty)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) =>
                    _HashtagListItem(tag: suggestedHashtags[index]),
                childCount: suggestedHashtags.length,
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    this.actionLabel,
    this.onActionPressed,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onActionPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
          ),
          if (actionLabel != null && onActionPressed != null)
            TextButton(
              onPressed: onActionPressed,
              child: Text(actionLabel!),
            ),
        ],
      ),
    );
  }
}

class _SuggestedUserCard extends StatelessWidget {
  const _SuggestedUserCard({required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    final avatarUrl = user.avatarUrl;
    final displayName = user.name.trim().isEmpty ? user.username : user.name;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => Get.toNamed(Routes.userProfile, arguments: user.id),
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.15),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            AppAvatar(
              radius: 30,
              avatarUrl: avatarUrl,
              backgroundColor: Colors.grey.shade200,
              iconColor: Colors.grey.shade600,
              iconSize: 28,
            ),
            const SizedBox(height: 12),
            Text(
              displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '@${user.username}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: SubscriberButton(
                userId: user.id,
                fullWidth: true,
                height: 36,
                borderRadius: 10,
                fontSize: 13,
                horizontalPadding: const EdgeInsets.symmetric(horizontal: 10),
              ),
            ),
          ],
        ),
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
    final displayName = user.name.trim().isEmpty ? user.username : user.name;

    return InkWell(
      onTap: () => Get.toNamed(Routes.userProfile, arguments: user.id),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            AppAvatar(
              radius: 22,
              avatarUrl: avatarUrl,
              backgroundColor: Colors.grey.shade200,
              iconColor: Colors.grey.shade600,
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
        _openPostWithRelatedContext(
          selected: post,
          source: ctrl.postResults.toList(),
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
                    : AppCachedImage(imageUrl: previewUrl, fit: BoxFit.cover),
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
        _openPostWithRelatedContext(
          selected: post,
          source: ctrl.suggestedPosts.toList(),
        );
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(color: Colors.grey.shade200),
          if (previewUrl != null)
            AppCachedImage(
              imageUrl: previewUrl,
              fit: BoxFit.cover,
              errorWidget: Icon(
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

class _HashtagListItem extends StatelessWidget {
  const _HashtagListItem({required this.tag});

  final Map<String, dynamic> tag;

  @override
  Widget build(BuildContext context) {
    final value = (tag['tag']?.toString() ?? '').trim();
    final postCount = (tag['post_count'] as num?)?.toInt() ?? 0;
    final usageCount = (tag['usage_count'] as num?)?.toInt() ?? 0;
    if (value.isEmpty) {
      return const SizedBox.shrink();
    }

    return InkWell(
      onTap: () {
        final ctrl = Get.find<SearchsController>();
        ctrl.queryCtrl.text = '#$value';
        ctrl.onQueryChanged('#$value');
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.grey.shade200,
              child: Text(
                '#',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '#$value',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$postCount posts • $usageCount uses',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _openPostWithRelatedContext({
  required PostModel selected,
  required List<PostModel> source,
}) {
  final related = _buildRelatedPosts(
    selected: selected,
    source: source,
  );

  if (selected.mediaType == MediaType.video) {
    ReelsNavigationHelper.openFromPost(
      selected,
      scopedPosts: related,
      scopedUserId: selected.userId,
    );
    return;
  }

  final initialIndex = related.indexWhere((p) => p.id == selected.id);
  Get.to(
    () => PostDetailScreen(
      posts: related,
      initialIndex: initialIndex < 0 ? 0 : initialIndex,
    ),
  );
}

List<PostModel> _buildRelatedPosts({
  required PostModel selected,
  required List<PostModel> source,
}) {
  final seedTags = _extractTags(selected.caption);
  final seedWords = _extractWords(selected.caption);

  final candidates = source
      .where((p) => !p.isDeleted)
      .toList();

  final dedup = <String, PostModel>{};
  for (final p in candidates) {
    dedup[p.id] = p;
  }

  final sorted = dedup.values.toList()
    ..sort((a, b) {
      if (a.id == selected.id) return -1;
      if (b.id == selected.id) return 1;

      final sa = _relatedScore(a, selected, seedTags, seedWords);
      final sb = _relatedScore(b, selected, seedTags, seedWords);
      if (sb != sa) return sb.compareTo(sa);
      return b.createdAt.compareTo(a.createdAt);
    });

  return sorted;
}

int _relatedScore(
  PostModel item,
  PostModel seed,
  Set<String> seedTags,
  Set<String> seedWords,
) {
  var score = 0;

  if (item.userId == seed.userId) score += 40;
  if (item.mediaType == seed.mediaType) score += 20;

  final itemTags = _extractTags(item.caption);
  final itemWords = _extractWords(item.caption);

  score += itemTags.intersection(seedTags).length * 15;
  score += itemWords.intersection(seedWords).length * 4;

  return score;
}

Set<String> _extractTags(String caption) {
  final matches = RegExp(r'#([a-zA-Z0-9_]+)').allMatches(caption.toLowerCase());
  return matches.map((m) => m.group(1)!).toSet();
}

Set<String> _extractWords(String caption) {
  return caption
      .toLowerCase()
      .split(RegExp(r'[^a-z0-9_]+'))
      .where((w) => w.length >= 3 && !w.startsWith('#'))
      .toSet();
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
