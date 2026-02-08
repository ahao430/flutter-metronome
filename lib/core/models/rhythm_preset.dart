import 'beat_type.dart';

/// 预设节奏型
class RhythmPreset {
  final String id;
  final String name;
  final String category;
  final int beatsPerBar;
  final int subdivisionPerBeat;
  final List<BeatType> pattern;
  final double swingRatio; // 0.5 = 直拍, 0.67 = 轻摇摆, 0.75 = 重摇摆

  const RhythmPreset({
    required this.id,
    required this.name,
    required this.category,
    required this.beatsPerBar,
    required this.subdivisionPerBeat,
    required this.pattern,
    this.swingRatio = 0.5,
  });

  /// 总步数
  int get totalSteps => pattern.length;

  /// 所有预设节奏型
  static const List<RhythmPreset> presets = [
    // ===== 基础 =====
    RhythmPreset(
      id: 'basic_1',
      name: '1拍',
      category: '基础',
      beatsPerBar: 1,
      subdivisionPerBeat: 1,
      pattern: [BeatType.strong],
    ),
    RhythmPreset(
      id: 'basic_2',
      name: '2拍',
      category: '基础',
      beatsPerBar: 2,
      subdivisionPerBeat: 1,
      pattern: [BeatType.strong, BeatType.weak],
    ),
    RhythmPreset(
      id: 'basic_3',
      name: '3拍',
      category: '基础',
      beatsPerBar: 3,
      subdivisionPerBeat: 1,
      pattern: [BeatType.strong, BeatType.weak, BeatType.weak],
    ),
    RhythmPreset(
      id: 'basic_4',
      name: '4拍',
      category: '基础',
      beatsPerBar: 4,
      subdivisionPerBeat: 1,
      pattern: [BeatType.strong, BeatType.weak, BeatType.subAccent, BeatType.weak],
    ),

    // ===== 八分音符 =====
    RhythmPreset(
      id: 'eighth_1beat',
      name: '1拍2下',
      category: '八分',
      beatsPerBar: 1,
      subdivisionPerBeat: 2,
      pattern: [BeatType.strong, BeatType.weak],
    ),
    RhythmPreset(
      id: 'eighth_2beat',
      name: '2拍2下',
      category: '八分',
      beatsPerBar: 2,
      subdivisionPerBeat: 2,
      pattern: [
        BeatType.strong, BeatType.weak,
        BeatType.subAccent, BeatType.weak,
      ],
    ),
    RhythmPreset(
      id: 'eighth_swing',
      name: 'Swing',
      category: '八分',
      beatsPerBar: 1,
      subdivisionPerBeat: 2,
      pattern: [BeatType.strong, BeatType.weak],
      swingRatio: 0.67, // 2:1 比例
    ),
    RhythmPreset(
      id: 'eighth_heavy_swing',
      name: '重Swing',
      category: '八分',
      beatsPerBar: 1,
      subdivisionPerBeat: 2,
      pattern: [BeatType.strong, BeatType.weak],
      swingRatio: 0.75, // 3:1 比例
    ),

    // ===== 三连音 =====
    RhythmPreset(
      id: 'triplet_1beat',
      name: '1拍3下',
      category: '三连音',
      beatsPerBar: 1,
      subdivisionPerBeat: 3,
      pattern: [BeatType.strong, BeatType.weak, BeatType.weak],
    ),
    RhythmPreset(
      id: 'triplet_shuffle',
      name: 'Shuffle',
      category: '三连音',
      beatsPerBar: 1,
      subdivisionPerBeat: 3,
      pattern: [BeatType.strong, BeatType.rest, BeatType.weak],
    ),

    // ===== 十六分音符 =====
    RhythmPreset(
      id: '16th_1beat',
      name: '1拍4下',
      category: '16分',
      beatsPerBar: 1,
      subdivisionPerBeat: 4,
      pattern: [BeatType.strong, BeatType.weak, BeatType.weak, BeatType.weak],
    ),
    RhythmPreset(
      id: '16th_down_rest_down_up',
      name: '下空下上',
      category: '16分',
      beatsPerBar: 1,
      subdivisionPerBeat: 4,
      pattern: [BeatType.strong, BeatType.rest, BeatType.weak, BeatType.weak],
    ),
    RhythmPreset(
      id: '16th_down_up_rest_up',
      name: '下上空上',
      category: '16分',
      beatsPerBar: 1,
      subdivisionPerBeat: 4,
      pattern: [BeatType.strong, BeatType.weak, BeatType.rest, BeatType.weak],
    ),
    RhythmPreset(
      id: '16th_rest_up_down_up',
      name: '空上下上',
      category: '16分',
      beatsPerBar: 1,
      subdivisionPerBeat: 4,
      pattern: [BeatType.rest, BeatType.weak, BeatType.strong, BeatType.weak],
    ),

    // ===== 吉他扫弦 2拍组合 =====
    RhythmPreset(
      id: 'strum_2beat_basic',
      name: '下空下上 空上下上',
      category: '扫弦',
      beatsPerBar: 2,
      subdivisionPerBeat: 4,
      pattern: [
        BeatType.strong, BeatType.rest, BeatType.weak, BeatType.weak,  // 下空下上
        BeatType.rest, BeatType.weak, BeatType.subAccent, BeatType.weak,  // 空上下上
      ],
    ),
    RhythmPreset(
      id: 'strum_folk',
      name: '民谣扫弦',
      category: '扫弦',
      beatsPerBar: 2,
      subdivisionPerBeat: 4,
      pattern: [
        BeatType.strong, BeatType.rest, BeatType.weak, BeatType.weak,
        BeatType.subAccent, BeatType.rest, BeatType.weak, BeatType.weak,
      ],
    ),
    RhythmPreset(
      id: 'strum_pop',
      name: '流行扫弦',
      category: '扫弦',
      beatsPerBar: 4,
      subdivisionPerBeat: 2,
      pattern: [
        BeatType.strong, BeatType.rest,
        BeatType.rest, BeatType.weak,
        BeatType.subAccent, BeatType.rest,
        BeatType.rest, BeatType.weak,
      ],
    ),

    // ===== Funk/律动 =====
    RhythmPreset(
      id: 'funk_basic',
      name: 'Funk基础',
      category: 'Funk',
      beatsPerBar: 1,
      subdivisionPerBeat: 4,
      pattern: [BeatType.strong, BeatType.rest, BeatType.weak, BeatType.rest],
    ),
    RhythmPreset(
      id: 'funk_syncopated',
      name: 'Funk切分',
      category: 'Funk',
      beatsPerBar: 2,
      subdivisionPerBeat: 4,
      pattern: [
        BeatType.strong, BeatType.rest, BeatType.rest, BeatType.weak,
        BeatType.rest, BeatType.weak, BeatType.subAccent, BeatType.rest,
      ],
    ),

    // ===== 拉丁 =====
    RhythmPreset(
      id: 'clave_32',
      name: 'Clave 3-2',
      category: '拉丁',
      beatsPerBar: 2,
      subdivisionPerBeat: 4,
      pattern: [
        BeatType.strong, BeatType.rest, BeatType.rest, BeatType.weak,
        BeatType.rest, BeatType.rest, BeatType.subAccent, BeatType.rest,
      ],
    ),
    RhythmPreset(
      id: 'bossa',
      name: 'Bossa Nova',
      category: '拉丁',
      beatsPerBar: 2,
      subdivisionPerBeat: 4,
      pattern: [
        BeatType.strong, BeatType.rest, BeatType.weak, BeatType.rest,
        BeatType.rest, BeatType.weak, BeatType.subAccent, BeatType.weak,
      ],
    ),
  ];

  /// 按分类分组
  static Map<String, List<RhythmPreset>> get groupedPresets {
    final map = <String, List<RhythmPreset>>{};
    for (final preset in presets) {
      map.putIfAbsent(preset.category, () => []).add(preset);
    }
    return map;
  }
}
