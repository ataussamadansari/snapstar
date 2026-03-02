import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:snapstar_app/app/core/utils/reels_navigation_helper.dart';
import 'package:snapstar_app/app/global_widgets/loading_skeleton.dart';
import 'package:snapstar_app/app/modules/profile_view/views/widgets/post_grid_item.dart';
import 'package:snapstar_app/app/routes/app_routes.dart';
import '../../../data/models/post_model.dart';
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
            controller.userProfile.value?.username ?? "Profile",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: controller.logout,
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const ProfileHeaderSkeleton();
        }

        final user = controller.userProfile.value;
        if (user == null) return const Center(child: Text("Profile not found"));

        return DefaultTabController(
          length: 3,
          child: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            // 1. Background color ko light grey ya primary color ka light shade rakhein
                            backgroundColor: Colors.grey[200],

                            // 2. BackgroundImage sirf tab lagayein jab photoUrl ho
                            backgroundImage:
                                (user.avatarUrl != null &&
                                    user.avatarUrl!.isNotEmpty)
                                ? NetworkImage(user.avatarUrl!)
                                : null,

                            // 3. Agar photoUrl nahi hai, toh child mein Icon dikhayein jiska color change ho sake
                            child:
                                (user.avatarUrl == null ||
                                    user.avatarUrl!.isEmpty)
                                ? Icon(
                                    Icons.person,
                                    size: 50,
                                    color: Colors
                                        .grey[500], // Black ki jagah grey use karein light theme ke liye
                                  )
                                : null,
                          ),
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildStatColumn(
                                  "Posts",
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
                                    "Subscriber",
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
                                    "Subscribing",
                                    controller.subscribingCount.value,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Bio Section
                      Text(
                        user.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (user.bio != null) Text(user.bio!),
                      const SizedBox(height: 16),
                      // Edit Profile Button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            Get.toNamed(Routes.editProfile);
                          },
                          child: const Text("Edit Profile"),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Tabs Section
              SliverPersistentHeader(
                pinned: true,
                floating: true,
                delegate: _SliverAppBarDelegate(
                  TabBar(
                    controller: controller.tabController,
                    unselectedLabelColor: Colors.grey,
                    tabs: const [
                      Tab(text: "All"),
                      Tab(text: "Images"),
                      Tab(text: "Videos"),
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

  // Helper for Stats
  Widget _buildStatColumn(String label, int count) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
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
            onTap: () => ReelsNavigationHelper.openFromPost(
              post,
              scopedPosts: controller.videoPosts.toList(),
              scopedUserId: post.userId,
            ),
          );
        },
      );
    });
  }
}

// Custom Delegate for Sticky TabBar
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
