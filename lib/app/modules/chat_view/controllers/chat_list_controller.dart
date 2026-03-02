import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/conversation_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/chat_repository.dart';
import '../../../data/repositories/subscriber_repository.dart';
import '../../../routes/app_routes.dart';

class ChatListController extends GetxController {
  ChatListController(this._chatRepo, this._subscriberRepo);

  final ChatRepository _chatRepo;
  final SubscriberRepository _subscriberRepo;

  final RxList<ConversationModel> conversations = <ConversationModel>[].obs;
  final RxList<UserModel> subscribersFollowing = <UserModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isLoadingUsers = false.obs;
  final RxnString errorMessage = RxnString();

  StreamSubscription<List<ConversationModel>>? _conversationsSub;

  @override
  void onInit() {
    super.onInit();
    _watchConversations();
    _loadSubscribersFollowing();
  }

  void _watchConversations() {
    _conversationsSub = _chatRepo.watchConversations().listen(
      (data) {
        conversations.assignAll(data);
        errorMessage.value = null;
      },
      onError: (error) {
        debugPrint('ChatListController._watchConversations error: $error');
        errorMessage.value = 'Failed to load conversations';
      },
    );
  }

  Future<void> _loadSubscribersFollowing() async {
    try {
      isLoadingUsers.value = true;

      final currentUserId = _subscriberRepo.currentUserId;
      if (currentUserId == null) {
        subscribersFollowing.clear();
        return;
      }

      // Get both subscribers and following as UserModel lists
      final subscribers = await _subscriberRepo.fetchSubscribersUsers(
        currentUserId,
      );
      final following = await _subscriberRepo.fetchSubscribingUsers(
        currentUserId,
      );

      // Combine and remove duplicates
      final allUsers = <String, UserModel>{};
      for (final user in subscribers) {
        allUsers[user.id] = user;
      }
      for (final user in following) {
        allUsers[user.id] = user;
      }

      subscribersFollowing.assignAll(allUsers.values.toList());
    } catch (error) {
      debugPrint('ChatListController._loadSubscribersFollowing error: $error');
    } finally {
      isLoadingUsers.value = false;
    }
  }

  Future<void> openChatWithUser(String userId, String username) async {
    try {
      isLoading.value = true;
      errorMessage.value = null;

      final conversationId = await _chatRepo.getOrCreateConversation(userId);

      Get.toNamed(
        Routes.chatDetail,
        arguments: {'conversationId': conversationId, 'username': username},
      );
    } catch (error) {
      debugPrint('ChatListController.openChatWithUser error: $error');
      errorMessage.value = 'Failed to open chat';
      Get.snackbar(
        'Error',
        'Failed to open chat',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void openConversation(ConversationModel conversation) {
    Get.toNamed(
      Routes.chatDetail,
      arguments: {
        'conversationId': conversation.id,
        'username': conversation.displayName,
      },
    );
  }

  Future<void> refreshConversations() async {
    // Realtime stream will automatically update
    await _loadSubscribersFollowing();
    await Future.delayed(const Duration(milliseconds: 500));
  }

  Future<void> toggleMute(String conversationId, bool currentMuteStatus) async {
    try {
      await _chatRepo.toggleMuteConversation(
        conversationId,
        !currentMuteStatus,
      );
      Get.snackbar(
        'Success',
        currentMuteStatus ? 'Conversation unmuted' : 'Conversation muted',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (error) {
      debugPrint('ChatListController.toggleMute error: $error');
      Get.snackbar(
        'Error',
        'Failed to update conversation',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> toggleArchive(
    String conversationId,
    bool currentArchiveStatus,
  ) async {
    try {
      await _chatRepo.toggleArchiveConversation(
        conversationId,
        !currentArchiveStatus,
      );
      Get.snackbar(
        'Success',
        currentArchiveStatus
            ? 'Conversation unarchived'
            : 'Conversation archived',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (error) {
      debugPrint('ChatListController.toggleArchive error: $error');
      Get.snackbar(
        'Error',
        'Failed to update conversation',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  int get totalUnreadCount {
    return conversations.fold(0, (sum, conv) => sum + conv.unreadCount);
  }

  @override
  void onClose() {
    _conversationsSub?.cancel();
    super.onClose();
  }
}
