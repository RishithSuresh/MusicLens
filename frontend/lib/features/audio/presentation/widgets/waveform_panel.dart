import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glass_card.dart';
import 'reactive_particle_field.dart';

class WaveformPanel extends StatefulWidget {
  const WaveformPanel({
    required this.energy,
    required this.beatTimestamps,
    required this.pitch,
    required this.duration,
    required this.currentTime,
    required this.bpm,
    required this.currentEnergy,
    required this.currentBass,
    required this.onSeek,
    super.key,
    this.compact = false,
  });

  final List<double> energy;
  final List<double> beatTimestamps;
  final List<double> pitch;
  final double duration;
  final double currentTime;
  final double bpm;
  final double currentEnergy;
  final double currentBass;
  final ValueChanged<double> onSeek;
  final bool compact;

  @override
  State<WaveformPanel> createState() => _WaveformPanelState();
}

class _WaveformPanelState extends State<WaveformPanel> {
  static const double _compactWaveformHeight = 220;
  static const double _tooltipOffsetX = 8;
  static const double _tooltipWidth = 150;

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
          final hoverTime = _hoverX != null && width > 0
              ? ((_hoverX! / width) * widget.duration).clamp(0.0, widget.duration)
              : null;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!widget.compact) ...[
                Text(
                  'Interactive Waveform',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
              ],
              if (widget.compact)
                SizedBox(
                  height: _compactWaveformHeight,
                  child: _buildWaveformArea(values, pitch, width, hoverTime),
                )
              else
                Expanded(
                  child: _buildWaveformArea(values, pitch, width, hoverTime),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildWaveformArea(
    List<double> values,
    List<double> pitch,
    double width,
    double? hoverTime,
  ) {
    return MouseRegion(
      opaque: true,
      onHover: (event) {
        if (width <= 0) {
          return;
        }
        final nextX = event.localPosition.dx.clamp(0.0, width);
        if (_hoverX == null || (_hoverX! - nextX).abs() > 0.75) {
          setState(() {
            _hoverX = nextX;
          });
        }
      },
      onExit: (_) => setState(() => _hoverX = null),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (details) => _seekFromLocalX(details.localPosition.dx, width),
        onHorizontalDragUpdate: (details) => _seekFromLocalX(details.localPosition.dx, width),
        child: SizedBox(
          width: double.infinity,
          child: ClipRect(
            child: Stack(
              children: [
                Positioned.fill(
                  child: RepaintBoundary(
                    child: ReactiveParticleField(intensity: widget.currentBass),
                  ),
                ),
                Positioned.fill(
                  child: RepaintBoundary(
                    child: CustomPaint(
                      painter: _WaveformPainter(
                        energy: values,
                        pitch: pitch,
                        beatTimestamps: widget.beatTimestamps,
                        duration: widget.duration,
                        currentTime: widget.currentTime,
                        currentEnergy: widget.currentEnergy,
                      ),
                    ),
                  ),
                ),
                if (_hoverX != null && hoverTime != null)
                  Positioned(
                    left: (_hoverX! + _tooltipOffsetX).clamp(0, width - _tooltipWidth),
                    top: widget.compact ? 10 : 12,
                    child: RepaintBoundary(
                      child: _HoverTooltip(
                        bpm: widget.bpm,
                        time: hoverTime,
                        pitch: _valueAtTime(pitch, hoverTime),
                        energy: _valueAtTime(values, hoverTime),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _seekFromLocalX(double localX, double width) {
    if (width <= 0 || widget.duration <= 0) {
      return;
    }
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
        color: AppTheme.cocoaBrown.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: DefaultTextStyle(
          style: const TextStyle(color: AppTheme.paper, fontSize: 12),
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
    required this.currentEnergy,
  });

  final List<double> energy;
  final List<double> pitch;
  final List<double> beatTimestamps;
  final double duration;
  final double currentTime;
  final double currentEnergy;

  @override
  void paint(Canvas canvas, Size size) {
    if (energy.isEmpty || pitch.isEmpty || size.width <= 0 || size.height <= 0) {
      return;
    }

    final energyDivisor = math.max(1, energy.length - 1).toDouble();
    final pitchDivisor = math.max(1, pitch.length - 1).toDouble();
    final isSingleEnergySample = energy.length == 1;
    final isSinglePitchSample = pitch.length == 1;

    final accent = Color.lerp(
      AppTheme.antiqueBrass,
      AppTheme.tan,
      currentEnergy.clamp(0.0, 1.0),
    )!;

    final basePaint = Paint()
      ..color = accent.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;

    final wavePaint = Paint()
      ..shader = LinearGradient(
        colors: [accent, AppTheme.capePalliser],
      ).createShader(Offset.zero & size)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4;

    final pitchPaint = Paint()
      ..color = AppTheme.tan.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7;

    final beatPaint = Paint()
      ..color = AppTheme.capePalliser.withValues(alpha: 0.3)
      ..strokeWidth = 1;

    final progressPaint = Paint()
      ..color = AppTheme.paper
      ..strokeWidth = 1.8;

    final wavePath = Path();
    final fillPath = Path();
    final centerY = size.height * 0.58;

    for (int i = 0; i < energy.length; i++) {
      final x = isSingleEnergySample ? size.width * 0.5 : i / energyDivisor * size.width;
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
      final x = isSinglePitchSample ? size.width * 0.5 : i / pitchDivisor * size.width;
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
        oldDelegate.currentEnergy != currentEnergy ||
        oldDelegate.energy != energy ||
        oldDelegate.pitch != pitch ||
        oldDelegate.beatTimestamps != beatTimestamps;
  }
}
