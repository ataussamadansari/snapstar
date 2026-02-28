import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/notification_controller.dart';

class NotificationScreen extends GetView<NotificationController> {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.notifications.isEmpty) {
          return const Center(child: CircularProgressIndicator());
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
            child: ListView.separated(
              itemCount: controller.notifications.length + (controller.isLoadingMore.value ? 1 : 0),
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                if (index >= controller.notifications.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  );
                }

                final item = controller.notifications[index];
                final isRead = item['is_read'] == true;

                return ListTile(
                  onTap: () => controller.markAsRead(item),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 4,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: controller.iconColorOf(item).withValues(alpha: 0.14),
                    child: Icon(
                      controller.iconOf(item),
                      color: controller.iconColorOf(item),
                      size: 20,
                    ),
                  ),
                  title: Text(
                    controller.titleOf(item),
                    style: TextStyle(
                      fontWeight: isRead ? FontWeight.w500 : FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    controller.messageOf(item),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        controller.timeAgoOf(item),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
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
                );
              },
            ),
          ),
        );
      }),
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
            Icon(Icons.notifications_off_outlined, color: Colors.grey.shade500),
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
