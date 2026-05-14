import 'package:flutter/material.dart';

import '../../../../core/widgets/glass_card.dart';
import '../../data/composition_models.dart';

/// Multi-track piano-roll visualizer with an animated playhead.
class PianoRoll extends StatelessWidget {
  const PianoRoll({
    required this.tracks,
    required this.totalBeats,
    required this.sections,
    required this.currentBeat,
    super.key,
  });

  final List<CompositionTrack> tracks;
  final double totalBeats;
  final List<CompositionSection> sections;
  final double currentBeat;

  static const Map<String, Color> _trackColors = {
    'Melody': Color(0xFF3B82F6),
    'Harmony': Color(0xFF8B5CF6),
    'Bass': Color(0xFFEC4899),
    'Drums': Color(0xFF06B6D4),
  };

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.piano_rounded, size: 18, color: Color(0xFF3B82F6)),
              const SizedBox(width: 8),
              Text(
                'Piano Roll',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                    ),
              ),
              const Spacer(),
              Wrap(
                spacing: 10,
                children: tracks.map((t) {
                  final color = _trackColors[t.name] ?? Colors.grey;
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        t.name,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ],
                  );
                }).toList(growable: false),
              ),
            ],
          ),
          const SizedBox(height: 10),
          AspectRatio(
            aspectRatio: 2.4,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: CustomPaint(
                painter: _PianoRollPainter(
                  tracks: tracks,
                  totalBeats: totalBeats,
                  sections: sections,
                  currentBeat: currentBeat,
                  trackColors: _trackColors,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PianoRollPainter extends CustomPainter {
  _PianoRollPainter({
    required this.tracks,
    required this.totalBeats,
    required this.sections,
    required this.currentBeat,
    required this.trackColors,
  });

  final List<CompositionTrack> tracks;
  final double totalBeats;
  final List<CompositionSection> sections;
  final double currentBeat;
  final Map<String, Color> trackColors;

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = const Color(0xFFF8FAFC);
    canvas.drawRect(Offset.zero & size, bg);

    if (totalBeats <= 0) {
      return;
    }

    // Section bands.
    for (var i = 0; i < sections.length; i++) {
      final section = sections[i];
      final x1 = (section.startBeat / totalBeats) * size.width;
      final x2 = (section.endBeat / totalBeats) * size.width;
      final paint = Paint()
        ..color = (i.isEven
                ? const Color(0xFF3B82F6)
                : const Color(0xFF8B5CF6))
            .withValues(alpha: 0.05);
      canvas.drawRect(Rect.fromLTWH(x1, 0, x2 - x1, size.height), paint);

      final labelStyle = TextStyle(
        fontSize: 9,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF475569).withValues(alpha: 0.85),
        letterSpacing: 0.6,
      );
      final tp = TextPainter(
        text: TextSpan(text: section.name.toUpperCase(), style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x1 + 6, 4));
    }

    // Compute pitch range across all non-drum tracks.
    int minPitch = 127;
    int maxPitch = 0;
    for (final track in tracks) {
      if (track.isDrum) continue;
      for (final note in track.notes) {
        if (note.pitch < minPitch) minPitch = note.pitch;
        if (note.pitch > maxPitch) maxPitch = note.pitch;
      }
    }
    if (maxPitch <= minPitch) {
      maxPitch = minPitch + 12;
    }
    final pitchRange = (maxPitch - minPitch).toDouble();

    // Reserve bottom band for drums.
    final drumBandHeight = size.height * 0.18;
    final melodicHeight = size.height - drumBandHeight - 14;

    // Draw notes.
    for (final track in tracks) {
      final color = trackColors[track.name] ?? Colors.grey;
      for (final note in track.notes) {
        final x = (note.startBeat / totalBeats) * size.width;
        final w = (note.durationBeats / totalBeats) * size.width;
        final velocityAlpha = (note.velocity / 127.0).clamp(0.35, 1.0);
        final paint = Paint()..color = color.withValues(alpha: velocityAlpha);
        if (track.isDrum) {
          final y = melodicHeight + 8 + (drumBandHeight - 6) * 0.5;
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(x, y - 3, w.clamp(2.0, double.infinity), 6),
              const Radius.circular(2),
            ),
            paint,
          );
        } else {
          final relative = (note.pitch - minPitch) / pitchRange;
          final y = melodicHeight - relative * (melodicHeight - 6);
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(x, y, w.clamp(2.0, double.infinity), 5),
              const Radius.circular(2.5),
            ),
            paint,
          );
        }
      }
    }

    // Playhead.
    final px = (currentBeat / totalBeats).clamp(0.0, 1.0) * size.width;
    final headPaint = Paint()
      ..color = const Color(0xFFEC4899)
      ..strokeWidth = 1.5;
    canvas.drawLine(Offset(px, 0), Offset(px, size.height), headPaint);
  }

  @override
  bool shouldRepaint(covariant _PianoRollPainter old) {
    return old.currentBeat != currentBeat ||
        old.tracks != tracks ||
        old.totalBeats != totalBeats;
  }
}
