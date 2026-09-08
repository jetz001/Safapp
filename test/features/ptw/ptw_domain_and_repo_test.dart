import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:safety_superapp/features/ptw/domain/enums/high_risk_type.dart';
import 'package:safety_superapp/features/ptw/domain/enums/ptw_status.dart';
import 'package:safety_superapp/features/ptw/domain/enums/energy_type.dart';
import 'package:safety_superapp/features/ptw/domain/enums/confined_role_type.dart';
import 'package:safety_superapp/features/ptw/data/models/ptw_model.dart';
import 'package:safety_superapp/features/ptw/data/models/gas_test_log_model.dart';
import 'package:safety_superapp/features/ptw/data/models/confined_role_model.dart';
import 'package:safety_superapp/features/ptw/data/models/fire_watch_model.dart';
import 'package:safety_superapp/features/ptw/data/models/loto_isolation_model.dart';
import 'package:safety_superapp/features/ptw/data/models/ptw_checklist_model.dart';
import 'package:safety_superapp/features/ptw/data/models/ptw_approval_model.dart';
import 'package:safety_superapp/features/ptw/data/models/ptw_kpi_summary_model.dart';
import 'package:safety_superapp/features/ptw/data/datasources/ptw_statutory_master_data.dart';
import 'package:safety_superapp/features/ptw/domain/services/ptw_safety_evaluator.dart';
import 'package:safety_superapp/features/ptw/data/repositories/ptw_repository.dart';
import 'package:safety_superapp/core/database/database_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;


  group('PTW Domain Enums Tests', () {
    test('HighRiskType enum serialization and Thai labels', () {
      expect(HighRiskType.hotWork.toDbCode(), 'HOT_WORK');
      expect(HighRiskType.confinedSpace.toDbCode(), 'CONFINED_SPACE');
      expect(HighRiskType.workingAtHeight.toDbCode(), 'WORKING_AT_HEIGHT');
      expect(HighRiskType.electricalLoto.toDbCode(), 'ELECTRICAL_LOTO');
      expect(HighRiskType.excavationLifting.toDbCode(), 'EXCAVATION_LIFTING');

      expect(HighRiskType.fromDbCode('HOT_WORK'), HighRiskType.hotWork);
      expect(HighRiskType.fromDbCode('CONFINED_SPACE'), HighRiskType.confinedSpace);
      expect(HighRiskType.fromDbCode('WORKING_AT_HEIGHT'), HighRiskType.workingAtHeight);
      expect(HighRiskType.fromDbCode('ELECTRICAL_LOTO'), HighRiskType.electricalLoto);
      expect(HighRiskType.fromDbCode('EXCAVATION_LIFTING'), HighRiskType.excavationLifting);
      expect(HighRiskType.fromDbCode('UNKNOWN'), HighRiskType.hotWork);

      expect(HighRiskType.hotWork.labelTh.contains('Hot Work'), isTrue);
      expect(HighRiskType.confinedSpace.labelTh.contains('Confined Space'), isTrue);
      expect(HighRiskType.workingAtHeight.labelTh.contains('Working at Height'), isTrue);
      expect(HighRiskType.electricalLoto.labelTh.contains('Electrical & LOTO'), isTrue);
      expect(HighRiskType.excavationLifting.labelTh.contains('Excavation & Lifting'), isTrue);

      expect(HighRiskType.hotWork.icon, isNotNull);
      expect(HighRiskType.hotWork.color, isNotNull);
      expect(HighRiskType.hotWork.legalRefTh.contains('๒๕๕๕'), isTrue);
    });

    test('PtwStatus enum serialization and badge colors', () {
      expect(PtwStatus.draft.toDbCode(), 'DRAFT');
      expect(PtwStatus.pendingApproval.toDbCode(), 'PENDING_APPROVAL');
      expect(PtwStatus.active.toDbCode(), 'ACTIVE');
      expect(PtwStatus.extendedHandover.toDbCode(), 'EXTENDED_HANDOVER');
      expect(PtwStatus.closedCancelled.toDbCode(), 'CLOSED_CANCELLED');

      expect(PtwStatus.fromDbCode('DRAFT'), PtwStatus.draft);
      expect(PtwStatus.fromDbCode('PENDING_APPROVAL'), PtwStatus.pendingApproval);
      expect(PtwStatus.fromDbCode('ACTIVE'), PtwStatus.active);
      expect(PtwStatus.fromDbCode('EXTENDED_HANDOVER'), PtwStatus.extendedHandover);
      expect(PtwStatus.fromDbCode('CLOSED_CANCELLED'), PtwStatus.closedCancelled);

      expect(PtwStatus.draft.badgeColor, isNotNull);
      expect(PtwStatus.active.badgeColor, isNotNull);
      expect(PtwStatus.draft.labelTh.contains('Draft'), isTrue);
      expect(PtwStatus.active.labelTh.contains('Active'), isTrue);
    });

    test('EnergyType enum serialization', () {
      expect(EnergyType.electrical.toDbCode(), 'ELECTRICAL');
      expect(EnergyType.pneumatic.toDbCode(), 'PNEUMATIC');
      expect(EnergyType.hydraulic.toDbCode(), 'HYDRAULIC');
      expect(EnergyType.chemical.toDbCode(), 'CHEMICAL');
      expect(EnergyType.mechanical.toDbCode(), 'MECHANICAL');
      expect(EnergyType.thermal.toDbCode(), 'THERMAL');
      expect(EnergyType.other.toDbCode(), 'OTHER');

      expect(EnergyType.fromDbCode('ELECTRICAL'), EnergyType.electrical);
      expect(EnergyType.fromDbCode('PNEUMATIC'), EnergyType.pneumatic);
      expect(EnergyType.fromDbCode('CHEMICAL'), EnergyType.chemical);
      expect(EnergyType.fromDbCode('UNKNOWN'), EnergyType.electrical);
    });

    test('ConfinedRoleType enum serialization and Thai sections', () {
      expect(ConfinedRoleType.authorizer.toDbCode(), 'AUTHORIZER');
      expect(ConfinedRoleType.supervisor.toDbCode(), 'SUPERVISOR');
      expect(ConfinedRoleType.attendant.toDbCode(), 'ATTENDANT');
      expect(ConfinedRoleType.entrant.toDbCode(), 'ENTRANT');

      expect(ConfinedRoleType.fromDbCode('AUTHORIZER'), ConfinedRoleType.authorizer);
      expect(ConfinedRoleType.fromDbCode('SUPERVISOR'), ConfinedRoleType.supervisor);
      expect(ConfinedRoleType.fromDbCode('ATTENDANT'), ConfinedRoleType.attendant);
      expect(ConfinedRoleType.fromDbCode('ENTRANT'), ConfinedRoleType.entrant);

      expect(ConfinedRoleType.authorizer.legalSectionTh.contains('ข้อ ๙'), isTrue);
      expect(ConfinedRoleType.supervisor.legalSectionTh.contains('ข้อ ๑๐'), isTrue);
      expect(ConfinedRoleType.attendant.legalSectionTh.contains('ข้อ ๑๑'), isTrue);
      expect(ConfinedRoleType.entrant.legalSectionTh.contains('ข้อ ๑๒'), isTrue);
    });

    test('PtwStatutoryMasterData provides valid checklists for all 5 risk types', () {
      for (final type in HighRiskType.values) {
        final checklist = PtwStatutoryMasterData.getStandardChecklistForRiskType(type, ptwNumber: 'PTW-TEST-001');
        expect(checklist, isNotEmpty);
        expect(checklist.every((c) => c.ptwNumber == 'PTW-TEST-001'), isTrue);
        expect(checklist.every((c) => c.riskType == type), isTrue);
        expect(checklist.every((c) => c.questionTh.isNotEmpty), isTrue);
        expect(checklist.every((c) => c.isMandatory), isTrue);
      }
    });
  });

  group('PTW Models & Serialization Tests', () {
    test('GasTestLogModel evaluation, hazard warnings and serialization', () {
      final safeLog = GasTestLogModel(
        logId: 'GAS-001',
        ptwNumber: 'PTW-2026-001',
        testStage: 'PRE_ENTRY',
        testTimestamp: '2026-09-01T08:00:00',
        locationPoint: 'Silo Tank Bottom',
        oxygenPercent: 20.9,
        combustiblePercentLel: 0.0,
        carbonMonoxidePpm: 0.0,
        hydrogenSulfidePpm: 0.0,
        testerName: 'Somchai Safe',
        detectorModel: 'Dräger X-am 5000',
        detectorSerialNo: 'DR-9921',
        lastCalibrationDate: '2026-08-01',
        isSafe: true,
      );

      expect(safeLog.isPreEntry, isTrue);
      expect(safeLog.isContinuous, isFalse);
      expect(safeLog.hazardWarnings, isEmpty);

      final map = safeLog.toMap();
      final fromMap = GasTestLogModel.fromMap(map);
      expect(fromMap.logId, 'GAS-001');
      expect(fromMap.oxygenPercent, 20.9);
      expect(fromMap.isSafe, isTrue);

      final unsafeLog = safeLog.copyWith(
        oxygenPercent: 18.0,
        combustiblePercentLel: 15.0,
        carbonMonoxidePpm: 30.0,
        hydrogenSulfidePpm: 12.0,
        isSafe: false,
      );
      expect(unsafeLog.hazardWarnings.length, 4);
      expect(unsafeLog.hazardWarnings[0].contains('ออกซิเจนต่ำเกินไป'), isTrue);
      expect(unsafeLog.hazardWarnings[1].contains('ก๊าซ/ไอระเหยไวไฟเกินเกณฑ์'), isTrue);
      expect(unsafeLog.hazardWarnings[2].contains('คาร์บอนมอนอกไซด์เกินเกณฑ์'), isTrue);
      expect(unsafeLog.hazardWarnings[3].contains('ไฮโดรเจนซัลไฟด์เกินเกณฑ์'), isTrue);
    });

    test('ConfinedRoleModel certificate validation and serialization', () {
      final validRole = ConfinedRoleModel(
        roleAssignmentId: 'CFR-001',
        ptwNumber: 'PTW-2026-001',
        roleType: ConfinedRoleType.authorizer,
        personName: 'Dr. Prapat Authorizer',
        companyName: 'Safety Corp',
        certNumber: 'AUTH-2026-88',
        certInstitute: 'DLPW Certified Institute',
        certIssueDate: '2026-01-01',
        certExpiryDate: '2028-01-01',
        contactPhone: '0812345678',
        isTrainedAndCertified: true,
      );

      expect(validRole.isCertificateValid, isTrue);

      final expiredRole = validRole.copyWith(
        certExpiryDate: '2020-01-01',
      );
      expect(expiredRole.isCertificateValid, isFalse);

      final uncertifiedRole = validRole.copyWith(
        isTrainedAndCertified: false,
      );
      expect(uncertifiedRole.isCertificateValid, isFalse);

      final json = validRole.toJson();
      final fromJson = ConfinedRoleModel.fromJson(json);
      expect(fromJson.roleAssignmentId, 'CFR-001');
      expect(fromJson.roleType, ConfinedRoleType.authorizer);
      expect(fromJson.personName, 'Dr. Prapat Authorizer');
    });

    test('FireWatchModel 30-min compliance and serialization', () {
      final compliantFw = FireWatchModel(
        watchId: 'FW-001',
        ptwNumber: 'PTW-2026-001',
        fireWatcherName: 'Wichai Watcher',
        fireWatcherPhone: '0891112233',
        fireExtinguisherType: 'Dry Chemical 15 lbs',
        fireExtinguisherSerial: 'EXT-01',
        extinguisherInspectedReady: true,
        clearedRadiusMeters: 11.0,
        hotWorkEndTime: '2026-09-01T16:00:00',
        postWorkWatchStartTime: '2026-09-01T16:00:00',
        postWorkWatchEndTime: '2026-09-01T16:35:00',
        postWorkWatchDurationMinutes: 35,
        isPostWorkAreaSafe: true,
      );

      expect(compliantFw.isCompliantWith30MinRule, isTrue);

      final nonCompliantFw = compliantFw.copyWith(
        postWorkWatchDurationMinutes: 20,
      );
      expect(nonCompliantFw.isCompliantWith30MinRule, isFalse);

      final map = compliantFw.toMap();
      final fromMap = FireWatchModel.fromMap(map);
      expect(fromMap.watchId, 'FW-001');
      expect(fromMap.postWorkWatchDurationMinutes, 35);
      expect(fromMap.isCompliantWith30MinRule, isTrue);
    });

    test('LotoIsolationModel zero energy verification and serialization', () {
      final loto = LotoIsolationModel(
        isolationId: 'LOTO-001',
        ptwNumber: 'PTW-2026-001',
        equipmentTagNo: 'MCC-PNL-04',
        equipmentName: 'Main Chemical Pump Breaker',
        locationArea: 'Control Room 1',
        energyType: EnergyType.electrical,
        isolationMethod: 'BREAKER_LOCK',
        padlockTagNo: 'PAD-401',
        lockAppliedBy: 'Somsak Electrician',
        lockAppliedTimestamp: '2026-09-01T08:00:00',
        zeroEnergyTestMethod: 'Digital Multimeter 0V',
        isZeroEnergyVerified: true,
        verifiedBy: 'Somsak Electrician',
        isDeIsolated: false,
      );

      expect(loto.isZeroEnergyVerified, isTrue);
      expect(loto.isDeIsolated, isFalse);

      final map = loto.toMap();
      final fromMap = LotoIsolationModel.fromMap(map);
      expect(fromMap.isolationId, 'LOTO-001');
      expect(fromMap.equipmentTagNo, 'MCC-PNL-04');
      expect(fromMap.energyType, EnergyType.electrical);
    });

    test('PtwChecklistModel and PtwApprovalModel serialization', () {
      final chk = PtwChecklistModel(
        itemId: 'CHK-HOT-01',
        riskType: HighRiskType.hotWork,
        checkCategory: 'EQUIPMENT',
        questionTh: 'ถังดับเพลิงอยู่ในสภาพพร้อมใช้',
        questionEn: 'Fire extinguisher is ready',
        isMandatory: true,
        result: 'YES',
      );
      expect(chk.isCompliant, isTrue);

      final chkNonCompliant = chk.copyWith(result: 'NO');
      expect(chkNonCompliant.isCompliant, isFalse);

      final app = PtwApprovalModel(
        approvalId: 'APR-001',
        ptwNumber: 'PTW-2026-001',
        approvalStage: 'ACTIVE',
        approverRole: 'SAFETY_OFFICER',
        approverName: 'Jane Safety',
        action: 'APPROVE',
        timestamp: '2026-09-01T08:30:00',
        comments: 'Approved after site inspection',
      );
      expect(app.approvalId, 'APR-001');
      expect(app.toMap()['approver_role'], 'SAFETY_OFFICER');
    });

    test('PtwKpiSummaryModel calculations and serialization', () {
      final kpi = PtwKpiSummaryModel(
        totalPermits: 10,
        activeCount: 4,
        pendingCount: 2,
        draftCount: 1,
        extendedCount: 1,
        closedCount: 2,
        overdueCount: 1,
        hotWorkCount: 3,
        confinedSpaceCount: 2,
        workingAtHeightCount: 2,
        electricalLotoCount: 2,
        excavationLiftingCount: 1,
        gasTestAnomalyCount: 0,
        lotoPendingDeIsolationCount: 1,
        complianceRatePercent: 90.0,
      );

      final json = kpi.toJson();
      final fromJson = PtwKpiSummaryModel.fromJson(json);
      expect(fromJson.totalPermits, 10);
      expect(fromJson.activeCount, 4);
      expect(fromJson.complianceRatePercent, 90.0);
    });

    test('Master PtwModel full serialization and calculated business getters', () {
      final permit = PtwModel(
        ptwNumber: 'PTW-20260901-001',
        workTitle: 'เชื่อมตัดท่อสารเคมีในถังไซโล',
        workDescription: 'งาน Hot Work และ Confined Space',
        primaryRiskType: HighRiskType.confinedSpace,
        secondaryRiskTypes: const [HighRiskType.hotWork, HighRiskType.electricalLoto],
        status: PtwStatus.active,
        plantArea: 'Plant 1 - Chemical Area',
        specificLocation: 'Silo Tank #3',
        requestDate: '2026-09-01',
        workStartDate: '2026-09-01',
        workStartTime: '08:00',
        workEndDate: '2026-09-01',
        workEndTime: '17:00',
        extensionHours: 2,
        extensionReason: 'งานเชื่อมมีความซับซ้อน',
        applicantType: 'INTERNAL_EMPLOYEE',
        applicantName: 'Somchai Requestor',
        applicantDepartment: 'Maintenance',
        applicantPhone: '0812345678',
        workerCount: 4,
        workerNames: const ['Somchai', 'Somsak', 'Wichai', 'Prapat'],
        jsaReferenceNo: 'JSA-2026-SILO-01',
        emergencyRescuePlan: 'เบอร์ติดต่อกู้ภัยภายใน 1999',
        requiredPpeList: 'Full Body Harness, SCBA, Fire Suit, Safety Shoes',
        specialPrecautions: 'ติดตั้งเครื่องเป่าระบายอากาศแบบ Explosion-proof',
        applicantSignaturePath: '/signatures/somchai.png',
        applicantSignedAt: '2026-09-01T07:30:00',
        safetyOfficerSignaturePath: '/signatures/safety.png',
        safetyOfficerName: 'Jane Safety',
        safetyOfficerSignedAt: '2026-09-01T07:45:00',
        authorizerSignaturePath: '/signatures/authorizer.png',
        authorizerName: 'Dr. Prapat',
        authorizerSignedAt: '2026-09-01T07:55:00',
        gasTestLogs: [
          GasTestLogModel(
            logId: 'GAS-001',
            ptwNumber: 'PTW-20260901-001',
            testStage: 'PRE_ENTRY',
            testTimestamp: '2026-09-01T07:40:00',
            locationPoint: 'Silo 3',
            oxygenPercent: 20.9,
            combustiblePercentLel: 0.0,
            carbonMonoxidePpm: 0.0,
            hydrogenSulfidePpm: 0.0,
            testerName: 'Jane Safety',
            detectorModel: 'Dräger X-am 5000',
            detectorSerialNo: 'DR-9921',
            lastCalibrationDate: '2026-08-01',
            isSafe: true,
          ),
        ],
        confinedRoles: [
          ConfinedRoleModel(
            roleAssignmentId: 'CFR-001',
            ptwNumber: 'PTW-20260901-001',
            roleType: ConfinedRoleType.authorizer,
            personName: 'Dr. Prapat',
            companyName: 'Safety Corp',
            certNumber: 'AUTH-01',
            certInstitute: 'DLPW',
            certIssueDate: '2026-01-01',
            certExpiryDate: '2028-01-01',
            contactPhone: '081',
          ),
          ConfinedRoleModel(
            roleAssignmentId: 'CFR-002',
            ptwNumber: 'PTW-20260901-001',
            roleType: ConfinedRoleType.supervisor,
            personName: 'Somchai',
            companyName: 'Safety Corp',
            certNumber: 'SUP-01',
            certInstitute: 'DLPW',
            certIssueDate: '2026-01-01',
            certExpiryDate: '2028-01-01',
            contactPhone: '082',
          ),
          ConfinedRoleModel(
            roleAssignmentId: 'CFR-003',
            ptwNumber: 'PTW-20260901-001',
            roleType: ConfinedRoleType.attendant,
            personName: 'Wichai',
            companyName: 'Safety Corp',
            certNumber: 'ATT-01',
            certInstitute: 'DLPW',
            certIssueDate: '2026-01-01',
            certExpiryDate: '2028-01-01',
            contactPhone: '083',
          ),
          ConfinedRoleModel(
            roleAssignmentId: 'CFR-004',
            ptwNumber: 'PTW-20260901-001',
            roleType: ConfinedRoleType.entrant,
            personName: 'Somsak',
            companyName: 'Safety Corp',
            certNumber: 'ENT-01',
            certInstitute: 'DLPW',
            certIssueDate: '2026-01-01',
            certExpiryDate: '2028-01-01',
            contactPhone: '084',
          ),
        ],
        lotoIsolations: [
          LotoIsolationModel(
            isolationId: 'LOTO-001',
            ptwNumber: 'PTW-20260901-001',
            equipmentTagNo: 'VALVE-01',
            equipmentName: 'Chemical Feed Valve',
            locationArea: 'Silo Top',
            energyType: EnergyType.chemical,
            isolationMethod: 'BLIND_FLANGE',
            padlockTagNo: 'PAD-01',
            lockAppliedBy: 'Somsak',
            lockAppliedTimestamp: '2026-09-01T07:20:00',
            zeroEnergyTestMethod: 'Drain valve check 0 bar',
            isZeroEnergyVerified: true,
            verifiedBy: 'Jane Safety',
          ),
        ],
        checklistItems: [
          PtwChecklistModel(
            itemId: 'CHK-01',
            riskType: HighRiskType.confinedSpace,
            checkCategory: 'VENTILATION',
            questionTh: 'ทำการเป่าระบายอากาศอย่างน้อย 15 นาที',
            questionEn: 'Ventilation blower operated for at least 15 min',
            isMandatory: true,
            result: 'YES',
          ),
        ],
      );

      expect(permit.isConfinedSpaceWork, isTrue);
      expect(permit.isHotWork, isTrue);
      expect(permit.isElectricalLotoWork, isTrue);
      expect(permit.isConfinedSpaceCompliant, isTrue);
      expect(permit.isPreEntryGasTestSafe, isTrue);
      expect(permit.isLotoVerified, isTrue);
      expect(permit.isChecklistComplete, isTrue);
      expect(permit.formattedTimeWindowTh.contains('08:00 น.'), isTrue);

      final json = permit.toJson();
      final fromJson = PtwModel.fromJson(json);
      expect(fromJson.ptwNumber, 'PTW-20260901-001');
      expect(fromJson.gasTestLogs.length, 1);
      expect(fromJson.confinedRoles.length, 4);
      expect(fromJson.lotoIsolations.length, 1);
      expect(fromJson.checklistItems.length, 1);
      expect(fromJson.secondaryRiskTypes.length, 2);
    });
  });

  group('PtwSafetyEvaluator Statutory Engine Tests', () {
    test('Atmosphere safety evaluations (O2, LEL, CO, H2S)', () {
      // 1. Safe condition
      final resSafe = PtwSafetyEvaluator.evaluateAtmosphere(
        oxygenPercent: 20.9,
        combustiblePercentLel: 0.0,
        carbonMonoxidePpm: 5.0,
        hydrogenSulfidePpm: 1.0,
      );
      expect(resSafe.isValid, isTrue);
      expect(resSafe.errors, isEmpty);

      // 2. Oxygen low violation (< 19.5%)
      final resLowO2 = PtwSafetyEvaluator.evaluateAtmosphere(
        oxygenPercent: 19.0,
        combustiblePercentLel: 0.0,
        carbonMonoxidePpm: 0.0,
        hydrogenSulfidePpm: 0.0,
      );
      expect(resLowO2.isValid, isFalse);
      expect(resLowO2.errors.first.contains('ออกซิเจนต่ำกว่าเกณฑ์'), isTrue);

      // 3. Oxygen high violation (> 23.5%)
      final resHighO2 = PtwSafetyEvaluator.evaluateAtmosphere(
        oxygenPercent: 24.0,
        combustiblePercentLel: 0.0,
        carbonMonoxidePpm: 0.0,
        hydrogenSulfidePpm: 0.0,
      );
      expect(resHighO2.isValid, isFalse);
      expect(resHighO2.errors.first.contains('ออกซิเจนสูงกว่าเกณฑ์'), isTrue);

      // 4. LEL violation (>= 10%)
      final resHighLel = PtwSafetyEvaluator.evaluateAtmosphere(
        oxygenPercent: 20.9,
        combustiblePercentLel: 10.0,
        carbonMonoxidePpm: 0.0,
        hydrogenSulfidePpm: 0.0,
      );
      expect(resHighLel.isValid, isFalse);
      expect(resHighLel.errors.first.contains('ก๊าซหรือไอระเหยไวไฟเกินเกณฑ์'), isTrue);

      // 5. CO violation (>= 25 ppm)
      final resHighCo = PtwSafetyEvaluator.evaluateAtmosphere(
        oxygenPercent: 20.9,
        combustiblePercentLel: 0.0,
        carbonMonoxidePpm: 25.0,
        hydrogenSulfidePpm: 0.0,
      );
      expect(resHighCo.isValid, isFalse);
      expect(resHighCo.errors.first.contains('คาร์บอนมอนอกไซด์เกินเกณฑ์'), isTrue);

      // 6. H2S violation (>= 10 ppm)
      final resHighH2s = PtwSafetyEvaluator.evaluateAtmosphere(
        oxygenPercent: 20.9,
        combustiblePercentLel: 0.0,
        carbonMonoxidePpm: 0.0,
        hydrogenSulfidePpm: 10.0,
      );
      expect(resHighH2s.isValid, isFalse);
      expect(resHighH2s.errors.first.contains('ไฮโดรเจนซัลไฟด์เกินเกณฑ์'), isTrue);
    });

    test('Confined space 4-role completeness validation', () {
      final roles = [
        ConfinedRoleModel(
          roleAssignmentId: '1',
          ptwNumber: 'PTW-01',
          roleType: ConfinedRoleType.authorizer,
          personName: 'Auth',
          companyName: 'Co',
          certNumber: 'C1',
          certInstitute: 'Inst',
          certIssueDate: '2026-01-01',
          certExpiryDate: '2028-01-01',
          contactPhone: '1',
        ),
        ConfinedRoleModel(
          roleAssignmentId: '2',
          ptwNumber: 'PTW-01',
          roleType: ConfinedRoleType.supervisor,
          personName: 'Sup',
          companyName: 'Co',
          certNumber: 'C2',
          certInstitute: 'Inst',
          certIssueDate: '2026-01-01',
          certExpiryDate: '2028-01-01',
          contactPhone: '2',
        ),
        ConfinedRoleModel(
          roleAssignmentId: '3',
          ptwNumber: 'PTW-01',
          roleType: ConfinedRoleType.attendant,
          personName: 'Att',
          companyName: 'Co',
          certNumber: 'C3',
          certInstitute: 'Inst',
          certIssueDate: '2026-01-01',
          certExpiryDate: '2028-01-01',
          contactPhone: '3',
        ),
        ConfinedRoleModel(
          roleAssignmentId: '4',
          ptwNumber: 'PTW-01',
          roleType: ConfinedRoleType.entrant,
          personName: 'Ent',
          companyName: 'Co',
          certNumber: 'C4',
          certInstitute: 'Inst',
          certIssueDate: '2026-01-01',
          certExpiryDate: '2028-01-01',
          contactPhone: '4',
        ),
      ];

      final resFull = PtwSafetyEvaluator.evaluateConfinedSpaceRoles(roles);
      expect(resFull.isValid, isTrue);

      // Missing Attendant
      final resMissingAtt = PtwSafetyEvaluator.evaluateConfinedSpaceRoles(
        roles.where((r) => r.roleType != ConfinedRoleType.attendant).toList(),
      );
      expect(resMissingAtt.isValid, isFalse);
      expect(resMissingAtt.errors.first.contains('ขาดผู้ช่วยเหลือ'), isTrue);
    });

    test('Fire Watch 30-min evaluation', () {
      final fw = FireWatchModel(
        watchId: '1',
        ptwNumber: 'PTW-01',
        fireWatcherName: 'Watcher',
        fireWatcherPhone: '081',
        fireExtinguisherType: 'Dry Chem',
        fireExtinguisherSerial: 'EXT-01',
        extinguisherInspectedReady: true,
        clearedRadiusMeters: 11.0,
        hotWorkEndTime: '2026-09-01T16:00:00',
        postWorkWatchStartTime: '2026-09-01T16:00:00',
        postWorkWatchDurationMinutes: 30,
        isPostWorkAreaSafe: true,
      );

      final resSafe = PtwSafetyEvaluator.evaluateFireWatch(fw);
      expect(resSafe.isValid, isTrue);

      final resTooShort = PtwSafetyEvaluator.evaluateFireWatch(
        fw.copyWith(postWorkWatchDurationMinutes: 25),
      );
      expect(resTooShort.isValid, isFalse);
      expect(resTooShort.errors.first.contains('ต้องไม่น้อยกว่า 30 นาที'), isTrue);
    });

    test('LOTO evaluation (zero energy verification & de-isolation)', () {
      final lotoList = [
        LotoIsolationModel(
          isolationId: '1',
          ptwNumber: 'PTW-01',
          equipmentTagNo: 'MCC-01',
          equipmentName: 'Pump Breaker',
          locationArea: 'Elec Room',
          energyType: EnergyType.electrical,
          isolationMethod: 'BREAKER_LOCK',
          padlockTagNo: 'P-01',
          lockAppliedBy: 'Electrician',
          lockAppliedTimestamp: '2026-09-01T08:00:00',
          zeroEnergyTestMethod: '0V Check',
          isZeroEnergyVerified: true,
          verifiedBy: 'Jane',
          isDeIsolated: false,
        )
      ];

      final resActive = PtwSafetyEvaluator.evaluateLoto(lotoList, requireDeIsolation: false);
      expect(resActive.isValid, isTrue);

      final resClose = PtwSafetyEvaluator.evaluateLoto(lotoList, requireDeIsolation: true);
      expect(resClose.isValid, isFalse);
      expect(resClose.errors.first.contains('ยังไม่ได้ทำการปลดล็อกคืนสภาพ'), isTrue);
    });

    test('Workflow transition guard rules', () {
      final draftPermit = PtwModel(
        ptwNumber: 'PTW-GUARD-01',
        workTitle: 'งานทาสีบนที่สูง',
        workDescription: 'ทาสีอาคารชั้น 3',
        primaryRiskType: HighRiskType.workingAtHeight,
        status: PtwStatus.draft,
        plantArea: 'Building A',
        specificLocation: 'Floor 3 Outside Wall',
        requestDate: '2026-09-01',
        workStartDate: '2026-09-01',
        workStartTime: '08:00',
        workEndDate: '2026-09-01',
        workEndTime: '17:00',
        applicantName: 'Somchai',
        applicantDepartment: 'Painting',
        applicantPhone: '081',
        emergencyRescuePlan: 'เบอร์ 1999',
        requiredPpeList: 'Harness',
        applicantSignaturePath: '/sign/somchai.png',
      );

      final canSubmit = PtwSafetyEvaluator.canSubmitDraft(draftPermit);
      expect(canSubmit.isValid, isTrue);

      final canApproveWithoutOfficer = PtwSafetyEvaluator.canApproveToActive(draftPermit);
      expect(canApproveWithoutOfficer.isValid, isFalse);

      final approvedPermit = draftPermit.copyWith(
        safetyOfficerSignaturePath: '/sign/safety.png',
        safetyOfficerName: 'Jane',
        authorizerSignaturePath: '/sign/auth.png',
        authorizerName: 'Prapat',
      );
      final canApproveWithSignatures = PtwSafetyEvaluator.canApproveToActive(approvedPermit);
      expect(canApproveWithSignatures.isValid, isTrue);
    });
  });

  group('PtwRepository SQLite Operations & KPI Tests', () {
    late Database testDb;
    late PtwRepository repository;

    setUp(() async {
      // Create in-memory database with PTW tables
      testDb = await openDatabase(
        inMemoryDatabasePath,
        version: 8,
        onCreate: (db, version) async {
          final helper = DatabaseHelper();
          await helper.database; // triggers standard setup if needed
          // Or execute table creation directly
        },
      );

      // Create PTW tables in in-memory DB
      await testDb.execute('''
        CREATE TABLE IF NOT EXISTS ptw_permits (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          ptw_number TEXT NOT NULL UNIQUE,
          work_title TEXT NOT NULL,
          work_description TEXT NOT NULL,
          primary_risk_type TEXT NOT NULL,
          secondary_risk_types TEXT,
          status TEXT NOT NULL DEFAULT 'DRAFT',
          plant_area TEXT NOT NULL,
          specific_location TEXT NOT NULL,
          request_date TEXT NOT NULL,
          work_start_date TEXT NOT NULL,
          work_start_time TEXT NOT NULL,
          work_end_date TEXT NOT NULL,
          work_end_time TEXT NOT NULL,
          extension_hours INTEGER DEFAULT 0,
          extension_reason TEXT,
          applicant_type TEXT NOT NULL DEFAULT 'INTERNAL_EMPLOYEE',
          applicant_name TEXT NOT NULL,
          applicant_department TEXT NOT NULL,
          applicant_phone TEXT NOT NULL,
          worker_count INTEGER DEFAULT 1,
          worker_names TEXT,
          jsa_reference_no TEXT,
          emergency_rescue_plan TEXT NOT NULL,
          required_ppe_list TEXT NOT NULL,
          special_precautions TEXT,
          applicant_signature_path TEXT,
          applicant_signed_at TEXT,
          safety_officer_signature_path TEXT,
          safety_officer_name TEXT,
          safety_officer_signed_at TEXT,
          authorizer_signature_path TEXT,
          authorizer_name TEXT,
          authorizer_signed_at TEXT,
          handover_signature_path TEXT,
          handover_signed_at TEXT,
          closure_signature_path TEXT,
          closure_signed_at TEXT,
          closure_remarks TEXT,
          site_photo_paths TEXT,
          qr_code_data TEXT,
          official_pdf_path TEXT,
          created_at TEXT DEFAULT CURRENT_TIMESTAMP,
          updated_at TEXT DEFAULT CURRENT_TIMESTAMP
        )
      ''');

      await testDb.execute('''
        CREATE TABLE IF NOT EXISTS ptw_gas_test_logs (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          log_id TEXT NOT NULL UNIQUE,
          ptw_number TEXT NOT NULL,
          test_stage TEXT NOT NULL,
          test_timestamp TEXT NOT NULL,
          location_point TEXT NOT NULL,
          oxygen_percent REAL NOT NULL,
          combustible_percent_lel REAL NOT NULL,
          carbon_monoxide_ppm REAL NOT NULL,
          hydrogen_sulfide_ppm REAL NOT NULL,
          toxic_other_ppm REAL,
          toxic_other_name TEXT,
          tester_name TEXT NOT NULL,
          tester_cert_no TEXT,
          detector_model TEXT NOT NULL,
          detector_serial_no TEXT NOT NULL,
          last_calibration_date TEXT NOT NULL,
          is_safe INTEGER NOT NULL DEFAULT 1,
          safety_remarks TEXT,
          signature_path TEXT,
          created_at TEXT DEFAULT CURRENT_TIMESTAMP
        )
      ''');

      await testDb.execute('''
        CREATE TABLE IF NOT EXISTS ptw_confined_roles (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          role_assignment_id TEXT NOT NULL UNIQUE,
          ptw_number TEXT NOT NULL,
          role_type TEXT NOT NULL,
          person_name TEXT NOT NULL,
          national_id TEXT,
          employee_id TEXT,
          company_name TEXT NOT NULL,
          cert_number TEXT NOT NULL,
          cert_institute TEXT NOT NULL,
          cert_issue_date TEXT NOT NULL,
          cert_expiry_date TEXT NOT NULL,
          contact_phone TEXT NOT NULL,
          is_trained_and_certified INTEGER NOT NULL DEFAULT 1,
          signature_path TEXT,
          created_at TEXT DEFAULT CURRENT_TIMESTAMP
        )
      ''');

      await testDb.execute('''
        CREATE TABLE IF NOT EXISTS ptw_fire_watches (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          watch_id TEXT NOT NULL UNIQUE,
          ptw_number TEXT NOT NULL UNIQUE,
          fire_watcher_name TEXT NOT NULL,
          fire_watcher_phone TEXT NOT NULL,
          fire_extinguisher_type TEXT NOT NULL,
          fire_extinguisher_serial TEXT NOT NULL,
          extinguisher_inspected_ready INTEGER NOT NULL DEFAULT 1,
          cleared_radius_meters REAL NOT NULL DEFAULT 11.0,
          fire_blanket_installed INTEGER NOT NULL DEFAULT 1,
          combustible_material_protected INTEGER NOT NULL DEFAULT 1,
          sewer_covered INTEGER NOT NULL DEFAULT 1,
          hot_work_end_time TEXT NOT NULL,
          post_work_watch_start_time TEXT NOT NULL,
          post_work_watch_end_time TEXT,
          post_work_watch_duration_minutes INTEGER NOT NULL DEFAULT 30,
          is_post_work_area_safe INTEGER NOT NULL DEFAULT 1,
          final_inspector_name TEXT,
          final_inspector_signature TEXT,
          notes TEXT,
          created_at TEXT DEFAULT CURRENT_TIMESTAMP
        )
      ''');

      await testDb.execute('''
        CREATE TABLE IF NOT EXISTS ptw_loto_isolations (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          isolation_id TEXT NOT NULL UNIQUE,
          ptw_number TEXT NOT NULL,
          equipment_tag_no TEXT NOT NULL,
          equipment_name TEXT NOT NULL,
          location_area TEXT NOT NULL,
          energy_type TEXT NOT NULL,
          isolation_method TEXT NOT NULL,
          padlock_tag_no TEXT NOT NULL,
          lock_applied_by TEXT NOT NULL,
          lock_applied_timestamp TEXT NOT NULL,
          zero_energy_test_method TEXT NOT NULL,
          is_zero_energy_verified INTEGER NOT NULL DEFAULT 1,
          verified_by TEXT NOT NULL,
          verified_timestamp TEXT,
          is_de_isolated INTEGER NOT NULL DEFAULT 0,
          de_isolated_by TEXT,
          de_isolated_timestamp TEXT,
          notes TEXT,
          created_at TEXT DEFAULT CURRENT_TIMESTAMP
        )
      ''');

      await testDb.execute('''
        CREATE TABLE IF NOT EXISTS ptw_checklists (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          ptw_number TEXT,
          item_id TEXT NOT NULL,
          risk_type TEXT NOT NULL,
          check_category TEXT NOT NULL,
          question_th TEXT NOT NULL,
          question_en TEXT NOT NULL,
          is_mandatory INTEGER NOT NULL DEFAULT 1,
          result TEXT NOT NULL DEFAULT 'NA',
          remarks TEXT,
          checked_by TEXT,
          checked_at TEXT
        )
      ''');

      await testDb.execute('''
        CREATE TABLE IF NOT EXISTS ptw_approval_logs (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          approval_id TEXT NOT NULL UNIQUE,
          ptw_number TEXT NOT NULL,
          approval_stage TEXT NOT NULL,
          approver_role TEXT NOT NULL,
          approver_name TEXT NOT NULL,
          approver_position TEXT,
          action TEXT NOT NULL,
          timestamp TEXT NOT NULL,
          comments TEXT,
          signature_path TEXT,
          created_at TEXT DEFAULT CURRENT_TIMESTAMP
        )
      ''');

      // Inject custom DatabaseHelper that provides testDb
      repository = _TestPtwRepository(testDb);
    });

    tearDown(() async {
      await testDb.close();
    });

    test('Repository CRUD and Child Relation Persistence', () async {
      final samplePermit = PtwModel(
        ptwNumber: 'PTW-20260901-001',
        workTitle: 'งานเชื่อมติดตั้งท่อส่งก๊าซ',
        workDescription: 'Hot work welding pipeline',
        primaryRiskType: HighRiskType.hotWork,
        status: PtwStatus.active,
        plantArea: 'Gas Plant',
        specificLocation: 'Line 2 Pipe Rack',
        requestDate: '2026-09-01',
        workStartDate: '2026-09-01',
        workStartTime: '08:00',
        workEndDate: '2026-09-01',
        workEndTime: '17:00',
        applicantName: 'Somchai Requestor',
        applicantDepartment: 'Mechanical',
        applicantPhone: '0812345678',
        emergencyRescuePlan: 'ติดต่อ 1999',
        requiredPpeList: 'Welding Mask, Gloves',
        fireWatch: FireWatchModel(
          watchId: 'FW-01',
          ptwNumber: 'PTW-20260901-001',
          fireWatcherName: 'Wichai',
          fireWatcherPhone: '082',
          fireExtinguisherType: 'Dry Chem 15 lbs',
          fireExtinguisherSerial: 'EXT-01',
          hotWorkEndTime: '2026-09-01T16:00:00',
          postWorkWatchStartTime: '2026-09-01T16:00:00',
          postWorkWatchDurationMinutes: 30,
          isPostWorkAreaSafe: true,
        ),
        checklistItems: [
          PtwChecklistModel(
            itemId: 'CHK-01',
            riskType: HighRiskType.hotWork,
            checkCategory: 'FIRE',
            questionTh: 'เตรียมถังดับเพลิง',
            questionEn: 'Fire extinguisher ready',
            result: 'YES',
          ),
        ],
      );

      // Save permit
      final saved = await repository.savePermit(samplePermit);
      expect(saved.id, isNotNull);

      // Fetch by number
      final fetched = await repository.getPermitByNumber('PTW-20260901-001');
      expect(fetched, isNotNull);
      expect(fetched!.workTitle, 'งานเชื่อมติดตั้งท่อส่งก๊าซ');
      expect(fetched.fireWatch, isNotNull);
      expect(fetched.fireWatch!.fireWatcherName, 'Wichai');
      expect(fetched.checklistItems.length, 1);

      // Add Gas Log
      final newGasLog = GasTestLogModel(
        logId: 'GAS-01',
        ptwNumber: 'PTW-20260901-001',
        testStage: 'CONTINUOUS',
        testTimestamp: '2026-09-01T10:00:00',
        locationPoint: 'Line 2 Pipe Rack',
        oxygenPercent: 20.9,
        combustiblePercentLel: 0.0,
        carbonMonoxidePpm: 0.0,
        hydrogenSulfidePpm: 0.0,
        testerName: 'Jane Safety',
        detectorModel: 'Dräger',
        detectorSerialNo: 'D-1',
        lastCalibrationDate: '2026-08-01',
        isSafe: true,
      );
      await repository.addGasTestLog('PTW-20260901-001', newGasLog);

      final gasLogs = await repository.getGasTestLogs('PTW-20260901-001');
      expect(gasLogs.length, 1);
      expect(gasLogs.first.logId, 'GAS-01');

      // Update status to Closed
      await repository.updatePermitStatus(
        'PTW-20260901-001',
        PtwStatus.closedCancelled,
        comments: 'งานเสร็จสิ้น ปลอดภัย',
        approverName: 'Jane Safety',
      );

      final updated = await repository.getPermitByNumber('PTW-20260901-001');
      expect(updated!.status, PtwStatus.closedCancelled);
      expect(updated.approvalLogs.length, 1);

      // Delete permit
      final deletedCount = await repository.deletePermit('PTW-20260901-001');
      expect(deletedCount, 1);
      final afterDelete = await repository.getPermitByNumber('PTW-20260901-001');
      expect(afterDelete, isNull);
    });

    test('Repository KPI calculation directly on SQLite', () async {
      // Seed multiple permits
      await repository.savePermit(PtwModel(
        ptwNumber: 'PTW-01',
        workTitle: 'Active Hot Work',
        workDescription: 'Desc',
        primaryRiskType: HighRiskType.hotWork,
        status: PtwStatus.active,
        plantArea: 'Plant A',
        specificLocation: 'Area 1',
        requestDate: '2026-09-01',
        workStartDate: '2026-09-01',
        workStartTime: '08:00',
        workEndDate: '2026-09-01',
        workEndTime: '18:00',
        applicantName: 'A',
        applicantDepartment: 'Maintenance',
        applicantPhone: '1',
        emergencyRescuePlan: 'Plan',
        requiredPpeList: 'PPE',
      ));

      await repository.savePermit(PtwModel(
        ptwNumber: 'PTW-02',
        workTitle: 'Pending Confined Space',
        workDescription: 'Desc',
        primaryRiskType: HighRiskType.confinedSpace,
        status: PtwStatus.pendingApproval,
        plantArea: 'Plant B',
        specificLocation: 'Silo',
        requestDate: '2026-09-01',
        workStartDate: '2026-09-01',
        workStartTime: '08:00',
        workEndDate: '2026-09-01',
        workEndTime: '18:00',
        applicantName: 'B',
        applicantDepartment: 'Production',
        applicantPhone: '2',
        emergencyRescuePlan: 'Plan',
        requiredPpeList: 'PPE',
      ));

      final kpi = await repository.getKpiSummary();
      expect(kpi.totalPermits, 2);
      expect(kpi.activeCount, 1);
      expect(kpi.pendingCount, 1);
      expect(kpi.hotWorkCount, 1);
      expect(kpi.confinedSpaceCount, 1);
      expect(kpi.complianceRatePercent, 100.0);
    });

    test('Repository next PTW Number generation', () async {
      final nextNum1 = await repository.generateNextPtwNumber(HighRiskType.hotWork);
      expect(nextNum1.startsWith('PTW-'), isTrue);
      expect(nextNum1.endsWith('-001'), isTrue);

      // Save a permit with this number
      await repository.savePermit(PtwModel(
        ptwNumber: nextNum1,
        workTitle: 'Test',
        workDescription: 'Test',
        primaryRiskType: HighRiskType.hotWork,
        status: PtwStatus.draft,
        plantArea: 'Area',
        specificLocation: 'Loc',
        requestDate: '2026-09-01',
        workStartDate: '2026-09-01',
        workStartTime: '08:00',
        workEndDate: '2026-09-01',
        workEndTime: '18:00',
        applicantName: 'Test',
        applicantDepartment: 'Test',
        applicantPhone: '1',
        emergencyRescuePlan: 'Plan',
        requiredPpeList: 'PPE',
      ));

      final nextNum2 = await repository.generateNextPtwNumber(HighRiskType.hotWork);
      expect(nextNum2.endsWith('-002'), isTrue);
    });
  });
}

class _TestPtwRepository extends PtwRepository {
  final Database _testDb;
  _TestPtwRepository(this._testDb);

  @override
  Future<Database> get _db async => _testDb;
}
