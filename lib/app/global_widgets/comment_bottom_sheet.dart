import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:snapstar_app/app/core/utils/time_ago.dart';
import 'package:snapstar_app/app/data/controllers/comment_controller.dart';
import 'package:snapstar_app/app/data/services/auth_service.dart';
import 'package:snapstar_app/app/global_widgets/loading_skeleton.dart';

class CommentBottomSheet extends StatefulWidget {
  final String postId;

  const CommentBottomSheet({super.key, required this.postId});

  @override
  State<CommentBottomSheet> createState() => _CommentBottomSheetState();
}

class _CommentBottomSheetState extends State<CommentBottomSheet> {
  final CommentController controller = Get.find<CommentController>();

  final TextEditingController _textController = TextEditingController();

  String? replyParentId;
  String? editingCommentId;

  @override
  void initState() {
    super.initState();

    /// Load once
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.loadComments(widget.postId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.5,
      maxChildSize: 1.0,
      snap: true,
      snapSizes: const [0.6, 1.0],
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: Column(
            children: [
              /// Drag Handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              Text(
                "Comments",
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

              /// COMMENT LIST
              Expanded(
                child: Obx(() {
                  if (controller.isLoading.value) {
                    return const CommentListSkeleton();
                  }

                  final parents = controller.parentComments;

                  if (parents.isEmpty) {
                    return const Center(child: Text("No comments yet"));
                  }

                  return ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: parents.length,
                    itemBuilder: (context, index) {
                      final parent = parents[index];
                      final replies = controller.replies(parent.id);

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          /// PARENT COMMENT
                          _buildCommentTile(parent, isReply: false),

                          /// REPLIES
                          ...replies.map(
                            (reply) => _buildCommentTile(reply, isReply: true),
                          ),

                          const SizedBox(height: 15),
                        ],
                      );
                    },
                  );
                }),
              ),

              /// INPUT
              _buildInputField(theme),
            ],
          ),
        );
      },
    );
  }

  // ===============================
  // COMMENT TILE
  // ===============================

  Widget _buildCommentTile(dynamic comment, {required bool isReply}) {
    return Padding(
      padding: EdgeInsets.only(left: isReply ? 50 : 0, top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Avatar
          CircleAvatar(
            radius: isReply ? 14 : 18,
            backgroundImage: comment.user?.avatarUrl != null
                ? NetworkImage(comment.user!.avatarUrl!)
                : null,
            child: comment.user?.avatarUrl == null
                ? Icon(Icons.person, size: isReply ? 14 : 18)
                : null,
          ),

          const SizedBox(width: 10),

          /// Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// Username + Time
                Row(
                  children: [
                    Text(
                      comment.user?.username ?? "User",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: isReply ? 13 : 14,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      // "• ${comment.createdAt}",
                      // comment.createdAt.timeAgo,
                      TimeAgo.format(comment.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 4),

                /// Comment Text
                Text(comment.commentText),

                const SizedBox(height: 6),

                /// Reply Button
                if (!isReply)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        replyParentId = comment.id;
                        editingCommentId = null;
                      });

                      _textController.text = "@${comment.user?.username} ";
                      _textController.selection = TextSelection.fromPosition(
                        TextPosition(offset: _textController.text.length),
                      );
                    },
                    child: Text(
                      "Reply",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          /// 3 DOT MENU - Only show if current user is comment owner
          if (Get.find<AuthService>().currentUser?.id == comment.userId)
            PopupMenuButton<String>(
              iconSize: 18,
              onSelected: (value) async {
                if (value == "edit") {
                  setState(() {
                    editingCommentId = comment.id;
                    replyParentId = null;
                  });

                  _textController.text = comment.commentText;
                } else if (value == "delete") {
                  await controller.deleteComment(comment.id, widget.postId);
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: "edit", child: Text("Edit")),
                PopupMenuItem(value: "delete", child: Text("Delete")),
              ],
            ),
        ],
      ),
    );
  }

  // ===============================
  // INPUT FIELD
  // ===============================

  Widget _buildInputField(ThemeData theme) {
    final media = MediaQuery.of(context);
    final bottomInset = media.viewInsets.bottom;
    final safeBottom = media.padding.bottom;

    return Padding(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        bottom: bottomInset + safeBottom + 10,
        top: 5,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              decoration: InputDecoration(
                hintText: editingCommentId != null
                    ? "Edit comment..."
                    : replyParentId != null
                    ? "Reply..."
                    : "Add a comment...",
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () async {
              final text = _textController.text.trim();
              if (text.isEmpty) return;

              if (editingCommentId != null) {
                await controller.updateComment(
                  editingCommentId!,
                  text,
                  widget.postId,
                );
              } else {
                await controller.addComment(
                  postId: widget.postId,
                  text: text,
                  parentId: replyParentId,
                );
              }

              if (!mounted) return;

              setState(() {
                replyParentId = null;
                editingCommentId = null;
              });

              _textController.clear();
              FocusScope.of(context).unfocus();
            },
            icon: Icon(Icons.send, color: theme.colorScheme.primary),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}
