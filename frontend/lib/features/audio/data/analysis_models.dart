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

class InsightSegment {
  const InsightSegment({
    required this.start,
    required this.end,
    required this.label,
  });

  final double start;
  final double end;
  final String label;

  factory InsightSegment.fromJson(Map<String, dynamic> json) {
    return InsightSegment(
      start: (json['start'] as num).toDouble(),
      end: (json['end'] as num).toDouble(),
      label: json['label'].toString(),
    );
  }
}

class CategorizedInsight {
  const CategorizedInsight({
    required this.text,
    required this.category,
  });

  final String text;
  final String category; // rhythm, melody, energy, structure

  factory CategorizedInsight.fromJson(Map<String, dynamic> json) {
    return CategorizedInsight(
      text: json['text'].toString(),
      category: json['category'].toString(),
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
    required this.bassEnergy,
    required this.bassTimes,
    required this.spectrumFrequencies,
    required this.spectrumFrames,
    required this.insights,
    required this.categorizedInsights,
    required this.insightTimeline,
    required this.genre,
    required this.genreConfidence,
    required this.lyrics,
  });

  final double duration;
  final int sampleRate;
  final double bpm;
  final List<double> beatTimestamps;
  final List<double> pitchHz;
  final List<double> pitchTimes;
  final List<double> energyRms;
  final List<double> energyTimes;
  final List<double> bassEnergy;
  final List<double> bassTimes;
  final List<double> spectrumFrequencies;
  final List<SpectrumFrame> spectrumFrames;
  final List<String> insights;
  final List<CategorizedInsight> categorizedInsights;
  final List<InsightSegment> insightTimeline;
  final String genre;
  final double genreConfidence;
  final String lyrics;

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
        bassEnergy: (json['bass_energy'] as List<dynamic>)
          .map((value) => (value as num).toDouble())
          .toList(growable: false),
        bassTimes: (json['bass_times'] as List<dynamic>)
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
      categorizedInsights: (json['categorized_insights'] as List<dynamic>? ?? <dynamic>[])
          .map((insight) => CategorizedInsight.fromJson(insight as Map<String, dynamic>))
          .toList(growable: false),
      insightTimeline: (json['insight_timeline'] as List<dynamic>)
          .map((segment) => InsightSegment.fromJson(segment as Map<String, dynamic>))
          .toList(growable: false),
      genre: (json['genre'] ?? 'Unknown').toString(),
      genreConfidence: (json['genre_confidence'] as num? ?? 0.0).toDouble(),
      lyrics: (json['lyrics'] ?? '').toString(),
    );
  }
}
