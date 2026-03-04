import 'package:flutter/foundation.dart';

import '../../core/utils/cursor_page.dart';
import '../services/notification_service.dart';

class NotificationRepository {
  NotificationRepository(this._service);

  final NotificationService _service;

  Future<void> createNotification(Map<String, dynamic> data) {
    return _service.createNotification(data);
  }

  Future<List<Map<String, dynamic>>> fetchNotifications({
    required String userId,
    int limit = 20,
    int offset = 0,
  }) {
    return _service.fetchNotifications(
      userId: userId,
      limit: limit,
      offset: offset,
    );
  }

  Future<CursorPage<Map<String, dynamic>>> fetchNotificationsByCursor({
    required String userId,
    int limit = 20,
    DateTime? cursorCreatedAt,
    String? cursorId,
  }) {
    return _service.fetchNotificationsByCursor(
      userId: userId,
      limit: limit,
      cursorCreatedAt: cursorCreatedAt,
      cursorId: cursorId,
    );
  }

  Future<void> markAsRead({required String notificationId}) {
    return _service.markAsRead(notificationId: notificationId);
  }

  Future<int> fetchUnreadCount({required String userId}) {
    return _service.fetchUnreadCount(userId: userId);
  }

  VoidCallback subscribeToUserNotifications({
    required String userId,
    required VoidCallback onChanged,
  }) {
    return _service.subscribeToUserNotifications(
      userId: userId,
      onChanged: onChanged,
    );
  }
}
