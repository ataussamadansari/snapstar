extension DateTimeExtension on DateTime {
  String get timeAgo {
    final Duration diff = DateTime.now().difference(this);

    if (diff.inDays > 365) {
      return "${(diff.inDays / 365).floor()}y ago";
    } else if (diff.inDays > 30) {
      return "${(diff.inDays / 30).floor()}mo ago";
    } else if (diff.inDays > 7) {
      return "${(diff.inDays / 7).floor()}w ago";
    } else if (diff.inDays >= 1) {
      return "${diff.inDays}d ago";
    } else if (diff.inHours >= 1) {
      return "${diff.inHours}h ago";
    } else if (diff.inMinutes >= 1) {
      return "${diff.inMinutes}m ago";
    } else {
      return "Just now";
    }
  }
}