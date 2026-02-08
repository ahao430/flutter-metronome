/// 音色类型
enum SoundType {
  synthesis,  // 合成音（电子音）
  sample,     // 采样音（音频文件）
}

/// 音色包枚举
enum SoundPack {
  // 合成音色
  digital('digital', '数字音', SoundType.synthesis),
  analog('analog', '机械音', SoundType.synthesis),
  woodblock('woodblock', '木块', SoundType.synthesis),
  hihat('hihat', '踩镲', SoundType.synthesis),
  cowbell('cowbell', '牛铃', SoundType.synthesis),

  // 采样音色 (音频文件)
  drumKit('drumkit', '鼓组', SoundType.sample),
  piano('piano', '钢琴', SoundType.sample),
  guitar('guitar', '吉他', SoundType.sample),
  bass('bass', '贝斯', SoundType.sample),
  musicBox('musicbox', '音乐盒', SoundType.sample),
  violin('violin', '小提琴', SoundType.sample),
  trumpet('trumpet', '小号', SoundType.sample);

  final String folderName;  // 文件夹名称
  final String label;       // 显示名称
  final SoundType type;

  const SoundPack(this.folderName, this.label, this.type);

  /// 是否是合成音色
  bool get isSynthesis => type == SoundType.synthesis;

  /// 是否是采样音色
  bool get isSample => type == SoundType.sample;

  /// 获取音频文件路径 (采样音色用)
  String getAssetPath(String beatType) => 'assets/audio/$folderName/$beatType.mp3';
}

/// 音色包对应的频率配置
class SoundPackConfig {
  final double strongFreq;
  final double weakFreq;
  final double subAccentFreq;
  final String waveType;
  final double duration; // 声音持续时间
  final double attack;   // 起音时间

  const SoundPackConfig({
    required this.strongFreq,
    required this.weakFreq,
    required this.subAccentFreq,
    this.waveType = 'sine',
    this.duration = 0.08,
    this.attack = 0.01,
  });

  static const Map<SoundPack, SoundPackConfig> configs = {
    // 数字音：清脆的高频方波
    SoundPack.digital: SoundPackConfig(
      strongFreq: 1200,
      weakFreq: 900,
      subAccentFreq: 1050,
      waveType: 'square',
      duration: 0.05,
    ),
    // 机械音：温暖的三角波
    SoundPack.analog: SoundPackConfig(
      strongFreq: 660,
      weakFreq: 440,
      subAccentFreq: 550,
      waveType: 'triangle',
      duration: 0.08,
    ),
    // 鼓组：低频正弦波模拟底鼓
    SoundPack.drumKit: SoundPackConfig(
      strongFreq: 80,
      weakFreq: 200,
      subAccentFreq: 120,
      waveType: 'sine',
      duration: 0.12,
    ),
    // 木块：高频短促
    SoundPack.woodblock: SoundPackConfig(
      strongFreq: 800,
      weakFreq: 600,
      subAccentFreq: 700,
      waveType: 'triangle',
      duration: 0.06,
    ),
    // 钢琴：待添加音频文件 (临时用正弦波占位)
    SoundPack.piano: SoundPackConfig(
      strongFreq: 523,   // C5
      weakFreq: 392,     // G4
      subAccentFreq: 440, // A4
      waveType: 'sine',
      duration: 0.15,
    ),
    // 吉他：待添加音频文件 (临时用三角波占位)
    SoundPack.guitar: SoundPackConfig(
      strongFreq: 330,   // E4
      weakFreq: 247,     // B3
      subAccentFreq: 294, // D4
      waveType: 'triangle',
      duration: 0.12,
    ),
    // 贝斯：待添加音频文件 (临时用低频正弦波占位)
    SoundPack.bass: SoundPackConfig(
      strongFreq: 98,    // G2
      weakFreq: 73,      // D2
      subAccentFreq: 82,  // E2
      waveType: 'sine',
      duration: 0.15,
    ),
    // 踩镲：高频噪声感
    SoundPack.hihat: SoundPackConfig(
      strongFreq: 1500,
      weakFreq: 1200,
      subAccentFreq: 1350,
      waveType: 'square',
      duration: 0.03,
    ),
    // 牛铃：中高频金属音
    SoundPack.cowbell: SoundPackConfig(
      strongFreq: 560,
      weakFreq: 450,
      subAccentFreq: 500,
      waveType: 'square',
      duration: 0.08,
    ),
  };
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
