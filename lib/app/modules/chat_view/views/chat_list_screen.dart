import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/utils/date_time_extension.dart';
import '../../../data/models/conversation_model.dart';
import '../../../global_widgets/app_avatar.dart';
import '../controllers/chat_list_controller.dart';
import '../widgets/chat_list_shimmer.dart';

class ChatListScreen extends GetView<ChatListController> {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Obx(() {
        // Show shimmer while loading
        if (controller.isLoading.value && controller.conversations.isEmpty) {
          return const ChatListShimmer();
        }

        if (controller.errorMessage.value != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)),
                const SizedBox(height: 16),
                Text(
                  controller.errorMessage.value!,
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55)),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: controller.refreshConversations,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (controller.conversations.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.25),
                ),
                const SizedBox(height: 16),
                Text(
                  'No conversations yet',
                  style: TextStyle(
                    fontSize: 18,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Start chatting with your friends',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45)),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.refreshConversations,
          child: ListView.builder(
            itemCount: controller.conversations.length,
            itemBuilder: (context, index) {
              final conversation = controller.conversations[index];
              return _ConversationTile(
                conversation: conversation,
                onTap: () => controller.openConversation(conversation),
                onLongPress: () =>
                    _showConversationOptions(context, conversation),
              );
            },
          ),
        );
      }),
    );
  }

  void _showConversationOptions(
    BuildContext context,
    ConversationModel conversation,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                conversation.isMuted
                    ? Icons.notifications_active
                    : Icons.notifications_off,
              ),
              title: Text(conversation.isMuted ? 'Unmute' : 'Mute'),
              onTap: () {
                Get.back();
                controller.toggleMute(conversation.id, conversation.isMuted);
              },
            ),
            ListTile(
              leading: Icon(
                conversation.isArchived ? Icons.unarchive : Icons.archive,
              ),
              title: Text(conversation.isArchived ? 'Unarchive' : 'Archive'),
              onTap: () {
                Get.back();
                controller.toggleArchive(
                  conversation.id,
                  conversation.isArchived,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final ConversationModel conversation;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _ConversationTile({
    required this.conversation,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final otherUser = conversation.otherUser;
    final hasUnread = conversation.unreadCount > 0;

    return ListTile(
      onTap: onTap,
      onLongPress: onLongPress,
      leading: Stack(
        children: [
          AppAvatar(
            radius: 28,
            avatarUrl: otherUser?.avatarUrl,
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            iconColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
          ),
          if (hasUnread)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              conversation.displayName,
              style: TextStyle(
                fontWeight: hasUnread ? FontWeight.bold : FontWeight.w500,
                fontSize: 16,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (conversation.isMuted)
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Icon(
                Icons.notifications_off,
                size: 16,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45),
              ),
            ),
        ],
      ),
      subtitle: Text(
        _getLastMessageText(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: hasUnread
              ? Theme.of(context).colorScheme.onSurface
              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
          fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
        ),
      ),
      trailing: SizedBox(
        width: 60,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              conversation.lastMessageAt?.timeAgo ?? '',
              style: TextStyle(
                fontSize: 12,
                color: hasUnread
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45),
                fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            if (hasUnread) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                child: Center(
                  child: Text(
                    conversation.unreadCount > 99
                        ? '99+'
                        : conversation.unreadCount.toString(),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getLastMessageText() {
    if (conversation.lastMessageText == null) {
      return 'No messages yet';
    }

    switch (conversation.lastMessageType) {
      case 'image':
        return '📷 Photo';
      case 'video':
        return '🎥 Video';
      case 'post':
        return '📝 Shared a post';
      case 'reel':
        return '🎬 Shared a reel';
      default:
        return conversation.lastMessageText!;
    }
  }
}
