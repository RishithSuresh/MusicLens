from __future__ import annotations

import io
import tempfile
from pathlib import Path
from typing import TYPE_CHECKING

import librosa
import numpy as np

from app.models.analysis import AnalysisResponse, CategorizedInsight, FrequencyBin, InsightSegment

if TYPE_CHECKING:
    from faster_whisper import WhisperModel
    from whisper.model import Whisper


_WHISPER_MODEL: Whisper | None = None
_FASTER_WHISPER_MODEL: WhisperModel | None = None


def _load_whisper_model() -> Whisper | None:
    global _WHISPER_MODEL
    if _WHISPER_MODEL is not None:
        return _WHISPER_MODEL

    try:
        import whisper
    except Exception:  # noqa: BLE001
        return None

    try:
        _WHISPER_MODEL = whisper.load_model("tiny")
    except Exception:  # noqa: BLE001
        return None

    return _WHISPER_MODEL


def _extract_lyrics(audio_bytes: bytes) -> str:
    # Whisper works with files; use a temporary file to avoid persisting uploads.
    temp_path: Path | None = None
    try:
        with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as tmp:
            tmp.write(audio_bytes)
            temp_path = Path(tmp.name)

        text = _transcribe_with_openai_whisper(temp_path)
        if text:
            return text

        text = _transcribe_with_faster_whisper(temp_path)
        if text:
            return text

        return ""
    except Exception:  # noqa: BLE001
        return ""
    finally:
        if temp_path is not None and temp_path.exists():
            try:
                temp_path.unlink(missing_ok=True)
            except Exception:  # noqa: BLE001
                pass


def _transcribe_with_openai_whisper(audio_path: Path) -> str:
    model = _load_whisper_model()
    if model is None:
        return ""

    try:
        result = model.transcribe(str(audio_path), fp16=False)
        return str(result.get("text", "")).strip()
    except Exception:  # noqa: BLE001
        return ""


def _load_faster_whisper_model() -> WhisperModel | None:
    global _FASTER_WHISPER_MODEL
    if _FASTER_WHISPER_MODEL is not None:
        return _FASTER_WHISPER_MODEL

    try:
        from faster_whisper import WhisperModel
    except Exception:  # noqa: BLE001
        return None

    try:
        _FASTER_WHISPER_MODEL = WhisperModel("tiny", device="cpu", compute_type="int8")
    except Exception:  # noqa: BLE001
        return None

    return _FASTER_WHISPER_MODEL


def _transcribe_with_faster_whisper(audio_path: Path) -> str:
    model = _load_faster_whisper_model()
    if model is None:
        return ""

    try:
        segments, _ = model.transcribe(str(audio_path), beam_size=1)
        return " ".join(segment.text.strip() for segment in segments if segment.text).strip()
    except Exception:  # noqa: BLE001
        return ""


def _normalize(values: np.ndarray) -> np.ndarray:
    max_value = float(np.max(values)) if values.size else 0.0
    if max_value <= 0.0:
        return values
    return values / max_value


def _build_insights(bpm: float, mean_energy: float, energy_std: float) -> list[str]:
    insights: list[str] = []

    if mean_energy > 0.5:
        insights.append("High energy section likely active")
    elif mean_energy < 0.2:
        insights.append("Low intensity passage detected")
    else:
        insights.append("Moderate groove with balanced dynamics")

    if bpm >= 130:
        insights.append("Fast tempo momentum")
    elif bpm <= 80:
        insights.append("Slow tempo flow")
    else:
        insights.append("Mid-tempo rhythm")

    if energy_std > 0.18:
        insights.append("Dynamic transitions present (possible drops/build-ups)")
    else:
        insights.append("Stable energy profile")

    return insights


def _build_categorized_insights(
    bpm: float, mean_energy: float, energy_std: float, pitch_range: float, spectral_centroid: float
) -> list[CategorizedInsight]:
    """Build insights organized by category for advanced filtering."""
    insights: list[CategorizedInsight] = []

    # Rhythm insights
    if bpm >= 140:
        insights.append(CategorizedInsight(text="Very fast tempo (high energy EDM/techno feel)", category="rhythm"))
    elif bpm >= 130:
        insights.append(CategorizedInsight(text="Fast tempo momentum", category="rhythm"))
    elif bpm >= 100:
        insights.append(CategorizedInsight(text="Upbeat mid-tempo pace", category="rhythm"))
    elif bpm >= 80:
        insights.append(CategorizedInsight(text="Mid-tempo rhythm", category="rhythm"))
    else:
        insights.append(CategorizedInsight(text="Slow tempo flow", category="rhythm"))

    # Energy insights
    if mean_energy > 0.6:
        insights.append(CategorizedInsight(text="High-energy dynamics - likely chorus or peak section", category="energy"))
    elif mean_energy > 0.4:
        insights.append(CategorizedInsight(text="Moderate groove with balanced dynamics", category="energy"))
    else:
        insights.append(CategorizedInsight(text="Low intensity passage - intro or quiet breakdown", category="energy"))

    if energy_std > 0.2:
        insights.append(CategorizedInsight(text="Strong dynamic shifts (possible drops/build-ups)", category="energy"))
    elif energy_std > 0.1:
        insights.append(CategorizedInsight(text="Varied energy profile", category="energy"))
    else:
        insights.append(CategorizedInsight(text="Consistent energy level throughout", category="energy"))

    # Melody insights
    if pitch_range > 2000:
        insights.append(CategorizedInsight(text="Wide melodic range - likely vocal or expressive lead", category="melody"))
    elif pitch_range > 800:
        insights.append(CategorizedInsight(text="Moderate pitch variation", category="melody"))
    else:
        insights.append(CategorizedInsight(text="Narrow pitch range - instrumental or bassline focused", category="melody"))

    if spectral_centroid > 5000:
        insights.append(CategorizedInsight(text="Bright, high-frequency content (possibly synths or cymbals)", category="melody"))
    elif spectral_centroid > 2000:
        insights.append(CategorizedInsight(text="Balanced frequency distribution", category="melody"))
    else:
        insights.append(CategorizedInsight(text="Warm, bass-focused tonality", category="melody"))

    # Structure insights
    if bpm >= 90 and mean_energy > 0.4:
        insights.append(CategorizedInsight(text="Likely dance/pop structure with driving rhythm", category="structure"))
    elif bpm <= 90 and pitch_range > 1000:
        insights.append(CategorizedInsight(text="Likely acoustic/singer-songwriter structure", category="structure"))
    else:
        insights.append(CategorizedInsight(text="Complex harmonic/arrangement structure", category="structure"))

    return insights


def _detect_genre(bpm: float, mean_energy: float, energy_std: float, spectral_centroid: float) -> tuple[str, float]:
    """Detect music genre based on audio features. Returns (genre, confidence)."""
    confidence = 0.0
    genre = "Unknown"

    # Genre detection heuristics based on BPM, energy, and spectral characteristics
    if 120 <= bpm <= 150 and mean_energy > 0.5 and energy_std > 0.15:
        genre = "Electronic/EDM"
        confidence = min(0.9, 0.5 + abs(bpm - 130) / 100 + mean_energy * 0.3)
    elif 85 <= bpm <= 115 and mean_energy > 0.45 and spectral_centroid > 3000:
        genre = "Pop"
        confidence = min(0.85, 0.5 + abs(bpm - 100) / 100 + mean_energy * 0.25)
    elif 60 <= bpm <= 100 and mean_energy < 0.4 and spectral_centroid < 3000:
        genre = "R&B/Soul"
        confidence = min(0.8, 0.5 + (0.4 - mean_energy) * 0.5)
    elif 160 <= bpm <= 180 and energy_std > 0.2 and mean_energy > 0.6:
        genre = "Hip-Hop"
        confidence = min(0.85, 0.5 + abs(bpm - 170) / 100 + mean_energy * 0.3)
    elif bpm <= 100 and mean_energy < 0.35 and spectral_centroid < 2000:
        genre = "Jazz/Blues"
        confidence = min(0.75, 0.45 + (0.35 - mean_energy) * 0.5)
    elif bpm <= 80 and mean_energy < 0.3 and energy_std < 0.1:
        genre = "Classical/Acoustic"
        confidence = min(0.8, 0.4 + (0.3 - mean_energy) * 0.3)
    elif 130 <= bpm <= 160 and mean_energy > 0.55 and energy_std > 0.18:
        genre = "House/Techno"
        confidence = min(0.85, 0.5 + abs(bpm - 145) / 100)
    elif 90 <= bpm <= 110 and mean_energy > 0.5:
        genre = "Rock"
        confidence = min(0.8, 0.5 + mean_energy * 0.2)
    else:
        genre = "Experimental"
        confidence = 0.4

    return genre, max(0.0, min(1.0, confidence))


def _label_for_energy(energy: float, delta: float) -> str:
    if energy > 0.72:
        return "High energy chorus"
    if delta > 0.22 and energy > 0.45:
        return "Beat drop detected"
    if energy < 0.24:
        return "Low intensity intro"
    return "Steady rhythmic section"


def _build_insight_timeline(energy_times: np.ndarray, energy_values: np.ndarray) -> list[InsightSegment]:
    if energy_values.size == 0 or energy_times.size == 0:
        return []

    smooth = np.convolve(energy_values, np.ones(5) / 5, mode="same")
    deltas = np.diff(smooth, prepend=smooth[0])

    segments: list[InsightSegment] = []
    seg_start_idx = 0
    current_label = _label_for_energy(float(smooth[0]), float(deltas[0]))

    for i in range(1, len(smooth)):
        next_label = _label_for_energy(float(smooth[i]), float(deltas[i]))
        if next_label != current_label:
            segments.append(
                InsightSegment(
                    start=float(energy_times[seg_start_idx]),
                    end=float(energy_times[i]),
                    label=current_label,
                )
            )
            current_label = next_label
            seg_start_idx = i

    segments.append(
        InsightSegment(
            start=float(energy_times[seg_start_idx]),
            end=float(energy_times[-1]),
            label=current_label,
        )
    )

    return segments


def analyze_audio_bytes(audio_bytes: bytes, *, max_spectrum_frames: int = 180) -> AnalysisResponse:
    y, sr = librosa.load(io.BytesIO(audio_bytes), sr=None, mono=True)
    duration = float(librosa.get_duration(y=y, sr=sr))

    tempo_raw, beat_frames = librosa.beat.beat_track(y=y, sr=sr)
    tempo_arr = np.asarray(tempo_raw)
    tempo = float(tempo_arr.reshape(-1)[0]) if tempo_arr.size else 0.0
    beat_timestamps = librosa.frames_to_time(beat_frames, sr=sr)

    try:
        f0, voiced_flag, _ = librosa.pyin(
            y,
            fmin=librosa.note_to_hz("C2"),
            fmax=librosa.note_to_hz("C7"),
        )
        pitch_times = librosa.times_like(f0, sr=sr)
        pitch_clean = np.where(voiced_flag, f0, np.nan)
        pitch_hz = np.nan_to_num(pitch_clean, nan=0.0)
    except Exception:  # noqa: BLE001
        # Fallback keeps endpoint resilient for noisy/atypical material.
        pitch_hz = librosa.yin(
            y,
            fmin=librosa.note_to_hz("C2"),
            fmax=librosa.note_to_hz("C7"),
        )
        pitch_times = librosa.times_like(pitch_hz, sr=sr)

    rms = librosa.feature.rms(y=y)[0]
    rms_times = librosa.times_like(rms, sr=sr)
    rms_normalized = _normalize(rms)

    stft = librosa.stft(y)
    stft_mag = np.abs(stft)
    stft_db = librosa.amplitude_to_db(stft_mag, ref=np.max)
    stft_db_norm = (stft_db + 80.0) / 80.0
    stft_db_norm = np.clip(stft_db_norm, 0.0, 1.0)

    freqs = librosa.fft_frequencies(sr=sr, n_fft=2048)
    frame_times = librosa.frames_to_time(np.arange(stft_db_norm.shape[1]), sr=sr)

    # Calculate spectral centroid for genre detection
    spectral_centroid = np.mean(librosa.feature.spectral_centroid(y=y, sr=sr))

    bass_band_mask = freqs <= 200
    bass_energy = np.mean(stft_db_norm[bass_band_mask, :], axis=0) if np.any(bass_band_mask) else np.zeros(stft_db_norm.shape[1])
    bass_energy = _normalize(bass_energy)

    if stft_db_norm.shape[1] > max_spectrum_frames:
        idx = np.linspace(0, stft_db_norm.shape[1] - 1, max_spectrum_frames, dtype=int)
        sampled_spec = stft_db_norm[:, idx]
        sampled_times = frame_times[idx]
    else:
        sampled_spec = stft_db_norm
        sampled_times = frame_times

    # Keep frontend payload practical while preserving curve quality.
    spectrum_freq_idx = np.linspace(0, len(freqs) - 1, 96, dtype=int)
    spectrum_frequencies = freqs[spectrum_freq_idx]

    spectrum_frames: list[FrequencyBin] = []
    for frame_i in range(sampled_spec.shape[1]):
        magnitudes = sampled_spec[spectrum_freq_idx, frame_i]
        spectrum_frames.append(
            FrequencyBin(
                time=float(sampled_times[frame_i]),
                magnitudes=magnitudes.astype(float).tolist(),
            )
        )

    insights = _build_insights(
        bpm=float(tempo),
        mean_energy=float(np.mean(rms_normalized)) if rms_normalized.size else 0.0,
        energy_std=float(np.std(rms_normalized)) if rms_normalized.size else 0.0,
    )

    mean_energy = float(np.mean(rms_normalized)) if rms_normalized.size else 0.0
    energy_std = float(np.std(rms_normalized)) if rms_normalized.size else 0.0
    pitch_range = float(np.ptp(pitch_hz[pitch_hz > 0])) if np.any(pitch_hz > 0) else 0.0

    categorized_insights = _build_categorized_insights(
        bpm=float(tempo),
        mean_energy=mean_energy,
        energy_std=energy_std,
        pitch_range=pitch_range,
        spectral_centroid=float(spectral_centroid),
    )

    genre, genre_confidence = _detect_genre(
        bpm=float(tempo),
        mean_energy=mean_energy,
        energy_std=energy_std,
        spectral_centroid=float(spectral_centroid),
    )

    insight_timeline = _build_insight_timeline(rms_times, rms_normalized)
    lyrics = _extract_lyrics(audio_bytes)

    return AnalysisResponse(
        duration=duration,
        sample_rate=int(sr),
        bpm=float(tempo),
        beat_timestamps=beat_timestamps.astype(float).tolist(),
        pitch_hz=pitch_hz.astype(float).tolist(),
        pitch_times=pitch_times.astype(float).tolist(),
        energy_rms=rms_normalized.astype(float).tolist(),
        energy_times=rms_times.astype(float).tolist(),
        bass_energy=bass_energy.astype(float).tolist(),
        bass_times=frame_times.astype(float).tolist(),
        spectrum_frequencies=spectrum_frequencies.astype(float).tolist(),
        spectrum_frames=spectrum_frames,
        insights=insights,
        categorized_insights=categorized_insights,
        genre=genre,
        genre_confidence=genre_confidence,
        insight_timeline=insight_timeline,
        lyrics=lyrics,
    )
