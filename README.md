# MusicLens - Interactive Visual Music Explainer & AI Compositor

MusicLens is an interactive music analysis and generation project that pairs a
FastAPI backend with a Flutter frontend. It lets you upload an audio file to
inspect tempo, pitch, energy, and rule-based insights, or generate a new piece
from a text prompt with a multi-track arrangement, piano-roll visualization,
and downloadable MIDI / MP3 output.

At a glance:
- FastAPI backend for audio feature extraction, best-effort lyrics
  transcription, and AI-assisted composition.
- Flutter frontend with a light, premium dashboard UI and two core modes:
  **Analyze** for audio exploration and **Compose** for prompt-driven music
  generation.
- MP3 preview/export is self-contained in the backend using a bundled encoder,
  so no system ffmpeg install is required for the compose workflow.

## 1) Folder Structure

```text
MusicLens/
  backend/
    app/
      main.py
      models/
        analysis.py
      services/
        audio_analysis.py
    requirements.txt
    tests/
  frontend/
    lib/
      core/
        theme/
          app_theme.dart
        widgets/
          glass_card.dart
      features/
        audio/
          data/
            analysis_models.dart
            audio_api_service.dart
          presentation/
            screens/
              dashboard_screen.dart
            widgets/
              animated_background.dart
              insights_panel.dart
              metric_chip.dart
              spectrum_panel.dart
              waveform_panel.dart
      main.dart
    test/
      widget_test.dart
    pubspec.yaml
```

## 2) Incremental Implementation Plan

1. Backend setup (completed)
   - FastAPI app + CORS
   - POST /analyze endpoint with audio upload
   - librosa-based extraction for BPM, beat times, pitch (pyin), RMS energy, STFT spectrum
   - Rule-based insight generation

2. Flutter base UI setup (completed)
   - Custom light theme and visual design tokens
   - Layered animated background and glassmorphism cards
   - Dashboard layout with waveform, spectrum, metrics, and insights panels
   - Interactive waveform seek + hover tooltip

3. Advanced reactive layer (completed)
  - Real audio playback with waveform/spectrum sync
  - Bass-reactive particle system
  - Energy-driven color transitions
  - Rule-based section timeline for "What's happening now?"
  - Best-effort lyrics extraction and dashboard lyrics panel

4. AI Music Compositor (completed)
  - `POST /compose` endpoint accepting a free-form prompt
  - LangGraph-based prompt interpretation (genre / mood / mode / tempo /
    key / bars), with a deterministic keyword-heuristic fallback when no
    `OPENAI_API_KEY` is configured
  - Procedural music engine (modal scales, diatonic chord progressions,
    voice leading, genre-aware drum + bass patterns, song-level
    intro/verse/chorus/bridge/outro structure)
  - Multi-track output: melody, harmony, bass, drums (note-level JSON +
    base64-encoded MIDI file + base64-encoded MP3 preview audio)
  - Frontend Compose tab with composition form, piano-roll visualizer,
    AI narrative panel, in-app audio playback, and MIDI/MP3 download

5. Optional expansions
  - Instrument separation (backend)
  - Song comparison view
  - Multi-track Music DNA benchmarking

## 3) Backend Setup (Windows + VS Code)

### Commands

```powershell
cd backend
python -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install --upgrade pip setuptools wheel
pip install -r requirements.txt
# Optional: install lyrics transcription engine
pip install -r requirements-lyrics.txt
# Optional: install AI Music Compositor runtime dependencies (music21/mido).
# The /compose endpoint works without LangGraph/LangChain and falls back to
# the deterministic procedural engine when LLM dependencies are absent.
pip install -r requirements-composer.txt
uvicorn app.main:app --reload
```

### API Endpoint

- Health: GET http://127.0.0.1:8000/health
- Readiness: GET http://127.0.0.1:8000/ready
- Analyze: POST http://127.0.0.1:8000/analyze (multipart/form-data, file field name: file)
- Compose: POST http://127.0.0.1:8000/compose (application/json, body keys: `prompt`, optional `style`, `key`, `mode`, `tempo_bpm`, `bars`, `use_llm`)

## 4) Frontend Setup (Windows + VS Code)

### Commands

```powershell
cd frontend
flutter pub get
flutter run -d chrome --dart-define=MUSICLENS_API_BASE_URL=http://127.0.0.1:8000
```

If running desktop:

```powershell
flutter run -d windows
```

The frontend expects backend at:
- `MUSICLENS_API_BASE_URL` dart define (defaults to `http://127.0.0.1:8000`)

Example production web build:

```powershell
flutter build web --release --dart-define=MUSICLENS_API_BASE_URL=https://your-api.example.com
```

## 8) Deployment Notes

### Backend runtime env vars

Create `.env` from `backend/.env.example` and tune:
- `MUSICLENS_ENV` (`development` or `production`)
- `MUSICLENS_CORS_ORIGINS` (comma-separated allowed origins)
- `MUSICLENS_MAX_UPLOAD_BYTES` (default 20 MB)
- `MUSICLENS_MAX_PROMPT_CHARS` (default 500)
- `MUSICLENS_ENABLE_COMPOSE` / `MUSICLENS_ENABLE_LYRICS`
- `MUSICLENS_LOG_LEVEL`

### Backend container

```powershell
cd backend
docker build -t musiclens-backend .
docker run --rm -p 8000:8000 --env-file .env musiclens-backend
```

### CI

GitHub Actions workflow is included at `.github/workflows/ci.yml`:
- backend: install + `pytest`
- frontend: `flutter pub get`, `flutter analyze`, `flutter test`

## 5) UI Layout + Widget Breakdown

### Screen Composition

- DashboardScreen
  - Top controls: select audio, analyze, play/pause visual sync
  - Metrics row: BPM, Duration, Sample Rate, Energy
  - Main visual: interactive waveform card
  - Side visuals: spectrum card + insight card

### Reusable Design Widgets

- AnimatedBackground
  - Soft gradient, blurred animated blobs, subtle moving wave lines
- GlassCard
  - Light blur + translucent card + soft shadows
- MetricChip
  - Compact KPI tile for analytics-style headers

### Visual Analytic Widgets

- WaveformPanel
  - Energy waveform
  - Beat markers
  - Pitch curve overlay
  - Current timeline indicator
  - Tap/drag seek and hover data tooltip

- SpectrumPanel
  - Animated-style spectrum bars with energy-aware glow

- InsightsPanel
  - "What's happening now?" rule-based real-time statement
  - Insight badges from backend

## 6) Current Feature Status

Implemented now:
- End-to-end upload and analysis request flow
- Backend feature extraction JSON
- Light-themed premium dashboard with interactive reactive visuals
- Real audio playback synchronized to analytics timeline
- Rule-based insight timeline and Music DNA summary panel
- Lyrics/transcription display after audio analysis

Note: lyrics transcription is best-effort and requires optional Whisper installation in the backend environment.

Optional for future:
- Instrument separation and comparative analytics pages

## 7) Project Description

MusicLens is designed as a hands-on music intelligence demo. The analyzer turns
an uploaded song into visual and textual summaries of rhythm, energy, and
spectral shape, while the composer turns a written prompt into a structured
piece of music that can be previewed directly in the browser. The project is
useful as both a portfolio piece and a practical prototype for music analysis,
procedural composition, and lightweight AI-assisted creativity.
