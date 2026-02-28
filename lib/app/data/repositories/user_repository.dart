import 'dart:io';

import '../models/user_model.dart';
import '../services/user_service.dart';

class UserRepository {
  final UserService _service;

  UserRepository(this._service);

  /// CREATE PROFILE
  Future<bool> createProfile(UserModel user) async {
    await _service.createUser(user.toJson());
    return true;
  }

  /// FETCH PROFILE
  Future<UserModel?> fetchProfile(String uid) async {
    final data = await _service.getUser(uid);
    if (data == null) return null;
    return UserModel.fromJson(data);
  }

  /// UPDATE PROFILE
  Future<void> updateProfile(String uid, Map<String, dynamic> data) async {
    await _service.updateUser(uid, data);
  }

  /// USERNAME CHECK
  Future<bool> checkUsername(String username) {
    return _service.isUsernameAvailable(username);
  }

  Future<List<UserModel>> searchUsers({
    required String query,
    int limit = 30,
    int offset = 0,
    String? excludeUserId,
  }) async {
    final raw = await _service.searchUsers(
      query: query,
      limit: limit,
      offset: offset,
      excludeUserId: excludeUserId,
    );

    return raw.map(UserModel.fromJson).toList();
  }

  Future<String> uploadAvatar({
    required String userId,
    required File file,
    String folder = 'profiles',
  }) {
    final fileExt = file.path.split('.').last;
    final filePath =
        '$folder/$userId-${DateTime.now().millisecondsSinceEpoch}.$fileExt';

    return _service.uploadAvatar(filePath: filePath, file: file);
  }
}
