import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../repositories/save_repository.dart';

class SaveController extends GetxController {
  SaveController(this._repo);

  final SaveRepository _repo;

  // postId → saved state
  final RxMap<String, bool> _savedPosts = <String, bool>{}.obs;
  // postId → loading state (optimistic UI ke liye)
  final RxSet<String> _loading = <String>{}.obs;

  /// PostCard init hone par call karo
  void initializePost(String postId) {
    if (_savedPosts.containsKey(postId)) return;
    _savedPosts[postId] = false;
    _syncSaveState(postId);
  }

  bool isSaved(String postId) => _savedPosts[postId] ?? false;
  bool isLoading(String postId) => _loading.contains(postId);

  Future<void> toggleSave(String postId) async {
    if (_loading.contains(postId)) return;

    // Optimistic update
    final prev = _savedPosts[postId] ?? false;
    _savedPosts[postId] = !prev;
    _loading.add(postId);

    try {
      final result = await _repo.toggleSave(postId);
      _savedPosts[postId] = result;
    } catch (error, stackTrace) {
      // Rollback
      _savedPosts[postId] = prev;
      debugPrint('SaveController.toggleSave error: $error');
      debugPrint('SaveController.toggleSave stack: $stackTrace');
    } finally {
      _loading.remove(postId);
    }
  }

  Future<void> _syncSaveState(String postId) async {
    try {
      final saved = await _repo.isSaved(postId);
      _savedPosts[postId] = saved;
    } catch (_) {}
  }
}
