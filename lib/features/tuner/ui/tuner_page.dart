import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// 调音器页面 (基础版本)
class TunerPage extends StatefulWidget {
  const TunerPage({super.key});

  @override
  State<TunerPage> createState() => _TunerPageState();
}

class _TunerPageState extends State<TunerPage> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  double _cents = 0; // -50 to +50
  String _note = 'A4';
  double _frequency = 440.0;
  bool _isListening = false;

  final List<String> _notes = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _toggleListening() {
    setState(() {
      _isListening = !_isListening;
    });

    if (_isListening) {
      _simulatePitchDetection();
    }
  }

  // 模拟音高检测（实际应使用 flutter_audio_capture + pitch_detector_dart）
  void _simulatePitchDetection() {
    if (!_isListening) return;

    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted || !_isListening) return;

      setState(() {
        // 模拟随机偏移
        _cents = (Random().nextDouble() - 0.5) * 60;
        final noteIndex = Random().nextInt(12);
        final octave = 3 + Random().nextInt(3);
        _note = '${_notes[noteIndex]}$octave';
        _frequency = 440.0 * pow(2, (noteIndex - 9) / 12.0 + (octave - 4)).toDouble();
      });

      _simulatePitchDetection();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isInTune = _cents.abs() < 5;

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

            Text(
              '${_frequency.toStringAsFixed(1)} Hz',
              style: TextStyle(
                fontSize: 18,
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ),

            const SizedBox(height: 40),

            // 调音指示器
            _TunerGauge(cents: _cents, isListening: _isListening),

            const SizedBox(height: 24),

            // 偏差显示
            Text(
              _cents >= 0 ? '+${_cents.toStringAsFixed(0)} cents' : '${_cents.toStringAsFixed(0)} cents',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w300,
                color: isInTune
                    ? Colors.green.shade400
                    : (_cents > 0 ? Colors.red.shade400 : Colors.blue.shade400),
              ),
            ),

            const Spacer(),

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
              _isListening ? '正在监听...' : '点击开始调音',
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

  const _TunerGauge({required this.cents, required this.isListening});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      height: 140,
      child: CustomPaint(
        painter: _GaugePainter(cents: cents, isListening: isListening),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double cents;
  final bool isListening;

  _GaugePainter({required this.cents, required this.isListening});

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

    if (!isListening) return;

    // 指针
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
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    return oldDelegate.cents != cents || oldDelegate.isListening != isListening;
  }
}
