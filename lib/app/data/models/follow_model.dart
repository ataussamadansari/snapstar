class FollowModel {
  final String id;
  final String followerId;
  final String followingId;
  final String status; // pending | accepted
  final DateTime createdAt;

  FollowModel({
    required this.id,
    required this.followerId,
    required this.followingId,
    required this.status,
    required this.createdAt,
  });

  factory FollowModel.fromJson(Map<String, dynamic> json) {
    return FollowModel(
      id: json['id'],
      followerId: json['follower_id'],
      followingId: json['following_id'],
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'follower_id': followerId,
      'following_id': followingId,
      'status': status,
    };
  }
}
