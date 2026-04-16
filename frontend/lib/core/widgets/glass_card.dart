import 'dart:ui';

import 'package:flutter/material.dart';

class GlassCard extends StatelessWidget {
  const GlassCard({
    required this.child,
    super.key,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = const BorderRadius.all(Radius.circular(24)),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            color: Colors.white.withValues(alpha: 0.62),
            border: Border.all(color: Colors.white.withValues(alpha: 0.75)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF9CB4D8).withValues(alpha: 0.18),
                offset: const Offset(0, 18),
                blurRadius: 36,
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
