import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safety_superapp/features/safety_manual/data/models/sop_model.dart';

void main() {
  group('Safety Manual & Digital SOP Model Tests', () {
    test('SopModel and SopStepModel toMap and fromMap serialization roundtrip', () {
      const step1 = SopStepModel(
        stepNumber: 1,
        title: 'ตรวจสอบก่อนเริ่มงาน',
        action: 'สวมใส่ PPE และสำรวจพื้นที่รอบเครื่องจักร',
        safetyCheckpoint: 'สวมหมวกและแว่นตานิรภัย',
      );

      final now = DateTime(2026, 3, 1);
      final review = DateTime(2027, 3, 1);

      final sop = SopModel(
        id: 10,
        docCode: 'SOP-MCH-001',
        title: 'ขั้นตอนการใช้งานปั้นจั่นเหนือศีรษะ',
        category: 'MACHINERY',
        revision: 'Rev. 02',
        effectiveDate: now,
        reviewDueDate: review,
        purpose: 'เพื่อควบคุมความปลอดภัยในการยกของ',
        scope: 'แผนกผลิตและคลังสินค้า',
        requiredPpeList: ['HELMET', 'SAFETY_GLASSES', 'BOOTS'],
        precautions: 'ห้ามเดินใต้แนวรัศมีชิ้นงาน',
        steps: [step1],
        emergencyProcedure: 'กด E-Stop ทันทีเมื่อเกิดเหตุ',
        pdfFilePath: 'D:/docs/sop_crane.pdf',
        author: 'ธีรพงษ์',
        reviewer: 'จป.วิชาชีพ',
        approver: 'ผู้จัดการโรงงาน',
        status: 'ACTIVE',
      );

      final map = sop.toMap();
      expect(map['doc_code'], 'SOP-MCH-001');
      expect(map['category'], 'MACHINERY');
      expect(map['revision'], 'Rev. 02');
      expect(map['status'], 'ACTIVE');
      expect(map['required_ppe'], contains('HELMET'));
      expect(map['steps_json'], contains('ตรวจสอบก่อนเริ่มงาน'));

      final restored = SopModel.fromMap(map);
      expect(restored.id, 10);
      expect(restored.docCode, 'SOP-MCH-001');
      expect(restored.title, 'ขั้นตอนการใช้งานปั้นจั่นเหนือศีรษะ');
      expect(restored.categoryTh, 'เครื่องจักร & ปั้นจั่น');
      expect(restored.categoryColor, const Color(0xFF0284C7));
      expect(restored.requiredPpeList.length, 3);
      expect(restored.steps.length, 1);
      expect(restored.steps.first.safetyCheckpoint, 'สวมหมวกและแว่นตานิรภัย');
      expect(restored.pdfFilePath, 'D:/docs/sop_crane.pdf');
    });

    test('SOP Review SLA calculates active, warning, and overdue accurately', () {
      final now = DateTime.now();

      // Future review date > 30 days -> ACTIVE
      final activeSop = SopModel(
        docCode: 'SOP-01',
        title: 'เอกสารปกติ',
        category: 'GENERAL',
        effectiveDate: now,
        reviewDueDate: now.add(const Duration(days: 90)),
      );
      expect(activeSop.isReviewDue, isFalse);
      expect(activeSop.isReviewWarning, isFalse);

      // Review within 30 days -> WARNING
      final warningSop = SopModel(
        docCode: 'SOP-02',
        title: 'ใกล้ครบกำหนดทบทวน',
        category: 'GENERAL',
        effectiveDate: now.subtract(const Duration(days: 350)),
        reviewDueDate: now.add(const Duration(days: 15)),
      );
      expect(warningSop.isReviewDue, isFalse);
      expect(warningSop.isReviewWarning, isTrue);

      // Review in the past -> OVERDUE
      final overdueSop = SopModel(
        docCode: 'SOP-03',
        title: 'เกินกำหนดทบทวนประจำปี',
        category: 'GENERAL',
        effectiveDate: now.subtract(const Duration(days: 400)),
        reviewDueDate: now.subtract(const Duration(days: 10)),
      );
      expect(overdueSop.isReviewDue, isTrue);
      expect(overdueSop.isReviewWarning, isFalse);
    });

    test('Factory scope adaptability: factories without boilers or specific operations can modify categories', () {
      // Factories without boilers can categorize SOPs under their active operations only
      final generalAssemblySop = SopModel(
        docCode: 'SOP-GEN-001',
        title: 'ขั้นตอนความปลอดภัยงานประกอบชิ้นส่วนอิเล็กทรอนิกส์',
        category: 'GENERAL',
        effectiveDate: DateTime.now(),
        reviewDueDate: DateTime.now().add(const Duration(days: 365)),
        purpose: 'โรงงานไม่มีหม้อน้ำและปั้นจั่น เน้นงานประกอบโต๊ะทำงาน',
        status: 'ACTIVE',
      );

      expect(generalAssemblySop.categoryTh, 'ความปลอดภัยทั่วไป');
      expect(generalAssemblySop.purpose, contains('ไม่มีหม้อน้ำ'));

      // Can archive or mark unused SOP
      final archivedBoilerSop = generalAssemblySop.copyWith(
        status: 'ARCHIVED',
        docCode: 'SOP-BLR-001',
        title: 'คู่มือหม้อน้ำ (โรงงานยกเลิกการใช้งานแล้ว)',
      );
      expect(archivedBoilerSop.status, 'ARCHIVED');
      expect(archivedBoilerSop.title, contains('ยกเลิกการใช้งาน'));
    });
  });
}
