import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:snapstar_app/app/routes/app_routes.dart';

import 'package:snapstar_app/app/core/utils/auth_helper.dart';
import 'package:snapstar_app/app/data/controllers/notification_badge_controller.dart';
import 'package:snapstar_app/app/data/models/story_model.dart';
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
                    title: const Text("SnapStar"),
                    actions: [
                      Obx(
                        () => IconButton(
                          onPressed: () => Get.toNamed(Routes.notifications),
                          icon: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              const Icon(Icons.notifications_none_rounded),
                              if (notificationBadgeController.unreadCount.value > 0)
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
                                      notificationBadgeController.unreadCount.value > 99
                                          ? '99+'
                                          : notificationBadgeController.unreadCount.value.toString(),
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
                            return PostCard(
                              post: controller.posts[actualPostIndex],
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
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(child: CircularProgressIndicator()),
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
              // ðŸŸ¢ SUGGESTED USERS POSITION LOGIC
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
        final String? myStoryPreviewUrl;
        if (myStory == null) {
          myStoryPreviewUrl = null;
        } else if (myStory.mediaTypes.isNotEmpty &&
            myStory.mediaTypes.first == StoryMediaType.image &&
            myStory.mediaUrls.isNotEmpty) {
          myStoryPreviewUrl = myStory.mediaUrls.first;
        } else {
          myStoryPreviewUrl = myStory.user?.avatarUrl;
        }

        final otherStories = storyController.getOtherUsersStories(
          currentUserId,
        );

        return ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          children: [
            /// ðŸ”µ YOUR STORY
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

            /// ðŸ”µ OTHER USERS
            ...otherStories.map((story) {
              return StoryCard(
                name: story.user!.username,
                imageUrl: story.user!.avatarUrl,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(
            "Suggested for you",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ),

        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            itemCount: controller.users.length,
            itemBuilder: (context, index) {
              return UserSuggestionCard(
                user: controller.users[index],
                onProfileTap: () => Get.toNamed(
                  Routes.userProfile,
                  arguments: controller.users[index].id,
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

