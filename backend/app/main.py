import hashlib
import random
from collections.abc import Callable
from collections import OrderedDict
from threading import Lock

from fastapi import FastAPI, File, HTTPException, UploadFile
from fastapi.middleware.cors import CORSMiddleware

from app.models.analysis import AnalysisResponse
from app.models.composition import CompositionRequest, CompositionResponse, RandomPromptResponse

app = FastAPI(title="MusicLens API", version="0.1.0")

ALLOWED_AUDIO_EXTENSIONS = {".mp3", ".wav", ".flac", ".ogg", ".m4a"}
ANALYSIS_CACHE_MAX_ITEMS = 24

_analysis_cache: OrderedDict[str, AnalysisResponse] = OrderedDict()
_analysis_cache_lock = Lock()
_analyze_audio_bytes: Callable[[bytes], AnalysisResponse] | None = None
_analyze_audio_import_error: Exception | None = None

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}


_RANDOM_PROMPTS = [
    "A hopeful uplifting lo-fi piano piece for a sunny morning",
    "An intense cinematic orchestral theme for an epic battle scene",
    "A melancholic jazz ballad for a rainy evening in the city",
    "A playful pop tune with bright guitars and catchy hooks",
    "A mysterious ambient soundscape evoking deep space exploration",
    "An energetic rock track with driving drums and electric guitar",
    "A tender folk ballad with acoustic guitar and gentle vocals",
    "A funky blues groove with expressive guitar and brass stabs",
    "A dreamy shoegaze piece with lush reverb and layered guitars",
    "A mellow bossa nova with warm guitar and subtle percussion",
    "A dramatic classical piano sonata with sweeping dynamics",
    "An upbeat electronic dance track with pulsing synths",
    "A serene meditation piece with soft pads and gentle arpeggios",
    "A gritty garage rock song with raw energy and distorted guitars",
    "A lush cinematic string arrangement for a heartfelt scene",
    "A nostalgic 80s synth-pop track with punchy drums and lead synths",
    "A hypnotic minimalist piano piece with repeating motifs",
    "A vibrant Latin jazz fusion with piano montunos and brass",
    "A haunting minor-key folk song with sparse arrangement",
    "A triumphant marching band fanfare full of brass and percussion",
]

_RANDOM_STYLES = ["pop", "rock", "jazz", "blues", "lofi", "cinematic", "classical", "electronic", "folk", "ambient"]
_RANDOM_KEYS = ["C", "C#", "D", "Eb", "E", "F", "F#", "G", "Ab", "A", "Bb", "B"]
_RANDOM_MODES = ["major", "minor", "dorian", "mixolydian", "lydian", "phrygian", "harmonic_minor"]
_RANDOM_TEMPOS = list(range(50, 181, 5))
_RANDOM_BARS = [8, 12, 16, 20, 24, 32]


@app.get("/random-prompt", response_model=RandomPromptResponse)
def random_prompt() -> RandomPromptResponse:
    """Return a randomly generated set of music composition parameters."""
    return RandomPromptResponse(
        prompt=random.choice(_RANDOM_PROMPTS),
        style=random.choice(_RANDOM_STYLES),
        key=random.choice(_RANDOM_KEYS),
        mode=random.choice(_RANDOM_MODES),
        tempo_bpm=random.choice(_RANDOM_TEMPOS),
        bars=random.choice(_RANDOM_BARS),
    )


def _hash_audio_bytes(audio_bytes: bytes) -> str:
    return hashlib.sha256(audio_bytes).hexdigest()


def _cache_get(cache_key: str) -> AnalysisResponse | None:
    with _analysis_cache_lock:
        cached = _analysis_cache.get(cache_key)
        if cached is None:
            return None
        # LRU refresh: move recently accessed item to the end.
        _analysis_cache.move_to_end(cache_key)
        return cached.model_copy(deep=True)


def _cache_set(cache_key: str, response: AnalysisResponse) -> None:
    with _analysis_cache_lock:
        _analysis_cache[cache_key] = response.model_copy(deep=True)
        _analysis_cache.move_to_end(cache_key)
        while len(_analysis_cache) > ANALYSIS_CACHE_MAX_ITEMS:
            _analysis_cache.popitem(last=False)


def _get_analyze_audio_bytes() -> Callable[[bytes], AnalysisResponse]:
    global _analyze_audio_bytes
    global _analyze_audio_import_error

    if _analyze_audio_bytes is not None:
        return _analyze_audio_bytes
    if _analyze_audio_import_error is not None:
        raise _analyze_audio_import_error

    try:
        from app.services.audio_analysis import analyze_audio_bytes
    except ImportError as exc:
        _analyze_audio_import_error = exc
        raise

    _analyze_audio_bytes = analyze_audio_bytes
    return analyze_audio_bytes


@app.post("/analyze", response_model=AnalysisResponse)
async def analyze(file: UploadFile = File(...)) -> AnalysisResponse:
    file_name = (file.filename or "").lower()
    has_allowed_extension = any(file_name.endswith(ext) for ext in ALLOWED_AUDIO_EXTENSIONS)
    has_audio_mime = bool(file.content_type and file.content_type.startswith("audio"))

    if not has_audio_mime and not has_allowed_extension:
        raise HTTPException(status_code=400, detail="Please upload an audio file")

    audio_bytes = await file.read()
    if not audio_bytes:
        raise HTTPException(status_code=400, detail="Uploaded file is empty")

    cache_key = _hash_audio_bytes(audio_bytes)
    cached = _cache_get(cache_key)
    if cached is not None:
        return cached

    try:
        analyze_audio_bytes = _get_analyze_audio_bytes()
    except ImportError as exc:
        raise HTTPException(
            status_code=503,
            detail=(
                "Audio analysis dependencies are not available. "
                "Run: pip install -r backend/requirements.txt"
            ),
        ) from exc

    try:
        response = analyze_audio_bytes(audio_bytes)
        _cache_set(cache_key, response)
        return response
    except Exception as exc:  # noqa: BLE001
        raise HTTPException(status_code=500, detail=f"Audio analysis failed: {exc}") from exc


@app.post("/compose", response_model=CompositionResponse)
def compose(request: CompositionRequest) -> CompositionResponse:
    """Generate a multi-track composition from a natural-language prompt.

    Optional dependencies (``music21`` and the LangGraph stack) must be
    installed for this endpoint; see ``backend/requirements-composer.txt``.
    """
    try:
        from app.services.music_composer import compose as run_compose
    except Exception as exc:  # noqa: BLE001
        raise HTTPException(
            status_code=503,
            detail=(
                "Music composer dependencies are not installed. "
                "Run: pip install -r requirements-composer.txt"
            ),
        ) from exc

    try:
        return run_compose(request)
    except Exception as exc:  # noqa: BLE001
        raise HTTPException(status_code=500, detail=f"Composition failed: {exc}") from exc
