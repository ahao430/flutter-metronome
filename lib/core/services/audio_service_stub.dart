import 'package:flutter/foundation.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import '../models/beat_type.dart';
import '../models/sound_pack.dart';

/// 音频服务 - 移动端/桌面端实现
/// 使用 flutter_soloud 进行低延迟音频合成和采样播放
class AudioService {
  bool _isInitialized = false;
  SoundPack _currentPack = SoundPack.digital;

  // 预加载的合成音源 (key: "packFolderName_beatType")
  final Map<String, AudioSource> _synthSources = {};

  // 预加载的采样音源
  final Map<String, AudioSource> _sampleSources = {};

  // 木鱼音源
  AudioSource? _woodenFishSource;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // 初始化 SoLoud
      await SoLoud.instance.init();
      debugPrint('✅ SoLoud engine initialized');

      // 预加载所有合成音色
      await _loadSynthSounds();

      // 预加载木鱼音效
      await _loadWoodenFishSound();

      // 预加载默认采样音色
      if (_currentPack.isSample) {
        await _loadSamplePack(_currentPack);
      }

      _isInitialized = true;
      debugPrint('✅ AudioService fully initialized');
    } catch (e, stack) {
      debugPrint('❌ AudioService init failed: $e');
      debugPrint('Stack: $stack');
      _isInitialized = false;
    }
  }

  /// 预加载所有合成音色
  Future<void> _loadSynthSounds() async {
    for (final pack in SoundPack.values) {
      if (!pack.isSynthesis) continue;

      try {
        final synthConfig = _getSynthConfig(pack);

        // 强拍
        _synthSources['${pack.folderName}_strong'] = await SoLoud.instance.loadWaveform(
          synthConfig.strongWave,
          true, // superWave
          synthConfig.strongScale,
          0.0, // detune
        );

        // 弱拍
        _synthSources['${pack.folderName}_weak'] = await SoLoud.instance.loadWaveform(
          synthConfig.weakWave,
          true,
          synthConfig.weakScale,
          0.0,
        );

        // 次强拍
        _synthSources['${pack.folderName}_subaccent'] = await SoLoud.instance.loadWaveform(
          synthConfig.subAccentWave,
          true,
          synthConfig.subAccentScale,
          0.0,
        );

        debugPrint('✅ Loaded synth: ${pack.folderName}');
      } catch (e) {
        debugPrint('❌ Failed to load synth ${pack.folderName}: $e');
      }
    }

    debugPrint('✅ Loaded ${_synthSources.length} synth sounds total');
  }

  /// 加载木鱼音效 (三角波模拟)
  Future<void> _loadWoodenFishSound() async {
    try {
      _woodenFishSource = await SoLoud.instance.loadWaveform(
        WaveForm.triangle,
        true,
        1.2,
        0.0,
      );
      debugPrint('✅ Loaded wooden fish sound');
    } catch (e) {
      debugPrint('❌ Failed to load wooden fish: $e');
    }
  }

  /// 获取合成音配置
  _SynthConfig _getSynthConfig(SoundPack pack) {
    return switch (pack) {
      // 数字音 - 清脆的方波
      SoundPack.digital => const _SynthConfig(
        strongWave: WaveForm.square,
        strongScale: 2.5,
        weakWave: WaveForm.square,
        weakScale: 1.8,
        subAccentWave: WaveForm.square,
        subAccentScale: 2.2,
      ),

      // 机械音 - 温暖的三角波
      SoundPack.analog => const _SynthConfig(
        strongWave: WaveForm.triangle,
        strongScale: 1.5,
        weakWave: WaveForm.triangle,
        weakScale: 1.0,
        subAccentWave: WaveForm.triangle,
        subAccentScale: 1.2,
      ),

      // 木块 - 短促三角波
      SoundPack.woodblock => const _SynthConfig(
        strongWave: WaveForm.triangle,
        strongScale: 2.0,
        weakWave: WaveForm.triangle,
        weakScale: 1.5,
        subAccentWave: WaveForm.triangle,
        subAccentScale: 1.8,
      ),

      // 踩镲 - 高频方波
      SoundPack.hihat => const _SynthConfig(
        strongWave: WaveForm.square,
        strongScale: 4.0,
        weakWave: WaveForm.square,
        weakScale: 3.5,
        subAccentWave: WaveForm.square,
        subAccentScale: 3.8,
      ),

      // 牛铃 - 中高频方波
      SoundPack.cowbell => const _SynthConfig(
        strongWave: WaveForm.square,
        strongScale: 1.8,
        weakWave: WaveForm.square,
        weakScale: 1.4,
        subAccentWave: WaveForm.square,
        subAccentScale: 1.6,
      ),

      // 采样音色默认配置 (作为后备)
      _ => const _SynthConfig(
        strongWave: WaveForm.sin,
        strongScale: 2.0,
        weakWave: WaveForm.sin,
        weakScale: 1.5,
        subAccentWave: WaveForm.sin,
        subAccentScale: 1.8,
      ),
    };
  }

  void setSoundPack(SoundPack pack) {
    _currentPack = pack;
    // 如果切换到采样音色，尝试加载
    if (pack.isSample && _isInitialized) {
      _loadSamplePack(pack);
    }
  }

  SoundPack get currentPack => _currentPack;

  /// 加载采样音色包
  Future<void> _loadSamplePack(SoundPack pack) async {
    if (!pack.isSample) return;

    final beatTypes = ['strong', 'weak', 'subaccent'];
    for (final type in beatTypes) {
      final key = '${pack.folderName}_$type';
      if (_sampleSources.containsKey(key)) continue;

      try {
        final path = pack.getAssetPath(type);
        debugPrint('🔄 Loading sample: $path');
        final source = await SoLoud.instance.loadAsset(path);
        _sampleSources[key] = source;
        debugPrint('✅ Loaded sample: $path');
      } catch (e) {
        debugPrint('⚠️ Sample not found: ${pack.getAssetPath(type)} - will use synth fallback');
      }
    }
  }

  void playBeat(BeatType type) {
    if (type == BeatType.rest || !_isInitialized) {
      debugPrint('⚠️ playBeat skipped: rest=${ type == BeatType.rest}, init=$_isInitialized');
      return;
    }

    if (_currentPack.isSynthesis) {
      _playSynthBeat(type);
    } else {
      _playSampleBeat(type);
    }
  }

  /// 播放合成音
  void _playSynthBeat(BeatType type) {
    final typeStr = switch (type) {
      BeatType.strong => 'strong',
      BeatType.subAccent => 'subaccent',
      BeatType.weak => 'weak',
      BeatType.rest => '',
    };

    final key = '${_currentPack.folderName}_$typeStr';
    final source = _synthSources[key];

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
        debugPrint('❌ Play synth error: $e');
      }
    } else {
      debugPrint('⚠️ Synth source not found: $key');
    }
  }

  /// 播放采样音
  void _playSampleBeat(BeatType type) {
    final typeStr = switch (type) {
      BeatType.strong => 'strong',
      BeatType.subAccent => 'subaccent',
      BeatType.weak => 'weak',
      BeatType.rest => '',
    };

    final key = '${_currentPack.folderName}_$typeStr';
    final source = _sampleSources[key];

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
        debugPrint('❌ Play sample error: $e');
        _playSynthFallback(type);
      }
    } else {
      // 采样未加载，使用合成音作为后备
      _playSynthFallback(type);
    }
  }

  /// 后备合成音（当采样不可用时）
  void _playSynthFallback(BeatType type) {
    final typeStr = switch (type) {
      BeatType.strong => 'strong',
      BeatType.subAccent => 'subaccent',
      BeatType.weak => 'weak',
      BeatType.rest => '',
    };

    // 使用 digital 音色作为后备
    final key = 'digital_$typeStr';
    final source = _synthSources[key];

    if (source != null) {
      final volume = switch (type) {
        BeatType.strong => 0.7,
        BeatType.subAccent => 0.5,
        BeatType.weak => 0.35,
        BeatType.rest => 0.0,
      };
      try {
        SoLoud.instance.play(source, volume: volume);
      } catch (e) {
        debugPrint('❌ Play fallback error: $e');
      }
    }
  }

  /// 播放木鱼声音
  void playWoodenFish() {
    if (!_isInitialized || _woodenFishSource == null) return;
    try {
      SoLoud.instance.play(_woodenFishSource!, volume: 0.7);
    } catch (e) {
      debugPrint('❌ Play wooden fish error: $e');
    }
  }

  void dispose() {
    // 清理合成音源
    for (final source in _synthSources.values) {
      try {
        SoLoud.instance.disposeSource(source);
      } catch (_) {}
    }
    _synthSources.clear();

    // 清理采样音源
    for (final source in _sampleSources.values) {
      try {
        SoLoud.instance.disposeSource(source);
      } catch (_) {}
    }
    _sampleSources.clear();

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

/// 合成音配置
class _SynthConfig {
  final WaveForm strongWave;
  final double strongScale;
  final WaveForm weakWave;
  final double weakScale;
  final WaveForm subAccentWave;
  final double subAccentScale;

  const _SynthConfig({
    required this.strongWave,
    required this.strongScale,
    required this.weakWave,
    required this.weakScale,
    required this.subAccentWave,
    required this.subAccentScale,
  });
}
