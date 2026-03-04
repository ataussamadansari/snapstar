import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/settings_controller.dart';

class NotificationSettingsScreen extends GetView<SettingsController> {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notification Settings')),
      body: Obx(
        () => ListView(
          children: [
            SwitchListTile(
              title: const Text('Likes'),
              subtitle: const Text('Notify when someone likes your post'),
              value: controller.pushLikes.value,
              onChanged: controller.togglePushLikes,
            ),
            SwitchListTile(
              title: const Text('Comments'),
              subtitle: const Text('Notify when someone comments'),
              value: controller.pushComments.value,
              onChanged: controller.togglePushComments,
            ),
            SwitchListTile(
              title: const Text('Messages'),
              subtitle: const Text('Notify for new chat messages'),
              value: controller.pushMessages.value,
              onChanged: controller.togglePushMessages,
            ),
          ],
        ),
      ),
    );
  }
}
