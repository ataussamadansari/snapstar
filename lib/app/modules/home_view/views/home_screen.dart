import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:snapstar_app/app/routes/app_routes.dart';

import 'package:snapstar_app/app/core/utils/auth_helper.dart';
import 'package:snapstar_app/app/data/controllers/notification_badge_controller.dart';
import 'package:snapstar_app/app/data/controllers/upload_task_controller.dart';
import 'package:snapstar_app/app/global_widgets/loading_skeleton.dart';
import 'package:snapstar_app/app/global_widgets/post_card.dart';
import 'package:snapstar_app/app/global_widgets/story_card.dart';
import 'package:snapstar_app/app/global_widgets/user_suggestion_card.dart';
import '../controllers/home_controller.dart';

class HomeScreen extends GetView<HomeController> {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notificationBadgeController = Get.find<NotificationBadgeController>();
    final uploadTaskController = Get.find<UploadTaskController>();

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: controller.refreshAll,
          child: Obx(() {
            final isInitialLoading =
                controller.isLoadingPosts.value && controller.posts.isEmpty;
            final hasPosts = controller.posts.isNotEmpty;

            if (isInitialLoading) {
              return const HomeFeedSkeleton();
            }

            return NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification.metrics.pixels >=
                    notification.metrics.maxScrollExtent - 300) {
                  controller.loadMorePosts();
                }
                return false;
              },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverAppBar(
                    floating: true,
                    snap: true,
                    elevation: 0,
                    scrolledUnderElevation: 0,
                    title: const Text(
                      'SnapStar',
                      style: TextStyle(
                        fontSize: 30,
                        fontFamily: 'cursive',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    actions: [
                      IconButton(
                        onPressed: () => Get.toNamed(Routes.chatList),
                        icon: HugeIcon(
                          icon: HugeIcons.strokeRoundedSent,
                          color: Theme.of(context).iconTheme.color ?? Colors.black,
                          size: 24,
                        ),
                      ),
                      Obx(
                        () => IconButton(
                          onPressed: () => Get.toNamed(Routes.notifications),
                          icon: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              HugeIcon(
                                icon: HugeIcons.strokeRoundedNotification03,
                                color: Theme.of(context).iconTheme.color ?? Colors.black,
                                size: 24,
                              ),
                              if (notificationBadgeController
                                      .unreadCount
                                      .value >
                                  0)
                                Positioned(
                                  top: -2,
                                  right: -6,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 5,
                                      vertical: 1,
                                    ),
                                    decoration: const BoxDecoration(
                                      color: Colors.redAccent,
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(10),
                                      ),
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 16,
                                      minHeight: 14,
                                    ),
                                    child: Text(
                                      notificationBadgeController
                                                  .unreadCount
                                                  .value >
                                              99
                                          ? '99+'
                                          : notificationBadgeController
                                                .unreadCount
                                                .value
                                                .toString(),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  SliverToBoxAdapter(child: _buildStories()),
                  SliverToBoxAdapter(
                    child: Obx(() {
                      final tasks = uploadTaskController.activeTasks
                          .where(
                            (task) =>
                                task.type == UploadTaskType.post ||
                                task.type == UploadTaskType.story,
                          )
                          .toList();
                      if (tasks.isEmpty) {
                        return const SizedBox.shrink();
                      }

                      return Padding(
                        padding: const EdgeInsets.fromLTRB(14, 6, 14, 8),
                        child: Column(
                          children: tasks.map((task) {
                            final percent = (task.progress * 100)
                                .clamp(0, 100)
                                .toInt();
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${task.label} ($percent%)',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  LinearProgressIndicator(
                                    value: task.progress.clamp(0.0, 1.0),
                                    minHeight: 5,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      );
                    }),
                  ),

                  if (!hasPosts)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: Text('No posts available')),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final postCount = controller.posts.length;
                          final showSuggestions = controller.users.isNotEmpty;
                          final suggestionIndex = postCount < 5 ? 2 : 5;

                          if (showSuggestions && index == suggestionIndex) {
                            return _buildSuggestedSection();
                          }

                          final actualPostIndex =
                              (showSuggestions && index > suggestionIndex)
                              ? index - 1
                              : index;

                          if (actualPostIndex < postCount) {
                            final post = controller.posts[actualPostIndex];
                            return PostCard(
                              key: ValueKey(post.id),
                              post: post,
                              feedPosts: controller.posts,
                            );
                          }

                          return const SizedBox.shrink();
                        },
                        childCount:
                            controller.posts.length +
                            (controller.users.isNotEmpty ? 1 : 0),
                      ),
                    ),

                  if (controller.isLoadingMorePosts.value)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 16,
                        ),
                        child: AppShimmer(
                          child: Column(
                            children: const [
                              SkeletonBox(height: 12, width: 180),
                              SizedBox(height: 10),
                              SkeletonBox(height: 8, width: 140),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          }),
        ),
      ),

      /*body: RefreshIndicator(
        onRefresh: () => controller.refreshAll(),
        child: Obx(() {
          if (controller.isLoadingPosts.value && controller.posts.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          // Total count calculate karein (Posts + Suggested Card)
          int postCount = controller.posts.length;
          bool showSuggestions = controller.users.isNotEmpty;

          // Agar suggestions dikhani hain toh list size 1 badha dein
          int totalItems = showSuggestions ? postCount + 1 : postCount;

          return ListView.builder(
            itemCount: totalItems,
            cacheExtent: 1000,
            addAutomaticKeepAlives: true,
            itemBuilder: (context, index) {
              // 🟢 SUGGESTED USERS POSITION LOGIC
              int suggestionIndex;
              if (postCount < 10) {
                suggestionIndex = 1; // 1st post ke baad (index 1 par)
              } else {
                suggestionIndex = 10; // Har 10 post ke baad (filhal ek baar dikhane ke liye)
              }

              // Agar suggestions ki bari hai
              if (showSuggestions && index == suggestionIndex) {
                return _buildSuggestedSection();
              }

              // Post ka index adjust karein agar suggestion beech mein aa gayi hai
              int actualPostIndex = (showSuggestions && index > suggestionIndex)
                  ? index - 1
                  : index;

              // Safe check taaki crash na ho
              if (actualPostIndex < controller.posts.length) {
                return PostCard(
                    post: controller.posts[actualPostIndex]
                );
              }

              return const SizedBox.shrink();
            },
          );
        }),
      ),*/
    );
  }

  Widget _buildStories() {
    return SizedBox(
      height: 110,
      child: Obx(() {
        final storyController = controller.storyController;

        final currentUserId = AuthHelper.currentUserId;

        final myStory = storyController.getMyLatestStory(currentUserId);
        final String? myStoryPreviewUrl =
            myStory?.user?.avatarUrl ?? controller.myAvatarUrl.value;

        final otherStories = storyController.getOtherUsersStories(
          currentUserId,
        );

        return ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          children: [
            /// 🔵 YOUR STORY
            StoryCard(
              name: "Your Story",
              imageUrl: myStoryPreviewUrl,
              isYourStory: true,
              hasStory: myStory != null,
              hasUnseen: false,
              onTap: () {
                if (myStory != null) {
                  Get.toNamed(Routes.storyViewer, arguments: myStory);
                }
              },
            ),

            /// 🔵 OTHER USERS
            ...otherStories.map((story) {
              final userName = story.user?.username ?? 'user';
              final avatarUrl = story.user?.avatarUrl;
              return StoryCard(
                name: userName,
                imageUrl: avatarUrl,
                hasUnseen: !story.isViewed,
                onTap: () {
                  Get.toNamed(Routes.storyViewer, arguments: story);
                },
              );
            }),
          ],
        );
      }),
    );
  }

  Widget _buildSuggestedSection() {
    final visibleUsers = controller.users.take(12).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  "Suggested for you",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
              TextButton(
                onPressed: () => Get.toNamed(Routes.searchSuggestedUsers),
                child: const Text('See all'),
              ),
            ],
          ),
        ),

        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            itemCount: visibleUsers.length,
            itemBuilder: (context, index) {
              return UserSuggestionCard(
                user: visibleUsers[index],
                onProfileTap: () => Get.toNamed(
                  Routes.userProfile,
                  arguments: visibleUsers[index].id,
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 10),
      ],
    );
  }
}


