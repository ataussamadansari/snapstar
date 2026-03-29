import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../firebase_options.dart';
import '../../routes/app_routes.dart';
import '../controllers/notification_badge_controller.dart';
import '../repositories/auth_repository.dart';
import '../repositories/post_repository.dart';
import 'push_notification_dispatcher.dart';
import '../../modules/post_view/views/post_detail_screen.dart';

const String _kDefaultNotificationChannelId = 'snapstar_notifications';
const String _kDefaultNotificationChannelName = 'Snapstar Notifications';
const String _kDefaultNotificationChannelDescription =
    'Likes, comments and follow activity updates';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (_) {}
}

class FcmService extends GetxService {
  FcmService(this._client, this._authRepository);

  final SupabaseClient _client;
  final AuthRepository _authRepository;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  final AndroidNotificationChannel _androidNotificationChannel =
      const AndroidNotificationChannel(
        _kDefaultNotificationChannelId,
        _kDefaultNotificationChannelName,
        description: _kDefaultNotificationChannelDescription,
        importance: Importance.high,
      );

  StreamSubscription<String>? _onTokenRefreshSub;
  StreamSubscription<User?>? _onAuthChangedSub;
  StreamSubscription<RemoteMessage>? _onMessageSub;
  StreamSubscription<RemoteMessage>? _onMessageOpenedSub;

  String? _lastSyncedUserId;
  String? _lastSyncedToken;

  @override
  void onInit() {
    super.onInit();
    _initialize();
  }

  Future<void> _initialize() async {
    if (kIsWeb) return;

    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }

      await _initializeLocalNotifications();
      await _requestPermissions();
      
      // Crucial for foreground notifications on iOS/Android
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // Listen for token refresh
      _onTokenRefreshSub = _messaging.onTokenRefresh.listen(_persistToken);

      // Listen for auth changes to sync tokens correctly
      _onAuthChangedSub = _authRepository.currentUserStream.listen((user) async {
        if (user != null) {
          await _syncCurrentToken();
        } else {
          // Cleanup on logout
          if (_lastSyncedToken != null) {
            await _deactivateToken(_lastSyncedToken!);
          }
          _lastSyncedUserId = null;
          _lastSyncedToken = null;
        }
      });

      // Handle foreground messages
      _onMessageSub = FirebaseMessaging.onMessage.listen((message) async {
        debugPrint('FCM: Foreground message received: ${message.messageId}');
        await _saveNotificationToDatabase(message); 
        _refreshNotificationBadge();
        await _showForegroundNotification(message);
      });

      // Handle message clicks
      _onMessageOpenedSub = FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageNavigation);

      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleMessageNavigation(initialMessage);
      }

      // Initial sync
      await _syncCurrentToken();
      
      // Requirement: Handle "All Devices" by subscribing to a topic
      await _messaging.subscribeToTopic('all_users');
      debugPrint('FCM: Subscribed to all_users topic');

    } catch (error, stackTrace) {
      debugPrint('FcmService._initialize error: $error');
      debugPrint('FcmService._initialize stack: $stackTrace');
    }
  }

  /// Helper to validate UUID
  bool _isUUID(String? s) {
    if (s == null) return false;
    return RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    ).hasMatch(s);
  }

  Future<void> _saveNotificationToDatabase(RemoteMessage message) async {
    final userId = _authRepository.currentUserId;
    if (userId == null) return;

    try {
      final data = message.data;
      final persistedNotificationId = data['notification_id']?.toString();
      if (persistedNotificationId != null && persistedNotificationId.isNotEmpty) {
        debugPrint('FCM: Notification already persisted as $persistedNotificationId');
        return;
      }
      
      String? actorId = data['actor_id']?.toString();
      if (!_isUUID(actorId)) actorId = null;
      
      String? postId = data['post_id']?.toString();
      if (!_isUUID(postId)) postId = null;

      final notificationData = {
        'user_id': userId,
        'actor_id': actorId,
        'post_id': postId,
        'title': _titleFromMessage(message) ?? 'Notification',
        'message': _bodyFromMessage(message) ?? '',
        'type': data['type'] ?? 'activity',
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
      };

      await _client.from('notifications').insert(notificationData);
      debugPrint('FCM: Notification saved to database');
    } catch (e) {
      debugPrint('FCM: Failed to save notification to DB: $e');
    }
  }

  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (response) {
        if (response.payload != null) {
          try {
            final data = jsonDecode(response.payload!);
            _handleDataNavigation(data);
          } catch (_) {
            _openNotificationsRoute();
          }
        } else {
          _openNotificationsRoute();
        }
      },
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_androidNotificationChannel);
  }

  Future<void> _requestPermissions() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<void> _syncCurrentToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await _persistToken(token);
      }
    } catch (e) {
      debugPrint('FcmService: Error getting token: $e');
    }
  }

  /// Fix for token sync using Supabase Function (RPC)
  Future<void> _persistToken(String token) async {
    final userId = _authRepository.currentUserId;
    if (userId == null || _authRepository.isAnonymous) return;

    if (_lastSyncedToken == token && _lastSyncedUserId == userId) return;

    try {
      // REQUIREMENT: Use RPC to bypass RLS issues for device tokens
      await _client.rpc('upsert_push_token', params: {
        'p_token': token,
        'p_platform': _platformName,
      });

      _lastSyncedToken = token;
      _lastSyncedUserId = userId;
      debugPrint('FCM: Token synced for user $userId via Function');
    } catch (e) {
      debugPrint('FCM: Token sync failed: $e');
    }
  }

  Future<void> _deactivateToken(String token) async {
    try {
      // Use RPC to deactivate to ensure consistent behavior
      await _client.rpc('deactivate_push_token', params: {
        'p_token': token,
      });
    } catch (e) {
      // Fallback to direct update if RPC fails
      try {
        await _client
            .from('user_push_tokens')
            .update({'is_active': false})
            .eq('token', token);
      } catch (_) {}
    }
  }

  /// New Method to send notification via Supabase Function (RPC)
  /// This method can be called from anywhere in the app to notify another user.
  Future<void> sendNotification({
    required String targetUserId,
    required String title,
    required String message,
    String type = 'general',
    Map<String, dynamic>? data,
  }) async {
    try {
      await PushNotificationDispatcher.dispatch(
        targetUserId: targetUserId,
        title: title,
        message: message,
        type: type,
        data: data,
      );
      debugPrint('FCM: Notification request sent to Firebase for user $targetUserId');
    } catch (e) {
      debugPrint('FCM: Failed to send notification via Function: $e');
    }
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final title = _titleFromMessage(message);
    final body = _bodyFromMessage(message);
    if (title == null && body == null) return;

    await _localNotifications.show(
      message.hashCode,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _androidNotificationChannel.id,
          _androidNotificationChannel.name,
          channelDescription: _androidNotificationChannel.description,
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }

  void _handleMessageNavigation(RemoteMessage message) {
    _refreshNotificationBadge();
    _handleDataNavigation(message.data);
  }

  void _handleDataNavigation(Map<String, dynamic> data) {
    if (_authRepository.currentUserId == null) return;

    final postId = data['post_id']?.toString();
    if (_isUUID(postId)) {
      _openPostFromNotification(postId!);
      return;
    }

    final conversationId = (data['conversation_id'] ?? data['chat_id'])?.toString();
    if (_isUUID(conversationId)) {
      Get.toNamed(Routes.chatDetail, arguments: {
        'conversationId': conversationId,
        'username': data['username'] ?? 'Chat',
      });
      return;
    }

    _openNotificationsRoute();
  }

  Future<void> _openPostFromNotification(String postId) async {
    try {
      if (Get.isRegistered<PostRepository>()) {
        final post = await Get.find<PostRepository>().fetchPostById(postId);
        if (post != null) {
          Get.to(() => PostDetailScreen(post: post));
          return;
        }
      }
    } catch (_) {}
    _openNotificationsRoute();
  }

  void _openNotificationsRoute() {
    if (Get.currentRoute != Routes.notifications) {
      Get.toNamed(Routes.notifications);
    }
  }

  void _refreshNotificationBadge() {
    if (Get.isRegistered<NotificationBadgeController>()) {
      Get.find<NotificationBadgeController>().refreshUnreadCount();
    }
  }

  String? _titleFromMessage(RemoteMessage message) {
    return message.notification?.title ?? message.data['title'];
  }

  String? _bodyFromMessage(RemoteMessage message) {
    return message.notification?.body ?? message.data['body'] ?? message.data['message'];
  }

  String get _platformName => defaultTargetPlatform.name.toLowerCase();

  @override
  void onClose() {
    _onTokenRefreshSub?.cancel();
    _onAuthChangedSub?.cancel();
    _onMessageSub?.cancel();
    _onMessageOpenedSub?.cancel();
    super.onClose();
  }
}
