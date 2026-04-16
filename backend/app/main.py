from fastapi import FastAPI, File, HTTPException, UploadFile
from fastapi.middleware.cors import CORSMiddleware

from app.models.analysis import AnalysisResponse
from app.services.audio_analysis import analyze_audio_bytes

app = FastAPI(title="MusicLens API", version="0.1.0")

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
    if not file.content_type or not file.content_type.startswith("audio"):
        raise HTTPException(status_code=400, detail="Please upload an audio file")

    audio_bytes = await file.read()
    if not audio_bytes:
        raise HTTPException(status_code=400, detail="Uploaded file is empty")

    try:
        return analyze_audio_bytes(audio_bytes)
    except Exception as exc:  # noqa: BLE001
        raise HTTPException(status_code=500, detail=f"Audio analysis failed: {exc}") from exc
