import 'package:flutter/foundation.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import '../models/beat_type.dart';
import '../models/sound_pack.dart';

/// 音频服务 - 移动端/桌面端实现
/// 使用 flutter_soloud 加载预生成的音频文件（避免 loadWaveform 在 Android 上不稳定）
class AudioService {
  bool _isInitialized = false;
  SoundPack _currentPack = SoundPack.digital;

  // 预加载的音源 (key: "packFolderName_beatType")
  final Map<String, AudioSource> _audioSources = {};

  // 木鱼音源
  AudioSource? _woodenFishSource;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // 初始化 SoLoud，使用较大的缓冲区增加稳定性
      await SoLoud.instance.init();
      debugPrint('✅ SoLoud engine initialized');

      // 预加载所有音色
      await _loadAllSounds();

      _isInitialized = true;
      debugPrint('✅ AudioService fully initialized');
    } catch (e, stack) {
      debugPrint('❌ AudioService init failed: $e');
      debugPrint('Stack: $stack');
      _isInitialized = false;
    }
  }

  /// 预加载所有音色（使用音频文件而非实时合成）
  Future<void> _loadAllSounds() async {
    // 加载合成音色（使用预生成的 wav 文件）
    final synthPacks = ['digital', 'analog', 'woodblock', 'hihat', 'cowbell'];
    final beatTypes = ['strong', 'weak', 'subaccent'];

    for (final pack in synthPacks) {
      for (final type in beatTypes) {
        final key = '${pack}_$type';
        try {
          final path = 'assets/audio/synth/${pack}_$type.wav';
          final source = await SoLoud.instance.loadAsset(path);
          _audioSources[key] = source;
          debugPrint('✅ Loaded synth: $key');
        } catch (e) {
          debugPrint('⚠️ Failed to load synth $key: $e');
        }
      }
    }

    // 加载采样音色
    for (final pack in SoundPack.values) {
      if (!pack.isSample) continue;

      for (final type in beatTypes) {
        final key = '${pack.folderName}_$type';
        if (_audioSources.containsKey(key)) continue;

        try {
          final path = pack.getAssetPath(type);
          final source = await SoLoud.instance.loadAsset(path);
          _audioSources[key] = source;
          debugPrint('✅ Loaded sample: $key');
        } catch (e) {
          debugPrint('⚠️ Sample not found: ${pack.getAssetPath(type)}');
        }
      }
    }

    // 加载木鱼音效
    try {
      _woodenFishSource = await SoLoud.instance.loadAsset('assets/audio/synth/woodenfish.wav');
      debugPrint('✅ Loaded wooden fish sound');
    } catch (e) {
      debugPrint('⚠️ Failed to load wooden fish: $e');
    }

    debugPrint('✅ Loaded ${_audioSources.length} sounds total');
  }

  void setSoundPack(SoundPack pack) {
    _currentPack = pack;
  }

  SoundPack get currentPack => _currentPack;

  void playBeat(BeatType type) {
    if (type == BeatType.rest || !_isInitialized) {
      return;
    }

    final typeStr = switch (type) {
      BeatType.strong => 'strong',
      BeatType.subAccent => 'subaccent',
      BeatType.weak => 'weak',
      BeatType.rest => '',
    };

    final key = '${_currentPack.folderName}_$typeStr';
    final source = _audioSources[key];

    if (source != null) {
      final volume = switch (type) {
        BeatType.strong => 0.9,
        BeatType.subAccent => 0.7,
        BeatType.weak => 0.5,
        BeatType.rest => 0.0,
      };
      try {
        SoLoud.instance.play(source, volume: volume);
      } catch (e) {
        debugPrint('❌ Play error: $e');
        // 尝试使用备用音色
        _playFallback(type);
      }
    } else {
      // 音源未加载，使用备用
      _playFallback(type);
    }
  }

  /// 后备音色（使用 digital）
  void _playFallback(BeatType type) {
    final typeStr = switch (type) {
      BeatType.strong => 'strong',
      BeatType.subAccent => 'subaccent',
      BeatType.weak => 'weak',
      BeatType.rest => '',
    };

    final key = 'digital_$typeStr';
    final source = _audioSources[key];

    if (source != null) {
      final volume = switch (type) {
        BeatType.strong => 0.8,
        BeatType.subAccent => 0.6,
        BeatType.weak => 0.4,
        BeatType.rest => 0.0,
      };
      try {
        SoLoud.instance.play(source, volume: volume);
      } catch (e) {
        debugPrint('❌ Fallback play error: $e');
      }
    }
  }

  /// 播放木鱼声音
  void playWoodenFish() {
    if (!_isInitialized || _woodenFishSource == null) return;
    try {
      SoLoud.instance.play(_woodenFishSource!, volume: 0.8);
    } catch (e) {
      debugPrint('❌ Play wooden fish error: $e');
    }
  }

  void dispose() {
    // 清理所有音源
    for (final source in _audioSources.values) {
      try {
        SoLoud.instance.disposeSource(source);
      } catch (_) {}
    }
    _audioSources.clear();

    // 清理木鱼音源
    if (_woodenFishSource != null) {
      try {
        SoLoud.instance.disposeSource(_woodenFishSource!);
      } catch (_) {}
      _woodenFishSource = null;
    }

    try {
      SoLoud.instance.deinit();
    } catch (_) {}
    _isInitialized = false;
  }
}
