import 'dart:math' as math;

import 'package:flutter/material.dart';

class BeatSyncedPulseOverlay extends StatelessWidget {
  const BeatSyncedPulseOverlay({
    required this.currentTime,
    required this.duration,
    required this.beatTimestamps,
    required this.energy,
    required this.bass,
    required this.isPlaying,
    super.key,
  });

  final double currentTime;
  final double duration;
  final List<double> beatTimestamps;
  final double energy;
  final double bass;
  final bool isPlaying;

  @override
  Widget build(BuildContext context) {
    if (!isPlaying) {
      return const SizedBox.shrink();
    }

    final pulse = _pulseStrength(
      currentTime: currentTime,
      duration: duration,
      beatTimestamps: beatTimestamps,
      energy: energy,
      bass: bass,
    );

    if (pulse < 0.02) {
      return const SizedBox.shrink();
    }

    return IgnorePointer(
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: pulse),
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        builder: (context, animatedPulse, _) {
          return CustomPaint(
            painter: _PulsePainter(strength: animatedPulse),
            child: const SizedBox.expand(),
          );
        },
      ),
    );
  }

  double _pulseStrength({
    required double currentTime,
    required double duration,
    required List<double> beatTimestamps,
    required double energy,
    required double bass,
  }) {
    if (duration <= 0) {
      return 0;
    }

    final beatWindowSeconds = 0.18;
    var nearestBeatDistance = 1.0;

    if (beatTimestamps.isNotEmpty) {
      for (final beat in beatTimestamps) {
        final distance = (beat - currentTime).abs();
        if (distance < nearestBeatDistance) {
          nearestBeatDistance = distance;
        }
      }
    } else {
      final syntheticPeriod = 0.5;
      final phase = (currentTime % syntheticPeriod) / syntheticPeriod;
      nearestBeatDistance = (phase <= 0.5 ? phase : (1 - phase)) * syntheticPeriod;
    }

    final beatProximity = (1 - (nearestBeatDistance / beatWindowSeconds)).clamp(0.0, 1.0);
    final energyBoost = (energy * 0.75).clamp(0.0, 1.0);
    final bassBoost = (bass * 0.95).clamp(0.0, 1.0);
    final mixed = (beatProximity * 0.65) + (energyBoost * 0.2) + (bassBoost * 0.15);
    return mixed.clamp(0.0, 1.0);
  }
}

class _PulsePainter extends CustomPainter {
  _PulsePainter({required this.strength});

  final double strength;

  @override
  void paint(Canvas canvas, Size size) {
    if (strength <= 0) {
      return;
    }

    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.sqrt((size.width * size.width) + (size.height * size.height)) * 0.52;
    final outerRadius = maxRadius * (0.72 + (0.28 * strength));

    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF38BDF8).withValues(alpha: 0.03 + (0.14 * strength)),
          const Color(0xFF2563EB).withValues(alpha: 0.03 + (0.09 * strength)),
          Colors.transparent,
        ],
        stops: const [0.0, 0.58, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: outerRadius));

    canvas.drawCircle(center, outerRadius, glowPaint);

    final ringCount = 2 + (strength * 2).floor();
    for (var i = 0; i < ringCount; i++) {
      final t = i / math.max(1, ringCount - 1);
      final radius = outerRadius * (0.42 + (0.48 * t));
      final alpha = (0.24 - (0.12 * t)) * strength;
      final ringPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2 + (2.2 * strength)
        ..color = const Color(0xFF0EA5E9).withValues(alpha: alpha.clamp(0.0, 1.0));

      canvas.drawCircle(center, radius, ringPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _PulsePainter oldDelegate) {
    return (oldDelegate.strength - strength).abs() > 0.002;
  }
}