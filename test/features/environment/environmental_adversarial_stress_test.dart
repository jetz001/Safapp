import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:excel/excel.dart';

import 'package:safety_superapp/features/environment/domain/models/environment_standard_model.dart';
import 'package:safety_superapp/features/environment/domain/models/environment_session_model.dart';
import 'package:safety_superapp/features/environment/domain/models/environment_point_model.dart';
import 'package:safety_superapp/features/environment/domain/models/environment_capa_model.dart';
import 'package:safety_superapp/features/environment/domain/models/environment_kpi_summary.dart';
import 'package:safety_superapp/features/environment/domain/models/subcontractor_model.dart';
import 'package:safety_superapp/features/environment/domain/services/environmental_evaluator.dart';
import 'package:safety_superapp/features/environment/domain/services/subcontractor_verifier.dart';
import 'package:safety_superapp/features/environment/data/environmental_standards_data.dart';
import 'package:safety_superapp/features/environment/data/environmental_gazette_data.dart';
import 'package:safety_superapp/features/environment/services/environment_pdf_exporter.dart';
import 'package:safety_superapp/features/environment/services/environment_excel_exporter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // =========================================================================
  // 1. WBGT Extreme Boundary & Precision Stress Tests
  // =========================================================================
  group('1. WBGT Extreme Boundary & Precision Stress Tests', () {
    test('Indoor WBGT extreme boundary: NWB = GT = 50.0°C', () {
      final wbgt = EnvironmentalEvaluator.calculateWbgt(
        nwb: 50.0,
        gt: 50.0,
        isOutdoor: false,
      );
      // 0.7 * 50 + 0.3 * 50 = 50.0
      expect(wbgt, 50.0);
    });

    test('Outdoor WBGT extreme boundary: NWB = GT = DB = 50.0°C', () {
      final wbgt = EnvironmentalEvaluator.calculateWbgt(
        nwb: 50.0,
        gt: 50.0,
        db: 50.0,
        isOutdoor: true,
      );
      // 0.7 * 50 + 0.2 * 50 + 0.1 * 50 = 50.0
      expect(wbgt, 50.0);
    });

    test('Outdoor WBGT with high Dry Bulb: NWB=30, GT=45, DB=65°C', () {
      final wbgt = EnvironmentalEvaluator.calculateWbgt(
        nwb: 30.0,
        gt: 45.0,
        db: 65.0,
        isOutdoor: true,
      );
      // 0.7 * 30 + 0.2 * 45 + 0.1 * 65 = 21.0 + 9.0 + 6.5 = 36.5°C
      expect(wbgt, 36.5);
    });

    test('Outdoor WBGT defaults DB to GT when DB is null', () {
      final wbgt = EnvironmentalEvaluator.calculateWbgt(
        nwb: 28.0,
        gt: 40.0,
        db: null,
        isOutdoor: true,
      );
      // 0.7 * 28 + 0.2 * 40 + 0.1 * 40 = 19.6 + 8.0 + 4.0 = 31.6°C
      expect(wbgt, 31.6);
    });

    test('Negative temperatures (e.g. cold storage): NWB = -10°C, GT = -5°C', () {
      final wbgt = EnvironmentalEvaluator.calculateWbgt(
        nwb: -10.0,
        gt: -5.0,
        isOutdoor: false,
      );
      // 0.7 * (-10) + 0.3 * (-5) = -7.0 - 1.5 = -8.5°C
      expect(wbgt, -8.5);

      final eval = EnvironmentalEvaluator.evaluateHeat(
        nwb: -10.0,
        gt: -5.0,
        isOutdoor: false,
        workload: WorkloadLevel.light,
      );
      expect(eval.calculatedWbgt, -8.5);
      expect(eval.isCompliant, isTrue);
      expect(eval.exceededMargin, 0.0);
      expect(eval.status, EnvironmentEvaluationStatus.pass);
    });

    test('Floating point precision & rounding (2 decimal places)', () {
      // 0.7 * 29.333333 + 0.3 * 37.777777 = 20.5333331 + 11.3333331 = 31.8666662 -> 31.87
      final wbgt = EnvironmentalEvaluator.calculateWbgt(
        nwb: 29.333333,
        gt: 37.777777,
        isOutdoor: false,
      );
      expect(wbgt, 31.87);
    });

    test('Workload statutory limit boundaries (Light=34.0, Moderate=32.0, Heavy=30.0)', () {
      // Light work exact boundary 34.00°C -> Compliant
      final lightExact = EnvironmentalEvaluator.evaluateHeat(
        nwb: 34.0,
        gt: 34.0,
        isOutdoor: false,
        workload: WorkloadLevel.light,
      );
      expect(lightExact.calculatedWbgt, 34.0);
      expect(lightExact.isCompliant, isTrue);
      expect(lightExact.status, EnvironmentEvaluationStatus.pass);
      expect(lightExact.exceededMargin, 0.0);

      // Light work slightly exceeded 34.01°C -> Fail
      final lightExceed = EnvironmentalEvaluator.evaluateHeat(
        nwb: 34.01,
        gt: 34.01,
        isOutdoor: false,
        workload: WorkloadLevel.light,
      );
      expect(lightExceed.calculatedWbgt, 34.01);
      expect(lightExceed.isCompliant, isFalse);
      expect(lightExceed.status, EnvironmentEvaluationStatus.fail);
      expect(lightExceed.exceededMargin, closeTo(0.01, 0.001));

      // Moderate work exact boundary 32.00°C -> Compliant
      final modExact = EnvironmentalEvaluator.evaluateHeat(
        nwb: 32.0,
        gt: 32.0,
        isOutdoor: false,
        workload: WorkloadLevel.moderate,
      );
      expect(modExact.calculatedWbgt, 32.0);
      expect(modExact.isCompliant, isTrue);
      expect(modExact.status, EnvironmentEvaluationStatus.pass);

      // Moderate work 32.01°C -> Fail
      final modExceed = EnvironmentalEvaluator.evaluateHeat(
        nwb: 32.01,
        gt: 32.01,
        isOutdoor: false,
        workload: WorkloadLevel.moderate,
      );
      expect(modExceed.calculatedWbgt, 32.01);
      expect(modExceed.isCompliant, isFalse);
      expect(modExceed.status, EnvironmentEvaluationStatus.fail);

      // Heavy work exact boundary 30.00°C -> Compliant
      final heavyExact = EnvironmentalEvaluator.evaluateHeat(
        nwb: 30.0,
        gt: 30.0,
        isOutdoor: false,
        workload: WorkloadLevel.heavy,
      );
      expect(heavyExact.calculatedWbgt, 30.0);
      expect(heavyExact.isCompliant, isTrue);
      expect(heavyExact.status, EnvironmentEvaluationStatus.pass);

      // Heavy work 30.01°C -> Fail
      final heavyExceed = EnvironmentalEvaluator.evaluateHeat(
        nwb: 30.01,
        gt: 30.01,
        isOutdoor: false,
        workload: WorkloadLevel.heavy,
      );
      expect(heavyExceed.calculatedWbgt, 30.01);
      expect(heavyExceed.isCompliant, isFalse);
      expect(heavyExceed.status, EnvironmentEvaluationStatus.fail);
    });

    test('Multi-stage TWA WBGT: handles empty list without crash', () {
      final result = EnvironmentalEvaluator.calculateTimeWeightedWbgt([]);
      expect(result.twaWbgt, 0.0);
      expect(result.twaMetabolicRate, 0.0);
      expect(result.effectiveWorkload, WorkloadLevel.light);
      expect(result.isCompliant, isTrue);
    });

    test('Multi-stage TWA WBGT: handles zero total minutes safely', () {
      final result = EnvironmentalEvaluator.calculateTimeWeightedWbgt([
        (wbgt: 32.0, minutes: 0.0, metabolicRate: 200.0),
        (wbgt: 35.0, minutes: 0.0, metabolicRate: 350.0),
      ]);
      expect(result.twaWbgt, 0.0);
      expect(result.twaMetabolicRate, 0.0);
      expect(result.isCompliant, isTrue);
    });

    test('Multi-stage TWA WBGT: transition boundaries for metabolic rates', () {
      // Exactly 200 kcal/hr -> Light
      final r200 = EnvironmentalEvaluator.calculateTimeWeightedWbgt([
        (wbgt: 33.0, minutes: 60.0, metabolicRate: 200.0),
      ]);
      expect(r200.effectiveWorkload, WorkloadLevel.light);
      expect(r200.isCompliant, isTrue); // 33 <= 34

      // 200.1 kcal/hr -> Moderate (Limit 32)
      final r201 = EnvironmentalEvaluator.calculateTimeWeightedWbgt([
        (wbgt: 33.0, minutes: 60.0, metabolicRate: 200.1),
      ]);
      expect(r201.effectiveWorkload, WorkloadLevel.moderate);
      expect(r201.isCompliant, isFalse); // 33 > 32

      // Exactly 350 kcal/hr -> Moderate (Limit 32)
      final r350 = EnvironmentalEvaluator.calculateTimeWeightedWbgt([
        (wbgt: 32.0, minutes: 60.0, metabolicRate: 350.0),
      ]);
      expect(r350.effectiveWorkload, WorkloadLevel.moderate);
      expect(r350.isCompliant, isTrue); // 32 <= 32

      // 350.1 kcal/hr -> Heavy (Limit 30)
      final r351 = EnvironmentalEvaluator.calculateTimeWeightedWbgt([
        (wbgt: 32.0, minutes: 60.0, metabolicRate: 350.1),
      ]);
      expect(r351.effectiveWorkload, WorkloadLevel.heavy);
      expect(r351.isCompliant, isFalse); // 32 > 30
    });
  });

  // =========================================================================
  // 2. Noise Exposure Edge Cases & Statutory Limits
  // =========================================================================
  group('2. Noise Exposure Edge Cases & Statutory Limits', () {
    test('Action Level boundary: exactly 85.0 dBA for 8 hours', () {
      final res85 = EnvironmentalEvaluator.evaluateNoise(
        measuredDba: 85.0,
        type: NoiseMeasurementType.leq8hrTwa,
        durationHours: 8.0,
      );
      expect(res85.twa8hrDba, 85.0);
      expect(res85.isStandardExceeded, isFalse);
      expect(res85.isHcpRequired, isTrue);
      expect(res85.status, EnvironmentEvaluationStatus.actionLevel);
      expect(res85.evaluationTier, 'ACTION_LEVEL_HCP');
    });

    test('Action Level boundary: 84.99 dBA for 8 hours -> NORMAL / PASS', () {
      final res8499 = EnvironmentalEvaluator.evaluateNoise(
        measuredDba: 84.99,
        type: NoiseMeasurementType.leq8hrTwa,
        durationHours: 8.0,
      );
      expect(res8499.twa8hrDba, 84.99);
      expect(res8499.isStandardExceeded, isFalse);
      expect(res8499.isHcpRequired, isFalse);
      expect(res8499.status, EnvironmentEvaluationStatus.pass);
      expect(res8499.evaluationTier, 'NORMAL');
    });

    test('Standard limit boundary: exactly 86.0 dBA for 8 hours', () {
      final res86 = EnvironmentalEvaluator.evaluateNoise(
        measuredDba: 86.0,
        type: NoiseMeasurementType.leq8hrTwa,
        durationHours: 8.0,
      );
      expect(res86.twa8hrDba, 86.0);
      expect(res86.noiseDosePercent, closeTo(100.0, 0.01));
      expect(res86.isStandardExceeded, isFalse);
      expect(res86.isHcpRequired, isTrue);
      expect(res86.status, EnvironmentEvaluationStatus.actionLevel);
      expect(res86.evaluationTier, 'ACTION_LEVEL_HCP');
    });

    test('Standard limit boundary: 86.01 dBA for 8 hours -> EXCEEDED / FAIL', () {
      final res8601 = EnvironmentalEvaluator.evaluateNoise(
        measuredDba: 86.01,
        type: NoiseMeasurementType.leq8hrTwa,
        durationHours: 8.0,
      );
      expect(res8601.isStandardExceeded, isTrue);
      expect(res8601.isHcpRequired, isTrue);
      expect(res8601.status, EnvironmentEvaluationStatus.fail);
      expect(res8601.evaluationTier, 'EXCEEDED_STANDARD');
    });

    test('Continuous noise ceiling limit: 115.0 dBA vs 115.1 dBA vs 114.99 dBA', () {
      // 115.0 dBA -> immediate ceiling fail
      final res115 = EnvironmentalEvaluator.evaluateNoise(
        measuredDba: 115.0,
        type: NoiseMeasurementType.areaNoise,
        durationHours: 0.01,
      );
      expect(res115.isCeilingExceeded, isTrue);
      expect(res115.isStandardExceeded, isTrue);
      expect(res115.status, EnvironmentEvaluationStatus.fail);

      // 115.1 dBA -> immediate ceiling fail
      final res1151 = EnvironmentalEvaluator.evaluateNoise(
        measuredDba: 115.1,
        type: NoiseMeasurementType.areaNoise,
        durationHours: 0.01,
      );
      expect(res1151.isCeilingExceeded, isTrue);
      expect(res1151.isStandardExceeded, isTrue);
      expect(res1151.status, EnvironmentEvaluationStatus.fail);

      // 114.99 dBA for very short duration (1 second = 1/3600 h) -> ceiling NOT exceeded
      final res11499 = EnvironmentalEvaluator.evaluateNoise(
        measuredDba: 114.99,
        type: NoiseMeasurementType.areaNoise,
        durationHours: 1.0 / 3600.0,
      );
      expect(res11499.isCeilingExceeded, isFalse);
    });

    test('Peak sound pressure limit: 140.0 dB vs 140.1 dB', () {
      // Exactly 140.0 dB Peak -> Permissible (not exceeded)
      final res140 = EnvironmentalEvaluator.evaluateNoise(
        measuredDba: 80.0,
        type: NoiseMeasurementType.peakSoundLevel,
        peakDb: 140.0,
      );
      expect(res140.isPeakExceeded, isFalse);
      expect(res140.isStandardExceeded, isFalse);
      expect(res140.status, EnvironmentEvaluationStatus.pass);

      // 140.1 dB Peak -> Exceeded / Critical Fail
      final res1401 = EnvironmentalEvaluator.evaluateNoise(
        measuredDba: 80.0,
        type: NoiseMeasurementType.peakSoundLevel,
        peakDb: 140.1,
      );
      expect(res1401.isPeakExceeded, isTrue);
      expect(res1401.isStandardExceeded, isTrue);
      expect(res1401.status, EnvironmentEvaluationStatus.fail);
    });

    test('Fractional exposure durations: 0.0h, 0.1h, 24.0h', () {
      // 0.0 hours -> Dose = 0%, TWA = 0 dBA, No crash
      final res0 = EnvironmentalEvaluator.evaluateNoise(
        measuredDba: 90.0,
        type: NoiseMeasurementType.areaNoise,
        durationHours: 0.0,
      );
      expect(res0.noiseDosePercent, 0.0);
      expect(res0.twa8hrDba, 0.0);

      // 0.1 hours (6 mins) at 95 dBA (permissible = 1.0 hr) -> Dose = 10%
      final res01 = EnvironmentalEvaluator.evaluateNoise(
        measuredDba: 95.0,
        type: NoiseMeasurementType.areaNoise,
        durationHours: 0.1,
      );
      expect(res01.noiseDosePercent, closeTo(10.0, 0.01));
      expect(res01.twa8hrDba, closeTo(76.03, 0.1));

      // 24.0 hours at 80 dBA (permissible = 32.0 hrs) -> Dose = 75.0%
      final res24 = EnvironmentalEvaluator.evaluateNoise(
        measuredDba: 80.0,
        type: NoiseMeasurementType.areaNoise,
        durationHours: 24.0,
      );
      expect(res24.noiseDosePercent, closeTo(75.0, 0.01));
      expect(res24.twa8hrDba, closeTo(84.75, 0.1));
      expect(res24.isStandardExceeded, isFalse);
    });

    test('Noise dose zero & extreme values safety', () {
      expect(EnvironmentalEvaluator.calculateNoiseTwa(0.0), 0.0);
      expect(EnvironmentalEvaluator.calculateNoiseTwa(-10.0), 0.0);

      final extremeTwa = EnvironmentalEvaluator.calculateNoiseTwa(10000.0);
      expect(extremeTwa.isFinite, isTrue);
      expect(extremeTwa, closeTo(105.93, 0.1));
    });

    test('Composite multi-exposure calculation', () {
      // 2 hrs at 89 dBA (Dose = 2/4 = 50%) + 1 hr at 92 dBA (Dose = 1/2 = 50%) = Total Dose 100% -> TWA 86.0 dBA
      final multi = EnvironmentalEvaluator.calculateMultiExposureTwa([
        (dba: 89.0, durationHours: 2.0),
        (dba: 92.0, durationHours: 1.0),
      ]);
      expect(multi.totalDose, closeTo(100.0, 0.1));
      expect(multi.twa8hr, closeTo(86.0, 0.1));
    });
  });

  // =========================================================================
  // 3. Lighting Edge Cases & Surrounding Ratios
  // =========================================================================
  group('3. Lighting Edge Cases & Surrounding Ratios', () {
    test('Measured Lux = 0 -> Fail, deficit = standard min Lux, no divide by zero', () {
      final res = EnvironmentalEvaluator.evaluateLighting(
        measuredLux: 0.0,
        standardMinLux: 300.0,
        surroundingLux: 50.0,
      );
      expect(res.isCompliant, isFalse);
      expect(res.status, EnvironmentEvaluationStatus.fail);
      expect(res.deficitLux, 300.0);
      expect(res.surroundingRatio, isNull); // safely null when measured is 0
      expect(res.hasSurroundingWarning, isFalse);
    });

    test('Measured Lux = standard - 0.001 -> Fail', () {
      final res = EnvironmentalEvaluator.evaluateLighting(
        measuredLux: 299.999,
        standardMinLux: 300.0,
      );
      expect(res.isCompliant, isFalse);
      expect(res.status, EnvironmentEvaluationStatus.fail);
      expect(res.deficitLux, closeTo(0.001, 0.0001));
    });

    test('Measured Lux = standard -> Pass', () {
      final res = EnvironmentalEvaluator.evaluateLighting(
        measuredLux: 300.0,
        standardMinLux: 300.0,
      );
      expect(res.isCompliant, isTrue);
      expect(res.status, EnvironmentEvaluationStatus.pass);
      expect(res.deficitLux, 0.0);
    });

    test('Surrounding ratio with zero ambient lighting (surroundingLux = 0)', () {
      final res = EnvironmentalEvaluator.evaluateLighting(
        measuredLux: 300.0,
        standardMinLux: 300.0,
        surroundingLux: 0.0,
      );
      expect(res.isCompliant, isTrue);
      expect(res.surroundingRatio, 0.0);
      expect(res.hasSurroundingWarning, isTrue); // 0.0 < 0.333
    });

    test('Surrounding ratio exactly at 1/3 (0.333) boundary', () {
      // 99.8 / 300 = 0.332667 < 0.333 -> Warning
      final resWarn = EnvironmentalEvaluator.evaluateLighting(
        measuredLux: 300.0,
        standardMinLux: 300.0,
        surroundingLux: 99.8,
      );
      expect(resWarn.hasSurroundingWarning, isTrue);

      // 100.0 / 300 = 0.333333 >= 0.333 -> Compliant (No warning)
      final resOk = EnvironmentalEvaluator.evaluateLighting(
        measuredLux: 300.0,
        standardMinLux: 300.0,
        surroundingLux: 100.0,
      );
      expect(resOk.hasSurroundingWarning, isFalse);
    });

    test('Unknown standardId falls back to standardMinLux or default 300 Lux', () {
      final resFallback = EnvironmentalEvaluator.evaluateLighting(
        measuredLux: 250.0,
        standardId: 'NON_EXISTENT_STD',
        standardMinLux: 200.0,
      );
      expect(resFallback.standardMinLux, 200.0);
      expect(resFallback.isCompliant, isTrue); // 250 >= 200
    });
  });

  // =========================================================================
  // 4. Subcontractor Credentials & Statutory Deadlines
  // =========================================================================
  group('4. Subcontractor Credentials & Statutory Deadlines', () {
    test('Invalid Thai prefixes rejected', () {
      // Individual Sec 9 with "บ." prefix -> mismatch
      final sec9Mismatch = SubcontractorVerifier.validate(
        type: SubcontractorType.section9Individual,
        licenseNumber: 'บ. 0123-45/2566',
      );
      expect(sec9Mismatch.isValid, isFalse);
      expect(sec9Mismatch.status, SubcontractorValidationStatus.invalidPrefixMismatch);

      // Juristic Sec 11 with "นบ." prefix -> mismatch
      final sec11Mismatch = SubcontractorVerifier.validate(
        type: SubcontractorType.section11Juristic,
        licenseNumber: 'นบ. 0123-45/2566',
      );
      expect(sec11Mismatch.isValid, isFalse);
      expect(sec11Mismatch.status, SubcontractorValidationStatus.invalidPrefixMismatch);

      // Random invalid prefixes
      final randomPrefix = SubcontractorVerifier.validate(
        type: SubcontractorType.section11Juristic,
        licenseNumber: 'XYZ-999',
      );
      expect(randomPrefix.isValid, isFalse);
      expect(randomPrefix.status, SubcontractorValidationStatus.invalidPrefixMismatch);
    });

    test('Valid Thai prefixes accepted ("นบ.", "นบ ", "บ.", "บ ")', () {
      final sec9Dot = SubcontractorVerifier.validate(
        type: SubcontractorType.section9Individual,
        licenseNumber: 'นบ. 0123-45/2566',
      );
      expect(sec9Dot.isValid, isTrue);

      final sec9Space = SubcontractorVerifier.validate(
        type: SubcontractorType.section9Individual,
        licenseNumber: 'นบ 0123-45/2566',
      );
      expect(sec9Space.isValid, isTrue);

      final sec11Dot = SubcontractorVerifier.validate(
        type: SubcontractorType.section11Juristic,
        licenseNumber: 'บ. 0045-12/2565',
      );
      expect(sec11Dot.isValid, isTrue);

      final sec11Space = SubcontractorVerifier.validate(
        type: SubcontractorType.section11Juristic,
        licenseNumber: 'บ 0045-12/2565',
      );
      expect(sec11Space.isValid, isTrue);
    });

    test('Empty / whitespace license number rejected', () {
      final empty = SubcontractorVerifier.validate(
        type: SubcontractorType.section9Individual,
        licenseNumber: '   ',
      );
      expect(empty.isValid, isFalse);
      expect(empty.status, SubcontractorValidationStatus.missingInformation);
    });

    test('Expired license detection', () {
      final pastDate = DateTime.now().subtract(const Duration(days: 10));
      final expired = SubcontractorVerifier.validate(
        type: SubcontractorType.section11Juristic,
        licenseNumber: 'บ. 0045-12/2565',
        expireDate: pastDate,
      );
      expect(expired.isValid, isFalse);
      expect(expired.status, SubcontractorValidationStatus.expired);
      expect(expired.daysRemaining, lessThan(0));
    });

    test('Statutory Deadlines calculation (Sec 15 OSH Act: +15 posting, +30 submission)', () {
      final measDate = DateTime(2026, 9, 1);
      final deadlines = SubcontractorVerifier.calculateStatutoryDeadlines(measDate);

      expect(deadlines.postingDeadline, DateTime(2026, 9, 16));
      expect(deadlines.submissionDeadline, DateTime(2026, 10, 1));
    });
  });

  // =========================================================================
  // 5. Exporter Stress Testing (Large Volumes & Empty Sessions)
  // =========================================================================
  group('5. Exporter Stress Testing (Large Volumes & Empty Sessions)', () {
    test('PDF Exporter handles empty session (0 points, 0 capas) without crash', () async {
      const emptySession = EnvironmentSessionModel(
        sessionId: 'ENV-EMPTY-001',
        sessionTitle: 'รอบตรวจวัดว่างเปล่า',
        sessionYearBe: 2569,
        sessionYearAd: 2026,
        measurementDate: '2026-09-01',
        locationPlant: 'โรงงานทดสอบ',
        workplaceName: 'บริษัท ทดสอบ จำกัด',
        objective: 'ทดสอบความทนทานของ PDF',
        subcontractorType: SubcontractorType.section11Juristic,
        subcontractorCompanyName: 'บริษัท ตรวจวัด จำกัด',
        subcontractorRegNumber: 'บ. 0001/2565',
        surveyorName: 'นายทดสอบ',
        certifierName: 'นายรับรอง',
      );

      final emptyKpi = EnvironmentKpiSummary.calculate(points: [], capas: []);

      final pdfBytes = await EnvironmentPdfExporter.generatePdf(
        session: emptySession,
        points: [],
        capas: [],
        kpi: emptyKpi,
      );

      expect(pdfBytes, isNotNull);
      expect(pdfBytes.length, greaterThan(1000));
    });

    test('PDF Exporter handles large dataset (120 sampling points across 3 factors)', () async {
      const stressSession = EnvironmentSessionModel(
        sessionId: 'ENV-STRESS-120',
        sessionTitle: 'การตรวจวัดความทนทาน 120 จุด',
        sessionYearBe: 2569,
        sessionYearAd: 2026,
        measurementDate: '2026-09-01',
        locationPlant: 'นิคมอุตสาหกรรมบางปู',
        workplaceName: 'บริษัท อุตสาหกรรมขนาดใหญ่ จำกัด (มหาชน)',
        objective: 'ทดสอบการสร้างเอกสาร PDF ขนาดใหญ่',
        subcontractorType: SubcontractorType.section11Juristic,
        subcontractorCompanyName: 'บริษัท ผู้เชี่ยวชาญสิ่งแวดล้อม จำกัด',
        subcontractorRegNumber: 'บ. 0999-88/2566',
        surveyorName: 'วิศวกรตรวจวัด',
        certifierName: 'ผู้รับรองรายงาน',
      );

      final List<EnvironmentPointModel> stressPoints = [];
      for (int i = 1; i <= 40; i++) {
        // 40 Light points
        stressPoints.add(EnvironmentPointModel(
          pointId: 'PT-LIGHT-$i',
          sessionId: 'ENV-STRESS-120',
          factorType: EnvironmentFactorType.light,
          department: 'ฝ่ายผลิตแผนก $i',
          locationName: 'สถานีงานหมายเลข $i',
          taskOrMachineName: 'งานประกอบแผงวงจร',
          evaluationStatus: i % 3 == 0 ? EnvironmentEvaluationStatus.fail : EnvironmentEvaluationStatus.pass,
          lightCategoryCode: 'LIGHT-CAT2-05',
          lightTaskDescription: 'งานประกอบชิ้นส่วนอิเล็กทรอนิกส์',
          lightMeasuredLux: i % 3 == 0 ? 320.0 : 450.0,
          lightStandardMinLux: 400.0,
          lightSurroundingLux: 200.0,
          lightIsCompliant: i % 3 != 0,
        ));

        // 40 Noise points
        stressPoints.add(EnvironmentPointModel(
          pointId: 'PT-NOISE-$i',
          sessionId: 'ENV-STRESS-120',
          factorType: EnvironmentFactorType.noise,
          department: 'ฝ่ายเครื่องจักรแผนก $i',
          locationName: 'เครื่องปั๊มไฮดรอลิก $i',
          taskOrMachineName: 'ปั๊มโลหะ ๕๐ ตัน',
          evaluationStatus: i % 4 == 0
              ? EnvironmentEvaluationStatus.fail
              : (i % 2 == 0 ? EnvironmentEvaluationStatus.actionLevel : EnvironmentEvaluationStatus.pass),
          noiseMeasurementType: NoiseMeasurementType.leq8hrTwa,
          noiseMeasuredDba: i % 4 == 0 ? 88.5 : (i % 2 == 0 ? 85.5 : 78.0),
          noiseStandardTwaLimit: 86.0,
          noiseActionLevelThreshold: 85.0,
          noiseIsHcpRequired: i % 2 == 0 || i % 4 == 0,
        ));

        // 40 Heat points
        stressPoints.add(EnvironmentPointModel(
          pointId: 'PT-HEAT-$i',
          sessionId: 'ENV-STRESS-120',
          factorType: EnvironmentFactorType.heat,
          department: 'ฝ่ายหลอมโลหะแผนก $i',
          locationName: 'หน้าเตาอบ $i',
          evaluationStatus: i % 5 == 0 ? EnvironmentEvaluationStatus.fail : EnvironmentEvaluationStatus.pass,
          heatSolarExposure: HeatSolarExposure.indoorNoSolar,
          heatNwbCelsius: i % 5 == 0 ? 32.0 : 26.0,
          heatGtCelsius: i % 5 == 0 ? 42.0 : 32.0,
          heatCalculatedWbgt: i % 5 == 0 ? 35.0 : 27.8,
          heatWorkloadType: WorkloadLevel.heavy,
          heatStandardLimitWbgt: 30.0,
          heatIsCompliant: i % 5 != 0,
        ));
      }

      final stressKpi = EnvironmentKpiSummary.calculate(points: stressPoints);

      final pdfBytes = await EnvironmentPdfExporter.generatePdf(
        session: stressSession,
        points: stressPoints,
        capas: [],
        kpi: stressKpi,
      );

      expect(pdfBytes, isNotNull);
      expect(pdfBytes.length, greaterThan(15000));
    });

    test('Excel Exporter handles 120 points across all 4 sheets without corruption', () {
      const stressSession = EnvironmentSessionModel(
        sessionId: 'ENV-EXCEL-120',
        sessionTitle: 'การตรวจวัด 120 จุดสำหรับ Excel',
        sessionYearBe: 2569,
        sessionYearAd: 2026,
        measurementDate: '2026-09-01',
        locationPlant: 'โรงงานหลัก',
        workplaceName: 'บริษัท ทดสอบสเปรดชีต จำกัด',
        objective: 'ทดสอบส่งออก Excel',
        subcontractorType: SubcontractorType.section11Juristic,
        subcontractorCompanyName: 'บริษัท สิ่งแวดล้อมสากล จำกัด',
        subcontractorRegNumber: 'บ. 1111-22/2566',
        surveyorName: 'นายตรวจวัด',
        certifierName: 'นายรับรอง',
      );

      final List<EnvironmentPointModel> stressPoints = [];
      for (int i = 1; i <= 120; i++) {
        stressPoints.add(EnvironmentPointModel(
          pointId: 'PT-MIX-$i',
          sessionId: 'ENV-EXCEL-120',
          factorType: i % 3 == 0
              ? EnvironmentFactorType.heat
              : (i % 2 == 0 ? EnvironmentFactorType.noise : EnvironmentFactorType.light),
          department: 'แผนก $i',
          locationName: 'จุดที่ $i',
          evaluationStatus: i % 5 == 0 ? EnvironmentEvaluationStatus.fail : EnvironmentEvaluationStatus.pass,
        ));
      }

      final kpi = EnvironmentKpiSummary.calculate(points: stressPoints);

      final excelBytes = EnvironmentExcelExporter.exportToExcelBytes(
        session: stressSession,
        points: stressPoints,
        capas: [],
        kpi: kpi,
      );

      expect(excelBytes, isNotNull);
      expect(excelBytes!.length, greaterThan(5000));

      final decoded = Excel.decodeBytes(Uint8List.fromList(excelBytes));
      expect(decoded.tables.containsKey('สรุปภาพรวม (Summary)'), isTrue);
      expect(decoded.tables.containsKey('ผลการตรวจวัด (Measurements)'), isTrue);
      expect(decoded.tables.containsKey('แผน CAPA'), isTrue);
      expect(decoded.tables.containsKey('ผู้รับจ้างตรวจวัด (Subcontractor)'), isTrue);
      expect(decoded.tables['ผลการตรวจวัด (Measurements)']!.rows.length, greaterThanOrEqualTo(123));
    });
  });

  // =========================================================================
  // 6. KPI Aggregator Stress Testing
  // =========================================================================
  group('6. KPI Aggregator Stress Testing', () {
    test('KPI calculation with 0 points produces 100% compliance without NaN', () {
      final kpi = EnvironmentKpiSummary.calculate(points: []);
      expect(kpi.totalPoints, 0);
      expect(kpi.compliancePercentage, 100.0);
      expect(kpi.lightCompliancePercentage, 100.0);
      expect(kpi.noiseCompliancePercentage, 100.0);
      expect(kpi.heatCompliancePercentage, 100.0);
      expect(kpi.compliancePercentage.isNaN, isFalse);
    });

    test('KPI calculation with 100% fail points produces 0.0% compliance', () {
      final points = [
        const EnvironmentPointModel(
          pointId: 'PT-1',
          sessionId: 'S1',
          factorType: EnvironmentFactorType.light,
          department: 'D1',
          locationName: 'L1',
          evaluationStatus: EnvironmentEvaluationStatus.fail,
        ),
        const EnvironmentPointModel(
          pointId: 'PT-2',
          sessionId: 'S1',
          factorType: EnvironmentFactorType.noise,
          department: 'D1',
          locationName: 'L1',
          evaluationStatus: EnvironmentEvaluationStatus.fail,
        ),
      ];

      final kpi = EnvironmentKpiSummary.calculate(points: points);
      expect(kpi.totalPoints, 2);
      expect(kpi.passedPoints, 0);
      expect(kpi.failedPoints, 2);
      expect(kpi.compliancePercentage, 0.0);
      expect(kpi.lightCompliancePercentage, 0.0);
      expect(kpi.noiseCompliancePercentage, 0.0);
    });
  });
}
