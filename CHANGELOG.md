# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.0.5] - 2025-02-09

### Added
- **Web 端调音器功能**
  - 使用 Web Audio API + 自相关算法 (ACF) 进行音高检测
  - 全平台支持调音器（iOS/Android/Web）

### Fixed
- 修复 Android NDK 版本不匹配问题 (升级到 27.0.12077973)
- 修复 record_linux 包兼容性问题 (升级 record 到 ^6.0.0)
- 移除未使用的 just_audio 依赖

### Changed
- 调音器服务重构为接口模式，支持平台条件导入
- Web 端移除"不支持"提示，改为完整功能实现

## [0.0.4] - 2025-02-09

### Added
- **调音器功能完整实现**
  - 使用 `pitch_detector_dart` (YIN算法) 进行实时音高检测
  - 使用 `record` 包采集麦克风 PCM16 音频流
  - 显示音符名称、频率 (Hz)、音分偏差
  - 仪表盘指针根据音准实时变化
  - Web 平台显示"仅支持移动端"提示

- **6种高质量采样音色**
  - click: 经典节拍器 (Perc_MetronomeQuartz)
  - stick: 鼓棒 (Perc_Stick)
  - block: 木块 (Synth_Block_A)
  - tick: 数字滴答 (Synth_Tick_A)
  - clap: 拍手 (Perc_Clap)
  - bell: 铃声 (Synth_Bell_A)

### Changed
- 音色系统从合成音改为真实采样音频
- Web 版本使用 Web Audio API + AudioBuffer 实现低延迟播放
- 移除旧的合成音色 (digital, analog, woodblock, hihat, cowbell)

### Fixed
- 修复 Web 端音频只播放一次无法重复的问题

## [0.0.3] - 2025-02-09

### Fixed
- **彻底修复 Android 音频崩溃问题**
  - 放弃不稳定的 `loadWaveform` 实时合成
  - 改用预生成的 WAV 音频文件，100% 稳定
  - 添加 ProGuard 规则防止混淆导致 Native 崩溃
- 修复 Web 端缺少音色配置导致的空值错误

### Added
- 预生成的合成音色 WAV 文件 (digital, analog, woodblock, hihat, cowbell)
- ProGuard 规则文件 `proguard-rules.pro`

### Changed
- 音频服务完全重写，统一使用 `loadAsset` 加载音频文件
- 启用 Android Release 混淆优化

## [0.0.2] - 2025-02-09

### Added
- Android 音频权限声明 (RECORD_AUDIO, MODIFY_AUDIO_SETTINGS)
- 自定义节拍器图标
- GitHub Actions 自动部署 Web 版本到 GitHub Pages
- 音频资源来源说明 (MusyngKite SoundFont)

### Changed
- 更新应用名称为"节拍器调音器"
- 优化 GitHub Actions 工作流，支持并行构建 Android 和 Web
- 调音器 UI 优化：
  - 移除模拟随机变化，改为静态等待状态
  - 添加"功能开发中"提示
  - 优化无信号时的显示状态

### Fixed
- 修复 AudioService 未初始化导致无声音的问题
- 修复调音器在无声音输入时随机变化的问题

## [0.0.1] - 2025-02-09

### Added
- 节拍器功能
  - 简单/高级模式切换
  - BPM 10-600 调节
  - 拍号选择：2/4, 3/4, 4/4, 5/4, 6/4
  - 多种节奏型：四分、八分、Swing、三连音、十六分、前八后十六、前十六后八
  - 高级模式下每拍可独立设置节奏型
  - Swing 摇摆比例调节
  - 多种音色：数字音、机械音、鼓组、木块、钢琴、吉他、贝斯、踩镲、牛铃
  - Tap Tempo 敲击测速
  - 设置自动保存 (Hive 本地存储)

- 调音器功能
  - 实时音高检测 (模拟)
  - 标准音 A4 = 440Hz
  - 可视化调音仪表盘

- 电子木鱼
  - 点击敲击积累功德
  - 飘字动画效果
  - 功德计数器

### Technical
- Flutter 3.27.0
- Riverpod 状态管理
- Hive 本地存储
- flutter_soloud 低延迟音频引擎
- flutter_animate 动画库
