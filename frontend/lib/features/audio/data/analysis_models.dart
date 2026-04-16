class SpectrumFrame {
  const SpectrumFrame({required this.time, required this.magnitudes});

  final double time;
  final List<double> magnitudes;

  factory SpectrumFrame.fromJson(Map<String, dynamic> json) {
    return SpectrumFrame(
      time: (json['time'] as num).toDouble(),
      magnitudes: (json['magnitudes'] as List<dynamic>)
          .map((value) => (value as num).toDouble())
          .toList(growable: false),
    );
  }
}

class AudioAnalysisResponse {
  const AudioAnalysisResponse({
    required this.duration,
    required this.sampleRate,
    required this.bpm,
    required this.beatTimestamps,
    required this.pitchHz,
    required this.pitchTimes,
    required this.energyRms,
    required this.energyTimes,
    required this.spectrumFrequencies,
    required this.spectrumFrames,
    required this.insights,
  });

  final double duration;
  final int sampleRate;
  final double bpm;
  final List<double> beatTimestamps;
  final List<double> pitchHz;
  final List<double> pitchTimes;
  final List<double> energyRms;
  final List<double> energyTimes;
  final List<double> spectrumFrequencies;
  final List<SpectrumFrame> spectrumFrames;
  final List<String> insights;

  factory AudioAnalysisResponse.fromJson(Map<String, dynamic> json) {
    return AudioAnalysisResponse(
      duration: (json['duration'] as num).toDouble(),
      sampleRate: (json['sample_rate'] as num).toInt(),
      bpm: (json['bpm'] as num).toDouble(),
      beatTimestamps: (json['beat_timestamps'] as List<dynamic>)
          .map((value) => (value as num).toDouble())
          .toList(growable: false),
      pitchHz: (json['pitch_hz'] as List<dynamic>)
          .map((value) => (value as num).toDouble())
          .toList(growable: false),
      pitchTimes: (json['pitch_times'] as List<dynamic>)
          .map((value) => (value as num).toDouble())
          .toList(growable: false),
      energyRms: (json['energy_rms'] as List<dynamic>)
          .map((value) => (value as num).toDouble())
          .toList(growable: false),
      energyTimes: (json['energy_times'] as List<dynamic>)
          .map((value) => (value as num).toDouble())
          .toList(growable: false),
      spectrumFrequencies: (json['spectrum_frequencies'] as List<dynamic>)
          .map((value) => (value as num).toDouble())
          .toList(growable: false),
      spectrumFrames: (json['spectrum_frames'] as List<dynamic>)
          .map((frame) => SpectrumFrame.fromJson(frame as Map<String, dynamic>))
          .toList(growable: false),
      insights: (json['insights'] as List<dynamic>)
          .map((value) => value.toString())
          .toList(growable: false),
    );
  }
}
