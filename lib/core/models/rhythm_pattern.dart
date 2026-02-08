import 'beat_type.dart';

/// 节奏型模型
class RhythmPattern {
  final String name;
  final int bpm;
  final List<BeatType> steps;
  final int timeSignature;

  const RhythmPattern({
    required this.name,
    required this.bpm,
    required this.steps,
    this.timeSignature = 4,
  });

  /// 默认 4/4 拍
  static RhythmPattern get defaultPattern => RhythmPattern(
        name: '4/4 Standard',
        bpm: 120,
        steps: [
          BeatType.strong,
          BeatType.weak,
          BeatType.weak,
          BeatType.weak,
        ],
      );

  /// 16 分音符网格的 4/4 拍
  static RhythmPattern get sixteenthNotePattern => RhythmPattern(
        name: '4/4 16th Notes',
        bpm: 120,
        steps: List.generate(16, (i) {
          if (i == 0) return BeatType.strong;
          if (i % 4 == 0) return BeatType.subAccent;
          return BeatType.weak;
        }),
      );

  RhythmPattern copyWith({
    String? name,
    int? bpm,
    List<BeatType>? steps,
    int? timeSignature,
  }) {
    return RhythmPattern(
      name: name ?? this.name,
      bpm: bpm ?? this.bpm,
      steps: steps ?? List.from(this.steps),
      timeSignature: timeSignature ?? this.timeSignature,
    );
  }
}
