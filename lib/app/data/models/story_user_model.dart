import 'story_model.dart';

class StoryUserModel {
  final String userId;
  final String userName;
  final String? avatarUrl;
  final List<StoryModel> stories;
  final bool hasUnseen;

  StoryUserModel({
    required this.userId,
    required this.userName,
    this.avatarUrl,
    required this.stories,
    required this.hasUnseen,
  });
}
