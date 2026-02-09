/// 音色类型
enum SoundType {
  synthesis,  // 合成音（电子音）- 已弃用
  sample,     // 采样音（音频文件）
}

/// 音色包枚举
enum SoundPack {
  // 采样音色（使用高质量 WAV 文件）
  click('click', '经典节拍器', SoundType.sample),
  stick('stick', '鼓棒', SoundType.sample),
  block('block', '木块', SoundType.sample),
  tick('tick', '数字滴答', SoundType.sample),
  clap('clap', '拍手', SoundType.sample),
  bell('bell', '铃声', SoundType.sample);

  final String folderName;  // 文件夹名称
  final String label;       // 显示名称
  final SoundType type;

  const SoundPack(this.folderName, this.label, this.type);

  /// 是否是合成音色
  bool get isSynthesis => type == SoundType.synthesis;

  /// 是否是采样音色
  bool get isSample => type == SoundType.sample;

  /// 获取音频文件路径
  String getAssetPath(String beatType) => 'assets/audio/samples/${folderName}_$beatType.wav';
}

/// 节奏细分类型
enum Subdivision {
  quarter(1, '四分音符', '♩'),       // 1拍1下
  eighth(2, '八分音符', '♫'),        // 1拍2下 (两个连音)
  triplet(3, '三连音', '♫³'),        // 1拍3下 (三连音标记)
  sixteenth(4, '十六分音符', '♬♬');  // 1拍4下 (四个连音)

  final int divisor;
  final String label;
  final String symbol;

  const Subdivision(this.divisor, this.label, this.symbol);
}

/// 拍号配置
class TimeSignature {
  final int beats;        // 每小节几拍
  final Subdivision subdivision; // 每拍细分

  const TimeSignature({
    required this.beats,
    required this.subdivision,
  });

  /// 总步数
  int get totalSteps => beats * subdivision.divisor;

  /// 常用预设
  static const standard44 = TimeSignature(beats: 4, subdivision: Subdivision.quarter);
  static const standard34 = TimeSignature(beats: 3, subdivision: Subdivision.quarter);
  static const eighth44 = TimeSignature(beats: 4, subdivision: Subdivision.eighth);
  static const triplet44 = TimeSignature(beats: 4, subdivision: Subdivision.triplet);
  static const sixteenth44 = TimeSignature(beats: 4, subdivision: Subdivision.sixteenth);
}
