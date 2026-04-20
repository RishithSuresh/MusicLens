import 'package:flutter/material.dart';

import '../../../../core/widgets/glass_card.dart';

class InsightsPanel extends StatelessWidget {
  const InsightsPanel({
    required this.currentInsight,
    required this.insights,
    required this.currentTime,
    required this.totalDuration,
    super.key,
  });

  final String currentInsight;
  final List<String> insights;
  final double currentTime;
  final double totalDuration;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "What's happening now?",
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            currentInsight,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: totalDuration <= 0 ? 0 : (currentTime / totalDuration).clamp(0.0, 1.0),
            minHeight: 6,
            borderRadius: BorderRadius.circular(99),
            backgroundColor: const Color(0xFFE2E8F0),
          ),
          const SizedBox(height: 8),
          Text(
            'Timeline ${currentTime.toStringAsFixed(2)}s / ${totalDuration.toStringAsFixed(2)}s',
            style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFF64748B)),
          ),

          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: insights
                .map(
                  (item) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: Colors.white.withValues(alpha: 0.8),
                      border: Border.all(color: const Color(0xFFD8E4F5)),
                    ),
                    child: Text(item, style: theme.textTheme.bodyMedium),
                  ),
                )
                .toList(growable: false),
          ),
        ],
      ),
    );
  }
}
