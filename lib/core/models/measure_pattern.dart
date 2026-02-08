import 'beat_rhythm.dart';
import 'beat_type.dart';

/// 小节节奏配置 - 支持每拍独立设置不同的节奏型
class MeasurePattern {
  /// 小节ID
  final String id;

  /// 名称
  final String name;

  /// 分类
  final String category;

  /// 每小节拍数 (拍号的分子)
  final int beatsPerBar;

  /// 每拍的节奏型配置
  final List<BeatConfig> beats;

  /// Swing 比例 (0.5 = 直拍, 0.67 = 轻摇摆, 0.75 = 重摇摆)
  final double swingRatio;

  const MeasurePattern({
    required this.id,
    required this.name,
    this.category = '自定义',
    required this.beatsPerBar,
    required this.beats,
    this.swingRatio = 0.5,
  });

  /// 复制并修改
  MeasurePattern copyWith({
    String? id,
    String? name,
    String? category,
    int? beatsPerBar,
    List<BeatConfig>? beats,
    double? swingRatio,
  }) {
    return MeasurePattern(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      beatsPerBar: beatsPerBar ?? this.beatsPerBar,
      beats: beats ?? List.from(this.beats.map((b) => b.copyWith())),
      swingRatio: swingRatio ?? this.swingRatio,
    );
  }

  /// 修改某一拍的节奏型
  MeasurePattern withBeatRhythm(int beatIndex, BeatRhythm rhythm) {
    if (beatIndex < 0 || beatIndex >= beats.length) return this;
    final newBeats = List<BeatConfig>.from(beats);
    newBeats[beatIndex] = newBeats[beatIndex].copyWith(rhythm: rhythm);
    return copyWith(beats: newBeats);
  }

  /// 将所有拍统一设置为同一个节奏型
  MeasurePattern withUniformRhythm(BeatRhythm rhythm) {
    final newBeats = beats.map((b) => b.copyWith(rhythm: rhythm)).toList();
    return copyWith(beats: newBeats);
  }

  /// 计算整个小节的统一网格大小 (所有拍的原生网格大小的最小公倍数)
  int get unifiedGridSize {
    if (beats.isEmpty) return 4;
    final sizes = beats.map((b) => b.rhythm.nativeGridSize).toList();
    return lcmMultiple(sizes);
  }

  /// 生成播放步骤列表 (展开所有拍) - 用于实际播放
  List<PlayStep> generateSteps() {
    final steps = <PlayStep>[];

    for (int beatIdx = 0; beatIdx < beats.length; beatIdx++) {
      final beat = beats[beatIdx];
      final rhythm = beat.rhythm;
      final positions = rhythm.allPositions;

      for (int subIdx = 0; subIdx < positions.length; subIdx++) {
        // 确定音量类型
        BeatType beatType;
        if (!rhythm.shouldSound(subIdx)) {
          beatType = BeatType.rest;
        } else if (beatIdx == 0 && subIdx == 0) {
          beatType = BeatType.strong;
        } else if (subIdx == 0) {
          beatType = beat.accentFirst ? BeatType.subAccent : BeatType.weak;
        } else {
          beatType = BeatType.weak;
        }

        // 允许用户覆盖
        if (beat.customTypes != null && subIdx < beat.customTypes!.length) {
          beatType = beat.customTypes![subIdx];
        }

        steps.add(PlayStep(
          beatIndex: beatIdx,
          subIndex: subIdx,
          position: positions[subIdx],
          duration: rhythm.durations[subIdx],
          beatType: beatType,
          isFirstOfBeat: subIdx == 0,
        ));
      }
    }

    return steps;
  }

  /// 生成统一网格步骤列表 - 用于 UI 显示
  /// 所有拍都按照统一的网格大小 (LCM) 显示
  List<GridStep> generateGridSteps() {
    final steps = <GridStep>[];
    final gridSize = unifiedGridSize;

    for (int beatIdx = 0; beatIdx < beats.length; beatIdx++) {
      final beat = beats[beatIdx];
      final rhythm = beat.rhythm;

      // 将原生网格扩展到统一大小
      final expandedGrid = rhythm.expandGridTo(gridSize);

      for (int gridIdx = 0; gridIdx < gridSize; gridIdx++) {
        final hasSound = expandedGrid[gridIdx];

        // 确定音量类型
        BeatType beatType;
        if (!hasSound) {
          beatType = BeatType.rest;
        } else if (beatIdx == 0 && gridIdx == 0) {
          beatType = BeatType.strong;
        } else if (gridIdx == 0) {
          beatType = beat.accentFirst ? BeatType.subAccent : BeatType.weak;
        } else {
          beatType = BeatType.weak;
        }

        // 允许用户通过 customGridTypes 覆盖
        if (beat.customGridTypes != null && gridIdx < beat.customGridTypes!.length) {
          beatType = beat.customGridTypes![gridIdx];
        }

        steps.add(GridStep(
          beatIndex: beatIdx,
          gridIndex: gridIdx,
          beatType: beatType,
          isFirstOfBeat: gridIdx == 0,
        ));
      }
    }

    return steps;
  }

  /// 创建统一节奏的小节 (所有拍使用相同节奏型)
  static MeasurePattern uniform({
    required String id,
    required String name,
    String category = '基础',
    required int beatsPerBar,
    required BeatRhythm rhythm,
    double swingRatio = 0.5,
  }) {
    final beats = List.generate(
      beatsPerBar,
      (i) => BeatConfig(
        rhythm: rhythm,
        accentFirst: i == 0,
      ),
    );

    return MeasurePattern(
      id: id,
      name: name,
      category: category,
      beatsPerBar: beatsPerBar,
      beats: beats,
      swingRatio: swingRatio,
    );
  }

  /// 预设库
  static const List<MeasurePattern> presets = [
    // ===== 基础 =====
    _preset4_4Quarter,
    _preset3_4Quarter,
    _preset2_4Quarter,

    // ===== 八分 =====
    _preset4_4Eighths,
    _preset3_4Eighths,
    _preset4_4Swing,

    // ===== 三连音 =====
    _preset4_4Triplets,

    // ===== 十六分 =====
    _preset4_4Sixteenths,

    // ===== 混合节奏 =====
    _presetGallopBasic,
    _presetReverseGallop,
    _presetMarchGallop,
  ];

  // ====== 预设定义 ======

  static const _preset4_4Quarter = MeasurePattern(
    id: 'basic_4_4',
    name: '4/4 四分',
    category: '基础',
    beatsPerBar: 4,
    beats: [
      BeatConfig(rhythm: BeatRhythm.quarter, accentFirst: true),
      BeatConfig(rhythm: BeatRhythm.quarter),
      BeatConfig(rhythm: BeatRhythm.quarter, accentFirst: true), // 次强
      BeatConfig(rhythm: BeatRhythm.quarter),
    ],
  );

  static const _preset3_4Quarter = MeasurePattern(
    id: 'basic_3_4',
    name: '3/4 四分',
    category: '基础',
    beatsPerBar: 3,
    beats: [
      BeatConfig(rhythm: BeatRhythm.quarter, accentFirst: true),
      BeatConfig(rhythm: BeatRhythm.quarter),
      BeatConfig(rhythm: BeatRhythm.quarter),
    ],
  );

  static const _preset2_4Quarter = MeasurePattern(
    id: 'basic_2_4',
    name: '2/4 四分',
    category: '基础',
    beatsPerBar: 2,
    beats: [
      BeatConfig(rhythm: BeatRhythm.quarter, accentFirst: true),
      BeatConfig(rhythm: BeatRhythm.quarter),
    ],
  );

  static const _preset4_4Eighths = MeasurePattern(
    id: 'eighth_4_4',
    name: '4/4 八分',
    category: '八分',
    beatsPerBar: 4,
    beats: [
      BeatConfig(rhythm: BeatRhythm.eighths, accentFirst: true),
      BeatConfig(rhythm: BeatRhythm.eighths),
      BeatConfig(rhythm: BeatRhythm.eighths, accentFirst: true),
      BeatConfig(rhythm: BeatRhythm.eighths),
    ],
  );

  static const _preset3_4Eighths = MeasurePattern(
    id: 'eighth_3_4',
    name: '3/4 八分',
    category: '八分',
    beatsPerBar: 3,
    beats: [
      BeatConfig(rhythm: BeatRhythm.eighths, accentFirst: true),
      BeatConfig(rhythm: BeatRhythm.eighths),
      BeatConfig(rhythm: BeatRhythm.eighths),
    ],
  );

  static const _preset4_4Swing = MeasurePattern(
    id: 'swing_4_4',
    name: '4/4 Swing',
    category: '八分',
    beatsPerBar: 4,
    swingRatio: 0.67,
    beats: [
      BeatConfig(rhythm: BeatRhythm.swing, accentFirst: true),
      BeatConfig(rhythm: BeatRhythm.swing),
      BeatConfig(rhythm: BeatRhythm.swing, accentFirst: true),
      BeatConfig(rhythm: BeatRhythm.swing),
    ],
  );

  static const _preset4_4Triplets = MeasurePattern(
    id: 'triplet_4_4',
    name: '4/4 三连音',
    category: '三连音',
    beatsPerBar: 4,
    beats: [
      BeatConfig(rhythm: BeatRhythm.triplets, accentFirst: true),
      BeatConfig(rhythm: BeatRhythm.triplets),
      BeatConfig(rhythm: BeatRhythm.triplets, accentFirst: true),
      BeatConfig(rhythm: BeatRhythm.triplets),
    ],
  );

  static const _preset4_4Sixteenths = MeasurePattern(
    id: 'sixteenth_4_4',
    name: '4/4 十六分',
    category: '十六分',
    beatsPerBar: 4,
    beats: [
      BeatConfig(rhythm: BeatRhythm.sixteenths, accentFirst: true),
      BeatConfig(rhythm: BeatRhythm.sixteenths),
      BeatConfig(rhythm: BeatRhythm.sixteenths, accentFirst: true),
      BeatConfig(rhythm: BeatRhythm.sixteenths),
    ],
  );

  static const _presetGallopBasic = MeasurePattern(
    id: 'gallop_basic',
    name: '前八后十六',
    category: '混合',
    beatsPerBar: 4,
    beats: [
      BeatConfig(rhythm: BeatRhythm.gallop, accentFirst: true),
      BeatConfig(rhythm: BeatRhythm.gallop),
      BeatConfig(rhythm: BeatRhythm.gallop, accentFirst: true),
      BeatConfig(rhythm: BeatRhythm.gallop),
    ],
  );

  static const _presetReverseGallop = MeasurePattern(
    id: 'reverse_gallop',
    name: '前十六后八',
    category: '混合',
    beatsPerBar: 4,
    beats: [
      BeatConfig(rhythm: BeatRhythm.reverseGallop, accentFirst: true),
      BeatConfig(rhythm: BeatRhythm.reverseGallop),
      BeatConfig(rhythm: BeatRhythm.reverseGallop, accentFirst: true),
      BeatConfig(rhythm: BeatRhythm.reverseGallop),
    ],
  );

  static const _presetMarchGallop = MeasurePattern(
    id: 'march_gallop',
    name: '进行曲',
    category: '混合',
    beatsPerBar: 4,
    beats: [
      // 第1拍: 四分
      BeatConfig(rhythm: BeatRhythm.quarter, accentFirst: true),
      // 第2拍: 前八后十六
      BeatConfig(rhythm: BeatRhythm.gallop),
      // 第3拍: 四分
      BeatConfig(rhythm: BeatRhythm.quarter, accentFirst: true),
      // 第4拍: 前八后十六
      BeatConfig(rhythm: BeatRhythm.gallop),
    ],
  );

  /// 按分类分组
  static Map<String, List<MeasurePattern>> get groupedPresets {
    final map = <String, List<MeasurePattern>>{};
    for (final preset in presets) {
      map.putIfAbsent(preset.category, () => []).add(preset);
    }
    return map;
  }
}

/// 单拍配置
class BeatConfig {
  /// 这一拍的节奏型
  final BeatRhythm rhythm;

  /// 是否强调第一下 (用于产生次强拍效果)
  final bool accentFirst;

  /// 自定义每个细分的类型 (可选，覆盖默认逻辑) - 用于播放
  final List<BeatType>? customTypes;

  /// 自定义网格显示的类型 (可选) - 用于UI显示
  final List<BeatType>? customGridTypes;

  const BeatConfig({
    required this.rhythm,
    this.accentFirst = false,
    this.customTypes,
    this.customGridTypes,
  });

  BeatConfig copyWith({
    BeatRhythm? rhythm,
    bool? accentFirst,
    List<BeatType>? customTypes,
    List<BeatType>? customGridTypes,
  }) {
    return BeatConfig(
      rhythm: rhythm ?? this.rhythm,
      accentFirst: accentFirst ?? this.accentFirst,
      customTypes: customTypes ?? this.customTypes,
      customGridTypes: customGridTypes ?? this.customGridTypes,
    );
  }
}

/// 播放步骤 - 展开后的单个发声点 (用于播放)
class PlayStep {
  /// 所属拍号 (0-based)
  final int beatIndex;

  /// 拍内细分索引 (0-based)
  final int subIndex;

  /// 在拍内的位置 (0.0 ~ 1.0)
  final double position;

  /// 持续时长比例 (相对于一拍)
  final double duration;

  /// 发声类型
  final BeatType beatType;

  /// 是否是该拍的第一个音
  final bool isFirstOfBeat;

  const PlayStep({
    required this.beatIndex,
    required this.subIndex,
    required this.position,
    required this.duration,
    required this.beatType,
    required this.isFirstOfBeat,
  });
}

/// 网格步骤 - 统一网格显示用 (用于UI)
class GridStep {
  /// 所属拍号 (0-based)
  final int beatIndex;

  /// 网格索引 (0-3，每拍固定4格)
  final int gridIndex;

  /// 发声类型
  final BeatType beatType;

  /// 是否是该拍的第一格
  final bool isFirstOfBeat;

  const GridStep({
    required this.beatIndex,
    required this.gridIndex,
    required this.beatType,
    required this.isFirstOfBeat,
  });

  /// 全局索引 (在整个小节中的位置)
  int globalIndex(int beatsPerBar) => beatIndex * 4 + gridIndex;
}
