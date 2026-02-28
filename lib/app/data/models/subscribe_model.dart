class SubscribeModel {
  final String id;
  final String subscriberId;   // jisne subscribe kiya
  final String subscribedId;   // jisko subscribe kiya
  final DateTime createdAt;
  final DateTime updatedAt;

  SubscribeModel({
    required this.id,
    required this.subscriberId,
    required this.subscribedId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SubscribeModel.fromJson(Map<String, dynamic> json) {
    return SubscribeModel(
      id: json['id'],
      subscriberId: json['subscriber_id'],
      subscribedId: json['subscribed_id'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'subscriber_id': subscriberId,
      'subscribed_id': subscribedId,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
  }
}
