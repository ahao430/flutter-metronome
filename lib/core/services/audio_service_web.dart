import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;
import '../models/beat_type.dart';
import '../models/sound_pack.dart';

/// Web Audio 服务实现
class AudioService {
  bool _isInitialized = false;
  web.AudioContext? _audioContext;
  SoundPack _currentPack = SoundPack.digital;

  Future<void> initialize() async {
    if (_isInitialized) return;
    _audioContext = web.AudioContext();
    _isInitialized = true;
    debugPrint('AudioService initialized (Web Audio API)');
  }

  void setSoundPack(SoundPack pack) {
    _currentPack = pack;
  }

  SoundPack get currentPack => _currentPack;

  void playBeat(BeatType type) {
    if (type == BeatType.rest || _audioContext == null) return;

    // 获取配置，如果不存在则使用默认配置
    final config = SoundPackConfig.configs[_currentPack] ??
        const SoundPackConfig(
          strongFreq: 880,
          weakFreq: 660,
          subAccentFreq: 770,
          waveType: 'sine',
          duration: 0.1,
        );
    final frequency = switch (type) {
      BeatType.strong => config.strongFreq,
      BeatType.subAccent => config.subAccentFreq,
      BeatType.weak => config.weakFreq,
      BeatType.rest => 0.0,
    };
    final volume = type == BeatType.strong ? 0.7 : 0.4;
    _playTone(frequency, volume, config.duration, config.waveType);
  }

  void _playTone(double frequency, double volume, double duration, String waveType) {
    final ctx = _audioContext;
    if (ctx == null) return;

    final oscillator = ctx.createOscillator();
    final gainNode = ctx.createGain();

    oscillator.type = waveType;
    oscillator.frequency.value = frequency;

    // 起始音量
    gainNode.gain.value = volume;

    oscillator.connect(gainNode);
    gainNode.connect(ctx.destination);

    final now = ctx.currentTime;
    oscillator.start(now);

    // 快速衰减
    gainNode.gain.setValueAtTime(volume, now);
    gainNode.gain.exponentialRampToValueAtTime(0.001, now + duration);
    oscillator.stop(now + duration + 0.01);
  }

  /// 播放木鱼声音 - 双音叠加模拟木鱼敲击
  void playWoodenFish() {
    final ctx = _audioContext;
    if (ctx == null) return;

    // 木鱼主音
    _playWoodFishTone(ctx, 650, 0.5, 0.12);
    // 泛音
    _playWoodFishTone(ctx, 1300, 0.2, 0.08);
    // 低频共振
    _playWoodFishTone(ctx, 200, 0.3, 0.15);
  }

  void _playWoodFishTone(web.AudioContext ctx, double freq, double vol, double dur) {
    final osc = ctx.createOscillator();
    final gain = ctx.createGain();

    osc.type = 'triangle';
    osc.frequency.value = freq;
    gain.gain.value = vol;

    osc.connect(gain);
    gain.connect(ctx.destination);

    final now = ctx.currentTime;
    osc.start(now);
    gain.gain.exponentialRampToValueAtTime(0.001, now + dur);
    osc.stop(now + dur + 0.01);
  }

  void dispose() {
    _audioContext?.close();
    _audioContext = null;
    _isInitialized = false;
  }
}
