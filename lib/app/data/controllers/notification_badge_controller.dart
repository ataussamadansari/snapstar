import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  StreamSubscription<User?>? _authSubscription;
  String? _subscribedUserId;
  Future<void>? _refreshInFlight;
  DateTime? _lastRefreshAt;

  @override
  void onInit() {
    super.onInit();
    _subscribeRealtime();
    refreshUnreadCount();
    _authSubscription = _authRepository.currentUserStream.listen((_) {
      _subscribeRealtime();
      refreshUnreadCount(force: true);
    });
  }

  Future<void> refreshUnreadCount({bool force = false}) {
    final existing = _refreshInFlight;
    if (existing != null) {
      return existing;
    }

    final lastRefreshAt = _lastRefreshAt;
    if (!force &&
        lastRefreshAt != null &&
        DateTime.now().difference(lastRefreshAt) < const Duration(minutes: 1)) {
      return Future<void>.value();
    }

    final request = _refreshUnreadCount();
    _refreshInFlight = request;
    return request.whenComplete(() {
      if (identical(_refreshInFlight, request)) {
        _refreshInFlight = null;
      }
    });
  }

  Future<void> _refreshUnreadCount() async {
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
      _lastRefreshAt = DateTime.now();
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
      _unsubscribeRealtime?.call();
      _unsubscribeRealtime = null;
      _subscribedUserId = null;
      return;
    }
    if (_subscribedUserId == userId && _unsubscribeRealtime != null) {
      return;
    }

    _unsubscribeRealtime?.call();
    _unsubscribeRealtime = _notificationRepository.subscribeToUserNotifications(
      userId: userId,
      onChanged: () => refreshUnreadCount(force: true),
    );
    _subscribedUserId = userId;
  }

  @override
  void onClose() {
    _unsubscribeRealtime?.call();
    _unsubscribeRealtime = null;
    _authSubscription?.cancel();
    _authSubscription = null;
    super.onClose();
  }
}
