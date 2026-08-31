import 'package:flutter_test/flutter_test.dart';
import 'package:safety_superapp/features/legal_register/domain/models/legal_master_item_model.dart';
import 'package:safety_superapp/features/legal_register/domain/models/legal_compliance_assessment_model.dart';
import 'package:safety_superapp/features/legal_register/domain/models/legal_capa_model.dart';
import 'package:safety_superapp/features/legal_register/domain/models/legal_compliance_stats_model.dart';
import 'package:safety_superapp/features/legal_register/data/safety_legal_8_categories_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CHALLENGE SUITE 1: Extreme Mathematical Boundary & Edge Cases in KPI Formulas', () {
    test('Boundary 1.1: 0 items total (Empty Assessment list)', () {
      final stats = LegalComplianceStatsModel.calculate(assessments: const []);
      expect(stats.totalItems, 0);
      expect(stats.applicableItems, 0);
      expect(stats.compliantCount, 0);
      expect(stats.nonCompliantCount, 0);
      expect(stats.inProgressCount, 0);
      expect(stats.notApplicableCount, 0);
      expect(stats.basicCompliancePercent, 100.0);
      expect(stats.riskWeightedCompliancePercent, 100.0);
      expect(stats.highRiskNonCompliantCount, 0);
      expect(stats.categoryBreakdown.length, 8);
      for (final cat in stats.categoryBreakdown) {
        expect(cat.totalItems, 0);
        expect(cat.applicableItems, 0);
        expect(cat.basicCompliancePercent, 100.0);
        expect(cat.riskWeightedCompliancePercent, 100.0);
      }
    });

    test('Boundary 1.2: 100% Not Applicable (Zero Applicable Items)', () {
      final assessments = [
        LegalComplianceAssessmentModel(
          id: 1, masterItemId: 'ITEM-1', requirementCode: 'ITEM-1', requirementTitle: 'T1',
          requirementDetails: 'D1', category: 'OSH_ACT', lawId: 'L1', lawTitleTh: 'LT1', articleNo: '1',
          isApplicable: false, complianceStatus: 'NOT_APPLICABLE', evaluatedDate: '2026-08-31',
          evaluatorName: 'Assessor', riskLevel: 'HIGH',
        ),
        LegalComplianceAssessmentModel(
          id: 2, masterItemId: 'ITEM-2', requirementCode: 'ITEM-2', requirementTitle: 'T2',
          requirementDetails: 'D2', category: 'FIRE_SAFETY', lawId: 'L2', lawTitleTh: 'LT2', articleNo: '2',
          isApplicable: false, complianceStatus: 'NOT_APPLICABLE', evaluatedDate: '2026-08-31',
          evaluatorName: 'Assessor', riskLevel: 'MEDIUM',
        ),
      ];

      final stats = LegalComplianceStatsModel.calculate(assessments: assessments);
      expect(stats.totalItems, 2);
      expect(stats.applicableItems, 0);
      expect(stats.notApplicableCount, 2);
      expect(stats.compliantCount, 0);
      expect(stats.nonCompliantCount, 0);
      expect(stats.basicCompliancePercent, 100.0);
      expect(stats.riskWeightedCompliancePercent, 100.0);
    });

    test('Boundary 1.3: 100% Compliant (All applicable items compliant)', () {
      final assessments = [
        LegalComplianceAssessmentModel(
          id: 1, masterItemId: 'ITEM-1', requirementCode: 'ITEM-1', requirementTitle: 'T1',
          requirementDetails: 'D1', category: 'OSH_ACT', lawId: 'L1', lawTitleTh: 'LT1', articleNo: '1',
          isApplicable: true, complianceStatus: 'COMPLIANT', evaluatedDate: '2026-08-31',
          evaluatorName: 'Assessor', riskLevel: 'HIGH', // Weight 3
        ),
        LegalComplianceAssessmentModel(
          id: 2, masterItemId: 'ITEM-2', requirementCode: 'ITEM-2', requirementTitle: 'T2',
          requirementDetails: 'D2', category: 'FIRE_SAFETY', lawId: 'L2', lawTitleTh: 'LT2', articleNo: '2',
          isApplicable: true, complianceStatus: 'COMPLIANT', evaluatedDate: '2026-08-31',
          evaluatorName: 'Assessor', riskLevel: 'LOW', // Weight 1
        ),
      ];

      final stats = LegalComplianceStatsModel.calculate(assessments: assessments);
      expect(stats.totalItems, 2);
      expect(stats.applicableItems, 2);
      expect(stats.compliantCount, 2);
      expect(stats.nonCompliantCount, 0);
      expect(stats.inProgressCount, 0);
      expect(stats.basicCompliancePercent, 100.0);
      expect(stats.riskWeightedCompliancePercent, 100.0);
    });

    test('Boundary 1.4: 100% Non-Compliant (All applicable items non-compliant)', () {
      final assessments = [
        LegalComplianceAssessmentModel(
          id: 1, masterItemId: 'ITEM-1', requirementCode: 'ITEM-1', requirementTitle: 'T1',
          requirementDetails: 'D1', category: 'OSH_ACT', lawId: 'L1', lawTitleTh: 'LT1', articleNo: '1',
          isApplicable: true, complianceStatus: 'NON_COMPLIANT', evaluatedDate: '2026-08-31',
          evaluatorName: 'Assessor', riskLevel: 'HIGH',
        ),
        LegalComplianceAssessmentModel(
          id: 2, masterItemId: 'ITEM-2', requirementCode: 'ITEM-2', requirementTitle: 'T2',
          requirementDetails: 'D2', category: 'FIRE_SAFETY', lawId: 'L2', lawTitleTh: 'LT2', articleNo: '2',
          isApplicable: true, complianceStatus: 'NON_COMPLIANT', evaluatedDate: '2026-08-31',
          evaluatorName: 'Assessor', riskLevel: 'MEDIUM',
        ),
      ];

      final stats = LegalComplianceStatsModel.calculate(assessments: assessments);
      expect(stats.totalItems, 2);
      expect(stats.applicableItems, 2);
      expect(stats.compliantCount, 0);
      expect(stats.nonCompliantCount, 2);
      expect(stats.highRiskNonCompliantCount, 1);
      expect(stats.basicCompliancePercent, 0.0);
      expect(stats.riskWeightedCompliancePercent, 0.0);
    });

    test('Boundary 1.5: 100% In-Progress (Applicable items under remediation)', () {
      final assessments = [
        LegalComplianceAssessmentModel(
          id: 1, masterItemId: 'ITEM-1', requirementCode: 'ITEM-1', requirementTitle: 'T1',
          requirementDetails: 'D1', category: 'OSH_ACT', lawId: 'L1', lawTitleTh: 'LT1', articleNo: '1',
          isApplicable: true, complianceStatus: 'IN_PROGRESS', evaluatedDate: '2026-08-31',
          evaluatorName: 'Assessor', riskLevel: 'HIGH',
        ),
      ];

      final stats = LegalComplianceStatsModel.calculate(assessments: assessments);
      expect(stats.applicableItems, 1);
      expect(stats.inProgressCount, 1);
      expect(stats.compliantCount, 0);
      expect(stats.nonCompliantCount, 0);
      expect(stats.basicCompliancePercent, 0.0);
      expect(stats.riskWeightedCompliancePercent, 0.0);
    });
  });

  group('CHALLENGE SUITE 2: Risk-Weighted Compliance (WCI) vs Basic Compliance (CI) Sensitivity', () {
    test('High Risk Non-Compliance disproportionately suppresses WCI below CI', () {
      // Scenario: 4 Applicable items:
      // Item 1: Low Risk (W=1) -> COMPLIANT
      // Item 2: Low Risk (W=1) -> COMPLIANT
      // Item 3: Low Risk (W=1) -> COMPLIANT
      // Item 4: High Risk (W=3) -> NON_COMPLIANT
      // Total Applicable = 4
      // Compliant Count = 3 -> Basic CI = (3 / 4) * 100 = 75.0%
      // Total Weight = 1 + 1 + 1 + 3 = 6
      // Compliant Weight = 1 + 1 + 1 = 3 -> Risk-Weighted WCI = (3 / 6) * 100 = 50.0%
      final assessments = [
        LegalComplianceAssessmentModel(
          id: 1, masterItemId: 'ITEM-1', requirementCode: 'ITEM-1', requirementTitle: 'T1',
          requirementDetails: 'D1', category: 'OSH_ACT', lawId: 'L1', lawTitleTh: 'LT1', articleNo: '1',
          isApplicable: true, complianceStatus: 'COMPLIANT', evaluatedDate: '2026-08-31',
          evaluatorName: 'Assessor', riskLevel: 'LOW', // W=1
        ),
        LegalComplianceAssessmentModel(
          id: 2, masterItemId: 'ITEM-2', requirementCode: 'ITEM-2', requirementTitle: 'T2',
          requirementDetails: 'D2', category: 'OSH_ACT', lawId: 'L1', lawTitleTh: 'LT1', articleNo: '2',
          isApplicable: true, complianceStatus: 'COMPLIANT', evaluatedDate: '2026-08-31',
          evaluatorName: 'Assessor', riskLevel: 'LOW', // W=1
        ),
        LegalComplianceAssessmentModel(
          id: 3, masterItemId: 'ITEM-3', requirementCode: 'ITEM-3', requirementTitle: 'T3',
          requirementDetails: 'D3', category: 'OSH_ACT', lawId: 'L1', lawTitleTh: 'LT1', articleNo: '3',
          isApplicable: true, complianceStatus: 'COMPLIANT', evaluatedDate: '2026-08-31',
          evaluatorName: 'Assessor', riskLevel: 'LOW', // W=1
        ),
        LegalComplianceAssessmentModel(
          id: 4, masterItemId: 'ITEM-4', requirementCode: 'ITEM-4', requirementTitle: 'T4',
          requirementDetails: 'D4', category: 'OSH_ACT', lawId: 'L1', lawTitleTh: 'LT1', articleNo: '4',
          isApplicable: true, complianceStatus: 'NON_COMPLIANT', evaluatedDate: '2026-08-31',
          evaluatorName: 'Assessor', riskLevel: 'HIGH', // W=3
        ),
      ];

      final stats = LegalComplianceStatsModel.calculate(assessments: assessments);
      expect(stats.basicCompliancePercent, 75.0);
      expect(stats.riskWeightedCompliancePercent, 50.0);
      expect(stats.riskWeightedCompliancePercent < stats.basicCompliancePercent, isTrue);
      expect(stats.highRiskNonCompliantCount, 1);
    });

    test('High Risk Compliance raises WCI above CI when low risk items are non-compliant', () {
      // Scenario: 4 Applicable items:
      // Item 1: High Risk (W=3) -> COMPLIANT
      // Item 2: High Risk (W=3) -> COMPLIANT
      // Item 3: Low Risk (W=1) -> NON_COMPLIANT
      // Item 4: Low Risk (W=1) -> NON_COMPLIANT
      // Total Applicable = 4
      // Compliant Count = 2 -> Basic CI = (2 / 4) * 100 = 50.0%
      // Total Weight = 3 + 3 + 1 + 1 = 8
      // Compliant Weight = 3 + 3 = 6 -> Risk-Weighted WCI = (6 / 8) * 100 = 75.0%
      final assessments = [
        LegalComplianceAssessmentModel(
          id: 1, masterItemId: 'ITEM-1', requirementCode: 'ITEM-1', requirementTitle: 'T1',
          requirementDetails: 'D1', category: 'OSH_ACT', lawId: 'L1', lawTitleTh: 'LT1', articleNo: '1',
          isApplicable: true, complianceStatus: 'COMPLIANT', evaluatedDate: '2026-08-31',
          evaluatorName: 'Assessor', riskLevel: 'HIGH', // W=3
        ),
        LegalComplianceAssessmentModel(
          id: 2, masterItemId: 'ITEM-2', requirementCode: 'ITEM-2', requirementTitle: 'T2',
          requirementDetails: 'D2', category: 'OSH_ACT', lawId: 'L1', lawTitleTh: 'LT1', articleNo: '2',
          isApplicable: true, complianceStatus: 'COMPLIANT', evaluatedDate: '2026-08-31',
          evaluatorName: 'Assessor', riskLevel: 'HIGH', // W=3
        ),
        LegalComplianceAssessmentModel(
          id: 3, masterItemId: 'ITEM-3', requirementCode: 'ITEM-3', requirementTitle: 'T3',
          requirementDetails: 'D3', category: 'OSH_ACT', lawId: 'L1', lawTitleTh: 'LT1', articleNo: '3',
          isApplicable: true, complianceStatus: 'NON_COMPLIANT', evaluatedDate: '2026-08-31',
          evaluatorName: 'Assessor', riskLevel: 'LOW', // W=1
        ),
        LegalComplianceAssessmentModel(
          id: 4, masterItemId: 'ITEM-4', requirementCode: 'ITEM-4', requirementTitle: 'T4',
          requirementDetails: 'D4', category: 'OSH_ACT', lawId: 'L1', lawTitleTh: 'LT1', articleNo: '4',
          isApplicable: true, complianceStatus: 'NON_COMPLIANT', evaluatedDate: '2026-08-31',
          evaluatorName: 'Assessor', riskLevel: 'LOW', // W=1
        ),
      ];

      final stats = LegalComplianceStatsModel.calculate(assessments: assessments);
      expect(stats.basicCompliancePercent, 50.0);
      expect(stats.riskWeightedCompliancePercent, 75.0);
      expect(stats.riskWeightedCompliancePercent > stats.basicCompliancePercent, isTrue);
      expect(stats.highRiskNonCompliantCount, 0);
    });

    test('Rounding accuracy to 1 decimal place without floating-point drift', () {
      // 1 Compliant out of 3 applicable: 1/3 = 33.333333...% -> 33.3%
      final assessments = [
        LegalComplianceAssessmentModel(
          id: 1, masterItemId: 'ITEM-1', requirementCode: 'ITEM-1', requirementTitle: 'T1',
          requirementDetails: 'D1', category: 'OSH_ACT', lawId: 'L1', lawTitleTh: 'LT1', articleNo: '1',
          isApplicable: true, complianceStatus: 'COMPLIANT', evaluatedDate: '2026-08-31',
          evaluatorName: 'Assessor', riskLevel: 'MEDIUM', // W=2
        ),
        LegalComplianceAssessmentModel(
          id: 2, masterItemId: 'ITEM-2', requirementCode: 'ITEM-2', requirementTitle: 'T2',
          requirementDetails: 'D2', category: 'OSH_ACT', lawId: 'L1', lawTitleTh: 'LT1', articleNo: '2',
          isApplicable: true, complianceStatus: 'NON_COMPLIANT', evaluatedDate: '2026-08-31',
          evaluatorName: 'Assessor', riskLevel: 'MEDIUM', // W=2
        ),
        LegalComplianceAssessmentModel(
          id: 3, masterItemId: 'ITEM-3', requirementCode: 'ITEM-3', requirementTitle: 'T3',
          requirementDetails: 'D3', category: 'OSH_ACT', lawId: 'L1', lawTitleTh: 'LT1', articleNo: '3',
          isApplicable: true, complianceStatus: 'NON_COMPLIANT', evaluatedDate: '2026-08-31',
          evaluatorName: 'Assessor', riskLevel: 'MEDIUM', // W=2
        ),
      ];

      final stats = LegalComplianceStatsModel.calculate(assessments: assessments);
      expect(stats.basicCompliancePercent, 33.3);
      expect(stats.riskWeightedCompliancePercent, 33.3);
    });
  });

  group('CHALLENGE SUITE 3: Assessment State Machine Transitions & Invariants', () {
    test('State Transition Matrix and requiresCapa invariant', () {
      final base = LegalComplianceAssessmentModel(
        id: 10, masterItemId: 'ITEM-1', requirementCode: 'ITEM-1', requirementTitle: 'T1',
        requirementDetails: 'D1', category: 'OSH_ACT', lawId: 'L1', lawTitleTh: 'LT1', articleNo: '1',
        isApplicable: true, complianceStatus: 'NOT_APPLICABLE', evaluatedDate: '2026-08-31',
        evaluatorName: 'Assessor',
      );

      // State 1: NOT_APPLICABLE
      expect(base.isNotApplicable, isTrue);
      expect(base.isCompliant, isFalse);
      expect(base.isNonCompliant, isFalse);
      expect(base.isInProgress, isFalse);
      expect(base.requiresCapa, isFalse);

      // Transition to IN_PROGRESS
      final inProg = base.copyWith(complianceStatus: 'IN_PROGRESS');
      expect(inProg.isInProgress, isTrue);
      expect(inProg.isNotApplicable, isFalse);
      expect(inProg.requiresCapa, isTrue);

      // Transition to NON_COMPLIANT
      final nonComp = inProg.copyWith(complianceStatus: 'NON_COMPLIANT');
      expect(nonComp.isNonCompliant, isTrue);
      expect(nonComp.requiresCapa, isTrue);

      // Transition to COMPLIANT
      final comp = nonComp.copyWith(complianceStatus: 'COMPLIANT');
      expect(comp.isCompliant, isTrue);
      expect(comp.isNonCompliant, isFalse);
      expect(comp.isInProgress, isFalse);
      expect(comp.requiresCapa, isFalse);

      // Override isApplicable = false should force isNotApplicable = true
      final notAppOverride = comp.copyWith(isApplicable: false);
      expect(notAppOverride.isNotApplicable, isTrue);
      expect(notAppOverride.isCompliant, isFalse);
      expect(notAppOverride.requiresCapa, isFalse);
    });

    test('Case-insensitivity of compliance status code parser', () {
      expect(LegalComplianceStatus.fromCode('compliant'), LegalComplianceStatus.compliant);
      expect(LegalComplianceStatus.fromCode('Non_Compliant'), LegalComplianceStatus.nonCompliant);
      expect(LegalComplianceStatus.fromCode('IN_PROGRESS'), LegalComplianceStatus.inProgress);
      expect(LegalComplianceStatus.fromCode('not_applicable'), LegalComplianceStatus.notApplicable);
      expect(LegalComplianceStatus.fromCode('UNKNOWN_INVALID_CODE'), LegalComplianceStatus.notApplicable);
    });
  });

  group('CHALLENGE SUITE 4: CAPA Overdue, Lifecycle & Status Synchronization', () {
    test('CAPA Overdue Date Calculations across Past, Present, and Future Target Dates', () {
      final todayStr = DateTime.now().toIso8601String().substring(0, 10);
      final yesterdayStr = DateTime.now().subtract(const Duration(days: 1)).toIso8601String().substring(0, 10);
      final tomorrowStr = DateTime.now().add(const Duration(days: 1)).toIso8601String().substring(0, 10);
      final tenDaysFutureStr = DateTime.now().add(const Duration(days: 10)).toIso8601String().substring(0, 10);

      // 1. Past target date -> OVERDUE
      final overdueCapa = LegalCapaModel(
        id: 1, assessmentId: 100, actionTitle: 'Action 1', rootCause: 'RC 1',
        correctiveAction: 'CA 1', picName: 'PIC 1', targetDate: yesterdayStr, status: 'PENDING',
      );
      expect(overdueCapa.isOverdue, isTrue);
      expect(overdueCapa.effectiveStatusEnum, LegalCapaStatus.overdue);
      expect(overdueCapa.daysRemaining, -1);

      // 2. Today target date -> NOT OVERDUE (0 days remaining)
      final dueTodayCapa = LegalCapaModel(
        id: 2, assessmentId: 100, actionTitle: 'Action 2', rootCause: 'RC 2',
        correctiveAction: 'CA 2', picName: 'PIC 2', targetDate: todayStr, status: 'PENDING',
      );
      expect(dueTodayCapa.isOverdue, isFalse);
      expect(dueTodayCapa.effectiveStatusEnum, LegalCapaStatus.pending);
      expect(dueTodayCapa.daysRemaining, 0);

      // 3. Tomorrow target date -> NOT OVERDUE (1 day remaining)
      final dueTomorrowCapa = LegalCapaModel(
        id: 3, assessmentId: 100, actionTitle: 'Action 3', rootCause: 'RC 3',
        correctiveAction: 'CA 3', picName: 'PIC 3', targetDate: tomorrowStr, status: 'IN_PROGRESS',
      );
      expect(dueTomorrowCapa.isOverdue, isFalse);
      expect(dueTomorrowCapa.effectiveStatusEnum, LegalCapaStatus.inProgress);
      expect(dueTomorrowCapa.daysRemaining, 1);

      // 4. 10 days future target date -> NOT OVERDUE (10 days remaining)
      final futureCapa = LegalCapaModel(
        id: 4, assessmentId: 100, actionTitle: 'Action 4', rootCause: 'RC 4',
        correctiveAction: 'CA 4', picName: 'PIC 4', targetDate: tenDaysFutureStr, status: 'IN_PROGRESS',
      );
      expect(futureCapa.isOverdue, isFalse);
      expect(futureCapa.daysRemaining, 10);

      // 5. Past target date but COMPLETED -> NEVER OVERDUE
      final completedCapa = overdueCapa.copyWith(
        status: 'COMPLETED',
        completedDate: todayStr,
      );
      expect(completedCapa.isCompleted, isTrue);
      expect(completedCapa.isOverdue, isFalse);
      expect(completedCapa.effectiveStatusEnum, LegalCapaStatus.completed);
    });

    test('CAPA Aggregate Counting Invariant in Stats Calculation', () {
      final pastStr = '2020-01-01';
      final futureStr = '2030-01-01';

      final capas = [
        // 1 Completed
        LegalCapaModel(id: 1, assessmentId: 1, actionTitle: 'A1', rootCause: 'R1', correctiveAction: 'C1', picName: 'P1', targetDate: pastStr, status: 'COMPLETED', completedDate: '2020-01-02'),
        // 1 Overdue (pending with past date)
        LegalCapaModel(id: 2, assessmentId: 1, actionTitle: 'A2', rootCause: 'R2', correctiveAction: 'C2', picName: 'P2', targetDate: pastStr, status: 'PENDING'),
        // 1 Overdue (in_progress with past date)
        LegalCapaModel(id: 3, assessmentId: 1, actionTitle: 'A3', rootCause: 'R3', correctiveAction: 'C3', picName: 'P3', targetDate: pastStr, status: 'IN_PROGRESS'),
        // 1 In Progress (future date)
        LegalCapaModel(id: 4, assessmentId: 1, actionTitle: 'A4', rootCause: 'R4', correctiveAction: 'C4', picName: 'P4', targetDate: futureStr, status: 'IN_PROGRESS'),
        // 1 Pending (future date)
        LegalCapaModel(id: 5, assessmentId: 1, actionTitle: 'A5', rootCause: 'R5', correctiveAction: 'C5', picName: 'P5', targetDate: futureStr, status: 'PENDING'),
      ];

      final stats = LegalComplianceStatsModel.calculate(
        assessments: const [],
        capas: capas,
      );

      expect(stats.totalCapaCount, 5);
      expect(stats.completedCapaCount, 1);
      expect(stats.overdueCapaCount, 2);
      expect(stats.inProgressCapaCount, 1);
      expect(stats.pendingCapaCount, 1);
      // Invariant: sum of parts equals total
      expect(
        stats.completedCapaCount + stats.overdueCapaCount + stats.inProgressCapaCount + stats.pendingCapaCount,
        stats.totalCapaCount,
      );
    });
  });

  group('CHALLENGE SUITE 5: Master Dataset Integrity & Thai Legal Categories', () {
    test('All 32 master items have valid risk levels, penalties, and gazette citations', () {
      final items = SafetyLegal8CategoriesData.masterItems;
      expect(items.length, 32);

      for (final item in items) {
        expect(item.itemId.isNotEmpty, isTrue);
        expect(item.lawId.isNotEmpty, isTrue);
        expect(item.category.isNotEmpty, isTrue);
        expect(item.articleNo.isNotEmpty, isTrue);
        expect(item.title.isNotEmpty, isTrue);
        expect(item.description.isNotEmpty, isTrue);
        expect(item.applicabilityCriteria.isNotEmpty, isTrue);
        expect(item.complianceCriteria.isNotEmpty, isTrue);
        expect(item.penaltySummary.isNotEmpty, isTrue);
        expect(['HIGH', 'MEDIUM', 'LOW'].contains(item.riskLevel), isTrue);
        expect(item.riskWeight >= 1 && item.riskWeight <= 3, isTrue);
        expect(item.gazetteReference.volume != null || item.gazetteReference.publishedDate != null, isTrue);
      }
    });
  });
}
