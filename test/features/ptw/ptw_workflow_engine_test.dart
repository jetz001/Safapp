import 'package:flutter_test/flutter_test.dart';
import 'package:safety_superapp/features/ptw/domain/enums/high_risk_type.dart';
import 'package:safety_superapp/features/ptw/domain/enums/ptw_status.dart';
import 'package:safety_superapp/features/ptw/domain/enums/confined_role_type.dart';
import 'package:safety_superapp/features/ptw/domain/enums/energy_type.dart';
import 'package:safety_superapp/features/ptw/data/models/ptw_model.dart';
import 'package:safety_superapp/features/ptw/data/models/gas_test_log_model.dart';
import 'package:safety_superapp/features/ptw/data/models/confined_role_model.dart';
import 'package:safety_superapp/features/ptw/data/models/fire_watch_model.dart';
import 'package:safety_superapp/features/ptw/data/models/loto_isolation_model.dart';
import 'package:safety_superapp/features/ptw/data/models/ptw_checklist_model.dart';
import 'package:safety_superapp/features/ptw/domain/services/ptw_workflow_engine.dart';

void main() {
  group('PtwWorkflowEngine State Machine Topology & Guards', () {
    late PtwModel sampleDraftPermit;

    setUp(() {
      sampleDraftPermit = PtwModel(
        ptwNumber: 'PTW-20260901-001',
        workTitle: 'งานตัดต่อท่อเคมีในถังไซโล',
        workDescription: 'งาน Hot Work และ Confined Space',
        primaryRiskType: HighRiskType.confinedSpace,
        secondaryRiskTypes: const [HighRiskType.hotWork, HighRiskType.electricalLoto],
        status: PtwStatus.draft,
        plantArea: 'Plant 1',
        specificLocation: 'Silo Tank #3',
        requestDate: '2026-09-01',
        workStartDate: '2026-09-01',
        workStartTime: '08:00',
        workEndDate: '2026-09-01',
        workEndTime: '17:00',
        applicantName: 'Somchai Requestor',
        applicantDepartment: 'Maintenance',
        applicantPhone: '0812345678',
        workerCount: 4,
        emergencyRescuePlan: 'เบอร์ติดต่อกู้ภัยภายใน 1999',
        requiredPpeList: 'Harness, SCBA, Fire Suit',
        applicantSignaturePath: '/signatures/applicant.png',
        checklistItems: [
          PtwChecklistModel(
            itemId: 'CHK-01',
            riskType: HighRiskType.confinedSpace,
            checkCategory: 'VENTILATION',
            questionTh: 'เป่าระบายอากาศอย่างน้อย 15 นาที',
            questionEn: 'Ventilation blower operated',
            isMandatory: true,
            result: 'YES',
          ),
        ],
      );
    });

    test('Topology allowed transitions map', () {
      expect(
        PtwWorkflowEngine.getAllowedTargetStatuses(PtwStatus.draft),
        [PtwStatus.pendingApproval, PtwStatus.closedCancelled],
      );
      expect(
        PtwWorkflowEngine.getAllowedTargetStatuses(PtwStatus.pendingApproval),
        [PtwStatus.active, PtwStatus.draft, PtwStatus.closedCancelled],
      );
      expect(
        PtwWorkflowEngine.getAllowedTargetStatuses(PtwStatus.active),
        [PtwStatus.extendedHandover, PtwStatus.closedCancelled],
      );
      expect(
        PtwWorkflowEngine.getAllowedTargetStatuses(PtwStatus.extendedHandover),
        [PtwStatus.active, PtwStatus.closedCancelled],
      );
      expect(
        PtwWorkflowEngine.getAllowedTargetStatuses(PtwStatus.closedCancelled),
        isEmpty,
      );
    });

    test('Direct jump from Draft to Active is rejected (violates topology)', () {
      final res = PtwWorkflowEngine.validateTransition(
        currentPermit: sampleDraftPermit,
        targetStatus: PtwStatus.active,
      );
      expect(res.isAllowed, isFalse);
      expect(res.validationErrors.first.contains('ไม่อนุญาตให้เปลี่ยนสถานะ'), isTrue);
    });

    test('Same status transition is rejected', () {
      final res = PtwWorkflowEngine.validateTransition(
        currentPermit: sampleDraftPermit,
        targetStatus: PtwStatus.draft,
      );
      expect(res.isAllowed, isFalse);
      expect(res.validationErrors.first.contains('อยู่ในสถานะ'), isTrue);
    });

    test('Transition from ClosedCancelled is rejected (terminal state)', () {
      final closedPermit = sampleDraftPermit.copyWith(status: PtwStatus.closedCancelled);
      final res = PtwWorkflowEngine.validateTransition(
        currentPermit: closedPermit,
        targetStatus: PtwStatus.active,
      );
      expect(res.isAllowed, isFalse);
      expect(res.validationErrors.first.contains('ปิดงานหรือถูกยกเลิกแล้ว'), isTrue);
    });

    test('Draft to PendingApproval succeeds when mandatory fields and checklist are complete', () {
      final res = PtwWorkflowEngine.validateTransition(
        currentPermit: sampleDraftPermit,
        targetStatus: PtwStatus.pendingApproval,
      );
      expect(res.isAllowed, isTrue);
      expect(res.validationErrors, isEmpty);
    });

    test('Draft to PendingApproval fails when applicant signature is missing', () {
      final incompletePermit = sampleDraftPermit.copyWith(applicantSignaturePath: null);
      final res = PtwWorkflowEngine.validateTransition(
        currentPermit: incompletePermit,
        targetStatus: PtwStatus.pendingApproval,
      );
      expect(res.isAllowed, isFalse);
      expect(res.validationErrors.any((e) => e.contains('ลายเซ็น')), isTrue);
    });

    test('Draft to PendingApproval fails when mandatory checklist item is not YES', () {
      final incompletePermit = sampleDraftPermit.copyWith(
        checklistItems: [
          PtwChecklistModel(
            itemId: 'CHK-01',
            riskType: HighRiskType.confinedSpace,
            checkCategory: 'VENTILATION',
            questionTh: 'เป่าระบายอากาศอย่างน้อย 15 นาที',
            questionEn: 'Ventilation blower operated',
            isMandatory: true,
            result: 'NO',
          ),
        ],
      );
      final res = PtwWorkflowEngine.validateTransition(
        currentPermit: incompletePermit,
        targetStatus: PtwStatus.pendingApproval,
      );
      expect(res.isAllowed, isFalse);
      expect(res.validationErrors.any((e) => e.contains('Checklist')), isTrue);
    });

    test('PendingApproval to Active requires Safety Officer & Authorizer Signatures', () {
      final pendingPermit = sampleDraftPermit.copyWith(status: PtwStatus.pendingApproval);
      final resWithoutSignatures = PtwWorkflowEngine.validateTransition(
        currentPermit: pendingPermit,
        targetStatus: PtwStatus.active,
      );
      expect(resWithoutSignatures.isAllowed, isFalse);
      expect(resWithoutSignatures.validationErrors.any((e) => e.contains('จป.วิชาชีพ')), isTrue);
      expect(resWithoutSignatures.validationErrors.any((e) => e.contains('ผู้อนุญาต')), isTrue);
    });

    test('PendingApproval to Active for Confined Space requires 4 roles and safe Pre-entry Gas Test', () {
      final pendingPermit = sampleDraftPermit.copyWith(
        status: PtwStatus.pendingApproval,
        safetyOfficerSignaturePath: '/sign/safety.png',
        safetyOfficerName: 'Jane Safety',
        authorizerSignaturePath: '/sign/auth.png',
        authorizerName: 'Dr. Prapat',
      );

      final resMissingRoles = PtwWorkflowEngine.validateTransition(
        currentPermit: pendingPermit,
        targetStatus: PtwStatus.active,
      );
      expect(resMissingRoles.isAllowed, isFalse);
      expect(resMissingRoles.validationErrors.any((e) => e.contains('ผู้อนุญาต')), isTrue);
      expect(resMissingRoles.validationErrors.any((e) => e.contains('Pre-entry')), isTrue);

      // Now supply 4 roles, safe pre-entry gas test, and LOTO
      final fullyCompliantPending = pendingPermit.copyWith(
        confinedRoles: [
          ConfinedRoleModel(
            roleAssignmentId: '1',
            ptwNumber: pendingPermit.ptwNumber,
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
            roleAssignmentId: '2',
            ptwNumber: pendingPermit.ptwNumber,
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
            roleAssignmentId: '3',
            ptwNumber: pendingPermit.ptwNumber,
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
            roleAssignmentId: '4',
            ptwNumber: pendingPermit.ptwNumber,
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
        gasTestLogs: [
          GasTestLogModel(
            logId: 'GAS-01',
            ptwNumber: pendingPermit.ptwNumber,
            testStage: 'PRE_ENTRY',
            testTimestamp: '2026-09-01T07:45:00',
            locationPoint: 'Silo Bottom',
            oxygenPercent: 20.9,
            combustiblePercentLel: 0.0,
            carbonMonoxidePpm: 0.0,
            hydrogenSulfidePpm: 0.0,
            testerName: 'Jane Safety',
            detectorModel: 'Dräger X-am 5000',
            detectorSerialNo: 'DR-01',
            lastCalibrationDate: '2026-08-01',
            isSafe: true,
          ),
        ],
        lotoIsolations: [
          LotoIsolationModel(
            isolationId: 'L-01',
            ptwNumber: pendingPermit.ptwNumber,
            equipmentTagNo: 'VALVE-01',
            equipmentName: 'Chemical Feed Valve',
            locationArea: 'Silo Top',
            energyType: EnergyType.chemical,
            isolationMethod: 'BLIND_FLANGE',
            padlockTagNo: 'PAD-01',
            lockAppliedBy: 'Somsak',
            lockAppliedTimestamp: '2026-09-01T07:30:00',
            zeroEnergyTestMethod: 'Drain check 0 bar',
            isZeroEnergyVerified: true,
            verifiedBy: 'Jane Safety',
          ),
        ],
      );

      final resCompliant = PtwWorkflowEngine.validateTransition(
        currentPermit: fullyCompliantPending,
        targetStatus: PtwStatus.active,
      );
      expect(resCompliant.isAllowed, isTrue);
      expect(resCompliant.validationErrors, isEmpty);
    });

    test('PendingApproval back to Draft requires non-empty rejectionReason', () {
      final pendingPermit = sampleDraftPermit.copyWith(status: PtwStatus.pendingApproval);
      final resNoReason = PtwWorkflowEngine.validateTransition(
        currentPermit: pendingPermit,
        targetStatus: PtwStatus.draft,
      );
      expect(resNoReason.isAllowed, isFalse);
      expect(resNoReason.validationErrors.first.contains('ต้องระบุเหตุผล'), isTrue);

      final resWithReason = PtwWorkflowEngine.validateTransition(
        currentPermit: pendingPermit,
        targetStatus: PtwStatus.draft,
        rejectionReason: 'โปรดแนบเอกสาร JSA ฉบับปรับปรุงใหม่',
      );
      expect(resWithReason.isAllowed, isTrue);
      expect(resWithReason.message!.contains('ตีกลับ'), isTrue);
    });

    test('Active to ExtendedHandover validates hours and reason', () {
      final activePermit = sampleDraftPermit.copyWith(
        status: PtwStatus.active,
        extensionHours: 0,
        extensionReason: '',
      );

      final resInvalid = PtwWorkflowEngine.validateTransition(
        currentPermit: activePermit,
        targetStatus: PtwStatus.extendedHandover,
      );
      expect(resInvalid.isAllowed, isFalse);
      expect(resInvalid.validationErrors.any((e) => e.contains('จำนวนชั่วโมง')), isTrue);

      final validExtension = activePermit.copyWith(
        extensionHours: 3,
        extensionReason: 'งานเชื่อมมีความล่าช้าเนื่องจากฝนตก',
        handoverSignaturePath: '/sign/handover.png',
      );
      final resValid = PtwWorkflowEngine.validateTransition(
        currentPermit: validExtension,
        targetStatus: PtwStatus.extendedHandover,
      );
      expect(resValid.isAllowed, isTrue);
    });

    test('Active to ClosedCancelled enforces 30-minute fire watch and LOTO de-isolation', () {
      final activePermit = sampleDraftPermit.copyWith(
        status: PtwStatus.active,
        closureSignaturePath: '/sign/closure.png',
        fireWatch: FireWatchModel(
          watchId: 'FW-01',
          ptwNumber: sampleDraftPermit.ptwNumber,
          fireWatcherName: 'Watcher',
          fireWatcherPhone: '081',
          fireExtinguisherType: 'Dry Chem',
          fireExtinguisherSerial: 'EXT-01',
          extinguisherInspectedReady: true,
          clearedRadiusMeters: 11.0,
          hotWorkEndTime: '2026-09-01T16:00:00',
          postWorkWatchStartTime: '2026-09-01T16:00:00',
          postWorkWatchDurationMinutes: 20, // VIOLATION: < 30 min
          isPostWorkAreaSafe: true,
        ),
        lotoIsolations: [
          LotoIsolationModel(
            isolationId: 'L-01',
            ptwNumber: sampleDraftPermit.ptwNumber,
            equipmentTagNo: 'VALVE-01',
            equipmentName: 'Chemical Feed Valve',
            locationArea: 'Silo Top',
            energyType: EnergyType.chemical,
            isolationMethod: 'BLIND_FLANGE',
            padlockTagNo: 'PAD-01',
            lockAppliedBy: 'Somsak',
            lockAppliedTimestamp: '2026-09-01T07:30:00',
            zeroEnergyTestMethod: 'Drain check 0 bar',
            isZeroEnergyVerified: true,
            verifiedBy: 'Jane Safety',
            isDeIsolated: false, // VIOLATION: Not de-isolated
          ),
        ],
      );

      final resNonCompliant = PtwWorkflowEngine.validateTransition(
        currentPermit: activePermit,
        targetStatus: PtwStatus.closedCancelled,
      );
      expect(resNonCompliant.isAllowed, isFalse);
      expect(resNonCompliant.validationErrors.any((e) => e.contains('30 นาที')), isTrue);
      expect(resNonCompliant.validationErrors.any((e) => e.contains('ปลดล็อกคืนสภาพ')), isTrue);

      // Fix Fire Watch and LOTO de-isolation
      final fullyClosedPermit = activePermit.copyWith(
        fireWatch: activePermit.fireWatch!.copyWith(postWorkWatchDurationMinutes: 35),
        lotoIsolations: [
          activePermit.lotoIsolations.first.copyWith(
            isDeIsolated: true,
            deIsolatedBy: 'Jane Safety',
            deIsolatedTimestamp: '2026-09-01T17:00:00',
          ),
        ],
      );

      final resCompliantClose = PtwWorkflowEngine.validateTransition(
        currentPermit: fullyClosedPermit,
        targetStatus: PtwStatus.closedCancelled,
      );
      expect(resCompliantClose.isAllowed, isTrue);
    });

    test('applyTransition generates audit approval log and attaches signature paths', () {
      final updated = PtwWorkflowEngine.applyTransition(
        sampleDraftPermit,
        PtwStatus.pendingApproval,
        signatoryName: 'Somchai Applicant',
        signatoryRole: 'APPLICANT',
        signaturePath: '/signatures/applicant_01.png',
        comments: 'ยื่นคำขออนุมัติงานความเสี่ยงสูง',
      );

      expect(updated.status, PtwStatus.pendingApproval);
      expect(updated.approvalLogs.length, 1);
      expect(updated.approvalLogs.first.approverName, 'Somchai Applicant');
      expect(updated.approvalLogs.first.action, 'TRANSITION_TO_PENDING_APPROVAL');
      expect(updated.applicantSignaturePath, '/signatures/applicant_01.png');
    });
  });
}
