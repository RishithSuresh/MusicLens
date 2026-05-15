import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

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

    final profile = _pulseProfile(
      currentTime: currentTime,
      duration: duration,
      beatTimestamps: beatTimestamps,
      energy: energy,
      bass: bass,
    );

    if (profile.strength < 0.01) {
      return const SizedBox.shrink();
    }

    return IgnorePointer(
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: profile.strength),
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOutCubic,
        builder: (context, animatedPulse, _) {
          return CustomPaint(
            painter: _PulsePainter(
              strength: animatedPulse,
              beatPhase: profile.beatPhase,
            ),
            child: const SizedBox.expand(),
          );
        },
      ),
    );
  }

  _PulseProfile _pulseProfile({
    required double currentTime,
    required double duration,
    required List<double> beatTimestamps,
    required double energy,
    required double bass,
  }) {
    if (duration <= 0) {
      return const _PulseProfile(strength: 0, beatPhase: 0);
    }

    final normalizedEnergy = (energy * 1.35).clamp(0.0, 1.0);
    final normalizedBass = (bass * 1.45).clamp(0.0, 1.0);

    var timeSinceLastBeat = 1.0;
    var timeToNextBeat = 1.0;

    if (beatTimestamps.isNotEmpty) {
      for (final beat in beatTimestamps) {
        if (beat <= currentTime) {
          timeSinceLastBeat = currentTime - beat;
          continue;
        }

        timeToNextBeat = beat - currentTime;
        break;
      }
    } else {
      final syntheticPeriod = 0.45;
      final phase = currentTime % syntheticPeriod;
      timeSinceLastBeat = phase;
      timeToNextBeat = syntheticPeriod - phase;
    }

    final beatTail = math.exp(-timeSinceLastBeat / 0.2).clamp(0.0, 1.0);
    final anticipation = (1 - (timeToNextBeat / 0.08)).clamp(0.0, 1.0) * 0.35;
    final beatImpact = (beatTail + anticipation).clamp(0.0, 1.0);

    final strength = (
      0.1 +
      (normalizedEnergy * 0.3) +
      (normalizedBass * 0.25) +
      (beatImpact * 0.6)
    )
        .clamp(0.0, 1.0);

    final beatPhase = (timeSinceLastBeat / 0.36).clamp(0.0, 1.0);

    return _PulseProfile(
      strength: strength,
      beatPhase: beatPhase,
    );
  }
}

class _PulseProfile {
  const _PulseProfile({
    required this.strength,
    required this.beatPhase,
  });

  final double strength;
  final double beatPhase;
}

class _PulsePainter extends CustomPainter {
  _PulsePainter({
    required this.strength,
    required this.beatPhase,
  });

  final double strength;
  final double beatPhase;

  @override
  void paint(Canvas canvas, Size size) {
    if (strength <= 0) {
      return;
    }

    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.sqrt((size.width * size.width) + (size.height * size.height)) * 0.58;

    final washPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppTheme.buccaneer.withValues(alpha: 0.05 + (0.12 * strength)),
          AppTheme.capePalliser.withValues(alpha: 0.04 + (0.1 * strength)),
          AppTheme.antiqueBrass.withValues(alpha: 0.02 + (0.06 * strength)),
        ],
      ).createShader(Offset.zero & size);

    canvas.drawRect(Offset.zero & size, washPaint);

    final glowRadius = maxRadius * (0.45 + (0.5 * strength));
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppTheme.tan.withValues(alpha: 0.08 + (0.23 * strength)),
          AppTheme.capePalliser.withValues(alpha: 0.03 + (0.16 * strength)),
          Colors.transparent,
        ],
        stops: const [0.0, 0.56, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: glowRadius));

    canvas.drawCircle(center, glowRadius, glowPaint);

    for (var i = 0; i < 3; i++) {
      final localPhase = (beatPhase + (i * 0.22)) % 1.0;
      final radius = maxRadius * (0.2 + (0.78 * localPhase));
      final alpha = (0.32 - (0.2 * localPhase)) * strength;

      final ringPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5 + ((1 - localPhase) * 3.4 * strength)
        ..color = AppTheme.tan.withValues(alpha: alpha.clamp(0.0, 1.0));

      canvas.drawCircle(center, radius, ringPaint);
    }

    final flashPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2 + (2.2 * strength)
      ..color = AppTheme.antiqueBrass.withValues(alpha: (0.04 + (0.12 * strength)).clamp(0.0, 1.0));

    final horizontalInset = size.width * 0.16;
    final verticalInset = size.height * 0.18;
    canvas.drawLine(
      Offset(horizontalInset, center.dy),
      Offset(size.width - horizontalInset, center.dy),
      flashPaint,
    );
    canvas.drawLine(
      Offset(center.dx, verticalInset),
      Offset(center.dx, size.height - verticalInset),
      flashPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _PulsePainter oldDelegate) {
    return (oldDelegate.strength - strength).abs() > 0.002 ||
        (oldDelegate.beatPhase - beatPhase).abs() > 0.002;
  }
}
