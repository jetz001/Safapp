import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Interactive and Display Widget for NFPA 704 Standard "Fire Diamond".
/// Standard 4-color hazard identification system:
/// - Top (Red): Flammability (0-4)
/// - Left (Blue): Health (0-4)
/// - Right (Yellow): Instability / Reactivity (0-4)
/// - Bottom (White): Special Hazard (W, OX, SA, COR, BIO, RAD)
class NfpaDiamondWidget extends StatelessWidget {
  final int health; // 0 - 4
  final int flammability; // 0 - 4
  final int instability; // 0 - 4
  final String? special; // '', 'W', 'OX', 'SA', 'COR', 'BIO', 'RAD'
  final double size;
  final bool isInteractive;
  final bool editable;
  final Function(int health, int flammability, int instability, String special)? onChanged;

  const NfpaDiamondWidget({
    super.key,
    this.health = 0,
    this.flammability = 0,
    this.instability = 0,
    this.special,
    this.size = 110,
    this.isInteractive = false,
    this.editable = false,
    this.onChanged,
  });

  /// High-resolution PNG generator for printing and PDF generation.
  static Future<Uint8List> renderToPng({
    int health = 0,
    int flammability = 0,
    int instability = 0,
    String? special,
    double size = 200,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, size, size));
    final painter = _NfpaDiamondPainter(
      health: health,
      flammability: flammability,
      instability: instability,
      special: special ?? '',
    );
    painter.paint(canvas, Size(size, size));
    final picture = recorder.endRecording();
    final img = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  void _showEditDialog(BuildContext context) {
    int h = health;
    int f = flammability;
    int i = instability;
    String s = special ?? '';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDlgState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Row(
                children: [
                  Icon(Icons.crop_rotate_rounded, color: Color(0xFF1E293B)),
                  SizedBox(width: 10),
                  Text('กำหนดระดับอันตราย NFPA 704 Diamond', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Preview Diamond
                    Center(
                      child: NfpaDiamondWidget(
                        health: h,
                        flammability: f,
                        instability: i,
                        special: s,
                        size: 130,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),

                    // Health (0 - 4)
                    _buildSliderRow(
                      label: 'สุขภาพ (Health - สีน้ำเงิน)',
                      value: h,
                      activeColor: const Color(0xFF3B82F6),
                      description: _getHealthDesc(h),
                      onChanged: (val) => setDlgState(() => h = val),
                    ),

                    // Flammability (0 - 4)
                    _buildSliderRow(
                      label: 'ความไวไฟ (Flammability - สีแดง)',
                      value: f,
                      activeColor: const Color(0xFFEF4444),
                      description: _getFlammabilityDesc(f),
                      onChanged: (val) => setDlgState(() => f = val),
                    ),

                    // Instability (0 - 4)
                    _buildSliderRow(
                      label: 'ความไม่เสถียร (Instability - สีเหลือง)',
                      value: i,
                      activeColor: const Color(0xFFF59E0B),
                      description: _getInstabilityDesc(i),
                      onChanged: (val) => setDlgState(() => i = val),
                    ),

                    const SizedBox(height: 8),
                    // Special Hazard (Dropdown)
                    Row(
                      children: [
                        const SizedBox(
                          width: 150,
                          child: Text('อันตรายพิเศษ (Special):', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        ),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: s.isEmpty ? '' : s,
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            items: const [
                              DropdownMenuItem(value: '', child: Text('ไม่มีระบุ (-)')),
                              DropdownMenuItem(value: 'W', child: Text('W\u0336 - ทำปฏิกิริยารุนแรงกับน้ำ')),
                              DropdownMenuItem(value: 'OX', child: Text('OX - สารออกซิไดเซอร์แรง')),
                              DropdownMenuItem(value: 'SA', child: Text('SA - ก๊าซที่ทำให้ขาดอากาศหายใจอย่างง่าย')),
                              DropdownMenuItem(value: 'COR', child: Text('COR - สารกัดกร่อน (Corrosive)')),
                              DropdownMenuItem(value: 'BIO', child: Text('BIO - อันตรายทางชีวภาพ (Biohazard)')),
                              DropdownMenuItem(value: 'RAD', child: Text('RAD - สารกัมมันตรังสี (Radiation)')),
                            ],
                            onChanged: (val) => setDlgState(() => s = val ?? ''),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (onChanged != null) {
                      onChanged!(h, f, i, s);
                    }
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('บันทึกระดับ NFPA'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSliderRow({
    required String label,
    required int value,
    required Color activeColor,
    required String description,
    required ValueChanged<int> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: activeColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                child: Text('ระดับ $value', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: activeColor)),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: activeColor,
              thumbColor: activeColor,
              inactiveTrackColor: Colors.grey.shade200,
              trackHeight: 4,
            ),
            child: Slider(
              value: value.toDouble(),
              min: 0,
              max: 4,
              divisions: 4,
              onChanged: (val) => onChanged(val.toInt()),
            ),
          ),
          Text(description, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  String _getHealthDesc(int val) {
    switch (val) {
      case 4:
        return 'ระดับ 4: อันตรายถึงชีวิต (Fatal) สัมผัสเพียงเล็กน้อยทำให้เสียชีวิตได้';
      case 3:
        return 'ระดับ 3: อันตรายร้ายแรงมาก อาจทำให้เกิดความเสียหายถาวรหรือเรื้อรัง';
      case 2:
        return 'ระดับ 2: อันตรายปานกลาง อาจทำให้ไร้ความสามารถชั่วคราว';
      case 1:
        return 'ระดับ 1: อันตรายเล็กน้อย อาจทำให้ระคายเคืองแต่ไม่มีผลถาวร';
      default:
        return 'ระดับ 0: ปลอดภัย ไม่เป็นอันตรายต่อสุขภาพแม้ในสภาวะไฟไหม้';
    }
  }

  String _getFlammabilityDesc(int val) {
    switch (val) {
      case 4:
        return 'ระดับ 4: ไวไฟสูงยิ่งยวด จุดวาบไฟต่ำกว่า 23°C และจุดเดือดต่ำกว่า 38°C';
      case 3:
        return 'ระดับ 3: ไวไฟ ติดไฟได้ง่ายในอุณหภูมิปกติ จุดวาบไฟต่ำกว่า 38°C';
      case 2:
        return 'ระดับ 2: ต้องได้รับความร้อนปานกลางจึงติดไฟ จุดวาบไฟ 38°C - 93°C';
      case 1:
        return 'ระดับ 1: ต้องได้รับความร้อนสูงมากจึงติดไฟ จุดวาบไฟสูงกว่า 93°C';
      default:
        return 'ระดับ 0: ไม่ติดไฟ ทนความร้อนสูง';
    }
  }

  String _getInstabilityDesc(int val) {
    switch (val) {
      case 4:
        return 'ระดับ 4: ระเบิดได้เองในอุณหภูมิและความดันปกติ';
      case 3:
        return 'ระดับ 3: ระเบิดได้เมื่อได้รับความร้อนสูงหรือแรงกระแทกรุนแรง';
      case 2:
        return 'ระดับ 2: เกิดปฏิกิริยารุนแรงเมื่อสัมผัสน้ำหรือความร้อนสูง';
      case 1:
        return 'ระดับ 1: ไม่เสถียรเมื่อได้รับความร้อนสูง';
      default:
        return 'ระดับ 0: เสถียร คงที่ แม้ในสภาวะไฟไหม้';
    }
  }

  @override
  Widget build(BuildContext context) {
    final diamond = SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        size: Size(size, size),
        painter: _NfpaDiamondPainter(
          health: health,
          flammability: flammability,
          instability: instability,
          special: special ?? '',
        ),
      ),
    );

    if (editable) {
      return InkWell(
        onTap: () => _showEditDialog(context),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              diamond,
              const SizedBox(height: 6),
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.edit_rounded, size: 12, color: Colors.blue),
                  SizedBox(width: 4),
                  Text('แตะเพื่อตั้งค่า NFPA', style: TextStyle(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return diamond;
  }
}

class _NfpaDiamondPainter extends CustomPainter {
  final int health;
  final int flammability;
  final int instability;
  final String special;

  _NfpaDiamondPainter({
    required this.health,
    required this.flammability,
    required this.instability,
    required this.special,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double cx = w / 2;
    final double cy = h / 2;
    final double half = w / 2;

    final borderPaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    // Red Top (Flammability)
    final redPaint = Paint()..color = const Color(0xFFEF4444);
    final topPath = Path()
      ..moveTo(cx, 0)
      ..lineTo(cx + half / 2, cy - half / 2)
      ..lineTo(cx, cy)
      ..lineTo(cx - half / 2, cy - half / 2)
      ..close();
    canvas.drawPath(topPath, redPaint);
    canvas.drawPath(topPath, borderPaint);

    // Blue Left (Health)
    final bluePaint = Paint()..color = const Color(0xFF3B82F6);
    final leftPath = Path()
      ..moveTo(0, cy)
      ..lineTo(cx - half / 2, cy - half / 2)
      ..lineTo(cx, cy)
      ..lineTo(cx - half / 2, cy + half / 2)
      ..close();
    canvas.drawPath(leftPath, bluePaint);
    canvas.drawPath(leftPath, borderPaint);

    // Yellow Right (Instability)
    final yellowPaint = Paint()..color = const Color(0xFFFBBF24);
    final rightPath = Path()
      ..moveTo(w, cy)
      ..lineTo(cx + half / 2, cy - half / 2)
      ..lineTo(cx, cy)
      ..lineTo(cx + half / 2, cy + half / 2)
      ..close();
    canvas.drawPath(rightPath, yellowPaint);
    canvas.drawPath(rightPath, borderPaint);

    // White Bottom (Special)
    final whitePaint = Paint()..color = Colors.white;
    final bottomPath = Path()
      ..moveTo(cx, h)
      ..lineTo(cx - half / 2, cy + half / 2)
      ..lineTo(cx, cy)
      ..lineTo(cx + half / 2, cy + half / 2)
      ..close();
    canvas.drawPath(bottomPath, whitePaint);
    canvas.drawPath(bottomPath, borderPaint);

    // Outer border
    final outerPath = Path()
      ..moveTo(cx, 0)
      ..lineTo(w, cy)
      ..lineTo(cx, h)
      ..lineTo(0, cy)
      ..close();
    canvas.drawPath(outerPath, borderPaint);

    // Draw Numbers & Labels
    final fontSize = (w * 0.22).clamp(12.0, 26.0);

    // Flammability (Top)
    _drawCenteredText(
      canvas: canvas,
      text: flammability.toString(),
      center: Offset(cx, cy - half / 2),
      fontSize: fontSize,
      color: Colors.white,
    );

    // Health (Left)
    _drawCenteredText(
      canvas: canvas,
      text: health.toString(),
      center: Offset(cx - half / 2, cy),
      fontSize: fontSize,
      color: Colors.white,
    );

    // Instability (Right)
    _drawCenteredText(
      canvas: canvas,
      text: instability.toString(),
      center: Offset(cx + half / 2, cy),
      fontSize: fontSize,
      color: const Color(0xFF1E293B),
    );

    // Special (Bottom)
    final specialText = special.isEmpty ? '-' : (special == 'W' ? 'W\u0336' : special);
    _drawCenteredText(
      canvas: canvas,
      text: specialText,
      center: Offset(cx, cy + half / 2),
      fontSize: special.length > 2 ? fontSize * 0.7 : fontSize * 0.85,
      color: const Color(0xFF1E293B),
      isBold: true,
    );
  }

  void _drawCenteredText({
    required Canvas canvas,
    required String text,
    required Offset center,
    required double fontSize,
    required Color color,
    bool isBold = true,
  }) {
    final textSpan = TextSpan(
      text: text,
      style: TextStyle(
        color: color,
        fontSize: fontSize,
        fontWeight: isBold ? FontWeight.w900 : FontWeight.bold,
        fontFamily: 'Roboto',
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();

    final offset = Offset(center.dx - (textPainter.width / 2), center.dy - (textPainter.height / 2));
    textPainter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _NfpaDiamondPainter oldDelegate) {
    return oldDelegate.health != health ||
        oldDelegate.flammability != flammability ||
        oldDelegate.instability != instability ||
        oldDelegate.special != special;
  }
}
