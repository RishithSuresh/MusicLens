import hashlib
from collections import OrderedDict
from threading import Lock

from fastapi import FastAPI, File, HTTPException, UploadFile
from fastapi.middleware.cors import CORSMiddleware

from app.models.analysis import AnalysisResponse
from app.services.audio_analysis import analyze_audio_bytes

app = FastAPI(title="MusicLens API", version="0.1.0")

ALLOWED_AUDIO_EXTENSIONS = {".mp3", ".wav", ".flac", ".ogg", ".m4a"}
ANALYSIS_CACHE_MAX_ITEMS = 24

_analysis_cache: OrderedDict[str, AnalysisResponse] = OrderedDict()
_analysis_cache_lock = Lock()

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
        response = analyze_audio_bytes(audio_bytes)
        _cache_set(cache_key, response)
        return response
    except Exception as exc:  # noqa: BLE001
        raise HTTPException(status_code=500, detail=f"Audio analysis failed: {exc}") from exc
