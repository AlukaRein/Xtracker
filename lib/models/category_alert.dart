enum AlertSeverity {
  warning, // 80% - 99% of limit or dominant category
  exceeded, // >= 100% of limit
}

class CategoryAlert {
  final String category;
  final double currentSpent;
  final double limit;
  final AlertSeverity severity;
  final String message;

  const CategoryAlert({
    required this.category,
    required this.currentSpent,
    required this.limit,
    required this.severity,
    required this.message,
  });

  double get percent => limit > 0 ? (currentSpent / limit) : 1.0;
  bool get isExceeded => severity == AlertSeverity.exceeded;
}
