import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../../core/widgets/glass_card.dart';
import '../../data/analysis_models.dart';
import '../../data/audio_api_service.dart';
import '../../data/audio_playback_service.dart';
import '../widgets/animated_background.dart';
import '../widgets/insights_panel.dart';
import '../widgets/lyrics_panel.dart';
import '../widgets/metric_chip.dart';
import '../widgets/music_dna_panel.dart';
import '../widgets/spectrum_panel.dart';
import '../widgets/waveform_panel.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final AudioApiService _apiService = AudioApiService();
  final AudioPlaybackService _playbackService = AudioPlaybackService();

  PlatformFile? _selectedFile;
  AudioAnalysisResponse? _analysis;
  bool _isLoading = false;
  bool _isAudioPrepared = false;
  String? _error;

  bool _isPlaying = false;
  double _currentTime = 0;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<PlayerState>? _stateSub;

  @override
  void initState() {
    super.initState();

    _positionSub = _playbackService.positionStream.listen((position) {
      if (!mounted) {
        return;
      }

      final seconds = position.inMilliseconds / 1000;
      final maxDuration = _analysis?.duration;
      setState(() {
        _currentTime = maxDuration == null ? seconds : seconds.clamp(0.0, maxDuration);
      });
    });

    _stateSub = _playbackService.stateStream.listen((state) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isPlaying = state == PlayerState.playing;
      });
    });
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _stateSub?.cancel();
    _playbackService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final duration = _analysis?.duration ?? 120;
    final energy = _currentEnergy;

    return Scaffold(
      body: AnimatedBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
            child: Column(
              children: [
                _buildTopBar(),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    MetricChip(label: 'BPM', value: (_analysis?.bpm ?? 0).toStringAsFixed(1)),
                    MetricChip(label: 'Duration', value: '${duration.toStringAsFixed(1)}s'),
                    MetricChip(label: 'Sample Rate', value: '${_analysis?.sampleRate ?? 0} Hz'),
                    MetricChip(label: 'Energy', value: '${(energy * 100).toStringAsFixed(0)}%'),
                      MetricChip(label: 'Playhead', value: '${_currentTime.toStringAsFixed(2)}s'),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 1040;

                      final mainVisual = WaveformPanel(
                        energy: _analysis?.energyRms ?? const [],
                        beatTimestamps: _analysis?.beatTimestamps ?? const [],
                        pitch: _analysis?.pitchHz ?? const [],
                        duration: duration,
                        currentTime: _currentTime,
                        bpm: _analysis?.bpm ?? 0,
                        currentEnergy: _currentEnergy,
                        currentBass: _currentBass,
                        onSeek: _onSeek,
                      );

                      final mainPanel = Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: mainVisual),
                          const SizedBox(height: 12),
                          LyricsPanel(
                            lyrics: _analysis?.lyrics ?? '',
                            currentTime: _currentTime,
                            totalDuration: duration,
                            maxHeight: isWide ? 140 : 180,
                          ),
                        ],
                      );

                      final sidePanel = Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SpectrumPanel(
                            magnitudes: _spectrumAtCurrentTime,
                            energy: energy,
                          ),
                          const SizedBox(height: 12),
                          InsightsPanel(
                            currentInsight: _currentInsight,
                            insights: _analysis?.insights ?? const ['Waiting for analysis...'],
                            currentTime: _currentTime,
                            totalDuration: duration,
                          ),
                          const SizedBox(height: 12),
                          MusicDnaPanel(
                            bpm: _analysis?.bpm ?? 0,
                            energyMean: _energyMean,
                            energyVariance: _energyVariance,
                            pitchRange: _pitchRange,
                          ),
                        ],
                      );

                      if (isWide) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(flex: 3, child: mainPanel),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: SingleChildScrollView(child: sidePanel),
                            ),
                          ],
                        );
                      }

                      return SingleChildScrollView(
                        child: Column(
                          children: [
                            SizedBox(
                              height: 560,
                              child: mainPanel,
                            ),
                            const SizedBox(height: 12),
                            sidePanel,
                          ],
                        ),
                      );
                    },
                  ),
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 12,
        children: [
          Text(
            'MusicLens',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(width: 2),
          FilledButton.icon(
            onPressed: _pickAudio,
            icon: const Icon(Icons.audio_file_rounded),
            label: Text(_selectedFile == null ? 'Select Audio' : 'Change Audio'),
          ),
          FilledButton.tonalIcon(
            onPressed: _selectedFile == null || _isLoading ? null : _analyze,
            icon: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.analytics_outlined),
            label: const Text('Analyze'),
          ),
          FilledButton.tonalIcon(
            onPressed: _analysis == null ? null : _togglePlayback,
            icon: Icon(_isPlaying ? Icons.pause_circle : Icons.play_circle_fill),
            label: Text(_isPlaying ? 'Pause Audio' : 'Play Audio'),
          ),
          FilledButton.tonalIcon(
            onPressed: _analysis == null ? null : _downloadAnalysisJson,
            icon: const Icon(Icons.download_rounded),
            label: const Text('Export JSON'),
          ),
          Text(
            _selectedFile?.name ?? 'No audio selected',
            style: const TextStyle(color: Color(0xFF334155)),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAudio() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      withData: true,
      allowedExtensions: ['mp3', 'wav', 'flac', 'ogg', 'm4a'],
    );

    if (result == null || result.files.isEmpty) {
      return;
    }

    setState(() {
      _selectedFile = result.files.single;
      _analysis = null;
      _currentTime = 0;
      _error = null;
    });

    await _prepareAudio(result.files.single);
  }

  Future<void> _analyze() async {
    final file = _selectedFile;
    if (file == null) {
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _apiService.analyzeAudio(file);
      setState(() {
        _analysis = response;
        _currentTime = 0;
      });

      if (!_isAudioPrepared) {
        await _prepareAudio(file);
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to analyze audio: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _downloadAnalysisJson() async {
    final analysis = _analysis;
    if (analysis == null) {
      return;
    }

    try {
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final fileName = 'musiclens-analysis-$timestamp.json';
      final jsonText = const JsonEncoder.withIndent('  ').convert(_analysisToJson(analysis));

      final savedPath = await FilePicker.saveFile(
        dialogTitle: 'Save analysis JSON',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['json'],
        bytes: Uint8List.fromList(utf8.encode(jsonText)),
      );

      if (!mounted) {
        return;
      }

      final message = savedPath == null
          ? 'Export cancelled'
          : 'Analysis JSON exported successfully';

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to export JSON: $e')),
      );
    }
  }

  Map<String, dynamic> _analysisToJson(AudioAnalysisResponse analysis) {
    return {
      'duration': analysis.duration,
      'sample_rate': analysis.sampleRate,
      'bpm': analysis.bpm,
      'beat_timestamps': analysis.beatTimestamps,
      'pitch_hz': analysis.pitchHz,
      'pitch_times': analysis.pitchTimes,
      'energy_rms': analysis.energyRms,
      'energy_times': analysis.energyTimes,
      'bass_energy': analysis.bassEnergy,
      'bass_times': analysis.bassTimes,
      'spectrum_frequencies': analysis.spectrumFrequencies,
      'spectrum_frames': analysis.spectrumFrames
          .map((frame) => {'time': frame.time, 'magnitudes': frame.magnitudes})
          .toList(growable: false),
      'insights': analysis.insights,
      'insight_timeline': analysis.insightTimeline
          .map((segment) => {
                'start': segment.start,
                'end': segment.end,
                'label': segment.label,
              })
          .toList(growable: false),
      'lyrics': analysis.lyrics,
      'exported_at': DateTime.now().toIso8601String(),
    };
  }

  void _togglePlayback() {
    if (_analysis == null || !_isAudioPrepared) {
      return;
    }

    if (_isPlaying) {
      _playbackService.pause();
      return;
    }

    _playbackService.play();
  }

  void _onSeek(double seconds) {
    setState(() {
      _currentTime = seconds;
    });
    _playbackService.seek(seconds);
  }

  Future<void> _prepareAudio(PlatformFile file) async {
    try {
      await _playbackService.loadFile(file);
      setState(() {
        _isAudioPrepared = true;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _isAudioPrepared = false;
        _error = 'Failed to load audio for playback: $e';
      });
    }
  }

  List<double> get _spectrumAtCurrentTime {
    final analysis = _analysis;
    if (analysis == null || analysis.spectrumFrames.isEmpty) {
      return const [];
    }

    final index = analysis.spectrumFrames.indexWhere((frame) => frame.time >= _currentTime);
    if (index == -1) {
      return analysis.spectrumFrames.last.magnitudes;
    }
    return analysis.spectrumFrames[index].magnitudes;
  }

  double get _currentEnergy {
    final analysis = _analysis;
    if (analysis == null || analysis.energyRms.isEmpty || analysis.duration <= 0) {
      return 0;
    }

    final idx = ((_currentTime / analysis.duration) * (analysis.energyRms.length - 1))
        .round()
        .clamp(0, analysis.energyRms.length - 1);
    return analysis.energyRms[idx];
  }

  double get _currentBass {
    final analysis = _analysis;
    if (analysis == null || analysis.bassEnergy.isEmpty || analysis.duration <= 0) {
      return 0;
    }

    final idx = ((_currentTime / analysis.duration) * (analysis.bassEnergy.length - 1))
        .round()
        .clamp(0, analysis.bassEnergy.length - 1);
    return analysis.bassEnergy[idx];
  }

  double get _energyMean {
    final energy = _analysis?.energyRms;
    if (energy == null || energy.isEmpty) {
      return 0;
    }
    return energy.reduce((a, b) => a + b) / energy.length;
  }

  double get _energyVariance {
    final energy = _analysis?.energyRms;
    if (energy == null || energy.isEmpty) {
      return 0;
    }
    final mean = _energyMean;
    final sum = energy.fold<double>(0, (acc, v) => acc + ((v - mean) * (v - mean)));
    return sum / energy.length;
  }

  double get _pitchRange {
    final pitchValues = (_analysis?.pitchHz ?? const []).where((value) => value > 0).toList(growable: false);
    if (pitchValues.isEmpty) {
      return 0;
    }
    final minPitch = pitchValues.reduce((a, b) => a < b ? a : b);
    final maxPitch = pitchValues.reduce((a, b) => a > b ? a : b);
    return maxPitch - minPitch;
  }

  String get _currentInsight {
    final timeline = _analysis?.insightTimeline ?? const [];
    for (final segment in timeline) {
      if (_currentTime >= segment.start && _currentTime <= segment.end) {
        return segment.label;
      }
    }

    final energy = _currentEnergy;
    if (energy > 0.72) {
      return 'High energy chorus';
    }
    if (energy > 0.48) {
      return 'Beat drop detected';
    }
    if (energy > 0.25) {
      return 'Steady rhythmic section';
    }
    return 'Low intensity intro';
  }
}
