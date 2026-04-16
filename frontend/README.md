# MusicLens Frontend

Flutter analytics dashboard for visual music explanation.

## Run

```powershell
flutter pub get
flutter run -d chrome
```

## Main Modules

- lib/core/theme/app_theme.dart
- lib/core/widgets/glass_card.dart
- lib/features/audio/data/audio_api_service.dart
- lib/features/audio/presentation/screens/dashboard_screen.dart
- lib/features/audio/presentation/widgets/

## Notes

- Light theme, layered gradients, glass cards, soft shadow style
- Real audio playback synchronized with visual timeline
- Waveform supports tap/drag seeking and hover tooltip
- Spectrum panel and insight panel react to live playback state
- Bass-reactive particle field and energy-based color transitions
