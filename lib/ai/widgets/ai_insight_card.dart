import 'package:budget/ai/models/ai_insight.dart';
import 'package:flutter/material.dart';

/// Card widget for displaying a single AI insight.
class AIInsightCard extends StatelessWidget {
  final InsightItem insight;
  final VoidCallback? onTap;

  const AIInsightCard({
    required this.insight,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _getBackgroundColor(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _getBorderColor(context),
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              insight.icon,
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          insight.title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                      _buildTypeBadge(context),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    insight.description,
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeBadge(BuildContext context) {
    String label;
    Color color;

    switch (insight.type) {
      case InsightType.warning:
        label = 'Warning';
        color = Colors.orange;
        break;
      case InsightType.achievement:
        label = 'Achievement';
        color = Colors.green;
        break;
      case InsightType.tip:
        label = 'Tip';
        color = Colors.blue;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Color _getBackgroundColor(BuildContext context) {
    switch (insight.type) {
      case InsightType.warning:
        return Colors.orange.withOpacity(0.05);
      case InsightType.achievement:
        return Colors.green.withOpacity(0.05);
      case InsightType.tip:
        return Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3);
    }
  }

  Color _getBorderColor(BuildContext context) {
    switch (insight.type) {
      case InsightType.warning:
        return Colors.orange.withOpacity(0.2);
      case InsightType.achievement:
        return Colors.green.withOpacity(0.2);
      case InsightType.tip:
        return Theme.of(context).colorScheme.outline.withOpacity(0.15);
    }
  }
}

/// Widget for showing the weekly insights summary header.
class AIInsightsSummary extends StatelessWidget {
  final AIInsight insight;

  const AIInsightsSummary({required this.insight, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.tertiaryContainer,
            Theme.of(context).colorScheme.secondaryContainer,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                size: 18,
                color: Theme.of(context).colorScheme.onTertiaryContainer,
              ),
              const SizedBox(width: 8),
              Text(
                'Weekly Summary',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onTertiaryContainer,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            insight.summary,
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context)
                  .colorScheme
                  .onTertiaryContainer
                  .withOpacity(0.9),
            ),
          ),
          if (insight.topTip.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .onTertiaryContainer
                    .withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Text('💡', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      insight.topTip,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context)
                            .colorScheme
                            .onTertiaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
