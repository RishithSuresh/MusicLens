import 'package:flutter/material.dart';

class TimelineScrubber extends StatefulWidget {
  const TimelineScrubber({
    required this.currentTime,
    required this.totalDuration,
    required this.onSeek,
    super.key,
  });

  final double currentTime;
  final double totalDuration;
  final ValueChanged<double> onSeek;

  @override
  State<TimelineScrubber> createState() => _TimelineScrubberState();
}

class _TimelineScrubberState extends State<TimelineScrubber> {
  late double _draggedTime;
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    final progress = widget.totalDuration > 0
        ? (widget.currentTime / widget.totalDuration).clamp(0.0, 1.0)
        : 0.0;

    final displayTime = _isDragging ? _draggedTime : widget.currentTime;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onHorizontalDragStart: (details) {
              _isDragging = true;
              _updateTimeFromPosition(details.globalPosition);
            },
            onHorizontalDragUpdate: (details) {
              _updateTimeFromPosition(details.globalPosition);
            },
            onHorizontalDragEnd: (details) {
              setState(() {
                _isDragging = false;
              });
              widget.onSeek(_draggedTime);
            },
            onTapDown: (details) {
              _updateTimeFromPosition(details.globalPosition);
              widget.onSeek(_draggedTime);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 4,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 4,
                        backgroundColor: const Color(0xFFE2E8F0),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF2563EB),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatTime(displayTime),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: const Color(0xFF334155),
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      Text(
                        _formatTime(widget.totalDuration),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: const Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _updateTimeFromPosition(Offset globalPosition) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;

    final localPosition = box.globalToLocal(globalPosition);
    final containerWidth = box.size.width - 40; // Subtract horizontal padding
    final fraction = (localPosition.dx - 20) / containerWidth;
    final clampedFraction = fraction.clamp(0.0, 1.0);

    setState(() {
      _draggedTime = clampedFraction * widget.totalDuration;
    });
  }

  String _formatTime(double seconds) {
    final total = seconds.round().clamp(0, 60 * 60 * 24);
    final mins = total ~/ 60;
    final secs = total % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}
