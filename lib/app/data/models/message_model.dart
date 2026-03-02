import 'user_model.dart';

enum MessageType {
  text,
  image,
  video,
  post,
  reel,
  story;

  static MessageType fromString(String value) {
    return MessageType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => MessageType.text,
    );
  }
}

class MessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final MessageType messageType;
  final String? messageText;
  final String? mediaUrl;
  final String? thumbnailUrl;
  final String? sharedPostId;
  final String? sharedPostCaption;
  final String? sharedPostMediaUrl;
  final String? sharedPostThumbnailUrl;
  final String? sharedPostUserId;
  final bool isDeleted;
  final DateTime createdAt;
  final DateTime updatedAt;
  final UserModel? sender;
  final UserModel? sharedPostUser;

  MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.messageType,
    this.messageText,
    this.mediaUrl,
    this.thumbnailUrl,
    this.sharedPostId,
    this.sharedPostCaption,
    this.sharedPostMediaUrl,
    this.sharedPostThumbnailUrl,
    this.sharedPostUserId,
    required this.isDeleted,
    required this.createdAt,
    required this.updatedAt,
    this.sender,
    this.sharedPostUser,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as String,
      conversationId: json['conversation_id'] as String,
      senderId: json['sender_id'] as String,
      messageType: MessageType.fromString(json['message_type'] as String),
      messageText: json['message_text'] as String?,
      mediaUrl: json['media_url'] as String?,
      thumbnailUrl: json['thumbnail_url'] as String?,
      sharedPostId: json['shared_post_id'] as String?,
      sharedPostCaption: json['shared_post_caption'] as String?,
      sharedPostMediaUrl: json['shared_post_media_url'] as String?,
      sharedPostThumbnailUrl: json['shared_post_thumbnail_url'] as String?,
      sharedPostUserId: json['shared_post_user_id'] as String?,
      isDeleted: json['is_deleted'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      sender: json['sender'] != null
          ? UserModel.fromJson(json['sender'] as Map<String, dynamic>)
          : null,
      sharedPostUser: json['shared_post_user'] != null
          ? UserModel.fromJson(json['shared_post_user'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'sender_id': senderId,
      'message_type': messageType.name,
      'message_text': messageText,
      'media_url': mediaUrl,
      'thumbnail_url': thumbnailUrl,
      'shared_post_id': sharedPostId,
      'shared_post_caption': sharedPostCaption,
      'shared_post_media_url': sharedPostMediaUrl,
      'shared_post_thumbnail_url': sharedPostThumbnailUrl,
      'shared_post_user_id': sharedPostUserId,
      'is_deleted': isDeleted,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      if (sender != null) 'sender': sender!.toJson(),
      if (sharedPostUser != null) 'shared_post_user': sharedPostUser!.toJson(),
    };
  }

  MessageModel copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    MessageType? messageType,
    String? messageText,
    String? mediaUrl,
    String? thumbnailUrl,
    String? sharedPostId,
    String? sharedPostCaption,
    String? sharedPostMediaUrl,
    String? sharedPostThumbnailUrl,
    String? sharedPostUserId,
    bool? isDeleted,
    DateTime? createdAt,
    DateTime? updatedAt,
    UserModel? sender,
    UserModel? sharedPostUser,
  }) {
    return MessageModel(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      messageType: messageType ?? this.messageType,
      messageText: messageText ?? this.messageText,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      sharedPostId: sharedPostId ?? this.sharedPostId,
      sharedPostCaption: sharedPostCaption ?? this.sharedPostCaption,
      sharedPostMediaUrl: sharedPostMediaUrl ?? this.sharedPostMediaUrl,
      sharedPostThumbnailUrl:
          sharedPostThumbnailUrl ?? this.sharedPostThumbnailUrl,
      sharedPostUserId: sharedPostUserId ?? this.sharedPostUserId,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      sender: sender ?? this.sender,
      sharedPostUser: sharedPostUser ?? this.sharedPostUser,
    );
  }

  bool get isSharedContent =>
      messageType == MessageType.post || messageType == MessageType.reel;
}
