import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:snapstar_app/app/core/utils/helpers.dart';

import '../../../core/utils/date_time_extension.dart';
import '../../../core/utils/reels_navigation_helper.dart';
import '../../../data/models/message_model.dart';
import '../../../data/repositories/post_repository.dart';
import '../../../global_widgets/app_cached_image.dart';
import '../../../presentation/controllers/auth_controller.dart';
import '../../post_view/views/post_detail_screen.dart';
import '../controllers/chat_detail_controller.dart';
import '../widgets/chat_detail_shimmer.dart';

class ChatDetailScreen extends GetView<ChatDetailController> {
  const ChatDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(controller.username),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: Obx(() {
              // Show shimmer while loading
              if (controller.isLoading.value && controller.messages.isEmpty) {
                return const ChatDetailShimmer();
              }

              if (controller.errorMessage.value != null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        controller.errorMessage.value!,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                );
              }

              if (controller.messages.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 64,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No messages yet',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Start the conversation',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                controller: controller.scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: controller.messages.length,
                itemBuilder: (context, index) {
                  final message = controller.messages[index];
                  final isMyMessage = controller.isMyMessage(message);
                  final showDate = _shouldShowDate(index);

                  return Column(
                    children: [
                      if (showDate) _DateDivider(date: message.createdAt),
                      _MessageBubble(
                        message: message,
                        isMyMessage: isMyMessage,
                        onLongPress: isMyMessage
                            ? () => _showMessageOptions(context, message)
                            : null,
                      ),
                    ],
                  );
                },
              );
            }),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  bool _shouldShowDate(int index) {
    if (index == 0) return true;

    final currentMessage = controller.messages[index];
    final previousMessage = controller.messages[index - 1];

    final currentDate = DateTime(
      currentMessage.createdAt.year,
      currentMessage.createdAt.month,
      currentMessage.createdAt.day,
    );
    final previousDate = DateTime(
      previousMessage.createdAt.year,
      previousMessage.createdAt.month,
      previousMessage.createdAt.day,
    );

    return currentDate != previousDate;
  }

  Widget _buildMessageInput() {
    final authController = Get.find<AuthController>();

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Obx(
                () => TextField(
                  controller: controller.messageController,
                  readOnly: authController.isAnonymous.value,
                  decoration: InputDecoration(
                    hintText: authController.isAnonymous.value
                        ? 'Login with Google to send messages'
                        : 'Type a message...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onTap: authController.isAnonymous.value
                      ? controller.sendTextMessage
                      : null,
                  onSubmitted: (_) => controller.sendTextMessage(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Obx(
              () => IconButton(
                icon: controller.isSending.value
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
                onPressed: controller.isSending.value
                    ? null
                    : controller.sendTextMessage,
                color: Colors.blue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMessageOptions(BuildContext context, MessageModel message) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text(
                'Delete Message',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Get.back();
                controller.deleteMessage(message.id);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DateDivider extends StatelessWidget {
  final DateTime date;

  const _DateDivider({required this.date});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(child: Divider(color: Colors.grey[300])),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              _formatDate(date),
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(child: Divider(color: Colors.grey[300])),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) {
      return 'Today';
    } else if (messageDate == yesterday) {
      return 'Yesterday';
    } else {
      return date.timeAgo;
    }
  }
}

class _MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMyMessage;
  final VoidCallback? onLongPress;

  const _MessageBubble({
    required this.message,
    required this.isMyMessage,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: onLongPress,
      child: Align(
        alignment: isMyMessage ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isMyMessage ? Colors.blue : Colors.grey[300],
            borderRadius: BorderRadius.circular(16),
          ),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.7,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMessageContent(),
              const SizedBox(height: 4),
              Text(
                _formatTime(message.createdAt),
                style: TextStyle(
                  color: isMyMessage ? Colors.white70 : Colors.grey[600],
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageContent() {
    switch (message.messageType) {
      case MessageType.image:
        return _buildImageMessage();
      case MessageType.video:
        return _buildVideoMessage();
      case MessageType.post:
      case MessageType.reel:
        return _buildSharedPost();
      default:
        return _buildTextMessage();
    }
  }

  Widget _buildTextMessage() {
    return Text(
      message.messageText ?? '',
      style: TextStyle(
        color: isMyMessage ? Colors.white : Colors.black87,
        fontSize: 15,
      ),
    );
  }

  Widget _buildImageMessage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (message.mediaUrl != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: AppCachedImage(
              imageUrl: message.mediaUrl!,
              fit: BoxFit.cover,
            ),
          ),
        if (message.messageText != null && message.messageText!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            message.messageText!,
            style: TextStyle(
              color: isMyMessage ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildVideoMessage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (message.thumbnailUrl != null || message.mediaUrl != null)
          Stack(
            alignment: Alignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: AppCachedImage(
                  imageUrl: message.thumbnailUrl ?? message.mediaUrl!,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ],
          ),
        if (message.messageText != null && message.messageText!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            message.messageText!,
            style: TextStyle(
              color: isMyMessage ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSharedPost() {
    final previewUrl = message.sharedPostThumbnailUrl ?? message.sharedPostMediaUrl;
    final isReel = message.messageType == MessageType.reel;

    return GestureDetector(
      onTap: () => _openSharedPost(),
      child: Container(
        decoration: BoxDecoration(
          color: isMyMessage ? Colors.blue[700] : Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                if (previewUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: AppCachedImage(
                      imageUrl: previewUrl,
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                if (previewUrl == null)
                  Container(
                    height: 150,
                    width: double.infinity,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isMyMessage ? Colors.blue[600] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isReel ? Icons.play_circle_outline : Icons.image_outlined,
                      color: isMyMessage ? Colors.white70 : Colors.black54,
                      size: 36,
                    ),
                  ),
                if (isReel)
                  Positioned.fill(
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            if (message.sharedPostCaption != null &&
                message.sharedPostCaption!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                message.sharedPostCaption!,
                style: TextStyle(
                  color: isMyMessage ? Colors.white : Colors.black87,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (message.messageText != null &&
                message.messageText!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                message.messageText!,
                style: TextStyle(
                  color: isMyMessage ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _openSharedPost() {
    if (message.sharedPostId == null) return;
    final postRepo = Get.find<PostRepository>();

    postRepo.fetchPostById(message.sharedPostId!).then((post) {
      if (post == null) {
        AppHelpers.showSnackBar(
          title: 'Unavailable',
          message: 'This shared post is no longer available',
          isError: true,
        );
        return;
      }

      if (post.mediaType.name == 'video') {
        ReelsNavigationHelper.openFromPost(
          post,
          scopedPosts: [post],
          scopedUserId: post.userId,
        );
        return;
      }

      Get.to(() => PostDetailScreen(post: post));
    }).catchError((_) {
      AppHelpers.showSnackBar(
        title: 'Error',
        message: 'Unable to open shared post',
        isError: true,
      );
    });
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
