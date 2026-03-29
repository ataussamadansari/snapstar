import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:snapstar_app/app/core/utils/auth_helper.dart';

import '../models/comment_model.dart';
import '../repositories/comment_repository.dart';

class CommentController extends GetxController {
  CommentController(this._repository);

  final CommentRepository _repository;

  final RxList<CommentModel> comments = <CommentModel>[].obs;
  final RxMap<String, int> commentCounts = <String, int>{}.obs;
  final RxBool isLoading = false.obs;

  final Map<String, VoidCallback> _commentListeners = {};
  String? _activePostId;

  void initializePost(String postId, int dbCommentCount) {
    commentCounts[postId] ??= dbCommentCount;
    _ensureRealtime(postId);
    _syncCommentCount(postId);
  }

  Future<void> loadComments(String postId, {bool showLoader = true}) async {
    _activePostId = postId;
    _ensureRealtime(postId);

    try {
      if (showLoader) {
        isLoading.value = true;
      }

      final result = await _repository.getComments(postId);
      comments.assignAll(result);
      commentCounts[postId] = result.length;
    } catch (error, stackTrace) {
      debugPrint('CommentController.loadComments error: $error');
      debugPrint('CommentController.loadComments stack: $stackTrace');
    } finally {
      if (showLoader) {
        isLoading.value = false;
      }
    }
  }

  Future<void> addComment({
    required String postId,
    required String text,
    String? parentId,
  }) async {
    // Requirement 5: Route Protection / Action Guard
    if (!AuthHelper.checkAuthAndShowModal(message: "Login with Google to join the conversation!")) {
      return;
    }

    try {
      await _repository.addCommentForCurrentUser(
        postId: postId,
        text: text,
        parentId: parentId,
      );
      await loadComments(postId, showLoader: false);
      await _syncCommentCount(postId);
    } catch (error, stackTrace) {
      debugPrint('CommentController.addComment error: $error');
      debugPrint('CommentController.addComment stack: $stackTrace');
    }
  }

  Future<void> updateComment(String id, String newText, String postId) async {
    try {
      await _repository.editComment(id, newText);
      await loadComments(postId, showLoader: false);
    } catch (error, stackTrace) {
      debugPrint('CommentController.updateComment error: $error');
      debugPrint('CommentController.updateComment stack: $stackTrace');
    }
  }

  Future<void> deleteComment(String id, String postId) async {
    try {
      await _repository.removeComment(id: id, postId: postId);
      await loadComments(postId, showLoader: false);
      await _syncCommentCount(postId);
    } catch (error, stackTrace) {
      debugPrint('CommentController.deleteComment error: $error');
      debugPrint('CommentController.deleteComment stack: $stackTrace');
    }
  }

  List<CommentModel> get parentComments {
    final knownCommentIds = comments.map((comment) => comment.id).toSet();

    return comments.where((comment) {
      final parentId = comment.parentId;
      return parentId == null ||
          parentId.isEmpty ||
          !knownCommentIds.contains(parentId);
    }).toList();
  }

  List<CommentModel> replies(String parentId) {
    return comments.where((comment) => comment.parentId == parentId).toList();
  }

  int commentCount(String postId) {
    return commentCounts[postId] ?? 0;
  }

  void _ensureRealtime(String postId) {
    if (_commentListeners.containsKey(postId)) {
      return;
    }

    _commentListeners[postId] = _repository.subscribeToPostCommentChanges(
      postId: postId,
      onEvent: (change) {
        _applyCommentCountDelta(change);

        if (_activePostId == postId) {
          final next = _repository.mergeComments(
            current: comments.toList(),
            change: change,
          );
          comments.assignAll(next);

          if (change.type == CommentModelChangeType.insert &&
              change.comment == null) {
            loadComments(postId, showLoader: false);
          }
        }
      },
    );
  }

  void _applyCommentCountDelta(CommentModelChange change) {
    final postId = change.postId;
    final current = commentCounts[postId] ?? 0;

    switch (change.type) {
      case CommentModelChangeType.insert:
        commentCounts[postId] = current + 1;
        break;
      case CommentModelChangeType.delete:
        commentCounts[postId] = current > 0 ? current - 1 : 0;
        break;
      case CommentModelChangeType.update:
        break;
    }
  }

  Future<void> _syncCommentCount(String postId) async {
    try {
      final count = await _repository.getCommentCount(postId);
      commentCounts[postId] = count;
    } catch (error, stackTrace) {
      debugPrint('CommentController._syncCommentCount error: $error');
      debugPrint('CommentController._syncCommentCount stack: $stackTrace');
    }
  }

  @override
  void onClose() {
    for (final unsubscribe in _commentListeners.values) {
      unsubscribe();
    }
    _commentListeners.clear();
    super.onClose();
  }
}
