import 'package:flutter_test/flutter_test.dart';
import 'package:safety_superapp/features/environment/domain/models/environment_standard_model.dart';
import 'package:safety_superapp/features/environment/domain/models/environment_point_model.dart';
import 'package:safety_superapp/features/environment/domain/models/environment_capa_model.dart';
import 'package:safety_superapp/features/environment/domain/models/subcontractor_model.dart';
import 'package:safety_superapp/features/environment/domain/services/environmental_evaluator.dart';
import 'package:safety_superapp/features/environment/domain/services/subcontractor_verifier.dart';
import 'package:safety_superapp/features/environment/data/environmental_standards_data.dart';
import 'package:safety_superapp/features/environment/data/environmental_gazette_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // =========================================================================
  // 1. Master Standards & Gazette Data Tests
  // =========================================================================
  group('1. Master Standards & Gazette Metadata Catalog Tests', () {
    test('Master catalog contains all statutory standards', () {
      final standards = EnvironmentalStandardsData.masterStandards;
      expect(standards.length, greaterThanOrEqualTo(14));

      final light = EnvironmentalStandardsData.lightingStandards;
      final noise = EnvironmentalStandardsData.noiseStandards;
      final heat = EnvironmentalStandardsData.heatStandards;

      expect(light.length, 13); // 6 Cat1 + 7 Cat2
      expect(noise.length, 4); // TWA, Action Level, Continuous ceiling, Peak
      expect(heat.length, 3); // Light, Moderate, Heavy
    });

    test('Exact lookup by standard_id retrieves correct standard', () {
      final officeLight = EnvironmentalStandardsData.findById('LIGHT-CAT2-04');
      expect(officeLight, isNotNull);
      expect(officeLight!.minLux, 300.0);
      expect(officeLight.categoryNameTh, contains('สำนักงาน'));

      final heavyHeat = EnvironmentalStandardsData.findById('HEAT-HEAVY-WORK');
      expect(heavyHeat, isNotNull);
      expect(heavyHeat!.wbgtLimitCelsius, 30.0);
      expect(heavyHeat.workLoadType, WorkloadLevel.heavy);

      final noiseTwa = EnvironmentalStandardsData.findById('NOISE-TWA-8HR');
      expect(noiseTwa, isNotNull);
      expect(noiseTwa!.noiseTwaLimitDba, 86.0);
      expect(noiseTwa.noiseActionLevelDba, 85.0);
    });

    test('Gazette catalog contains 6 statutory Thai laws and notifications', () {
      final gazettes = EnvironmentalGazetteData.gazetteList;
      expect(gazettes.length, 6);

      final act = EnvironmentalGazetteData.findByLawId('LAW-OSH-2554');
      expect(act, isNotNull);
      expect(act!.keyArticles.any((a) => a.contains('มาตรา ๙')), isTrue);
      expect(act.keyArticles.any((a) => a.contains('มาตรา ๑๑')), isTrue);
      expect(act.keyArticles.any((a) => a.contains('มาตรา ๑๕')), isTrue);

      final heatNotif = EnvironmentalGazetteData.findByLawId('LAW-HEAT-NOTIF-2563');
      expect(heatNotif, isNotNull);
      expect(heatNotif!.titleTh, contains('ความร้อน'));
    });
  });

  // =========================================================================
  // 2. Lighting Evaluator Tests (DLPW 2561)
  // =========================================================================
  group('2. Lighting Evaluation Engine Tests', () {
    test('Workstation meeting standard min Lux -> PASS', () {
      // General Office standard: 300 Lux
      final result = EnvironmentalEvaluator.evaluateLighting(
        measuredLux: 350.0,
        standardId: 'LIGHT-CAT2-04',
      );

      expect(result.isCompliant, isTrue);
      expect(result.status, EnvironmentEvaluationStatus.pass);
      expect(result.deficitLux, 0.0);
      expect(result.hasSurroundingWarning, isFalse);
    });

    test('Workstation below standard min Lux -> FAIL with deficit calculated', () {
      // Fine Task standard: 400 Lux
      final result = EnvironmentalEvaluator.evaluateLighting(
        measuredLux: 280.0,
        standardId: 'LIGHT-CAT2-05',
      );

      expect(result.isCompliant, isFalse);
      expect(result.status, EnvironmentEvaluationStatus.fail);
      expect(result.deficitLux, 120.0);
      expect(result.summaryTh, contains('ไม่ผ่านเกณฑ์'));
    });

    test('Surrounding area warning triggered when surrounding < 1/3 of task area', () {
      // Measured task = 450 Lux (Standard = 400 Lux, pass), surrounding = 120 Lux (120/450 = 0.267 < 0.333)
      final result = EnvironmentalEvaluator.evaluateLighting(
        measuredLux: 450.0,
        standardId: 'LIGHT-CAT2-05',
        surroundingLux: 120.0,
      );

      expect(result.isCompliant, isTrue);
      expect(result.hasSurroundingWarning, isTrue);
      expect(result.surroundingRatio, closeTo(0.267, 0.01));
      expect(result.summaryTh, contains('ข้อควรระวัง'));
    });

    test('Surrounding area compliant when surrounding >= 1/3 of task area', () {
      final result = EnvironmentalEvaluator.evaluateLighting(
        measuredLux: 450.0,
        standardId: 'LIGHT-CAT2-05',
        surroundingLux: 200.0,
      );

      expect(result.isCompliant, isTrue);
      expect(result.hasSurroundingWarning, isFalse);
    });
  });

  // =========================================================================
  // 3. Noise Evaluator Tests (DLPW 2561 & Reg 2559)
  // =========================================================================
  group('3. Noise Evaluation Engine Tests', () {
    test('Permissible duration formula T = 8 / 2^((L-86)/3)', () {
      expect(EnvironmentalEvaluator.calculatePermissibleDuration(86.0), closeTo(8.0, 0.001));
      expect(EnvironmentalEvaluator.calculatePermissibleDuration(89.0), closeTo(4.0, 0.001));
      expect(EnvironmentalEvaluator.calculatePermissibleDuration(92.0), closeTo(2.0, 0.001));
      expect(EnvironmentalEvaluator.calculatePermissibleDuration(95.0), closeTo(1.0, 0.001));
      expect(EnvironmentalEvaluator.calculatePermissibleDuration(83.0), closeTo(16.0, 0.001));
      expect(EnvironmentalEvaluator.calculatePermissibleDuration(80.0), closeTo(32.0, 0.001));
    });

    test('Noise Dose and TWA calculation round-trip', () {
      // 86 dBA for 8 hrs -> Dose = 100%, TWA = 86.0 dBA
      final dose86 = EnvironmentalEvaluator.calculateNoiseDose(86.0, 8.0);
      expect(dose86, closeTo(100.0, 0.1));
      final twa86 = EnvironmentalEvaluator.calculateNoiseTwa(dose86);
      expect(twa86, closeTo(86.0, 0.1));

      // 89 dBA for 4 hrs -> Dose = 100%, TWA = 86.0 dBA
      final dose89 = EnvironmentalEvaluator.calculateNoiseDose(89.0, 4.0);
      expect(dose89, closeTo(100.0, 0.1));

      // 85 dBA for 8 hrs -> Dose ~ 79.37%, TWA ~ 85.0 dBA
      final dose85 = EnvironmentalEvaluator.calculateNoiseDose(85.0, 8.0);
      expect(dose85, closeTo(79.37, 0.2));
      final twa85 = EnvironmentalEvaluator.calculateNoiseTwa(dose85);
      expect(twa85, closeTo(85.0, 0.1));
    });

    test('Normal Noise Level (< 85 dBA for 8 hrs) -> Tier NORMAL, PASS, No HCP', () {
      final result = EnvironmentalEvaluator.evaluateNoise(
        measuredDba: 82.0,
        type: NoiseMeasurementType.leq8hrTwa,
        durationHours: 8.0,
      );

      expect(result.status, EnvironmentEvaluationStatus.pass);
      expect(result.evaluationTier, 'NORMAL');
      expect(result.isStandardExceeded, isFalse);
      expect(result.isHcpRequired, isFalse);
    });

    test('Action Level (85.0 - 86.0 dBA for 8 hrs) -> Tier ACTION_LEVEL_HCP, HCP Required', () {
      final result = EnvironmentalEvaluator.evaluateNoise(
        measuredDba: 85.2,
        type: NoiseMeasurementType.leq8hrTwa,
        durationHours: 8.0,
      );

      expect(result.status, EnvironmentEvaluationStatus.actionLevel);
      expect(result.evaluationTier, 'ACTION_LEVEL_HCP');
      expect(result.isStandardExceeded, isFalse);
      expect(result.isHcpRequired, isTrue);
      expect(result.summaryTh, contains('อนุรักษ์การได้ยิน'));
    });

    test('Exceeded Standard Level (> 86.0 dBA for 8 hrs) -> Tier EXCEEDED_STANDARD, FAIL', () {
      final result = EnvironmentalEvaluator.evaluateNoise(
        measuredDba: 88.5,
        type: NoiseMeasurementType.leq8hrTwa,
        durationHours: 8.0,
      );

      expect(result.status, EnvironmentEvaluationStatus.fail);
      expect(result.evaluationTier, 'EXCEEDED_STANDARD');
      expect(result.isStandardExceeded, isTrue);
      expect(result.isHcpRequired, isTrue);
    });

    test('Peak sound level exceeding 140 dB -> Immediate Critical FAIL', () {
      final result = EnvironmentalEvaluator.evaluateNoise(
        measuredDba: 78.0, // TWA is low
        type: NoiseMeasurementType.peakSoundLevel,
        durationHours: 8.0,
        peakDb: 142.5, // Exceeds 140 dB
      );

      expect(result.status, EnvironmentEvaluationStatus.fail);
      expect(result.isPeakExceeded, isTrue);
      expect(result.isStandardExceeded, isTrue);
      expect(result.summaryTh, contains('140 dB'));
    });

    test('Continuous ceiling >= 115 dBA -> Immediate Critical FAIL', () {
      final result = EnvironmentalEvaluator.evaluateNoise(
        measuredDba: 116.0,
        type: NoiseMeasurementType.areaNoise,
        durationHours: 0.1,
      );

      expect(result.status, EnvironmentEvaluationStatus.fail);
      expect(result.isCeilingExceeded, isTrue);
      expect(result.isStandardExceeded, isTrue);
      expect(result.summaryTh, contains('115 dBA'));
    });
  });

  // =========================================================================
  // 4. Heat WBGT Evaluator Tests (DLPW 2563 & Reg 2559)
  // =========================================================================
  group('4. Heat WBGT Evaluation Engine Tests', () {
    test('Indoor WBGT calculation: 0.7 * NWB + 0.3 * GT', () {
      // NWB = 28.0, GT = 35.0 -> 0.7(28) + 0.3(35) = 19.6 + 10.5 = 30.1
      final wbgt = EnvironmentalEvaluator.calculateWbgt(
        nwb: 28.0,
        gt: 35.0,
        isOutdoor: false,
      );
      expect(wbgt, closeTo(30.1, 0.01));
    });

    test('Outdoor WBGT calculation: 0.7 * NWB + 0.2 * GT + 0.1 * DB', () {
      // NWB = 28.0, GT = 40.0, DB = 36.0 -> 0.7(28) + 0.2(40) + 0.1(36) = 19.6 + 8.0 + 3.6 = 31.2
      final wbgt = EnvironmentalEvaluator.calculateWbgt(
        nwb: 28.0,
        gt: 40.0,
        db: 36.0,
        isOutdoor: true,
      );
      expect(wbgt, closeTo(31.2, 0.01));
    });

    test('Heat evaluation Light Work (Limit 34.0°C) -> Compliant', () {
      final result = EnvironmentalEvaluator.evaluateHeat(
        nwb: 29.0,
        gt: 38.0,
        isOutdoor: false,
        workload: WorkloadLevel.light, // Limit = 34.0°C
      );
      // WBGT = 0.7(29) + 0.3(38) = 20.3 + 11.4 = 31.7°C <= 34.0°C
      expect(result.calculatedWbgt, closeTo(31.7, 0.01));
      expect(result.isCompliant, isTrue);
      expect(result.status, EnvironmentEvaluationStatus.pass);
      expect(result.exceededMargin, 0.0);
    });

    test('Heat evaluation Moderate Work (Limit 32.0°C) -> Exceeded FAIL', () {
      final result = EnvironmentalEvaluator.evaluateHeat(
        nwb: 30.0,
        gt: 42.0,
        isOutdoor: false,
        workload: WorkloadLevel.moderate, // Limit = 32.0°C
      );
      // WBGT = 0.7(30) + 0.3(42) = 21.0 + 12.6 = 33.6°C > 32.0°C
      expect(result.calculatedWbgt, closeTo(33.6, 0.01));
      expect(result.isCompliant, isFalse);
      expect(result.status, EnvironmentEvaluationStatus.fail);
      expect(result.exceededMargin, closeTo(1.6, 0.01));
    });

    test('Heat evaluation Heavy Work (Limit 30.0°C) -> Exceeded FAIL', () {
      final result = EnvironmentalEvaluator.evaluateHeat(
        nwb: 28.5,
        gt: 37.0,
        isOutdoor: false,
        workload: WorkloadLevel.heavy, // Limit = 30.0°C
      );
      // WBGT = 0.7(28.5) + 0.3(37) = 19.95 + 11.1 = 31.05°C > 30.0°C
      expect(result.calculatedWbgt, closeTo(31.05, 0.01));
      expect(result.isCompliant, isFalse);
      expect(result.status, EnvironmentEvaluationStatus.fail);
      expect(result.exceededMargin, closeTo(1.05, 0.01));
    });

    test('Time-weighted WBGT multi-stage cycle calculation', () {
      // 40 mins at WBGT 32°C (Moderate 280 kcal/hr) + 20 mins at WBGT 26°C in rest room (Light 100 kcal/hr)
      // Total = 60 mins
      // Avg WBGT = (32*40 + 26*20) / 60 = (1280 + 520) / 60 = 1800 / 60 = 30.0°C
      // Avg Meta = (280*40 + 100*20) / 60 = (11200 + 2000) / 60 = 13200 / 60 = 220 kcal/hr -> Moderate (Limit 32°C)
      // 30.0 <= 32.0 -> Compliant!
      final stages = [
        (wbgt: 32.0, minutes: 40.0, metabolicRate: 280.0),
        (wbgt: 26.0, minutes: 20.0, metabolicRate: 100.0),
      ];
      final twa = EnvironmentalEvaluator.calculateTimeWeightedWbgt(stages);
      expect(twa.twaWbgt, closeTo(30.0, 0.01));
      expect(twa.twaMetabolicRate, closeTo(220.0, 0.1));
      expect(twa.effectiveWorkload, WorkloadLevel.moderate);
      expect(twa.isCompliant, isTrue);
    });
  });

  // =========================================================================
  // 5. Subcontractor Verifier Tests (Section 9 / 11)
  // =========================================================================
  group('5. Subcontractor Verifier & Deadlines Tests', () {
    test('Valid Section 9 Individual with นบ. prefix', () {
      final result = SubcontractorVerifier.validate(
        type: SubcontractorType.section9Individual,
        licenseNumber: 'นบ. 0123-45/2566',
        expireDate: DateTime.now().add(const Duration(days: 180)),
      );

      expect(result.isValid, isTrue);
      expect(result.status, SubcontractorValidationStatus.valid);
    });

    test('Valid Section 11 Juristic with บ. prefix', () {
      final result = SubcontractorVerifier.validate(
        type: SubcontractorType.section11Juristic,
        licenseNumber: 'บ. 0045-12/2565',
        expireDate: DateTime.now().add(const Duration(days: 90)),
      );

      expect(result.isValid, isTrue);
      expect(result.status, SubcontractorValidationStatus.valid);
    });

    test('Prefix mismatch: Section 11 selected but นบ. prefix provided -> INVALID', () {
      final result = SubcontractorVerifier.validate(
        type: SubcontractorType.section11Juristic,
        licenseNumber: 'นบ. 0123-45/2566',
      );

      expect(result.isValid, isFalse);
      expect(result.status, SubcontractorValidationStatus.invalidPrefixMismatch);
      expect(result.messageTh, contains('"บ."'));
    });

    test('Expired license detection', () {
      final pastDate = DateTime.now().subtract(const Duration(days: 10));
      final result = SubcontractorVerifier.validate(
        type: SubcontractorType.section9Individual,
        licenseNumber: 'นบ. 0001-01/2560',
        expireDate: pastDate,
      );

      expect(result.isValid, isFalse);
      expect(result.status, SubcontractorValidationStatus.expired);
      expect(result.daysRemaining! < 0, isTrue);
    });

    test('Statutory Deadlines calculation: Posting (15 days) & Submission (30 days)', () {
      final measDate = DateTime(2026, 9, 1);
      final deadlines = SubcontractorVerifier.calculateStatutoryDeadlines(measDate);

      expect(deadlines.postingDeadline, DateTime(2026, 9, 16));
      expect(deadlines.submissionDeadline, DateTime(2026, 10, 1));
    });
  });

  // =========================================================================
  // 6. Overall KPI Calculation Engine Tests
  // =========================================================================
  group('6. Overall KPI Calculation Engine Tests', () {
    test('100% compliant scenario calculation', () {
      final points = [
        EnvironmentPointModel(
          pointId: 'PT-1',
          sessionId: 'S1',
          factorType: EnvironmentFactorType.light,
          department: 'Assembly',
          locationName: 'Table 1',
          evaluationStatus: EnvironmentEvaluationStatus.pass,
          lightMeasuredLux: 400.0,
          lightStandardMinLux: 300.0,
        ),
        EnvironmentPointModel(
          pointId: 'PT-2',
          sessionId: 'S1',
          factorType: EnvironmentFactorType.noise,
          department: 'Machining',
          locationName: 'CNC-01',
          evaluationStatus: EnvironmentEvaluationStatus.pass,
          noiseMeasuredDba: 82.0,
        ),
        EnvironmentPointModel(
          pointId: 'PT-3',
          sessionId: 'S1',
          factorType: EnvironmentFactorType.heat,
          department: 'Boiler',
          locationName: 'Room 1',
          evaluationStatus: EnvironmentEvaluationStatus.pass,
          heatCalculatedWbgt: 29.0,
          heatStandardLimitWbgt: 32.0,
        ),
      ];

      final kpi = EnvironmentalEvaluator.calculateKpi(points);
      expect(kpi.totalPoints, 3);
      expect(kpi.passedPoints, 3);
      expect(kpi.failedPoints, 0);
      expect(kpi.actionLevelPoints, 0);
      expect(kpi.compliancePercentage, 100.0);
      expect(kpi.lightCompliancePercentage, 100.0);
      expect(kpi.noiseCompliancePercentage, 100.0);
      expect(kpi.heatCompliancePercentage, 100.0);
    });

    test('Mixed points with Action Level, Failed points, and CAPA metrics', () {
      final points = [
        // Light Pass
        EnvironmentPointModel(
          pointId: 'PT-1',
          sessionId: 'S1',
          factorType: EnvironmentFactorType.light,
          department: 'Assembly',
          locationName: 'Line 1',
          evaluationStatus: EnvironmentEvaluationStatus.pass,
          lightMeasuredLux: 350.0,
        ),
        // Light Fail
        EnvironmentPointModel(
          pointId: 'PT-2',
          sessionId: 'S1',
          factorType: EnvironmentFactorType.light,
          department: 'Warehouse',
          locationName: 'Aisle 2',
          evaluationStatus: EnvironmentEvaluationStatus.fail,
          lightMeasuredLux: 80.0,
        ),
        // Noise Action Level (HCP Required)
        EnvironmentPointModel(
          pointId: 'PT-3',
          sessionId: 'S1',
          factorType: EnvironmentFactorType.noise,
          department: 'Press',
          locationName: 'P-01',
          evaluationStatus: EnvironmentEvaluationStatus.actionLevel,
          noiseMeasuredDba: 85.5,
          noiseIsHcpRequired: true,
        ),
        // Heat Pass
        EnvironmentPointModel(
          pointId: 'PT-4',
          sessionId: 'S1',
          factorType: EnvironmentFactorType.heat,
          department: 'Foundry',
          locationName: 'Furnace',
          evaluationStatus: EnvironmentEvaluationStatus.pass,
          heatCalculatedWbgt: 31.0,
        ),
      ];

      final capas = [
        EnvironmentCapaModel(
          capaId: 'CAPA-1',
          sessionId: 'S1',
          factorType: EnvironmentFactorType.light,
          actionTitle: 'เพิ่มหลอดไฟ LED',
          hazardDescription: 'แสงสว่างไม่พอ',
          rootCause: 'หลอดไฟขาด',
          picName: 'จป.',
          targetDate: '2026-10-01',
          status: 'IN_PROGRESS',
        ),
        EnvironmentCapaModel(
          capaId: 'CAPA-2',
          sessionId: 'S1',
          factorType: EnvironmentFactorType.noise,
          actionTitle: 'โครงการอนุรักษ์การได้ยิน',
          hazardDescription: 'เสียงระดับ 85.5 dBA',
          rootCause: 'เครื่องจักรปั๊มโลหะ',
          picName: 'จป.',
          targetDate: '2026-10-01',
          status: 'COMPLETED',
          completedDate: '2026-09-01',
          hearingProgramEnrolled: true,
        ),
      ];

      // Total = 4 points: 2 Passed (PT-1, PT-4), 1 Action Level (PT-3), 1 Failed (PT-2)
      // Overall compliance = (2 / 4) * 100 = 50.0%
      // Light compliance = (1 / 2) * 100 = 50.0%
      // Noise compliance = (0 / 1) * 100 = 0.0%
      // Heat compliance = (1 / 1) * 100 = 100.0%

      final kpi = EnvironmentalEvaluator.calculateKpi(points, capas: capas);
      expect(kpi.totalPoints, 4);
      expect(kpi.passedPoints, 2);
      expect(kpi.actionLevelPoints, 1);
      expect(kpi.failedPoints, 1);
      expect(kpi.compliancePercentage, 50.0);
      expect(kpi.lightCompliancePercentage, 50.0);
      expect(kpi.noiseCompliancePercentage, 0.0);
      expect(kpi.heatCompliancePercentage, 100.0);
      expect(kpi.hcpRequiredCount, 1);
      expect(kpi.capaTotalCount, 2);
      expect(kpi.capaCompletedCount, 1);
      expect(kpi.capaPendingCount, 1);
    });

    test('Zero points protection -> 100% compliance defaults', () {
      final kpi = EnvironmentalEvaluator.calculateKpi([]);
      expect(kpi.totalPoints, 0);
      expect(kpi.compliancePercentage, 100.0);
      expect(kpi.lightCompliancePercentage, 100.0);
      expect(kpi.noiseCompliancePercentage, 100.0);
      expect(kpi.heatCompliancePercentage, 100.0);
    });
  });
}
