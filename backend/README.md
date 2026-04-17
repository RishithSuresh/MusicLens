# MusicLens Backend

FastAPI audio analysis backend.

## Run

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
uvicorn app.main:app --reload
```

## Endpoints

- GET /health
- POST /analyze (multipart/form-data with file)

## Output

The API returns:
- tempo (BPM)
- beat timestamps
- pitch over time
- RMS energy over time
- normalized STFT spectrum frames
- rule-based insights
- best-effort lyrics/transcription text

## Notes for Lyrics Extraction

- Lyrics extraction uses Whisper-compatible engines and runs best-effort.
- Whisper is optional and is not required for normal backend startup.
- If transcription fails (for example missing ffmpeg or unclear vocals), the API still succeeds and returns an empty `lyrics` string.

The backend tries engines in this order:
1. `openai-whisper` (if installed)
2. `faster-whisper` (if installed)

### Optional: enable Whisper locally

If you want lyrics extraction enabled, install one of these after base dependencies:

Option A (recommended on Windows):

```powershell
pip install -r requirements-lyrics.txt
```

Option B (`openai-whisper`, may fail on some environments due to upstream packaging issues):

```powershell
pip install setuptools==80.9.0 wheel
pip install openai-whisper==20231117 --no-build-isolation
```
