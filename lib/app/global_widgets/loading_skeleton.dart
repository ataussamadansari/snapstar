import 'package:flutter/material.dart';

class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    this.width,
    this.height = 12,
    this.radius = 8,
    this.margin,
  });

  final double? width;
  final double height;
  final double radius;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).brightness == Brightness.dark
        ? Colors.grey.shade800
        : Colors.grey.shade300;

    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: base,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class HomeFeedSkeleton extends StatelessWidget {
  const HomeFeedSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SkeletonBox(width: 120, height: 24),
        ),
        SizedBox(
          height: 98,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemBuilder: (_, __) => const Column(
              children: [
                SkeletonBox(width: 64, height: 64, radius: 32),
                SizedBox(height: 8),
                SkeletonBox(width: 56, height: 10),
              ],
            ),
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemCount: 6,
          ),
        ),
        const SizedBox(height: 10),
        ...List.generate(
          3,
          (_) => const Padding(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Column(
              children: [
                Row(
                  children: [
                    SkeletonBox(width: 40, height: 40, radius: 20),
                    SizedBox(width: 10),
                    Expanded(child: SkeletonBox(height: 12)),
                  ],
                ),
                SizedBox(height: 10),
                SkeletonBox(height: 260, radius: 14),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class ProfileHeaderSkeleton extends StatelessWidget {
  const ProfileHeaderSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: const [
        Row(
          children: [
            SkeletonBox(width: 80, height: 80, radius: 40),
            SizedBox(width: 14),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  SkeletonBox(width: 46, height: 36),
                  SkeletonBox(width: 46, height: 36),
                  SkeletonBox(width: 46, height: 36),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        SkeletonBox(width: 120, height: 12),
        SizedBox(height: 8),
        SkeletonBox(width: double.infinity, height: 12),
        SizedBox(height: 16),
        SkeletonBox(width: double.infinity, height: 40),
        SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            SkeletonBox(width: 70, height: 26),
            SkeletonBox(width: 70, height: 26),
            SkeletonBox(width: 70, height: 26),
          ],
        ),
      ],
    );
  }
}

class GridSkeleton extends StatelessWidget {
  const GridSkeleton({
    super.key,
    this.itemCount = 9,
  });

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: EdgeInsets.zero,
      itemCount: itemCount,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemBuilder: (_, __) => const SkeletonBox(height: double.infinity, radius: 0),
    );
  }
}

class UserListSkeleton extends StatelessWidget {
  const UserListSkeleton({
    super.key,
    this.itemCount = 8,
  });

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: itemCount,
      separatorBuilder: (_, __) => const SizedBox.shrink(),
      itemBuilder: (_, __) => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            SkeletonBox(width: 44, height: 44, radius: 22),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(width: 140, height: 12),
                  SizedBox(height: 6),
                  SkeletonBox(width: 100, height: 10),
                ],
              ),
            ),
            SizedBox(width: 8),
            SkeletonBox(width: 90, height: 32),
          ],
        ),
      ),
    );
  }
}

class SearchSkeleton extends StatelessWidget {
  const SearchSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: const [
        Padding(
          padding: EdgeInsets.fromLTRB(16, 10, 16, 8),
          child: SkeletonBox(width: 110, height: 12),
        ),
        SizedBox(
          height: 520,
          child: UserListSkeleton(itemCount: 7),
        ),
      ],
    );
  }
}

class ReelsSkeleton extends StatelessWidget {
  const ReelsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: const [
        SkeletonBox(height: double.infinity, radius: 0),
        SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(12, 10, 12, 16),
            child: Column(
              children: [
                Row(
                  children: [
                    SkeletonBox(width: 90, height: 24),
                    Spacer(),
                    SkeletonBox(width: 26, height: 26, radius: 13),
                    SizedBox(width: 10),
                    SkeletonBox(width: 26, height: 26, radius: 13),
                  ],
                ),
                Spacer(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class CommentListSkeleton extends StatelessWidget {
  const CommentListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      itemCount: 6,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, __) => const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonBox(width: 36, height: 36, radius: 18),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(width: 120, height: 12),
                SizedBox(height: 6),
                SkeletonBox(width: double.infinity, height: 10),
                SizedBox(height: 4),
                SkeletonBox(width: 180, height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
