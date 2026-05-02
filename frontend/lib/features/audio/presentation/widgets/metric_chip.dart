import 'package:flutter/material.dart';

class MetricChip extends StatefulWidget {
  const MetricChip({
    required this.label,
    required this.value,
    super.key,
    this.icon,
    this.color,
  });

  final String label;
  final String value;
  final IconData? icon;
  final Color? color;

  @override
  State<MetricChip> createState() => _MetricChipState();
}

class _MetricChipState extends State<MetricChip> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = widget.color ?? const Color(0xFF3B82F6);

    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _controller.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _controller.reverse();
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, _) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: _isHovered ? 0.90 : 0.80),
                    Colors.white.withValues(alpha: _isHovered ? 0.85 : 0.70),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: accentColor.withValues(
                    alpha: _isHovered ? 0.5 : 0.25,
                  ),
                  width: _isHovered ? 2 : 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withValues(alpha: _isHovered ? 0.25 : 0.10),
                    offset: const Offset(0, 8),
                    blurRadius: _isHovered ? 24 : 12,
                    spreadRadius: _isHovered ? 1 : 0,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.icon != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Icon(
                        widget.icon,
                        size: 18,
                        color: accentColor,
                      ),
                    ),
                  Text(
                    widget.label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      letterSpacing: 1.0,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 6),
                  ShaderMask(
                    shaderCallback: (bounds) {
                      return LinearGradient(
                        colors: [accentColor, accentColor.withValues(alpha: 0.8)],
                      ).createShader(bounds);
                    },
                    child: Text(
                      widget.value,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
