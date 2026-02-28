import 'package:flutter/foundation.dart';

import '../../core/utils/subscribe_state.dart';
import '../models/subscribe_model.dart';
import '../models/user_model.dart';
import '../services/subscriber_service.dart';
import 'auth_repository.dart';

class SubscriberRepository {
  SubscriberRepository(
    this._service,
    this._authRepository,
  );

  final SubscriberService _service;
  final AuthRepository _authRepository;

  String? get currentUserId => _authRepository.currentUserId;

  Future<SubscribeState> getRelationStatus(String targetUserId) async {
    final myId = _authRepository.currentUserId;
    if (myId == null) {
      return SubscribeState.none;
    }

    final iSubscribed = await _service.getSubscription(
      subscriberId: myId,
      subscribedId: targetUserId,
    );

    final theySubscribed = await _service.getSubscription(
      subscriberId: targetUserId,
      subscribedId: myId,
    );

    if (iSubscribed != null && theySubscribed != null) {
      return SubscribeState.mutual;
    }

    if (iSubscribed != null) {
      return SubscribeState.subscribed;
    }

    if (theySubscribed != null) {
      return SubscribeState.subscribeBack;
    }

    return SubscribeState.none;
  }

  Future<List<UserModel>> getSuggestedUsers({
    required int limit,
    required int offset,
  }) async {
    final myId = _authRepository.currentUserId;
    if (myId == null) {
      return <UserModel>[];
    }

    final raw = await _service.getSuggestedUsers(
      myId: myId,
      limit: limit,
      offset: offset,
    );

    return raw.map(UserModel.fromJson).toList();
  }

  Future<bool> toggleSubscribe(String targetUserId) async {
    final myId = _authRepository.currentUserId;
    if (myId == null) {
      throw StateError('User not logged in');
    }

    return _service.toggleSubscription(
      subscriberId: myId,
      subscribedId: targetUserId,
    );
  }

  Future<bool> isSubscribed(String targetUserId) async {
    final myId = _authRepository.currentUserId;
    if (myId == null) {
      return false;
    }

    return _service.isSubscribed(
      subscriberId: myId,
      subscribedId: targetUserId,
    );
  }

  Future<List<SubscribeModel>> getSubscribers(String userId) async {
    final raw = await _service.getSubscribers(userId);
    return raw.map(SubscribeModel.fromJson).toList();
  }

  Future<List<SubscribeModel>> getSubscribing(String userId) async {
    final raw = await _service.getSubscribing(userId);
    return raw.map(SubscribeModel.fromJson).toList();
  }

  Future<List<UserModel>> fetchSubscribersUsers(String userId) async {
    final raw = await _service.getSubscribers(userId);

    return raw
        .map(_extractJoinedUser)
        .whereType<Map<String, dynamic>>()
        .map(UserModel.fromJson)
        .toList();
  }

  Future<List<UserModel>> fetchSubscribingUsers(String userId) async {
    final raw = await _service.getSubscribing(userId);

    return raw
        .map(_extractJoinedUser)
        .whereType<Map<String, dynamic>>()
        .map(UserModel.fromJson)
        .toList();
  }

  Future<int> fetchSubscriberCount(String userId) {
    return _service.getSubscriberCount(userId);
  }

  Future<int> fetchSubscribingCount(String userId) {
    return _service.getSubscribingCount(userId);
  }

  VoidCallback subscribeToUserRelationChanges({
    required String userId,
    required VoidCallback onChanged,
  }) {
    return _service.subscribeToUserRelationChanges(
      userId: userId,
      onChanged: onChanged,
    );
  }

  Map<String, dynamic>? _extractJoinedUser(Map<String, dynamic> row) {
    final keys = [
      'users',
      'users!subscribes_subscriber_id_fkey',
      'users!subscribes_subscribed_id_fkey',
    ];

    for (final key in keys) {
      final value = row[key];
      if (value is Map<String, dynamic>) {
        return value;
      }
    }

    return null;
  }
}
