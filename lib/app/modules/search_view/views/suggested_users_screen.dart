import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/user_model.dart';
import '../../../global_widgets/app_avatar.dart';
import '../../../global_widgets/loading_skeleton.dart';
import '../../../global_widgets/subscribe_button.dart';
import '../../../routes/app_routes.dart';
import '../controllers/search_controller.dart';

class SuggestedUsersScreen extends GetView<SearchsController> {
  const SuggestedUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Suggested people'),
      ),
      body: Obx(() {
        if (controller.isLoadingSuggestions.value &&
            controller.suggestedUsers.isEmpty) {
          return const SearchSkeleton();
        }

        if (controller.suggestedUsers.isEmpty) {
          return RefreshIndicator(
            onRefresh: controller.loadSuggestions,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 180),
                Center(child: Text('No suggested users')),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.loadSuggestions,
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: controller.suggestedUsers.length,
            itemBuilder: (context, index) {
              return _SuggestedUserListTile(
                user: controller.suggestedUsers[index],
              );
            },
          ),
        );
      }),
    );
  }
}

class _SuggestedUserListTile extends StatelessWidget {
  const _SuggestedUserListTile({required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    final avatarUrl = user.avatarUrl;
    final displayName = user.name.trim().isEmpty ? user.username : user.name;

    return InkWell(
      onTap: () => Get.toNamed(Routes.userProfile, arguments: user.id),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            AppAvatar(
              radius: 24,
              avatarUrl: avatarUrl,
              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              iconColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '@${user.username}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55)),
                  ),
                ],
              ),
            ),
            SubscriberButton(userId: user.id),
          ],
        ),
      ),
    );
  }
}
