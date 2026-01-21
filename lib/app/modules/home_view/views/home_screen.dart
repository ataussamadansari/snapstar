import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/home_controller.dart';

class HomeScreen extends GetView<HomeController> {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [

          /// 🔥 APP BAR + STORIES (TOGETHER)
          SliverAppBar(
            title: const Text("SnapStar", style: TextStyle(fontFamily: "Serif")),
            floating: true,
            snap: true,
            elevation: 0,
            scrolledUnderElevation: 0,
            // backgroundColor: Theme.of(context).scaffoldBackgroundColor,

            // 👇 total height (appbar + stories)
            expandedHeight: 170,

            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(110),
              child: SizedBox(
                height: 110,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: controller.stories.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min, // 🔥 overflow safe
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.blue,
                            child: CircleAvatar(
                              radius: 38,
                              backgroundColor: Colors.grey.shade300,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            controller.stories[index],
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          /// 🧱 POSTS (padding for bottom nav overlay)
          SliverPadding(
            padding: const EdgeInsets.only(bottom: 80),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                    (context, index) {
                  final post = controller.posts[index];
                  return _PostCard(post: post);
                },
                childCount: controller.posts.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class _PostCard extends StatelessWidget {
  final Map post;

  const _PostCard({required this.post});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// HEADER
        ListTile(
          leading: const CircleAvatar(
            backgroundColor: Colors.grey,
          ),
          title: Text(
            post['username'],
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          trailing: const Icon(Icons.more_vert),
        ),

        /// IMAGE PLACEHOLDER
        Container(
          height: 250,
          color: Colors.red.shade300,
        ),

        /// ACTIONS
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: const [
              Icon(Icons.favorite_border),
              SizedBox(width: 16),
              Icon(Icons.comment_outlined),
              SizedBox(width: 16),
              Icon(Icons.send),
            ],
          ),
        ),

        /// LIKES
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            "${post['likes']} likes",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),

        /// CAPTION
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: RichText(
            text: TextSpan(
              style: DefaultTextStyle.of(context).style,
              children: [
                TextSpan(
                  text: "${post['username']} ",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: post['caption']),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),
      ],
    );
  }
}

/*
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/home_controller.dart';

class HomeScreen extends GetView<HomeController> {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [

          /// 🔥 HIDE / SHOW APP BAR
          SliverAppBar(
            title: const Text("SnapStar"),
            floating: true,
            snap: true,
            elevation: 0,
            scrolledUnderElevation: 0,
          ),

          /// 🔵 STORIES
          SliverToBoxAdapter(
            child: SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: controller.stories.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.blue,
                          child: CircleAvatar(
                            radius: 38,
                            backgroundColor: Colors.grey.shade300,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          controller.stories[index],
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),


          /// 🧱 POSTS
          SliverList(
            delegate: SliverChildBuilderDelegate(
                  (context, index) {
                final post = controller.posts[index];
                return _PostCard(post: post);
              },
              childCount: controller.posts.length,
            ),
          ),
        ],
      ),
    );
  }
} */


