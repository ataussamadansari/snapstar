import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../data/models/conversation_model.dart';
import '../../../data/models/message_model.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/chat_repository.dart';
import '../../../data/services/storage_service.dart';

class ChatDetailController extends GetxController {
  ChatDetailController(
    this._chatRepo,
    this._authRepo,
    this._storageService,
    this.conversationId,
    this.username,
  );

  final ChatRepository _chatRepo;
  final AuthRepository _authRepo;
  final StorageService _storageService;
  final String conversationId;
  final String username;

  final RxList<MessageModel> messages = <MessageModel>[].obs;
  final Rxn<ConversationModel> conversation = Rxn<ConversationModel>();
  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final RxBool isSending = false.obs;
  final RxBool isLoadingMedia = false.obs;
  final RxnString errorMessage = RxnString();

  StreamSubscription<List<MessageModel>>? _messagesSub;
  Timer? _markReadTimer;

  @override
  void onInit() {
    super.onInit();
    _fetchConversation();
    _watchMessages();
    _scheduleMarkAsRead();
  }

  Future<void> _fetchConversation() async {
    final conv = await _chatRepo.fetchConversation(conversationId);
    conversation.value = conv;
  }

  void _watchMessages() {
    _messagesSub = _chatRepo
        .watchMessages(conversationId)
        .listen(
          (data) {
            final hadMessages = messages.isNotEmpty;
            messages.assignAll(data);
            errorMessage.value = null;

            // Scroll to bottom when new message arrives
            if (hadMessages && data.length > messages.length) {
              _scrollToBottom();
            } else if (!hadMessages && data.isNotEmpty) {
              // Initial load
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _scrollToBottom(animated: false);
              });
            }
          },
          onError: (error) {
            debugPrint('ChatDetailController._watchMessages error: $error');
            errorMessage.value = 'Failed to load messages';
          },
        );
  }

  void _scheduleMarkAsRead() {
    _markReadTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _markAsRead();
    });
  }

  Future<void> _markAsRead() async {
    if (messages.isEmpty) return;
    await _chatRepo.markMessagesRead(conversationId);
  }

  Future<void> sendTextMessage() async {
    final text = messageController.text.trim();
    if (text.isEmpty || isSending.value) return;

    try {
      isSending.value = true;
      errorMessage.value = null;
      messageController.clear();

      await _chatRepo.sendTextMessage(conversationId, text);
    } catch (error) {
      debugPrint('ChatDetailController.sendTextMessage error: $error');
      errorMessage.value = 'Failed to send message';
      Get.snackbar(
        'Error',
        'Failed to send message',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isSending.value = false;
    }
  }

  Future<void> sendImageMessage() async {
    try {
      isLoadingMedia.value = true;
      errorMessage.value = null;

      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery);

      if (image == null) {
        isLoadingMedia.value = false;
        return;
      }

      // Upload image to storage
      final imageUrl = await _storageService.uploadChatImage(
        File(image.path),
        conversationId,
      );

      isSending.value = true;
      await _chatRepo.sendImageMessage(conversationId, imageUrl, null);
    } catch (error) {
      debugPrint('ChatDetailController.sendImageMessage error: $error');
      errorMessage.value = 'Failed to send image';
      Get.snackbar(
        'Error',
        'Failed to send image',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoadingMedia.value = false;
      isSending.value = false;
    }
  }

  Future<void> sendVideoMessage() async {
    try {
      isLoadingMedia.value = true;
      errorMessage.value = null;

      final picker = ImagePicker();
      final video = await picker.pickVideo(source: ImageSource.gallery);

      if (video == null) {
        isLoadingMedia.value = false;
        return;
      }

      // Upload video to storage
      final videoUrl = await _storageService.uploadChatVideo(
        File(video.path),
        conversationId,
      );

      isSending.value = true;
      await _chatRepo.sendVideoMessage(conversationId, videoUrl, null);
    } catch (error) {
      debugPrint('ChatDetailController.sendVideoMessage error: $error');
      errorMessage.value = 'Failed to send video';
      Get.snackbar(
        'Error',
        'Failed to send video',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoadingMedia.value = false;
      isSending.value = false;
    }
  }

  Future<void> sharePost(String postId, String type) async {
    try {
      isSending.value = true;
      errorMessage.value = null;

      await _chatRepo.sharePost(conversationId, postId, type, null);

      Get.back(); // Close share dialog
      Get.snackbar(
        'Success',
        'Post shared successfully',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (error) {
      debugPrint('ChatDetailController.sharePost error: $error');
      errorMessage.value = 'Failed to share post';
      Get.snackbar(
        'Error',
        'Failed to share post',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isSending.value = false;
    }
  }

  Future<void> deleteMessage(String messageId) async {
    try {
      await _chatRepo.deleteMessage(messageId);
      Get.snackbar(
        'Success',
        'Message deleted',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (error) {
      debugPrint('ChatDetailController.deleteMessage error: $error');
      Get.snackbar(
        'Error',
        'Failed to delete message',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void _scrollToBottom({bool animated = true}) {
    if (!scrollController.hasClients) return;

    if (animated) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (scrollController.hasClients) {
          scrollController.animateTo(
            scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } else {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (scrollController.hasClients) {
          scrollController.jumpTo(scrollController.position.maxScrollExtent);
        }
      });
    }
  }

  bool isMyMessage(MessageModel message) {
    return message.senderId == _authRepo.currentUserId;
  }

  void showMediaOptions() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.image),
              title: const Text('Send Image'),
              onTap: () {
                Get.back();
                sendImageMessage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam),
              title: const Text('Send Video'),
              onTap: () {
                Get.back();
                sendVideoMessage();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void onClose() {
    _messagesSub?.cancel();
    _markReadTimer?.cancel();
    messageController.dispose();
    scrollController.dispose();
    super.onClose();
  }
}
