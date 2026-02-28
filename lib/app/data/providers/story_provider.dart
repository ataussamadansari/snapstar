import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/story_model.dart';
import '../models/story_view_model.dart';

class StoryProvider {
  final SupabaseClient _client = Supabase.instance.client;

  Future<String> uploadStoryFile(
      File file,
      String userId,
      ) async {

    final fileExt = file.path.split('.').last;
    final fileName =
        "${DateTime.now().millisecondsSinceEpoch}.$fileExt";

    final path = "$userId/$fileName";

    await _client.storage
        .from('stories')
        .upload(path, file);

    return _client.storage
        .from('stories')
        .getPublicUrl(path);
  }

  Future<void> insertStory({
    required String userId,
    required String mediaUrl,
    required String mediaType,
  }) async {

    final expiresAt =
    DateTime.now().add(const Duration(hours: 24));

    await _client.from('stories').insert({
      'user_id': userId,
      'media_urls': [mediaUrl],
      'media_types': [mediaType],
      'expires_at': expiresAt.toIso8601String(),
    });
  }

  Future<List<StoryModel>> fetchActiveStories() async {
    final now = DateTime.now().toIso8601String();

    final response = await _client
        .from('stories')
        .select('*')
        .gt('expires_at', now)
        .order('created_at', ascending: true);

    return (response as List)
        .map((e) => StoryModel.fromJson(e))
        .toList();
  }

  Future<List<StoryViewModel>> fetchStoryViews(
      List<String> storyIds) async {
    if (storyIds.isEmpty) return [];

    final response = await _client
        .from('story_views')
        .select()
        .inFilter('story_id', storyIds);

    return (response as List)
        .map((e) => StoryViewModel.fromJson(e))
        .toList();
  }

  Future<void> markStoryViewed(
      String storyId, String viewerId) async {
    await _client.from('story_views').insert({
      'story_id': storyId,
      'viewer_id': viewerId,
    });
  }
}
