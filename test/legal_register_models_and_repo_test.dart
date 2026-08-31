import 'package:flutter_test/flutter_test.dart';
import 'package:safety_superapp/features/legal_register/data/safety_legal_8_categories_data.dart';
import 'package:safety_superapp/features/legal_register/domain/models/legal_master_item_model.dart';
import 'package:safety_superapp/features/legal_register/domain/models/legal_compliance_assessment_model.dart';
import 'package:safety_superapp/features/legal_register/domain/models/legal_capa_model.dart';
import 'package:safety_superapp/features/legal_register/domain/models/legal_compliance_stats_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('1. Master Legal Catalog (32 Items & 8 Laws) Tests', () {
    test('Catalog contains exactly 32 statutory items', () {
      expect(SafetyLegal8CategoriesData.masterItems.length, 32);
    });

    test('All 8 statutory categories are present with correct item distributions', () {
      final items = SafetyLegal8CategoriesData.masterItems;
      final oshAct = items.where((e) => e.category == 'OSH_ACT').toList();
      final safetyOfficer = items.where((e) => e.category == 'SAFETY_OFFICER').toList();
      final chemical = items.where((e) => e.category == 'CHEMICAL_SAFETY').toList();
      final fire = items.where((e) => e.category == 'FIRE_SAFETY').toList();
      final electrical = items.where((e) => e.category == 'ELECTRICAL_SAFETY').toList();
      final machinery = items.where((e) => e.category == 'MACHINERY_BOILER').toList();
      final environment = items.where((e) => e.category == 'ENVIRONMENT_PHYSICAL').toList();
      final health = items.where((e) => e.category == 'HEALTH_SURVEILLANCE').toList();

      expect(oshAct.length, 5);
      expect(safetyOfficer.length, 4);
      expect(chemical.length, 6);
      expect(fire.length, 5);
      expect(electrical.length, 4);
      expect(machinery.length, 4);
      expect(environment.length, 3);
      expect(health.length, 3);
    });

    test('Exact lookup by item_id retrieves correct master item', () {
      final item = SafetyLegal8CategoriesData.findByItemId('ITEM-OSH-001');
      expect(item, isNotNull);
      expect(item!.lawId, 'LAW-OSH-2554');
      expect(item.articleNo, contains('มาตรา ๖'));
      expect(item.riskLevel, 'HIGH');
      expect(item.riskWeight, 3);
    });

    test('Keyword search matches across titles, articles, and descriptions', () {
      final sdsMatches = SafetyLegal8CategoriesData.search('สอ.๑');
      expect(sdsMatches.isNotEmpty, isTrue);
      expect(sdsMatches.first.itemId, 'ITEM-CHM-001');

      final fireMatches = SafetyLegal8CategoriesData.search('๔๐%');
      expect(fireMatches.isNotEmpty, isTrue);
      expect(fireMatches.first.itemId, 'ITEM-FIR-004');
    });

    test('Category filter retrieves specific category items', () {
      final chemItems = SafetyLegal8CategoriesData.findByCategory('CHEMICAL_SAFETY');
      expect(chemItems.length, 6);
      for (final it in chemItems) {
        expect(it.category, 'CHEMICAL_SAFETY');
      }
    });
  });

  group('2. Domain Models Serialization & Helpers Tests', () {
    test('LegalMasterItemModel JSON/Map roundtrip', () {
      final original = SafetyLegal8CategoriesData.masterItems.first;
      final map = original.toMap();
      final restored = LegalMasterItemModel.fromMap(map);

      expect(restored.itemId, original.itemId);
      expect(restored.lawId, original.lawId);
      expect(restored.category, original.category);
      expect(restored.articleNo, original.articleNo);
      expect(restored.riskLevel, original.riskLevel);
      expect(restored.riskWeight, original.riskWeight);
      expect(restored.gazetteReference.volume, original.gazetteReference.volume);
    });

    test('LegalComplianceAssessmentModel JSON/Map roundtrip and helpers', () {
      final assessment = LegalComplianceAssessmentModel(
        id: 10,
        masterItemId: 'ITEM-OSH-002',
        requirementCode: 'ITEM-OSH-002',
        requirementTitle: 'การฝึกอบรมลูกจ้างใหม่',
        requirementDetails: 'อบรม 6 ชม.',
        category: 'OSH_ACT',
        lawId: 'LAW-OSH-2554',
        lawTitleTh: 'พ.ร.บ. ความปลอดภัย ๒๕๕๔',
        articleNo: 'มาตรา ๑๖',
        isApplicable: true,
        complianceStatus: 'NON_COMPLIANT',
        actualPractice: 'ยังไม่ได้จัดอบรมพนักงานแผนกคลังสินค้า',
        evaluatedDate: '2026-08-31',
        evaluatorName: 'นาย จป. ทดสอบ',
        department: 'EHS',
        evidenceFilePaths: const ['/docs/ev1.pdf', '/photos/ev2.jpg'],
        riskLevel: 'HIGH',
      );

      expect(assessment.isNonCompliant, isTrue);
      expect(assessment.requiresCapa, isTrue);
      expect(assessment.hasEvidence, isTrue);
      expect(assessment.riskWeight, 3);
      expect(assessment.statusLabelTh, contains('ไม่สอดคล้อง'));

      final map = assessment.toMap();
      final fromDb = LegalComplianceAssessmentModel.fromMap(map);

      expect(fromDb.id, 10);
      expect(fromDb.requirementCode, 'ITEM-OSH-002');
      expect(fromDb.complianceStatus, 'NON_COMPLIANT');
      expect(fromDb.evidenceFilePaths.length, 2);
      expect(fromDb.evidenceFilePaths[0], '/docs/ev1.pdf');
    });

    test('LegalCapaModel overdue calculation and status helpers', () {
      final pastDate = '2020-01-01';
      final futureDate = '2030-01-01';

      final overdueCapa = LegalCapaModel(
        id: 1,
        assessmentId: 5,
        actionTitle: 'จัดอบรมลูกจ้างใหม่ 6 ชม.',
        rootCause: 'ขาดระบบ onboarding',
        correctiveAction: 'จัดหลักสูตรอบรมทันที',
        picName: 'จป.วิชาชีพ',
        targetDate: pastDate,
        status: 'IN_PROGRESS',
      );

      expect(overdueCapa.isOverdue, isTrue);
      expect(overdueCapa.effectiveStatusEnum, LegalCapaStatus.overdue);
      expect(overdueCapa.daysRemaining < 0, isTrue);

      final completedCapa = overdueCapa.copyWith(
        status: 'COMPLETED',
        completedDate: '2026-08-31',
      );
      expect(completedCapa.isCompleted, isTrue);
      expect(completedCapa.isOverdue, isFalse);
      expect(completedCapa.effectiveStatusEnum, LegalCapaStatus.completed);

      final futureCapa = overdueCapa.copyWith(
        targetDate: futureDate,
        status: 'PENDING',
      );
      expect(futureCapa.isOverdue, isFalse);
      expect(futureCapa.effectiveStatusEnum, LegalCapaStatus.pending);
    });
  });

  group('3. Compliance KPI & Statistics Engine Calculation Tests', () {
    test('100% Compliant Scenario -> CI=100.0%, WCI=100.0%', () {
      final assessments = [
        LegalComplianceAssessmentModel(
          masterItemId: '1', requirementCode: '1', requirementTitle: 'T1', requirementDetails: 'D1',
          category: 'OSH_ACT', lawId: 'L1', lawTitleTh: 'LT1', articleNo: 'A1',
          isApplicable: true, complianceStatus: 'COMPLIANT', evaluatedDate: '2026-08-31',
          evaluatorName: 'Assessor', riskLevel: 'HIGH',
        ),
        LegalComplianceAssessmentModel(
          masterItemId: '2', requirementCode: '2', requirementTitle: 'T2', requirementDetails: 'D2',
          category: 'OSH_ACT', lawId: 'L1', lawTitleTh: 'LT1', articleNo: 'A2',
          isApplicable: true, complianceStatus: 'COMPLIANT', evaluatedDate: '2026-08-31',
          evaluatorName: 'Assessor', riskLevel: 'MEDIUM',
        ),
      ];

      final stats = LegalComplianceStatsModel.calculate(assessments: assessments);
      expect(stats.totalItems, 2);
      expect(stats.applicableItems, 2);
      expect(stats.compliantCount, 2);
      expect(stats.nonCompliantCount, 0);
      expect(stats.basicCompliancePercent, 100.0);
      expect(stats.riskWeightedCompliancePercent, 100.0);
    });

    test('Mixed Scenario: 1 Compliant (High=3), 1 Non-Compliant (High=3), 1 In-Progress (Medium=2), 1 N/A', () {
      final assessments = [
        LegalComplianceAssessmentModel(
          masterItemId: '1', requirementCode: '1', requirementTitle: 'T1', requirementDetails: 'D1',
          category: 'OSH_ACT', lawId: 'L1', lawTitleTh: 'LT1', articleNo: 'A1',
          isApplicable: true, complianceStatus: 'COMPLIANT', evaluatedDate: '2026-08-31',
          evaluatorName: 'Assessor', riskLevel: 'HIGH', // weight = 3
        ),
        LegalComplianceAssessmentModel(
          masterItemId: '2', requirementCode: '2', requirementTitle: 'T2', requirementDetails: 'D2',
          category: 'OSH_ACT', lawId: 'L1', lawTitleTh: 'LT1', articleNo: 'A2',
          isApplicable: true, complianceStatus: 'NON_COMPLIANT', evaluatedDate: '2026-08-31',
          evaluatorName: 'Assessor', riskLevel: 'HIGH', // weight = 3
        ),
        LegalComplianceAssessmentModel(
          masterItemId: '3', requirementCode: '3', requirementTitle: 'T3', requirementDetails: 'D3',
          category: 'CHEMICAL_SAFETY', lawId: 'L2', lawTitleTh: 'LT2', articleNo: 'A3',
          isApplicable: true, complianceStatus: 'IN_PROGRESS', evaluatedDate: '2026-08-31',
          evaluatorName: 'Assessor', riskLevel: 'MEDIUM', // weight = 2
        ),
        LegalComplianceAssessmentModel(
          masterItemId: '4', requirementCode: '4', requirementTitle: 'T4', requirementDetails: 'D4',
          category: 'MACHINERY_BOILER', lawId: 'L3', lawTitleTh: 'LT3', articleNo: 'A4',
          isApplicable: false, complianceStatus: 'NOT_APPLICABLE', evaluatedDate: '2026-08-31',
          evaluatorName: 'Assessor', riskLevel: 'HIGH', // excluded
        ),
      ];

      // Total applicable = 3 items (1, 2, 3)
      // Basic Compliance CI = (1 / 3) * 100 = 33.3%
      // Total applicable weight = 3 + 3 + 2 = 8
      // Compliant weight = 3
      // Risk Weighted WCI = (3 / 8) * 100 = 37.5%

      final stats = LegalComplianceStatsModel.calculate(assessments: assessments);
      expect(stats.totalItems, 4);
      expect(stats.applicableItems, 3);
      expect(stats.compliantCount, 1);
      expect(stats.nonCompliantCount, 1);
      expect(stats.inProgressCount, 1);
      expect(stats.notApplicableCount, 1);
      expect(stats.basicCompliancePercent, 33.3);
      expect(stats.riskWeightedCompliancePercent, 37.5);
      expect(stats.highRiskNonCompliantCount, 1);
    });

    test('Zero applicable items protection (All N/A) -> CI=100.0%, WCI=100.0%', () {
      final assessments = [
        LegalComplianceAssessmentModel(
          masterItemId: '1', requirementCode: '1', requirementTitle: 'T1', requirementDetails: 'D1',
          category: 'OSH_ACT', lawId: 'L1', lawTitleTh: 'LT1', articleNo: 'A1',
          isApplicable: false, complianceStatus: 'NOT_APPLICABLE', evaluatedDate: '2026-08-31',
          evaluatorName: 'Assessor', riskLevel: 'HIGH',
        ),
      ];

      final stats = LegalComplianceStatsModel.calculate(assessments: assessments);
      expect(stats.applicableItems, 0);
      expect(stats.notApplicableCount, 1);
      expect(stats.basicCompliancePercent, 100.0);
      expect(stats.riskWeightedCompliancePercent, 100.0);
    });
  });
}
