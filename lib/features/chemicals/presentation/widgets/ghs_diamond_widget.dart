import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Authentic United Nations (UN) Globally Harmonized System (GHS) Hazard Diamond.
///
/// Strictly conforms to UN GHS Rev. 9 & Thai Ministry of Industry / DLPW standards:
/// 1. Diamond shape: Square set at a point (rotated 45°).
/// 2. Border: Vivid Red (#DC2626) solid border.
/// 3. Interior: Solid pure White (#FFFFFF).
/// 4. Symbol: Upright Jet-Black (#111827 / #000000) hazard silhouette.
class GhsDiamondWidget extends StatelessWidget {
  final String code;
  final double size;
  final bool showTooltip;
  final VoidCallback? onTap;

  const GhsDiamondWidget({
    super.key,
    required this.code,
    this.size = 32,
    this.showTooltip = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cleanCode = code.toUpperCase().trim();
    final info = _getGhsMetadata(cleanCode);

    Widget diamond = SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        size: Size(size, size),
        painter: GhsDiamondPainter(code: cleanCode),
      ),
    );

    if (onTap != null) {
      diamond = GestureDetector(
        onTap: onTap,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: diamond,
        ),
      );
    }

    if (showTooltip && info != null) {
      diamond = Tooltip(
        message: '${info.code}: ${info.nameTh} (${info.nameEn})\n${info.description}',
        preferBelow: false,
        child: diamond,
      );
    }

    return diamond;
  }

  /// High-resolution PNG generator for printing and PDF generation.
  static Future<Uint8List> renderToPng(String code, {double size = 240}) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, size, size));
    final painter = GhsDiamondPainter(code: code);
    painter.paint(canvas, Size(size, size));
    final picture = recorder.endRecording();
    final img = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }
}

class _GhsMeta {
  final String code;
  final String nameTh;
  final String nameEn;
  final String description;

  const _GhsMeta({
    required this.code,
    required this.nameTh,
    required this.nameEn,
    required this.description,
  });
}

_GhsMeta? _getGhsMetadata(String code) {
  switch (code) {
    case 'GHS01':
      return const _GhsMeta(
        code: 'GHS01',
        nameTh: 'วัตถุระเบิด',
        nameEn: 'Exploding Bomb',
        description: 'สารระเบิดได้ สารที่ทำปฏิกิริยาได้เอง สารอินทรีย์เปอร์ออกไซด์',
      );
    case 'GHS02':
      return const _GhsMeta(
        code: 'GHS02',
        nameTh: 'สารไวไฟ',
        nameEn: 'Flame',
        description: 'ก๊าซ ของเหลว ของแข็งไวไฟ สารที่ติดไฟได้เอง สารที่สัมผัสน้ำแล้วให้ก๊าซไวไฟ',
      );
    case 'GHS03':
      return const _GhsMeta(
        code: 'GHS03',
        nameTh: 'สารออกซิไดซ์',
        nameEn: 'Flame over Circle',
        description: 'ก๊าซ ของเหลว หรือของแข็งออกซิไดซ์ เร่งให้เกิดการลุกไหม้รุนแรง',
      );
    case 'GHS04':
      return const _GhsMeta(
        code: 'GHS04',
        nameTh: 'ก๊าซบรรจุภายใต้ความดัน',
        nameEn: 'Gas Cylinder',
        description: 'ก๊าซอัด ก๊าซเหลว ก๊าซละลายภายใต้ความดัน ก๊าซเหลวอุณหภูมิต่ำยิ่งยวด',
      );
    case 'GHS05':
      return const _GhsMeta(
        code: 'GHS05',
        nameTh: 'สารกัดกร่อน',
        nameEn: 'Corrosion',
        description: 'สารกัดกร่อนโลหะ กัดกร่อนผิวหนัง และทำลายดวงตาอย่างรุนแรง',
      );
    case 'GHS06':
      return const _GhsMeta(
        code: 'GHS06',
        nameTh: 'ความเป็นพิษเฉียบพลันร้ายแรง',
        nameEn: 'Skull and Crossbones',
        description: 'สารพิษเฉียบพลันร้ายแรง (ประเภท ๑-๓) อาจถึงแก่ชีวิตเมื่อสูดดม กลืนกิน หรือสัมผัส',
      );
    case 'GHS07':
      return const _GhsMeta(
        code: 'GHS07',
        nameTh: 'อันตรายต่อสุขภาพ / ระคายเคือง',
        nameEn: 'Exclamation Mark',
        description: 'สารระคายเคืองตา/ผิวหนัง ความเป็นพิษเฉียบพลันระดับต่ำ สารก่อภูมิแพ้ผิวหนัง',
      );
    case 'GHS08':
      return const _GhsMeta(
        code: 'GHS08',
        nameTh: 'อันตรายต่อสุขภาพระยะยาว',
        nameEn: 'Health Hazard',
        description: 'สารก่อมะเร็ง สารก่อการกลายพันธุ์ สารพิษต่อระบบสืบพันธุ์ สารก่อโรคหอบหืด',
      );
    case 'GHS09':
      return const _GhsMeta(
        code: 'GHS09',
        nameTh: 'อันตรายต่อสิ่งแวดล้อม',
        nameEn: 'Environment',
        description: 'ความเป็นพิษเฉียบพลันหรือเรื้อรังต่อระบบนิเวศทางน้ำ',
      );
    default:
      return null;
  }
}

/// CustomPainter rendering international standard UN GHS 45° diamond and silhouettes.
class GhsDiamondPainter extends CustomPainter {
  final String code;

  const GhsDiamondPainter({required this.code});

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double cx = w / 2;
    final double cy = h / 2;

    // Red border thickness is standard ~8% of total width
    final double strokeWidth = math.max(1.8, w * 0.082);
    final double pad = strokeWidth / 2 + (w * 0.02);

    // 1. Draw 45° Diamond Path
    final diamondPath = Path()
      ..moveTo(cx, pad)
      ..lineTo(w - pad, cy)
      ..lineTo(cx, h - pad)
      ..lineTo(pad, cy)
      ..close();

    // 2. Pure White Interior Fill
    final whitePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawPath(diamondPath, whitePaint);

    // 3. Vivid Red GHS Border (#DC2626)
    final redPaint = Paint()
      ..color = const Color(0xFFDC2626)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(diamondPath, redPaint);

    // 4. Draw Upright Black Hazard Silhouette
    final symbolPaint = Paint()
      ..color = const Color(0xFF111827) // Jet-black
      ..style = PaintingStyle.fill;

    final symbolStroke = Paint()
      ..color = const Color(0xFF111827)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.5, w * 0.045)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final cleanCode = code.toUpperCase().trim();
    switch (cleanCode) {
      case 'GHS01':
        _drawExplodingBomb(canvas, cx, cy, w, symbolPaint, symbolStroke);
        break;
      case 'GHS02':
        _drawFlame(canvas, cx, cy, w, symbolPaint);
        break;
      case 'GHS03':
        _drawFlameOverCircle(canvas, cx, cy, w, symbolPaint, symbolStroke);
        break;
      case 'GHS04':
        _drawGasCylinder(canvas, cx, cy, w, symbolPaint, symbolStroke);
        break;
      case 'GHS05':
        _drawCorrosion(canvas, cx, cy, w, symbolPaint, symbolStroke);
        break;
      case 'GHS06':
        _drawSkullAndCrossbones(canvas, cx, cy, w, symbolPaint, symbolStroke);
        break;
      case 'GHS07':
        _drawExclamationMark(canvas, cx, cy, w, symbolPaint);
        break;
      case 'GHS08':
        _drawHealthHazard(canvas, cx, cy, w, symbolPaint, symbolStroke);
        break;
      case 'GHS09':
        _drawEnvironment(canvas, cx, cy, w, symbolPaint, symbolStroke);
        break;
      default:
        // Fallback: GHS Exclamation
        _drawExclamationMark(canvas, cx, cy, w, symbolPaint);
        break;
    }
  }

  // --- GHS01: Exploding Bomb (ระเบิด) ---
  void _drawExplodingBomb(Canvas canvas, double cx, double cy, double s, Paint fill, Paint stroke) {
    // Central sphere
    canvas.drawCircle(Offset(cx, cy + s * 0.04), s * 0.11, fill);

    // Fragment shards flying out
    final p1 = Path()
      ..moveTo(cx - s * 0.08, cy - s * 0.12)
      ..lineTo(cx - s * 0.16, cy - s * 0.18)
      ..lineTo(cx - s * 0.11, cy - s * 0.09)
      ..close();
    canvas.drawPath(p1, fill);

    final p2 = Path()
      ..moveTo(cx + s * 0.08, cy - s * 0.13)
      ..lineTo(cx + s * 0.17, cy - s * 0.19)
      ..lineTo(cx + s * 0.13, cy - s * 0.08)
      ..close();
    canvas.drawPath(p2, fill);

    final p3 = Path()
      ..moveTo(cx - s * 0.18, cy + s * 0.02)
      ..lineTo(cx - s * 0.24, cy + s * 0.08)
      ..lineTo(cx - s * 0.15, cy + s * 0.10)
      ..close();
    canvas.drawPath(p3, fill);

    final p4 = Path()
      ..moveTo(cx + s * 0.16, cy + s * 0.03)
      ..lineTo(cx + s * 0.23, cy + s * 0.09)
      ..lineTo(cx + s * 0.14, cy + s * 0.11)
      ..close();
    canvas.drawPath(p4, fill);

    // Explosion blast beams
    canvas.drawLine(Offset(cx, cy - s * 0.10), Offset(cx, cy - s * 0.24), stroke);
    canvas.drawLine(Offset(cx - s * 0.12, cy - s * 0.06), Offset(cx - s * 0.22, cy - s * 0.14), stroke);
    canvas.drawLine(Offset(cx + s * 0.12, cy - s * 0.06), Offset(cx + s * 0.22, cy - s * 0.14), stroke);
  }

  // --- GHS02: Flame (สารไวไฟ) ---
  void _drawFlame(Canvas canvas, double cx, double cy, double s, Paint fill) {
    // Outer flame silhouette
    final p = Path();
    p.moveTo(cx - s * 0.20, cy + s * 0.22);
    // Base horizontal bar
    p.lineTo(cx + s * 0.20, cy + s * 0.22);
    p.lineTo(cx + s * 0.20, cy + s * 0.18);
    // Right flame tongue
    p.quadraticBezierTo(cx + s * 0.24, cy + s * 0.04, cx + s * 0.16, cy - s * 0.08);
    p.quadraticBezierTo(cx + s * 0.12, cy + s * 0.02, cx + s * 0.09, cy - s * 0.06);
    // Central tall flame tongue
    p.quadraticBezierTo(cx + s * 0.14, cy - s * 0.22, cx, cy - s * 0.28);
    p.quadraticBezierTo(cx - s * 0.06, cy - s * 0.18, cx - s * 0.06, cy - s * 0.10);
    // Left flame tongue
    p.quadraticBezierTo(cx - s * 0.18, cy - s * 0.04, cx - s * 0.20, cy + s * 0.18);
    p.close();

    // Inner hollow flame cutout
    final inner = Path();
    inner.moveTo(cx - s * 0.07, cy + s * 0.16);
    inner.quadraticBezierTo(cx - s * 0.08, cy + s * 0.06, cx - s * 0.02, cy - s * 0.02);
    inner.quadraticBezierTo(cx + s * 0.06, cy + s * 0.04, cx + s * 0.07, cy + s * 0.16);
    inner.close();

    final combined = Path.combine(PathOperation.difference, p, inner);
    canvas.drawPath(combined, fill);
  }

  // --- GHS03: Flame Over Circle (สารออกซิไดซ์) ---
  void _drawFlameOverCircle(Canvas canvas, double cx, double cy, double s, Paint fill, Paint stroke) {
    // Lower circle ring
    final circleCenter = Offset(cx, cy + s * 0.09);
    final circleRadius = s * 0.13;
    final ringPaint = Paint()
      ..color = const Color(0xFF111827)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(2.0, s * 0.052);
    canvas.drawCircle(circleCenter, circleRadius, ringPaint);

    // Flames rising from top of circle
    final p = Path();
    p.moveTo(cx - s * 0.11, cy + s * 0.02);
    p.quadraticBezierTo(cx - s * 0.16, cy - s * 0.08, cx - s * 0.08, cy - s * 0.14);
    p.quadraticBezierTo(cx - s * 0.06, cy - s * 0.06, cx, cy - s * 0.26);
    p.quadraticBezierTo(cx + s * 0.05, cy - s * 0.08, cx + s * 0.10, cy - s * 0.14);
    p.quadraticBezierTo(cx + s * 0.15, cy - s * 0.06, cx + s * 0.11, cy + s * 0.02);
    p.close();
    canvas.drawPath(p, fill);
  }

  // --- GHS04: Gas Cylinder (ก๊าซภายใต้ความดัน) ---
  void _drawGasCylinder(Canvas canvas, double cx, double cy, double s, Paint fill, Paint stroke) {
    // Main vertical cylinder body
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy + s * 0.06), width: s * 0.18, height: s * 0.36),
      Radius.circular(s * 0.04),
    );
    canvas.drawRRect(bodyRect, fill);

    // Top dome
    final dome = Path()
      ..moveTo(cx - s * 0.09, cy - s * 0.11)
      ..quadraticBezierTo(cx, cy - s * 0.20, cx + s * 0.09, cy - s * 0.11)
      ..close();
    canvas.drawPath(dome, fill);

    // Valve stem & cap
    final valveStem = Rect.fromCenter(center: Offset(cx, cy - s * 0.18), width: s * 0.06, height: s * 0.08);
    canvas.drawRect(valveStem, fill);

    // Valve handle
    final valveHandle = Rect.fromCenter(center: Offset(cx, cy - s * 0.22), width: s * 0.13, height: s * 0.032);
    canvas.drawRect(valveHandle, fill);

    // Bottom base foot ring
    final baseRect = Rect.fromCenter(center: Offset(cx, cy + s * 0.24), width: s * 0.20, height: s * 0.035);
    canvas.drawRect(baseRect, fill);
  }

  // --- GHS05: Corrosion (สารกัดกร่อน) ---
  void _drawCorrosion(Canvas canvas, double cx, double cy, double s, Paint fill, Paint stroke) {
    // Left test tube tilted right
    canvas.save();
    canvas.translate(cx - s * 0.12, cy - s * 0.12);
    canvas.rotate(0.65);
    final tube1 = RRect.fromRectAndRadius(
      Rect.fromLTWH(-s * 0.04, -s * 0.10, s * 0.08, s * 0.18),
      Radius.circular(s * 0.03),
    );
    canvas.drawRRect(tube1, fill);
    canvas.restore();

    // Right test tube tilted left
    canvas.save();
    canvas.translate(cx + s * 0.12, cy - s * 0.12);
    canvas.rotate(-0.65);
    final tube2 = RRect.fromRectAndRadius(
      Rect.fromLTWH(-s * 0.04, -s * 0.10, s * 0.08, s * 0.18),
      Radius.circular(s * 0.03),
    );
    canvas.drawRRect(tube2, fill);
    canvas.restore();

    // Falling liquid drops
    canvas.drawCircle(Offset(cx - s * 0.08, cy + s * 0.01), s * 0.022, fill);
    canvas.drawCircle(Offset(cx + s * 0.08, cy + s * 0.01), s * 0.022, fill);

    // Surface on left (corroding metal bar)
    final bar = Path()
      ..moveTo(cx - s * 0.24, cy + s * 0.14)
      ..lineTo(cx - s * 0.10, cy + s * 0.14)
      ..quadraticBezierTo(cx - s * 0.07, cy + s * 0.18, cx - s * 0.04, cy + s * 0.14)
      ..lineTo(cx - s * 0.01, cy + s * 0.14)
      ..lineTo(cx - s * 0.01, cy + s * 0.22)
      ..lineTo(cx - s * 0.24, cy + s * 0.22)
      ..close();
    canvas.drawPath(bar, fill);

    // Surface on right (human hand/flesh being corroded)
    final hand = Path()
      ..moveTo(cx + s * 0.01, cy + s * 0.15)
      ..lineTo(cx + s * 0.07, cy + s * 0.15)
      ..quadraticBezierTo(cx + s * 0.10, cy + s * 0.20, cx + s * 0.13, cy + s * 0.15)
      ..lineTo(cx + s * 0.24, cy + s * 0.15)
      ..lineTo(cx + s * 0.24, cy + s * 0.22)
      ..lineTo(cx + s * 0.01, cy + s * 0.22)
      ..close();
    canvas.drawPath(hand, fill);
  }

  // --- GHS06: Skull and Crossbones (ความเป็นพิษเฉียบพลันร้ายแรง) ---
  void _drawSkullAndCrossbones(Canvas canvas, double cx, double cy, double s, Paint fill, Paint stroke) {
    // Crossed diagonal bones behind
    final boneStroke = Paint()
      ..color = const Color(0xFF111827)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.8, s * 0.045)
      ..strokeCap = StrokeCap.round;

    // Diagonal 1
    canvas.drawLine(Offset(cx - s * 0.19, cy - s * 0.15), Offset(cx + s * 0.19, cy + s * 0.19), boneStroke);
    // Diagonal 2
    canvas.drawLine(Offset(cx + s * 0.19, cy - s * 0.15), Offset(cx - s * 0.19, cy + s * 0.19), boneStroke);

    // Bone knobby joints
    canvas.drawCircle(Offset(cx - s * 0.20, cy - s * 0.15), s * 0.026, fill);
    canvas.drawCircle(Offset(cx + s * 0.20, cy - s * 0.15), s * 0.026, fill);
    canvas.drawCircle(Offset(cx - s * 0.20, cy + s * 0.19), s * 0.026, fill);
    canvas.drawCircle(Offset(cx + s * 0.20, cy + s * 0.19), s * 0.026, fill);

    // Skull cranium
    final skull = Path()
      ..addArc(Rect.fromCircle(center: Offset(cx, cy - s * 0.05), radius: s * 0.14), -math.pi, math.pi)
      ..lineTo(cx + s * 0.08, cy + s * 0.07)
      ..lineTo(cx - s * 0.08, cy + s * 0.07)
      ..close();
    canvas.drawPath(skull, fill);

    // Eye sockets (white cutout)
    final eyePaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(cx - s * 0.05, cy - s * 0.04), s * 0.033, eyePaint);
    canvas.drawCircle(Offset(cx + s * 0.05, cy - s * 0.04), s * 0.033, eyePaint);

    // Nose triangular cutout
    final nose = Path()
      ..moveTo(cx, cy - s * 0.01)
      ..lineTo(cx + s * 0.02, cy + s * 0.02)
      ..lineTo(cx - s * 0.02, cy + s * 0.02)
      ..close();
    canvas.drawPath(nose, eyePaint);

    // Teeth slits
    final teethPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.0, s * 0.022);
    canvas.drawLine(Offset(cx - s * 0.04, cy + s * 0.045), Offset(cx - s * 0.04, cy + s * 0.07), teethPaint);
    canvas.drawLine(Offset(cx, cy + s * 0.045), Offset(cx, cy + s * 0.07), teethPaint);
    canvas.drawLine(Offset(cx + s * 0.04, cy + s * 0.045), Offset(cx + s * 0.04, cy + s * 0.07), teethPaint);
  }

  // --- GHS07: Exclamation Mark (ระวัง / ระคายเคือง) ---
  void _drawExclamationMark(Canvas canvas, double cx, double cy, double s, Paint fill) {
    // Top tapering bar
    final bar = Path()
      ..moveTo(cx - s * 0.05, cy - s * 0.22)
      ..lineTo(cx + s * 0.05, cy - s * 0.22)
      ..lineTo(cx + s * 0.035, cy + s * 0.06)
      ..lineTo(cx - s * 0.035, cy + s * 0.06)
      ..close();
    canvas.drawPath(bar, fill);

    // Bottom dot
    canvas.drawCircle(Offset(cx, cy + s * 0.17), s * 0.045, fill);
  }

  // --- GHS08: Health Hazard (อันตรายต่อสุขภาพ / สารก่อมะเร็ง) ---
  void _drawHealthHazard(Canvas canvas, double cx, double cy, double s, Paint fill, Paint stroke) {
    // Head
    canvas.drawCircle(Offset(cx, cy - s * 0.18), s * 0.07, fill);

    // Torso & shoulders silhouette
    final torso = Path()
      ..moveTo(cx - s * 0.04, cy - s * 0.11)
      ..lineTo(cx - s * 0.18, cy - s * 0.02)
      ..lineTo(cx - s * 0.20, cy + s * 0.22)
      ..lineTo(cx + s * 0.20, cy + s * 0.22)
      ..lineTo(cx + s * 0.18, cy - s * 0.02)
      ..lineTo(cx + s * 0.04, cy - s * 0.11)
      ..close();
    canvas.drawPath(torso, fill);

    // White 6-pointed star / burst cutout on chest
    final starPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final star = Path();
    final starCenter = Offset(cx, cy + s * 0.07);
    const int points = 6;
    final double rOuter = s * 0.08;
    final double rInner = s * 0.032;

    for (int i = 0; i < points * 2; i++) {
      final double r = i.isEven ? rOuter : rInner;
      final double angle = (i * math.pi / points) - (math.pi / 2);
      final double x = starCenter.dx + r * math.cos(angle);
      final double y = starCenter.dy + r * math.sin(angle);
      if (i == 0) {
        star.moveTo(x, y);
      } else {
        star.lineTo(x, y);
      }
    }
    star.close();
    canvas.drawPath(star, starPaint);
  }

  // --- GHS09: Environment (อันตรายต่อสิ่งแวดล้อม) ---
  void _drawEnvironment(Canvas canvas, double cx, double cy, double s, Paint fill, Paint stroke) {
    // Bare tree on the right
    final tree = Path();
    // Trunk
    tree.moveTo(cx + s * 0.10, cy + s * 0.12);
    tree.lineTo(cx + s * 0.14, cy - s * 0.08);
    // Branches
    tree.lineTo(cx + s * 0.08, cy - s * 0.16);
    tree.moveTo(cx + s * 0.14, cy - s * 0.08);
    tree.lineTo(cx + s * 0.17, cy - s * 0.18);
    tree.moveTo(cx + s * 0.14, cy - s * 0.08);
    tree.lineTo(cx + s * 0.22, cy - s * 0.12);
    canvas.drawPath(tree, stroke);

    // Shore bank
    final shore = Path()
      ..moveTo(cx + s * 0.04, cy + s * 0.13)
      ..lineTo(cx + s * 0.22, cy + s * 0.13)
      ..lineTo(cx + s * 0.22, cy + s * 0.20)
      ..lineTo(cx + s * 0.04, cy + s * 0.20)
      ..close();
    canvas.drawPath(shore, fill);

    // Dead fish floating belly up on left
    final fish = Path()
      ..moveTo(cx - s * 0.20, cy + s * 0.06)
      ..quadraticBezierTo(cx - s * 0.11, cy + s * 0.01, cx - s * 0.04, cy + s * 0.06)
      ..quadraticBezierTo(cx - s * 0.11, cy + s * 0.11, cx - s * 0.20, cy + s * 0.06)
      ..close();
    canvas.drawPath(fish, fill);

    // Fish tail
    final tail = Path()
      ..moveTo(cx - s * 0.20, cy + s * 0.06)
      ..lineTo(cx - s * 0.24, cy + s * 0.02)
      ..lineTo(cx - s * 0.24, cy + s * 0.10)
      ..close();
    canvas.drawPath(tail, fill);

    // Water wave lines
    final waterStroke = Paint()
      ..color = const Color(0xFF111827)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.0, s * 0.025);

    final wave = Path()
      ..moveTo(cx - s * 0.22, cy + s * 0.15)
      ..quadraticBezierTo(cx - s * 0.14, cy + s * 0.12, cx - s * 0.06, cy + s * 0.15)
      ..moveTo(cx - s * 0.20, cy + s * 0.19)
      ..quadraticBezierTo(cx - s * 0.12, cy + s * 0.16, cx - s * 0.04, cy + s * 0.19);
    canvas.drawPath(wave, waterStroke);
  }

  @override
  bool shouldRepaint(covariant GhsDiamondPainter oldDelegate) {
    return oldDelegate.code != code;
  }
}
