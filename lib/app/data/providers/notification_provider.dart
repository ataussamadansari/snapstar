import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/utils/cursor_page.dart';

class NotificationProvider {
  NotificationProvider(this._client);

  final SupabaseClient _client;
  bool _isNotificationsSupported = true;
  bool _supportCheckCompleted = false;

  Future<void> createNotification(Map<String, dynamic> data) async {
    if (!await _ensureNotificationsTable()) {
      return;
    }

    try {
      await _client.from('notifications').insert(data);
    } on PostgrestException catch (error) {
      if (_isMissingNotificationsTable(error)) {
        _isNotificationsSupported = false;
        return;
      }
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> fetchNotifications({
    required String userId,
    required int limit,
    required int offset,
  }) async {
    if (!await _ensureNotificationsTable()) {
      return <Map<String, dynamic>>[];
    }

    try {
      final response = await _client
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .eq('is_deleted', false)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return List<Map<String, dynamic>>.from(response);
    } on PostgrestException catch (error) {
      if (_isMissingNotificationsTable(error)) {
        _isNotificationsSupported = false;
        return <Map<String, dynamic>>[];
      }
      rethrow;
    }
  }

  Future<CursorPage<Map<String, dynamic>>> fetchNotificationsByCursor({
    required String userId,
    required int limit,
    DateTime? cursorCreatedAt,
    String? cursorId,
  }) async {
    if (!await _ensureNotificationsTable()) {
      return const CursorPage<Map<String, dynamic>>(
        items: <Map<String, dynamic>>[],
        nextCursorCreatedAt: null,
        nextCursorId: null,
        hasMore: false,
      );
    }

    try {
      var query = _client
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .eq('is_deleted', false);

      if (cursorCreatedAt != null && cursorId != null) {
        final cursorIso = cursorCreatedAt.toUtc().toIso8601String();
        query = query.or(
          'created_at.lt.$cursorIso,and(created_at.eq.$cursorIso,id.lt.$cursorId)',
        );
      }

      final response = await query
          .order('created_at', ascending: false)
          .order('id', ascending: false)
          .limit(limit);

      final rows = List<Map<String, dynamic>>.from(response);
      DateTime? nextCreatedAt;
      String? nextId;
      if (rows.isNotEmpty) {
        final last = rows.last;
        nextCreatedAt = DateTime.tryParse(last['created_at']?.toString() ?? '');
        nextId = last['id']?.toString();
      }

      return CursorPage<Map<String, dynamic>>(
        items: rows,
        nextCursorCreatedAt: nextCreatedAt?.toUtc(),
        nextCursorId: nextId,
        hasMore: rows.length >= limit && nextCreatedAt != null && nextId != null,
      );
    } on PostgrestException catch (error) {
      if (_isMissingNotificationsTable(error)) {
        _isNotificationsSupported = false;
        return const CursorPage<Map<String, dynamic>>(
          items: <Map<String, dynamic>>[],
          nextCursorCreatedAt: null,
          nextCursorId: null,
          hasMore: false,
        );
      }
      rethrow;
    }
  }

  Future<void> markAsRead({required String notificationId}) async {
    if (!await _ensureNotificationsTable()) {
      return;
    }

    try {
      await _client.from('notifications').update({
        'is_read': true,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', notificationId);
    } on PostgrestException catch (error) {
      if (_isMissingNotificationsTable(error)) {
        _isNotificationsSupported = false;
        return;
      }
      rethrow;
    }
  }

  Future<int> fetchUnreadCount({required String userId}) async {
    if (!await _ensureNotificationsTable()) {
      return 0;
    }

    try {
      final response = await _client
          .from('notifications')
          .select('id')
          .eq('user_id', userId)
          .eq('is_read', false)
          .eq('is_deleted', false);

      return (response as List).length;
    } on PostgrestException catch (error) {
      if (_isMissingNotificationsTable(error)) {
        _isNotificationsSupported = false;
        return 0;
      }
      rethrow;
    }
  }

  Future<bool> _ensureNotificationsTable() async {
    if (_supportCheckCompleted) {
      return _isNotificationsSupported;
    }

    try {
      await _client.from('notifications').select('id').limit(1);
      _isNotificationsSupported = true;
    } on PostgrestException catch (error) {
      _isNotificationsSupported = !_isMissingNotificationsTable(error);
      if (_isNotificationsSupported) {
        rethrow;
      }
    } finally {
      _supportCheckCompleted = true;
    }

    return _isNotificationsSupported;
  }

  bool _isMissingNotificationsTable(PostgrestException error) {
    final message = error.message.toLowerCase();
    final details = (error.details?.toString() ?? '').toLowerCase();

    return error.code == 'PGRST205' ||
        error.code == '42P01' ||
        message.contains('notifications') ||
        details.contains('notifications');
  }
}
