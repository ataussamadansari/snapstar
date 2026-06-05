import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:snapstar_app/app/core/utils/time_ago.dart';
import 'package:snapstar_app/app/data/controllers/comment_controller.dart';
import 'package:snapstar_app/app/data/controllers/comment_like_controller.dart';
import 'package:snapstar_app/app/data/models/comment_model.dart';
import 'package:snapstar_app/app/global_widgets/app_avatar.dart';
import 'package:snapstar_app/app/global_widgets/loading_skeleton.dart';
import 'package:snapstar_app/app/presentation/controllers/auth_controller.dart';

class CommentBottomSheet extends StatefulWidget {
  final String postId;
  const CommentBottomSheet({super.key, required this.postId});

  @override
  State<CommentBottomSheet> createState() => _CommentBottomSheetState();
}

class _CommentBottomSheetState extends State<CommentBottomSheet> {
  final CommentController _commentCtrl = Get.find<CommentController>();
  final CommentLikeController _likeCtrl = Get.find<CommentLikeController>();
  final AuthController _authCtrl = Get.find<AuthController>();

  final TextEditingController _textCtrl = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  String? _replyParentId;
  String? _replyUsername;
  String? _editingCommentId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _commentCtrl.loadComments(widget.postId);
    });
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _startReply(CommentModel comment) {
    setState(() {
      _replyParentId = comment.id;
      _replyUsername = comment.user?.username;
      _editingCommentId = null;
    });
    _textCtrl.text = '@${comment.user?.username ?? ''} ';
    _textCtrl.selection = TextSelection.collapsed(
      offset: _textCtrl.text.length,
    );
    _focusNode.requestFocus();
  }

  void _startEdit(CommentModel comment) {
    setState(() {
      _editingCommentId = comment.id;
      _replyParentId = null;
      _replyUsername = null;
    });
    _textCtrl.text = comment.commentText;
    _textCtrl.selection = TextSelection.collapsed(
      offset: _textCtrl.text.length,
    );
    _focusNode.requestFocus();
  }

  void _clearInput() {
    setState(() {
      _replyParentId = null;
      _replyUsername = null;
      _editingCommentId = null;
    });
    _textCtrl.clear();
    _focusNode.unfocus();
  }

  Future<void> _submit() async {
    final isAnon = _authCtrl.isAnonymous.value;
    if (isAnon) {
      await _commentCtrl.addComment(
        postId: widget.postId,
        text: '',
        parentId: null,
      );
      return;
    }

    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;

    if (_editingCommentId != null) {
      await _commentCtrl.updateComment(
        _editingCommentId!,
        text,
        widget.postId,
      );
    } else {
      await _commentCtrl.addComment(
        postId: widget.postId,
        text: text,
        parentId: _replyParentId,
      );
    }

    if (!mounted) return;
    _clearInput();
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
      builder: (context, scrollCtrl) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // ── Handle ──
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Text(
                'Comments',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),

              // ── Comment List ──
              Expanded(
                child: Obx(() {
                  if (_commentCtrl.isLoading.value) {
                    return const CommentListSkeleton();
                  }
                  final parents = _commentCtrl.parentComments;
                  if (parents.isEmpty) {
                    return const Center(child: Text('No comments yet'));
                  }
                  return ListView.builder(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: parents.length,
                    itemBuilder: (context, index) {
                      final parent = parents[index];
                      final replies = _commentCtrl.replies(parent.id);
                      return _CommentThread(
                        comment: parent,
                        replies: replies,
                        likeCtrl: _likeCtrl,
                        myId: _authCtrl.currentUserId,
                        onReply: _startReply,
                        onEdit: _startEdit,
                        onDelete: (c) =>
                            _commentCtrl.deleteComment(c.id, widget.postId),
                      );
                    },
                  );
                }),
              ),

              // ── Reply indicator ──
              if (_replyParentId != null || _editingCommentId != null)
                Container(
                  color: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.6),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Row(
                    children: [
                      Icon(
                        _editingCommentId != null
                            ? Icons.edit_outlined
                            : Icons.reply,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _editingCommentId != null
                              ? 'Editing comment'
                              : 'Replying to @$_replyUsername',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: _clearInput,
                        child: const Icon(Icons.close, size: 16),
                      ),
                    ],
                  ),
                ),

              // ── Input ──
              _buildInputField(theme),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInputField(ThemeData theme) {
    final media = MediaQuery.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        bottom: media.viewInsets.bottom + media.padding.bottom + 8,
        top: 6,
      ),
      child: Row(
        children: [
          Expanded(
            child: Obx(() {
              final isAnon = _authCtrl.isAnonymous.value;
              return TextField(
                controller: _textCtrl,
                focusNode: _focusNode,
                readOnly: isAnon,
                maxLines: null,
                decoration: InputDecoration(
                  hintText: isAnon
                      ? 'Login with Google to comment...'
                      : _editingCommentId != null
                          ? 'Edit comment...'
                          : _replyParentId != null
                              ? 'Reply...'
                              : 'Add a comment...',
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _submit,
            icon: Icon(Icons.send, color: theme.colorScheme.primary),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// _CommentThread — parent + replies grouped
// ─────────────────────────────────────────────────────────────
class _CommentThread extends StatefulWidget {
  const _CommentThread({
    required this.comment,
    required this.replies,
    required this.likeCtrl,
    required this.myId,
    required this.onReply,
    required this.onEdit,
    required this.onDelete,
  });

  final CommentModel comment;
  final List<CommentModel> replies;
  final CommentLikeController likeCtrl;
  final String? myId;
  final void Function(CommentModel) onReply;
  final void Function(CommentModel) onEdit;
  final void Function(CommentModel) onDelete;

  @override
  State<_CommentThread> createState() => _CommentThreadState();
}

class _CommentThreadState extends State<_CommentThread> {
  bool _showReplies = false;

  @override
  Widget build(BuildContext context) {
    final hasReplies = widget.replies.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Parent comment
          _CommentTile(
            comment: widget.comment,
            likeCtrl: widget.likeCtrl,
            myId: widget.myId,
            isReply: false,
            onReply: () => widget.onReply(widget.comment),
            onEdit: () => widget.onEdit(widget.comment),
            onDelete: () => widget.onDelete(widget.comment),
          ),

          // "View N replies" toggle
          if (hasReplies)
            Padding(
              padding: const EdgeInsets.only(left: 50, top: 2, bottom: 2),
              child: GestureDetector(
                onTap: () => setState(() => _showReplies = !_showReplies),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 1,
                      color: Theme.of(context).dividerColor,
                      margin: const EdgeInsets.only(right: 8),
                    ),
                    Text(
                      _showReplies
                          ? 'Hide replies'
                          : 'View ${widget.replies.length} '
                              '${widget.replies.length == 1 ? 'reply' : 'replies'}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Replies (collapsed by default)
          if (_showReplies)
            ...widget.replies.map(
              (reply) => _CommentTile(
                comment: reply,
                likeCtrl: widget.likeCtrl,
                myId: widget.myId,
                isReply: true,
                onReply: () => widget.onReply(widget.comment),
                onEdit: () => widget.onEdit(reply),
                onDelete: () => widget.onDelete(reply),
              ),
            ),

          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// _CommentTile — single comment row
// ─────────────────────────────────────────────────────────────
class _CommentTile extends StatefulWidget {
  const _CommentTile({
    required this.comment,
    required this.likeCtrl,
    required this.myId,
    required this.isReply,
    required this.onReply,
    required this.onEdit,
    required this.onDelete,
  });

  final CommentModel comment;
  final CommentLikeController likeCtrl;
  final String? myId;
  final bool isReply;
  final VoidCallback onReply;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  State<_CommentTile> createState() => _CommentTileState();
}

class _CommentTileState extends State<_CommentTile> {
  @override
  void initState() {
    super.initState();
    widget.likeCtrl.initComment(widget.comment.id);
  }

  @override
  Widget build(BuildContext context) {
    final comment = widget.comment;
    final isOwn = widget.myId == comment.userId;

    return Padding(
      padding: EdgeInsets.only(
        left: widget.isReply ? 46 : 0,
        top: 6,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          AppAvatar(
            radius: widget.isReply ? 14 : 18,
            avatarUrl: comment.user?.avatarUrl,
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            iconSize: widget.isReply ? 14 : 18,
          ),
          const SizedBox(width: 10),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Username + time
                Row(
                  children: [
                    Text(
                      comment.user?.username ?? 'User',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: widget.isReply ? 12 : 13,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      TimeAgo.format(comment.createdAt),
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),

                // Comment text
                Text(
                  comment.commentText,
                  style: const TextStyle(fontSize: 13, height: 1.35),
                ),
                const SizedBox(height: 5),

                // Action row: Reply + Like
                Row(
                  children: [
                    if (!widget.isReply)
                      GestureDetector(
                        onTap: widget.onReply,
                        child: Text(
                          'Reply',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Like + count column
          Obx(() {
            final liked = widget.likeCtrl.isLiked(comment.id);
            final count = widget.likeCtrl.likeCount(comment.id);
            return GestureDetector(
              onTap: () => widget.likeCtrl.toggleLike(comment.id),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Column(
                  children: [
                    Icon(
                      liked ? Icons.favorite : Icons.favorite_border,
                      size: 16,
                      color: liked ? Colors.redAccent : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45),
                    ),
                    if (count > 0)
                      Text(
                        '$count',
                        style: TextStyle(
                          fontSize: 10,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }),

          // 3-dot menu for own comments
          if (isOwn)
            PopupMenuButton<String>(
              iconSize: 18,
              padding: EdgeInsets.zero,
              onSelected: (value) {
                if (value == 'edit') widget.onEdit();
                if (value == 'delete') widget.onDelete();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Edit')),
                PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
        ],
      ),
    );
  }
}
