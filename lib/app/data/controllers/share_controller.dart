import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../models/post_model.dart';
import '../repositories/post_repository.dart';

class ShareController extends GetxController {
  ShareController(this._postRepo);

  final PostRepository _postRepo;

  final RxMap<String, int> shareCounts = <String, int>{}.obs;
  final RxMap<String, bool> shareLoading = <String, bool>{}.obs;

  final Set<String> _trackedPostIds = <String>{};
  VoidCallback? _unsubscribePostChanges;

  void initializePost(String postId, int dbShareCount) {
    shareCounts[postId] ??= dbShareCount;
    _trackedPostIds.add(postId);
    _ensureRealtimeSubscription();
    _syncShareCount(postId);
  }

  int shareCount(String postId) {
    return shareCounts[postId] ?? 0;
  }

  bool isSharing(String postId) {
    return shareLoading[postId] ?? false;
  }

  Future<void> sharePost(PostModel post) async {
    final postId = post.id;
    if (isSharing(postId)) {
      return;
    }

    final previousCount = shareCount(postId);
    shareLoading[postId] = true;
    shareCounts[postId] = previousCount + 1;

    try {
      await _postRepo.incrementShareCount(postId);

      if (post.mediaUrls.isNotEmpty) {
        await Clipboard.setData(ClipboardData(text: post.mediaUrls.first));
      }

      Get.snackbar(
        'Shared',
        post.mediaUrls.isNotEmpty
            ? 'Post link copied to clipboard'
            : 'Post shared',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (error, stackTrace) {
      shareCounts[postId] = previousCount;
      debugPrint('ShareController.sharePost error: $error');
      debugPrint('ShareController.sharePost stack: $stackTrace');

      Get.snackbar(
        'Error',
        'Could not share post',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      shareLoading[postId] = false;
    }
  }

  void _ensureRealtimeSubscription() {
    if (_unsubscribePostChanges != null) {
      return;
    }

    _unsubscribePostChanges = _postRepo.subscribeToFeedChanges(
      onEvent: (change) {
        if (!_trackedPostIds.contains(change.postId)) {
          return;
        }

        switch (change.type) {
          case PostModelChangeType.insert:
          case PostModelChangeType.update:
            if (change.post != null) {
              shareCounts[change.postId] = change.post!.shareCount;
            }
            break;
          case PostModelChangeType.delete:
            shareCounts.remove(change.postId);
            shareLoading.remove(change.postId);
            _trackedPostIds.remove(change.postId);
            break;
        }
      },
    );
  }

  Future<void> _syncShareCount(String postId) async {
    try {
      final latest = await _postRepo.getShareCount(postId);
      shareCounts[postId] = latest;
    } catch (error, stackTrace) {
      debugPrint('ShareController._syncShareCount error: $error');
      debugPrint('ShareController._syncShareCount stack: $stackTrace');
    }
  }

  @override
  void onClose() {
    _unsubscribePostChanges?.call();
    _unsubscribePostChanges = null;
    super.onClose();
  }
}
