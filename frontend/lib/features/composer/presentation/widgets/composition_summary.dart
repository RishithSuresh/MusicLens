import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../data/composition_models.dart';

/// Compact summary card with key/tempo/style chips, chord progression,
/// instruments, and the AI-generated narrative.
class CompositionSummary extends StatelessWidget {
  const CompositionSummary({
    required this.metadata,
    required this.narrative,
    required this.usedLlm,
    super.key,
  });

  final CompositionMetadata metadata;
  final String narrative;
  final bool usedLlm;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.queue_music_rounded, color: AppTheme.tan),
              const SizedBox(width: 8),
              Text(
                'Composition Summary',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              _badge(
                usedLlm ? 'LLM' : 'Procedural',
                usedLlm ? AppTheme.antiqueBrass : AppTheme.capePalliser,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _chip('Key', '${metadata.key} ${metadata.mode}'),
              _chip('Tempo', '${metadata.tempoBpm} BPM'),
              _chip('Time', metadata.timeSignature),
              _chip('Bars', '${metadata.bars}'),
              _chip('Style', metadata.style),
              _chip('Mood', metadata.mood),
              _chip('Genre', metadata.genre),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Chord progression',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w800,
               color: AppTheme.tan,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            metadata.chordProgression.isEmpty
                ? '—'
                : metadata.chordProgression.take(12).join('  ·  '),
            style: const TextStyle(color: AppTheme.paper, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Text(
            'Instruments',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w800,
               color: AppTheme.tan,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: metadata.instruments
                .map((i) => _chip('', i))
                .toList(growable: false),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [
                  AppTheme.antiqueBrass.withValues(alpha: 0.18),
                  AppTheme.capePalliser.withValues(alpha: 0.2),
                ],
              ),
              border: Border.all(color: AppTheme.tan.withValues(alpha: 0.35)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.auto_awesome_rounded, size: 16, color: AppTheme.tan),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    narrative,
                    style: const TextStyle(
                      color: AppTheme.paper,
                      fontWeight: FontWeight.w500,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 0.6),
      ),
    );
  }

  Widget _chip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.buccaneer.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.tan.withValues(alpha: 0.35), width: 1),
      ),
      child: Text(
        label.isEmpty ? value : '$label · $value',
        style: const TextStyle(color: AppTheme.paper, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }
}
