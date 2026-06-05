import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:snapstar_app/app/global_widgets/loading_skeleton.dart';

import '../controllers/notification_controller.dart';

class NotificationScreen extends GetView<NotificationController> {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text('Notifications'),
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.notifications.isEmpty) {
          return const AppShimmer(
            child: UserListSkeleton(itemCount: 8),
          );
        }

        if (controller.errorMessage.value != null &&
            controller.notifications.isEmpty) {
          return _StateWidget(
            title: controller.errorMessage.value!,
            buttonText: 'Retry',
            onPressed: () => controller.fetchNotifications(refresh: true),
          );
        }

        if (controller.notifications.isEmpty) {
          return RefreshIndicator(
            onRefresh: () => controller.fetchNotifications(refresh: true),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 180),
                Center(child: Text('No notifications yet')),
              ],
            ),
          );
        }

        return NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            controller.loadMoreIfNeeded(notification);
            return false;
          },
          child: RefreshIndicator(
            onRefresh: () => controller.fetchNotifications(refresh: true),
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
              itemCount: controller.notifications.length + (controller.isLoadingMore.value ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= controller.notifications.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Center(
                      child: AppShimmer(
                        child: SkeletonBox(
                          width: 120,
                          height: 14,
                        ),
                      ),
                    ),
                  );
                }

                final item = controller.notifications[index];
                final isRead = item['is_read'] == true;

                return TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: 1),
                  duration: Duration(milliseconds: 220 + ((index % 8) * 35)),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset(0, (1 - value) * 12),
                      child: Opacity(opacity: value, child: child),
                    );
                  },
                  child: _NotificationCard(
                    isRead: isRead,
                    icon: controller.iconOf(item),
                    iconColor: controller.iconColorOf(item),
                    title: controller.titleOf(item),
                    message: controller.messageOf(item),
                    timeLabel: controller.timeAgoOf(item),
                    onTap: () => controller.handleNotificationTap(item),
                  ),
                );
              },
            ),
          ),
        );
      }),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.isRead,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.message,
    required this.timeLabel,
    required this.onTap,
  });

  final bool isRead;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String message;
  final String timeLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cardColor = isRead
        ? Theme.of(context).colorScheme.surface
        : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.45);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isRead
                    ? Theme.of(context).dividerColor.withValues(alpha: 0.2)
                    : iconColor.withValues(alpha: 0.24),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: iconColor.withValues(alpha: 0.14),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: isRead ? FontWeight.w600 : FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        message,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.82),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      timeLabel,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                    if (!isRead) ...[
                      const SizedBox(height: 6),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.blueAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StateWidget extends StatelessWidget {
  const _StateWidget({
    required this.title,
    this.buttonText,
    this.onPressed,
  });

  final String title;
  final String? buttonText;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.notifications_off_outlined, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            if (buttonText != null && onPressed != null) ...[
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: onPressed,
                child: Text(buttonText!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
