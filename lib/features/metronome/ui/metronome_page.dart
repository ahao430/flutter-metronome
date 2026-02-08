import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/models/beat_type.dart';
import '../../../core/models/beat_rhythm.dart';
import '../../../core/models/measure_pattern.dart';
import '../../../core/models/rhythm_preset.dart';
import '../../../core/models/sound_pack.dart';
import '../../../core/widgets/note_icons.dart';
import '../logic/metronome_providers.dart';

/// 专业节拍器页面
class MetronomePage extends ConsumerStatefulWidget {
  const MetronomePage({super.key});

  @override
  ConsumerState<MetronomePage> createState() => _MetronomePageState();
}

class _MetronomePageState extends ConsumerState<MetronomePage> {
  String _selectedNewCategory = '基础';  // 混合节奏的分类
  String _selectedOldCategory = '基础';  // 经典预设的分类
  bool _useNewPresets = true; // 切换新旧预设系统

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(audioServiceProvider).initialize();
    });
  }

  /// 检查是否包含可以应用 Swing 的节奏型
  bool _hasSwingableRhythm(MeasurePattern pattern) {
    return pattern.beats.any((beat) =>
        beat.rhythm == BeatRhythm.swing ||
        beat.rhythm == BeatRhythm.eighths);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(metronomeStateProvider);
    final notifier = ref.read(metronomeStateProvider.notifier);
    final engine = ref.watch(metronomeEngineProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                const SizedBox(height: 12),

                // 简单/高级模式切换
                _SimpleModeToggle(
                  isSimpleMode: state.isSimpleMode,
                  onChanged: notifier.setSimpleMode,
                ),

                const SizedBox(height: 16),

                // BPM 显示
                _BpmDisplay(
                  bpm: state.bpm,
                  isPlaying: state.isPlaying,
                  onIncrement: () => notifier.incrementBpm(),
                  onDecrement: () => notifier.decrementBpm(),
                  onIncrementLong: () => notifier.incrementBpm(10),
                  onDecrementLong: () => notifier.decrementBpm(10),
                ),

                const SizedBox(height: 8),
                _BpmSlider(bpm: state.bpm, onChanged: notifier.setBpm),

                const SizedBox(height: 16),

                // 简单模式: 节奏型下拉选择
                if (state.isSimpleMode) ...[
                  _SimpleRhythmSelector(
                    currentRhythm: state.simpleRhythm,
                    onChanged: notifier.setSimpleRhythm,
                  ),

                  const SizedBox(height: 12),

                  // Swing 控制 (仅对 swing 或 eighths 有效)
                  if (state.simpleRhythm == BeatRhythm.swing ||
                      state.simpleRhythm == BeatRhythm.eighths)
                    _SwingControl(
                      swingRatio: state.swingRatio,
                      onChanged: notifier.setSwingRatio,
                    ),
                ] else ...[
                  // 高级模式: 完整的节拍器控制

                  // 拍号选择器
                  _TimeSignatureSelector(
                    currentBeats: engine.beatsPerBar,
                    onChanged: notifier.setTimeSignature,
                  ),

                  const SizedBox(height: 12),

                  // 每拍节奏型编辑卡片
                  _BeatRhythmCards(
                    measurePattern: engine.measurePattern,
                    onBeatRhythmChanged: notifier.setBeatRhythm,
                  ),

                  const SizedBox(height: 12),

                  // 预设切换标签
                  _PresetModeToggle(
                    useNewPresets: _useNewPresets,
                    onChanged: (v) => setState(() => _useNewPresets = v),
                  ),

                  const SizedBox(height: 8),

                  // 预设选择器
                  if (_useNewPresets)
                    _MeasurePatternSelector(
                      selectedCategory: _selectedNewCategory,
                      currentPattern: engine.measurePattern,
                      onCategoryChanged: (cat) => setState(() => _selectedNewCategory = cat),
                      onPatternSelected: notifier.applyMeasurePattern,
                    )
                  else
                    _RhythmPresetSelector(
                      selectedCategory: _selectedOldCategory,
                      currentPreset: state.currentPreset,
                      onCategoryChanged: (cat) => setState(() => _selectedOldCategory = cat),
                      onPresetSelected: notifier.applyPreset,
                    ),

                  const SizedBox(height: 12),

                  // Swing 控制 (仅对包含 swing 或 eighths 的节奏有效)
                  if (_hasSwingableRhythm(engine.measurePattern))
                    _SwingControl(
                      swingRatio: state.swingRatio,
                      onChanged: notifier.setSwingRatio,
                    ),
                ],

                const SizedBox(height: 12),

                // 步进网格
                _StepSequencer(
                  pattern: engine.pattern,
                  currentStep: state.currentStep,
                  isPlaying: state.isPlaying,
                  beatsPerBar: engine.beatsPerBar,
                  gridSizePerBeat: engine.gridSizePerBeat,
                  gridSteps: engine.gridSteps,
                  onToggleBeat: notifier.toggleBeatAt,
                ),

                const SizedBox(height: 12),

                // 音色选择
                _SoundPackSelector(
                  selected: state.soundPack,
                  onChanged: notifier.setSoundPack,
                ),

                const SizedBox(height: 20),

                // 控制按钮
                _ControlPanel(
                  isPlaying: state.isPlaying,
                  onToggle: notifier.toggle,
                  onTapTempo: notifier.tapTempo,
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 简单/高级模式切换
class _SimpleModeToggle extends StatelessWidget {
  final bool isSimpleMode;
  final ValueChanged<bool> onChanged;

  const _SimpleModeToggle({
    required this.isSimpleMode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(true),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSimpleMode ? Colors.blue.shade700 : Colors.transparent,
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(11)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.looks_one,
                      size: 18,
                      color: isSimpleMode ? Colors.white : Colors.white54,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '简单模式',
                      style: TextStyle(
                        color: isSimpleMode ? Colors.white : Colors.white54,
                        fontSize: 14,
                        fontWeight: isSimpleMode ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(false),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: !isSimpleMode ? Colors.blue.shade700 : Colors.transparent,
                  borderRadius: const BorderRadius.horizontal(right: Radius.circular(11)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.tune,
                      size: 18,
                      color: !isSimpleMode ? Colors.white : Colors.white54,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '高级模式',
                      style: TextStyle(
                        color: !isSimpleMode ? Colors.white : Colors.white54,
                        fontSize: 14,
                        fontWeight: !isSimpleMode ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 简单模式节奏型选择器
class _SimpleRhythmSelector extends StatelessWidget {
  final BeatRhythm currentRhythm;
  final ValueChanged<BeatRhythm> onChanged;

  const _SimpleRhythmSelector({
    required this.currentRhythm,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.music_note, color: Colors.white54, size: 16),
              SizedBox(width: 6),
              Text(
                '节奏型',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: BeatRhythm.values.map((rhythm) {
              final isSelected = rhythm == currentRhythm;
              return GestureDetector(
                onTap: () => onChanged(rhythm),
                child: Container(
                  width: 72,
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.blue.shade700
                        : Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? Colors.blue.shade400 : Colors.white24,
                    ),
                  ),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 28,
                        child: getBeatRhythmIcon(
                          rhythm,
                          size: 26,
                          color: isSelected ? Colors.white : Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        rhythm.label,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white60,
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

/// BPM 显示
class _BpmDisplay extends StatelessWidget {
  final int bpm;
  final bool isPlaying;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onIncrementLong;
  final VoidCallback onDecrementLong;

  const _BpmDisplay({
    required this.bpm,
    required this.isPlaying,
    required this.onIncrement,
    required this.onDecrement,
    required this.onIncrementLong,
    required this.onDecrementLong,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _CircleButton(icon: Icons.remove, onTap: onDecrement, onLongPress: onDecrementLong),
        const SizedBox(width: 16),
        Column(
          children: [
            Text(
              '$bpm',
              style: TextStyle(
                fontSize: 72,
                fontWeight: FontWeight.w200,
                color: isPlaying ? Colors.red.shade400 : Colors.white,
                height: 1,
              ),
            ).animate(target: isPlaying ? 1 : 0).shimmer(duration: 1500.ms, color: Colors.red.shade200),
            const Text('BPM', style: TextStyle(fontSize: 12, color: Colors.white38, letterSpacing: 4)),
          ],
        ),
        const SizedBox(width: 16),
        _CircleButton(icon: Icons.add, onTap: onIncrement, onLongPress: onIncrementLong),
      ],
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _CircleButton({required this.icon, required this.onTap, this.onLongPress});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.1),
          border: Border.all(color: Colors.white24),
        ),
        child: Icon(icon, color: Colors.white70, size: 22),
      ),
    );
  }
}

class _BpmSlider extends StatelessWidget {
  final int bpm;
  final ValueChanged<int> onChanged;

  const _BpmSlider({required this.bpm, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SliderTheme(
      data: SliderThemeData(
        trackHeight: 3,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
        activeTrackColor: Colors.red.shade400,
        inactiveTrackColor: Colors.white12,
        thumbColor: Colors.white,
      ),
      child: Slider(
        value: bpm.toDouble(),
        min: 10,
        max: 600,
        onChanged: (v) => onChanged(v.round()),
      ),
    );
  }
}

/// 拍号选择器
class _TimeSignatureSelector extends StatelessWidget {
  final int currentBeats;
  final ValueChanged<int> onChanged;

  const _TimeSignatureSelector({
    required this.currentBeats,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          const Text(
            '拍号',
            style: TextStyle(color: Colors.white60, fontSize: 12),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [2, 3, 4, 5, 6].map((beats) {
                final isSelected = currentBeats == beats;
                return GestureDetector(
                  onTap: () => onChanged(beats),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blue.shade700 : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? Colors.blue.shade400 : Colors.white24,
                      ),
                    ),
                    child: Text(
                      '$beats/4',
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white60,
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

/// 每拍节奏型编辑卡片
class _BeatRhythmCards extends StatelessWidget {
  final MeasurePattern measurePattern;
  final void Function(int beatIndex, BeatRhythm rhythm) onBeatRhythmChanged;

  const _BeatRhythmCards({
    required this.measurePattern,
    required this.onBeatRhythmChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.tune, color: Colors.white54, size: 16),
              SizedBox(width: 6),
              Text(
                '每拍节奏型 (点击编辑)',
                style: TextStyle(color: Colors.white54, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: List.generate(measurePattern.beats.length, (index) {
              final beat = measurePattern.beats[index];
              final isFirst = index == 0;

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: _BeatCard(
                    beatIndex: index,
                    rhythm: beat.rhythm,
                    isFirst: isFirst,
                    onTap: () => _showRhythmPicker(context, index),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  void _showRhythmPicker(BuildContext context, int beatIndex) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _RhythmPickerSheet(
        currentRhythm: measurePattern.beats[beatIndex].rhythm,
        beatIndex: beatIndex,
        onSelected: (rhythm) {
          onBeatRhythmChanged(beatIndex, rhythm);
          Navigator.pop(context);
        },
      ),
    );
  }
}

class _BeatCard extends StatelessWidget {
  final int beatIndex;
  final BeatRhythm rhythm;
  final bool isFirst;
  final VoidCallback onTap;

  const _BeatCard({
    required this.beatIndex,
    required this.rhythm,
    required this.isFirst,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isFirst
              ? Colors.red.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isFirst ? Colors.red.shade400 : Colors.white24,
          ),
        ),
        child: Column(
          children: [
            Text(
              '${beatIndex + 1}',
              style: TextStyle(
                color: isFirst ? Colors.red.shade300 : Colors.white54,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: 28,
              child: getBeatRhythmIcon(rhythm, size: 26, color: Colors.white70),
            ),
            const SizedBox(height: 4),
            Text(
              rhythm.label,
              style: const TextStyle(color: Colors.white54, fontSize: 8),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// 节奏型选择底部弹窗
class _RhythmPickerSheet extends StatelessWidget {
  final BeatRhythm currentRhythm;
  final int beatIndex;
  final ValueChanged<BeatRhythm> onSelected;

  const _RhythmPickerSheet({
    required this.currentRhythm,
    required this.beatIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '选择第 ${beatIndex + 1} 拍的节奏型',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: BeatRhythm.values.map((rhythm) {
              final isSelected = rhythm == currentRhythm;
              return GestureDetector(
                onTap: () => onSelected(rhythm),
                child: Container(
                  width: 80,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.blue.shade700
                        : Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? Colors.blue.shade400 : Colors.white24,
                    ),
                  ),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 32,
                        child: getBeatRhythmIcon(
                          rhythm,
                          size: 30,
                          color: isSelected ? Colors.white : Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        rhythm.label,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white60,
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

/// 预设模式切换
class _PresetModeToggle extends StatelessWidget {
  final bool useNewPresets;
  final ValueChanged<bool> onChanged;

  const _PresetModeToggle({
    required this.useNewPresets,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => onChanged(true),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: useNewPresets ? Colors.purple.shade700 : Colors.transparent,
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(10)),
                border: Border.all(
                  color: useNewPresets ? Colors.purple.shade400 : Colors.white24,
                ),
              ),
              child: Text(
                '混合节奏',
                style: TextStyle(
                  color: useNewPresets ? Colors.white : Colors.white54,
                  fontSize: 12,
                  fontWeight: useNewPresets ? FontWeight.bold : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () => onChanged(false),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: !useNewPresets ? Colors.purple.shade700 : Colors.transparent,
                borderRadius: const BorderRadius.horizontal(right: Radius.circular(10)),
                border: Border.all(
                  color: !useNewPresets ? Colors.purple.shade400 : Colors.white24,
                ),
              ),
              child: Text(
                '经典预设',
                style: TextStyle(
                  color: !useNewPresets ? Colors.white : Colors.white54,
                  fontSize: 12,
                  fontWeight: !useNewPresets ? FontWeight.bold : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// 新版预设选择器 (MeasurePattern)
class _MeasurePatternSelector extends StatelessWidget {
  final String selectedCategory;
  final MeasurePattern currentPattern;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<MeasurePattern> onPatternSelected;

  const _MeasurePatternSelector({
    required this.selectedCategory,
    required this.currentPattern,
    required this.onCategoryChanged,
    required this.onPatternSelected,
  });

  @override
  Widget build(BuildContext context) {
    final grouped = MeasurePattern.groupedPresets;
    final categories = grouped.keys.toList();

    // 如果选中的分类不存在，使用第一个分类
    final effectiveCategory = grouped.containsKey(selectedCategory)
        ? selectedCategory
        : (categories.isNotEmpty ? categories.first : '');
    final patternsInCategory = grouped[effectiveCategory] ?? [];

    // 如果分类不匹配，通知父组件更新
    if (effectiveCategory != selectedCategory && categories.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        onCategoryChanged(effectiveCategory);
      });
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 分类标签
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: categories.map((cat) {
                final isSelected = cat == effectiveCategory;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => onCategoryChanged(cat),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.purple.shade700 : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? Colors.purple.shade500 : Colors.white24,
                        ),
                      ),
                      child: Text(
                        cat,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white60,
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 10),

          // 预设列表
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: patternsInCategory.map((pattern) {
              final isSelected = currentPattern.id == pattern.id;
              return GestureDetector(
                onTap: () => onPatternSelected(pattern),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.green.shade700 : Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? Colors.green.shade400 : Colors.white12,
                    ),
                  ),
                  child: Text(
                    pattern.name,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

/// 节奏型预设选择器
class _RhythmPresetSelector extends StatelessWidget {
  final String selectedCategory;
  final RhythmPreset? currentPreset;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<RhythmPreset> onPresetSelected;

  const _RhythmPresetSelector({
    required this.selectedCategory,
    required this.currentPreset,
    required this.onCategoryChanged,
    required this.onPresetSelected,
  });

  @override
  Widget build(BuildContext context) {
    final grouped = RhythmPreset.groupedPresets;
    final categories = grouped.keys.toList();

    // 如果选中的分类不存在，使用第一个分类
    final effectiveCategory = grouped.containsKey(selectedCategory)
        ? selectedCategory
        : (categories.isNotEmpty ? categories.first : '');
    final presetsInCategory = grouped[effectiveCategory] ?? [];

    // 如果分类不匹配，通知父组件更新
    if (effectiveCategory != selectedCategory && categories.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        onCategoryChanged(effectiveCategory);
      });
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 分类标签
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: categories.map((cat) {
                final isSelected = cat == effectiveCategory;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => onCategoryChanged(cat),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.blue.shade700 : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? Colors.blue.shade500 : Colors.white24,
                        ),
                      ),
                      child: Text(
                        cat,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white60,
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 10),

          // 预设列表
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: presetsInCategory.map((preset) {
              final isSelected = currentPreset?.id == preset.id;
              return GestureDetector(
                onTap: () => onPresetSelected(preset),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.red.shade700 : Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? Colors.red.shade400 : Colors.white12,
                    ),
                  ),
                  child: Text(
                    preset.name,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

/// Swing 控制
class _SwingControl extends StatelessWidget {
  final double swingRatio;
  final ValueChanged<double> onChanged;

  const _SwingControl({required this.swingRatio, required this.onChanged});

  String get _label {
    if (swingRatio <= 0.52) return '直拍';
    if (swingRatio <= 0.60) return '轻Swing';
    if (swingRatio <= 0.70) return 'Swing';
    return '重Swing';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.swap_horiz, color: Colors.orange.shade300, size: 18),
          const SizedBox(width: 8),
          Text('Swing', style: TextStyle(color: Colors.orange.shade200, fontSize: 12)),
          const Spacer(),
          SizedBox(
            width: 120,
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                activeTrackColor: Colors.orange.shade400,
                inactiveTrackColor: Colors.white12,
                thumbColor: Colors.orange.shade200,
              ),
              child: Slider(
                value: swingRatio,
                min: 0.5,
                max: 0.75,
                onChanged: onChanged,
              ),
            ),
          ),
          SizedBox(
            width: 60,
            child: Text(
              _label,
              style: TextStyle(color: Colors.orange.shade200, fontSize: 11),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

/// 步进网格
class _StepSequencer extends StatelessWidget {
  final List<BeatType> pattern;
  final int currentStep;
  final bool isPlaying;
  final int beatsPerBar;
  final int gridSizePerBeat;
  final List<GridStep> gridSteps;
  final ValueChanged<int> onToggleBeat;

  const _StepSequencer({
    required this.pattern,
    required this.currentStep,
    required this.isPlaying,
    required this.beatsPerBar,
    required this.gridSizePerBeat,
    required this.gridSteps,
    required this.onToggleBeat,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          // 按拍分行，每拍 gridSizePerBeat 格
          ...List.generate(beatsPerBar, (beatIdx) {
            final startIdx = beatIdx * gridSizePerBeat;

            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  // 拍号
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: beatIdx == 0 ? Colors.red.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text(
                        '${beatIdx + 1}',
                        style: TextStyle(
                          color: beatIdx == 0 ? Colors.red.shade300 : Colors.white54,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // gridSizePerBeat 个网格
                  Expanded(
                    child: Row(
                      children: List.generate(gridSizePerBeat, (gridIdx) {
                        final globalIdx = startIdx + gridIdx;
                        if (globalIdx >= gridSteps.length) {
                          return const Expanded(child: SizedBox());
                        }
                        final gridStep = gridSteps[globalIdx];
                        final isActive = currentStep == globalIdx && isPlaying;
                        final beatType = gridStep.beatType;
                        final isFirst = gridStep.isFirstOfBeat;

                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: _StepBox(
                              beatType: beatType,
                              isActive: isActive,
                              isFirst: isFirst,
                              onTap: () => onToggleBeat(globalIdx),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 6),
          // 图例
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _Legend(Colors.grey.shade700, '空'),
              const SizedBox(width: 12),
              _Legend(Colors.green.shade600, '弱'),
              const SizedBox(width: 12),
              _Legend(Colors.red.shade600, '强'),
              const SizedBox(width: 12),
              _Legend(Colors.orange.shade600, '次'),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepBox extends StatelessWidget {
  final BeatType beatType;
  final bool isActive;
  final bool isFirst;
  final VoidCallback onTap;

  const _StepBox({
    required this.beatType,
    required this.isActive,
    required this.isFirst,
    required this.onTap,
  });

  Color get _color => switch (beatType) {
        BeatType.rest => Colors.grey.shade800,
        BeatType.weak => Colors.green.shade600,
        BeatType.strong => Colors.red.shade600,
        BeatType.subAccent => Colors.orange.shade600,
      };

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 50),
        height: isFirst ? 40 : 32,
        decoration: BoxDecoration(
          color: _color,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: isActive ? Colors.white : Colors.transparent, width: 2),
          boxShadow: isActive
              ? [BoxShadow(color: _color.withValues(alpha: 0.8), blurRadius: 10)]
              : null,
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;

  const _Legend(this.color, this.label);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 3),
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 9)),
      ],
    );
  }
}

/// 音色选择
class _SoundPackSelector extends StatelessWidget {
  final SoundPack selected;
  final ValueChanged<SoundPack> onChanged;

  const _SoundPackSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: SoundPack.values.map((pack) {
          final isSelected = pack == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: GestureDetector(
              onTap: () => onChanged(pack),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.purple.shade700 : Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isSelected ? Colors.purple.shade400 : Colors.white12),
                ),
                child: Text(
                  pack.label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white60,
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// 控制面板
class _ControlPanel extends StatelessWidget {
  final bool isPlaying;
  final VoidCallback onToggle;
  final VoidCallback onTapTempo;

  const _ControlPanel({required this.isPlaying, required this.onToggle, required this.onTapTempo});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Tap Tempo
        GestureDetector(
          onTap: onTapTempo,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.1),
              border: Border.all(color: Colors.white24),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.touch_app, color: Colors.white70, size: 20),
                Text('TAP', style: TextStyle(color: Colors.white54, fontSize: 8, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 24),
        // 播放
        GestureDetector(
          onTap: onToggle,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isPlaying
                    ? [Colors.red.shade400, Colors.red.shade700]
                    : [Colors.green.shade400, Colors.green.shade700],
              ),
              boxShadow: [
                BoxShadow(
                  color: (isPlaying ? Colors.red : Colors.green).withValues(alpha: 0.4),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              isPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded,
              size: 44,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 24),
        const SizedBox(width: 56),
      ],
    );
  }
}
