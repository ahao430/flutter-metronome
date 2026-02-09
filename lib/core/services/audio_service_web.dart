import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;
import '../models/beat_type.dart';
import '../models/sound_pack.dart';

/// Web 音色配置（合成音）
class WebSoundConfig {
  final double strongFreq;
  final double weakFreq;
  final String waveType;
  final double duration;

  const WebSoundConfig({
    required this.strongFreq,
    required this.weakFreq,
    this.waveType = 'sine',
    this.duration = 0.08,
  });

  double get subAccentFreq => (strongFreq + weakFreq) / 2;

  /// 每种音色对应的 Web Audio 合成配置
  static const Map<SoundPack, WebSoundConfig> configs = {
    SoundPack.click: WebSoundConfig(
      strongFreq: 1200,
      weakFreq: 900,
      waveType: 'square',
      duration: 0.05,
    ),
    SoundPack.stick: WebSoundConfig(
      strongFreq: 800,
      weakFreq: 600,
      waveType: 'triangle',
      duration: 0.04,
    ),
    SoundPack.block: WebSoundConfig(
      strongFreq: 700,
      weakFreq: 500,
      waveType: 'triangle',
      duration: 0.06,
    ),
    SoundPack.tick: WebSoundConfig(
      strongFreq: 1000,
      weakFreq: 800,
      waveType: 'square',
      duration: 0.03,
    ),
    SoundPack.clap: WebSoundConfig(
      strongFreq: 400,
      weakFreq: 300,
      waveType: 'sawtooth',
      duration: 0.08,
    ),
    SoundPack.bell: WebSoundConfig(
      strongFreq: 880,
      weakFreq: 660,
      waveType: 'sine',
      duration: 0.15,
    ),
  };
}

/// Web Audio 服务实现
class AudioService {
  bool _isInitialized = false;
  web.AudioContext? _audioContext;
  SoundPack _currentPack = SoundPack.click;

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

    final config = WebSoundConfig.configs[_currentPack] ??
        const WebSoundConfig(
          strongFreq: 880,
          weakFreq: 660,
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

    gainNode.gain.value = volume;

    oscillator.connect(gainNode);
    gainNode.connect(ctx.destination);

    final now = ctx.currentTime;
    oscillator.start(now);

    gainNode.gain.setValueAtTime(volume, now);
    gainNode.gain.exponentialRampToValueAtTime(0.001, now + duration);
    oscillator.stop(now + duration + 0.01);
  }

  /// 播放木鱼声音 - 双音叠加模拟木鱼敲击
  void playWoodenFish() {
    final ctx = _audioContext;
    if (ctx == null) return;

    _playWoodFishTone(ctx, 650, 0.5, 0.12);
    _playWoodFishTone(ctx, 1300, 0.2, 0.08);
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
