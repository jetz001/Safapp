import 'package:flutter_test/flutter_test.dart';
import 'package:safety_superapp/features/ppe_asl/domain/models/ppe_item_model.dart';
import 'package:safety_superapp/features/ppe_asl/domain/models/ppe_transaction_model.dart';
import 'package:safety_superapp/features/ppe_asl/domain/models/asl_supplier_model.dart';
import 'package:safety_superapp/features/ppe_asl/data/datasources/ppe_statutory_master_data.dart';

void main() {
  group('PPE & Statutory Section 22 Master Data Tests', () {
    test('Verify all 8 statutory PPE categories exist according to Section 22', () {
      expect(PpeCategory.values.length, 8);

      final categories = PpeCategory.values.map((c) => c.code).toSet();
      expect(categories.contains('HEAD'), isTrue);
      expect(categories.contains('EYE_FACE'), isTrue);
      expect(categories.contains('HEARING'), isTrue);
      expect(categories.contains('RESPIRATORY'), isTrue);
      expect(categories.contains('HAND_ARM'), isTrue);
      expect(categories.contains('FOOT_LEG'), isTrue);
      expect(categories.contains('FALL_PROTECTION'), isTrue);
      expect(categories.contains('BODY'), isTrue);
    });

    test('Verify default statutory PPE items seed correctly with standards', () {
      final items = PpeStatutoryMasterData.defaultPpeItems;
      expect(items.isNotEmpty, isTrue);

      // Verify each item has standard certificate according to law
      for (final item in items) {
        expect(item.code.startsWith('PPE-'), isTrue);
        expect(item.name.isNotEmpty, isTrue);
        expect(item.standardCert.isNotEmpty, isTrue);
        expect(item.unit.isNotEmpty, isTrue);
        expect(item.minStock, greaterThan(0));
      }
    });

    test('Verify stock status logic (normal, low stock, out of stock)', () {
      const itemNormal = PpeItem(
        code: 'PPE-HD-001',
        name: 'หมวกนิรภัย',
        category: PpeCategory.head,
        standardCert: 'มอก. 368-2554',
        currentStock: 25,
        minStock: 10,
      );
      expect(itemNormal.isLowStock, isFalse);
      expect(itemNormal.isOutOfStock, isFalse);

      const itemLow = PpeItem(
        code: 'PPE-HD-002',
        name: 'แว่นตานิรภัย',
        category: PpeCategory.eyeFace,
        standardCert: 'ANSI Z87.1',
        currentStock: 8,
        minStock: 10,
      );
      expect(itemLow.isLowStock, isTrue);
      expect(itemLow.isOutOfStock, isFalse);

      const itemOut = PpeItem(
        code: 'PPE-HD-003',
        name: 'ถุงมือกันบาด',
        category: PpeCategory.handArm,
        standardCert: 'EN 388',
        currentStock: 0,
        minStock: 5,
      );
      expect(itemOut.isLowStock, isTrue);
      expect(itemOut.isOutOfStock, isTrue);
    });

    test('Verify Stock Card Transaction types and data mapping', () {
      final tx = PpeTransaction(
        transactionNo: 'TX-20260908-001',
        ppeId: 1,
        ppeCode: 'PPE-HD-001',
        ppeName: 'หมวกนิรภัยมาตรฐาน มอก.',
        transactionType: PpeTransactionType.stockOut,
        quantity: 2,
        balanceAfter: 43,
        transactionDate: '2026-09-08',
        recipientName: 'นายสมบัติ รักปลอดภัย',
        department: 'แผนกซ่อมบำรุง',
        cpoMeetingRef: 'มติ คปอ. ครั้งที่ 1/2569',
      );

      final map = tx.toMap();
      expect(map['transaction_type'], 'OUT');
      expect(map['quantity'], 2);
      expect(map['balance_after'], 43);
      expect(map['cpo_meeting_ref'], 'มติ คปอ. ครั้งที่ 1/2569');

      final fromMap = PpeTransaction.fromMap(map);
      expect(fromMap.transactionNo, 'TX-20260908-001');
      expect(fromMap.transactionType, PpeTransactionType.stockOut);
      expect(fromMap.recipientName, 'นายสมบัติ รักปลอดภัย');
    });

    test('Verify ASL Supplier default list and evaluation status', () {
      final suppliers = PpeStatutoryMasterData.defaultSuppliers;
      expect(suppliers.length, greaterThanOrEqualTo(3));

      for (final s in suppliers) {
        expect(s.code.startsWith('ASL-'), isTrue);
        expect(s.companyName.isNotEmpty, isTrue);
        expect(s.evaluationStatus, AslStatus.approved);
        expect(s.rating, greaterThanOrEqualTo(4.0));
      }
    });
  });
}
