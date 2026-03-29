import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/auth_controller.dart';
import '../../../routes/app_routes.dart';

class LoginScreen extends GetView<AuthController> {
  const LoginScreen({super.key});

  Future<void> _continueWithGoogle() async {
    await controller.loginWithGoogle();
    if (controller.isLoggedIn.value && !controller.isAnonymous.value) {
      Get.offAllNamed(Routes.main);
    }
  }

  Future<void> _continueAsGuest() async {
    await controller.loginAnonymously();
    if (controller.isLoggedIn.value) {
      Get.offAllNamed(Routes.main);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),
                  const Center(
                    child: Hero(
                      tag: 'app_logo',
                      child: Image(
                        image: AssetImage('assets/images/app_logo.png'),
                        height: 112,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Welcome to SnapStar',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Continue with Google for full access, or enter as a guest to browse, like posts, view stories, and explore the app.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
                    ),
                  ),
                  const SizedBox(height: 40),
                  Obx(
                    () => ElevatedButton.icon(
                      onPressed: controller.isLoading.value
                          ? null
                          : _continueWithGoogle,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: controller.isLoading.value
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.login),
                      label: const Text('Continue with Google'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Obx(
                    () => OutlinedButton(
                      onPressed: controller.isLoading.value
                          ? null
                          : _continueAsGuest,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text('Continue as Guest'),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'Guest mode can view posts, like posts, view stories, and open chat. Google login unlocks posting, commenting, following, editing your profile, and sending messages.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Obx(() {
                    final message = controller.authError.value;
                    if (message == null || message.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        message,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
