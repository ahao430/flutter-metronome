import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/beat_rhythm.dart';
import '../../../core/models/measure_pattern.dart';
import '../../../core/models/rhythm_preset.dart';
import '../../../core/models/sound_pack.dart';
import '../../../core/services/audio_service.dart';
import '../../../core/services/settings_service.dart';
import 'metronome_engine.dart';

/// 音频服务 Provider
final audioServiceProvider = Provider<AudioService>((ref) {
  final service = AudioService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// 节拍器引擎 Provider
final metronomeEngineProvider = Provider<MetronomeEngine>((ref) {
  final audioService = ref.watch(audioServiceProvider);
  final engine = MetronomeEngine(audioService);
  ref.onDispose(() => engine.dispose());
  return engine;
});

/// 节拍器状态
class MetronomeState {
  final bool isPlaying;
  final int bpm;
  final int currentStep;
  final SoundPack soundPack;
  final RhythmPreset? currentPreset;
  final MeasurePattern? measurePattern;
  final double swingRatio;
  final List<int> tapTimestamps;
  final bool isSimpleMode;
  final BeatRhythm simpleRhythm;

  const MetronomeState({
    this.isPlaying = false,
    this.bpm = 120,
    this.currentStep = -1,
    this.soundPack = SoundPack.digital,
    this.currentPreset,
    this.measurePattern,
    this.swingRatio = 0.5,
    this.tapTimestamps = const [],
    this.isSimpleMode = true,
    this.simpleRhythm = BeatRhythm.quarter,
  });

  MetronomeState copyWith({
    bool? isPlaying,
    int? bpm,
    int? currentStep,
    SoundPack? soundPack,
    RhythmPreset? currentPreset,
    bool clearPreset = false,
    MeasurePattern? measurePattern,
    bool clearMeasurePattern = false,
    double? swingRatio,
    List<int>? tapTimestamps,
    bool? isSimpleMode,
    BeatRhythm? simpleRhythm,
  }) {
    return MetronomeState(
      isPlaying: isPlaying ?? this.isPlaying,
      bpm: bpm ?? this.bpm,
      currentStep: currentStep ?? this.currentStep,
      soundPack: soundPack ?? this.soundPack,
      currentPreset: clearPreset ? null : (currentPreset ?? this.currentPreset),
      measurePattern: clearMeasurePattern ? null : (measurePattern ?? this.measurePattern),
      swingRatio: swingRatio ?? this.swingRatio,
      tapTimestamps: tapTimestamps ?? this.tapTimestamps,
      isSimpleMode: isSimpleMode ?? this.isSimpleMode,
      simpleRhythm: simpleRhythm ?? this.simpleRhythm,
    );
  }
}

/// 节拍器状态 Notifier
class MetronomeNotifier extends StateNotifier<MetronomeState> {
  final MetronomeEngine _engine;
  final AudioService _audioService;

  MetronomeNotifier(this._engine, this._audioService)
      : super(MetronomeState(
          bpm: MetronomeSettings.bpm,
          isSimpleMode: MetronomeSettings.isSimpleMode,
          simpleRhythm: MetronomeSettings.simpleRhythm,
          soundPack: SoundPack.values[MetronomeSettings.soundPackIndex.clamp(0, SoundPack.values.length - 1)],
          currentPreset: RhythmPreset.presets.first,
          measurePattern: MeasurePattern.presets.first,
          swingRatio: MetronomeSettings.swingRatio,
        )) {
    // 应用保存的设置
    _engine.bpm = state.bpm;
    _audioService.setSoundPack(state.soundPack);

    if (state.isSimpleMode) {
      // 简单模式: 单拍，应用保存的节奏型
      _applySimpleModePattern(state.simpleRhythm);
    } else {
      // 高级模式: 应用保存的预设
      final savedPatternId = MetronomeSettings.advancedPatternId;
      final savedPattern = MeasurePattern.presets.firstWhere(
        (p) => p.id == savedPatternId,
        orElse: () => MeasurePattern.presets.first,
      );
      _engine.applyMeasurePattern(savedPattern);
      state = state.copyWith(measurePattern: savedPattern);
    }

    _engine.onStepChanged.listen((step) {
      state = state.copyWith(
        currentStep: step,
        isPlaying: _engine.isPlaying,
        measurePattern: _engine.measurePattern,
      );
    });
  }

  /// 应用简单模式的节奏配置
  void _applySimpleModePattern(BeatRhythm rhythm) {
    final pattern = MeasurePattern(
      id: 'simple_${rhythm.name}',
      name: '简单模式',
      category: '简单',
      beatsPerBar: 1,
      beats: [BeatConfig(rhythm: rhythm)],
    );
    _engine.applyMeasurePattern(pattern);
  }

  /// 切换简单/高级模式
  void setSimpleMode(bool isSimple) {
    if (state.isSimpleMode == isSimple) return;

    MetronomeSettings.setIsSimpleMode(isSimple);

    if (isSimple) {
      // 切换到简单模式
      _applySimpleModePattern(state.simpleRhythm);
    } else {
      // 切换到高级模式，恢复保存的预设
      final savedPatternId = MetronomeSettings.advancedPatternId;
      final savedPattern = MeasurePattern.presets.firstWhere(
        (p) => p.id == savedPatternId,
        orElse: () => MeasurePattern.presets.first,
      );
      _engine.applyMeasurePattern(savedPattern);
      state = state.copyWith(measurePattern: savedPattern);
    }

    state = state.copyWith(
      isSimpleMode: isSimple,
      measurePattern: _engine.measurePattern,
    );
  }

  /// 设置简单模式的节奏型
  void setSimpleRhythm(BeatRhythm rhythm) {
    MetronomeSettings.setSimpleRhythm(rhythm);
    _applySimpleModePattern(rhythm);
    state = state.copyWith(
      simpleRhythm: rhythm,
      measurePattern: _engine.measurePattern,
    );
  }

  void toggle() {
    _engine.toggle();
    state = state.copyWith(isPlaying: _engine.isPlaying);
  }

  void setBpm(int bpm) {
    final clampedBpm = bpm.clamp(10, 600);
    _engine.bpm = clampedBpm;
    MetronomeSettings.setBpm(clampedBpm);
    state = state.copyWith(bpm: clampedBpm);
  }

  void toggleBeatAt(int index) {
    _engine.toggleBeatAt(index);
    // 手动修改后清除预设标记
    state = state.copyWith(
      clearPreset: true,
      measurePattern: _engine.measurePattern,
    );
  }

  void setSoundPack(SoundPack pack) {
    _audioService.setSoundPack(pack);
    MetronomeSettings.setSoundPackIndex(pack.index);
    state = state.copyWith(soundPack: pack);
  }

  /// 应用预设节奏型 (旧 API)
  void applyPreset(RhythmPreset preset) {
    _engine.applyPreset(preset);
    state = state.copyWith(
      currentPreset: preset,
      swingRatio: preset.swingRatio,
      measurePattern: _engine.measurePattern,
    );
  }

  /// 应用小节节奏配置 (新 API)
  void applyMeasurePattern(MeasurePattern pattern) {
    _engine.applyMeasurePattern(pattern);
    MetronomeSettings.setAdvancedPatternId(pattern.id);
    state = state.copyWith(
      measurePattern: pattern,
      swingRatio: pattern.swingRatio,
      clearPreset: true,
    );
  }

  /// 设置拍号
  void setTimeSignature(int beatsPerBar) {
    _engine.setTimeSignature(beatsPerBar);
    MetronomeSettings.setBeatsPerBar(beatsPerBar);
    state = state.copyWith(
      measurePattern: _engine.measurePattern,
      clearPreset: true,
    );
  }

  /// 设置某一拍的节奏型
  void setBeatRhythm(int beatIndex, BeatRhythm rhythm) {
    _engine.setBeatRhythm(beatIndex, rhythm);
    state = state.copyWith(
      measurePattern: _engine.measurePattern,
      clearPreset: true,
    );
  }

  /// 统一设置所有拍的节奏型
  void setUniformRhythm(BeatRhythm rhythm) {
    _engine.setUniformRhythm(rhythm);
    state = state.copyWith(
      measurePattern: _engine.measurePattern,
      clearPreset: true,
    );
  }

  /// 设置 Swing 比例
  void setSwingRatio(double ratio) {
    _engine.setSwingRatio(ratio);
    MetronomeSettings.setSwingRatio(ratio);
    state = state.copyWith(swingRatio: ratio, clearPreset: true);
  }

  /// Tap Tempo
  void tapTempo() {
    final now = DateTime.now().millisecondsSinceEpoch;
    var taps = List<int>.from(state.tapTimestamps);

    taps = taps.where((t) => now - t < 2000).toList();
    taps.add(now);

    if (taps.length >= 2) {
      int totalInterval = 0;
      for (int i = 1; i < taps.length; i++) {
        totalInterval += taps[i] - taps[i - 1];
      }
      final avgInterval = totalInterval / (taps.length - 1);
      final calculatedBpm = (60000 / avgInterval).round().clamp(10, 600);

      _engine.bpm = calculatedBpm;
      state = state.copyWith(bpm: calculatedBpm, tapTimestamps: taps);
    } else {
      state = state.copyWith(tapTimestamps: taps);
    }
  }

  void incrementBpm([int delta = 1]) {
    setBpm(state.bpm + delta);
  }

  void decrementBpm([int delta = 1]) {
    setBpm(state.bpm - delta);
  }
}

/// 节拍器状态 Provider
final metronomeStateProvider =
    StateNotifierProvider<MetronomeNotifier, MetronomeState>((ref) {
  final engine = ref.watch(metronomeEngineProvider);
  final audioService = ref.watch(audioServiceProvider);
  return MetronomeNotifier(engine, audioService);
});
