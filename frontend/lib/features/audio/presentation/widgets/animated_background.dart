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
      duration: const Duration(seconds: 16),
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
        final wave = math.sin(_controller.value * math.pi * 2);
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFFFFFF),
                Color(0xFFF2F7FF),
                Color(0xFFF7F2FF),
              ],
            ),
          ),
          child: Stack(
            children: [
              _Blob(
                color: const Color(0xFF3B82F6).withValues(alpha: 0.22),
                left: 60 + (24 * wave),
                top: 80,
                size: 260,
              ),
              _Blob(
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.20),
                left: 420,
                top: 200 + (20 * wave),
                size: 300,
              ),
              _Blob(
                color: const Color(0xFFEC4899).withValues(alpha: 0.15),
                left: 180,
                top: 520 - (18 * wave),
                size: 240,
              ),
              Positioned.fill(
                child: CustomPaint(painter: _WavePatternPainter(progress: _controller.value)),
              ),
              widget.child,
            ],
          ),
        );
      },
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({
    required this.color,
    required this.left,
    required this.top,
    required this.size,
  });

  final Color color;
  final double left;
  final double top;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      top: top,
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 46, sigmaY: 46),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

class _WavePatternPainter extends CustomPainter {
  _WavePatternPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF3B82F6).withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    for (int row = 0; row < 5; row++) {
      final path = Path();
      final yBase = 120 + row * 130;
      for (double x = 0; x <= size.width; x += 8) {
        final y = yBase + math.sin((x / 72) + (progress * 2 * math.pi) + row) * 10;
        if (x == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WavePatternPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
