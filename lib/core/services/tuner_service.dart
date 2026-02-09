import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:pitch_detector_dart/pitch_detector.dart';

/// 音高检测结果
class PitchResult {
  final double frequency;  // 检测到的频率 (Hz)
  final String noteName;   // 音符名称 (如 "A4")
  final double cents;      // 偏差 (音分, -50 到 +50)
  final double confidence; // 置信度 (0-1)

  const PitchResult({
    required this.frequency,
    required this.noteName,
    required this.cents,
    required this.confidence,
  });

  /// 是否准确 (偏差在 ±5 音分内)
  bool get isInTune => cents.abs() < 5;

  /// 无信号
  static const noSignal = PitchResult(
    frequency: 0,
    noteName: '--',
    cents: 0,
    confidence: 0,
  );
}

/// 调音器服务 - 处理音频采集和音高检测
class TunerService {
  static const int sampleRate = 44100;
  static const int bufferSize = 4096;

  final AudioRecorder _recorder = AudioRecorder();
  final PitchDetector _pitchDetector = PitchDetector(
    audioSampleRate: sampleRate.toDouble(),
    bufferSize: bufferSize,
  );

  StreamSubscription<Uint8List>? _audioSubscription;
  final _pitchController = StreamController<PitchResult>.broadcast();

  bool _isListening = false;
  bool _hasPermission = false;

  /// 音高检测结果流
  Stream<PitchResult> get pitchStream => _pitchController.stream;

  /// 是否正在监听
  bool get isListening => _isListening;

  /// 是否有麦克风权限
  bool get hasPermission => _hasPermission;

  /// 音符名称列表
  static const List<String> _noteNames = [
    'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'
  ];

  /// 是否支持当前平台
  bool get isSupported => !kIsWeb;

  /// 请求麦克风权限
  Future<bool> requestPermission() async {
    if (kIsWeb) {
      debugPrint('⚠️ Tuner not supported on web');
      return false;
    }
    final status = await Permission.microphone.request();
    _hasPermission = status.isGranted;
    return _hasPermission;
  }

  /// 检查权限状态
  Future<bool> checkPermission() async {
    if (kIsWeb) return false;
    final status = await Permission.microphone.status;
    _hasPermission = status.isGranted;
    return _hasPermission;
  }

  /// 开始监听
  Future<bool> startListening() async {
    if (kIsWeb) {
      debugPrint('⚠️ Tuner not supported on web');
      return false;
    }
    if (_isListening) return true;

    // 检查权限
    if (!_hasPermission) {
      final granted = await requestPermission();
      if (!granted) {
        debugPrint('❌ Microphone permission denied');
        return false;
      }
    }

    try {
      // 检查录音支持
      if (!await _recorder.hasPermission()) {
        debugPrint('❌ Recorder has no permission');
        return false;
      }

      // 开始录音流
      final stream = await _recorder.startStream(
        RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: sampleRate,
          numChannels: 1,
          autoGain: true,
          echoCancel: false,
          noiseSuppress: false,
        ),
      );

      _audioSubscription = stream.listen(_processAudioData);
      _isListening = true;
      debugPrint('✅ Tuner started listening');
      return true;
    } catch (e) {
      debugPrint('❌ Failed to start listening: $e');
      return false;
    }
  }

  /// 停止监听
  Future<void> stopListening() async {
    if (!_isListening) return;

    await _audioSubscription?.cancel();
    _audioSubscription = null;
    await _recorder.stop();
    _isListening = false;
    _pitchController.add(PitchResult.noSignal);
    debugPrint('✅ Tuner stopped listening');
  }

  /// 处理音频数据
  Future<void> _processAudioData(Uint8List data) async {
    if (data.isEmpty) return;

    try {
      // 使用 getPitchFromIntBuffer 直接处理 PCM16 数据
      final result = await _pitchDetector.getPitchFromIntBuffer(data);

      if (result.pitched && result.pitch > 0) {
        // 有效的音高检测
        final frequency = result.pitch;
        final (noteName, cents) = _frequencyToNote(frequency);

        _pitchController.add(PitchResult(
          frequency: frequency,
          noteName: noteName,
          cents: cents,
          confidence: result.probability,
        ));
      } else {
        // 无有效音高
        _pitchController.add(PitchResult.noSignal);
      }
    } catch (e) {
      debugPrint('⚠️ Pitch detection error: $e');
    }
  }

  /// 频率转换为音符名称和偏差
  (String, double) _frequencyToNote(double frequency) {
    if (frequency <= 0) return ('--', 0);

    // A4 = 440 Hz
    const a4Freq = 440.0;
    const a4Index = 9; // A 在 _noteNames 中的索引

    // 计算相对于 A4 的半音数
    final semitones = 12 * _log2(frequency / a4Freq);
    final roundedSemitones = semitones.round();

    // 计算音符索引和八度
    final noteIndex = ((a4Index + roundedSemitones) % 12 + 12) % 12;
    final octave = 4 + ((a4Index + roundedSemitones) ~/ 12);

    // 计算音分偏差 (1 半音 = 100 音分)
    final cents = (semitones - roundedSemitones) * 100;

    return ('${_noteNames[noteIndex]}$octave', cents);
  }

  /// log2 计算
  static double _log2(double x) => log(x) / ln10 * 3.321928094887362;

  /// 释放资源
  Future<void> dispose() async {
    await stopListening();
    await _pitchController.close();
    _recorder.dispose();
  }
}
