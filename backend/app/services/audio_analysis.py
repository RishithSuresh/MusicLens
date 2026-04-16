from __future__ import annotations

import io

import librosa
import numpy as np

from app.models.analysis import AnalysisResponse, FrequencyBin


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


def analyze_audio_bytes(audio_bytes: bytes, *, max_spectrum_frames: int = 180) -> AnalysisResponse:
    y, sr = librosa.load(io.BytesIO(audio_bytes), sr=None, mono=True)
    duration = float(librosa.get_duration(y=y, sr=sr))

    tempo, beat_frames = librosa.beat.beat_track(y=y, sr=sr)
    beat_timestamps = librosa.frames_to_time(beat_frames, sr=sr)

    f0, voiced_flag, _ = librosa.pyin(
        y,
        fmin=librosa.note_to_hz("C2"),
        fmax=librosa.note_to_hz("C7"),
    )
    pitch_times = librosa.times_like(f0, sr=sr)
    pitch_clean = np.where(voiced_flag, f0, np.nan)
    pitch_hz = np.nan_to_num(pitch_clean, nan=0.0)

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

    return AnalysisResponse(
        duration=duration,
        sample_rate=int(sr),
        bpm=float(tempo),
        beat_timestamps=beat_timestamps.astype(float).tolist(),
        pitch_hz=pitch_hz.astype(float).tolist(),
        pitch_times=pitch_times.astype(float).tolist(),
        energy_rms=rms_normalized.astype(float).tolist(),
        energy_times=rms_times.astype(float).tolist(),
        spectrum_frequencies=spectrum_frequencies.astype(float).tolist(),
        spectrum_frames=spectrum_frames,
        insights=insights,
    )
