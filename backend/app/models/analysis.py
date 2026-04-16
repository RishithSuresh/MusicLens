from pydantic import BaseModel, Field


class FrequencyBin(BaseModel):
    time: float = Field(..., description="Time in seconds")
    magnitudes: list[float] = Field(..., description="Normalized spectrum magnitudes")


class AnalysisResponse(BaseModel):
    duration: float
    sample_rate: int
    bpm: float
    beat_timestamps: list[float]
    pitch_hz: list[float]
    pitch_times: list[float]
    energy_rms: list[float]
    energy_times: list[float]
    spectrum_frequencies: list[float]
    spectrum_frames: list[FrequencyBin]
    insights: list[str]
