import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../data/composer_api_service.dart';
import '../../data/composition_models.dart';
import '../widgets/composition_form.dart';
import '../widgets/composition_summary.dart';
import '../widgets/piano_roll.dart';
import '../../../../features/audio/data/audio_playback_service.dart';

/// Full screen for the AI Music Compositor feature, intended to live inside
/// the home tab shell alongside the audio analyzer.
class ComposerScreen extends StatefulWidget {
  const ComposerScreen({super.key});

  @override
  State<ComposerScreen> createState() => _ComposerScreenState();
}

class _ComposerScreenState extends State<ComposerScreen> {
  static const int _idPrefixLength = 8;
  static const int _secondsPerMinute = 60;
  static const int _millisecondsPerSecond = 1000;

  final ComposerApiService _api = ComposerApiService();
  final AudioPlaybackService _audioService = AudioPlaybackService();

  CompositionResponse? _composition;
  bool _isLoading = false;
  bool _isAudioPrepared = false;
  String? _error;

  Duration _elapsed = Duration.zero;
  bool _playing = false;
  int _maxPlaybackMs = 0;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<PlayerState>? _stateSub;

  int _calculatePlaybackMs(double totalBeats, int tempo) {
    return (totalBeats / tempo * _secondsPerMinute * _millisecondsPerSecond).round();
  }

  @override
  void initState() {
    super.initState();
    _positionSub = _audioService.positionStream.listen((position) {
      if (!mounted) return;
      final c = _composition;
      if (c == null) {
        setState(() => _elapsed = position);
        return;
      }
      final clampedPositionMs = position.inMilliseconds.clamp(0, _maxPlaybackMs);
      setState(() => _elapsed = Duration(milliseconds: clampedPositionMs));
    });
    _stateSub = _audioService.stateStream.listen((state) {
      if (!mounted) return;
      setState(() {
        _playing = state == PlayerState.playing;
      });
    });
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _stateSub?.cancel();
    _audioService.dispose();
    super.dispose();
  }

  double get _currentBeat {
    final c = _composition;
    if (c == null) return 0;
    final beatsPerSecond = c.metadata.tempoBpm / 60.0;
    final beat = _elapsed.inMilliseconds / 1000.0 * beatsPerSecond;
    return beat.clamp(0.0, c.metadata.totalBeats);
  }

  Future<void> _togglePlay() async {
    if (_composition == null) return;
    if (!_isAudioPrepared) {
      setState(() => _error = 'MP3 preview is not available for this composition.');
      return;
    }
    try {
      if (_playing) {
        await _audioService.pause();
        return;
      }
      await _audioService.play();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Playback failed: $e');
    }
  }

  void _resetPlayhead() async {
    await _audioService.pause();
    await _audioService.seek(0);
    setState(() {
      _playing = false;
      _elapsed = Duration.zero;
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
      await _audioService.stop();
      bool isAudioPrepared = false;
      String? audioError;
      final mp3Base64 = result.mp3Base64;
      if (mp3Base64 != null && mp3Base64.isNotEmpty) {
        try {
          await _audioService.loadBytes(base64Decode(mp3Base64), mimeType: 'audio/mpeg');
          isAudioPrepared = true;
        } catch (e) {
          audioError = 'MP3 preview unavailable: $e';
        }
      }

      setState(() {
        _composition = result;
        _elapsed = Duration.zero;
        _playing = false;
        _isAudioPrepared = isAudioPrepared;
        _maxPlaybackMs = _calculatePlaybackMs(result.metadata.totalBeats, result.metadata.tempoBpm);
        _error = audioError;
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
      final fileName = 'musiclens-composition-${c.compositionId.substring(0, _idPrefixLength)}.mid';
      final saved = await FilePicker.saveFile(
        dialogTitle: 'Save MIDI file',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['mid', 'midi'],
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

  Future<void> _downloadMp3() async {
    final c = _composition;
    final mp3Base64 = c?.mp3Base64;
    if (c == null || mp3Base64 == null || mp3Base64.isEmpty) return;
    try {
      final bytes = base64Decode(mp3Base64);
      final fileName = 'musiclens-composition-${c.compositionId.substring(0, _idPrefixLength)}.mp3';
      final saved = await FilePicker.saveFile(
        dialogTitle: 'Save MP3 file',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['mp3'],
        bytes: Uint8List.fromList(bytes),
      );
      if (!mounted) return;
      final msg = saved == null ? 'Export cancelled' : 'MP3 exported to $saved';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to export MP3: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final composition = _composition;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.ivory.withValues(alpha: 0.92),
            AppTheme.paper.withValues(alpha: 0.7),
            Colors.transparent,
          ],
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _headerCard(),
            const SizedBox(height: 12),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(_error!, style: const TextStyle(color: Colors.redAccent)),
              ),
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 1040;
                final form = CompositionForm(onSubmit: _compose, isLoading: _isLoading, apiService: _api);

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
      ),
    );
  }

  Widget _headerCard() {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppTheme.paper.withValues(alpha: 0.92),
          AppTheme.ivory.withValues(alpha: 0.88),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: const LinearGradient(
                colors: [AppTheme.tan, AppTheme.antiqueBrass],
              ),
            ),
            child: const Icon(Icons.auto_awesome_rounded, color: AppTheme.cocoaBrown, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Music Composer Studio',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppTheme.cocoaBrown,
                      ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Generate, preview, and export MIDI + MP3 ideas in seconds.',
                  style: TextStyle(
                    color: AppTheme.buccaneer,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
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
            const Icon(Icons.music_note_rounded, size: 48, color: AppTheme.tan),
            const SizedBox(height: 12),
            Text(
              'Describe the music and press Compose.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.paper,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 6),
               const Text(
                 'A multi-stage LangGraph pipeline interprets your prompt, '
                 'then a procedural music engine arranges melody, harmony, '
                 'bass, and drums into a MIDI piece with optional in-app MP3 preview.',
                 textAlign: TextAlign.center,
                 style: TextStyle(color: AppTheme.tan, height: 1.5),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Tooltip(
                message: _isAudioPrepared
                    ? 'Play generated MP3 preview'
                    : 'MP3 preview unavailable for this composition',
                child: IconButton(
                  onPressed: _isAudioPrepared ? _togglePlay : null,
                  icon: Icon(_playing ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded),
                  color: AppTheme.antiqueBrass,
                  iconSize: 36,
                ),
              ),
              IconButton(
                onPressed: _resetPlayhead,
                icon: const Icon(Icons.replay_rounded),
                color: AppTheme.tan,
                tooltip: 'Reset playhead',
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    LinearProgressIndicator(
                      value: c.metadata.totalBeats == 0 ? 0 : (beat / c.metadata.totalBeats).clamp(0.0, 1.0),
                      backgroundColor: AppTheme.buccaneer.withValues(alpha: 0.7),
                      color: AppTheme.antiqueBrass,
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Beat ${beat.toStringAsFixed(1)} / ${c.metadata.totalBeats.toStringAsFixed(0)}'
                      '   ·   ${c.metadata.tempoBpm} BPM',
                      style: const TextStyle(color: AppTheme.tan, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              if (c.mp3Base64 != null && c.mp3Base64!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilledButton.icon(
                    onPressed: _downloadMp3,
                    icon: const Icon(Icons.graphic_eq_rounded, size: 18),
                    label: const Text('MP3'),
                  ),
                ),
              FilledButton.icon(
                onPressed: _downloadMidi,
                icon: const Icon(Icons.download_rounded, size: 18),
                label: const Text('MIDI'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.capePalliser.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.tan.withValues(alpha: 0.32)),
            ),
             child: Row(
               children: [
                 const Icon(Icons.info_rounded, size: 16, color: AppTheme.tan),
                 const SizedBox(width: 8),
                 Expanded(
                   child: Text(
                      _isAudioPrepared
                          ? 'Playing synthesized MP3 preview in-app. Export MIDI for DAWs and MIDI editors.'
                          : 'MP3 preview unavailable due to backend synthesis failure. You can still export MIDI.',
                      style: const TextStyle(fontSize: 11, color: AppTheme.tan),
                    ),
                  ),
               ],
             ),
          ),
        ],
      ),
    );
  }
}
