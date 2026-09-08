import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Single continuous stroke made by the pen/finger
class SignatureStroke {
  final List<Offset> points;
  final Color color;
  final double strokeWidth;

  const SignatureStroke({
    required this.points,
    this.color = const Color(0xFF0F172A),
    this.strokeWidth = 3.0,
  });

  SignatureStroke copyWith({
    List<Offset>? points,
    Color? color,
    double? strokeWidth,
  }) {
    return SignatureStroke(
      points: points ?? List.from(this.points),
      color: color ?? this.color,
      strokeWidth: strokeWidth ?? this.strokeWidth,
    );
  }
}

/// Controller managing strokes, undo/clear actions, and PNG export
class SignaturePadController extends ChangeNotifier {
  final List<SignatureStroke> _strokes = [];
  Color penColor;
  double strokeWidth;

  SignaturePadController({
    this.penColor = const Color(0xFF0F172A),
    this.strokeWidth = 3.0,
  });

  List<SignatureStroke> get strokes => List.unmodifiable(_strokes);
  bool get isEmpty => _strokes.isEmpty;
  bool get isNotEmpty => _strokes.isNotEmpty;

  void startStroke(Offset point) {
    _strokes.add(SignatureStroke(
      points: [point],
      color: penColor,
      strokeWidth: strokeWidth,
    ));
    notifyListeners();
  }

  void addPoint(Offset point) {
    if (_strokes.isEmpty) {
      startStroke(point);
      return;
    }
    final lastStroke = _strokes.removeLast();
    final updatedPoints = List<Offset>.from(lastStroke.points)..add(point);
    _strokes.add(lastStroke.copyWith(points: updatedPoints));
    notifyListeners();
  }

  void endStroke() {
    notifyListeners();
  }

  void clear() {
    if (_strokes.isEmpty) return;
    _strokes.clear();
    notifyListeners();
  }

  void undo() {
    if (_strokes.isEmpty) return;
    _strokes.removeLast();
    notifyListeners();
  }

  /// Export the signature canvas to PNG image bytes
  Future<Uint8List?> toPngBytes({
    double width = 500,
    double height = 250,
    Color? overridePenColor,
    Color backgroundColor = Colors.transparent,
  }) async {
    if (_strokes.isEmpty) return null;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, width, height),
    );

    // Draw background if specified
    if (backgroundColor != Colors.transparent) {
      final bgPaint = Paint()..color = backgroundColor;
      canvas.drawRect(Rect.fromLTWH(0, 0, width, height), bgPaint);
    }

    final painter = _SignaturePainter(
      strokes: _strokes,
      overrideColor: overridePenColor,
    );
    painter.paint(canvas, Size(width, height));

    final picture = recorder.endRecording();
    final img = await picture.toImage(width.toInt(), height.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);

    return byteData?.buffer.asUint8List();
  }

  /// Save signature to app documents folder and return absolute path
  Future<String?> saveToFile({
    required String ptwNumber,
    required String roleKey,
    double width = 500,
    double height = 250,
  }) async {
    final bytes = await toPngBytes(width: width, height: height);
    if (bytes == null) return null;

    final appDir = await getApplicationDocumentsDirectory();
    final sigDir = Directory(p.join(appDir.path, 'safapp_signatures'));
    if (!await sigDir.exists()) {
      await sigDir.create(recursive: true);
    }

    final safePtw = ptwNumber.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
    final filename = '${safePtw}_${roleKey}_${DateTime.now().millisecondsSinceEpoch}.png';
    final filePath = p.join(sigDir.path, filename);

    final file = File(filePath);
    await file.writeAsBytes(bytes);
    return file.path;
  }
}

/// CustomPainter rendering smooth signature strokes
class _SignaturePainter extends CustomPainter {
  final List<SignatureStroke> strokes;
  final Color? overrideColor;

  _SignaturePainter({
    required this.strokes,
    this.overrideColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      if (stroke.points.isEmpty) continue;

      final paint = Paint()
        ..color = overrideColor ?? stroke.color
        ..strokeWidth = stroke.strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      if (stroke.points.length == 1) {
        // Draw single point dot
        canvas.drawCircle(stroke.points.first, stroke.strokeWidth / 2, paint..style = PaintingStyle.fill);
        continue;
      }

      final path = Path();
      path.moveTo(stroke.points.first.dx, stroke.points.first.dy);

      for (int i = 1; i < stroke.points.length; i++) {
        final p0 = stroke.points[i - 1];
        final p1 = stroke.points[i];
        final mid = Offset((p0.dx + p1.dx) / 2, (p0.dy + p1.dy) / 2);
        path.quadraticBezierTo(p0.dx, p0.dy, mid.dx, mid.dy);
      }

      path.lineTo(stroke.points.last.dx, stroke.points.last.dy);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) => true;
}

/// Responsive Signature Pad Widget with Gesture Capturing & Built-in Controls
class SignaturePadWidget extends StatefulWidget {
  final SignaturePadController? controller;
  final double height;
  final Color backgroundColor;
  final Color penColor;
  final double strokeWidth;
  final String placeholderText;
  final bool showToolbar;
  final VoidCallback? onSigned;
  final VoidCallback? onCleared;

  const SignaturePadWidget({
    super.key,
    this.controller,
    this.height = 200,
    this.backgroundColor = const Color(0xFFF8FAFC),
    this.penColor = const Color(0xFF0F172A),
    this.strokeWidth = 3.0,
    this.placeholderText = 'เซ็นชื่อที่นี่ (Sign here using stylus or touch)',
    this.showToolbar = true,
    this.onSigned,
    this.onCleared,
  });

  @override
  State<SignaturePadWidget> createState() => _SignaturePadWidgetState();
}

class _SignaturePadWidgetState extends State<SignaturePadWidget> {
  late SignaturePadController _controller;
  bool _isInternalController = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      _controller = SignaturePadController(
        penColor: widget.penColor,
        strokeWidth: widget.strokeWidth,
      );
      _isInternalController = true;
    }
    _controller.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(covariant SignaturePadWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller && widget.controller != null) {
      if (_isInternalController) {
        _controller.removeListener(_onControllerChanged);
        _controller.dispose();
        _isInternalController = false;
      }
      _controller = widget.controller!;
      _controller.addListener(_onControllerChanged);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    if (_isInternalController) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: widget.height,
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              // Subtle guideline
              Positioned(
                bottom: 40,
                left: 24,
                right: 24,
                child: Container(
                  height: 1,
                  color: const Color(0xFFE2E8F0),
                ),
              ),

              // Placeholder hint
              if (_controller.isEmpty)
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.draw_outlined, color: Colors.grey.shade400, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        widget.placeholderText,
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),

              // Drawing Canvas & Gesture Listener
              GestureDetector(
                onPanStart: (details) {
                  _controller.startStroke(details.localPosition);
                  widget.onSigned?.call();
                },
                onPanUpdate: (details) {
                  _controller.addPoint(details.localPosition);
                },
                onPanEnd: (_) {
                  _controller.endStroke();
                },
                child: CustomPaint(
                  painter: _SignaturePainter(strokes: _controller.strokes),
                  size: Size.infinite,
                ),
              ),
            ],
          ),
        ),

        if (widget.showToolbar) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: _controller.isEmpty
                    ? null
                    : () {
                        _controller.undo();
                      },
                icon: const Icon(Icons.undo, size: 16),
                label: const Text('เลิกทำ (Undo)', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF64748B),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                ),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: _controller.isEmpty
                    ? null
                    : () {
                        _controller.clear();
                        widget.onCleared?.call();
                      },
                icon: const Icon(Icons.delete_outline, size: 16),
                label: const Text('ล้างลายเซ็น (Clear)', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFEF4444),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Helper Modal Dialog for Digital Sign-off
Future<Uint8List?> showSignatureDialog({
  required BuildContext context,
  required String title,
  String? subtitle,
  String? signatoryRole,
  String? signatoryName,
  Color primaryColor = const Color(0xFF0D9488),
}) async {
  final controller = SignaturePadController();
  final nameController = TextEditingController(text: signatoryName ?? '');

  final result = await showDialog<Uint8List?>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
            contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.draw, color: primaryColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.normal),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 500,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (signatoryRole != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.badge_outlined, size: 16, color: Color(0xFF475569)),
                          const SizedBox(width: 8),
                          Text(
                            'บทบาท: $signatoryRole',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'ชื่อ-นามสกุล ผู้ลงนาม (Signatory Name) *',
                      labelStyle: const TextStyle(fontSize: 13),
                      hintText: 'ระบุชื่อและนามสกุลเต็ม',
                      prefixIcon: const Icon(Icons.person_outline, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 14),

                  const Text(
                    'กรุณาวาดลายเซ็นดิจิทัลในกรอบด้านล่าง:',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF475569)),
                  ),
                  const SizedBox(height: 6),

                  SignaturePadWidget(
                    controller: controller,
                    height: 180,
                    showToolbar: true,
                  ),
                ],
              ),
            ),
            actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
            actions: [
              OutlinedButton(
                onPressed: () => Navigator.of(ctx).pop(null),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                child: const Text('ยกเลิก (Cancel)'),
              ),
              FilledButton.icon(
                onPressed: () async {
                  if (controller.isEmpty) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(content: Text('กรุณาวาดลายเซ็นก่อนกดยืนยัน')),
                    );
                    return;
                  }
                  if (nameController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(content: Text('กรุณาระบุชื่อ-นามสกุลผู้ลงนาม')),
                    );
                    return;
                  }
                  final pngBytes = await controller.toPngBytes();
                  if (ctx.mounted) {
                    Navigator.of(ctx).pop(pngBytes);
                  }
                },
                icon: const Icon(Icons.check, size: 18),
                label: const Text('ยืนยันลงนาม (Confirm)'),
                style: FilledButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                ),
              ),
            ],
          );
        },
      );
    },
  );

  return result;
}
