import 'dart:async';
import '../../../core/models/beat_type.dart';
import '../../../core/models/beat_rhythm.dart';
import '../../../core/models/measure_pattern.dart';
import '../../../core/models/rhythm_preset.dart';
import '../../../core/services/audio_service.dart';

/// 节拍器引擎 - 支持混合节奏型（每拍独立设置）
class MetronomeEngine {
  final AudioService _audioService;
  Timer? _timer;

  bool _isPlaying = false;
  int _bpm = 120;
  int _currentStepIndex = 0;

  // 当前节奏配置 (新架构)
  MeasurePattern _measurePattern = MeasurePattern.presets.first;
  List<PlayStep> _steps = [];       // 用于播放
  List<GridStep> _gridSteps = [];   // 用于UI显示

  // 向后兼容：旧的预设系统
  RhythmPreset? _legacyPreset;

  final StreamController<int> _currentStepController =
      StreamController<int>.broadcast();

  MetronomeEngine(this._audioService) {
    _regenerateSteps();
  }

  // ====== Getters ======

  bool get isPlaying => _isPlaying;
  int get bpm => _bpm;
  int get currentStepIndex => _currentStepIndex;
  int get beatsPerBar => _measurePattern.beatsPerBar;
  double get swingRatio => _measurePattern.swingRatio;
  Stream<int> get onStepChanged => _currentStepController.stream;
  RhythmPreset? get currentPreset => _legacyPreset;
  MeasurePattern get measurePattern => _measurePattern;
  List<PlayStep> get steps => List.unmodifiable(_steps);
  List<GridStep> get gridSteps => List.unmodifiable(_gridSteps);
  int get totalSteps => _steps.length;
  int get totalGridSteps => _gridSteps.length;

  /// 获取展开后的 pattern (用于显示网格)
  List<BeatType> get pattern => _gridSteps.map((s) => s.beatType).toList();

  /// 获取每拍的统一网格数
  int get gridSizePerBeat => _measurePattern.unifiedGridSize;

  // ====== Setters ======

  set bpm(int value) {
    _bpm = value.clamp(10, 600);
  }

  /// 设置 Swing 比例
  void setSwingRatio(double ratio) {
    final clamped = ratio.clamp(0.5, 0.75);
    _measurePattern = _measurePattern.copyWith(swingRatio: clamped);
  }

  // ====== 新的 MeasurePattern API ======

  /// 应用小节节奏配置
  void applyMeasurePattern(MeasurePattern pattern) {
    _measurePattern = pattern;
    _legacyPreset = null;
    _regenerateSteps();
    _currentStepIndex = 0;
  }

  /// 修改某一拍的节奏型
  void setBeatRhythm(int beatIndex, BeatRhythm rhythm) {
    _measurePattern = _measurePattern.withBeatRhythm(beatIndex, rhythm);
    _legacyPreset = null;
    _regenerateSteps();
  }

  /// 将所有拍统一设置为同一节奏型
  void setUniformRhythm(BeatRhythm rhythm) {
    _measurePattern = _measurePattern.withUniformRhythm(rhythm);
    _legacyPreset = null;
    _regenerateSteps();
  }

  /// 设置拍号
  void setTimeSignature(int beatsPerBar) {
    final currentRhythm = _measurePattern.beats.isNotEmpty
        ? _measurePattern.beats.first.rhythm
        : BeatRhythm.quarter;

    _measurePattern = MeasurePattern.uniform(
      id: 'custom_${beatsPerBar}_4',
      name: '$beatsPerBar/4',
      beatsPerBar: beatsPerBar,
      rhythm: currentRhythm,
      swingRatio: _measurePattern.swingRatio,
    );
    _legacyPreset = null;
    _regenerateSteps();
    _currentStepIndex = 0;
  }

  /// 重新生成播放步骤和网格步骤
  void _regenerateSteps() {
    _steps = _measurePattern.generateSteps();
    _gridSteps = _measurePattern.generateGridSteps();
  }

  // ====== 向后兼容：旧的 RhythmPreset API ======

  /// 应用旧的预设节奏型 (向后兼容)
  void applyPreset(RhythmPreset preset) {
    _legacyPreset = preset;

    // 转换为新的 MeasurePattern
    final rhythm = _subdivisionToRhythm(preset.subdivisionPerBeat);
    final beats = List.generate(
      preset.beatsPerBar,
      (i) => BeatConfig(
        rhythm: rhythm,
        accentFirst: i == 0 || (preset.beatsPerBar == 4 && i == 2),
        customTypes: _extractBeatTypes(preset.pattern, i, preset.subdivisionPerBeat),
      ),
    );

    _measurePattern = MeasurePattern(
      id: 'legacy_${preset.id}',
      name: preset.name,
      category: preset.category,
      beatsPerBar: preset.beatsPerBar,
      beats: beats,
      swingRatio: preset.swingRatio,
    );

    _regenerateSteps();
    _currentStepIndex = 0;
  }

  BeatRhythm _subdivisionToRhythm(int subdivision) {
    return switch (subdivision) {
      1 => BeatRhythm.quarter,
      2 => BeatRhythm.eighths,
      3 => BeatRhythm.triplets,
      4 => BeatRhythm.sixteenths,
      _ => BeatRhythm.quarter,
    };
  }

  List<BeatType>? _extractBeatTypes(List<BeatType> pattern, int beatIndex, int subdivision) {
    final start = beatIndex * subdivision;
    final end = start + subdivision;
    if (end > pattern.length) return null;
    return pattern.sublist(start, end);
  }

  // ====== 播放控制 ======

  /// 计算当前网格步的时长
  Duration _calculateGridStepDuration(int gridStepIndex) {
    if (gridStepIndex >= _gridSteps.length) return const Duration(milliseconds: 500);

    final gridStep = _gridSteps[gridStepIndex];
    final quarterNoteMs = 60000.0 / _bpm;
    final gridSize = _measurePattern.unifiedGridSize;

    // 每拍 gridSize 格，每格时长 = 一拍时长 / gridSize
    final gridStepMs = quarterNoteMs / gridSize;

    // 如果是 Swing，需要特殊处理
    if (_measurePattern.swingRatio != 0.5) {
      final beatConfig = _measurePattern.beats[gridStep.beatIndex];
      if (beatConfig.rhythm == BeatRhythm.swing) {
        // Swing 是 3 格，按 2:1 比例分配时间
        // 第1格占 swingRatio，第2格(空)占剩余的一半，第3格占剩余的一半
        final beatDuration = quarterNoteMs;
        if (gridStep.gridIndex == 0) {
          return Duration(microseconds: (beatDuration * _measurePattern.swingRatio * 1000).round());
        } else {
          // 后两格平分剩余时间
          return Duration(microseconds: (beatDuration * (1 - _measurePattern.swingRatio) / 2 * 1000).round());
        }
      }
    }

    return Duration(microseconds: (gridStepMs * 1000).round());
  }

  void _tick() {
    if (!_isPlaying) return;
    if (_gridSteps.isEmpty) return;

    final gridStep = _gridSteps[_currentStepIndex];
    _currentStepController.add(_currentStepIndex);

    // 只有非休止符才发声
    if (gridStep.beatType != BeatType.rest) {
      _audioService.playBeat(gridStep.beatType);
    }

    final currentIdx = _currentStepIndex;
    _currentStepIndex = (_currentStepIndex + 1) % _gridSteps.length;
    _timer = Timer(_calculateGridStepDuration(currentIdx), _tick);
  }

  void start() {
    if (_isPlaying) return;
    _isPlaying = true;
    _currentStepIndex = 0;
    _tick();
  }

  void stop() {
    _isPlaying = false;
    _timer?.cancel();
    _timer = null;
    _currentStepIndex = 0;
    _currentStepController.add(-1);
  }

  void toggle() {
    if (_isPlaying) {
      stop();
    } else {
      start();
    }
  }

  /// 切换指定位置的节拍类型 (用于网格编辑)
  void toggleBeatAt(int index) {
    if (index < 0 || index >= _gridSteps.length) return;

    final gridStep = _gridSteps[index];
    final beatConfig = _measurePattern.beats[gridStep.beatIndex];
    final gridSize = _measurePattern.unifiedGridSize;

    // 获取或创建 customGridTypes
    final currentTypes = beatConfig.customGridTypes ?? List<BeatType>.generate(
      gridSize,
      (i) => _gridSteps.firstWhere(
        (s) => s.beatIndex == gridStep.beatIndex && s.gridIndex == i,
      ).beatType,
    );

    // 循环切换
    final current = currentTypes[gridStep.gridIndex];
    final next = switch (current) {
      BeatType.rest => BeatType.weak,
      BeatType.weak => BeatType.strong,
      BeatType.strong => BeatType.subAccent,
      BeatType.subAccent => BeatType.rest,
    };

    final newTypes = List<BeatType>.from(currentTypes);
    newTypes[gridStep.gridIndex] = next;

    // 更新配置
    final newBeats = List<BeatConfig>.from(_measurePattern.beats);
    newBeats[gridStep.beatIndex] = beatConfig.copyWith(customGridTypes: newTypes);
    _measurePattern = _measurePattern.copyWith(beats: newBeats);

    _regenerateSteps();
    _legacyPreset = null;
  }

  /// 获取当前步所在的拍号 (0-based)
  int getBeatIndexForStep(int stepIndex) {
    if (stepIndex < 0 || stepIndex >= _gridSteps.length) return 0;
    return _gridSteps[stepIndex].beatIndex;
  }

  /// 判断是否是某拍的第一下
  bool isFirstOfBeat(int stepIndex) {
    if (stepIndex < 0 || stepIndex >= _gridSteps.length) return false;
    return _gridSteps[stepIndex].isFirstOfBeat;
  }

  void dispose() {
    stop();
    _currentStepController.close();
  }
}
