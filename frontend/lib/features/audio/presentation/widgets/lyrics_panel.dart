import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasLyrics = lyrics.trim().isNotEmpty;
    final fullText = hasLyrics
        ? lyrics
        : 'No lyrics detected yet. Try a clearer vocal track for better transcription.';

    final lyricStyle = theme.textTheme.bodyMedium?.copyWith(
      color: AppTheme.paper,
      height: 1.6,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.2,
    );

    return GlassCard(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppTheme.buccaneer.withValues(alpha: 0.82),
          AppTheme.cocoaBrown.withValues(alpha: 0.74),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lyrics_rounded,
                size: 22,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 10),
              Text(
                'Lyrics & Transcription',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            constraints: BoxConstraints(maxHeight: maxHeight),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.buccaneer.withValues(alpha: 0.78),
                  AppTheme.cocoaBrown.withValues(alpha: 0.68),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.tan.withValues(alpha: 0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.capePalliser.withValues(alpha: 0.2),
                  offset: const Offset(0, 4),
                  blurRadius: 16,
                ),
              ],
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: RichText(
                text: TextSpan(
                  text: fullText,
                  style: lyricStyle,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
