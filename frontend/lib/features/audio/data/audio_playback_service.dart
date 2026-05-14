import 'dart:async';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';

class AudioPlaybackService {
  final AudioPlayer _player = AudioPlayer();

  late final StreamSubscription<Duration> _positionSub;
  late final StreamSubscription<PlayerState> _stateSub;
  late final StreamSubscription<void> _completeSub;

  final StreamController<Duration> _positionController = StreamController.broadcast();
  final StreamController<PlayerState> _stateController = StreamController.broadcast();

  AudioPlaybackService() {
    // Initialize audio player with proper settings for web
    _player.setReleaseMode(ReleaseMode.stop);
    _player.setVolume(1.0);

    _positionSub = _player.onPositionChanged.listen((duration) {
      _positionController.add(duration);
    });

    _stateSub = _player.onPlayerStateChanged.listen((state) {
      _stateController.add(state);
    });

    _completeSub = _player.onPlayerComplete.listen((_) {
      _stateController.add(PlayerState.completed);
    });
  }

  Stream<Duration> get positionStream => _positionController.stream;
  Stream<PlayerState> get stateStream => _stateController.stream;

  Future<void> loadFile(PlatformFile file) async {
    try {
      await _player.stop();

      if (file.bytes != null && file.bytes!.isNotEmpty) {
        await _player.setSource(BytesSource(file.bytes!));
        return;
      }

      if (file.path != null && file.path!.isNotEmpty) {
        await _player.setSource(DeviceFileSource(file.path!));
        return;
      }

      throw StateError('Audio file is not readable on this platform.');
    } catch (e) {
      rethrow;
    }
  }

  Future<void> loadBytes(Uint8List bytes, {String? mimeType}) async {
    if (bytes.isEmpty) {
      throw StateError('Audio bytes are empty.');
    }
    await _player.stop();
    await _player.setSource(BytesSource(bytes, mimeType: mimeType));
  }

  Future<void> play() async {
    try {
      await _player.resume();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> pause() async {
    try {
      await _player.pause();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> seek(double seconds) async {
    await _player.seek(Duration(milliseconds: (seconds * 1000).round()));
  }

  Future<void> stop() async {
    await _player.stop();
  }

  Future<void> dispose() async {
    await _positionSub.cancel();
    await _stateSub.cancel();
    await _completeSub.cancel();
    await _positionController.close();
    await _stateController.close();
    await _player.dispose();
  }
}
