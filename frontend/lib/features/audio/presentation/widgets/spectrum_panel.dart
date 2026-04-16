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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Frequency Spectrum',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
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
    final barWidth = size.width / (values.length * 1.25);
    final gap = barWidth * 0.25;
    final glow = (0.25 + energy * 0.75).clamp(0.2, 1.0);

    for (int i = 0; i < values.length; i++) {
      final v = values[i].clamp(0.0, 1.0);
      final x = i * (barWidth + gap);
      final h = v * size.height;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, size.height - h, barWidth, h),
        const Radius.circular(8),
      );

      final paint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            const Color(0xFF3B82F6).withValues(alpha: glow),
            const Color(0xFF8B5CF6).withValues(alpha: 0.95),
            const Color(0xFFEC4899).withValues(alpha: 0.85),
          ],
        ).createShader(Rect.fromLTWH(x, size.height - h, barWidth, h));

      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SpectrumPainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.energy != energy;
  }
}
