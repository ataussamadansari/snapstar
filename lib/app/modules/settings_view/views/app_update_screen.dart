import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/settings_controller.dart';

class AppUpdateScreen extends GetView<SettingsController> {
  const AppUpdateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('App Update')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Current version: 1.0.0',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            const Text('Check for latest app update status.'),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: controller.checkForUpdates,
              icon: const Icon(Icons.system_update_alt_rounded),
              label: const Text('Check for updates'),
            ),
          ],
        ),
      ),
    );
  }
}
