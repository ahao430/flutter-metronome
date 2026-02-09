import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:pitch_detector_dart/pitch_detector.dart';

import 'tuner_service_interface.dart';

/// 调音器服务 - 移动端实现
/// 使用 record + pitch_detector_dart
class TunerService implements TunerServiceInterface {
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

  @override
  Stream<PitchResult> get pitchStream => _pitchController.stream;

  @override
  bool get isListening => _isListening;

  @override
  bool get hasPermission => _hasPermission;

  @override
  bool get isSupported => true;

  @override
  Future<bool> requestPermission() async {
    final status = await Permission.microphone.request();
    _hasPermission = status.isGranted;
    return _hasPermission;
  }

  @override
  Future<bool> checkPermission() async {
    final status = await Permission.microphone.status;
    _hasPermission = status.isGranted;
    return _hasPermission;
  }

  @override
  Future<bool> startListening() async {
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
      debugPrint('✅ Tuner started listening (Mobile)');
      return true;
    } catch (e) {
      debugPrint('❌ Failed to start listening: $e');
      return false;
    }
  }

  @override
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
      final result = await _pitchDetector.getPitchFromIntBuffer(data);

      if (result.pitched && result.pitch > 0) {
        final frequency = result.pitch;
        final (noteName, cents) = frequencyToNote(frequency);

        _pitchController.add(PitchResult(
          frequency: frequency,
          noteName: noteName,
          cents: cents,
          confidence: result.probability,
        ));
      } else {
        _pitchController.add(PitchResult.noSignal);
      }
    } catch (e) {
      debugPrint('⚠️ Pitch detection error: $e');
    }
  }

  @override
  Future<void> dispose() async {
    await stopListening();
    await _pitchController.close();
    _recorder.dispose();
  }
}
