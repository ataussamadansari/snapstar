import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/notification_provider.dart';

class NotificationService {
  NotificationService(
    this._provider,
    this._client,
  );

  final NotificationProvider _provider;
  final SupabaseClient _client;

  RealtimeChannel? _channel;
  final Map<String, Set<VoidCallback>> _userListeners =
      <String, Set<VoidCallback>>{};

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

    _ensureChannel();

    return () {
      final listeners = _userListeners[userId];
      if (listeners == null) {
        return;
      }

      listeners.remove(onChanged);
      if (listeners.isEmpty) {
        _userListeners.remove(userId);
      }

      _disposeChannelIfIdle();
    };
  }

  void _ensureChannel() {
    if (_channel != null) {
      return;
    }

    _channel = _client.channel('notifications-realtime-channel');

    _channel!
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'notifications',
        callback: _handleRealtime,
      )
      ..subscribe();
  }

  void _handleRealtime(PostgresChangePayload payload) {
    final userIds = <String>{};

    final newUserId = payload.newRecord['user_id']?.toString();
    final oldUserId = payload.oldRecord['user_id']?.toString();

    if (newUserId != null && newUserId.isNotEmpty) {
      userIds.add(newUserId);
    }
    if (oldUserId != null && oldUserId.isNotEmpty) {
      userIds.add(oldUserId);
    }

    for (final userId in userIds) {
      final listeners = _userListeners[userId];
      if (listeners == null || listeners.isEmpty) {
        continue;
      }

      for (final listener in listeners.toList()) {
        listener();
      }
    }
  }

  void _disposeChannelIfIdle() {
    if (_channel == null || _userListeners.isNotEmpty) {
      return;
    }

    _client.removeChannel(_channel!);
    _channel = null;
  }
}
