"""Music theory primitives used by the procedural composer.

Pure-Python, dependency-free helpers for keys, scales, diatonic chords,
voice leading, and General MIDI instrument selection. Keeping this isolated
makes the rest of the composer easy to reason about and test.
"""
from __future__ import annotations

from dataclasses import dataclass

NOTE_TO_PC: dict[str, int] = {
    "C": 0, "C#": 1, "Db": 1, "D": 2, "D#": 3, "Eb": 3, "E": 4, "Fb": 4,
    "F": 5, "E#": 5, "F#": 6, "Gb": 6, "G": 7, "G#": 8, "Ab": 8,
    "A": 9, "A#": 10, "Bb": 10, "B": 11, "Cb": 11,
}

PC_TO_NOTE: list[str] = ["C", "C#", "D", "Eb", "E", "F", "F#", "G", "Ab", "A", "Bb", "B"]

# Scale step intervals (semitones from tonic) for each supported mode.
MODE_INTERVALS: dict[str, tuple[int, ...]] = {
    "major": (0, 2, 4, 5, 7, 9, 11),
    "minor": (0, 2, 3, 5, 7, 8, 10),
    "harmonic_minor": (0, 2, 3, 5, 7, 8, 11),
    "melodic_minor": (0, 2, 3, 5, 7, 9, 11),
    "dorian": (0, 2, 3, 5, 7, 9, 10),
    "phrygian": (0, 1, 3, 5, 7, 8, 10),
    "lydian": (0, 2, 4, 6, 7, 9, 11),
    "mixolydian": (0, 2, 4, 5, 7, 9, 10),
    "aeolian": (0, 2, 3, 5, 7, 8, 10),
    "locrian": (0, 1, 3, 5, 6, 8, 10),
}

# Diatonic chord quality per scale degree (1..7) for each mode.
MODE_CHORD_QUALITIES: dict[str, tuple[str, ...]] = {
    "major":          ("maj", "min", "min", "maj", "maj", "min", "dim"),
    "minor":          ("min", "dim", "maj", "min", "min", "maj", "maj"),
    "harmonic_minor": ("min", "dim", "aug", "min", "maj", "maj", "dim"),
    "melodic_minor":  ("min", "min", "aug", "maj", "maj", "dim", "dim"),
    "dorian":         ("min", "min", "maj", "maj", "min", "dim", "maj"),
    "phrygian":       ("min", "maj", "maj", "min", "dim", "maj", "min"),
    "lydian":         ("maj", "maj", "min", "dim", "maj", "min", "min"),
    "mixolydian":     ("maj", "min", "dim", "maj", "min", "min", "maj"),
    "aeolian":        ("min", "dim", "maj", "min", "min", "maj", "maj"),
    "locrian":        ("dim", "maj", "min", "min", "maj", "maj", "min"),
}

# Common chord progressions expressed as scale degrees (1-indexed).
PROGRESSIONS: dict[str, list[tuple[int, ...]]] = {
    "pop":       [(1, 5, 6, 4), (6, 4, 1, 5), (1, 6, 4, 5)],
    "rock":      [(1, 4, 5, 5), (1, 5, 6, 4), (1, 5, 4, 5)],
    "jazz":      [(2, 5, 1, 6), (1, 6, 2, 5), (3, 6, 2, 5)],
    "blues":     [(1, 1, 1, 1), (4, 4, 1, 1), (5, 4, 1, 5)],
    "lofi":      [(1, 6, 4, 5), (2, 5, 1, 1), (6, 2, 5, 1)],
    "cinematic": [(6, 4, 1, 5), (1, 6, 3, 7), (1, 5, 6, 4)],
    "classical": [(1, 4, 5, 1), (2, 5, 1, 1), (1, 6, 4, 5)],
    "electronic": [(6, 4, 1, 5), (1, 5, 6, 4), (1, 1, 6, 5)],
    "folk":      [(1, 4, 1, 5), (1, 5, 6, 4), (1, 4, 5, 1)],
    "ambient":   [(1, 3, 6, 4), (1, 5, 6, 4), (6, 4, 1, 5)],
}

CHORD_OFFSETS: dict[str, tuple[int, ...]] = {
    "maj": (0, 4, 7), "min": (0, 3, 7), "dim": (0, 3, 6), "aug": (0, 4, 8),
    "maj7": (0, 4, 7, 11), "min7": (0, 3, 7, 10), "dom7": (0, 4, 7, 10),
}

# General MIDI program numbers (0-indexed) for instrument selection.
GM_INSTRUMENTS: dict[str, int] = {
    "Acoustic Grand Piano": 0, "Electric Piano": 4, "Music Box": 10,
    "Vibraphone": 11, "Marimba": 12, "Church Organ": 19, "Acoustic Guitar": 24,
    "Electric Guitar (clean)": 27, "Acoustic Bass": 32, "Electric Bass (finger)": 33,
    "Synth Bass 1": 38, "Violin": 40, "Cello": 42, "String Ensemble 1": 48,
    "Synth Strings 1": 50, "Choir Aahs": 52, "Trumpet": 56, "French Horn": 60,
    "Alto Sax": 65, "Flute": 73, "Lead 1 (square)": 80, "Lead 2 (sawtooth)": 81,
    "Pad 2 (warm)": 89, "Pad 3 (polysynth)": 90, "Pad 5 (bowed)": 92,
}

GENRE_INSTRUMENTATION: dict[str, dict[str, str]] = {
    "pop":        {"melody": "Electric Piano", "harmony": "Acoustic Grand Piano", "bass": "Electric Bass (finger)"},
    "rock":       {"melody": "Electric Guitar (clean)", "harmony": "Electric Guitar (clean)", "bass": "Electric Bass (finger)"},
    "jazz":       {"melody": "Alto Sax", "harmony": "Acoustic Grand Piano", "bass": "Acoustic Bass"},
    "blues":      {"melody": "Electric Guitar (clean)", "harmony": "Acoustic Grand Piano", "bass": "Electric Bass (finger)"},
    "lofi":       {"melody": "Electric Piano", "harmony": "Vibraphone", "bass": "Acoustic Bass"},
    "cinematic":  {"melody": "Violin", "harmony": "String Ensemble 1", "bass": "Cello"},
    "classical":  {"melody": "Violin", "harmony": "Acoustic Grand Piano", "bass": "Cello"},
    "electronic": {"melody": "Lead 2 (sawtooth)", "harmony": "Pad 3 (polysynth)", "bass": "Synth Bass 1"},
    "folk":       {"melody": "Acoustic Guitar", "harmony": "Acoustic Guitar", "bass": "Acoustic Bass"},
    "ambient":    {"melody": "Pad 5 (bowed)", "harmony": "Pad 2 (warm)", "bass": "Synth Bass 1"},
}


@dataclass(frozen=True)
class KeyContext:
    """Fully-resolved key/scale information used by the composer."""

    tonic_pc: int
    tonic_name: str
    mode: str

    @property
    def scale_pcs(self) -> tuple[int, ...]:
        return tuple((self.tonic_pc + step) % 12 for step in MODE_INTERVALS[self.mode])


def normalize_note_name(name: str) -> str:
    cleaned = name.strip().capitalize()
    if len(cleaned) >= 2 and cleaned[1] in {"#", "b"}:
        cleaned = cleaned[0].upper() + cleaned[1].lower() if cleaned[1] == "b" else cleaned[0].upper() + "#"
    return cleaned


def parse_key(name: str | None, default: str = "C") -> int:
    if not name:
        return NOTE_TO_PC[default]
    return NOTE_TO_PC.get(normalize_note_name(name), NOTE_TO_PC[default])


def chord_pitches(root_pc: int, quality: str, octave: int = 4) -> list[int]:
    base = 12 * (octave + 1) + root_pc
    return [base + offset for offset in CHORD_OFFSETS.get(quality, CHORD_OFFSETS["maj"])]


def diatonic_chord(ctx: KeyContext, degree: int, *, seventh: bool = False, octave: int = 4) -> tuple[int, str, list[int]]:
    """Return ``(root_pc, quality, midi_pitches)`` for a diatonic chord."""
    idx = (degree - 1) % 7
    quality = MODE_CHORD_QUALITIES[ctx.mode][idx]
    root_pc = ctx.scale_pcs[idx]
    if seventh:
        seventh_quality = {"maj": "maj7", "min": "min7", "dom": "dom7"}.get(quality, quality)
        return root_pc, quality, chord_pitches(root_pc, seventh_quality, octave)
    return root_pc, quality, chord_pitches(root_pc, quality, octave)


def voice_lead(prev: list[int], target: list[int]) -> list[int]:
    """Adjust ``target`` chord voicing octaves to minimize total motion from ``prev``."""
    if not prev:
        return target
    voiced = []
    for i, pitch in enumerate(target):
        ref = prev[min(i, len(prev) - 1)]
        best = pitch
        while best - ref > 6:
            best -= 12
        while ref - best > 6:
            best += 12
        voiced.append(best)
    return voiced
