class StoryViewModel {
  final String id;
  final String storyId;
  final String viewerId;
  final DateTime createdAt;

  StoryViewModel({
    required this.id,
    required this.storyId,
    required this.viewerId,
    required this.createdAt,
  });

  factory StoryViewModel.fromJson(Map<String, dynamic> json) {
    return StoryViewModel(
      id: json['id'],
      storyId: json['story_id'],
      viewerId: json['viewer_id'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'story_id': storyId,
      'viewer_id': viewerId,
    };
  }
}
