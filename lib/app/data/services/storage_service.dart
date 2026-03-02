import 'dart:io';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StorageService extends GetxService {
  final _supabase = Supabase.instance.client;

  // Upload chat image
  Future<String> uploadChatImage(File imageFile, String conversationId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'chat_${conversationId}_${timestamp}.jpg';
      final path = 'chat_images/$userId/$fileName';

      await _supabase.storage
          .from('chat-media')
          .upload(
            path,
            imageFile,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );

      final url = _supabase.storage.from('chat-media').getPublicUrl(path);
      return url;
    } catch (e) {
      throw Exception('Failed to upload chat image: $e');
    }
  }

  // Upload chat video
  Future<String> uploadChatVideo(File videoFile, String conversationId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'chat_${conversationId}_${timestamp}.mp4';
      final path = 'chat_videos/$userId/$fileName';

      await _supabase.storage
          .from('chat-media')
          .upload(
            path,
            videoFile,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );

      final url = _supabase.storage.from('chat-media').getPublicUrl(path);
      return url;
    } catch (e) {
      throw Exception('Failed to upload chat video: $e');
    }
  }

  // Delete chat media
  Future<void> deleteChatMedia(String mediaUrl) async {
    try {
      final uri = Uri.parse(mediaUrl);
      final path = uri.pathSegments.skip(4).join('/');
      await _supabase.storage.from('chat-media').remove([path]);
    } catch (e) {
      throw Exception('Failed to delete chat media: $e');
    }
  }
}
