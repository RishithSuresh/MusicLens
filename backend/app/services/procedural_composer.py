"""Deterministic procedural music generator.

Produces a multi-track arrangement (melody, harmony, bass, drums) given a
``CompositionPlan``. The output is structured note data that can be rendered
to MIDI later. Used both as a standalone composer and as the deterministic
substrate that the LangGraph workflow refines.
"""
from __future__ import annotations

import random
from dataclasses import dataclass, field

from app.services.music_theory import (
    GENRE_INSTRUMENTATION,
    GM_INSTRUMENTS,
    PROGRESSIONS,
    KeyContext,
    diatonic_chord,
    voice_lead,
)


@dataclass
class NoteEvent:
    pitch: int
    start_beat: float
    duration_beats: float
    velocity: int = 90


@dataclass
class TrackData:
    name: str
    instrument: str
    program: int
    is_drum: bool = False
    notes: list[NoteEvent] = field(default_factory=list)


@dataclass
class SectionData:
    name: str
    start_beat: float
    end_beat: float
    chord_degrees: tuple[int, ...]
    description: str = ""


@dataclass
class CompositionPlan:
    """All parameters required to generate a composition."""

    key: KeyContext
    tempo_bpm: int
    bars: int
    beats_per_bar: int = 4
    genre: str = "pop"
    mood: str = "uplifting"
    style: str = "modern"
    seed: int = 0


# Drum General MIDI pitches on channel 10.
DRUM_KICK = 36
DRUM_SNARE = 38
DRUM_HIHAT = 42
DRUM_OPEN_HAT = 46

GENRE_DRUM_PATTERNS: dict[str, list[tuple[int, float]]] = {
    # (pitch, beat_offset_within_bar)
    "pop":        [(DRUM_KICK, 0.0), (DRUM_SNARE, 1.0), (DRUM_KICK, 2.0), (DRUM_SNARE, 3.0)],
    "rock":       [(DRUM_KICK, 0.0), (DRUM_SNARE, 1.0), (DRUM_KICK, 2.0), (DRUM_SNARE, 3.0)],
    "jazz":       [(DRUM_HIHAT, 0.0), (DRUM_HIHAT, 0.66), (DRUM_HIHAT, 1.0), (DRUM_HIHAT, 1.66),
                   (DRUM_HIHAT, 2.0), (DRUM_HIHAT, 2.66), (DRUM_HIHAT, 3.0), (DRUM_HIHAT, 3.66)],
    "lofi":       [(DRUM_KICK, 0.0), (DRUM_SNARE, 2.0), (DRUM_HIHAT, 1.0), (DRUM_HIHAT, 3.0)],
    "electronic": [(DRUM_KICK, 0.0), (DRUM_KICK, 1.0), (DRUM_KICK, 2.0), (DRUM_KICK, 3.0),
                   (DRUM_OPEN_HAT, 0.5), (DRUM_OPEN_HAT, 1.5), (DRUM_OPEN_HAT, 2.5), (DRUM_OPEN_HAT, 3.5)],
    "cinematic": [(DRUM_KICK, 0.0), (DRUM_KICK, 2.0), (DRUM_SNARE, 3.0)],
    "ambient":   [(DRUM_HIHAT, 0.0), (DRUM_HIHAT, 2.0)],
}


def _hihat_layer(beats_per_bar: int, bar_offset: float) -> list[NoteEvent]:
    return [NoteEvent(DRUM_HIHAT, bar_offset + i * 0.5, 0.25, 70) for i in range(beats_per_bar * 2)]


def _build_drums(plan: CompositionPlan) -> TrackData:
    pattern = GENRE_DRUM_PATTERNS.get(plan.genre, GENRE_DRUM_PATTERNS["pop"])
    notes: list[NoteEvent] = []
    for bar in range(plan.bars):
        bar_offset = bar * plan.beats_per_bar
        for pitch, off in pattern:
            notes.append(NoteEvent(pitch, bar_offset + off, 0.5, 100 if pitch == DRUM_KICK else 90))
        if plan.genre in {"pop", "rock", "lofi", "electronic"}:
            notes.extend(_hihat_layer(plan.beats_per_bar, bar_offset))
    return TrackData("Drums", "Drum Kit", 0, is_drum=True, notes=notes)


def _build_harmony(plan: CompositionPlan, sections: list[SectionData]) -> tuple[TrackData, list[str]]:
    instrument = GENRE_INSTRUMENTATION.get(plan.genre, GENRE_INSTRUMENTATION["pop"])["harmony"]
    program = GM_INSTRUMENTS[instrument]
    notes: list[NoteEvent] = []
    progression_labels: list[str] = []
    prev_voicing: list[int] = []
    use_seventh = plan.genre in {"jazz", "lofi"}
    for section in sections:
        section_bars = int(round((section.end_beat - section.start_beat) / plan.beats_per_bar))
        for i in range(section_bars):
            degree = section.chord_degrees[i % len(section.chord_degrees)]
            root_pc, quality, pitches = diatonic_chord(plan.key, degree, seventh=use_seventh, octave=4)
            voiced = voice_lead(prev_voicing, pitches)
            prev_voicing = voiced
            start = section.start_beat + i * plan.beats_per_bar
            for pitch in voiced:
                notes.append(NoteEvent(pitch, start, plan.beats_per_bar, 70))
            progression_labels.append(f"{['I','II','III','IV','V','VI','VII'][(degree - 1) % 7]}{'7' if use_seventh else ''} ({quality})")
    return TrackData("Harmony", instrument, program, notes=notes), progression_labels


def _build_bass(plan: CompositionPlan, sections: list[SectionData]) -> TrackData:
    instrument = GENRE_INSTRUMENTATION.get(plan.genre, GENRE_INSTRUMENTATION["pop"])["bass"]
    program = GM_INSTRUMENTS[instrument]
    notes: list[NoteEvent] = []
    rng = random.Random(plan.seed + 17)
    for section in sections:
        section_bars = int(round((section.end_beat - section.start_beat) / plan.beats_per_bar))
        for i in range(section_bars):
            degree = section.chord_degrees[i % len(section.chord_degrees)]
            root_pc, _quality, _pitches = diatonic_chord(plan.key, degree, octave=2)
            base_pitch = 12 * 3 + root_pc  # bass register
            start = section.start_beat + i * plan.beats_per_bar
            if plan.genre in {"electronic", "rock"}:
                for beat in range(plan.beats_per_bar):
                    notes.append(NoteEvent(base_pitch, start + beat, 0.9, 95))
            elif plan.genre == "jazz":
                walk = [0, 2, 4, 5]
                for beat in range(plan.beats_per_bar):
                    step = walk[beat % len(walk)] + rng.choice([-2, 0, 0, 2])
                    notes.append(NoteEvent(base_pitch + step, start + beat, 0.9, 88))
            else:
                notes.append(NoteEvent(base_pitch, start, 2.0, 90))
                notes.append(NoteEvent(base_pitch + 7, start + 2, 2.0, 80))
    return TrackData("Bass", instrument, program, notes=notes)


def _build_melody(plan: CompositionPlan, sections: list[SectionData]) -> TrackData:
    instrument = GENRE_INSTRUMENTATION.get(plan.genre, GENRE_INSTRUMENTATION["pop"])["melody"]
    program = GM_INSTRUMENTS[instrument]
    notes: list[NoteEvent] = []
    rng = random.Random(plan.seed + 91)
    scale_pcs = list(plan.key.scale_pcs)
    base_octave = 5
    last_pitch = 12 * (base_octave + 1) + scale_pcs[0]
    for section in sections:
        intensity = {"intro": 0.4, "verse": 0.6, "chorus": 1.0, "bridge": 0.8, "outro": 0.5}.get(section.name, 0.6)
        section_bars = int(round((section.end_beat - section.start_beat) / plan.beats_per_bar))
        for i in range(section_bars):
            degree = section.chord_degrees[i % len(section.chord_degrees)]
            chord_tones = {plan.key.scale_pcs[(degree - 1 + offset) % 7] for offset in (0, 2, 4)}
            start = section.start_beat + i * plan.beats_per_bar
            beat_cursor = 0.0
            while beat_cursor < plan.beats_per_bar - 0.001:
                step_choice = rng.choice([-2, -1, -1, 0, 1, 1, 2])
                pc_index = scale_pcs.index(last_pitch % 12) if (last_pitch % 12) in scale_pcs else 0
                next_pc = scale_pcs[(pc_index + step_choice) % 7]
                octave_shift = (last_pitch // 12 - 1) - base_octave
                if octave_shift > 1:
                    last_pitch -= 12
                if octave_shift < -1:
                    last_pitch += 12
                next_pitch = 12 * ((last_pitch // 12)) + next_pc
                while abs(next_pitch - last_pitch) > 7:
                    next_pitch += 12 if next_pitch < last_pitch else -12
                duration = rng.choice([0.5, 0.5, 1.0, 1.0, 1.5])
                duration = min(duration, plan.beats_per_bar - beat_cursor)
                if beat_cursor == 0 or (next_pitch % 12) in chord_tones:
                    velocity = int(95 * intensity)
                else:
                    velocity = int(75 * intensity)
                notes.append(NoteEvent(next_pitch, start + beat_cursor, duration, max(40, min(120, velocity))))
                last_pitch = next_pitch
                beat_cursor += duration
    return TrackData("Melody", instrument, program, notes=notes)


def plan_structure(plan: CompositionPlan) -> list[SectionData]:
    """Build a section structure (intro / verse / chorus / bridge / outro)."""
    bpb = plan.beats_per_bar
    progression = random.Random(plan.seed).choice(PROGRESSIONS.get(plan.genre, PROGRESSIONS["pop"]))
    if plan.bars >= 24:
        layout = [("intro", 4), ("verse", 8), ("chorus", 8), ("bridge", 4), ("outro", 4)]
    elif plan.bars >= 16:
        layout = [("intro", 4), ("verse", 4), ("chorus", 4), ("outro", 4)]
    else:
        layout = [("verse", plan.bars // 2), ("chorus", plan.bars - plan.bars // 2)]
    total = sum(b for _, b in layout)
    scale = plan.bars / max(total, 1)
    sections: list[SectionData] = []
    cursor = 0.0
    for name, bars in layout:
        scaled = max(1, round(bars * scale))
        sections.append(SectionData(
            name=name,
            start_beat=cursor,
            end_beat=cursor + scaled * bpb,
            chord_degrees=progression,
            description=f"{name.title()} section ({scaled} bars)",
        ))
        cursor += scaled * bpb
    if cursor != plan.bars * bpb:
        sections[-1].end_beat = plan.bars * bpb
    return sections


def compose_procedural(plan: CompositionPlan) -> tuple[list[TrackData], list[SectionData], list[str]]:
    random.seed(plan.seed)
    sections = plan_structure(plan)
    harmony, progression_labels = _build_harmony(plan, sections)
    bass = _build_bass(plan, sections)
    melody = _build_melody(plan, sections)
    drums = _build_drums(plan)
    return [melody, harmony, bass, drums], sections, progression_labels
