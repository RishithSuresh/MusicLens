# MusicLens - Interactive Visual Music Explainer

MusicLens is a two-part system:
- FastAPI backend for audio feature extraction and rule-based music insight generation.
- Flutter frontend (light-themed premium dashboard style) for interactive visual exploration.

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

4. Optional expansions
  - Instrument separation (backend)
  - Song comparison view
  - Multi-track Music DNA benchmarking

## 3) Backend Setup (Windows + VS Code)

### Commands

```powershell
cd backend
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
uvicorn app.main:app --reload
```

### API Endpoint

- Health: GET http://127.0.0.1:8000/health
- Analyze: POST http://127.0.0.1:8000/analyze (multipart/form-data, file field name: file)

## 4) Frontend Setup (Windows + VS Code)

### Commands

```powershell
cd frontend
flutter pub get
flutter run -d chrome
```

If running desktop:

```powershell
flutter run -d windows
```

The frontend expects backend at:
- http://127.0.0.1:8000

You can change this in:
- lib/features/audio/data/audio_api_service.dart

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

Optional for future:
- Instrument separation and comparative analytics pages
