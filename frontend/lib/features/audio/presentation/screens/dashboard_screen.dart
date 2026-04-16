import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../../core/widgets/glass_card.dart';
import '../../data/analysis_models.dart';
import '../../data/audio_api_service.dart';
import '../widgets/animated_background.dart';
import '../widgets/insights_panel.dart';
import '../widgets/metric_chip.dart';
import '../widgets/spectrum_panel.dart';
import '../widgets/waveform_panel.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final AudioApiService _apiService = AudioApiService();

  PlatformFile? _selectedFile;
  AudioAnalysisResponse? _analysis;
  bool _isLoading = false;
  String? _error;

  bool _isPlaying = false;
  double _currentTime = 0;
  Timer? _playbackTimer;

  @override
  void dispose() {
    _playbackTimer?.cancel();
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
                        onSeek: _onSeek,
                      );

                      final sidePanel = Column(
                        children: [
                          SpectrumPanel(
                            magnitudes: _spectrumAtCurrentTime,
                            energy: energy,
                          ),
                          const SizedBox(height: 12),
                          InsightsPanel(
                            currentInsight: _currentInsight,
                            insights: _analysis?.insights ?? const ['Waiting for analysis...'],
                          ),
                        ],
                      );

                      if (isWide) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(flex: 3, child: mainVisual),
                            const SizedBox(width: 12),
                            Expanded(flex: 2, child: sidePanel),
                          ],
                        );
                      }

                      return SingleChildScrollView(
                        child: Column(
                          children: [
                            mainVisual,
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
            label: Text(_isPlaying ? 'Pause Visual Sync' : 'Play Visual Sync'),
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
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      withData: true,
      allowedExtensions: ['mp3', 'wav', 'flac', 'ogg', 'm4a'],
    );

    if (result == null || result.files.isEmpty) {
      return;
    }

    setState(() {
      _selectedFile = result.files.single;
      _error = null;
    });
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

  void _togglePlayback() {
    if (_analysis == null) {
      return;
    }

    setState(() {
      _isPlaying = !_isPlaying;
    });

    _playbackTimer?.cancel();
    if (!_isPlaying) {
      return;
    }

    _playbackTimer = Timer.periodic(const Duration(milliseconds: 40), (_) {
      if (!mounted) {
        return;
      }

      final duration = _analysis!.duration;
      setState(() {
        _currentTime += 0.04;
        if (_currentTime >= duration) {
          _currentTime = duration;
          _isPlaying = false;
          _playbackTimer?.cancel();
        }
      });
    });
  }

  void _onSeek(double seconds) {
    setState(() {
      _currentTime = seconds;
    });
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

  String get _currentInsight {
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
