from fastapi import FastAPI, File, HTTPException, UploadFile
from fastapi.middleware.cors import CORSMiddleware

from app.models.analysis import AnalysisResponse
from app.services.audio_analysis import analyze_audio_bytes

app = FastAPI(title="MusicLens API", version="0.1.0")

ALLOWED_AUDIO_EXTENSIONS = {".mp3", ".wav", ".flac", ".ogg", ".m4a"}

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

    try:
        return analyze_audio_bytes(audio_bytes)
    except Exception as exc:  # noqa: BLE001
        raise HTTPException(status_code=500, detail=f"Audio analysis failed: {exc}") from exc
