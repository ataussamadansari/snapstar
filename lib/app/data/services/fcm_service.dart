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
  String? _lastAuthUserId;

  @override
  void onInit() {
    super.onInit();
    Future<void>.microtask(_initialize);
  }

  Future<void> _initialize() async {
    if (kIsWeb) {
      return;
    }

    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
    } catch (error, stackTrace) {
      debugPrint('FcmService._initialize firebase init error: $error');
      debugPrint('FcmService._initialize firebase init stack: $stackTrace');
      return;
    }

    try {
      await _initializeLocalNotifications();
      await _requestPermissions();
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      _onTokenRefreshSub = _messaging.onTokenRefresh.listen(_persistToken);
      _onAuthChangedSub = _authRepository.currentUserStream.listen((
        user,
      ) async {
        final previousUserId = _lastAuthUserId;
        _lastAuthUserId = user?.id;

        if (user == null) {
          if (previousUserId != null && _lastSyncedToken != null) {
            await _deactivateToken(previousUserId, _lastSyncedToken!);
          }
          _lastSyncedUserId = null;
          _lastSyncedToken = null;
          return;
        }

        await _syncCurrentToken();
      });

      _onMessageSub = FirebaseMessaging.onMessage.listen((message) async {
        _refreshNotificationBadge();
        await _showForegroundNotification(message);
      });

      _onMessageOpenedSub = FirebaseMessaging.onMessageOpenedApp.listen(
        _handleMessageNavigation,
      );

      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleMessageNavigation(initialMessage);
      }

      await _syncCurrentToken();
    } catch (error, stackTrace) {
      debugPrint('FcmService._initialize error: $error');
      debugPrint('FcmService._initialize stack: $stackTrace');
    }
  }

  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/launcher_icon',
    );
    const iosSettings = DarwinInitializationSettings();
    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload == null || payload.isEmpty) {
          _openNotificationsRoute();
          return;
        }

        try {
          final decoded = jsonDecode(payload);
          if (decoded is Map<String, dynamic>) {
            _handleDataNavigation(decoded);
            return;
          }
        } catch (_) {}

        _openNotificationsRoute();
      },
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_androidNotificationChannel);
  }

  Future<void> _requestPermissions() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  Future<void> _syncCurrentToken() async {
    try {
      final token = await _messaging.getToken();
      if (token == null || token.isEmpty) {
        return;
      }
      await _persistToken(token);
    } catch (error, stackTrace) {
      debugPrint('FcmService._syncCurrentToken error: $error');
      debugPrint('FcmService._syncCurrentToken stack: $stackTrace');
    }
  }

  Future<void> _persistToken(String token) async {
    final userId = _authRepository.currentUserId;
    if (userId == null || token.isEmpty) {
      return;
    }

    if (_lastSyncedUserId == userId && _lastSyncedToken == token) {
      return;
    }

    final now = DateTime.now().toIso8601String();
    final platform = _platformName;

    // First, deactivate all old tokens for this user on this platform
    try {
      await _client
          .from('user_push_tokens')
          .update({'is_active': false, 'updated_at': now})
          .eq('user_id', userId)
          .eq('platform', platform)
          .neq('token', token);
    } catch (error) {
      debugPrint(
        'FcmService._persistToken deactivate old tokens error: $error',
      );
    }

    final attempts = <Future<void> Function()>[
      () => _client.rpc(
        'upsert_push_token',
        params: {'p_token': token, 'p_platform': platform},
      ),
      () async {
        // Check if token already exists
        final existing = await _client
            .from('user_push_tokens')
            .select('id')
            .eq('user_id', userId)
            .eq('token', token)
            .maybeSingle();

        if (existing != null) {
          // Update existing token
          await _client
              .from('user_push_tokens')
              .update({
                'is_active': true,
                'platform': platform,
                'updated_at': now,
              })
              .eq('user_id', userId)
              .eq('token', token);
        } else {
          // Insert new token
          await _client.from('user_push_tokens').insert({
            'user_id': userId,
            'token': token,
            'platform': platform,
            'is_active': true,
            'created_at': now,
            'updated_at': now,
          });
        }
      },
      () => _client
          .from('users')
          .update({'fcm_token': token, 'updated_at': now})
          .eq('id', userId),
      () => _client
          .from('users')
          .update({'push_token': token, 'updated_at': now})
          .eq('id', userId),
    ];

    Object? lastError;
    StackTrace? lastStack;

    for (final attempt in attempts) {
      try {
        await attempt();
        _lastSyncedUserId = userId;
        _lastSyncedToken = token;
        _lastAuthUserId = userId;
        return;
      } catch (error, stackTrace) {
        lastError = error;
        lastStack = stackTrace;

        if (_isSchemaMismatch(error)) {
          continue;
        }

        debugPrint('FcmService._persistToken error: $error');
        debugPrint('FcmService._persistToken stack: $stackTrace');
        return;
      }
    }

    if (lastError != null) {
      debugPrint('FcmService._persistToken failed all strategies: $lastError');
      if (lastStack != null) {
        debugPrint('FcmService._persistToken failed stack: $lastStack');
      }
    }
  }

  Future<void> _deactivateToken(String userId, String token) async {
    final now = DateTime.now().toIso8601String();

    final attempts = <Future<void> Function()>[
      () => _client.rpc('deactivate_push_token', params: {'p_token': token}),
      () => _client
          .from('user_push_tokens')
          .update({'is_active': false, 'updated_at': now})
          .eq('user_id', userId)
          .eq('token', token),
    ];

    for (final attempt in attempts) {
      try {
        await attempt();
        return;
      } catch (error) {
        if (_isSchemaMismatch(error)) {
          continue;
        }
        return;
      }
    }
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final title = _titleFromMessage(message);
    final body = _bodyFromMessage(message);
    if (title == null && body == null) {
      return;
    }

    final payload = message.data.isEmpty ? null : jsonEncode(message.data);

    await _localNotifications.show(
      message.messageId?.hashCode ?? DateTime.now().millisecondsSinceEpoch,
      title ?? 'Snapstar',
      body ?? '',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _androidNotificationChannel.id,
          _androidNotificationChannel.name,
          channelDescription: _androidNotificationChannel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: payload,
    );
  }

  void _handleMessageNavigation(RemoteMessage message) {
    _refreshNotificationBadge();
    _handleDataNavigation(message.data);
  }

  void _handleDataNavigation(Map<String, dynamic> data) {
    if (_authRepository.currentUserId == null) {
      return;
    }

    final route = data['route']?.toString();
    if (route != null && route.isNotEmpty && route.startsWith('/')) {
      Future<void>.microtask(() => Get.toNamed(route, arguments: data));
      return;
    }

    _openNotificationsRoute();
  }

  void _openNotificationsRoute() {
    if (Get.currentRoute == Routes.notifications) {
      return;
    }
    Future<void>.microtask(() => Get.toNamed(Routes.notifications));
  }

  void _refreshNotificationBadge() {
    if (!Get.isRegistered<NotificationBadgeController>()) {
      return;
    }
    Get.find<NotificationBadgeController>().refreshUnreadCount();
  }

  String? _titleFromMessage(RemoteMessage message) {
    final notificationTitle = message.notification?.title?.trim();
    if (notificationTitle != null && notificationTitle.isNotEmpty) {
      return notificationTitle;
    }

    final dataTitle = message.data['title']?.toString().trim();
    if (dataTitle != null && dataTitle.isNotEmpty) {
      return dataTitle;
    }

    final dataType = message.data['type']?.toString().trim();
    if (dataType != null && dataType.isNotEmpty) {
      return dataType;
    }

    return null;
  }

  String? _bodyFromMessage(RemoteMessage message) {
    final notificationBody = message.notification?.body?.trim();
    if (notificationBody != null && notificationBody.isNotEmpty) {
      return notificationBody;
    }

    final dataMessage = message.data['message']?.toString().trim();
    if (dataMessage != null && dataMessage.isNotEmpty) {
      return dataMessage;
    }

    final dataBody = message.data['body']?.toString().trim();
    if (dataBody != null && dataBody.isNotEmpty) {
      return dataBody;
    }

    return null;
  }

  String get _platformName {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.macOS:
        return 'macos';
      case TargetPlatform.windows:
        return 'windows';
      case TargetPlatform.linux:
        return 'linux';
      case TargetPlatform.fuchsia:
        return 'fuchsia';
    }
  }

  bool _isSchemaMismatch(Object error) {
    if (error is! PostgrestException) {
      return false;
    }

    final code = error.code;
    final message = error.message.toLowerCase();
    final details = (error.details?.toString() ?? '').toLowerCase();

    if (code == 'PGRST202' ||
        code == 'PGRST204' ||
        code == 'PGRST205' ||
        code == '42P01' ||
        code == '42703') {
      return true;
    }

    return message.contains('schema cache') ||
        message.contains('column') ||
        message.contains('function') ||
        message.contains('table') ||
        details.contains('schema cache');
  }

  @override
  void onClose() {
    _onTokenRefreshSub?.cancel();
    _onAuthChangedSub?.cancel();
    _onMessageSub?.cancel();
    _onMessageOpenedSub?.cancel();
    super.onClose();
  }
}
