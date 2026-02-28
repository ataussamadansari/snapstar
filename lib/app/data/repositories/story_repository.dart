import 'dart:io';
import 'package:snapstar_app/app/data/models/story_view_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/story_model.dart';

class StoryRepository {
  final _client = Supabase.instance.client;

  // ===============================
  // 🔹 UPLOAD MEDIA TO STORAGE
  // ===============================
  Future<String> uploadMedia({
    required File file,
    required String userId,
  }) async {
    final fileExt = file.path.split('.').last;
    final fileName =
        "$userId/${DateTime.now().millisecondsSinceEpoch}.$fileExt";

    await _client.storage
        .from('stories') // bucket name
        .upload(fileName, file);

    final publicUrl = _client.storage.from('stories').getPublicUrl(fileName);

    return publicUrl;
  }

  // ===============================
  // 🔹 CREATE STORY
  // ===============================
  Future<void> createStory(StoryModel story) async {
    await _client.from('stories').insert(story.toJson());
  }

  // ===============================
  // 🔹 FETCH ALL ACTIVE STORIES
  // ===============================
  Future<List<StoryModel>> fetchActiveStories() async {
    final response = await _client
        .from('stories')
        .select('*, users(*)')
        .gt('expires_at', DateTime.now().toIso8601String())
        .order('created_at', ascending: false);

    return (response as List).map((e) => StoryModel.fromJson(e)).toList();
  }

  // ===============================
  // 🔹 FETCH STORIES BY USER
  // ===============================
  Future<List<StoryModel>> fetchUserStories(String userId) async {
    final response = await _client
        .from('stories')
        .select()
        .eq('user_id', userId)
        .gt('expires_at', DateTime.now().toIso8601String())
        .order('created_at', ascending: false);

    return (response as List).map((e) => StoryModel.fromJson(e)).toList();
  }

  // ===============================
  // 🔹 DELETE STORY
  // ===============================
  Future<void> deleteStory(String storyId) async {
    await _client.from('stories').delete().eq('id', storyId);
  }

  // ===============================
  // 🔹 INSERT STORY VIEW
  // ===============================
  Future<void> insertStoryView({
    required String storyId,
    required String viewerId,
  }) async {
    await _client.from('story_views').insert({
      'story_id': storyId,
      'viewer_id': viewerId,
    });
  }

  // ===============================
  // 🔹 CHECK IF STORY VIEWED
  // ===============================
  Future<bool> isStoryViewed(String storyId, String viewerId) async {
    final response = await _client
        .from('story_views')
        .select()
        .eq('story_id', storyId)
        .eq('viewer_id', viewerId)
        .maybeSingle();

    return response != null;
  }


  // ===============================
  // 🔹 GET VIEW COUNT
  // ===============================
  Future<int> getStoryViewCount(String storyId) async {
    final response = await _client
        .from('story_views')
        .select('id')
        .eq('story_id', storyId);

    return (response as List).length;
  }

  // ===============================
  // 🔹 DELETE EXPIRED STORIES
  // ===============================
  Future<void> deleteExpiredStories() async {
    await _client
        .from('stories')
        .delete()
        .lt('expires_at', DateTime.now().toIso8601String());
  }


}

