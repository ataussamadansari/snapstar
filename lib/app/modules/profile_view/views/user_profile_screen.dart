import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:snapstar_app/app/core/utils/helpers.dart';
import '../../../data/models/post_model.dart';
import '../../../data/repositories/chat_repository.dart';
import '../../../global_widgets/loading_skeleton.dart';
import '../../../global_widgets/subscribe_button.dart';
import '../../../routes/app_routes.dart';
import '../../subscribe_list_view/controllers/subscriber_list_controller.dart';
import '../controllers/user_profile_controller.dart';
import '../../post_view/views/post_detail_screen.dart';
import 'package:snapstar_app/app/modules/profile_view/views/widgets/post_grid_item.dart';

class UserProfileScreen extends GetView<UserProfileController> {
  const UserProfileScreen({super.key});

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
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const ProfileHeaderSkeleton();
        }

        final user = controller.userProfile.value;
        if (user == null) {
          return const Center(child: Text('Profile not found'));
        }

        return DefaultTabController(
          length: 3,
          child: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.grey[200],
                            backgroundImage:
                                (user.avatarUrl != null &&
                                    user.avatarUrl!.isNotEmpty)
                                ? NetworkImage(user.avatarUrl!)
                                : null,
                            child:
                                (user.avatarUrl == null ||
                                    user.avatarUrl!.isEmpty)
                                ? Icon(
                                    Icons.person,
                                    size: 50,
                                    color: Colors.grey[500],
                                  )
                                : null,
                          ),
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
                      controller.isMyProfile
                          ? SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: () {
                                  Get.toNamed(Routes.editProfile);
                                },
                                child: const Text('Edit Profile'),
                              ),
                            )
                          : Row(
                              children: [
                                Expanded(
                                  child: SubscriberButton(
                                    userId: user.id,
                                    fullWidth: true,
                                    height: 40,
                                    borderRadius: 12,
                                    fontSize: 14,
                                    horizontalPadding:
                                        const EdgeInsets.symmetric(
                                          horizontal: 16,
                                        ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  height: 40,
                                  child: OutlinedButton(
                                    onPressed: () async {
                                      // Navigate to chat with this user
                                      try {
                                        final chatRepo =
                                            Get.find<ChatRepository>();
                                        final conversationId = await chatRepo
                                            .getOrCreateConversation(user.id);
                                        Get.toNamed(
                                          Routes.chatDetail,
                                          arguments: conversationId,
                                        );
                                      } catch (e) {
                                        AppHelpers.showSnackBar(
                                          title: 'Error',
                                          message: 'Failed to open chat',
                                          isError: true,
                                        );
                                      }
                                    },
                                    child: const Icon(
                                      Icons.chat_bubble_outline,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    ],
                  ),
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                floating: true,
                delegate: _UserProfileTabDelegate(
                  TabBar(
                    controller: controller.tabController,
                    unselectedLabelColor: Colors.grey,
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
        );
      }),
    );
  }

  Widget _buildStatColumn(String label, int count) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(label, style: const TextStyle(fontSize: 14)),
      ],
    );
  }

  // Post Grid
  Widget _buildPostGrid(List<PostModel> posts) {
    return Obx(() {
      if (controller.isPostLoading.value) {
        return const GridSkeleton();
      }

      if (posts.isEmpty) {
        return const Center(child: Text("No Posts Yet"));
      }

      return GridView.builder(
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
}

class _UserProfileTabDelegate extends SliverPersistentHeaderDelegate {
  _UserProfileTabDelegate(this._tabBar);

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
  bool shouldRebuild(_UserProfileTabDelegate oldDelegate) => false;
}

