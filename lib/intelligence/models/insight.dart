enum InsightSeverity { low, medium, high }

enum InsightType { anomaly, forecast, recommendation }

class Insight {
  final String id;
  final String title;
  final String explanation;
  final String impact;
  final String action;
  final double confidence;
  final InsightSeverity severity;
  final InsightType type;

  const Insight({
    required this.id,
    required this.title,
    required this.explanation,
    required this.impact,
    required this.action,
    required this.confidence,
    required this.severity,
    required this.type,
  });
}
