import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../presentation/controllers/auth_controller.dart';

class AuthHelper {
  static AuthController get _authController => Get.find<AuthController>();
  static String get currentUserId => _authController.currentUserId ?? '';
  static bool get isAnonymous => _authController.isAnonymous.value;
  static bool get isLoggedIn => _authController.isLoggedIn.value;

  /// Check if user is anonymous and show upgrade modal if they are.
  /// Returns true if user is NOT anonymous (authorized).
  static bool checkAuthAndShowModal({
    String message = "Login with Google to unlock full features",
  }) {
    if (!_authController.isLoggedIn.value || _authController.isAnonymous.value) {
      _showUpgradeBottomSheet(message);
      return false;
    }
    return true;
  }

  static void _showUpgradeBottomSheet(String message) {
    final theme = Get.theme;
    
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            Icon(Icons.account_circle, size: 64, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              "Account Required",
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(color: theme.hintColor),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  Get.back(); // Close bottom sheet
                  if (_authController.isAnonymous.value) {
                    await _authController.upgradeAnonymousToGoogle();
                  } else {
                    await _authController.loginWithGoogle();
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.login),
                label: const Text("Login with Google", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Get.back(),
              child: const Text("Maybe later"),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }
}
