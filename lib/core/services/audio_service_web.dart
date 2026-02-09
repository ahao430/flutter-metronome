import 'dart:async';
import 'dart:js_interop';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:web/web.dart' as web;

import '../models/beat_type.dart';
import '../models/sound_pack.dart';

/// Web Audio 服务实现 - 使用 Web Audio API + 音频缓冲
/// 加载真实 WAV 文件到 AudioBuffer，每次播放创建新的 BufferSourceNode
class AudioService {
  bool _isInitialized = false;
  SoundPack _currentPack = SoundPack.click;

  web.AudioContext? _audioContext;

  // 预加载的音频缓冲 (key: "packName_beatType")
  final Map<String, web.AudioBuffer> _buffers = {};

  // 木鱼音频缓冲
  web.AudioBuffer? _woodenFishBuffer;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _audioContext = web.AudioContext();
      await _loadAllSounds();
      _isInitialized = true;
      debugPrint('✅ AudioService initialized (Web Audio API with samples)');
    } catch (e) {
      debugPrint('❌ AudioService init failed: $e');
      _isInitialized = false;
    }
  }

  /// 预加载所有采样音色到 AudioBuffer
  Future<void> _loadAllSounds() async {
    final beatTypes = ['strong', 'weak', 'subaccent'];

    for (final pack in SoundPack.values) {
      for (final type in beatTypes) {
        final key = '${pack.folderName}_$type';
        try {
          final buffer = await _loadAudioBuffer('assets/audio/samples/${pack.folderName}_$type.wav');
          if (buffer != null) {
            _buffers[key] = buffer;
            debugPrint('✅ Loaded: $key');
          }
        } catch (e) {
          debugPrint('⚠️ Failed to load $key: $e');
        }
      }
    }

    // 加载木鱼音效
    try {
      _woodenFishBuffer = await _loadAudioBuffer('assets/audio/synth/woodenfish.wav');
      debugPrint('✅ Loaded wooden fish sound');
    } catch (e) {
      debugPrint('⚠️ Failed to load wooden fish: $e');
    }

    debugPrint('✅ Loaded ${_buffers.length} sounds total');
  }

  /// 加载音频文件到 AudioBuffer
  Future<web.AudioBuffer?> _loadAudioBuffer(String assetPath) async {
    final ctx = _audioContext;
    if (ctx == null) return null;

    try {
      // 从 Flutter assets 加载文件
      final byteData = await rootBundle.load(assetPath);
      final uint8List = byteData.buffer.asUint8List();

      // 转换为 JS ArrayBuffer
      final jsArrayBuffer = uint8List.buffer.toJS;

      // 解码为 AudioBuffer
      final audioBuffer = await ctx.decodeAudioData(jsArrayBuffer).toDart;
      return audioBuffer;
    } catch (e) {
      debugPrint('⚠️ Failed to decode audio: $assetPath - $e');
      return null;
    }
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
    final buffer = _buffers[key];

    if (buffer != null) {
      final volume = switch (type) {
        BeatType.strong => 1.0,
        BeatType.subAccent => 0.8,
        BeatType.weak => 0.6,
        BeatType.rest => 0.0,
      };
      _playBuffer(buffer, volume);
    } else {
      _playFallback(type);
    }
  }

  /// 播放 AudioBuffer - 每次创建新的 BufferSourceNode
  void _playBuffer(web.AudioBuffer buffer, double volume) {
    final ctx = _audioContext;
    if (ctx == null) return;

    try {
      // 创建新的 BufferSourceNode（一次性使用）
      final source = ctx.createBufferSource();
      source.buffer = buffer;

      // 创建增益节点控制音量
      final gainNode = ctx.createGain();
      gainNode.gain.value = volume;

      // 连接: source -> gain -> destination
      source.connect(gainNode);
      gainNode.connect(ctx.destination);

      // 立即播放
      source.start();
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
    final buffer = _buffers[key];

    if (buffer != null) {
      final volume = switch (type) {
        BeatType.strong => 0.9,
        BeatType.subAccent => 0.7,
        BeatType.weak => 0.5,
        BeatType.rest => 0.0,
      };
      _playBuffer(buffer, volume);
    }
  }

  /// 播放木鱼声音
  void playWoodenFish() {
    if (!_isInitialized || _woodenFishBuffer == null) return;
    _playBuffer(_woodenFishBuffer!, 0.8);
  }

  void dispose() {
    _buffers.clear();
    _woodenFishBuffer = null;
    _audioContext?.close();
    _audioContext = null;
    _isInitialized = false;
  }
}
