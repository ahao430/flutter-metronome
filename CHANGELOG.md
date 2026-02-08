# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
- flutter_animate 动画库
