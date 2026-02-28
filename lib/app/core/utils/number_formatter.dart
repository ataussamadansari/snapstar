class NumberFormatter {
  static String format(int value) {
    if (value < 1000) {
      return value.toString();
    }

    if (value < 1000000) {
      final v = value / 1000;
      return "${_trim(v)}K";
    }

    if (value < 1000000000) {
      final v = value / 1000000;
      return "${_trim(v)}M";
    }

    final v = value / 1000000000;
    return "${_trim(v)}B";
  }

  static String _trim(double value) {
    // 1.0 -> 1 , 1.5 -> 1.5
    return value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1);
  }
}
