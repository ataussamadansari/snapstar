import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/conversation_model.dart';
import '../models/message_model.dart';
import './auth_repository.dart';

class ChatRepository {
  final SupabaseClient _client;

  ChatRepository(this._client, AuthRepository _authRepo);

  // Get or create conversation with another user
  Future<String> getOrCreateConversation(String otherUserId) async {
    try {
      final response = await _client.rpc(
        'get_or_create_conversation',
        params: {'p_other_user_id': otherUserId},
      );
      return response as String;
    } catch (error, stackTrace) {
      debugPrint('ChatRepository.getOrCreateConversation error: $error');
      debugPrint('ChatRepository.getOrCreateConversation stack: $stackTrace');
      rethrow;
    }
  }

  // Fetch conversations list with realtime updates
  Stream<List<ConversationModel>> watchConversations() {
    final currentUserId = _client.auth.currentUser?.id;
    if (currentUserId == null) {
      return Stream.value([]);
    }

    return _client
        .from('conversation_list')
        .stream(primaryKey: ['id'])
        .eq('current_user_id', currentUserId)
        .order('updated_at', ascending: false)
        .map((data) {
          return data.map((json) => ConversationModel.fromJson(json)).toList();
        });
  }

  // Fetch single conversation
  Future<ConversationModel?> fetchConversation(String conversationId) async {
    try {
      final response = await _client
          .from('conversation_list')
          .select()
          .eq('id', conversationId)
          .eq('current_user_id', _client.auth.currentUser!.id)
          .maybeSingle();

      if (response == null) return null;
      return ConversationModel.fromJson(response);
    } catch (error, stackTrace) {
      debugPrint('ChatRepository.fetchConversation error: $error');
      debugPrint('ChatRepository.fetchConversation stack: $stackTrace');
      return null;
    }
  }

  // Fetch messages for a conversation with realtime updates
  Stream<List<MessageModel>> watchMessages(String conversationId) {
    return _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: true)
        .map(
          (data) => data
              .where(
                (json) =>
                    json['conversation_id'] == conversationId &&
                    json['is_deleted'] != true,
              )
              .map((json) => MessageModel.fromJson(json))
              .toList(),
        );
  }

  // Send text message
  Future<String> sendTextMessage(String conversationId, String text) async {
    try {
      final response = await _client.rpc(
        'send_message',
        params: {
          'p_conversation_id': conversationId,
          'p_message_type': 'text',
          'p_message_text': text,
        },
      );
      return response as String;
    } catch (error, stackTrace) {
      debugPrint('ChatRepository.sendTextMessage error: $error');
      debugPrint('ChatRepository.sendTextMessage stack: $stackTrace');
      rethrow;
    }
  }

  // Send image message
  Future<String> sendImageMessage(
    String conversationId,
    String mediaUrl,
    String? thumbnailUrl,
  ) async {
    try {
      final response = await _client.rpc(
        'send_message',
        params: {
          'p_conversation_id': conversationId,
          'p_message_type': 'image',
          'p_media_url': mediaUrl,
          'p_thumbnail_url': thumbnailUrl,
        },
      );
      return response as String;
    } catch (error, stackTrace) {
      debugPrint('ChatRepository.sendImageMessage error: $error');
      debugPrint('ChatRepository.sendImageMessage stack: $stackTrace');
      rethrow;
    }
  }

  // Send video message
  Future<String> sendVideoMessage(
    String conversationId,
    String mediaUrl,
    String? thumbnailUrl,
  ) async {
    try {
      final response = await _client.rpc(
        'send_message',
        params: {
          'p_conversation_id': conversationId,
          'p_message_type': 'video',
          'p_media_url': mediaUrl,
          'p_thumbnail_url': thumbnailUrl,
        },
      );
      return response as String;
    } catch (error, stackTrace) {
      debugPrint('ChatRepository.sendVideoMessage error: $error');
      debugPrint('ChatRepository.sendVideoMessage stack: $stackTrace');
      rethrow;
    }
  }

  // Share post/reel
  Future<String> sharePost(
    String conversationId,
    String postId,
    String messageType, // 'post' or 'reel'
    String? additionalText,
  ) async {
    try {
      final response = await _client.rpc(
        'send_message',
        params: {
          'p_conversation_id': conversationId,
          'p_message_type': messageType,
          'p_message_text': additionalText,
          'p_shared_post_id': postId,
        },
      );
      return response as String;
    } catch (error, stackTrace) {
      debugPrint('ChatRepository.sharePost error: $error');
      debugPrint('ChatRepository.sharePost stack: $stackTrace');
      rethrow;
    }
  }

  // Mark messages as read
  Future<void> markMessagesRead(String conversationId) async {
    try {
      await _client.rpc(
        'mark_messages_read',
        params: {'p_conversation_id': conversationId},
      );
    } catch (error, stackTrace) {
      debugPrint('ChatRepository.markMessagesRead error: $error');
      debugPrint('ChatRepository.markMessagesRead stack: $stackTrace');
    }
  }

  // Delete message (soft delete)
  Future<void> deleteMessage(String messageId) async {
    try {
      await _client
          .from('messages')
          .update({
            'is_deleted': true,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', messageId);
    } catch (error, stackTrace) {
      debugPrint('ChatRepository.deleteMessage error: $error');
      debugPrint('ChatRepository.deleteMessage stack: $stackTrace');
      rethrow;
    }
  }

  // Mute/unmute conversation
  Future<void> toggleMuteConversation(
    String conversationId,
    bool isMuted,
  ) async {
    try {
      await _client
          .from('conversation_participants')
          .update({'is_muted': isMuted})
          .eq('conversation_id', conversationId)
          .eq('user_id', _client.auth.currentUser!.id);
    } catch (error, stackTrace) {
      debugPrint('ChatRepository.toggleMuteConversation error: $error');
      debugPrint('ChatRepository.toggleMuteConversation stack: $stackTrace');
      rethrow;
    }
  }

  // Archive/unarchive conversation
  Future<void> toggleArchiveConversation(
    String conversationId,
    bool isArchived,
  ) async {
    try {
      await _client
          .from('conversation_participants')
          .update({'is_archived': isArchived})
          .eq('conversation_id', conversationId)
          .eq('user_id', _client.auth.currentUser!.id);
    } catch (error, stackTrace) {
      debugPrint('ChatRepository.toggleArchiveConversation error: $error');
      debugPrint('ChatRepository.toggleArchiveConversation stack: $stackTrace');
      rethrow;
    }
  }

  // Get total unread count
  Future<int> getTotalUnreadCount() async {
    try {
      final response = await _client
          .from('conversation_participants')
          .select('unread_count')
          .eq('user_id', _client.auth.currentUser!.id);

      int total = 0;
      for (final item in response) {
        total += (item['unread_count'] as int?) ?? 0;
      }
      return total;
    } catch (error, stackTrace) {
      debugPrint('ChatRepository.getTotalUnreadCount error: $error');
      debugPrint('ChatRepository.getTotalUnreadCount stack: $stackTrace');
      return 0;
    }
  }
}
