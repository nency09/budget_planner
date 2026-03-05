/// Data model for AI-calculated financial health score.
class FinancialScore {
  final int score; // 0-100
  final String grade; // A+, A, B+, B, C+, C, D, F
  final ScoreBreakdown breakdown;
  final String advice;
  final DateTime generatedAt;

  FinancialScore({
    required this.score,
    required this.grade,
    required this.breakdown,
    required this.advice,
    DateTime? generatedAt,
  }) : generatedAt = generatedAt ?? DateTime.now();

  factory FinancialScore.fromJson(Map<String, dynamic> json) {
    return FinancialScore(
      score: (json['score'] as num?)?.toInt() ?? 0,
      grade: json['grade'] as String? ?? 'N/A',
      breakdown:
          ScoreBreakdown.fromJson(json['breakdown'] as Map<String, dynamic>),
      advice: json['advice'] as String? ?? '',
      generatedAt: json['generatedAt'] != null
          ? DateTime.parse(json['generatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'score': score,
        'grade': grade,
        'breakdown': breakdown.toJson(),
        'advice': advice,
        'generatedAt': generatedAt.toIso8601String(),
      };
}

class ScoreBreakdown {
  final ScoreComponent savingsScore;
  final ScoreComponent budgetScore;
  final ScoreComponent diversityScore;
  final ScoreComponent commitmentScore;
  final ScoreComponent consistencyScore;

  ScoreBreakdown({
    required this.savingsScore,
    required this.budgetScore,
    required this.diversityScore,
    required this.commitmentScore,
    required this.consistencyScore,
  });

  factory ScoreBreakdown.fromJson(Map<String, dynamic> json) {
    return ScoreBreakdown(
      savingsScore: ScoreComponent.fromJson(
          json['savingsScore'] as Map<String, dynamic>? ?? {}),
      budgetScore: ScoreComponent.fromJson(
          json['budgetScore'] as Map<String, dynamic>? ?? {}),
      diversityScore: ScoreComponent.fromJson(
          json['diversityScore'] as Map<String, dynamic>? ?? {}),
      commitmentScore: ScoreComponent.fromJson(
          json['commitmentScore'] as Map<String, dynamic>? ?? {}),
      consistencyScore: ScoreComponent.fromJson(
          json['consistencyScore'] as Map<String, dynamic>? ?? {}),
    );
  }

  Map<String, dynamic> toJson() => {
        'savingsScore': savingsScore.toJson(),
        'budgetScore': budgetScore.toJson(),
        'diversityScore': diversityScore.toJson(),
        'commitmentScore': commitmentScore.toJson(),
        'consistencyScore': consistencyScore.toJson(),
      };
}

class ScoreComponent {
  final int value;
  final int max;
  final String tip;

  ScoreComponent({
    required this.value,
    required this.max,
    required this.tip,
  });

  factory ScoreComponent.fromJson(Map<String, dynamic> json) {
    return ScoreComponent(
      value: (json['value'] as num?)?.toInt() ?? 0,
      max: (json['max'] as num?)?.toInt() ?? 0,
      tip: json['tip'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'value': value,
        'max': max,
        'tip': tip,
      };

  double get percentage => max > 0 ? value / max : 0;
}
