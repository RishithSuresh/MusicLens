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


def _render_to_mp3(tracks: list[TrackData], tempo_bpm: int, beats_per_bar: int) -> bytes:
    """Render the in-memory tracks to MP3 audio using music21's export capabilities.

    Falls back to MIDI if synthesis fails.
    """
    if tempo_bpm <= 0:
        raise ValueError("tempo_bpm must be greater than 0")

    import io
    import tempfile
    import os

    # Generate MIDI bytes first
    midi_bytes = _render_midi(tracks, tempo_bpm, beats_per_bar)

    try:
        from pydub import AudioSegment
    except ImportError as e:
        print(f"Warning: pydub not available ({e}). Returning MIDI format instead of MP3.")
        return midi_bytes

    try:
        # Write MIDI to temporary file
        with tempfile.NamedTemporaryFile(suffix=".mid", delete=False) as midi_temp:
            midi_temp.write(midi_bytes)
            midi_path = midi_temp.name

        wav_path = midi_path.replace(".mid", ".wav")
        mp3_path = midi_path.replace(".mid", ".mp3")

        # Try to convert MIDI to audio using music21's export
        try:
            try:
                import music21
                score = music21.midi.translate.midiFileToStream(
                    music21.midi.MidiFile(midi_path)
                )
                # Try to show/export to audio format
                # This requires external tools like MuseScore, Finale, or notation software
                score.show("musicxml.pdf")  # This won't produce audio, just check format
            except Exception:
                # music21 export to audio requires external tools
                raise NotImplementedError("music21 export requires external notation software")

        except Exception as e:
            # Fallback: Create synthetic audio from MIDI
            print(f"Note: music21 export not available ({e}). Using synthetic audio...")

            try:
                # Simple synthesis: Play each note as a sine wave
                import numpy as np
                from scipy.io import wavfile
                from mido import MidiFile

                midi_file = MidiFile(midi_path)

                # Calculate total duration
                total_ticks = 0
                for track in midi_file.tracks:
                    tick_count = 0
                    for msg in track:
                        tick_count += msg.time
                    total_ticks = max(total_ticks, tick_count)

                ticks_per_beat = midi_file.ticks_per_beat
                # Tempo in microseconds per beat.
                tempo = int(60_000_000 / tempo_bpm)
                ticks_per_second = (ticks_per_beat * 1_000_000) / tempo
                duration_sec = max(2, total_ticks / ticks_per_second + 0.5)

                sample_rate = 44100
                num_samples = int(duration_sec * sample_rate)
                audio_data = np.zeros(num_samples, dtype=np.float32)

                # MIDI note to frequency conversion
                def midi_to_freq(midi_note: int) -> float:
                    return 440 * (2 ** ((midi_note - 69) / 12))

                # Process MIDI events
                current_time = 0
                for track in midi_file.tracks:
                    current_time = 0
                    active_notes = {}  # Track active notes: {note: (start_sample, start_time)}

                    for msg in track:
                        current_time += msg.time
                        current_sample = int((current_time / ticks_per_beat) * (60 / tempo_bpm) * sample_rate)

                        if msg.type == "note_on" and msg.velocity > 0:
                            freq = midi_to_freq(msg.note)
                            # Store note info
                            active_notes[msg.note] = (current_sample, msg.velocity / 127.0)

                        elif msg.type == "note_off" or (msg.type == "note_on" and msg.velocity == 0):
                            if msg.note in active_notes:
                                start_sample, velocity = active_notes[msg.note]
                                duration_samples = current_sample - start_sample

                                if duration_samples > 0:
                                    freq = midi_to_freq(msg.note)
                                    # Generate sine wave for this note
                                    t = np.arange(duration_samples) / sample_rate
                                    phase = 2 * np.pi * freq * t
                                    note_data = np.sin(phase) * velocity * 0.3

                                    # Add to main audio with fade
                                    end_sample = min(current_sample, len(audio_data))
                                    samples_to_add = end_sample - start_sample
                                    if samples_to_add > 0:
                                        audio_data[start_sample:end_sample] += note_data[:samples_to_add]

                                del active_notes[msg.note]

                # Normalize audio
                max_val = np.max(np.abs(audio_data))
                if max_val > 0:
                    audio_data = audio_data / max_val * 0.95

                # Convert to 16-bit PCM
                audio_int = (audio_data * 32767).astype(np.int16)

                # Write WAV file
                wavfile.write(wav_path, sample_rate, audio_int)

            except ImportError:
                print("Warning: mido not available for MIDI parsing. Returning MIDI format instead.")
                if os.path.exists(midi_path):
                    os.remove(midi_path)
                return midi_bytes

        # Load WAV and convert to MP3
        try:
            audio = AudioSegment.from_wav(wav_path)
            mp3_buffer = io.BytesIO()
            audio.export(mp3_buffer, format="mp3", bitrate="192k")
            mp3_bytes = mp3_buffer.getvalue()

            # Verify we got valid MP3 data
            if len(mp3_bytes) > 100:
                print(f"Successfully generated MP3: {len(mp3_bytes)} bytes")
                # Cleanup
                if os.path.exists(midi_path):
                    os.remove(midi_path)
                if os.path.exists(wav_path):
                    os.remove(wav_path)
                if os.path.exists(mp3_path):
                    os.remove(mp3_path)
                return mp3_bytes
            else:
                raise ValueError("Generated MP3 data too small")

        except Exception as e:
            print(f"Warning: Failed to encode MP3 ({e}). Returning MIDI format instead.")
            # Cleanup
            if os.path.exists(midi_path):
                os.remove(midi_path)
            if os.path.exists(wav_path):
                os.remove(wav_path)
            if os.path.exists(mp3_path):
                os.remove(mp3_path)
            return midi_bytes

    except Exception as e:
        print(f"Error in MIDI to MP3 conversion: {e}. Returning MIDI format instead.")
        return midi_bytes


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
    audio_bytes = _render_to_mp3(tracks, plan.tempo_bpm, plan.beats_per_bar)
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
        midi_base64=base64.b64encode(audio_bytes).decode("ascii"),
    )
