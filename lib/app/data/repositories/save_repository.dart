import '../models/post_model.dart';
import '../services/save_service.dart';
import 'auth_repository.dart';

class SaveRepository {
  SaveRepository(this._service, this._authRepo);

  final SaveService _service;
  final AuthRepository _authRepo;

  Future<bool> isSaved(String postId) async {
    final userId = _authRepo.currentUserId;
    if (userId == null) return false;
    return _service.isSaved(postId: postId, userId: userId);
  }

  /// Toggle save — returns new saved state (true = saved)
  Future<bool> toggleSave(String postId) async {
    final userId = _authRepo.currentUserId;
    if (userId == null) throw StateError('User not logged in');

    final saved = await _service.isSaved(postId: postId, userId: userId);
    if (saved) {
      await _service.unsavePost(postId: postId, userId: userId);
      return false;
    } else {
      await _service.savePost(postId: postId, userId: userId);
      return true;
    }
  }

  Future<List<PostModel>> fetchSavedPosts({
    int limit = 30,
    int offset = 0,
  }) async {
    final userId = _authRepo.currentUserId;
    if (userId == null) return [];

    final raw = await _service.fetchSavedPosts(
      userId: userId,
      limit: limit,
      offset: offset,
    );
    return raw.map((e) => PostModel.fromJson(e)).toList();
  }
}
