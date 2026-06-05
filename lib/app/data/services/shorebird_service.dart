import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';

class ShorebirdService extends GetxService {
  final _updater = ShorebirdUpdater();

  // ─── Observable State ─────────────────────────────────────────────────────
  final isUpdateAvailable = false.obs;
  final isDownloading = false.obs;
  final isChecking = false.obs;

  // Current aur downloaded patch number
  final currentPatchNumber = Rxn<int>();
  final downloadedPatchNumber = Rxn<int>();

  // Last check ka result message
  final statusMessage = ''.obs;

  // ─── Init ─────────────────────────────────────────────────────────────────
  @override
  void onInit() {
    super.onInit();
    _loadCurrentPatchInfo();
    if (_updater.isAvailable) {
      _checkForUpdate();
    } else {
      statusMessage.value = 'Shorebird not available in this build.';
    }
  }

  // ─── Patch Info ───────────────────────────────────────────────────────────

  Future<void> _loadCurrentPatchInfo() async {
    try {
      final current = await _updater.readCurrentPatch();
      currentPatchNumber.value = current?.number;

      final next = await _updater.readNextPatch();
      downloadedPatchNumber.value = next?.number;

      // Agar downloaded patch current se alag hai — restart pending hai
      if (next != null &&
          current != null &&
          next.number != current.number) {
        statusMessage.value =
            'Patch ${next.number} downloaded. Restart karo apply karne ke liye.';
        _showRestartDialog(patchNumber: next.number);
      }
    } catch (e) {
      debugPrint('ShorebirdService._loadCurrentPatchInfo error: $e');
    }
  }

  // ─── Check for Update ─────────────────────────────────────────────────────

  Future<void> checkForUpdate() => _checkForUpdate();

  Future<void> _checkForUpdate() async {
    if (isChecking.value) return;

    try {
      isChecking.value = true;
      statusMessage.value = 'Checking for update...';

      final status = await _updater.checkForUpdate();

      switch (status) {
        case UpdateStatus.upToDate:
          isUpdateAvailable.value = false;
          statusMessage.value = 'App is up to date.';

        case UpdateStatus.outdated:
          isUpdateAvailable.value = true;
          statusMessage.value = 'New update available! Downloading...';
          await _downloadUpdate();

        case UpdateStatus.restartRequired:
          isUpdateAvailable.value = false;
          final next = await _updater.readNextPatch();
          statusMessage.value =
              'Patch ${next?.number ?? ''} ready. Restart karo apply karne ke liye.';
          _showRestartDialog(patchNumber: next?.number);

        case UpdateStatus.unavailable:
          statusMessage.value = 'Update check unavailable.';
      }
    } catch (e) {
      statusMessage.value = 'Update check failed.';
      debugPrint('ShorebirdService._checkForUpdate error: $e');
    } finally {
      isChecking.value = false;
    }
  }

  // ─── Download ─────────────────────────────────────────────────────────────

  Future<void> _downloadUpdate() async {
    try {
      isDownloading.value = true;
      statusMessage.value = 'Downloading update...';

      await _updater.update();

      isDownloading.value = false;
      isUpdateAvailable.value = false;

      final next = await _updater.readNextPatch();
      downloadedPatchNumber.value = next?.number;
      statusMessage.value =
          'Patch ${next?.number ?? ''} downloaded successfully!';

      _showRestartDialog(patchNumber: next?.number);
    } on UpdateException catch (e) {
      isDownloading.value = false;
      statusMessage.value = 'Download failed: ${e.message}';
      debugPrint('ShorebirdService._downloadUpdate error: ${e.message}');
    }
  }

  // ─── Restart Dialog ───────────────────────────────────────────────────────

  void _showRestartDialog({int? patchNumber}) {
    // Agar pehle se dialog open hai to dobara mat dikhao
    if (Get.isDialogOpen ?? false) return;

    Get.dialog(
      AlertDialog(
        title: const Text('Update Ready ✅'),
        content: Text(
          patchNumber != null
              ? 'Patch #$patchNumber download ho gaya.\nApp band karke dobara kholo — update apply ho jaayega.'
              : 'Ek naya update download ho gaya.\nApp band karke dobara kholo — update apply ho jaayega.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Baad mein'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }
}
