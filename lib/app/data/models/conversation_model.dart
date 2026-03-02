import 'user_model.dart';

class ConversationModel {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastMessageAt;
  final String? lastMessageText;
  final String? lastMessageType;
  final int unreadCount;
  final bool isMuted;
  final bool isArchived;
  final DateTime? lastReadAt;
  final List<UserModel> otherParticipants;

  ConversationModel({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.lastMessageAt,
    this.lastMessageText,
    this.lastMessageType,
    required this.unreadCount,
    required this.isMuted,
    required this.isArchived,
    this.lastReadAt,
    required this.otherParticipants,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    final otherParticipantsJson = json['other_participants'] as List?;
    final otherParticipants =
        otherParticipantsJson
            ?.map((p) => UserModel.fromJson(p as Map<String, dynamic>))
            .toList() ??
        [];

    return ConversationModel(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.parse(json['last_message_at'] as String)
          : null,
      lastMessageText: json['last_message_text'] as String?,
      lastMessageType: json['last_message_type'] as String?,
      unreadCount: json['unread_count'] as int? ?? 0,
      isMuted: json['is_muted'] as bool? ?? false,
      isArchived: json['is_archived'] as bool? ?? false,
      lastReadAt: json['last_read_at'] != null
          ? DateTime.parse(json['last_read_at'] as String)
          : null,
      otherParticipants: otherParticipants,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'last_message_at': lastMessageAt?.toIso8601String(),
      'last_message_text': lastMessageText,
      'last_message_type': lastMessageType,
      'unread_count': unreadCount,
      'is_muted': isMuted,
      'is_archived': isArchived,
      'last_read_at': lastReadAt?.toIso8601String(),
      'other_participants': otherParticipants.map((p) => p.toJson()).toList(),
    };
  }

  ConversationModel copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastMessageAt,
    String? lastMessageText,
    String? lastMessageType,
    int? unreadCount,
    bool? isMuted,
    bool? isArchived,
    DateTime? lastReadAt,
    List<UserModel>? otherParticipants,
  }) {
    return ConversationModel(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      lastMessageText: lastMessageText ?? this.lastMessageText,
      lastMessageType: lastMessageType ?? this.lastMessageType,
      unreadCount: unreadCount ?? this.unreadCount,
      isMuted: isMuted ?? this.isMuted,
      isArchived: isArchived ?? this.isArchived,
      lastReadAt: lastReadAt ?? this.lastReadAt,
      otherParticipants: otherParticipants ?? this.otherParticipants,
    );
  }

  // Helper to get other user in 1-on-1 chat
  UserModel? get otherUser =>
      otherParticipants.isNotEmpty ? otherParticipants.first : null;

  // Helper to get display name
  String get displayName {
    if (otherParticipants.isEmpty) return 'Unknown';
    if (otherParticipants.length == 1) {
      return otherParticipants.first.name.isNotEmpty
          ? otherParticipants.first.name
          : otherParticipants.first.username;
    }
    return otherParticipants.map((u) => u.username).join(', ');
  }

  // Helper to get avatar URL
  String? get avatarUrl =>
      otherParticipants.isNotEmpty ? otherParticipants.first.avatarUrl : null;
}
