import 'package:flutter/material.dart';
import 'package:snapstar_app/app/global_widgets/loading_skeleton.dart';

class ChatListShimmer extends StatelessWidget {
  const ChatListShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: ListView.builder(
        itemCount: 10,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemBuilder: (context, index) => const _ChatListItemShimmer(),
      ),
    );
  }
}

class _ChatListItemShimmer extends StatelessWidget {
  const _ChatListItemShimmer();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const SkeletonBox(width: 56, height: 56, radius: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                SkeletonBox(width: double.infinity, height: 16),
                SizedBox(height: 8),
                SkeletonBox(width: 200, height: 14),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const SkeletonBox(width: 40, height: 12),
        ],
      ),
    );
  }
}
