import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../models/beat_type.dart';
import '../models/sound_pack.dart';

/// Web Audio 服务实现 - 使用 just_audio 加载真实音频文件
class AudioService {
  bool _isInitialized = false;
  SoundPack _currentPack = SoundPack.click;

  // 预加载的播放器 (key: "packName_beatType")
  final Map<String, AudioPlayer> _players = {};

  // 木鱼播放器
  AudioPlayer? _woodenFishPlayer;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _loadAllSounds();
      _isInitialized = true;
      debugPrint('✅ AudioService initialized (just_audio for Web)');
    } catch (e) {
      debugPrint('❌ AudioService init failed: $e');
      _isInitialized = false;
    }
  }

  /// 预加载所有采样音色
  Future<void> _loadAllSounds() async {
    final beatTypes = ['strong', 'weak', 'subaccent'];

    for (final pack in SoundPack.values) {
      for (final type in beatTypes) {
        final key = '${pack.folderName}_$type';
        try {
          final player = AudioPlayer();
          await player.setAsset('assets/audio/samples/${pack.folderName}_$type.wav');
          _players[key] = player;
          debugPrint('✅ Loaded: $key');
        } catch (e) {
          debugPrint('⚠️ Failed to load $key: $e');
        }
      }
    }

    // 加载木鱼音效
    try {
      _woodenFishPlayer = AudioPlayer();
      await _woodenFishPlayer!.setAsset('assets/audio/synth/woodenfish.wav');
      debugPrint('✅ Loaded wooden fish sound');
    } catch (e) {
      debugPrint('⚠️ Failed to load wooden fish: $e');
    }

    debugPrint('✅ Loaded ${_players.length} sounds total');
  }

  void setSoundPack(SoundPack pack) {
    _currentPack = pack;
  }

  SoundPack get currentPack => _currentPack;

  void playBeat(BeatType type) {
    if (type == BeatType.rest || !_isInitialized) return;

    final typeStr = switch (type) {
      BeatType.strong => 'strong',
      BeatType.subAccent => 'subaccent',
      BeatType.weak => 'weak',
      BeatType.rest => '',
    };

    final key = '${_currentPack.folderName}_$typeStr';
    final player = _players[key];

    if (player != null) {
      final volume = switch (type) {
        BeatType.strong => 1.0,
        BeatType.subAccent => 0.8,
        BeatType.weak => 0.6,
        BeatType.rest => 0.0,
      };

      _playSound(player, volume);
    } else {
      // 使用后备音色
      _playFallback(type);
    }
  }

  /// 播放音频
  void _playSound(AudioPlayer player, double volume) async {
    try {
      await player.setVolume(volume);
      await player.seek(Duration.zero);
      player.play();
    } catch (e) {
      debugPrint('❌ Play error: $e');
    }
  }

  /// 后备音色（使用 click）
  void _playFallback(BeatType type) {
    final typeStr = switch (type) {
      BeatType.strong => 'strong',
      BeatType.subAccent => 'subaccent',
      BeatType.weak => 'weak',
      BeatType.rest => '',
    };

    final key = 'click_$typeStr';
    final player = _players[key];

    if (player != null) {
      final volume = switch (type) {
        BeatType.strong => 0.9,
        BeatType.subAccent => 0.7,
        BeatType.weak => 0.5,
        BeatType.rest => 0.0,
      };
      _playSound(player, volume);
    }
  }

  /// 播放木鱼声音
  void playWoodenFish() {
    if (!_isInitialized || _woodenFishPlayer == null) return;
    _playSound(_woodenFishPlayer!, 0.8);
  }

  void dispose() {
    for (final player in _players.values) {
      player.dispose();
    }
    _players.clear();

    _woodenFishPlayer?.dispose();
    _woodenFishPlayer = null;

    _isInitialized = false;
  }
}
