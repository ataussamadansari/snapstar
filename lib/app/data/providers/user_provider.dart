import 'dart:io';

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
    await _client.from('users').insert(data);
  }

  /// GET USER PROFILE
  Future<Map<String, dynamic>?> getUser(String uid) async {
    return await _client.from('users').select().eq('id', uid).maybeSingle();
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
