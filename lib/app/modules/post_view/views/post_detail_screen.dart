import 'package:flutter/material.dart';

import '../../../data/models/post_model.dart';
import '../../../global_widgets/post_card.dart';

class PostDetailScreen extends StatefulWidget {
  const PostDetailScreen({
    super.key,
    this.posts,
    this.initialIndex = 0,
    this.post,
  }) : assert(
         posts != null || post != null,
         'Either posts or post must be provided',
       );

  final List<PostModel>? posts;
  final int initialIndex;
  final PostModel? post;

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  late ScrollController _scrollController;
  late int _currentIndex;
  late List<PostModel> _displayPosts;
  late List<GlobalKey> _itemKeys;

  // Ek session mein ek post ka view sirf ek baar count ho

  @override
  void initState() {
    super.initState();
    _displayPosts = _buildDisplayPosts();
    _currentIndex = 0;
    _scrollController = ScrollController();

    _itemKeys = List<GlobalKey>.generate(
      _displayPosts.length,
      (_) => GlobalKey(),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToInitial();
      // Pehla post jo open hote hi dikh raha hai uska view count karo
    });

    _scrollController.addListener(_updateCurrentIndexByPosition);
  }

  List<PostModel> _buildDisplayPosts() {
    final posts = widget.posts;
    if (posts == null || posts.isEmpty) {
      return [widget.post!];
    }

    final safeIndex = widget.initialIndex.clamp(0, posts.length - 1);
    if (safeIndex == 0) {
      return posts;
    }

    return <PostModel>[...posts.skip(safeIndex), ...posts.take(safeIndex)];
  }

  void _scrollToInitial() {
    if (_currentIndex <= 0) return;
    final ctx = _itemKeys[_currentIndex].currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(ctx, duration: Duration.zero, alignment: 0.0);
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToInitial());
    }
  }

  void _updateCurrentIndexByPosition() {
    // Widget unmount ho gaya ho to crash avoid karo
    if (!mounted) return;

    final screenMiddle = MediaQuery.of(context).size.height / 2;
    for (var i = 0; i < _itemKeys.length; i++) {
      final ctx = _itemKeys[i].currentContext;
      if (ctx == null) continue;

      final renderObject = ctx.findRenderObject();
      // RenderBox attached nahi hai to skip karo — crash ka main reason
      if (renderObject is! RenderBox || !renderObject.attached) continue;

      final pos = renderObject.localToGlobal(Offset.zero);
      if (pos.dy <= screenMiddle &&
          pos.dy + renderObject.size.height >= screenMiddle) {
        if (_currentIndex != i) {
          setState(() => _currentIndex = i);
        }
        break;
      }
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_updateCurrentIndexByPosition);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text("Posts"),
      ),
      body: SafeArea(
        child: ListView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          children: List<Widget>.generate(_displayPosts.length, (index) {
            return Container(
              key: _itemKeys[index],
              child: PostCard(
                post: _displayPosts[index],
                allowReelsNavigation: false,
                feedPosts: _displayPosts,
              ),
            );
          }),
        ),
      ),
    );
  }
}
