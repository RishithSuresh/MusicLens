/// Data models mirroring `backend/app/models/composition.py`.
///
/// Kept intentionally small and JSON-shape-compatible with the FastAPI
/// payload returned by the `POST /compose` endpoint.
class CompositionNote {
  const CompositionNote({
    required this.pitch,
    required this.startBeat,
    required this.durationBeats,
    required this.velocity,
  });

  final int pitch;
  final double startBeat;
  final double durationBeats;
  final int velocity;

  factory CompositionNote.fromJson(Map<String, dynamic> json) {
    return CompositionNote(
      pitch: (json['pitch'] as num).toInt(),
      startBeat: (json['start_beat'] as num).toDouble(),
      durationBeats: (json['duration_beats'] as num).toDouble(),
      velocity: (json['velocity'] as num).toInt(),
    );
  }
}

class CompositionTrack {
  const CompositionTrack({
    required this.name,
    required this.instrument,
    required this.program,
    required this.isDrum,
    required this.notes,
  });

  final String name;
  final String instrument;
  final int program;
  final bool isDrum;
  final List<CompositionNote> notes;

  factory CompositionTrack.fromJson(Map<String, dynamic> json) {
    return CompositionTrack(
      name: json['name'].toString(),
      instrument: json['instrument'].toString(),
      program: (json['program'] as num).toInt(),
      isDrum: json['is_drum'] as bool? ?? false,
      notes: (json['notes'] as List<dynamic>)
          .map((n) => CompositionNote.fromJson(n as Map<String, dynamic>))
          .toList(growable: false),
    );
  }
}

class CompositionSection {
  const CompositionSection({
    required this.name,
    required this.startBeat,
    required this.endBeat,
    required this.description,
  });

  final String name;
  final double startBeat;
  final double endBeat;
  final String? description;

  factory CompositionSection.fromJson(Map<String, dynamic> json) {
    return CompositionSection(
      name: json['name'].toString(),
      startBeat: (json['start_beat'] as num).toDouble(),
      endBeat: (json['end_beat'] as num).toDouble(),
      description: json['description'] as String?,
    );
  }
}

class CompositionMetadata {
  const CompositionMetadata({
    required this.key,
    required this.mode,
    required this.tempoBpm,
    required this.timeSignature,
    required this.bars,
    required this.totalBeats,
    required this.style,
    required this.mood,
    required this.genre,
    required this.chordProgression,
    required this.instruments,
  });

  final String key;
  final String mode;
  final int tempoBpm;
  final String timeSignature;
  final int bars;
  final double totalBeats;
  final String style;
  final String mood;
  final String genre;
  final List<String> chordProgression;
  final List<String> instruments;

  factory CompositionMetadata.fromJson(Map<String, dynamic> json) {
    return CompositionMetadata(
      key: json['key'].toString(),
      mode: json['mode'].toString(),
      tempoBpm: (json['tempo_bpm'] as num).toInt(),
      timeSignature: json['time_signature'].toString(),
      bars: (json['bars'] as num).toInt(),
      totalBeats: (json['total_beats'] as num).toDouble(),
      style: json['style'].toString(),
      mood: json['mood'].toString(),
      genre: json['genre'].toString(),
      chordProgression: (json['chord_progression'] as List<dynamic>)
          .map((v) => v.toString())
          .toList(growable: false),
      instruments: (json['instruments'] as List<dynamic>)
          .map((v) => v.toString())
          .toList(growable: false),
    );
  }
}

class CompositionResponse {
  const CompositionResponse({
    required this.compositionId,
    required this.metadata,
    required this.structure,
    required this.tracks,
    required this.narrative,
    required this.usedLlm,
    required this.midiBase64,
  });

  final String compositionId;
  final CompositionMetadata metadata;
  final List<CompositionSection> structure;
  final List<CompositionTrack> tracks;
  final String narrative;
  final bool usedLlm;
  final String midiBase64;

  factory CompositionResponse.fromJson(Map<String, dynamic> json) {
    return CompositionResponse(
      compositionId: json['composition_id'].toString(),
      metadata: CompositionMetadata.fromJson(json['metadata'] as Map<String, dynamic>),
      structure: (json['structure'] as List<dynamic>)
          .map((s) => CompositionSection.fromJson(s as Map<String, dynamic>))
          .toList(growable: false),
      tracks: (json['tracks'] as List<dynamic>)
          .map((t) => CompositionTrack.fromJson(t as Map<String, dynamic>))
          .toList(growable: false),
      narrative: json['narrative'].toString(),
      usedLlm: json['used_llm'] as bool? ?? false,
      midiBase64: json['midi_base64'].toString(),
    );
  }
}
