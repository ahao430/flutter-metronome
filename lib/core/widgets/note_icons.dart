import 'package:flutter/material.dart';
import '../models/beat_rhythm.dart';

/// 音符图标绘制器
class NoteIconPainter extends CustomPainter {
  final int noteCount; // 1, 2, 3, 4
  final int beamCount; // 1 = 八分, 2 = 十六分
  final bool isTriplet; // 是否三连音
  final bool isSwing;   // 是否 Swing
  final Color color;

  NoteIconPainter({
    required this.noteCount,
    this.beamCount = 1,
    this.isTriplet = false,
    this.isSwing = false,
    this.color = Colors.white,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // 计算尺寸
    final noteHeadWidth = size.width / (noteCount + 0.5);
    final noteHeadHeight = noteHeadWidth * 0.7;
    final stemHeight = size.height * 0.55;
    final beamHeight = size.height * 0.08;
    final spacing = (size.width - noteHeadWidth * noteCount) / (noteCount + 1);

    // 绘制每个音符
    for (int i = 0; i < noteCount; i++) {
      final x = spacing + i * (noteHeadWidth + spacing) + noteHeadWidth / 2;
      final y = size.height - noteHeadHeight / 2 - 2;

      // 符头 (椭圆，稍微倾斜)
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(-0.3); // 轻微倾斜
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset.zero,
          width: noteHeadWidth,
          height: noteHeadHeight,
        ),
        paint,
      );
      canvas.restore();

      // 符干 (从符头右侧向上)
      if (noteCount > 1 || beamCount > 0) {
        final stemX = x + noteHeadWidth * 0.35;
        final stemBottom = y - noteHeadHeight * 0.3;
        final stemTop = size.height - stemHeight - noteHeadHeight;

        canvas.drawLine(
          Offset(stemX, stemBottom),
          Offset(stemX, stemTop),
          strokePaint..strokeWidth = 2,
        );
      }
    }

    // 绘制符杠 (Beams)
    if (noteCount > 1) {
      final firstStemX = spacing + noteHeadWidth * 0.35 + noteHeadWidth / 2;
      final lastStemX = spacing + (noteCount - 1) * (noteHeadWidth + spacing) +
          noteHeadWidth / 2 + noteHeadWidth * 0.35;
      final beamY = size.height - stemHeight - noteHeadHeight;

      // 第一条符杠 (连接所有音符)
      final beamRect = RRect.fromRectAndRadius(
        Rect.fromLTRB(firstStemX - 1, beamY, lastStemX + 1, beamY + beamHeight),
        const Radius.circular(1),
      );
      canvas.drawRRect(beamRect, paint);

      // 第二条符杠 (十六分音符)
      if (beamCount >= 2) {
        final beam2Rect = RRect.fromRectAndRadius(
          Rect.fromLTRB(
            firstStemX - 1,
            beamY + beamHeight + 3,
            lastStemX + 1,
            beamY + beamHeight * 2 + 3,
          ),
          const Radius.circular(1),
        );
        canvas.drawRRect(beam2Rect, paint);
      }
    }

    // 三连音标记 "3"
    if (isTriplet && noteCount == 3) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: '3',
          style: TextStyle(
            color: color,
            fontSize: size.height * 0.22,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          (size.width - textPainter.width) / 2,
          0,
        ),
      );
    }

    // Swing 标记
    if (isSwing && noteCount == 2) {
      // 绘制 swing 等式: ♫ = ♪³♪
      final textPainter = TextPainter(
        text: TextSpan(
          text: 'swing',
          style: TextStyle(
            color: color.withValues(alpha: 0.7),
            fontSize: size.height * 0.18,
            fontStyle: FontStyle.italic,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset((size.width - textPainter.width) / 2, 0),
      );
    }
  }

  @override
  bool shouldRepaint(covariant NoteIconPainter oldDelegate) {
    return oldDelegate.noteCount != noteCount ||
        oldDelegate.beamCount != beamCount ||
        oldDelegate.isTriplet != isTriplet ||
        oldDelegate.color != color;
  }
}

/// 四分音符图标 (一拍一下)
class QuarterNoteIcon extends StatelessWidget {
  final double size;
  final Color color;

  const QuarterNoteIcon({super.key, this.size = 24, this.color = Colors.white});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size * 0.6, size),
      painter: _QuarterNotePainter(color: color),
    );
  }
}

class _QuarterNotePainter extends CustomPainter {
  final Color color;

  _QuarterNotePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // 符头
    final headWidth = size.width * 0.9;
    final headHeight = headWidth * 0.7;
    final headX = size.width * 0.4;
    final headY = size.height - headHeight / 2 - 2;

    canvas.save();
    canvas.translate(headX, headY);
    canvas.rotate(-0.3);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: headWidth, height: headHeight),
      paint,
    );
    canvas.restore();

    // 符干
    final stemX = headX + headWidth * 0.35;
    canvas.drawLine(
      Offset(stemX, headY - headHeight * 0.3),
      Offset(stemX, size.height * 0.15),
      strokePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 八分音符图标 (一拍两下)
class EighthNotesIcon extends StatelessWidget {
  final double size;
  final Color color;
  final bool isSwing;

  const EighthNotesIcon({
    super.key,
    this.size = 24,
    this.color = Colors.white,
    this.isSwing = false,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: NoteIconPainter(
        noteCount: 2,
        beamCount: 1,
        isSwing: isSwing,
        color: color,
      ),
    );
  }
}

/// 三连音图标 (一拍三下)
class TripletIcon extends StatelessWidget {
  final double size;
  final Color color;

  const TripletIcon({super.key, this.size = 24, this.color = Colors.white});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size * 1.2, size),
      painter: NoteIconPainter(
        noteCount: 3,
        beamCount: 1,
        isTriplet: true,
        color: color,
      ),
    );
  }
}

/// 十六分音符图标 (一拍四下)
class SixteenthNotesIcon extends StatelessWidget {
  final double size;
  final Color color;

  const SixteenthNotesIcon({super.key, this.size = 24, this.color = Colors.white});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size * 1.4, size),
      painter: NoteIconPainter(
        noteCount: 4,
        beamCount: 2,
        color: color,
      ),
    );
  }
}

/// 获取细分类型对应的图标 Widget
Widget getSubdivisionIcon(int divisor, {double size = 28, Color color = Colors.white}) {
  return switch (divisor) {
    1 => QuarterNoteIcon(size: size, color: color),
    2 => EighthNotesIcon(size: size, color: color),
    3 => TripletIcon(size: size, color: color),
    4 => SixteenthNotesIcon(size: size, color: color),
    _ => QuarterNoteIcon(size: size, color: color),
  };
}

/// 根据 BeatRhythm 获取对应的图标
Widget getBeatRhythmIcon(BeatRhythm rhythm, {double size = 28, Color color = Colors.white}) {
  return switch (rhythm) {
    BeatRhythm.quarter => QuarterNoteIcon(size: size, color: color),
    BeatRhythm.eighths => EighthNotesIcon(size: size, color: color),
    BeatRhythm.swing => EighthNotesIcon(size: size, color: color, isSwing: true),
    BeatRhythm.triplets => TripletIcon(size: size, color: color),
    BeatRhythm.sixteenths => SixteenthNotesIcon(size: size, color: color),
    BeatRhythm.gallop => GallopNoteIcon(size: size, color: color),
    BeatRhythm.reverseGallop => ReverseGallopNoteIcon(size: size, color: color),
  };
}

/// 前八后十六 (Gallop) 图标
/// 结构: 三个符头，顶梁连接全部，底梁只连接后两个
class GallopNoteIcon extends StatelessWidget {
  final double size;
  final Color color;

  const GallopNoteIcon({super.key, this.size = 24, this.color = Colors.white});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size * 1.2, size),
      painter: _GallopNotePainter(color: color, isReverse: false),
    );
  }
}

/// 前十六后八 (Reverse Gallop) 图标
/// 结构: 三个符头，顶梁连接全部，底梁只连接前两个
class ReverseGallopNoteIcon extends StatelessWidget {
  final double size;
  final Color color;

  const ReverseGallopNoteIcon({super.key, this.size = 24, this.color = Colors.white});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size * 1.2, size),
      painter: _GallopNotePainter(color: color, isReverse: true),
    );
  }
}

class _GallopNotePainter extends CustomPainter {
  final Color color;
  final bool isReverse; // false = 前八后十六, true = 前十六后八

  _GallopNotePainter({required this.color, required this.isReverse});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    const noteCount = 3;
    final noteHeadWidth = size.width / (noteCount + 0.8);
    final noteHeadHeight = noteHeadWidth * 0.7;
    final stemHeight = size.height * 0.55;
    final beamHeight = size.height * 0.08;
    final spacing = (size.width - noteHeadWidth * noteCount) / (noteCount + 1);

    // 计算符干位置
    final stemXPositions = <double>[];

    // 绘制三个音符
    for (int i = 0; i < noteCount; i++) {
      final x = spacing + i * (noteHeadWidth + spacing) + noteHeadWidth / 2;
      final y = size.height - noteHeadHeight / 2 - 2;

      // 符头 (椭圆，稍微倾斜)
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(-0.3);
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: noteHeadWidth, height: noteHeadHeight),
        paint,
      );
      canvas.restore();

      // 符干
      final stemX = x + noteHeadWidth * 0.35;
      stemXPositions.add(stemX);
      final stemBottom = y - noteHeadHeight * 0.3;
      final stemTop = size.height - stemHeight - noteHeadHeight;

      canvas.drawLine(
        Offset(stemX, stemBottom),
        Offset(stemX, stemTop),
        strokePaint..strokeWidth = 2,
      );
    }

    // 第一条符杠 (顶梁 - 连接所有三根符干)
    final beamY = size.height - stemHeight - noteHeadHeight;
    final topBeamRect = RRect.fromRectAndRadius(
      Rect.fromLTRB(stemXPositions[0] - 1, beamY, stemXPositions[2] + 1, beamY + beamHeight),
      const Radius.circular(1),
    );
    canvas.drawRRect(topBeamRect, paint);

    // 第二条符杠 (底梁 - 只连接其中两个)
    if (isReverse) {
      // 前十六后八: 底梁连接第1根和第2根
      final bottomBeamRect = RRect.fromRectAndRadius(
        Rect.fromLTRB(
          stemXPositions[0] - 1,
          beamY + beamHeight + 3,
          stemXPositions[1] + 1,
          beamY + beamHeight * 2 + 3,
        ),
        const Radius.circular(1),
      );
      canvas.drawRRect(bottomBeamRect, paint);
    } else {
      // 前八后十六: 底梁连接第2根和第3根
      final bottomBeamRect = RRect.fromRectAndRadius(
        Rect.fromLTRB(
          stemXPositions[1] - 1,
          beamY + beamHeight + 3,
          stemXPositions[2] + 1,
          beamY + beamHeight * 2 + 3,
        ),
        const Radius.circular(1),
      );
      canvas.drawRRect(bottomBeamRect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GallopNotePainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.isReverse != isReverse;
  }
}
