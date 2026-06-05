import 'package:flutter/material.dart';
import 'package:snapstar_app/app/global_widgets/loading_skeleton.dart';

class ChatDetailShimmer extends StatelessWidget {
  const ChatDetailShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 15,
        itemBuilder: (context, index) {
          final isMyMessage = index % 3 == 0;
          return _MessageBubbleShimmer(isMyMessage: isMyMessage);
        },
      ),
    );
  }
}

class _MessageBubbleShimmer extends StatelessWidget {
  final bool isMyMessage;

  const _MessageBubbleShimmer({required this.isMyMessage});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMyMessage ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            SkeletonBox(width: double.infinity, height: 14),
            SizedBox(height: 6),
            SkeletonBox(width: 100, height: 14),
            SizedBox(height: 8),
            SkeletonBox(width: 40, height: 10),
          ],
        ),
      ),
    );
  }
}
