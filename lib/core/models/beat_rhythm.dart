/// 每拍的节奏型 - 定义一拍内的音符细分方式
enum BeatRhythm {
  /// 四分音符 - 一拍一下 (♩)
  quarter(1, '四分', [1.0], null, [true]),

  /// 八分音符 - 一拍两下 (♫)
  eighths(2, '八分', [0.5, 0.5], null, [true, true]),

  /// Swing - 摇摆节奏 (三连音省略中间)
  /// 显示为3格: 1-0-1
  swing(2, 'Swing', [2/3, 1/3], null, [true, false, true]),

  /// 三连音 - 一拍三下 (3)
  triplets(3, '三连音', [1/3, 1/3, 1/3], null, [true, true, true]),

  /// 十六分音符 - 一拍四下 (♬)
  sixteenths(4, '十六分', [0.25, 0.25, 0.25, 0.25], null, [true, true, true, true]),

  /// 前八后十六 (Gallop) - 一拍三下 (♪♬)
  /// 第一个音占1/2拍，后两个音各占1/4拍
  /// 显示为4格: 1-0-1-1
  gallop(3, '前八后十六', [0.5, 0.25, 0.25], null, [true, false, true, true]),

  /// 前十六后八 (Reverse Gallop) - 一拍三下 (♬♪)
  /// 前两个音各占1/4拍，最后一个音占1/2拍
  /// 显示为4格: 1-1-1-0
  reverseGallop(3, '前十六后八', [0.25, 0.25, 0.5], null, [true, true, true, false]);

  /// 每拍响的次数
  final int soundCount;

  /// 显示名称
  final String label;

  /// 每个音的时值比例 (加起来 = 1.0) - 用于播放
  final List<double> durations;

  /// 哪些位置发声 (仅用于有休止符的节奏型) - 用于播放
  final List<bool>? soundMask;

  /// 原生网格模式 - 用于UI显示
  /// 长度就是这个节奏型的原生格子数
  final List<bool> nativeGrid;

  const BeatRhythm(this.soundCount, this.label, this.durations, this.soundMask, this.nativeGrid);

  /// 原生格子数量
  int get nativeGridSize => nativeGrid.length;

  /// 获取实际的发声时间点列表 (0.0 ~ 1.0 范围内)
  List<double> get soundPositions {
    final positions = <double>[];
    double pos = 0.0;

    for (int i = 0; i < durations.length; i++) {
      if (soundMask == null || soundMask![i]) {
        positions.add(pos);
      }
      pos += durations[i];
    }

    return positions;
  }

  /// 获取所有时间点列表 (包括不发声的)
  List<double> get allPositions {
    final positions = <double>[];
    double pos = 0.0;

    for (int i = 0; i < durations.length; i++) {
      positions.add(pos);
      pos += durations[i];
    }

    return positions;
  }

  /// 判断某个位置是否发声 (播放用)
  bool shouldSound(int index) {
    if (soundMask == null) return true;
    if (index >= soundMask!.length) return false;
    return soundMask![index];
  }

  /// 将原生网格扩展到指定大小
  /// 例如: [1,1] 扩展到4格 -> [1,0,1,0]
  List<bool> expandGridTo(int targetSize) {
    if (targetSize == nativeGridSize) return List.from(nativeGrid);
    if (targetSize < nativeGridSize) return List.from(nativeGrid); // 不能缩小

    final result = List.filled(targetSize, false);
    final ratio = targetSize / nativeGridSize;

    for (int i = 0; i < nativeGridSize; i++) {
      if (nativeGrid[i]) {
        final targetIndex = (i * ratio).round();
        if (targetIndex < targetSize) {
          result[targetIndex] = true;
        }
      }
    }

    return result;
  }
}

/// 计算最小公倍数
int lcm(int a, int b) {
  return (a * b) ~/ gcd(a, b);
}

/// 计算最大公约数
int gcd(int a, int b) {
  while (b != 0) {
    final t = b;
    b = a % b;
    a = t;
  }
  return a;
}

/// 计算多个数的最小公倍数
int lcmMultiple(List<int> numbers) {
  if (numbers.isEmpty) return 1;
  return numbers.reduce((a, b) => lcm(a, b));
}
