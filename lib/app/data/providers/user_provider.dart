import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserProvider {
  UserProvider(this._client);

  final SupabaseClient _client;

  /// 🔹 Get suggested users (exclude self)
  Future<List<Map<String, dynamic>>> getSuggestedUsers({
    required String myId,
    required int limit,
    required int offset,
  }) async {
    final res = await _client
        .from('users')
        .select('id, username, name, avatar_url')
        .neq('id', myId)
        .eq('is_anonymous', false)
        .range(offset, offset + limit - 1);

    return List<Map<String, dynamic>>.from(res);
  }

  Future<List<Map<String, dynamic>>> searchUsers({
    required String query,
    required int limit,
    required int offset,
    String? excludeUserId,
  }) async {
    final normalizedQuery = query.trim();
    if (normalizedQuery.isEmpty) {
      return <Map<String, dynamic>>[];
    }

    var request = _client
        .from('users')
        .select()
        .eq('is_anonymous', false)
        .or('username.ilike.%$normalizedQuery%,name.ilike.%$normalizedQuery%');

    if (excludeUserId != null && excludeUserId.isNotEmpty) {
      request = request.neq('id', excludeUserId);
    }

    final res = await request
        .order('subscriber_count', ascending: false)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return List<Map<String, dynamic>>.from(res);
  }

  /// CREATE USER PROFILE
  Future<void> createUser(Map<String, dynamic> data) async {
    try {
      await _client.from('users').upsert(data, onConflict: 'id');
    } on PostgrestException catch (error, stackTrace) {
      final normalizedEmail = data['email']?.toString().trim();
      final isEmailConflict =
          error.code == '23505' &&
          error.message.contains('users_email_key') &&
          normalizedEmail != null &&
          normalizedEmail.isNotEmpty;

      if (!isEmailConflict) {
        rethrow;
      }

      debugPrint('UserProvider.createUser email conflict fallback: $error');
      debugPrint('UserProvider.createUser email conflict stack: $stackTrace');

      final existing = await _client
          .from('users')
          .select('id')
          .eq('email', normalizedEmail)
          .maybeSingle();

      if (existing == null) {
        rethrow;
      }

      final updatePayload = Map<String, dynamic>.from(data)
        ..remove('id')
        ..remove('created_at');

      await _client
          .from('users')
          .update(updatePayload)
          .eq('email', normalizedEmail);
    }
  }

  /// GET USER PROFILE
  Future<Map<String, dynamic>?> getUser(String uid) async {
    return await _client.from('users').select().eq('id', uid).maybeSingle();
  }

  /// GET USER BY USERNAME
  Future<Map<String, dynamic>?> getUserByUsername(String username) async {
    return await _client
        .from('users')
        .select()
        .eq('username', username.toLowerCase())
        .maybeSingle();
  }

  /// UPDATE USER PROFILE
  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    await _client.from('users').update(data).eq('id', uid);
  }

  /// CHECK USERNAME UNIQUE
  Future<bool> isUsernameAvailable(String username) async {
    final res = await _client
        .from('users')
        .select('id')
        .eq('username', username)
        .maybeSingle();

    return res == null;
  }

  Future<String> uploadAvatar({
    required String filePath,
    required File file,
  }) async {
    await _client.storage
        .from('avatars')
        .upload(filePath, file, fileOptions: const FileOptions(upsert: true));

    return _client.storage.from('avatars').getPublicUrl(filePath);
  }
}
