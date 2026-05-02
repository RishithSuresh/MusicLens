import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/widgets/glass_card.dart';

class SpectrumPanel extends StatelessWidget {
  const SpectrumPanel({
    required this.magnitudes,
    required this.energy,
    super.key,
  });

  final List<double> magnitudes;
  final double energy;

  @override
  Widget build(BuildContext context) {
    final fallback = List<double>.generate(64, (index) => 0.4 + 0.4 * math.sin(index / 4).abs());
    final values = magnitudes.isEmpty ? fallback : magnitudes;

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
            'Frequency Spectrum',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 180,
            width: double.infinity,
            child: CustomPaint(
              painter: _SpectrumPainter(values: values, energy: energy),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpectrumPainter extends CustomPainter {
  _SpectrumPainter({required this.values, required this.energy});

  final List<double> values;
  final double energy;

  @override
  void paint(Canvas canvas, Size size) {
    final barWidth = size.width / (values.length * 1.3);
    final gap = barWidth * 0.3;
    final glow = (0.3 + energy * 0.7).clamp(0.3, 1.0);

    // Draw background grid
    final gridPaint = Paint()
      ..color = const Color(0xFF3B82F6).withValues(alpha: 0.05)
      ..strokeWidth = 0.5;

    for (int i = 1; i < 5; i++) {
      final y = size.height * (i / 5);
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        gridPaint,
      );
    }

    // Draw spectrum bars
    for (int i = 0; i < values.length; i++) {
      final v = values[i].clamp(0.0, 1.0);
      final x = i * (barWidth + gap);
      final h = v * size.height;

      // Bar with gradient
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, size.height - h, barWidth, h),
        const Radius.circular(8),
      );

      // Enhanced gradient shader
      final paint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            const Color(0xFF3B82F6).withValues(alpha: glow * 0.95),
            const Color(0xFF8B5CF6).withValues(alpha: glow * 0.85),
            const Color(0xFFEC4899).withValues(alpha: glow * 0.75),
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(Rect.fromLTWH(x, size.height - h, barWidth, h));

      canvas.drawRRect(rect, paint);

      // Glow effect on top
      if (glow > 0.5) {
        final glowPaint = Paint()
          ..color = const Color(0xFF3B82F6).withValues(alpha: (glow - 0.5) * 0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
        canvas.drawRRect(rect, glowPaint);
      }

      // Reflection effect
      final reflectionPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            const Color(0xFF3B82F6).withValues(alpha: 0.1),
            const Color(0xFF8B5CF6).withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromLTWH(x, size.height - h * 0.3, barWidth, h * 0.3));

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, size.height - h * 0.3, barWidth, h * 0.3),
          const Radius.circular(6),
        ),
        reflectionPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SpectrumPainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.energy != energy;
  }
}
