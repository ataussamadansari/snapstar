import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/utils/date_time_extension.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/notification_repository.dart';

class NotificationController extends GetxController {
  NotificationController(
    this._notificationRepository,
    this._authRepository,
  );

  final NotificationRepository _notificationRepository;
  final AuthRepository _authRepository;

  final RxList<Map<String, dynamic>> notifications = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isLoadingMore = false.obs;
  final RxBool hasMore = true.obs;
  final RxnString errorMessage = RxnString();

  static const int _pageSize = 20;
  int _offset = 0;
  VoidCallback? _unsubscribeRealtime;

  @override
  void onInit() {
    super.onInit();
    _subscribeRealtime();
    fetchNotifications(refresh: true);
  }

  Future<void> fetchNotifications({bool refresh = false}) async {
    final userId = _authRepository.currentUserId;
    if (userId == null) {
      notifications.clear();
      hasMore.value = false;
      return;
    }

    if (refresh) {
      _offset = 0;
      hasMore.value = true;
      notifications.clear();
    }

    if (!hasMore.value || isLoading.value || isLoadingMore.value) {
      return;
    }

    final isFirstPage = _offset == 0;
    if (isFirstPage) {
      isLoading.value = true;
    } else {
      isLoadingMore.value = true;
    }

    try {
      errorMessage.value = null;
      final fetched = await _notificationRepository.fetchNotifications(
        userId: userId,
        limit: _pageSize,
        offset: _offset,
      );

      if (isFirstPage) {
        notifications.assignAll(fetched);
      } else {
        final ids = notifications
            .map((item) => item['id']?.toString())
            .whereType<String>()
            .toSet();

        final unique = fetched.where((item) {
          final id = item['id']?.toString();
          return id == null || !ids.contains(id);
        });

        notifications.addAll(unique);
      }

      if (fetched.length < _pageSize) {
        hasMore.value = false;
      } else {
        _offset += fetched.length;
      }
    } catch (error, stackTrace) {
      debugPrint('NotificationController.fetchNotifications error: $error');
      debugPrint('NotificationController.fetchNotifications stack: $stackTrace');
      errorMessage.value = 'Could not load notifications';
    } finally {
      if (isFirstPage) {
        isLoading.value = false;
      } else {
        isLoadingMore.value = false;
      }
    }
  }

  Future<void> markAsRead(Map<String, dynamic> notification) async {
    final id = notification['id']?.toString();
    if (id == null || id.isEmpty || notification['is_read'] == true) {
      return;
    }

    try {
      await _notificationRepository.markAsRead(notificationId: id);

      final index = notifications.indexWhere((item) => item['id']?.toString() == id);
      if (index >= 0) {
        final updated = Map<String, dynamic>.from(notifications[index]);
        updated['is_read'] = true;
        notifications[index] = updated;
      }
    } catch (error, stackTrace) {
      debugPrint('NotificationController.markAsRead error: $error');
      debugPrint('NotificationController.markAsRead stack: $stackTrace');
    }
  }

  Future<void> loadMoreIfNeeded(ScrollNotification notification) async {
    if (!hasMore.value || isLoading.value || isLoadingMore.value) {
      return;
    }

    if (notification.metrics.pixels >= notification.metrics.maxScrollExtent - 200) {
      await fetchNotifications();
    }
  }

  String titleOf(Map<String, dynamic> item) {
    final title = item['title']?.toString().trim();
    if (title != null && title.isNotEmpty) {
      return title;
    }

    final type = item['type']?.toString().toLowerCase();
    switch (type) {
      case 'like':
        return 'New like';
      case 'comment':
        return 'New comment';
      case 'subscribe':
        return 'New follower';
      case 'unsubscribe':
        return 'Follower update';
      default:
        return 'New activity';
    }
  }

  String messageOf(Map<String, dynamic> item) {
    final candidates = [
      item['message'],
      item['body'],
      item['description'],
      item['text'],
    ];

    for (final candidate in candidates) {
      final text = candidate?.toString().trim();
      if (text != null && text.isNotEmpty) {
        return text;
      }
    }

    final type = item['type']?.toString().toLowerCase();
    switch (type) {
      case 'like':
        return 'Your post was liked';
      case 'comment':
        return 'Someone commented on your post';
      case 'subscribe':
        return 'Someone started following you';
      case 'unsubscribe':
        return 'Someone unfollowed you';
      default:
        return 'You have a new notification';
    }
  }

  String timeAgoOf(Map<String, dynamic> item) {
    final createdAtRaw = item['created_at']?.toString();
    if (createdAtRaw == null || createdAtRaw.isEmpty) {
      return '';
    }

    final createdAt = DateTime.tryParse(createdAtRaw);
    if (createdAt == null) {
      return '';
    }

    return createdAt.toLocal().timeAgo;
  }

  IconData iconOf(Map<String, dynamic> item) {
    final type = item['type']?.toString().toLowerCase();
    switch (type) {
      case 'like':
        return Icons.favorite_rounded;
      case 'comment':
        return Icons.chat_bubble_rounded;
      case 'subscribe':
        return Icons.person_add_alt_1_rounded;
      case 'unsubscribe':
        return Icons.person_remove_alt_1_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color iconColorOf(Map<String, dynamic> item) {
    final type = item['type']?.toString().toLowerCase();
    switch (type) {
      case 'like':
        return Colors.redAccent;
      case 'comment':
        return Colors.blueAccent;
      case 'subscribe':
        return Colors.green;
      case 'unsubscribe':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  void _subscribeRealtime() {
    final userId = _authRepository.currentUserId;
    if (userId == null) {
      return;
    }

    _unsubscribeRealtime = _notificationRepository.subscribeToUserNotifications(
      userId: userId,
      onChanged: () => fetchNotifications(refresh: true),
    );
  }

  @override
  void onClose() {
    _unsubscribeRealtime?.call();
    _unsubscribeRealtime = null;
    super.onClose();
  }
}
