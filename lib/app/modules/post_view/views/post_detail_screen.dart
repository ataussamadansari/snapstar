import 'package:flutter/material.dart';

import '../../../data/models/post_model.dart';
import '../../../global_widgets/post_card.dart';

class PostDetailScreen extends StatelessWidget {
  const PostDetailScreen({
    super.key,
    required this.post,
  });

  final PostModel post;

  @override
  Widget build(BuildContext context) {
    final username = post.user?.username;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(username != null && username.isNotEmpty ? '@$username' : 'Post'),
      ),
      body: SafeArea(
        child: ListView(
          children: [
            PostCard(post: post),
          ],
        ),
      ),
    );
  }
}
