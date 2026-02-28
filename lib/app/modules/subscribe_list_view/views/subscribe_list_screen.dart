import 'package:flutter/material.dart';
import 'package:get/get.dart';

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

        if (controller.users.isEmpty) {
          return const Center(child: Text('No users'));
        }

        return ListView.separated(
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
                          CircleAvatar(
                            radius: 22,
                            backgroundImage: user.avatarUrl != null
                                ? NetworkImage(user.avatarUrl!)
                                : null,
                            child: user.avatarUrl == null
                                ? const Icon(Icons.person)
                                : null,
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
                                      color: Colors.grey.shade600,
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
        );
      }),
    );
  }
}


