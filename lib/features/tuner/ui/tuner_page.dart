import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/tuner_service.dart';

/// TunerService Provider
final tunerServiceProvider = Provider<TunerService>((ref) {
  final service = TunerService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// 调音器状态
class TunerState {
  final bool isListening;
  final bool hasPermission;
  final PitchResult pitch;

  const TunerState({
    this.isListening = false,
    this.hasPermission = false,
    this.pitch = PitchResult.noSignal,
  });

  TunerState copyWith({
    bool? isListening,
    bool? hasPermission,
    PitchResult? pitch,
  }) {
    return TunerState(
      isListening: isListening ?? this.isListening,
      hasPermission: hasPermission ?? this.hasPermission,
      pitch: pitch ?? this.pitch,
    );
  }
}

/// 调音器状态 Notifier
class TunerNotifier extends StateNotifier<TunerState> {
  final TunerService _tunerService;
  StreamSubscription<PitchResult>? _pitchSubscription;

  TunerNotifier(this._tunerService) : super(const TunerState()) {
    _init();
  }

  void _init() async {
    // 检查权限
    final hasPermission = await _tunerService.checkPermission();
    state = state.copyWith(hasPermission: hasPermission);

    // 监听音高变化
    _pitchSubscription = _tunerService.pitchStream.listen((pitch) {
      state = state.copyWith(pitch: pitch);
    });
  }

  Future<void> toggleListening() async {
    if (state.isListening) {
      await _tunerService.stopListening();
      state = state.copyWith(
        isListening: false,
        pitch: PitchResult.noSignal,
      );
    } else {
      final success = await _tunerService.startListening();
      state = state.copyWith(
        isListening: success,
        hasPermission: _tunerService.hasPermission,
      );
    }
  }

  @override
  void dispose() {
    _pitchSubscription?.cancel();
    super.dispose();
  }
}

/// 调音器状态 Provider
final tunerStateProvider = StateNotifierProvider<TunerNotifier, TunerState>((ref) {
  final service = ref.watch(tunerServiceProvider);
  return TunerNotifier(service);
});

/// 调音器页面
class TunerPage extends ConsumerWidget {
  const TunerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Web 平台不支持调音器
    if (kIsWeb) {
      return _buildUnsupportedView();
    }

    final tunerState = ref.watch(tunerStateProvider);
    final tunerNotifier = ref.read(tunerStateProvider.notifier);

    final pitch = tunerState.pitch;
    final isListening = tunerState.isListening;
    final hasSignal = pitch.frequency > 0;
    final isInTune = hasSignal && pitch.isInTune;

    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      body: SafeArea(
        child: Center(
          child: Column(
            children: [
              const SizedBox(height: 40),
              // 标题
              Text(
                'TUNER',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 4,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
              const Spacer(),

              // 音名显示
              Text(
                pitch.noteName,
                style: TextStyle(
                  fontSize: 72,
                  fontWeight: FontWeight.w200,
                  color: isInTune ? Colors.green.shade400 : Colors.white,
                ),
              )
                  .animate(target: isInTune ? 1 : 0)
                  .tint(color: Colors.green.shade400),

              if (hasSignal)
                Text(
                  '${pitch.frequency.toStringAsFixed(1)} Hz',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                )
              else
                Text(
                  isListening ? '等待声音输入...' : '点击下方按钮开始',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ),

              const SizedBox(height: 40),

              // 调音指示器
              _TunerGauge(
                cents: pitch.cents,
                isListening: isListening,
                hasSignal: hasSignal,
              ),

              const SizedBox(height: 24),

              // 偏差显示
              if (hasSignal)
                Text(
                  pitch.cents >= 0
                      ? '+${pitch.cents.toStringAsFixed(0)} cents'
                      : '${pitch.cents.toStringAsFixed(0)} cents',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w300,
                    color: isInTune
                        ? Colors.green.shade400
                        : (pitch.cents > 0 ? Colors.red.shade400 : Colors.blue.shade400),
                  ),
                )
              else
                Text(
                  isListening ? '请对着麦克风发出声音' : '',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w300,
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                ),

              const Spacer(),

              // 权限提示
              if (!tunerState.hasPermission && !isListening)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 40),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.amber.shade300, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '需要麦克风权限来检测音高',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.amber.shade200,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 24),

              // 开始/停止按钮
              GestureDetector(
                onTap: () => tunerNotifier.toggleListening(),
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isListening
                          ? [Colors.red.shade400, Colors.red.shade700]
                          : [Colors.blue.shade400, Colors.blue.shade700],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (isListening ? Colors.red : Colors.blue).withValues(alpha: 0.4),
                        blurRadius: 20,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: Icon(
                    isListening ? Icons.mic_off : Icons.mic,
                    size: 48,
                    color: Colors.white,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Text(
                isListening ? '点击停止' : '点击开始调音',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),

              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }

  /// Web 平台不支持调音器的提示界面
  Widget _buildUnsupportedView() {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.mic_off,
                size: 80,
                color: Colors.white.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 24),
              Text(
                'TUNER',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 4,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '调音器功能仅支持移动端',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '请在 iOS 或 Android 设备上使用',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 调音仪表盘
class _TunerGauge extends StatelessWidget {
  final double cents;
  final bool isListening;
  final bool hasSignal;

  const _TunerGauge({
    required this.cents,
    required this.isListening,
    required this.hasSignal,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      height: 140,
      child: CustomPaint(
        painter: _GaugePainter(
          cents: cents,
          isListening: isListening,
          hasSignal: hasSignal,
        ),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double cents;
  final bool isListening;
  final bool hasSignal;

  _GaugePainter({
    required this.cents,
    required this.isListening,
    required this.hasSignal,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2 - 20;

    // 背景弧
    final bgPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      pi,
      pi,
      false,
      bgPaint,
    );

    // 刻度
    final tickPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..strokeWidth = 2;

    for (int i = -5; i <= 5; i++) {
      final angle = pi + (i + 5) / 10 * pi;
      final innerRadius = radius - (i == 0 ? 20 : 10);
      final outerRadius = radius + 5;

      canvas.drawLine(
        Offset(
          center.dx + cos(angle) * innerRadius,
          center.dy + sin(angle) * innerRadius,
        ),
        Offset(
          center.dx + cos(angle) * outerRadius,
          center.dy + sin(angle) * outerRadius,
        ),
        tickPaint,
      );
    }

    // 中心绿色区域
    final greenPaint = Paint()
      ..color = Colors.green.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      pi + 0.45 * pi,
      0.1 * pi,
      false,
      greenPaint,
    );

    // 指针 - 只有在监听且有信号时才显示
    if (isListening && hasSignal) {
      final clampedCents = cents.clamp(-50.0, 50.0);
      final needleAngle = pi + (clampedCents + 50) / 100 * pi;
      final needleLength = radius - 30;

      final isInTune = cents.abs() < 5;
      final needlePaint = Paint()
        ..color = isInTune ? Colors.green : Colors.white
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(
        center,
        Offset(
          center.dx + cos(needleAngle) * needleLength,
          center.dy + sin(needleAngle) * needleLength,
        ),
        needlePaint,
      );

      // 中心点
      canvas.drawCircle(
        center,
        8,
        Paint()..color = isInTune ? Colors.green : Colors.white,
      );
    } else if (isListening) {
      // 监听中但无信号 - 显示灰色中心点
      canvas.drawCircle(
        center,
        6,
        Paint()..color = Colors.white.withValues(alpha: 0.3),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    return oldDelegate.cents != cents ||
        oldDelegate.isListening != isListening ||
        oldDelegate.hasSignal != hasSignal;
  }
}
