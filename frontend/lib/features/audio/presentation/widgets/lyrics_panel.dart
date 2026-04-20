import 'package:flutter/material.dart';

import '../../../../core/widgets/glass_card.dart';

class LyricsPanel extends StatelessWidget {
  const LyricsPanel({
    required this.lyrics,
    required this.currentTime,
    required this.totalDuration,
    super.key,
    this.maxHeight = 250,
  });

  final String lyrics;
  final double currentTime;
  final double totalDuration;
  final double maxHeight;

  double get _playedFraction {
    if (totalDuration <= 0) {
      return 0;
    }
    return (currentTime / totalDuration).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasLyrics = lyrics.trim().isNotEmpty;
    final fullText = hasLyrics
        ? lyrics
        : 'No lyrics detected yet. Try a clearer vocal track for better transcription.';

    final splitIndex = (fullText.length * _playedFraction).round().clamp(0, fullText.length);
    final playedText = fullText.substring(0, splitIndex);
    final upcomingText = fullText.substring(splitIndex);

    final playedStyle = theme.textTheme.bodyMedium?.copyWith(
      color: const Color(0xFF0F172A),
      height: 1.5,
      fontWeight: FontWeight.w500,
    );
    final upcomingStyle = theme.textTheme.bodyMedium?.copyWith(
      color: const Color(0xFF64748B),
      height: 1.5,
      fontWeight: FontWeight.w500,
    );

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
            constraints: BoxConstraints(maxHeight: maxHeight),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.78),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFD8E4F5)),
            ),
            child: SingleChildScrollView(
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(text: playedText, style: playedStyle),
                    TextSpan(text: upcomingText, style: upcomingStyle),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
