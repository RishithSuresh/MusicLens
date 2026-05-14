from pydantic import BaseModel, Field


class CompositionRequest(BaseModel):
    """Input for the AI Music Compositor."""

    prompt: str = Field(
        ...,
        description="Free-form description of the desired music",
        min_length=2,
        max_length=500,
    )
    style: str | None = Field(
        default=None,
        description="Optional musical style override (e.g. 'jazz', 'lofi', 'cinematic')",
        max_length=80,
    )
    key: str | None = Field(
        default=None,
        description="Optional tonic key override (e.g. 'C', 'F#', 'Bb')",
        max_length=4,
    )
    mode: str | None = Field(
        default=None,
        description="Optional mode override (major, minor, dorian, mixolydian, ...)",
        max_length=24,
    )
    tempo_bpm: int | None = Field(
        default=None,
        description="Optional tempo override in BPM (40-220)",
        ge=40,
        le=220,
    )
    bars: int | None = Field(
        default=None,
        description="Optional total bar count (4-64)",
        ge=4,
        le=64,
    )
    use_llm: bool = Field(
        default=True,
        description="Whether to invoke the LangGraph LLM workflow if an API key is configured",
    )


class CompositionNote(BaseModel):
    """A single note event for piano-roll style visualization."""

    pitch: int = Field(..., description="MIDI pitch (0-127)")
    start_beat: float = Field(..., description="Onset position in beats")
    duration_beats: float = Field(..., description="Length in beats")
    velocity: int = Field(..., description="MIDI velocity 0-127", ge=0, le=127)


class CompositionTrack(BaseModel):
    """A single instrument track in the composition."""

    name: str
    instrument: str
    program: int = Field(..., description="General MIDI program number")
    is_drum: bool = False
    notes: list[CompositionNote] = Field(default_factory=list)


class CompositionSection(BaseModel):
    """A structural section of the song (intro / verse / chorus / ...)."""

    name: str
    start_beat: float
    end_beat: float
    description: str | None = None


class CompositionMetadata(BaseModel):
    """High-level metadata describing the generated piece."""

    key: str
    mode: str
    tempo_bpm: int
    time_signature: str
    bars: int
    total_beats: float
    style: str
    mood: str
    genre: str
    chord_progression: list[str]
    instruments: list[str]


class CompositionResponse(BaseModel):
    """Full composition payload returned to the client."""

    composition_id: str
    metadata: CompositionMetadata
    structure: list[CompositionSection]
    tracks: list[CompositionTrack]
    narrative: str
    used_llm: bool
    midi_base64: str = Field(..., description="Base64-encoded MIDI file bytes")
