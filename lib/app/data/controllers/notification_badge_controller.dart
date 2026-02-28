import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../repositories/auth_repository.dart';
import '../repositories/notification_repository.dart';

class NotificationBadgeController extends GetxController {
  NotificationBadgeController(
    this._notificationRepository,
    this._authRepository,
  );

  final NotificationRepository _notificationRepository;
  final AuthRepository _authRepository;

  final RxInt unreadCount = 0.obs;
  VoidCallback? _unsubscribeRealtime;

  @override
  void onInit() {
    super.onInit();
    _subscribeRealtime();
    refreshUnreadCount();
  }

  Future<void> refreshUnreadCount() async {
    final userId = _authRepository.currentUserId;
    if (userId == null) {
      unreadCount.value = 0;
      return;
    }

    try {
      final count = await _notificationRepository.fetchUnreadCount(
        userId: userId,
      );
      unreadCount.value = count;
    } catch (error, stackTrace) {
      debugPrint('NotificationBadgeController.refreshUnreadCount error: $error');
      debugPrint(
        'NotificationBadgeController.refreshUnreadCount stack: $stackTrace',
      );
    }
  }

  void _subscribeRealtime() {
    final userId = _authRepository.currentUserId;
    if (userId == null) {
      return;
    }

    _unsubscribeRealtime = _notificationRepository.subscribeToUserNotifications(
      userId: userId,
      onChanged: refreshUnreadCount,
    );
  }

  @override
  void onClose() {
    _unsubscribeRealtime?.call();
    _unsubscribeRealtime = null;
    super.onClose();
  }
}
