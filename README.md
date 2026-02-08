# 节拍器 + 调音器 APP (Flutter)

一款专业的音乐练习工具，支持节拍器和调音器功能。

## 功能特性

### 节拍器
- **简单/高级模式切换**
  - 简单模式：单拍设置，快速选择节奏型
  - 高级模式：多拍编排，每拍独立设置
- 支持 BPM 10-600 调节
- 拍号选择：2/4, 3/4, 4/4, 5/4, 6/4
- 多种节奏型：四分、八分、三连音、十六分、前八后十六、前十六后八
- Swing 摇摆节奏支持
- 多种音色：数字音、机械音、鼓组、木块、钢琴、吉他、贝斯、踩镲、牛铃
- Tap Tempo 敲击测速
- 设置自动保存

### 调音器
- 实时音高检测
- 标准音 A4 = 440Hz

### 电子木鱼
- 点击敲击，积累功德
- 飘字动画效果

## TODO

- [ ] 寻找更多音色文件，用实际音频文件代替合成声音
  - 钢琴、吉他、贝斯等乐器音色
  - 可在 `assets/sounds/` 目录下放置音频文件
  - 更新 `AudioService` 以加载音频文件

## 环境要求

- Flutter SDK: ^3.10.8
- Dart SDK: ^3.10.8

## 安装

### 1. 安装 Flutter

如果尚未安装 Flutter，请参考官方文档：https://docs.flutter.dev/get-started/install

macOS 推荐使用 FVM (Flutter Version Manager)：
```bash
# 安装 FVM
brew tap leoafarias/fvm
brew install fvm

# 安装指定版本 Flutter
fvm install 3.27.0
fvm use 3.27.0
```

### 2. 克隆项目

```bash
git clone <repository-url>
cd flutter-metronome
```

### 3. 安装依赖

```bash
flutter pub get
```

## 运行项目

### iOS 模拟器
```bash
# 打开 iOS 模拟器
open -a Simulator

# 运行项目
flutter run
```

### Android 模拟器
```bash
# 确保 Android 模拟器已启动
flutter run
```

### Web
```bash
flutter run -d chrome
```

### macOS 桌面
```bash
flutter run -d macos
```

### 指定设备运行
```bash
# 查看可用设备
flutter devices

# 在指定设备运行
flutter run -d <device-id>
```

## 构建发布版本

### iOS
```bash
flutter build ios --release
```

### Android
```bash
flutter build apk --release
# 或构建 App Bundle
flutter build appbundle --release
```

### Web
```bash
flutter build web --release
```

### macOS
```bash
flutter build macos --release
```

## 项目结构

```
lib/
├── main.dart                      # 应用入口
├── core/
│   ├── models/
│   │   ├── beat_type.dart         # 节拍类型枚举
│   │   ├── beat_rhythm.dart       # 节奏型枚举
│   │   ├── measure_pattern.dart   # 小节配置模型
│   │   ├── rhythm_preset.dart     # 预设节奏型
│   │   └── sound_pack.dart        # 音色包
│   ├── services/
│   │   ├── audio_service.dart     # 音频服务
│   │   └── settings_service.dart  # 设置持久化服务
│   └── widgets/
│       └── note_icons.dart        # 音符图标组件
└── features/
    ├── metronome/
    │   ├── logic/
    │   │   ├── metronome_engine.dart    # 节拍器引擎
    │   │   └── metronome_providers.dart # 状态管理
    │   └── ui/
    │       └── metronome_page.dart      # 节拍器页面
    ├── tuner/
    │   └── ui/
    │       └── tuner_page.dart          # 调音器页面
    └── wooden_fish/
        └── ui/
            └── wooden_fish_page.dart    # 木鱼页面
```

## 技术栈

- **状态管理**: flutter_riverpod
- **音频播放**: audioplayers
- **本地存储**: hive
- **动画**: flutter_animate
- **屏幕常亮**: wakelock_plus

## License

MIT
