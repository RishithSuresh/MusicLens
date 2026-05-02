import 'dart:ui';

import 'package:flutter/material.dart';

class GlassCard extends StatefulWidget {
  const GlassCard({
    required this.child,
    super.key,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = const BorderRadius.all(Radius.circular(28)),
    this.onHover,
    this.gradient,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;
  final VoidCallback? onHover;
  final LinearGradient? gradient;

  @override
  State<GlassCard> createState() => _GlassCardState();
}

class _GlassCardState extends State<GlassCard> with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _hoverAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _hoverAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  void _onHoverChange(bool isHovered) {
    setState(() => _isHovered = isHovered);
    if (isHovered) {
      _hoverController.forward();
      widget.onHover?.call();
    } else {
      _hoverController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _onHoverChange(true),
      onExit: (_) => _onHoverChange(false),
      child: AnimatedBuilder(
        animation: _hoverAnimation,
        builder: (context, _) {
          return Transform.scale(
            scale: _hoverAnimation.value,
            child: ClipRRect(
              borderRadius: widget.borderRadius,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  padding: widget.padding,
                  decoration: BoxDecoration(
                    borderRadius: widget.borderRadius,
                    gradient: widget.gradient != null
                        ? widget.gradient!
                        : LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withValues(alpha: 0.72),
                              Colors.white.withValues(alpha: 0.55),
                            ],
                          ),
                    border: Border.all(
                      color: Colors.white.withValues(
                        alpha: _isHovered ? 0.85 : 0.70,
                      ),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF3B82F6).withValues(alpha: _isHovered ? 0.25 : 0.12),
                        offset: const Offset(0, 12),
                        blurRadius: _isHovered ? 48 : 32,
                        spreadRadius: _isHovered ? 2 : 0,
                      ),
                      BoxShadow(
                        color: const Color(0xFF8B5CF6).withValues(alpha: _isHovered ? 0.15 : 0.08),
                        offset: const Offset(0, 20),
                        blurRadius: _isHovered ? 32 : 20,
                      ),
                    ],
                  ),
                  child: widget.child,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
