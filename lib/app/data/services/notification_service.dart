import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/utils/cursor_page.dart';
import '../providers/notification_provider.dart';

class NotificationService {
  NotificationService(
    this._provider,
    this._client,
  );

  final NotificationProvider _provider;
  final SupabaseClient _client;

  final Map<String, Set<VoidCallback>> _userListeners =
      <String, Set<VoidCallback>>{};
  final Map<String, RealtimeChannel> _userChannels = <String, RealtimeChannel>{};

  Future<void> createNotification(Map<String, dynamic> data) async {
    try {
      await _provider.createNotification(data);
    } catch (error, stackTrace) {
      debugPrint('NotificationService.createNotification error: $error');
      debugPrint('NotificationService.createNotification stack: $stackTrace');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> fetchNotifications({
    required String userId,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      return await _provider.fetchNotifications(
        userId: userId,
        limit: limit,
        offset: offset,
      );
    } catch (error, stackTrace) {
      debugPrint('NotificationService.fetchNotifications error: $error');
      debugPrint('NotificationService.fetchNotifications stack: $stackTrace');
      rethrow;
    }
  }

  Future<CursorPage<Map<String, dynamic>>> fetchNotificationsByCursor({
    required String userId,
    int limit = 20,
    DateTime? cursorCreatedAt,
    String? cursorId,
  }) async {
    try {
      return await _provider.fetchNotificationsByCursor(
        userId: userId,
        limit: limit,
        cursorCreatedAt: cursorCreatedAt,
        cursorId: cursorId,
      );
    } catch (error, stackTrace) {
      debugPrint('NotificationService.fetchNotificationsByCursor error: $error');
      debugPrint('NotificationService.fetchNotificationsByCursor stack: $stackTrace');
      rethrow;
    }
  }

  Future<void> markAsRead({required String notificationId}) async {
    try {
      await _provider.markAsRead(notificationId: notificationId);
    } catch (error, stackTrace) {
      debugPrint('NotificationService.markAsRead error: $error');
      debugPrint('NotificationService.markAsRead stack: $stackTrace');
      rethrow;
    }
  }

  Future<int> fetchUnreadCount({required String userId}) async {
    try {
      return await _provider.fetchUnreadCount(userId: userId);
    } catch (error, stackTrace) {
      debugPrint('NotificationService.fetchUnreadCount error: $error');
      debugPrint('NotificationService.fetchUnreadCount stack: $stackTrace');
      rethrow;
    }
  }

  VoidCallback subscribeToUserNotifications({
    required String userId,
    required VoidCallback onChanged,
  }) {
    _userListeners.putIfAbsent(userId, () => <VoidCallback>{});
    _userListeners[userId]!.add(onChanged);

    _ensureChannelForUser(userId);

    return () {
      final listeners = _userListeners[userId];
      if (listeners == null) {
        return;
      }

      listeners.remove(onChanged);
      if (listeners.isEmpty) {
        _userListeners.remove(userId);
      }

      _disposeChannelIfIdle(userId);
    };
  }

  void _ensureChannelForUser(String userId) {
    if (_userChannels.containsKey(userId)) {
      return;
    }

    final channel = _client.channel('notifications-realtime-$userId');
    _userChannels[userId] = channel;

    channel
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'notifications',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'user_id',
          value: userId,
        ),
        callback: (payload) => _handleRealtime(userId, payload),
      )
      ..subscribe();
  }

  void _handleRealtime(String userId, PostgresChangePayload payload) {
    final listeners = _userListeners[userId];
    if (listeners == null || listeners.isEmpty) {
      return;
    }

    final isDeleteForUser = payload.eventType == PostgresChangeEvent.delete &&
        payload.oldRecord['user_id']?.toString() == userId;
    final isUpsertForUser = payload.newRecord['user_id']?.toString() == userId;
    if (!isDeleteForUser && !isUpsertForUser) {
      return;
    }

    for (final listener in listeners.toList()) {
      listener();
    }
  }

  void _disposeChannelIfIdle(String userId) {
    final listeners = _userListeners[userId];
    if (listeners != null && listeners.isNotEmpty) {
      return;
    }

    final channel = _userChannels.remove(userId);
    if (channel == null) {
      return;
    }

    _client.removeChannel(channel);
  }
}
