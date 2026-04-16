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
