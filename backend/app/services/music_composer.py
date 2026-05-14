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
    )
