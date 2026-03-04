class CursorPage<T> {
  const CursorPage({
    required this.items,
    required this.nextCursorCreatedAt,
    required this.nextCursorId,
    this.nextCursorScore,
    required this.hasMore,
  });

  final List<T> items;
  final DateTime? nextCursorCreatedAt;
  final String? nextCursorId;
  final double? nextCursorScore;
  final bool hasMore;
}
