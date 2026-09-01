import 'package:flutter_test/flutter_test.dart';
import 'package:safety_superapp/features/environment/domain/models/environment_standard_model.dart';
import 'package:safety_superapp/features/environment/domain/models/subcontractor_model.dart';
import 'package:safety_superapp/features/environment/domain/models/environment_session_model.dart';
import 'package:safety_superapp/features/environment/domain/models/environment_point_model.dart';
import 'package:safety_superapp/features/environment/domain/models/environment_capa_model.dart';
import 'package:safety_superapp/features/environment/domain/models/environment_kpi_summary.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Environment Domain Models Serialization & Helpers Tests', () {
    // ------------------------------------------------------------------------
    // 1. EnvironmentStandardModel
    // ------------------------------------------------------------------------
    test('EnvironmentStandardModel Map/JSON serialization and copyWith', () {
      const model = EnvironmentStandardModel(
        id: 1,
        standardId: 'LIGHT-CAT2-05',
        factorType: EnvironmentFactorType.light,
        categoryCode: 'LIGHT_CAT2',
        categoryNameTh: 'งานละเอียด',
        categoryNameEn: 'Fine Tasks',
        taskDescription: 'ประกอบแผงวงจร',
        minLux: 400.0,
        maxLux: 600.0,
        surroundingLuxRatio: 0.333,
        referenceLawTitle: 'ประกาศกรมฯ ๒๕๖๑',
        referenceArticle: 'ข้อ ๒ (๕)',
        notes: 'ทดสอบ',
        sortOrder: 5,
      );

      final map = model.toMap();
      final fromMap = EnvironmentStandardModel.fromMap(map);

      expect(fromMap.id, 1);
      expect(fromMap.standardId, 'LIGHT-CAT2-05');
      expect(fromMap.factorType, EnvironmentFactorType.light);
      expect(fromMap.minLux, 400.0);
      expect(fromMap.surroundingLuxRatio, 0.333);

      final jsonStr = model.toJson();
      final fromJson = EnvironmentStandardModel.fromJson(jsonStr);
      expect(fromJson.standardId, model.standardId);

      final modified = model.copyWith(minLux: 450.0);
      expect(modified.minLux, 450.0);
      expect(modified.standardId, model.standardId);
    });

    // ------------------------------------------------------------------------
    // 2. SubcontractorModel
    // ------------------------------------------------------------------------
    test('SubcontractorModel Map/JSON serialization and helpers', () {
      final subcon = SubcontractorModel(
        id: 2,
        subcontractorId: 'SUBCON-001',
        subcontractorType: SubcontractorType.section11Juristic,
        companyName: 'ไทยเซฟตี้ คอนซัลแตนท์ จำกัด',
        registrationNumber: 'บ. 0045-12/2565',
        contactPerson: 'นาย สมศักดิ์',
        contactPhone: '0812345678',
        licenseExpireDate: '2028-12-31',
        surveyorName: 'นาย วิชาชีพ',
        surveyorLicenseNo: 'จป.ว 1234',
        certifierName: 'ดร. สิ่งแวดล้อม',
        certifierRegNo: 'วศ.บ 5678',
        calibrationCertPaths: const ['/certs/cal1.pdf', '/certs/cal2.pdf'],
        isVerified: true,
      );

      expect(subcon.hasValidRegistrationPrefix, isTrue);
      expect(subcon.isExpired, isFalse);
      expect(subcon.daysUntilExpiration! > 0, isTrue);

      final map = subcon.toMap();
      final fromMap = SubcontractorModel.fromMap(map);

      expect(fromMap.id, 2);
      expect(fromMap.subcontractorId, 'SUBCON-001');
      expect(fromMap.subcontractorType, SubcontractorType.section11Juristic);
      expect(fromMap.registrationNumber, 'บ. 0045-12/2565');
      expect(fromMap.calibrationCertPaths.length, 2);
      expect(fromMap.calibrationCertPaths[0], '/certs/cal1.pdf');

      final jsonStr = subcon.toJson();
      final fromJson = SubcontractorModel.fromJson(jsonStr);
      expect(fromJson.companyName, subcon.companyName);
    });

    // ------------------------------------------------------------------------
    // 3. EnvironmentSessionModel
    // ------------------------------------------------------------------------
    test('EnvironmentSessionModel Map/JSON serialization and statutory deadlines', () {
      final session = EnvironmentSessionModel(
        id: 5,
        sessionId: 'ENV-SESS-2026-001',
        sessionTitle: 'การตรวจวัดสภาพแวดล้อมประจำปี 2569',
        sessionYearBe: 2569,
        sessionYearAd: 2026,
        measurementDate: '2026-09-01',
        locationPlant: 'โรงงานบางปู',
        workplaceName: 'บริษัท สยามแมนูแฟคเจอริ่ง จำกัด',
        objective: 'ตรวจวัดประจำปีตามกฎหมาย',
        subcontractorType: SubcontractorType.section11Juristic,
        subcontractorCompanyName: 'บริษัท ตรวจวัด จำกัด',
        subcontractorRegNumber: 'บ. 0100-01/2566',
        surveyorName: 'นาย ตรวจวัด',
        certifierName: 'นาย รับรอง',
        calibrationCertPaths: const ['/certs/sound.pdf', '/certs/lux.pdf'],
        sitePhotoPaths: const ['/photos/point1.jpg', '/photos/point2.jpg'],
        status: EnvironmentSessionStatus.measured,
      );

      expect(session.effectivePostingDeadline, '2026-09-16');
      expect(session.effectiveSubmissionDeadline, '2026-10-01');

      final map = session.toMap();
      final fromMap = EnvironmentSessionModel.fromMap(map);

      expect(fromMap.id, 5);
      expect(fromMap.sessionId, 'ENV-SESS-2026-001');
      expect(fromMap.sessionYearBe, 2569);
      expect(fromMap.status, EnvironmentSessionStatus.measured);
      expect(fromMap.calibrationCertPaths.length, 2);
      expect(fromMap.sitePhotoPaths.length, 2);

      final jsonStr = session.toJson();
      final fromJson = EnvironmentSessionModel.fromJson(jsonStr);
      expect(fromJson.sessionTitle, session.sessionTitle);
    });

    // ------------------------------------------------------------------------
    // 4. EnvironmentPointModel
    // ------------------------------------------------------------------------
    test('EnvironmentPointModel Map/JSON serialization and getters for all factors', () {
      // Light Point
      final lightPoint = EnvironmentPointModel(
        id: 10,
        pointId: 'PT-LIGHT-01',
        sessionId: 'ENV-SESS-2026-001',
        factorType: EnvironmentFactorType.light,
        department: 'QC',
        locationName: 'Table 1',
        evaluationStatus: EnvironmentEvaluationStatus.pass,
        lightCategoryCode: 'LIGHT_CAT2',
        lightTaskDescription: 'ตรวจสอบชิ้นงาน',
        lightMeasuredLux: 650.0,
        lightStandardMinLux: 600.0,
        lightIsCompliant: true,
      );

      expect(lightPoint.isPass, isTrue);
      expect(lightPoint.isFail, isFalse);
      expect(lightPoint.requiresCapa, isFalse);
      expect(lightPoint.summaryValueDisplay, contains('650.0 Lux'));

      final lightMap = lightPoint.toMap();
      final lightFromMap = EnvironmentPointModel.fromMap(lightMap);
      expect(lightFromMap.lightMeasuredLux, 650.0);
      expect(lightFromMap.lightIsCompliant, isTrue);

      // Noise Point with HCP requirement
      final noisePoint = EnvironmentPointModel(
        id: 11,
        pointId: 'PT-NOISE-01',
        sessionId: 'ENV-SESS-2026-001',
        factorType: EnvironmentFactorType.noise,
        department: 'Press',
        locationName: 'Press Line 3',
        evaluationStatus: EnvironmentEvaluationStatus.actionLevel,
        noiseMeasurementType: NoiseMeasurementType.leq8hrTwa,
        noiseMeasuredDba: 85.5,
        noiseExposureDurationHours: 8.0,
        noiseDosePercent: 88.5,
        noiseIsHcpRequired: true,
      );

      expect(noisePoint.isActionLevel, isTrue);
      expect(noisePoint.requiresHearingConservation, isTrue);
      expect(noisePoint.requiresCapa, isTrue);

      final noiseMap = noisePoint.toMap();
      final noiseFromMap = EnvironmentPointModel.fromMap(noiseMap);
      expect(noiseFromMap.noiseMeasuredDba, 85.5);
      expect(noiseFromMap.noiseIsHcpRequired, isTrue);

      // Heat Point
      final heatPoint = EnvironmentPointModel(
        id: 12,
        pointId: 'PT-HEAT-01',
        sessionId: 'ENV-SESS-2026-001',
        factorType: EnvironmentFactorType.heat,
        department: 'Boiler',
        locationName: 'Burner Area',
        evaluationStatus: EnvironmentEvaluationStatus.fail,
        heatSolarExposure: HeatSolarExposure.indoorNoSolar,
        heatNwbCelsius: 29.5,
        heatGtCelsius: 44.0,
        heatCalculatedWbgt: 33.85,
        heatWorkloadType: WorkloadLevel.moderate,
        heatStandardLimitWbgt: 32.0,
        heatIsCompliant: false,
      );

      expect(heatPoint.isFail, isTrue);
      expect(heatPoint.requiresCapa, isTrue);
      expect(heatPoint.summaryValueDisplay, contains('WBGT 33.85 °C'));

      final heatMap = heatPoint.toMap();
      final heatFromMap = EnvironmentPointModel.fromMap(heatMap);
      expect(heatFromMap.heatCalculatedWbgt, 33.85);
      expect(heatFromMap.heatWorkloadType, WorkloadLevel.moderate);
    });

    // ------------------------------------------------------------------------
    // 5. EnvironmentCapaModel
    // ------------------------------------------------------------------------
    test('EnvironmentCapaModel Map/JSON serialization, overdue calculation and status', () {
      final pastDate = '2020-01-01';
      final futureDate = '2030-01-01';

      final overdueCapa = EnvironmentCapaModel(
        id: 1,
        capaId: 'CAPA-001',
        pointId: 'PT-NOISE-01',
        sessionId: 'ENV-SESS-2026-001',
        factorType: EnvironmentFactorType.noise,
        actionTitle: 'จัดทำโครงการอนุรักษ์การได้ยินและแจก Earplugs',
        hazardDescription: 'เสียง 85.5 dBA',
        rootCause: 'เครื่องจักรเสียงดัง',
        engineeringControl: 'ติดตั้งฉนวนซับเสียง',
        administrativeControl: 'สลับกะการทำงาน',
        ppeControl: 'แจกปลั๊กอุดหู NRR 25 dB',
        picName: 'จป.วิชาชีพ',
        targetDate: pastDate,
        status: 'IN_PROGRESS',
        hearingProgramEnrolled: true,
      );

      expect(overdueCapa.isOverdue, isTrue);
      expect(overdueCapa.effectiveStatusEnum, EnvironmentCapaStatus.overdue);
      expect(overdueCapa.daysRemaining < 0, isTrue);
      expect(overdueCapa.statusLabelTh, contains('เกินกำหนด'));

      final completedCapa = overdueCapa.copyWith(
        status: 'COMPLETED',
        completedDate: '2026-09-01',
      );
      expect(completedCapa.isCompleted, isTrue);
      expect(completedCapa.isOverdue, isFalse);
      expect(completedCapa.effectiveStatusEnum, EnvironmentCapaStatus.completed);

      final futureCapa = overdueCapa.copyWith(
        targetDate: futureDate,
        status: 'PENDING',
      );
      expect(futureCapa.isOverdue, isFalse);
      expect(futureCapa.effectiveStatusEnum, EnvironmentCapaStatus.pending);

      final map = overdueCapa.toMap();
      final fromMap = EnvironmentCapaModel.fromMap(map);
      expect(fromMap.capaId, 'CAPA-001');
      expect(fromMap.factorType, EnvironmentFactorType.noise);
      expect(fromMap.hearingProgramEnrolled, isTrue);
    });

    // ------------------------------------------------------------------------
    // 6. EnvironmentKpiSummary
    // ------------------------------------------------------------------------
    test('EnvironmentKpiSummary Map/JSON serialization round-trip', () {
      final summary = EnvironmentKpiSummary.calculate(
        points: [
          EnvironmentPointModel(
            pointId: 'PT-1',
            sessionId: 'S1',
            factorType: EnvironmentFactorType.light,
            department: 'D1',
            locationName: 'L1',
            evaluationStatus: EnvironmentEvaluationStatus.pass,
          ),
          EnvironmentPointModel(
            pointId: 'PT-2',
            sessionId: 'S1',
            factorType: EnvironmentFactorType.noise,
            department: 'D2',
            locationName: 'L2',
            evaluationStatus: EnvironmentEvaluationStatus.actionLevel,
          ),
        ],
      );

      final map = summary.toMap();
      final fromMap = EnvironmentKpiSummary.fromMap(map);

      expect(fromMap.totalPoints, 2);
      expect(fromMap.passedPoints, 1);
      expect(fromMap.actionLevelPoints, 1);
      expect(fromMap.compliancePercentage, 50.0);

      final jsonStr = summary.toJson();
      final fromJson = EnvironmentKpiSummary.fromJson(jsonStr);
      expect(fromJson.totalPoints, summary.totalPoints);
    });
  });
}
