import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// 调音器页面
/// 注意: 当前为演示版本，实际音高检测功能待实现
/// TODO: 集成 flutter_audio_capture + pitch_detector_dart 实现真实音高检测
class TunerPage extends StatefulWidget {
  const TunerPage({super.key});

  @override
  State<TunerPage> createState() => _TunerPageState();
}

class _TunerPageState extends State<TunerPage> with SingleTickerProviderStateMixin {
  double _cents = 0; // -50 to +50
  String _note = '--';
  double _frequency = 0;
  bool _isListening = false;
  bool _hasSignal = false; // 是否检测到声音信号

  void _toggleListening() {
    setState(() {
      _isListening = !_isListening;
      if (!_isListening) {
        // 停止监听时重置状态
        _hasSignal = false;
        _note = '--';
        _frequency = 0;
        _cents = 0;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isInTune = _hasSignal && _cents.abs() < 5;

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
              _note,
              style: TextStyle(
                fontSize: 72,
                fontWeight: FontWeight.w200,
                color: isInTune ? Colors.green.shade400 : Colors.white,
              ),
            )
                .animate(target: isInTune ? 1 : 0)
                .tint(color: Colors.green.shade400),

            if (_hasSignal && _frequency > 0)
              Text(
                '${_frequency.toStringAsFixed(1)} Hz',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              )
            else
              Text(
                _isListening ? '等待声音输入...' : '点击下方按钮开始',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
              ),

            const SizedBox(height: 40),

            // 调音指示器
            _TunerGauge(cents: _cents, isListening: _isListening, hasSignal: _hasSignal),

            const SizedBox(height: 24),

            // 偏差显示
            if (_hasSignal)
              Text(
                _cents >= 0 ? '+${_cents.toStringAsFixed(0)} cents' : '${_cents.toStringAsFixed(0)} cents',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w300,
                  color: isInTune
                      ? Colors.green.shade400
                      : (_cents > 0 ? Colors.red.shade400 : Colors.blue.shade400),
                ),
              )
            else
              Text(
                _isListening ? '请对着麦克风发出声音' : '',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w300,
                  color: Colors.white.withValues(alpha: 0.4),
                ),
              ),

            const Spacer(),

            // 功能提示
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
                      '调音器功能开发中，即将支持真实音高检测',
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
              onTap: _toggleListening,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: _isListening
                        ? [Colors.red.shade400, Colors.red.shade700]
                        : [Colors.blue.shade400, Colors.blue.shade700],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (_isListening ? Colors.red : Colors.blue).withValues(alpha: 0.4),
                      blurRadius: 20,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Icon(
                  _isListening ? Icons.mic_off : Icons.mic,
                  size: 48,
                  color: Colors.white,
                ),
              ),
            ),

            const SizedBox(height: 16),

            Text(
              _isListening ? '点击停止' : '点击开始调音',
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
      final needleAngle = pi + (cents + 50) / 100 * pi;
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
