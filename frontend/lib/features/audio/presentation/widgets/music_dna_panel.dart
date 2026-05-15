import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glass_card.dart';

class MusicDnaPanel extends StatelessWidget {
  const MusicDnaPanel({
    required this.bpm,
    required this.energyMean,
    required this.energyVariance,
    required this.pitchRange,
    super.key,
  });

  final double bpm;
  final double energyMean;
  final double energyVariance;
  final double pitchRange;

  @override
  Widget build(BuildContext context) {
    final mood = energyMean > 0.62
        ? 'Explosive'
        : energyMean > 0.4
            ? 'Driving'
            : 'Atmospheric';

    final groove = bpm > 128
        ? 'High-Tempo Pulse'
        : bpm > 95
            ? 'Balanced Flow'
            : 'Slow Burn';

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Music DNA',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _pill('Mood', mood),
              _pill('Groove', groove),
              _pill('Dynamics', energyVariance > 0.04 ? 'Volatile' : 'Stable'),
              _pill('Pitch Span', '${pitchRange.toStringAsFixed(0)} Hz'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pill(String key, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.tan.withValues(alpha: 0.42)),
        color: AppTheme.buccaneer.withValues(alpha: 0.76),
      ),
      child: Text('$key: $value', style: const TextStyle(color: AppTheme.paper)),
    );
  }
}
