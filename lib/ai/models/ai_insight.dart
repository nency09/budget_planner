/// Data model for AI-generated spending insights.
class AIInsight {
  final String summary;
  final List<InsightItem> insights;
  final String topTip;
  final DateTime generatedAt;

  AIInsight({
    required this.summary,
    required this.insights,
    required this.topTip,
    DateTime? generatedAt,
  }) : generatedAt = generatedAt ?? DateTime.now();

  factory AIInsight.fromJson(Map<String, dynamic> json) {
    return AIInsight(
      summary: json['summary'] as String? ?? '',
      insights: (json['insights'] as List<dynamic>?)
              ?.map((e) => InsightItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      topTip: json['topTip'] as String? ?? '',
      generatedAt: json['generatedAt'] != null
          ? DateTime.parse(json['generatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'summary': summary,
        'insights': insights.map((e) => e.toJson()).toList(),
        'topTip': topTip,
        'generatedAt': generatedAt.toIso8601String(),
      };
}

class InsightItem {
  final String title;
  final String description;
  final InsightType type;
  final String icon;

  InsightItem({
    required this.title,
    required this.description,
    required this.type,
    required this.icon,
  });

  factory InsightItem.fromJson(Map<String, dynamic> json) {
    return InsightItem(
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      type: InsightType.fromString(json['type'] as String? ?? 'tip'),
      icon: json['icon'] as String? ?? '💡',
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'type': type.value,
        'icon': icon,
      };
}

enum InsightType {
  warning('warning'),
  tip('tip'),
  achievement('achievement');

  final String value;
  const InsightType(this.value);

  static InsightType fromString(String value) {
    return InsightType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => InsightType.tip,
    );
  }
}
