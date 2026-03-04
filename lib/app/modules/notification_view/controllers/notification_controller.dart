import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/utils/date_time_extension.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/notification_repository.dart';
import '../../../data/repositories/post_repository.dart';
import '../../../data/services/local_cache_service.dart';
import '../../../routes/app_routes.dart';
import '../../post_view/views/post_detail_screen.dart';

class NotificationController extends GetxController {
  NotificationController(
    this._notificationRepository,
    this._authRepository,
    this._cacheService,
    this._postRepository,
  );

  final NotificationRepository _notificationRepository;
  final AuthRepository _authRepository;
  final LocalCacheService _cacheService;
  final PostRepository _postRepository;

  final RxList<Map<String, dynamic>> notifications = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isLoadingMore = false.obs;
  final RxBool hasMore = true.obs;
  final RxnString errorMessage = RxnString();

  static const int _pageSize = 20;
  DateTime? _cursorCreatedAt;
  String? _cursorId;
  VoidCallback? _unsubscribeRealtime;

  @override
  void onInit() {
    super.onInit();
    _subscribeRealtime();
    _hydrateFromCache();
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
      _cursorCreatedAt = null;
      _cursorId = null;
      hasMore.value = true;
    }

    if (!hasMore.value || isLoading.value || isLoadingMore.value) {
      return;
    }

    final isFirstPage = _cursorCreatedAt == null || _cursorId == null;
    if (isFirstPage) {
      isLoading.value = true;
    } else {
      isLoadingMore.value = true;
    }

    try {
      errorMessage.value = null;
      final page = await _notificationRepository.fetchNotificationsByCursor(
        userId: userId,
        limit: _pageSize,
        cursorCreatedAt: _cursorCreatedAt,
        cursorId: _cursorId,
      );
      final fetched = page.items;

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

      hasMore.value = page.hasMore;
      _cursorCreatedAt = page.nextCursorCreatedAt;
      _cursorId = page.nextCursorId;
      _persistCache();
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

  Future<void> _hydrateFromCache() async {
    final userId = _authRepository.currentUserId;
    if (userId == null) {
      return;
    }

    final payload = await _cacheService.getJson('notifications_$userId');
    final items = payload?['items'];
    if (items is! List || items.isEmpty) {
      return;
    }

    final restored = items
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
    if (restored.isNotEmpty && notifications.isEmpty) {
      notifications.assignAll(restored);
    }
  }

  Future<void> _persistCache() async {
    final userId = _authRepository.currentUserId;
    if (userId == null || notifications.isEmpty) {
      return;
    }

    await _cacheService.putJson(
      'notifications_$userId',
      <String, dynamic>{'items': notifications.take(60).toList()},
      ttl: const Duration(minutes: 2),
    );
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

  Future<void> handleNotificationTap(Map<String, dynamic> notification) async {
    await markAsRead(notification);
    await _navigateFromNotification(notification);
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

  Future<void> _navigateFromNotification(Map<String, dynamic> item) async {
    final route = item['route']?.toString();
    if (route != null && route.isNotEmpty && route.startsWith('/')) {
      if (Get.currentRoute != route) {
        Get.toNamed(route, arguments: item);
      }
      return;
    }

    final conversationId =
        item['conversation_id']?.toString() ?? item['chat_id']?.toString();
    if (conversationId != null && conversationId.isNotEmpty) {
      Get.toNamed(Routes.chatDetail, arguments: conversationId);
      return;
    }

    final postId = item['post_id']?.toString();
    if (postId != null && postId.isNotEmpty) {
      try {
        final post = await _postRepository.fetchPostById(postId);
        if (post != null) {
          Get.to(() => PostDetailScreen(post: post));
          return;
        }
      } catch (error, stackTrace) {
        debugPrint('NotificationController._navigateFromNotification post error: $error');
        debugPrint('NotificationController._navigateFromNotification post stack: $stackTrace');
      }
    }

    final actorId = item['actor_id']?.toString();
    final type = item['type']?.toString().toLowerCase();
    const profileTypes = <String>{
      'subscribe',
      'unsubscribe',
      'follow',
      'follower',
    };
    if (actorId != null && actorId.isNotEmpty && profileTypes.contains(type)) {
      Get.toNamed(Routes.userProfile, arguments: actorId);
      return;
    }
  }

  @override
  void onClose() {
    _unsubscribeRealtime?.call();
    _unsubscribeRealtime = null;
    super.onClose();
  }
}
