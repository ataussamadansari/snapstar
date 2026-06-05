/// Caption se hashtags aur mentions extract karne ke liye helper
class HashtagHelper {
  // Caption se saare unique hashtags extract karo (# ke saath nahi, sirf tag)
  static List<String> extractHashtags(String caption) {
    final regex = RegExp(r'#([a-zA-Z0-9_]+)');
    final matches = regex.allMatches(caption);
    final tags = matches.map((m) => m.group(1)!.toLowerCase()).toSet().toList();
    return tags;
  }

  // Caption se saare unique mentions extract karo (@ ke saath nahi, sirf username)
  static List<String> extractMentions(String caption) {
    final regex = RegExp(r'@([a-zA-Z0-9_.]+)');
    final matches = regex.allMatches(caption);
    return matches.map((m) => m.group(1)!.toLowerCase()).toSet().toList();
  }
}
