/// Data model for AI-predicted spending.
class SpendingPrediction {
  final double predictedTotal;
  final double confidence; // 0.0 - 1.0
  final List<CategoryPrediction> byCategory;
  final String? warning;
  final DateTime generatedAt;

  SpendingPrediction({
    required this.predictedTotal,
    required this.confidence,
    required this.byCategory,
    this.warning,
    DateTime? generatedAt,
  }) : generatedAt = generatedAt ?? DateTime.now();

  factory SpendingPrediction.fromJson(Map<String, dynamic> json) {
    return SpendingPrediction(
      predictedTotal: (json['predictedTotal'] as num?)?.toDouble() ?? 0,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
      byCategory: (json['byCategory'] as List<dynamic>?)
              ?.map(
                  (e) => CategoryPrediction.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      warning: json['warning'] as String?,
      generatedAt: json['generatedAt'] != null
          ? DateTime.parse(json['generatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'predictedTotal': predictedTotal,
        'confidence': confidence,
        'byCategory': byCategory.map((e) => e.toJson()).toList(),
        'warning': warning,
        'generatedAt': generatedAt.toIso8601String(),
      };
}

class CategoryPrediction {
  final String name;
  final double predicted;
  final SpendingTrend trend;

  CategoryPrediction({
    required this.name,
    required this.predicted,
    required this.trend,
  });

  factory CategoryPrediction.fromJson(Map<String, dynamic> json) {
    return CategoryPrediction(
      name: json['name'] as String? ?? '',
      predicted: (json['predicted'] as num?)?.toDouble() ?? 0,
      trend: SpendingTrend.fromString(json['trend'] as String? ?? 'stable'),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'predicted': predicted,
        'trend': trend.value,
      };
}

enum SpendingTrend {
  up('up'),
  down('down'),
  stable('stable');

  final String value;
  const SpendingTrend(this.value);

  static SpendingTrend fromString(String value) {
    return SpendingTrend.values.firstWhere(
      (e) => e.value == value,
      orElse: () => SpendingTrend.stable,
    );
  }
}

/// Helper model for passing monthly data to predictions.
class MonthlySpendingSummary {
  final String monthName;
  final double total;

  MonthlySpendingSummary({
    required this.monthName,
    required this.total,
  });
}
