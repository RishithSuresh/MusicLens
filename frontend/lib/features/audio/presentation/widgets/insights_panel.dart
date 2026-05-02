import 'package:flutter/material.dart';

import '../../data/analysis_models.dart';
import '../../../../core/widgets/glass_card.dart';

class InsightsPanel extends StatefulWidget {
  const InsightsPanel({
    required this.currentInsight,
    required this.insights,
    required this.categorizedInsights,
    required this.currentTime,
    required this.totalDuration,
    super.key,
  });

  final String currentInsight;
  final List<String> insights;
  final List<CategorizedInsight> categorizedInsights;
  final double currentTime;
  final double totalDuration;

  @override
  State<InsightsPanel> createState() => _InsightsPanelState();
}

class _InsightsPanelState extends State<InsightsPanel> {
  String? _selectedCategory;

  static const List<String> _categories = ['All', 'rhythm', 'energy', 'melody', 'structure'];

  List<CategorizedInsight> _getFilteredInsights() {
    if (_selectedCategory == null || _selectedCategory == 'All') {
      return widget.categorizedInsights;
    }
    return widget.categorizedInsights
        .where((insight) => insight.category == _selectedCategory)
        .toList();
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'rhythm':
        return const Color(0xFFEF4444); // red
      case 'energy':
        return const Color(0xFFFBBF24); // amber
      case 'melody':
        return const Color(0xFF8B5CF6); // violet
      case 'structure':
        return const Color(0xFF3B82F6); // blue
      default:
        return const Color(0xFF64748B); // slate
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filteredInsights = _getFilteredInsights();

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
            widget.currentInsight,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: widget.totalDuration <= 0 ? 0 : (widget.currentTime / widget.totalDuration).clamp(0.0, 1.0),
            minHeight: 6,
            borderRadius: BorderRadius.circular(99),
            backgroundColor: const Color(0xFFE2E8F0),
          ),
          const SizedBox(height: 8),
          Text(
            'Timeline ${widget.currentTime.toStringAsFixed(2)}s / ${widget.totalDuration.toStringAsFixed(2)}s',
            style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFF64748B)),
          ),

          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _categories.map((category) {
                final isSelected = _selectedCategory == category || (_selectedCategory == null && category == 'All');
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = selected && category != 'All' ? category : null;
                      });
                    },
                    label: Text(category),
                    backgroundColor: Colors.white.withValues(alpha: 0.5),
                    selectedColor: _getCategoryColor(category).withValues(alpha: 0.3),
                    side: BorderSide(
                      color: isSelected ? _getCategoryColor(category) : const Color(0xFFD8E4F5),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: filteredInsights
                .map(
                  (insight) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: _getCategoryColor(insight.category).withValues(alpha: 0.15),
                      border: Border.all(color: _getCategoryColor(insight.category).withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _getCategoryColor(insight.category),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            insight.text,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(growable: false),
          ),
        ],
      ),
    );
  }
}
