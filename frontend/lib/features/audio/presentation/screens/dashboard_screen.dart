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
import '../widgets/beat_synced_pulse_overlay.dart';
import '../widgets/insights_panel.dart';
import '../widgets/lyrics_panel.dart';
import '../widgets/metric_chip.dart';
import '../widgets/music_dna_panel.dart';
import '../widgets/spectrum_panel.dart';
import '../widgets/timeline_scrubber.dart';
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
  bool _pulseEnabled = true;
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
        child: Stack(
          children: [
            if (_pulseEnabled)
              Positioned.fill(
                child: BeatSyncedPulseOverlay(
                  currentTime: _currentTime,
                  duration: duration,
                  beatTimestamps: _analysis?.beatTimestamps ?? const [],
                  energy: _currentEnergy,
                  bass: _currentBass,
                  isPlaying: _isPlaying,
                ),
              ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
                child: Column(
                  children: [
                    TimelineScrubber(
                      currentTime: _currentTime,
                      totalDuration: duration,
                      onSeek: _onSeek,
                    ),
                    const SizedBox(height: 8),
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
                        MetricChip(label: 'Genre', value: _analysis?.genre ?? 'Unknown'),
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
                            compact: !isWide,
                          );

                          final mainPanel = isWide
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(child: mainVisual),
                                    const SizedBox(height: 12),
                                    LyricsPanel(
                                      lyrics: _analysis?.lyrics ?? '',
                                      currentTime: _currentTime,
                                      totalDuration: duration,
                                      maxHeight: 140,
                                    ),
                                  ],
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    mainVisual,
                                    const SizedBox(height: 12),
                                    LyricsPanel(
                                      lyrics: _analysis?.lyrics ?? '',
                                      currentTime: _currentTime,
                                      totalDuration: duration,
                                      maxHeight: 110,
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
                                categorizedInsights: _analysis?.categorizedInsights ?? const [],
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
                            physics: const BouncingScrollPhysics(),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                mainPanel,
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
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    final theme = Theme.of(context);
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.8),
          Colors.white.withValues(alpha: 0.65),
        ],
      ),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 14,
        runSpacing: 14,
        children: [
          ShaderMask(
            shaderCallback: (bounds) {
              return const LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
              ).createShader(bounds);
            },
            child: Text(
              'MusicLens',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const VerticalDivider(width: 1, thickness: 1, color: Color(0xFFE2E8F0)),
          _buildActionButton(
            onPressed: _pickAudio,
            icon: Icons.audio_file_rounded,
            label: _selectedFile == null ? 'Select' : 'Change',
            theme: theme,
          ),
          _buildActionButton(
            onPressed: _selectedFile == null || _isLoading ? null : _analyze,
            icon: _isLoading ? null : Icons.analytics_outlined,
            label: 'Analyze',
            theme: theme,
            isLoading: _isLoading,
          ),
          _buildActionButton(
            onPressed: _analysis == null ? null : _togglePlayback,
            icon: _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
            label: _isPlaying ? 'Pause' : 'Play',
            theme: theme,
            isPrimary: _analysis != null,
          ),
          _EnhancedToggleChip(
            selected: _pulseEnabled,
            onSelected: (value) {
              setState(() {
                _pulseEnabled = value;
              });
            },
            icon: Icons.bolt_rounded,
            label: 'Pulse FX',
          ),
          _buildActionButton(
            onPressed: _analysis == null ? null : _downloadAnalysisJson,
            icon: Icons.download_rounded,
            label: 'Export',
            theme: theme,
          ),
          Tooltip(
            message: _selectedFile?.name ?? 'No audio selected',
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: const Color(0xFFF1F5F9).withValues(alpha: 0.8),
                border: Border.all(
                  color: const Color(0xFFE2E8F0),
                  width: 1.5,
                ),
              ),
              child: Text(
                ((_selectedFile?.name?.length ?? 0) > 20)
                    ? '${_selectedFile!.name!.substring(0, 17)}...'
                    : (_selectedFile?.name ?? 'No file'),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF475569),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required VoidCallback? onPressed,
    required IconData? icon,
    required String label,
    required ThemeData theme,
    bool isPrimary = false,
    bool isLoading = false,
  }) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: isLoading
          ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  theme.colorScheme.onPrimary,
                ),
              ),
            )
          : Icon(icon, size: 18),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: isPrimary ? theme.colorScheme.primary : const Color(0xFFF1F5F9),
        foregroundColor: isPrimary ? Colors.white : theme.colorScheme.primary,
        elevation: isPrimary ? 6 : 2,
        shadowColor: isPrimary
            ? theme.colorScheme.primary.withValues(alpha: 0.4)
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
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

class _EnhancedToggleChip extends StatefulWidget {
  const _EnhancedToggleChip({
    required this.selected,
    required this.onSelected,
    required this.icon,
    required this.label,
  });

  final bool selected;
  final ValueChanged<bool> onSelected;
  final IconData icon;
  final String label;

  @override
  State<_EnhancedToggleChip> createState() => _EnhancedToggleChipState();
}

class _EnhancedToggleChipState extends State<_EnhancedToggleChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, _) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: FilterChip(
            selected: widget.selected,
            onSelected: (value) {
              if (value) {
                _controller.forward();
              } else {
                _controller.reverse();
              }
              widget.onSelected(value);
            },
            avatar: Icon(
              widget.icon,
              size: 18,
              color: widget.selected ? Colors.white : const Color(0xFF3B82F6),
            ),
            label: Text(
              widget.label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: widget.selected ? Colors.white : const Color(0xFF3B82F6),
              ),
            ),
            backgroundColor: Colors.white.withValues(alpha: 0.7),
            selectedColor: const Color(0xFF3B82F6),
            side: BorderSide(
              color: widget.selected
                  ? const Color(0xFF3B82F6)
                  : const Color(0xFF3B82F6).withValues(alpha: 0.3),
              width: widget.selected ? 2 : 1.5,
            ),
            elevation: widget.selected ? 6 : 2,
            pressElevation: 8,
          ),
        );
      },
    );
  }
}
