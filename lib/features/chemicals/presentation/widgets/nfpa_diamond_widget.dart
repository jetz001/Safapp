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
    Key? key,
    this.health = 0,
    this.flammability = 0,
    this.instability = 0,
    this.special,
    this.size = 110,
    this.isInteractive = false,
    this.editable = false,
    this.onChanged,
  }) : super(key: key);

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
                    // Health (Blue)
                    _buildSlider(
                      title: 'สุขภาพ (Health - สีน้ำเงิน): $h',
                      value: h,
                      color: const Color(0xFF2563EB),
                      descriptions: const ['0: ปลอดภัย', '1: ระคายเคืองเล็กน้อย', '2: อันตรายปานกลาง', '3: อันตรายสูง', '4: ถึงแก่ชีวิต'],
                      onChanged: (val) => setDlgState(() => h = val),
                    ),
                    const SizedBox(height: 8),
                    // Flammability (Red)
                    _buildSlider(
                      title: 'ความไวไฟ (Flammability - สีแดง): $f',
                      value: f,
                      color: const Color(0xFFDC2626),
                      descriptions: const ['0: ไม่ติดไฟ', '1: จุดวาบไฟ > 93°C', '2: จุดวาบไฟ 38-93°C', '3: จุดวาบไฟ < 38°C', '4: จุดวาบไฟ < 23°C ไวไฟสูงมาก'],
                      onChanged: (val) => setDlgState(() => f = val),
                    ),
                    const SizedBox(height: 8),
                    // Instability (Yellow)
                    _buildSlider(
                      title: 'ความไม่เสถียร (Instability - สีเหลือง): $i',
                      value: i,
                      color: const Color(0xFFD97706),
                      descriptions: const ['0: เสถียร', '1: ไม่เสถียรเมื่อร้อน', '2: ปฏิกิริยารุนแรง', '3: ระเบิดได้เมื่อกระแทก', '4: ระเบิดได้เอง'],
                      onChanged: (val) => setDlgState(() => i = val),
                    ),
                    const SizedBox(height: 8),
                    // Special (White)
                    Row(
                      children: [
                        const Text('สัญลักษณ์พิเศษ (Special - สีขาว):', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButton<String>(
                            value: ['W', 'OX', 'SA', 'COR', 'BIO', 'RAD', ''].contains(s) ? s : '',
                            isExpanded: true,
                            underline: Container(height: 1, color: Colors.grey.shade400),
                            items: const [
                              DropdownMenuItem(value: '', child: Text('ไม่มี (None)')),
                              DropdownMenuItem(value: 'W', child: Text('W̅ (ทำปฏิกิริยารุนแรงกับน้ำ)')),
                              DropdownMenuItem(value: 'OX', child: Text('OX (สารออกซิไดเซอร์)')),
                              DropdownMenuItem(value: 'SA', child: Text('SA (ก๊าซแทนที่ออกซิเจน)')),
                              DropdownMenuItem(value: 'COR', child: Text('COR (สารกัดกร่อน)')),
                              DropdownMenuItem(value: 'BIO', child: Text('BIO (สารอันตรายทางชีวภาพ)')),
                              DropdownMenuItem(value: 'RAD', child: Text('RAD (สารกัมมันตรังสี)')),
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
                  child: const Text('ยกเลิก'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (onChanged != null) {
                      onChanged!(h, f, i, s);
                    }
                    Navigator.pop(ctx);
                  },
                  child: const Text('บันทึกค่า'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSlider({
    required String title,
    required int value,
    required Color color,
    required List<String> descriptions,
    required ValueChanged<int> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: value.toDouble(),
                min: 0,
                max: 4,
                divisions: 4,
                activeColor: color,
                onChanged: (v) => onChanged(v.round()),
              ),
            ),
            SizedBox(
              width: 140,
              child: Text(
                descriptions[value.clamp(0, 4)],
                style: const TextStyle(fontSize: 11, color: Color(0xFF475569)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final diamond = CustomPaint(
      size: Size(size, size),
      painter: _NfpaDiamondPainter(
        health: health,
        flammability: flammability,
        instability: instability,
        special: special ?? '',
      ),
    );

    if (isInteractive || editable) {
      return InkWell(
        onTap: () => _showEditDialog(context),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
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
