import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';

class ShorebirdService extends GetxService {
  final _updater = ShorebirdUpdater();

  final isUpdateAvailable = false.obs;
  final isDownloading = false.obs;

  @override
  void onInit() {
    super.onInit();
    if (_updater.isAvailable) {
      _checkForUpdate();
    }
  }

  Future<void> _checkForUpdate() async {
    try {
      final status = await _updater.checkForUpdate();
      if (status == UpdateStatus.outdated) {
        isUpdateAvailable.value = true;
        await _downloadUpdate();
      } else if (status == UpdateStatus.restartRequired) {
        _showRestartDialog();
      }
    } catch (e) {
      debugPrint('Shorebird check error: $e');
    }
  }

  Future<void> _downloadUpdate() async {
    try {
      isDownloading.value = true;
      await _updater.update();
      isDownloading.value = false;
      isUpdateAvailable.value = false;
      _showRestartDialog();
    } on UpdateException catch (e) {
      isDownloading.value = false;
      debugPrint('Shorebird update error: ${e.message}');
    }
  }

  void _showRestartDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('Update Ready'),
        content: const Text(
          'A new update has been downloaded. Restart the app to apply it.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Later'),
          ),
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('OK'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }
}
