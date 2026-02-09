import 'dart:async';
import 'dart:math';

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

/// 调音器服务接口
abstract class TunerServiceInterface {
  /// 音高检测结果流
  Stream<PitchResult> get pitchStream;

  /// 是否正在监听
  bool get isListening;

  /// 是否有麦克风权限
  bool get hasPermission;

  /// 是否支持当前平台
  bool get isSupported;

  /// 请求麦克风权限
  Future<bool> requestPermission();

  /// 检查权限状态
  Future<bool> checkPermission();

  /// 开始监听
  Future<bool> startListening();

  /// 停止监听
  Future<void> stopListening();

  /// 释放资源
  Future<void> dispose();
}

/// 音符名称列表
const List<String> noteNames = [
  'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'
];

/// 频率转换为音符名称和偏差
(String, double) frequencyToNote(double frequency) {
  if (frequency <= 0) return ('--', 0);

  // A4 = 440 Hz
  const a4Freq = 440.0;
  const a4Index = 9; // A 在 noteNames 中的索引

  // 计算相对于 A4 的半音数
  final semitones = 12 * log2(frequency / a4Freq);
  final roundedSemitones = semitones.round();

  // 计算音符索引和八度
  final noteIndex = ((a4Index + roundedSemitones) % 12 + 12) % 12;
  final octave = 4 + ((a4Index + roundedSemitones) ~/ 12);

  // 计算音分偏差 (1 半音 = 100 音分)
  final cents = (semitones - roundedSemitones) * 100;

  return ('${noteNames[noteIndex]}$octave', cents);
}

/// log2 计算
double log2(double x) => log(x) / ln10 * 3.321928094887362;
