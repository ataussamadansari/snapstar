import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'notification_event_helper.dart';
import '../providers/subscriber_provider.dart';

class SubscriberService {
  SubscriberService(
    this._provider,
    this._client,
  );

  final SubscriberProvider _provider;
  final SupabaseClient _client;

  RealtimeChannel? _channel;
  final Map<String, Set<VoidCallback>> _userListeners =
      <String, Set<VoidCallback>>{};

  Future<void> subscribe(Map<String, dynamic> data) async {
    try {
      await _provider.subscribe(data);
    } catch (error, stackTrace) {
      debugPrint('SubscriberService.subscribe error: $error');
      debugPrint('SubscriberService.subscribe stack: $stackTrace');
      rethrow;
    }
  }

  Future<void> unsubscribe({
    required String subscriberId,
    required String subscribedId,
  }) async {
    try {
      await _provider.unsubscribe(
        subscriberId: subscriberId,
        subscribedId: subscribedId,
      );
    } catch (error, stackTrace) {
      debugPrint('SubscriberService.unsubscribe error: $error');
      debugPrint('SubscriberService.unsubscribe stack: $stackTrace');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getSubscription({
    required String subscriberId,
    required String subscribedId,
  }) async {
    try {
      return await _provider.getSubscription(
        subscriberId: subscriberId,
        subscribedId: subscribedId,
      );
    } catch (error, stackTrace) {
      debugPrint('SubscriberService.getSubscription error: $error');
      debugPrint('SubscriberService.getSubscription stack: $stackTrace');
      rethrow;
    }
  }

  Future<bool> toggleSubscription({
    required String subscriberId,
    required String subscribedId,
  }) async {
    if (subscriberId == subscribedId) {
      throw ArgumentError('Cannot subscribe to self');
    }

    try {
      final existing = await _provider.getSubscription(
        subscriberId: subscriberId,
        subscribedId: subscribedId,
      );

      if (existing != null) {
        await _provider.unsubscribe(
          subscriberId: subscriberId,
          subscribedId: subscribedId,
        );

        await _updateFollowCounts(
          subscriberId: subscriberId,
          subscribedId: subscribedId,
          isSubscribeAction: false,
        );
        await _createFollowNotification(
          actorUserId: subscriberId,
          receiverUserId: subscribedId,
          isSubscribeAction: false,
        );

        return false;
      }

      await _provider.subscribe({
        'subscriber_id': subscriberId,
        'subscribed_id': subscribedId,
      });

      await _updateFollowCounts(
        subscriberId: subscriberId,
        subscribedId: subscribedId,
        isSubscribeAction: true,
      );
      await _createFollowNotification(
        actorUserId: subscriberId,
        receiverUserId: subscribedId,
        isSubscribeAction: true,
      );

      return true;
    } catch (error, stackTrace) {
      debugPrint('SubscriberService.toggleSubscription error: $error');
      debugPrint('SubscriberService.toggleSubscription stack: $stackTrace');
      rethrow;
    }
  }

  Future<bool> isSubscribed({
    required String subscriberId,
    required String subscribedId,
  }) async {
    try {
      final existing = await _provider.getSubscription(
        subscriberId: subscriberId,
        subscribedId: subscribedId,
      );
      return existing != null;
    } catch (error, stackTrace) {
      debugPrint('SubscriberService.isSubscribed error: $error');
      debugPrint('SubscriberService.isSubscribed stack: $stackTrace');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getSubscribers(String userId) async {
    try {
      return await _provider.getSubscribers(userId);
    } catch (error, stackTrace) {
      debugPrint('SubscriberService.getSubscribers error: $error');
      debugPrint('SubscriberService.getSubscribers stack: $stackTrace');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getSubscribing(String userId) async {
    try {
      return await _provider.getSubscribing(userId);
    } catch (error, stackTrace) {
      debugPrint('SubscriberService.getSubscribing error: $error');
      debugPrint('SubscriberService.getSubscribing stack: $stackTrace');
      rethrow;
    }
  }

  Future<int> getSubscriberCount(String userId) async {
    try {
      return await _provider.fetchSubscriberCount(userId);
    } catch (error, stackTrace) {
      debugPrint('SubscriberService.getSubscriberCount error: $error');
      debugPrint('SubscriberService.getSubscriberCount stack: $stackTrace');
      rethrow;
    }
  }

  Future<int> getSubscribingCount(String userId) async {
    try {
      return await _provider.fetchSubscribingCount(userId);
    } catch (error, stackTrace) {
      debugPrint('SubscriberService.getSubscribingCount error: $error');
      debugPrint('SubscriberService.getSubscribingCount stack: $stackTrace');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getSuggestedUsers({
    required String myId,
    required int limit,
    required int offset,
  }) async {
    try {
      final subscribed = await _provider.getSubscribing(myId);
      final subscribedIds = subscribed.map((entry) => entry['subscribed_id']).toSet();

      final allUsers = await _provider.getUsersExcluding(
        userId: myId,
        limit: limit,
        offset: offset,
      );

      return allUsers.where((user) => !subscribedIds.contains(user['id'])).toList();
    } catch (error, stackTrace) {
      debugPrint('SubscriberService.getSuggestedUsers error: $error');
      debugPrint('SubscriberService.getSuggestedUsers stack: $stackTrace');
      rethrow;
    }
  }

  VoidCallback subscribeToUserRelationChanges({
    required String userId,
    required VoidCallback onChanged,
  }) {
    _userListeners.putIfAbsent(userId, () => <VoidCallback>{});
    _userListeners[userId]!.add(onChanged);

    _ensureRealtimeChannel();

    return () {
      final listeners = _userListeners[userId];
      if (listeners == null) {
        return;
      }

      listeners.remove(onChanged);
      if (listeners.isEmpty) {
        _userListeners.remove(userId);
      }

      _disposeRealtimeIfIdle();
    };
  }

  Future<void> _updateFollowCounts({
    required String subscriberId,
    required String subscribedId,
    required bool isSubscribeAction,
  }) async {
    try {
      if (isSubscribeAction) {
        await _provider.callIncrementSubscriberRpc(subscribedId);
        await _provider.callIncrementSubscribingRpc(subscriberId);
      } else {
        await _provider.callDecrementSubscriberRpc(subscribedId);
        await _provider.callDecrementSubscribingRpc(subscriberId);
      }
    } on PostgrestException catch (error, stackTrace) {
      final isMissingRpc = error.code == 'PGRST202';
      if (!isMissingRpc) {
        debugPrint('SubscriberService._updateFollowCounts rpc error: $error');
        debugPrint('SubscriberService._updateFollowCounts rpc stack: $stackTrace');
      }
      await _syncCountsFallback(subscriberId, subscribedId);
    } catch (error, stackTrace) {
      debugPrint('SubscriberService._updateFollowCounts rpc error: $error');
      debugPrint('SubscriberService._updateFollowCounts rpc stack: $stackTrace');
      await _syncCountsFallback(subscriberId, subscribedId);
    }
  }

  Future<void> _syncCountsFallback(
    String subscriberId,
    String subscribedId,
  ) async {
    try {
      final subscribedFollowerCount =
          await _provider.fetchSubscriberCount(subscribedId);
      final subscribedFollowingCount =
          await _provider.fetchSubscribingCount(subscribedId);

      await _provider.updateUserCounts(
        userId: subscribedId,
        subscriberCount: subscribedFollowerCount,
        subscribingCount: subscribedFollowingCount,
      );

      final subscriberFollowerCount =
          await _provider.fetchSubscriberCount(subscriberId);
      final subscriberFollowingCount =
          await _provider.fetchSubscribingCount(subscriberId);

      await _provider.updateUserCounts(
        userId: subscriberId,
        subscriberCount: subscriberFollowerCount,
        subscribingCount: subscriberFollowingCount,
      );
    } catch (error, stackTrace) {
      debugPrint('SubscriberService._syncCountsFallback error: $error');
      debugPrint('SubscriberService._syncCountsFallback stack: $stackTrace');
    }
  }

  void _ensureRealtimeChannel() {
    if (_channel != null) {
      return;
    }

    _channel = _client.channel('subscribes-realtime-channel');

    _channel!
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'subscribes',
        callback: _handleRealtime,
      )
      ..subscribe();
  }

  void _handleRealtime(PostgresChangePayload payload) {
    final impactedIds = <String>{};

    final newSubscriber = payload.newRecord['subscriber_id']?.toString();
    final newSubscribed = payload.newRecord['subscribed_id']?.toString();
    final oldSubscriber = payload.oldRecord['subscriber_id']?.toString();
    final oldSubscribed = payload.oldRecord['subscribed_id']?.toString();

    if (newSubscriber != null && newSubscriber.isNotEmpty) {
      impactedIds.add(newSubscriber);
    }
    if (newSubscribed != null && newSubscribed.isNotEmpty) {
      impactedIds.add(newSubscribed);
    }
    if (oldSubscriber != null && oldSubscriber.isNotEmpty) {
      impactedIds.add(oldSubscriber);
    }
    if (oldSubscribed != null && oldSubscribed.isNotEmpty) {
      impactedIds.add(oldSubscribed);
    }

    for (final userId in impactedIds) {
      final listeners = _userListeners[userId];
      if (listeners == null || listeners.isEmpty) {
        continue;
      }

      for (final listener in listeners.toList()) {
        listener();
      }
    }
  }

  void _disposeRealtimeIfIdle() {
    if (_channel == null || _userListeners.isNotEmpty) {
      return;
    }

    _client.removeChannel(_channel!);
    _channel = null;
  }

  Future<void> _createFollowNotification({
    required String actorUserId,
    required String receiverUserId,
    required bool isSubscribeAction,
  }) async {
    try {
      await NotificationEventHelper.create(
        client: _client,
        receiverUserId: receiverUserId,
        actorUserId: actorUserId,
        type: isSubscribeAction ? 'subscribe' : 'unsubscribe',
        title: isSubscribeAction ? 'New follower' : 'Follower update',
        message: isSubscribeAction
            ? 'Someone started following you'
            : 'Someone unfollowed you',
      );
    } catch (error, stackTrace) {
      debugPrint('SubscriberService._createFollowNotification error: $error');
      debugPrint(
        'SubscriberService._createFollowNotification stack: $stackTrace',
      );
    }
  }
}
