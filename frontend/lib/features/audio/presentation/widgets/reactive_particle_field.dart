import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class ReactiveParticleField extends StatefulWidget {
  const ReactiveParticleField({
    required this.intensity,
    super.key,
  });

  final double intensity;

  @override
  State<ReactiveParticleField> createState() => _ReactiveParticleFieldState();
}

class _ReactiveParticleFieldState extends State<ReactiveParticleField>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          painter: _ParticlePainter(
            intensity: widget.intensity,
            progress: _controller.value,
          ),
        );
      },
    );
  }
}

class _ParticlePainter extends CustomPainter {
  _ParticlePainter({
    required this.intensity,
    required this.progress,
  });

  final double intensity;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final count = 18 + (intensity * 30).round();
    final speed = 0.25 + (intensity * 1.6);

    for (int i = 0; i < count; i++) {
      final seed = i * 0.6180339887;
      final x = (seed * size.width * 1.97) % size.width;
      final localPhase = (progress * speed + (i * 0.07)) % 1.0;
      final y = size.height - (localPhase * size.height);
      final wobble = math.sin((progress * math.pi * 2) + i) * (4 + 10 * intensity);
      final radius = 1.2 + (intensity * 2.6) + ((i % 3) * 0.35);

      final color = Color.lerp(
        AppTheme.antiqueBrass.withValues(alpha: 0.14),
        AppTheme.tan.withValues(alpha: 0.24),
        (i % 10) / 10,
      )!;

      canvas.drawCircle(
        Offset((x + wobble).clamp(0.0, size.width), y),
        radius,
        Paint()..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) {
    return oldDelegate.intensity != intensity || oldDelegate.progress != progress;
  }
}
