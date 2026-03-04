import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/settings_controller.dart';

class AccessibilitySettingsScreen extends GetView<SettingsController> {
  const AccessibilitySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Accessibility')),
      body: Obx(
        () => ListView(
          children: [
            SwitchListTile(
              title: const Text('High contrast mode'),
              subtitle: const Text('Increase contrast for readability'),
              value: controller.highContrast.value,
              onChanged: controller.toggleHighContrast,
            ),
            SwitchListTile(
              title: const Text('Larger text'),
              subtitle: const Text('Use bigger text where possible'),
              value: controller.largerText.value,
              onChanged: controller.toggleLargerText,
            ),
          ],
        ),
      ),
    );
  }
}
