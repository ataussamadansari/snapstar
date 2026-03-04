import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:snapstar_app/app/core/utils/helpers.dart';
import 'package:snapstar_app/app/global_widgets/loading_skeleton.dart';
import '../data/models/conversation_model.dart';
import '../data/models/post_model.dart';
import '../data/repositories/chat_repository.dart';
import '../routes/app_routes.dart';

class SharePostBottomSheet extends StatefulWidget {
  final PostModel post;

  const SharePostBottomSheet({super.key, required this.post});

  @override
  State<SharePostBottomSheet> createState() => _SharePostBottomSheetState();
}

class _SharePostBottomSheetState extends State<SharePostBottomSheet> {
  final _chatRepo = Get.find<ChatRepository>();
  List<ConversationModel> _conversations = [];
  bool _isLoading = true;
  final Set<String> _selectedConversations = {};
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    try {
      final conversationsStream = _chatRepo.watchConversations();
      final conversations = await conversationsStream.first;
      setState(() {
        _conversations = conversations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      AppHelpers.showSnackBar(
        title: 'Error',
        message: 'Failed to load conversations',
        isError: true,
      );
    }
  }

  Future<void> _sharePost() async {
    if (_selectedConversations.isEmpty) return;

    setState(() {
      _isSending = true;
    });

    try {
      final caption = widget.post.caption.isNotEmpty
          ? widget.post.caption
          : 'Shared a post';

      for (final conversationId in _selectedConversations) {
        await _chatRepo.sharePost(
          conversationId,
          widget.post.id,
          widget.post.mediaType == MediaType.video ? 'reel' : 'post',
          caption,
        );
      }

      Get.back();
      AppHelpers.showSnackBar(
        title: 'Success',
        message:
            'Post shared to ${_selectedConversations.length} conversation(s)',
        isError: false,
      );
    } catch (e) {
      AppHelpers.showSnackBar(
        title: 'Error',
        message: 'Failed to share post',
        isError: true,
      );
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final halfHeight = MediaQuery.of(context).size.height * 0.6;

    return SizedBox(
      height: halfHeight,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Text(
                    'Share to',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  if (_selectedConversations.isNotEmpty)
                    TextButton(
                      onPressed: _isSending ? null : _sharePost,
                      child: _isSending
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Send'),
                    ),
                ],
              ),
            ),

            Expanded(
              child: _isLoading
                  ? const AppShimmer(child: UserListSkeleton(itemCount: 6))
                  : _conversations.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('No conversations yet'),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              Get.back();
                              Get.toNamed(Routes.chatList);
                            },
                            child: const Text('Start a conversation'),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _conversations.length,
                      itemBuilder: (context, index) {
                        final conversation = _conversations[index];
                        final isSelected = _selectedConversations.contains(
                          conversation.id,
                        );

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage:
                                conversation.otherUser?.avatarUrl != null &&
                                    conversation
                                        .otherUser!
                                        .avatarUrl!
                                        .isNotEmpty
                                ? CachedNetworkImageProvider(
                                    conversation.otherUser!.avatarUrl!,
                                  )
                                : null,
                            child: conversation.otherUser?.avatarUrl == null
                                ? const Icon(Icons.person)
                                : null,
                          ),
                          title: Text(
                            conversation.otherUser?.name ?? 'Unknown',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            '@${conversation.otherUser?.username ?? 'user'}',
                          ),
                          trailing: isSelected
                              ? const Icon(
                                  Icons.check_circle,
                                  color: Colors.blue,
                                )
                              : const Icon(Icons.circle_outlined),
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                _selectedConversations.remove(conversation.id);
                              } else {
                                _selectedConversations.add(conversation.id);
                              }
                            });
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
