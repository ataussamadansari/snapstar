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

  /// keys used to scroll/measure individual list items when opening the
  /// detail screen from a feed.
  late List<GlobalKey> _itemKeys;

  List<PostModel> get _posts => widget.posts ?? [widget.post!];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _scrollController = ScrollController();

    // prepare keys for each post so we can scroll/measure later
    _itemKeys = List<GlobalKey>.generate(_posts.length, (_) => GlobalKey());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToInitial();
    });

    // install scroll listener after first frame so context is available
    _scrollController.addListener(_updateCurrentIndexByPosition);
  }

  void _scrollToInitial() {
    if (_currentIndex <= 0) return;
    final ctx = _itemKeys[_currentIndex].currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(ctx, duration: Duration.zero, alignment: 0.0);
    } else {
      // item not built yet, try again next frame
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToInitial());
    }
  }

  void _updateCurrentIndexByPosition() {
    final screenMiddle = MediaQuery.of(context).size.height / 2;
    for (var i = 0; i < _itemKeys.length; i++) {
      final ctx = _itemKeys[i].currentContext;
      if (ctx == null) continue;
      final box = ctx.findRenderObject() as RenderBox;
      final pos = box.localToGlobal(Offset.zero);
      if (pos.dy <= screenMiddle && pos.dy + box.size.height >= screenMiddle) {
        if (_currentIndex != i) {
          setState(() {
            _currentIndex = i;
          });
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
    final current = _posts[_currentIndex];
    // username not displayed now since appbar is static label

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text("Posts"),
      ),
      body: SafeArea(
        child: ListView.builder(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: _posts.length,
          itemBuilder: (context, index) {
            return Container(
              key: _itemKeys[index],
              child: PostCard(
                post: _posts[index],
                allowReelsNavigation: false,
                feedPosts: widget.posts,
              ),
            );
          },
        ),
      ),
    );
  }
}
