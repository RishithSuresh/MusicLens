import 'package:flutter/material.dart';

import '../../data/analysis_models.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/theme/app_theme.dart';

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

class _InsightsPanelState extends State<InsightsPanel> with SingleTickerProviderStateMixin {
  String? _selectedCategory;
  late AnimationController _insightController;

  static const List<String> _categories = ['All', 'rhythm', 'energy', 'melody', 'structure'];

  @override
  void initState() {
    super.initState();
    _insightController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..forward();
  }

  @override
  void didUpdateWidget(InsightsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentInsight != widget.currentInsight) {
      _insightController.reset();
      _insightController.forward();
    }
  }

  @override
  void dispose() {
    _insightController.dispose();
    super.dispose();
  }

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
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.75),
          Colors.white.withValues(alpha: 0.60),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "What's happening now?",
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 14),
          FadeTransition(
            opacity: Tween<double>(begin: 0.7, end: 1.0).animate(_insightController),
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.95, end: 1.0).animate(_insightController),
              child: Text(
                widget.currentInsight,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: widget.totalDuration <= 0 ? 0 : (widget.currentTime / widget.totalDuration).clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(
                AppTheme.primaryGradient.colors.first,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Timeline ${widget.currentTime.toStringAsFixed(2)}s / ${widget.totalDuration.toStringAsFixed(2)}s',
            style: theme.textTheme.bodySmall?.copyWith(
              color: const Color(0xFF64748B),
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
            ),
          ),

          const SizedBox(height: 16),
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
                    label: Text(
                      category,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isSelected ? _getCategoryColor(category) : const Color(0xFF64748B),
                      ),
                    ),
                    backgroundColor: Colors.white.withValues(alpha: 0.6),
                    selectedColor: _getCategoryColor(category).withValues(alpha: 0.2),
                    side: BorderSide(
                      color: isSelected ? _getCategoryColor(category) : const Color(0xFFD8E4F5),
                      width: isSelected ? 2.5 : 1.5,
                    ),
                    elevation: isSelected ? 4 : 0,
                    pressElevation: 8,
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 14),
          if (filteredInsights.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'No insights in this category',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF94A3B8),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            )
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: filteredInsights
                  .asMap()
                  .entries
                  .map(
                    (entry) {
                      final insight = entry.value;
                      final index = entry.key;
                      return _InsightBubble(
                        insight: insight,
                        categoryColor: _getCategoryColor(insight.category),
                        animationDelay: Duration(milliseconds: 100 * index),
                      );
                    },
                  )
                  .toList(growable: false),
            ),
        ],
      ),
    );
  }
}

class _InsightBubble extends StatefulWidget {
  const _InsightBubble({
    required this.insight,
    required this.categoryColor,
    required this.animationDelay,
  });

  final CategorizedInsight insight;
  final Color categoryColor;
  final Duration animationDelay;

  @override
  State<_InsightBubble> createState() => _InsightBubbleState();
}

class _InsightBubbleState extends State<_InsightBubble> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _slideAnimation = Tween<double>(begin: -20, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    Future.delayed(widget.animationDelay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Transform.translate(
        offset: Offset(_slideAnimation.value, 0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                widget.categoryColor.withValues(alpha: 0.18),
                widget.categoryColor.withValues(alpha: 0.08),
              ],
            ),
            border: Border.all(
              color: widget.categoryColor.withValues(alpha: 0.45),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.categoryColor.withValues(alpha: 0.15),
                offset: const Offset(0, 4),
                blurRadius: 12,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.categoryColor,
                  boxShadow: [
                    BoxShadow(
                      color: widget.categoryColor.withValues(alpha: 0.6),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  widget.insight.text,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF1E293B),
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
