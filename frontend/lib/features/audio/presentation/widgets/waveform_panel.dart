import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/widgets/glass_card.dart';

class WaveformPanel extends StatefulWidget {
  const WaveformPanel({
    required this.energy,
    required this.beatTimestamps,
    required this.pitch,
    required this.duration,
    required this.currentTime,
    required this.bpm,
    required this.onSeek,
    super.key,
  });

  final List<double> energy;
  final List<double> beatTimestamps;
  final List<double> pitch;
  final double duration;
  final double currentTime;
  final double bpm;
  final ValueChanged<double> onSeek;

  @override
  State<WaveformPanel> createState() => _WaveformPanelState();
}

class _WaveformPanelState extends State<WaveformPanel> {
  double? _hoverX;

  @override
  Widget build(BuildContext context) {
    final values = widget.energy.isEmpty
        ? List<double>.generate(180, (index) => 0.2 + (math.sin(index / 7) + 1) / 4)
        : widget.energy;

    final pitch = widget.pitch.isEmpty
        ? List<double>.generate(180, (index) => 160 + (math.sin(index / 9) * 35))
        : widget.pitch;

    return GlassCard(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final hoverTime = _hoverX != null
              ? ((_hoverX! / width) * widget.duration).clamp(0.0, widget.duration)
              : null;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Interactive Waveform',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              MouseRegion(
                onHover: (event) {
                  setState(() {
                    _hoverX = event.localPosition.dx.clamp(0.0, width);
                  });
                },
                onExit: (_) => setState(() => _hoverX = null),
                child: GestureDetector(
                  onTapDown: (details) => _seekFromLocalX(details.localPosition.dx, width),
                  onHorizontalDragUpdate: (details) => _seekFromLocalX(details.localPosition.dx, width),
                  child: SizedBox(
                    height: 220,
                    width: double.infinity,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _WaveformPainter(
                              energy: values,
                              pitch: pitch,
                              beatTimestamps: widget.beatTimestamps,
                              duration: widget.duration,
                              currentTime: widget.currentTime,
                            ),
                          ),
                        ),
                        if (_hoverX != null && hoverTime != null)
                          Positioned(
                            left: (_hoverX! + 8).clamp(0, width - 150),
                            top: 8,
                            child: _HoverTooltip(
                              bpm: widget.bpm,
                              time: hoverTime,
                              pitch: _valueAtTime(pitch, hoverTime),
                              energy: _valueAtTime(values, hoverTime),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _seekFromLocalX(double localX, double width) {
    final clamped = localX.clamp(0.0, width);
    final time = (clamped / width) * widget.duration;
    widget.onSeek(time);
  }

  double _valueAtTime(List<double> values, double time) {
    if (values.isEmpty || widget.duration <= 0) {
      return 0;
    }
    final idx = ((time / widget.duration) * (values.length - 1)).round().clamp(0, values.length - 1);
    return values[idx];
  }
}

class _HoverTooltip extends StatelessWidget {
  const _HoverTooltip({
    required this.bpm,
    required this.time,
    required this.pitch,
    required this.energy,
  });

  final double bpm;
  final double time;
  final double pitch;
  final double energy;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: DefaultTextStyle(
          style: const TextStyle(color: Colors.white, fontSize: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('t=${time.toStringAsFixed(2)}s'),
              Text('BPM ${bpm.toStringAsFixed(1)}'),
              Text('Pitch ${pitch.toStringAsFixed(1)} Hz'),
              Text('Energy ${(energy * 100).toStringAsFixed(0)}%'),
            ],
          ),
        ),
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  _WaveformPainter({
    required this.energy,
    required this.pitch,
    required this.beatTimestamps,
    required this.duration,
    required this.currentTime,
  });

  final List<double> energy;
  final List<double> pitch;
  final List<double> beatTimestamps;
  final double duration;
  final double currentTime;

  @override
  void paint(Canvas canvas, Size size) {
    final basePaint = Paint()
      ..color = const Color(0xFF3B82F6).withValues(alpha: 0.18)
      ..style = PaintingStyle.fill;

    final wavePaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
      ).createShader(Offset.zero & size)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4;

    final pitchPaint = Paint()
      ..color = const Color(0xFFEC4899).withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7;

    final beatPaint = Paint()
      ..color = const Color(0xFF8B5CF6).withValues(alpha: 0.25)
      ..strokeWidth = 1;

    final progressPaint = Paint()
      ..color = const Color(0xFF0F172A)
      ..strokeWidth = 1.8;

    final wavePath = Path();
    final fillPath = Path();
    final centerY = size.height * 0.58;

    for (int i = 0; i < energy.length; i++) {
      final x = i / (energy.length - 1) * size.width;
      final amp = (energy[i].clamp(0, 1) as double) * (size.height * 0.42);
      final y = centerY - amp;

      if (i == 0) {
        wavePath.moveTo(x, y);
        fillPath.moveTo(x, centerY);
      }
      wavePath.lineTo(x, y);
      fillPath.lineTo(x, y);
    }

    fillPath
      ..lineTo(size.width, centerY)
      ..close();

    canvas.drawPath(fillPath, basePaint);
    canvas.drawPath(wavePath, wavePaint);

    if (duration > 0) {
      for (final beat in beatTimestamps) {
        final x = (beat / duration) * size.width;
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), beatPaint);
      }
    }

    final minPitch = pitch.isEmpty ? 0.0 : pitch.reduce(math.min);
    final maxPitch = pitch.isEmpty ? 1.0 : pitch.reduce(math.max);
    final pitchRange = (maxPitch - minPitch).abs() < 0.001 ? 1.0 : maxPitch - minPitch;

    final pitchPath = Path();
    for (int i = 0; i < pitch.length; i++) {
      final x = i / (pitch.length - 1) * size.width;
      final normalized = ((pitch[i] - minPitch) / pitchRange).clamp(0.0, 1.0);
      final y = size.height * 0.86 - (normalized * (size.height * 0.36));
      if (i == 0) {
        pitchPath.moveTo(x, y);
      } else {
        pitchPath.lineTo(x, y);
      }
    }
    canvas.drawPath(pitchPath, pitchPaint);

    if (duration > 0) {
      final progressX = (currentTime / duration).clamp(0.0, 1.0) * size.width;
      canvas.drawLine(Offset(progressX, 0), Offset(progressX, size.height), progressPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) {
    return oldDelegate.currentTime != currentTime ||
        oldDelegate.energy != energy ||
        oldDelegate.pitch != pitch ||
        oldDelegate.beatTimestamps != beatTimestamps;
  }
}
