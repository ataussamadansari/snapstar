import 'package:flutter/foundation.dart';

import '../models/comment_model.dart';
import 'auth_repository.dart';
import '../services/comment_service.dart';

enum CommentModelChangeType { insert, update, delete }

class CommentModelChange {
  const CommentModelChange({
    required this.type,
    required this.commentId,
    required this.postId,
    this.comment,
  });

  final CommentModelChangeType type;
  final String commentId;
  final String postId;
  final CommentModel? comment;
}

class CommentRepository {
  CommentRepository(
    this._service,
    this._authRepository,
  );

  final CommentService _service;
  final AuthRepository _authRepository;

  Future<void> addCommentForCurrentUser({
    required String postId,
    required String text,
    String? parentId,
  }) async {
    final userId = _authRepository.currentUserId;
    if (userId == null) {
      throw StateError('User not logged in');
    }

    await _service.createComment({
      'post_id': postId,
      'user_id': userId,
      'parent_id': parentId,
      'comment_text': text,
    });
  }

  Future<void> addComment(CommentModel comment) {
    return _service.createComment(comment.toJson());
  }

  Future<List<CommentModel>> getComments(String postId) async {
    final data = await _service.fetchComments(postId);

    return data.map((json) => CommentModel.fromJson(json)).toList();
  }

  Future<int> getCommentCount(String postId) {
    return _service.fetchCommentCount(postId);
  }

  Future<void> editComment(String id, String newText) {
    return _service.updateComment(id, newText);
  }

  Future<void> removeComment({
    required String id,
    required String postId,
  }) {
    return _service.deleteComment(
      id: id,
      postId: postId,
    );
  }

  VoidCallback subscribeToPostCommentChanges({
    required String postId,
    required void Function(CommentModelChange) onEvent,
  }) {
    return _service.subscribeToPostComments(
      postId: postId,
      onEvent: (change) {
        final converted = _toModelChange(change);
        if (converted != null) {
          onEvent(converted);
        }
      },
    );
  }

  VoidCallback subscribeToPostComments({
    required String postId,
    required VoidCallback onChanged,
  }) {
    return subscribeToPostCommentChanges(
      postId: postId,
      onEvent: (_) => onChanged(),
    );
  }

  List<CommentModel> mergeComments({
    required List<CommentModel> current,
    required CommentModelChange change,
  }) {
    final next = List<CommentModel>.from(current);

    switch (change.type) {
      case CommentModelChangeType.insert:
        if (change.comment == null) {
          return next;
        }

        next.removeWhere((item) => item.id == change.commentId);
        next.add(change.comment!);
        next.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        return next;
      case CommentModelChangeType.update:
        if (change.comment == null) {
          return next;
        }

        final index = next.indexWhere((item) => item.id == change.commentId);
        if (index >= 0) {
          next[index] = change.comment!;
        } else {
          next.add(change.comment!);
        }

        next.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        return next;
      case CommentModelChangeType.delete:
        next.removeWhere((item) => item.id == change.commentId);
        return next;
    }
  }

  CommentModelChange? _toModelChange(CommentRealtimeChange change) {
    try {
      final model = change.commentData != null
          ? CommentModel.fromJson(change.commentData!)
          : null;

      switch (change.type) {
        case CommentChangeType.insert:
          return CommentModelChange(
            type: CommentModelChangeType.insert,
            commentId: change.commentId,
            postId: change.postId,
            comment: model,
          );
        case CommentChangeType.update:
          return CommentModelChange(
            type: CommentModelChangeType.update,
            commentId: change.commentId,
            postId: change.postId,
            comment: model,
          );
        case CommentChangeType.delete:
          return CommentModelChange(
            type: CommentModelChangeType.delete,
            commentId: change.commentId,
            postId: change.postId,
          );
      }
    } catch (error, stackTrace) {
      debugPrint('CommentRepository._toModelChange error: $error');
      debugPrint('CommentRepository._toModelChange stack: $stackTrace');
      return null;
    }
  }
}
