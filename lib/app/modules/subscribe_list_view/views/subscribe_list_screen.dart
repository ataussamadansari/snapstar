import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../global_widgets/app_avatar.dart';
import '../../../global_widgets/loading_skeleton.dart';
import '../../../global_widgets/subscribe_button.dart';
import '../../../routes/app_routes.dart';
import '../controllers/subscriber_list_controller.dart';

class SubscriberListScreen extends GetView<SubscriberListController> {
  const SubscriberListScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Obx(
          () => Text(
            controller.type.value == SubscriberListType.subscribers
                ? 'Subscriber'
                : 'Subscribing',
          ),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const UserListSkeleton();
        }

        return RefreshIndicator(
          onRefresh: () => controller.load(
            controller.type.value,
            userId: controller.userId,
          ),
          child: controller.users.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(height: 160),
                    Center(child: Text('No users')),
                  ],
                )
              : ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: controller.users.length,
            separatorBuilder: (_, __) => const SizedBox.shrink(),
            itemBuilder: (context, index) {
              final user = controller.users[index];

              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => Get.toNamed(
                          Routes.userProfile,
                          arguments: user.id,
                        ),
                        child: Row(
                          children: [
                            AppAvatar(
                              radius: 22,
                              avatarUrl: user.avatarUrl,
                              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                              iconColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user.username,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (user.name.isNotEmpty)
                                    Text(
                                      user.name,
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
                                        fontSize: 13,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SubscriberButton(userId: user.id),
                  ],
                ),
              );
            },
          ),
        );
      }),
    );
  }
}


