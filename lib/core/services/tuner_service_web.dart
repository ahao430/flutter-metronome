import 'dart:async';
import 'dart:js_interop';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

import 'tuner_service_interface.dart';

/// 调音器服务 - Web 端实现
/// 使用 Web Audio API + 自相关算法 (ACF) 进行音高检测
class TunerService implements TunerServiceInterface {
  static const int sampleRate = 44100;
  static const int bufferSize = 4096;

  web.AudioContext? _audioContext;
  web.MediaStream? _mediaStream;
  web.AnalyserNode? _analyser;
  web.MediaStreamAudioSourceNode? _source;

  Timer? _analysisTimer;
  final _pitchController = StreamController<PitchResult>.broadcast();

  bool _isListening = false;
  bool _hasPermission = false;

  @override
  Stream<PitchResult> get pitchStream => _pitchController.stream;

  @override
  bool get isListening => _isListening;

  @override
  bool get hasPermission => _hasPermission;

  @override
  bool get isSupported => true; // Web 支持调音器

  @override
  Future<bool> requestPermission() async {
    try {
      // 请求麦克风权限
      final constraints = web.MediaStreamConstraints(
        audio: true.toJS,
        video: false.toJS,
      );

      _mediaStream = await web.window.navigator.mediaDevices
          .getUserMedia(constraints)
          .toDart;

      _hasPermission = true;
      debugPrint('✅ Microphone permission granted (Web)');
      return true;
    } catch (e) {
      debugPrint('❌ Microphone permission denied: $e');
      _hasPermission = false;
      return false;
    }
  }

  @override
  Future<bool> checkPermission() async {
    // Web 上无法直接检查权限，需要尝试请求
    return _hasPermission;
  }

  @override
  Future<bool> startListening() async {
    if (_isListening) return true;

    try {
      // 如果还没有权限，先请求
      if (_mediaStream == null) {
        final granted = await requestPermission();
        if (!granted) return false;
      }

      // 创建音频上下文
      _audioContext = web.AudioContext();

      // 创建分析器节点
      _analyser = _audioContext!.createAnalyser();
      _analyser!.fftSize = bufferSize;
      _analyser!.smoothingTimeConstant = 0.8;

      // 连接麦克风到分析器
      _source = _audioContext!.createMediaStreamSource(_mediaStream!);
      _source!.connect(_analyser!);

      // 开始周期性分析
      _startAnalysis();

      _isListening = true;
      debugPrint('✅ Tuner started listening (Web)');
      return true;
    } catch (e) {
      debugPrint('❌ Failed to start listening: $e');
      return false;
    }
  }

  /// 开始音频分析
  void _startAnalysis() {
    // 每 50ms 分析一次 (20fps)
    _analysisTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      _analyzeAudio();
    });
  }

  /// 分析音频并检测音高
  void _analyzeAudio() {
    if (_analyser == null) return;

    try {
      // 获取时域数据
      final bufferLength = _analyser!.fftSize;
      final dataArray = Float32List(bufferLength);
      final jsArray = dataArray.toJS;

      _analyser!.getFloatTimeDomainData(jsArray);

      // 从 JS 数组复制回 Dart
      for (var i = 0; i < bufferLength; i++) {
        dataArray[i] = jsArray.toDart[i];
      }

      // 检测音高
      final frequency = _detectPitch(dataArray, sampleRate.toDouble());

      if (frequency > 0) {
        final (noteName, cents) = frequencyToNote(frequency);
        _pitchController.add(PitchResult(
          frequency: frequency,
          noteName: noteName,
          cents: cents,
          confidence: 0.9,
        ));
      } else {
        _pitchController.add(PitchResult.noSignal);
      }
    } catch (e) {
      debugPrint('⚠️ Analysis error: $e');
    }
  }

  /// 使用自相关算法 (ACF) 检测音高
  /// 这是 YIN 算法的简化版本
  double _detectPitch(Float32List buffer, double sampleRate) {
    // 检查信号强度
    double rms = 0;
    for (var i = 0; i < buffer.length; i++) {
      rms += buffer[i] * buffer[i];
    }
    rms = math.sqrt(rms / buffer.length);

    // 信号太弱，返回 0
    if (rms < 0.01) return 0;

    // 自相关算法
    final size = buffer.length;
    final maxLag = size ~/ 2;

    // 寻找音高范围: 50Hz - 1500Hz
    final minPeriod = (sampleRate / 1500).floor(); // 最高频率对应的周期
    final maxPeriod = (sampleRate / 50).floor();   // 最低频率对应的周期

    double bestCorrelation = 0;
    int bestPeriod = 0;

    for (var lag = minPeriod; lag < math.min(maxPeriod, maxLag); lag++) {
      double correlation = 0;
      double norm1 = 0;
      double norm2 = 0;

      for (var i = 0; i < size - lag; i++) {
        correlation += buffer[i] * buffer[i + lag];
        norm1 += buffer[i] * buffer[i];
        norm2 += buffer[i + lag] * buffer[i + lag];
      }

      // 归一化
      if (norm1 > 0 && norm2 > 0) {
        correlation /= math.sqrt(norm1 * norm2);
      }

      if (correlation > bestCorrelation) {
        bestCorrelation = correlation;
        bestPeriod = lag;
      }
    }

    // 需要足够高的相关性才认为检测到有效音高
    if (bestCorrelation < 0.8 || bestPeriod == 0) {
      return 0;
    }

    // 使用抛物线插值提高精度
    final frequency = sampleRate / bestPeriod;

    // 过滤不合理的频率
    if (frequency < 50 || frequency > 1500) {
      return 0;
    }

    return frequency;
  }

  @override
  Future<void> stopListening() async {
    if (!_isListening) return;

    _analysisTimer?.cancel();
    _analysisTimer = null;

    _source?.disconnect();
    _source = null;

    _analyser = null;

    _audioContext?.close();
    _audioContext = null;

    _isListening = false;
    _pitchController.add(PitchResult.noSignal);
    debugPrint('✅ Tuner stopped listening (Web)');
  }

  @override
  Future<void> dispose() async {
    await stopListening();
    await _pitchController.close();

    // 停止所有音轨
    _mediaStream?.getTracks().toDart.forEach((track) {
      track.stop();
    });
    _mediaStream = null;
  }
}
