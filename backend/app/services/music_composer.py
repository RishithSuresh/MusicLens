"""Top-level entry point for the AI Music Compositor feature.

Combines the LangGraph LLM interpretation layer with the deterministic
procedural composer, then renders the result to a MIDI file using the
``mido``-free path provided by ``music21``. Returns a fully-populated
``CompositionResponse`` ready to ship to the frontend.
"""
from __future__ import annotations

import base64
import uuid

from app.models.composition import (
    CompositionMetadata,
    CompositionNote,
    CompositionRequest,
    CompositionResponse,
    CompositionSection,
    CompositionTrack,
)
from app.services.composer_llm import interpret_prompt, write_narrative
from app.services.music_theory import KeyContext, parse_key
from app.services.procedural_composer import (
    CompositionPlan,
    SectionData,
    TrackData,
    compose_procedural,
)

MIN_MP3_SIZE_BYTES = 100
DRUM_BASE_FREQ_HZ = 120
DRUM_PITCH_STEP_HZ = 25
DRUM_DECAY_RATE = 12
NOTE_FADE_SECONDS = 0.01
DRUM_MIDI_BASE_NOTE = 35
DRUM_MIDI_MAX_OFFSET = 46
DRUM_VOLUME_SCALE = 0.4
NOTE_VOLUME_SCALE = 0.28
AUDIO_NORMALIZATION_HEADROOM = 0.95
FALLBACK_BEAT_MULTIPLIER = 2
MIN_NOTE_DURATION_BEATS = 0.125
MIN_VELOCITY_SCALE = 0.05
MAX_VELOCITY_SCALE = 1.0
MIN_FADE_SAMPLES = 1


def _to_response_track(track: TrackData) -> CompositionTrack:
    return CompositionTrack(
        name=track.name,
        instrument=track.instrument,
        program=track.program,
        is_drum=track.is_drum,
        notes=[
            CompositionNote(
                pitch=n.pitch,
                start_beat=round(n.start_beat, 4),
                duration_beats=round(n.duration_beats, 4),
                velocity=n.velocity,
            )
            for n in track.notes
        ],
    )


def _to_response_section(section: SectionData) -> CompositionSection:
    return CompositionSection(
        name=section.name,
        start_beat=round(section.start_beat, 4),
        end_beat=round(section.end_beat, 4),
        description=section.description or None,
    )


def _render_midi(tracks: list[TrackData], tempo_bpm: int, beats_per_bar: int) -> bytes:
    """Render the in-memory tracks to a MIDI file using ``music21``.

    Imported lazily so the rest of the API still functions when the optional
    composer dependencies are not installed.
    """
    try:
        import music21  # local import: optional dependency
    except ImportError as e:
        raise ImportError(
            f"music21 is required for MIDI rendering. Install it with: pip install music21. Error: {e}"
        ) from e

    score = music21.stream.Score()
    score.insert(0, music21.tempo.MetronomeMark(number=tempo_bpm))
    score.insert(0, music21.meter.TimeSignature(f"{beats_per_bar}/4"))

    for track in tracks:
        part = music21.stream.Part()
        part.partName = track.name
        if track.is_drum:
            # Channel 10 is reserved for drums in standard MIDI.
            part.insert(0, music21.instrument.Percussion())
        else:
            inst = music21.instrument.instrumentFromMidiProgram(track.program)
            inst.midiChannel = None
            part.insert(0, inst)
        for note in track.notes:
            element: music21.note.GeneralNote
            if track.is_drum:
                element = music21.note.Unpitched()
                element.storedInstrument = music21.instrument.SnareDrum()
                element.pitch = music21.pitch.Pitch(midi=note.pitch)  # type: ignore[attr-defined]
            else:
                element = music21.note.Note()
                element.pitch = music21.pitch.Pitch(midi=note.pitch)
            element.quarterLength = max(0.125, note.duration_beats)
            element.volume.velocity = max(1, min(127, note.velocity))
            part.insert(note.start_beat, element)
        score.insert(0, part)

    midi_file = music21.midi.translate.streamToMidiFile(score)
    return midi_file.writestr()


def _render_to_mp3(tracks: list[TrackData], tempo_bpm: int, beats_per_bar: int) -> bytes | None:
    """Render the in-memory tracks to MP3 audio using lightweight synthesis.

    Returns ``None`` if MP3 synthesis fails.
    """
    if tempo_bpm <= 0:
        raise ValueError(f"tempo_bpm must be greater than 0, got {tempo_bpm}")
    if beats_per_bar <= 0:
        raise ValueError(f"beats_per_bar must be greater than 0, got {beats_per_bar}")

    import io
    import os
    import tempfile

    try:
        import numpy as np
        from pydub import AudioSegment
        from scipy.io import wavfile
    except ImportError as e:
        print(
            "Warning: audio synthesis dependencies not available "
            f"({e}). MP3 export disabled. "
            "Install backend dependencies: pip install -r requirements.txt "
            "(or the full composer set: pip install -r requirements-composer.txt)"
        )
        return None

    try:
        with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as wav_temp:
            wav_path = wav_temp.name
        try:
            seconds_per_beat = 60.0 / tempo_bpm
            total_beats = max(
                (
                    note.start_beat + max(note.duration_beats, MIN_NOTE_DURATION_BEATS)
                    for track in tracks
                    for note in track.notes
                ),
                default=float(beats_per_bar * FALLBACK_BEAT_MULTIPLIER),
            )
            duration_sec = max(2.0, total_beats * seconds_per_beat + 0.5)

            sample_rate = 44100
            audio_data = np.zeros(int(duration_sec * sample_rate), dtype=np.float32)

            def midi_to_freq(midi_note: int) -> float:
                return 440 * (2 ** ((midi_note - 69) / 12))

            for track in tracks:
                for note in track.notes:
                    start_sample = max(0, int(note.start_beat * seconds_per_beat * sample_rate))
                    duration_samples = max(
                        1,
                        int(max(note.duration_beats, MIN_NOTE_DURATION_BEATS) * seconds_per_beat * sample_rate),
                    )
                    end_sample = min(len(audio_data), start_sample + duration_samples)
                    samples_to_add = end_sample - start_sample
                    if samples_to_add <= 0:
                        continue

                    velocity = max(MIN_VELOCITY_SCALE, min(MAX_VELOCITY_SCALE, note.velocity / 127.0))
                    t = np.arange(samples_to_add) / sample_rate

                    if track.is_drum:
                        drum_pitch_offset = max(
                            0,
                            min(DRUM_MIDI_MAX_OFFSET, note.pitch - DRUM_MIDI_BASE_NOTE),
                        )
                        freq = DRUM_BASE_FREQ_HZ + (drum_pitch_offset * DRUM_PITCH_STEP_HZ)
                        envelope = np.exp(-DRUM_DECAY_RATE * t)
                        note_data = np.sin(2 * np.pi * freq * t) * envelope * velocity * DRUM_VOLUME_SCALE
                    else:
                        freq = midi_to_freq(note.pitch)
                        note_data = np.sin(2 * np.pi * freq * t) * velocity * NOTE_VOLUME_SCALE
                        if samples_to_add >= 4:
                            fade = min(
                                max(MIN_FADE_SAMPLES, int(NOTE_FADE_SECONDS * sample_rate)),
                                samples_to_add // 2,
                            )
                            note_data[:fade] *= np.linspace(0.0, 1.0, fade)
                            note_data[-fade:] *= np.linspace(1.0, 0.0, fade)

                    audio_data[start_sample:end_sample] += note_data.astype(np.float32)

            max_val = np.max(np.abs(audio_data))
            if max_val > 0:
                audio_data = audio_data / max_val * AUDIO_NORMALIZATION_HEADROOM
            audio_int = (audio_data * 32767).astype(np.int16)
            wavfile.write(wav_path, sample_rate, audio_int)
        except Exception as e:
            print(f"Warning: Failed to synthesize WAV ({e}).")
            if os.path.exists(wav_path):
                os.remove(wav_path)
            return None

        # Load WAV and convert to MP3
        try:
            audio = AudioSegment.from_wav(wav_path)
            mp3_buffer = io.BytesIO()
            audio.export(mp3_buffer, format="mp3", bitrate="192k")
            mp3_bytes = mp3_buffer.getvalue()

            # Verify we got valid MP3 data
            if len(mp3_bytes) > MIN_MP3_SIZE_BYTES:
                print(f"Successfully generated MP3: {len(mp3_bytes)} bytes")
                if os.path.exists(wav_path):
                    os.remove(wav_path)
                return mp3_bytes
            else:
                raise ValueError(
                    "Generated MP3 data too small: "
                    f"{len(mp3_bytes)} bytes (minimum: {MIN_MP3_SIZE_BYTES})"
                )

        except Exception as e:
            print(f"Warning: Failed to encode MP3 ({e}).")
            if os.path.exists(wav_path):
                os.remove(wav_path)
            return None

    except Exception as e:
        print(f"Error in MIDI to MP3 conversion: {e}.")
        return None


def compose(request: CompositionRequest) -> CompositionResponse:
    """Run the full Compose pipeline end-to-end."""
    overrides = {
        "key": request.key,
        "mode": request.mode,
        "tempo_bpm": request.tempo_bpm,
        "bars": request.bars,
        "style": request.style,
    }
    interp = interpret_prompt(request.prompt, use_llm=request.use_llm, overrides=overrides)

    key_ctx = KeyContext(
        tonic_pc=parse_key(interp.key),
        tonic_name=interp.key,
        mode=interp.mode if interp.mode in {
            "major", "minor", "harmonic_minor", "melodic_minor",
            "dorian", "phrygian", "lydian", "mixolydian", "aeolian", "locrian",
        } else "major",
    )

    plan = CompositionPlan(
        key=key_ctx,
        tempo_bpm=interp.tempo_bpm,
        bars=interp.bars,
        beats_per_bar=4,
        genre=interp.genre,
        mood=interp.mood,
        style=interp.style,
        seed=abs(hash(request.prompt)) % (2 ** 31),
    )

    tracks, sections, progression = compose_procedural(plan)
    midi_bytes = _render_midi(tracks, plan.tempo_bpm, plan.beats_per_bar)
    mp3_bytes = _render_to_mp3(tracks, plan.tempo_bpm, plan.beats_per_bar)
    narrative = write_narrative(request.prompt, interp, progression)

    metadata = CompositionMetadata(
        key=interp.key,
        mode=interp.mode,
        tempo_bpm=interp.tempo_bpm,
        time_signature=f"{plan.beats_per_bar}/4",
        bars=interp.bars,
        total_beats=float(interp.bars * plan.beats_per_bar),
        style=interp.style,
        mood=interp.mood,
        genre=interp.genre,
        chord_progression=progression,
        instruments=[t.instrument for t in tracks],
    )

    return CompositionResponse(
        composition_id=uuid.uuid4().hex,
        metadata=metadata,
        structure=[_to_response_section(s) for s in sections],
        tracks=[_to_response_track(t) for t in tracks],
        narrative=narrative,
        used_llm=interp.used_llm,
        midi_base64=base64.b64encode(midi_bytes).decode("ascii"),
        mp3_base64=base64.b64encode(mp3_bytes).decode("ascii") if mp3_bytes else None,
    )
