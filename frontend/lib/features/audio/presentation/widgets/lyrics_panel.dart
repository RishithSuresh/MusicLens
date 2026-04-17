import 'package:flutter/material.dart';

import '../../../../core/widgets/glass_card.dart';

class LyricsPanel extends StatelessWidget {
  const LyricsPanel({required this.lyrics, super.key});

  final String lyrics;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasLyrics = lyrics.trim().isNotEmpty;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Lyrics',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxHeight: 250),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.78),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFD8E4F5)),
            ),
            child: SingleChildScrollView(
              child: Text(
                hasLyrics
                    ? lyrics
                    : 'No lyrics detected yet. Try a clearer vocal track for better transcription.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF1E293B),
                  height: 1.45,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
