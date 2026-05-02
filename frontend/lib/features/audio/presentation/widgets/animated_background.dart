import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

class AnimatedBackground extends StatefulWidget {
  const AnimatedBackground({required this.child, super.key});

  final Widget child;

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
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
      child: RepaintBoundary(child: widget.child),
      builder: (context, child) {
        final wave1 = math.sin(_controller.value * math.pi * 2);
        final wave2 = math.cos(_controller.value * math.pi * 2 + math.pi / 3);
        final wave3 = math.sin(_controller.value * math.pi * 2 + math.pi * 2 / 3);

        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFAFBFC),
                Color(0xFFF0F4FF),
                Color(0xFFFAF5FF),
                Color(0xFFF5FEFF),
              ],
              stops: [0.0, 0.33, 0.66, 1.0],
            ),
          ),
          child: Stack(
            children: [
              // Enhanced blob system with multiple layers
              _AnimatedBlob(
                color: const Color(0xFF3B82F6),
                left: 40 + (40 * wave1),
                top: 60,
                size: 280,
                blur: 42,
                opacity: 0.20,
              ),
              _AnimatedBlob(
                color: const Color(0xFF8B5CF6),
                left: 380 + (50 * wave2),
                top: 180 + (30 * wave1),
                size: 320,
                blur: 46,
                opacity: 0.18,
              ),
              _AnimatedBlob(
                color: const Color(0xFFEC4899),
                left: 150 + (45 * wave3),
                top: 520 - (40 * wave2),
                size: 260,
                blur: 40,
                opacity: 0.16,
              ),
              _AnimatedBlob(
                color: const Color(0xFF06B6D4),
                left: 600 + (35 * wave1),
                top: 400 + (25 * wave3),
                size: 240,
                blur: 38,
                opacity: 0.14,
              ),
              // Wave pattern overlay
              Positioned.fill(
                child: CustomPaint(
                  painter: _EnhancedWavePatternPainter(
                    progress: _controller.value,
                    wave1: wave1,
                    wave2: wave2,
                  ),
                ),
              ),
              // Mesh grid overlay
              Positioned.fill(
                child: CustomPaint(
                  painter: _MeshGridPainter(progress: _controller.value),
                ),
              ),
              if (child != null) child,
            ],
          ),
        );
      },
    );
  }
}

class _AnimatedBlob extends StatelessWidget {
  const _AnimatedBlob({
    required this.color,
    required this.left,
    required this.top,
    required this.size,
    required this.blur,
    required this.opacity,
  });

  final Color color;
  final double left;
  final double top;
  final double size;
  final double blur;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      top: top,
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: [
                color.withValues(alpha: opacity),
                color.withValues(alpha: opacity * 0.5),
                color.withValues(alpha: 0.0),
              ],
            ),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

class _EnhancedWavePatternPainter extends CustomPainter {
  _EnhancedWavePatternPainter({
    required this.progress,
    required this.wave1,
    required this.wave2,
  });

  final double progress;
  final double wave1;
  final double wave2;

  @override
  void paint(Canvas canvas, Size size) {
    // Primary wave pattern
    final paint1 = Paint()
      ..color = const Color(0xFF3B82F6).withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    // Secondary wave pattern
    final paint2 = Paint()
      ..color = const Color(0xFF8B5CF6).withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (int row = 0; row < 6; row++) {
      // Primary waves
      final path1 = Path();
      final yBase1 = 100 + row * 120;
      for (double x = 0; x <= size.width; x += 6) {
        final y = yBase1 +
            math.sin((x / 60) + (progress * 2 * math.pi) + row) * 12 +
            math.cos((x / 80) + (progress * math.pi) + row * 0.5) * 6;
        if (x == 0) {
          path1.moveTo(x, y);
        } else {
          path1.lineTo(x, y);
        }
      }
      canvas.drawPath(path1, paint1);

      // Secondary offset waves
      final path2 = Path();
      final yBase2 = 115 + row * 120;
      for (double x = 0; x <= size.width; x += 8) {
        final y = yBase2 +
            math.sin((x / 70) + (progress * 2 * math.pi) + row + math.pi / 2) * 8;
        if (x == 0) {
          path2.moveTo(x, y);
        } else {
          path2.lineTo(x, y);
        }
      }
      canvas.drawPath(path2, paint2);
    }
  }

  @override
  bool shouldRepaint(covariant _EnhancedWavePatternPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.wave1 != wave1 ||
        oldDelegate.wave2 != wave2;
  }
}

class _MeshGridPainter extends CustomPainter {
  _MeshGridPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF3B82F6).withValues(alpha: 0.04)
      ..strokeWidth = 0.8;

    const gridSize = 120.0;
    final offset = (progress * 60) % gridSize;

    // Vertical lines
    for (double x = -gridSize + offset; x < size.width; x += gridSize) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    // Horizontal lines
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MeshGridPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
