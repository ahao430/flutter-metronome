import 'package:hive_flutter/hive_flutter.dart';
import '../models/beat_rhythm.dart';

/// 节拍器设置服务 - 持久化存储用户设置
class MetronomeSettings {
  static const String _boxName = 'metronome_settings';
  static Box? _box;

  /// 初始化
  static Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox(_boxName);
  }

  static Box get box {
    if (_box == null) {
      throw StateError('MetronomeSettings not initialized. Call init() first.');
    }
    return _box!;
  }

  // ===== Keys =====
  static const String _keyIsSimpleMode = 'isSimpleMode';
  static const String _keyBpm = 'bpm';
  static const String _keySimpleRhythm = 'simpleRhythm';
  static const String _keyAdvancedPatternId = 'advancedPatternId';
  static const String _keyBeatsPerBar = 'beatsPerBar';
  static const String _keySwingRatio = 'swingRatio';
  static const String _keySoundPack = 'soundPack';

  // ===== Getters =====

  /// 是否是简单模式
  static bool get isSimpleMode => box.get(_keyIsSimpleMode, defaultValue: true);

  /// BPM
  static int get bpm => box.get(_keyBpm, defaultValue: 120);

  /// 简单模式的节奏型
  static String get simpleRhythmName =>
      box.get(_keySimpleRhythm, defaultValue: 'quarter');

  static BeatRhythm get simpleRhythm {
    final name = simpleRhythmName;
    return BeatRhythm.values.firstWhere(
      (r) => r.name == name,
      orElse: () => BeatRhythm.quarter,
    );
  }

  /// 高级模式的预设ID
  static String get advancedPatternId =>
      box.get(_keyAdvancedPatternId, defaultValue: 'basic_4_4');

  /// 拍数
  static int get beatsPerBar => box.get(_keyBeatsPerBar, defaultValue: 4);

  /// Swing比例
  static double get swingRatio => box.get(_keySwingRatio, defaultValue: 0.5);

  /// 音色包索引
  static int get soundPackIndex => box.get(_keySoundPack, defaultValue: 0);

  // ===== Setters =====

  static Future<void> setIsSimpleMode(bool value) async {
    await box.put(_keyIsSimpleMode, value);
  }

  static Future<void> setBpm(int value) async {
    await box.put(_keyBpm, value);
  }

  static Future<void> setSimpleRhythm(BeatRhythm rhythm) async {
    await box.put(_keySimpleRhythm, rhythm.name);
  }

  static Future<void> setAdvancedPatternId(String id) async {
    await box.put(_keyAdvancedPatternId, id);
  }

  static Future<void> setBeatsPerBar(int value) async {
    await box.put(_keyBeatsPerBar, value);
  }

  static Future<void> setSwingRatio(double value) async {
    await box.put(_keySwingRatio, value);
  }

  static Future<void> setSoundPackIndex(int index) async {
    await box.put(_keySoundPack, index);
  }
}
