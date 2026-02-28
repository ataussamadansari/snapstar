import 'package:flutter/foundation.dart';

import '../models/like_model.dart';
import '../models/user_model.dart';
import '../services/like_service.dart';
import 'auth_repository.dart';

class LikeRepository {
  LikeRepository(
    this._service,
    this._authRepository,
  );

  final LikeService _service;
  final AuthRepository _authRepository;

  Future<bool> toggleLike(String postId) async {
    final myId = _authRepository.currentUserId;
    if (myId == null) {
      throw StateError('User not logged in');
    }

    return _service.toggleLike(
      postId: postId,
      userId: myId,
    );
  }

  Future<List<UserModel>> getLikesList(String postId) async {
    final rawLikes = await _service.fetchLikes(postId);
    return rawLikes
        .map((entry) => LikeModel.fromJson(entry).user)
        .whereType<UserModel>()
        .toList();
  }

  Future<bool> checkLikeStatus(String postId) async {
    final myId = _authRepository.currentUserId;
    if (myId == null) {
      return false;
    }

    return _service.isPostLiked(postId, myId);
  }

  Future<int> getLikeCount(String postId) {
    return _service.fetchLikeCount(postId);
  }

  VoidCallback subscribeToPostLikes({
    required String postId,
    required VoidCallback onChanged,
  }) {
    return _service.subscribeToPostLikes(
      postId: postId,
      onChanged: onChanged,
    );
  }
}
