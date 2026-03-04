import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../routes/app_routes.dart';
import '../controllers/settings_controller.dart';

class SettingsScreen extends GetView<SettingsController> {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy Policy'),
            onTap: () => Get.toNamed(Routes.settingsPrivacyPolicy),
          ),
          ListTile(
            leading: const Icon(Icons.notifications_none_rounded),
            title: const Text('Notification Settings'),
            onTap: () => Get.toNamed(Routes.settingsNotifications),
          ),
          ListTile(
            leading: const Icon(Icons.help_outline_rounded),
            title: const Text('Help and Feedback'),
            onTap: () => Get.toNamed(Routes.settingsHelpFeedback),
          ),
          ListTile(
            leading: const Icon(Icons.system_update_alt_rounded),
            title: const Text('App Update'),
            onTap: () => Get.toNamed(Routes.settingsAppUpdate),
          ),
          ListTile(
            leading: const Icon(Icons.accessibility_new_rounded),
            title: const Text('Accessibility'),
            onTap: () => Get.toNamed(Routes.settingsAccessibility),
          ),
          ListTile(
            leading: const Icon(Icons.tune_rounded),
            title: const Text('Post & Story Style'),
            subtitle: const Text('Size, colors, corner radius'),
            onTap: () => Get.toNamed(Routes.settingsContentStyle),
          ),
          const Divider(height: 24),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text(
              'Logout',
              style: TextStyle(color: Colors.redAccent),
            ),
            onTap: () => _confirmLogout(context),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await controller.logout();
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
