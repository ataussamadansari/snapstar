import 'package:flutter/foundation.dart';
import 'dart:io';

import '../providers/user_provider.dart';

class UserService {
  UserService(this._provider);

  final UserProvider _provider;

  Future<void> createUser(Map<String, dynamic> data) async {
    try {
      await _provider.createUser(data);
    } catch (error, stackTrace) {
      debugPrint('UserService.createUser error: $error');
      debugPrint('UserService.createUser stack: $stackTrace');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getUser(String uid) async {
    try {
      return await _provider.getUser(uid);
    } catch (error, stackTrace) {
      debugPrint('UserService.getUser error: $error');
      debugPrint('UserService.getUser stack: $stackTrace');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getUserByUsername(String username) async {
    try {
      return await _provider.getUserByUsername(username);
    } catch (error, stackTrace) {
      debugPrint('UserService.getUserByUsername error: $error');
      debugPrint('UserService.getUserByUsername stack: $stackTrace');
      rethrow;
    }
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    try {
      await _provider.updateUser(uid, data);
    } catch (error, stackTrace) {
      debugPrint('UserService.updateUser error: $error');
      debugPrint('UserService.updateUser stack: $stackTrace');
      rethrow;
    }
  }

  Future<bool> isUsernameAvailable(String username) async {
    try {
      return await _provider.isUsernameAvailable(username);
    } catch (error, stackTrace) {
      debugPrint('UserService.isUsernameAvailable error: $error');
      debugPrint('UserService.isUsernameAvailable stack: $stackTrace');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getSuggestedUsers({
    required String myId,
    required int limit,
    required int offset,
  }) async {
    try {
      return await _provider.getSuggestedUsers(
        myId: myId,
        limit: limit,
        offset: offset,
      );
    } catch (error, stackTrace) {
      debugPrint('UserService.getSuggestedUsers error: $error');
      debugPrint('UserService.getSuggestedUsers stack: $stackTrace');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> searchUsers({
    required String query,
    required int limit,
    required int offset,
    String? excludeUserId,
  }) async {
    try {
      return await _provider.searchUsers(
        query: query,
        limit: limit,
        offset: offset,
        excludeUserId: excludeUserId,
      );
    } catch (error, stackTrace) {
      debugPrint('UserService.searchUsers error: $error');
      debugPrint('UserService.searchUsers stack: $stackTrace');
      rethrow;
    }
  }

  Future<String> uploadAvatar({
    required String filePath,
    required File file,
  }) async {
    try {
      return await _provider.uploadAvatar(filePath: filePath, file: file);
    } catch (error, stackTrace) {
      debugPrint('UserService.uploadAvatar error: $error');
      debugPrint('UserService.uploadAvatar stack: $stackTrace');
      rethrow;
    }
  }
}
