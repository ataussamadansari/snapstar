import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:snapstar_app/app/core/utils/auth_helper.dart';

import '../../core/utils/subscribe_state.dart';
import '../../modules/profile_view/controllers/profile_controller.dart';
import '../../modules/profile_view/controllers/user_profile_controller.dart';
import '../repositories/subscriber_repository.dart';

class SubscriberController extends GetxController {
  SubscriberController(this.repo);

  final SubscriberRepository repo;

  final RxBool isLoading = false.obs;

  final RxMap<String, SubscribeState> relationMap =
      <String, SubscribeState>{}.obs;

  VoidCallback? _unsubscribeMyRelationChanges;

  @override
  void onInit() {
    super.onInit();

    final myId = repo.currentUserId;
    if (myId != null) {
      _unsubscribeMyRelationChanges = repo.subscribeToUserRelationChanges(
        userId: myId,
        onChanged: _refreshTrackedStatuses,
      );
    }
  }

  Future<void> loadStatus(String userId) async {
    try {
      final state = await repo.getRelationStatus(userId);
      relationMap[userId] = state;
    } catch (_) {
      relationMap[userId] = SubscribeState.none;
    }
  }

  SubscribeState getState(String userId) {
    return relationMap[userId] ?? SubscribeState.none;
  }

  Future<void> toggle(String userId) async {
    // Requirement 5: Action Guard
    if (!AuthHelper.checkAuthAndShowModal(message: "Login with Google to follow your favorite creators!")) {
      return;
    }

    try {
      isLoading.value = true;
      await repo.toggleSubscribe(userId);
      await loadStatus(userId);
      _refreshActiveProfileCounts(userId);
    } catch (_) {
      relationMap[userId] = relationMap[userId] ?? SubscribeState.none;
    } finally {
      isLoading.value = false;
    }
  }

  void _refreshActiveProfileCounts(String targetUserId) {
    if (Get.isRegistered<ProfileController>()) {
      Get.find<ProfileController>().refreshFollowCounts();
    }

    if (Get.isRegistered<UserProfileController>()) {
      final controller = Get.find<UserProfileController>();
      if (controller.userId == targetUserId || controller.isMyProfile) {
        controller.refreshFollowCounts();
      }
    }
  }

  Future<void> _refreshTrackedStatuses() async {
    final trackedUserIds = relationMap.keys.toList(growable: false);

    for (final userId in trackedUserIds) {
      await loadStatus(userId);
    }
  }

  @override
  void onClose() {
    _unsubscribeMyRelationChanges?.call();
    _unsubscribeMyRelationChanges = null;
    super.onClose();
  }
}
