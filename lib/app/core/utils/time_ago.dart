class TimeAgo {
  static String format(DateTime date) {
    final now = DateTime.now();

    /// If database time is UTC, convert to local once
    final postDate = date.isUtc ? date.toLocal() : date;

    final diff = now.difference(postDate);

    /// Future time protection (clock mismatch fix)
    if (diff.isNegative) return "just now";

    if (diff.inSeconds < 60) {
      return "just now";
    } else if (diff.inMinutes < 60) {
      return "${diff.inMinutes}m";
    } else if (diff.inHours < 24) {
      return "${diff.inHours}h";
    } else if (diff.inDays < 7) {
      return "${diff.inDays}d";
    } else if (diff.inDays < 30) {
      return "${(diff.inDays / 7).floor()}w";
    } else if (diff.inDays < 365) {
      return "${(diff.inDays / 30).floor()}mo";
    } else {
      return "${(diff.inDays / 365).floor()}y";
    }
  }
}
