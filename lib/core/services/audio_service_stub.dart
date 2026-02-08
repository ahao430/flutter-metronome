import 'package:flutter/foundation.dart';
import '../models/beat_type.dart';
import '../models/sound_pack.dart';

/// 音频服务 Stub - 非 Web 平台实现
class AudioService {
  bool _isInitialized = false;
  SoundPack _currentPack = SoundPack.digital;

  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;
    debugPrint('AudioService initialized (Stub)');
  }

  void setSoundPack(SoundPack pack) {
    _currentPack = pack;
  }

  SoundPack get currentPack => _currentPack;

  void playBeat(BeatType type) {
    if (type == BeatType.rest) return;
    debugPrint('Beat: $type (${_currentPack.name})');
  }

  void playWoodenFish() {
    debugPrint('Wooden fish knock!');
  }

  void dispose() {
    _isInitialized = false;
  }
}
