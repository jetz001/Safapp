import 'package:flutter_test/flutter_test.dart';
import 'package:safety_superapp/features/risk_assessment/domain/models/risk_matrix_criteria.dart';

void main() {
  group('กระทรวงแรงงาน ๒๕๖๗ - Risk Matrix Criteria Evaluation Tests', () {
    test('Likelihood 1 x Severity 1 = 1 -> ระดับต่ำมาก (ไม่ต้องทำ ปอ.๒)', () {
      final res = RiskMatrixCriteria.evaluate(1, 1);
      expect(res.score, 1);
      expect(res.level, RiskLevel.veryLow);
      expect(res.thaiName, 'ระดับต่ำมาก');
      expect(res.requiresPor2, false);
    });

    test('Likelihood 1 x Severity 2 = 2 -> ระดับต่ำ (ยอมรับได้ ไม่ต้องทำ ปอ.๒)', () {
      final res = RiskMatrixCriteria.evaluate(1, 2);
      expect(res.score, 2);
      expect(res.level, RiskLevel.low);
      expect(res.thaiName, 'ระดับต่ำ');
      expect(res.requiresPor2, false);
    });

    test('Likelihood 2 x Severity 1 = 2 -> ระดับต่ำ (ยอมรับได้ ไม่ต้องทำ ปอ.๒)', () {
      final res = RiskMatrixCriteria.evaluate(2, 1);
      expect(res.score, 2);
      expect(res.level, RiskLevel.low);
      expect(res.thaiName, 'ระดับต่ำ');
      expect(res.requiresPor2, false);
    });

    test('Likelihood 3 x Severity 1 = 3 -> ระดับปานกลาง (ต้องจัดทำแบบ ปอ.๒)', () {
      final res = RiskMatrixCriteria.evaluate(3, 1);
      expect(res.score, 3);
      expect(res.level, RiskLevel.medium);
      expect(res.thaiName, 'ระดับปานกลาง');
      expect(res.requiresPor2, true);
    });

    test('Likelihood 2 x Severity 2 = 4 -> ระดับปานกลาง (ต้องจัดทำแบบ ปอ.๒)', () {
      final res = RiskMatrixCriteria.evaluate(2, 2);
      expect(res.score, 4);
      expect(res.level, RiskLevel.medium);
      expect(res.thaiName, 'ระดับปานกลาง');
      expect(res.requiresPor2, true);
    });

    test('Likelihood 2 x Severity 3 = 6 -> ระดับสูง (ต้องจัดทำแบบ ปอ.๒)', () {
      final res = RiskMatrixCriteria.evaluate(2, 3);
      expect(res.score, 6);
      expect(res.level, RiskLevel.high);
      expect(res.thaiName, 'ระดับสูง');
      expect(res.requiresPor2, true);
    });

    test('Likelihood 3 x Severity 2 = 6 -> ระดับสูง (ต้องจัดทำแบบ ปอ.๒)', () {
      final res = RiskMatrixCriteria.evaluate(3, 2);
      expect(res.score, 6);
      expect(res.level, RiskLevel.high);
      expect(res.thaiName, 'ระดับสูง');
      expect(res.requiresPor2, true);
    });

    test('Likelihood 3 x Severity 3 = 9 -> ระดับสูงมาก (หยุดดำเนินการทันที + ต้องจัดทำแบบ ปอ.๒)', () {
      final res = RiskMatrixCriteria.evaluate(3, 3);
      expect(res.score, 9);
      expect(res.level, RiskLevel.veryHigh);
      expect(res.thaiName, 'ระดับสูงมาก');
      expect(res.requiresPor2, true);
    });

    test('Schedule 1 has 5 categories, Schedule 2 has 49 categories', () {
      expect(RiskMatrixCriteria.schedule1Categories.length, 5);
      expect(RiskMatrixCriteria.schedule2Categories.length, 49);
      expect(RiskMatrixCriteria.hazardIdentificationMethods.isNotEmpty, true);
    });
  });
}
