import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../../core/widgets/glass_card.dart';
import '../../data/composer_api_service.dart';
import '../../data/composition_models.dart';
import '../widgets/composition_form.dart';
import '../widgets/composition_summary.dart';
import '../widgets/piano_roll.dart';

/// Full screen for the AI Music Compositor feature, intended to live inside
/// the home tab shell alongside the audio analyzer.
class ComposerScreen extends StatefulWidget {
  const ComposerScreen({super.key});

  @override
  State<ComposerScreen> createState() => _ComposerScreenState();
}

class _ComposerScreenState extends State<ComposerScreen>
    with SingleTickerProviderStateMixin {
  final ComposerApiService _api = ComposerApiService();

  CompositionResponse? _composition;
  bool _isLoading = false;
  String? _error;

  Ticker? _ticker;
  Duration _elapsed = Duration.zero;
  bool _playing = false;

  @override
  void dispose() {
    _ticker?.dispose();
    super.dispose();
  }

  void _ensureTicker() {
    _ticker ??= createTicker((elapsed) {
      if (!mounted || !_playing) return;
      setState(() => _elapsed = elapsed);
    });
  }

  double get _currentBeat {
    final c = _composition;
    if (c == null) return 0;
    final beatsPerSecond = c.metadata.tempoBpm / 60.0;
    final beat = _elapsed.inMilliseconds / 1000.0 * beatsPerSecond;
    if (beat >= c.metadata.totalBeats) {
      _playing = false;
      _ticker?.stop();
      return c.metadata.totalBeats;
    }
    return beat;
  }

  void _togglePlay() {
    _ensureTicker();
    setState(() {
      _playing = !_playing;
      if (_playing) {
        if (_currentBeat >= (_composition?.metadata.totalBeats ?? 0)) {
          _elapsed = Duration.zero;
          _ticker?.stop();
        }
        _ticker?.start();
      } else {
        _ticker?.stop();
      }
    });
  }

  void _resetPlayhead() {
    setState(() {
      _playing = false;
      _elapsed = Duration.zero;
      _ticker?.stop();
    });
  }

  Future<void> _compose({
    required String prompt,
    String? style,
    String? key,
    String? mode,
    int? tempoBpm,
    int? bars,
    required bool useLlm,
  }) async {
    if (prompt.isEmpty) {
      setState(() => _error = 'Please describe the music you want.');
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final result = await _api.compose(
        prompt: prompt,
        style: style,
        key: key,
        mode: mode,
        tempoBpm: tempoBpm,
        bars: bars,
        useLlm: useLlm,
      );
      setState(() {
        _composition = result;
        _elapsed = Duration.zero;
        _playing = false;
        _ticker?.stop();
      });
    } catch (e) {
      setState(() => _error = 'Compose failed: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _downloadMidi() async {
    final c = _composition;
    if (c == null) return;
    try {
      final bytes = base64Decode(c.midiBase64);
      final fileName = 'musiclens-composition-${c.compositionId.substring(0, 8)}.mid';
      final saved = await FilePicker.saveFile(
        dialogTitle: 'Save MIDI file',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['mid'],
        bytes: Uint8List.fromList(bytes),
      );
      if (!mounted) return;
      final msg = saved == null ? 'Export cancelled' : 'MIDI exported to $saved';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to export MIDI: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final composition = _composition;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(_error!, style: const TextStyle(color: Colors.redAccent)),
            ),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 1040;
              final form = CompositionForm(onSubmit: _compose, isLoading: _isLoading);

              if (composition == null) {
                return isWide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: form),
                          const SizedBox(width: 16),
                          Expanded(child: _emptyState()),
                        ],
                      )
                    : Column(
                        children: [
                          form,
                          const SizedBox(height: 16),
                          _emptyState(),
                        ],
                      );
              }

              final results = Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _playbackBar(composition),
                  const SizedBox(height: 12),
                  PianoRoll(
                    tracks: composition.tracks,
                    totalBeats: composition.metadata.totalBeats,
                    sections: composition.structure,
                    currentBeat: _currentBeat,
                  ),
                  const SizedBox(height: 12),
                  CompositionSummary(
                    metadata: composition.metadata,
                    narrative: composition.narrative,
                    usedLlm: composition.usedLlm,
                  ),
                ],
              );

              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: 420, child: form),
                    const SizedBox(width: 16),
                    Expanded(child: results),
                  ],
                );
              }
              return Column(children: [form, const SizedBox(height: 16), results]);
            },
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 12),
        child: Column(
          children: [
            const Icon(Icons.music_note_rounded, size: 48, color: Color(0xFF8B5CF6)),
            const SizedBox(height: 12),
            Text(
              'Describe the music and press Compose.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: const Color(0xFF334155),
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 6),
            const Text(
              'A multi-stage LangGraph pipeline interprets your prompt, '
              'then a procedural music engine arranges melody, harmony, '
              'bass, and drums into a downloadable MIDI piece.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF64748B), height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _playbackBar(CompositionResponse c) {
    final beat = _currentBeat;
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          IconButton(
            onPressed: _togglePlay,
            icon: Icon(_playing ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded),
            color: const Color(0xFF3B82F6),
            iconSize: 36,
            tooltip: _playing ? 'Pause' : 'Play visual',
          ),
          IconButton(
            onPressed: _resetPlayhead,
            icon: const Icon(Icons.replay_rounded),
            color: const Color(0xFF475569),
            tooltip: 'Reset',
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                LinearProgressIndicator(
                  value: c.metadata.totalBeats == 0 ? 0 : (beat / c.metadata.totalBeats).clamp(0.0, 1.0),
                  backgroundColor: const Color(0xFFE2E8F0),
                  color: const Color(0xFF8B5CF6),
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(6),
                ),
                const SizedBox(height: 4),
                Text(
                  'Beat ${beat.toStringAsFixed(1)} / ${c.metadata.totalBeats.toStringAsFixed(0)}'
                  '   ·   ${c.metadata.tempoBpm} BPM',
                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          FilledButton.icon(
            onPressed: _downloadMidi,
            icon: const Icon(Icons.download_rounded, size: 18),
            label: const Text('MIDI'),
          ),
        ],
      ),
    );
  }
}
