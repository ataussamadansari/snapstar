import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:snapstar_app/app/global_widgets/loading_skeleton.dart';
import 'package:snapstar_app/app/modules/profile_view/views/widgets/post_grid_item.dart';
import 'package:snapstar_app/app/routes/app_routes.dart';

import '../../../data/models/post_model.dart';
import '../../post_view/views/post_detail_screen.dart';
import '../../subscribe_list_view/controllers/subscriber_list_controller.dart';
import '../controllers/profile_controller.dart';

class ProfileScreen extends GetView<ProfileController> {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Obx(
          () => Text(
            controller.userProfile.value?.username ?? 'Profile',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => _confirmLogout(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: controller.refreshProfileData,
        notificationPredicate: (_) => true,
        child: Obx(() {
          if (controller.isLoading.value) {
            return const AnimatedSwitcher(
              duration: Duration(milliseconds: 250),
              child: ProfileHeaderSkeleton(),
            );
          }

          final user = controller.userProfile.value;
          if (user == null) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 160),
                Center(child: Text('Profile not found')),
              ],
            );
          }

          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: DefaultTabController(
              key: ValueKey(user.id),
              length: 3,
              child: NestedScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                headerSliverBuilder: (context, innerBoxIsScrolled) => [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest
                              .withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 40,
                                  backgroundColor: Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHighest,
                                  backgroundImage:
                                      (user.avatarUrl != null &&
                                              user.avatarUrl!.isNotEmpty)
                                          ? NetworkImage(user.avatarUrl!)
                                          : null,
                                  child: (user.avatarUrl == null ||
                                          user.avatarUrl!.isEmpty)
                                      ? Icon(
                                          Icons.person,
                                          size: 50,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withValues(alpha: 0.6),
                                        )
                                      : null,
                                ),
                                Expanded(
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      _buildStatColumn(
                                        'Posts',
                                        controller.postsCount.value,
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          Get.toNamed(
                                            Routes.subscriberList,
                                            arguments: SubscriberListArgs(
                                              type: SubscriberListType.subscribers,
                                              userId: user.id,
                                            ),
                                          );
                                        },
                                        child: _buildStatColumn(
                                          'Subscriber',
                                          controller.subscriberCount.value,
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          Get.toNamed(
                                            Routes.subscriberList,
                                            arguments: SubscriberListArgs(
                                              type: SubscriberListType.subscribing,
                                              userId: user.id,
                                            ),
                                          );
                                        },
                                        child: _buildStatColumn(
                                          'Subscribing',
                                          controller.subscribingCount.value,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              user.name,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            if (user.bio != null) Text(user.bio!),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: () {
                                  Get.toNamed(Routes.editProfile);
                                },
                                child: const Text('Edit Profile'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SliverPersistentHeader(
                    pinned: true,
                    floating: true,
                    delegate: _SliverAppBarDelegate(
                      TabBar(
                        controller: controller.tabController,
                        unselectedLabelColor: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.55),
                        tabs: const [
                          Tab(text: 'All'),
                          Tab(text: 'Images'),
                          Tab(text: 'Videos'),
                        ],
                      ),
                    ),
                  ),
                ],
                body: TabBarView(
                  controller: controller.tabController,
                  children: [
                    _buildPostGrid(controller.allPosts),
                    _buildPostGrid(controller.imagePosts),
                    _buildPostGrid(controller.videoPosts),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStatColumn(String label, int count) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: Column(
        key: ValueKey('$label-$count'),
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            count.toString(),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(label, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildPostGrid(List<PostModel> posts) {
    return Obx(() {
      if (controller.isPostLoading.value) {
        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 12),
            GridSkeleton(),
          ],
        );
      }

      if (posts.isEmpty) {
        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 140),
            Center(child: Text('No Posts Yet')),
          ],
        );
      }

      return GridView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
        ),
        itemCount: posts.length,
        itemBuilder: (context, index) {
          final post = posts[index];

          return PostGridItem(
            post: post,
            onTap: () {

              Get.to(
                () => PostDetailScreen(
                  posts: posts,
                  initialIndex: index,
                ),
              );
            },
          );
        },
      );
    });
  }

  void _confirmLogout(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              controller.logout();
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Theme.of(context).appBarTheme.backgroundColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}

