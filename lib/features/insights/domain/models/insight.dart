enum InsightImpact { low, medium, high }

enum InsightType { spending, saving, budget, subscription, trend }

class Insight {
  const Insight({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.impact,
    required this.createdAt,
    this.actionLabel,
    this.route,
    this.metadata,
    this.isRead = false,
  });

  final String id;
  final String title;
  final String description;
  final InsightType type;
  final InsightImpact impact;
  final DateTime createdAt;
  final String? actionLabel;
  final String? route;
  final Map<String, dynamic>? metadata;
  final bool isRead;
}
