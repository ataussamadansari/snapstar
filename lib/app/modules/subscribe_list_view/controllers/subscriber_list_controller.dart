import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../../data/models/user_model.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/subscriber_repository.dart';

enum SubscriberListType { subscribers, subscribing }

class SubscriberListArgs {
  const SubscriberListArgs({
    required this.type,
    this.userId,
  });

  final SubscriberListType type;
  final String? userId;
}

class SubscriberListController extends GetxController {
  SubscriberListController(this._repo, this._authRepo);

  final SubscriberRepository _repo;
  final AuthRepository _authRepo;

  RxList<UserModel> users = <UserModel>[].obs;
  RxBool isLoading = true.obs;

  final Rx<SubscriberListType> type = SubscriberListType.subscribers.obs;
  String? _targetUserId;
  VoidCallback? _unsubscribeRelationChanges;

  String? get userId => _targetUserId;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;

    if (args is SubscriberListArgs) {
      load(args.type, userId: args.userId);
    } else if (args is SubscriberListType) {
      load(args);
    } else {
      load(SubscriberListType.subscribers);
    }
  }

  Future<void> load(
    SubscriberListType listType, {
    String? userId,
  }) async {
    type.value = listType;
    isLoading.value = true;

    try {
      final uid = userId ?? _authRepo.currentUserId;
      _targetUserId = uid;

      if (uid == null) {
        users.clear();
        return;
      }

      if (type.value == SubscriberListType.subscribers) {
        users.value = await _repo.fetchSubscribersUsers(uid);
      } else {
        users.value = await _repo.fetchSubscribingUsers(uid);
      }

      _subscribeRealtime(uid);
    } catch (_) {
      users.clear();
    } finally {
      isLoading.value = false;
    }
  }

  void _subscribeRealtime(String userId) {
    _unsubscribeRelationChanges?.call();
    _unsubscribeRelationChanges = _repo.subscribeToUserRelationChanges(
      userId: userId,
      onChanged: () {
        if (_targetUserId == null) {
          return;
        }

        load(type.value, userId: _targetUserId);
      },
    );
  }

  @override
  void onClose() {
    _unsubscribeRelationChanges?.call();
    _unsubscribeRelationChanges = null;
    super.onClose();
  }
}
