import 'package:flutter_test/flutter_test.dart';
import 'package:safety_superapp/features/emergency/domain/enums/hazard_type.dart';
import 'package:safety_superapp/features/emergency/domain/enums/emergency_enums.dart';
import 'package:safety_superapp/features/emergency/data/models/emergency_plan_model.dart';
import 'package:safety_superapp/features/emergency/data/models/drill_session_model.dart';
import 'package:safety_superapp/features/emergency/domain/services/emergency_evaluator.dart';
import 'package:safety_superapp/features/emergency/data/datasources/emergency_presets_data.dart';

void main() {
  group('EmergencyEvaluator Unit Tests', () {
    test('40% Basic Fire Training Quota calculation per Clause 27', () {
      // 100 employees -> 40 required
      final res1 = EmergencyEvaluator.evaluateBasicFireTraining(
        totalEmployees: 100,
        currentlyTrained: 40,
      );
      expect(res1.requiredQuota, 40);
      expect(res1.isCompliant, isTrue);
      expect(res1.shortfall, 0);

      // 100 employees -> 30 trained -> shortfall 10
      final res2 = EmergencyEvaluator.evaluateBasicFireTraining(
        totalEmployees: 100,
        currentlyTrained: 30,
      );
      expect(res2.requiredQuota, 40);
      expect(res2.isCompliant, isFalse);
      expect(res2.shortfall, 10);

      // 125 employees -> ceil(125 * 0.40) = 50
      final res3 = EmergencyEvaluator.evaluateBasicFireTraining(
        totalEmployees: 125,
        currentlyTrained: 45,
      );
      expect(res3.requiredQuota, 50);
      expect(res3.shortfall, 5);
      expect(res3.isCompliant, isFalse);
    });

    test('Fire Extinguisher requirements per Clause 11', () {
      // 1000 sqm medium hazard -> ceil(1000 / 100) = 10 units
      final resMedium = EmergencyEvaluator.evaluateExtinguishers(
        areaSqm: 1000,
        hazardLevel: 'MEDIUM',
      );
      expect(resMedium.recommendedUnits, 10);
      expect(resMedium.maxTravelDistanceMeters, 20.0);
      expect(resMedium.maxInstallationHeightMeters, 1.50);

      // 1000 sqm high hazard -> ceil(1000 / 70) = 15 units
      final resHigh = EmergencyEvaluator.evaluateExtinguishers(
        areaSqm: 1000,
        hazardLevel: 'HIGH',
      );
      expect(resHigh.recommendedUnits, 15);
      expect(resHigh.maxTravelDistanceMeters, 15.0);

      // 1000 sqm light hazard -> ceil(1000 / 150) = 7 units
      final resLight = EmergencyEvaluator.evaluateExtinguishers(
        areaSqm: 1000,
        hazardLevel: 'LIGHT',
      );
      expect(resLight.recommendedUnits, 7);
      expect(resLight.maxTravelDistanceMeters, 20.0);
    });

    test('Drill Compliance & 30-day Spr.4 deadline tracking per Clause 30', () {
      final now = DateTime.now();
      final drillDateStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
      final deadlineStr = DrillSessionModel.calculateDeadline(drillDateStr);

      final drill = DrillSessionModel(
        drillTitle: 'ซ้อมดับเพลิงประจำปี',
        drillDate: drillDateStr,
        drillYear: now.year,
        totalWorkersOnSite: 100,
        participatedCount: 95,
        submissionDeadline: deadlineStr,
        organizerType: DrillOrganizerType.certifiedTrainingBody,
      );

      final audit = EmergencyEvaluator.evaluateDrillCompliance(drill, currentDate: now);
      expect(audit.isCompliant, isTrue);
      expect(audit.isOverdue, isFalse);
      expect(audit.daysRemainingToSubmitSpr4, greaterThanOrEqualTo(29));
    });

    test('Overdue Spr.4 submission is flagged accurately', () {
      final drill = DrillSessionModel(
        drillTitle: 'ซ้อมดับเพลิงที่ผ่านมาแล้ว 40 วัน',
        drillDate: '2025-01-01',
        drillYear: 2025,
        totalWorkersOnSite: 100,
        participatedCount: 95,
        submissionDeadline: '2025-01-31',
        spr4SubmissionStatus: Spr4SubmissionStatus.pending,
      );

      final testDate = DateTime(2025, 2, 15); // 15 days past Jan 31 deadline
      final audit = EmergencyEvaluator.evaluateDrillCompliance(drill, currentDate: testDate);
      expect(audit.isOverdue, isTrue);
      expect(audit.isCompliant, isFalse);
      expect(audit.issues.any((msg) => msg.contains('เกินกำหนดเวลา')), isTrue);
    });

    test('Preset completeness evaluation for Factory Fire Plan', () {
      final preset = EmergencyPresetsData.getPreset(
        hazardType: HazardType.fire,
        businessType: BusinessType.factory,
      );

      final audit = EmergencyEvaluator.evaluatePlanCompleteness(preset);
      expect(audit.isFullyCompliant, isTrue);
      expect(audit.completenessScore, greaterThanOrEqualTo(90));
      expect(audit.missingPillars.isEmpty, isTrue);
    });
  });
}
