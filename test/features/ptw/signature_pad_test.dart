import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safety_superapp/features/ptw/presentation/widgets/signature_pad_widget.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SignaturePadController Tests', () {
    test('Initial state is empty', () {
      final controller = SignaturePadController();
      expect(controller.isEmpty, isTrue);
      expect(controller.isNotEmpty, isFalse);
      expect(controller.strokes, isEmpty);
    });

    test('Drawing strokes updates points and notifiers', () {
      final controller = SignaturePadController();
      int notifyCount = 0;
      controller.addListener(() => notifyCount++);

      controller.startStroke(const Offset(10, 10));
      expect(controller.isNotEmpty, isTrue);
      expect(controller.strokes.length, 1);
      expect(controller.strokes.first.points.length, 1);
      expect(notifyCount, 1);

      controller.addPoint(const Offset(20, 20));
      controller.addPoint(const Offset(30, 30));
      expect(controller.strokes.first.points.length, 3);
      expect(notifyCount, 3);

      controller.endStroke();
      expect(notifyCount, 4);
    });

    test('Undo removes last stroke', () {
      final controller = SignaturePadController();
      controller.startStroke(const Offset(10, 10));
      controller.endStroke();
      controller.startStroke(const Offset(50, 50));
      controller.endStroke();

      expect(controller.strokes.length, 2);

      controller.undo();
      expect(controller.strokes.length, 1);
      expect(controller.strokes.first.points.first, const Offset(10, 10));

      controller.undo();
      expect(controller.isEmpty, isTrue);
    });

    test('Clear removes all strokes', () {
      final controller = SignaturePadController();
      controller.startStroke(const Offset(10, 10));
      controller.startStroke(const Offset(50, 50));
      expect(controller.strokes.length, 2);

      controller.clear();
      expect(controller.isEmpty, isTrue);
      expect(controller.strokes, isEmpty);
    });

    test('Export to PNG Uint8List returns valid byte data', () async {
      final controller = SignaturePadController();
      expect(await controller.toPngBytes(), isNull);

      controller.startStroke(const Offset(10, 10));
      controller.addPoint(const Offset(50, 50));
      controller.addPoint(const Offset(100, 50));
      controller.endStroke();

      final bytes = await controller.toPngBytes(width: 200, height: 100);
      expect(bytes, isNotNull);
      expect(bytes!.isNotEmpty, isTrue);
      // PNG header check (0x89 0x50 0x4E 0x47)
      expect(bytes[0], 0x89);
      expect(bytes[1], 0x50);
      expect(bytes[2], 0x4E);
      expect(bytes[3], 0x47);
    });
  });

  group('SignaturePadWidget Widget Tests', () {
    testWidgets('Renders placeholder and buttons', (tester) async {
      final controller = SignaturePadController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SignaturePadWidget(
              controller: controller,
              height: 200,
              placeholderText: 'เซ็นชื่อที่นี่',
              showToolbar: true,
            ),
          ),
        ),
      );

      expect(find.text('เซ็นชื่อที่นี่'), findsOneWidget);
      expect(find.text('เลิกทำ (Undo)'), findsOneWidget);
      expect(find.text('ล้างลายเซ็น (Clear)'), findsOneWidget);

      // Perform a pan gesture on the signature pad
      await tester.drag(find.byType(GestureDetector).first, const Offset(50, 30));
      await tester.pumpAndSettle();

      expect(controller.isNotEmpty, isTrue);

      // Tap Clear
      await tester.tap(find.text('ล้างลายเซ็น (Clear)'));
      await tester.pumpAndSettle();

      expect(controller.isEmpty, isTrue);
    });
  });
}
