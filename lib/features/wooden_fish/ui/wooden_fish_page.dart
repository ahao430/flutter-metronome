import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../metronome/logic/metronome_providers.dart';

/// 功德计数器 Provider
final meritCountProvider = StateProvider<int>((ref) => 0);

/// 电子木鱼页面
class WoodenFishPage extends ConsumerStatefulWidget {
  const WoodenFishPage({super.key});

  @override
  ConsumerState<WoodenFishPage> createState() => _WoodenFishPageState();
}

class _WoodenFishPageState extends ConsumerState<WoodenFishPage>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  final List<_FloatingText> _floatingTexts = [];
  int _textIdCounter = 0;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _knock() {
    // 播放音效
    ref.read(audioServiceProvider).playWoodenFish();

    // 动画
    _scaleController.forward().then((_) => _scaleController.reverse());

    // 增加功德
    ref.read(meritCountProvider.notifier).state++;

    // 添加飘字
    setState(() {
      _floatingTexts.add(_FloatingText(
        id: _textIdCounter++,
        text: _getRandomMeritText(),
        x: 0.5 + (Random().nextDouble() - 0.5) * 0.3,
      ));
    });

    // 移除旧的飘字
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          if (_floatingTexts.isNotEmpty) {
            _floatingTexts.removeAt(0);
          }
        });
      }
    });
  }

  String _getRandomMeritText() {
    final texts = [
      '功德 +1',
      '善哉善哉',
      '阿弥陀佛',
      '福报 +1',
      '心诚则灵',
      '普度众生',
    ];
    return texts[Random().nextInt(texts.length)];
  }

  @override
  Widget build(BuildContext context) {
    final meritCount = ref.watch(meritCountProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF1A0A00),
      body: Stack(
        children: [
          // 背景装饰
          Positioned.fill(
            child: CustomPaint(
              painter: _BackgroundPainter(),
            ),
          ),

          // 主内容
          SafeArea(
            child: Center(
              child: Column(
                children: [
                const SizedBox(height: 40),
                // 标题
                Text(
                  '电子木鱼',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w300,
                    color: Colors.amber.shade200,
                    letterSpacing: 8,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '功德无量',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.amber.shade100.withValues(alpha: 0.5),
                    letterSpacing: 4,
                  ),
                ),

                const Spacer(),

                // 木鱼
                GestureDetector(
                  onTap: _knock,
                  child: AnimatedBuilder(
                    animation: _scaleAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _scaleAnimation.value,
                        child: child,
                      );
                    },
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Colors.brown.shade600,
                            Colors.brown.shade900,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.amber.withValues(alpha: 0.3),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // 木鱼纹理
                          Icon(
                            Icons.self_improvement,
                            size: 80,
                            color: Colors.amber.shade200.withValues(alpha: 0.8),
                          ),
                          // 点击提示
                          Positioned(
                            bottom: 30,
                            child: Text(
                              '点击敲击',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.amber.shade100.withValues(alpha: 0.5),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const Spacer(),

                // 功德计数
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '累计功德',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.amber.shade100.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$meritCount',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w200,
                          color: Colors.amber.shade200,
                        ),
                      )
                          .animate(
                            onPlay: (controller) => controller.repeat(),
                          )
                          .shimmer(
                            duration: 3000.ms,
                            color: Colors.amber.shade100,
                          ),
                    ],
                  ),
                ),

                const SizedBox(height: 60),
              ],
            ),
          ),
        ),

          // 飘字效果
          ..._floatingTexts.map((ft) => _FloatingTextWidget(
                key: ValueKey(ft.id),
                text: ft.text,
                x: ft.x,
              )),
        ],
      ),
    );
  }
}

class _FloatingText {
  final int id;
  final String text;
  final double x;

  _FloatingText({required this.id, required this.text, required this.x});
}

class _FloatingTextWidget extends StatelessWidget {
  final String text;
  final double x;

  const _FloatingTextWidget({
    super.key,
    required this.text,
    required this.x,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Positioned(
      left: screenWidth * x - 50,
      top: screenHeight * 0.35,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.amber.shade300,
        ),
      )
          .animate()
          .fadeIn(duration: 200.ms)
          .moveY(begin: 0, end: -100, duration: 1200.ms, curve: Curves.easeOut)
          .fadeOut(delay: 800.ms, duration: 400.ms),
    );
  }
}

class _BackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 1.0,
        colors: [
          Colors.brown.shade900.withValues(alpha: 0.3),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width * 0.6,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
