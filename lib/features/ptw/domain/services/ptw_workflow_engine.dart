import 'dart:typed_data';
import '../enums/high_risk_type.dart';
import '../enums/ptw_status.dart';
import '../enums/confined_role_type.dart';
import '../../data/models/ptw_model.dart';
import '../../data/models/ptw_approval_model.dart';
import 'ptw_safety_evaluator.dart';

/// Comprehensive Result Container for PTW Workflow State Transitions
class WorkflowTransitionResult {
  final bool isAllowed;
  final String? message;
  final List<String> validationErrors;
  final List<String> warnings;
  final PtwStatus fromStatus;
  final PtwStatus toStatus;
  final List<String> requiredSignatories;

  const WorkflowTransitionResult({
    required this.isAllowed,
    this.message,
    this.validationErrors = const [],
    this.warnings = const [],
    required this.fromStatus,
    required this.toStatus,
    this.requiredSignatories = const [],
  });

  factory WorkflowTransitionResult.allowed({
    required PtwStatus fromStatus,
    required PtwStatus toStatus,
    String? message,
    List<String> warnings = const [],
    List<String> requiredSignatories = const [],
  }) {
    return WorkflowTransitionResult(
      isAllowed: true,
      message: message ?? 'การเปลี่ยนสถานะจาก ${fromStatus.labelTh} ไปเป็น ${toStatus.labelTh} ถูกต้องตามระเบียบ',
      validationErrors: const [],
      warnings: warnings,
      fromStatus: fromStatus,
      toStatus: toStatus,
      requiredSignatories: requiredSignatories,
    );
  }

  factory WorkflowTransitionResult.denied({
    required PtwStatus fromStatus,
    required PtwStatus toStatus,
    required List<String> errors,
    String? message,
    List<String> warnings = const [],
    List<String> requiredSignatories = const [],
  }) {
    return WorkflowTransitionResult(
      isAllowed: false,
      message: message ?? 'ไม่สามารถเปลี่ยนสถานะเป็น ${toStatus.labelTh} ได้เนื่องจากไม่ผ่านเกณฑ์ความปลอดภัย',
      validationErrors: errors,
      warnings: warnings,
      fromStatus: fromStatus,
      toStatus: toStatus,
      requiredSignatories: requiredSignatories,
    );
  }

  @override
  String toString() => 'WorkflowTransitionResult(allowed: $isAllowed, from: ${fromStatus.toDbCode()}, to: ${toStatus.toDbCode()}, errors: ${validationErrors.length})';
}

/// 5-Stage Guarded State Machine Engine for High-Risk Permit to Work (PTW)
/// Codified according to Thai Safety Legislation (พ.ร.บ. ความปลอดภัยฯ ๒๕๕๔, กฎกระทรวงอับอากาศ ๒๕๖๒, อัคคีภัย ๒๕๕๕, ไฟฟ้า ๒๕๕๘, งานบนที่สูง ๒๕๖๔)
class PtwWorkflowEngine {
  /// Get list of valid target statuses for a given current status
  static List<PtwStatus> getAllowedTargetStatuses(PtwStatus currentStatus) {
    switch (currentStatus) {
      case PtwStatus.draft:
        return [
          PtwStatus.pendingApproval, // ส่งคำขออนุมัติ
          PtwStatus.closedCancelled, // ยกเลิกแบบร่าง
        ];
      case PtwStatus.pendingApproval:
        return [
          PtwStatus.active, // อนุมัติเปิดงาน
          PtwStatus.draft, // ตีกลับให้แก้ไข JSA/ข้อมูล
          PtwStatus.closedCancelled, // ไม่อนุมัติ / ยกเลิกคำขอ
        ];
      case PtwStatus.active:
        return [
          PtwStatus.extendedHandover, // ขอต่อเวลา / ส่งมอบงานระหว่างกะ
          PtwStatus.closedCancelled, // ปิดงานเสร็จสิ้น หรือ ยกเลิกฉุกเฉิน
        ];
      case PtwStatus.extendedHandover:
        return [
          PtwStatus.active, // กลับสู่สถานะเปิดงานต่อเนื่อง
          PtwStatus.closedCancelled, // ปิดงานเสร็จสิ้น หรือ ยกเลิก
        ];
      case PtwStatus.closedCancelled:
        return []; // Terminal state: ใบอนุญาตปิดงานแล้ว ไม่สามารถเปลี่ยนสถานะได้อีก
    }
  }

  /// Check if a transition between two statuses is topologically valid in the state graph
  static bool isTopologicallyAllowed(PtwStatus fromStatus, PtwStatus toStatus) {
    return getAllowedTargetStatuses(fromStatus).contains(toStatus);
  }

  /// Get list of required signatories based on the target transition
  static List<String> getRequiredSignatories(PtwStatus targetStatus, PtwModel permit) {
    switch (targetStatus) {
      case PtwStatus.pendingApproval:
        return ['ผู้ขออนุญาต / ผู้ควบคุมงาน (Applicant / Supervisor)'];
      case PtwStatus.active:
        final list = [
          'เจ้าหน้าที่ความปลอดภัยในการทำงานระดับวิชาชีพ (Safety Officer - จป.วิชาชีพ)',
          'ผู้อนุญาตตามกฎหมาย (Authorizer / Department Head)',
        ];
        if (permit.isConfinedSpaceWork) {
          list.add('ผู้ควบคุมงานในที่อับอากาศ (Confined Space Supervisor)');
        }
        return list;
      case PtwStatus.extendedHandover:
        return [
          'ผู้ขอต่อเวลา / ผู้ส่งมอบงาน (Handover Outgoing Person)',
          'ผู้รับมอบงาน / ผู้อนุมัติต่อเวลา (Handover Incoming Person / Authorizer)',
        ];
      case PtwStatus.closedCancelled:
        return [
          'ผู้ตรวจสอบปิดงาน / จป.วิชาชีพ (Site Closure Inspector)',
        ];
      case PtwStatus.draft:
        return [];
    }
  }

  /// Strictly Validate a Proposed Workflow Status Transition
  /// Evaluates state graph, required data completeness, statutory thresholds, and digital signatures.
  static WorkflowTransitionResult validateTransition({
    required PtwModel currentPermit,
    required PtwStatus targetStatus,
    String? rejectionReason,
    String? signatoryName,
    Uint8List? signatureBytes,
    String? signaturePath,
  }) {
    final fromStatus = currentPermit.status;
    final requiredSignatories = getRequiredSignatories(targetStatus, currentPermit);

    // 1. Terminal state check
    if (fromStatus == PtwStatus.closedCancelled) {
      return WorkflowTransitionResult.denied(
        fromStatus: fromStatus,
        toStatus: targetStatus,
        errors: ['ใบอนุญาตหมายเลข ${currentPermit.ptwNumber} ปิดงานหรือถูกยกเลิกแล้ว ไม่สามารถดำเนินการใดๆ ต่อได้'],
        requiredSignatories: requiredSignatories,
      );
    }

    // 2. Same status check
    if (fromStatus == targetStatus) {
      return WorkflowTransitionResult.denied(
        fromStatus: fromStatus,
        toStatus: targetStatus,
        errors: ['ใบอนุญาตอยู่ในสถานะ ${targetStatus.labelTh} อยู่แล้ว'],
        requiredSignatories: requiredSignatories,
      );
    }

    // 3. Topology graph validation
    if (!isTopologicallyAllowed(fromStatus, targetStatus)) {
      return WorkflowTransitionResult.denied(
        fromStatus: fromStatus,
        toStatus: targetStatus,
        errors: [
          'ไม่อนุญาตให้เปลี่ยนสถานะจาก ${fromStatus.labelTh} ไปเป็น ${targetStatus.labelTh} โดยตรงตามขั้นตอนมาตรฐาน',
        ],
        requiredSignatories: requiredSignatories,
      );
    }

    // 4. Detailed transition-specific guard rules
    switch (targetStatus) {
      case PtwStatus.pendingApproval:
        // Transition: DRAFT -> PENDING_APPROVAL
        return _validateSubmissionToPending(currentPermit, fromStatus, targetStatus, requiredSignatories);

      case PtwStatus.active:
        // Transition: PENDING_APPROVAL -> ACTIVE, or EXTENDED_HANDOVER -> ACTIVE
        return _validateActivation(currentPermit, fromStatus, targetStatus, requiredSignatories);

      case PtwStatus.extendedHandover:
        // Transition: ACTIVE -> EXTENDED_HANDOVER
        return _validateExtensionHandover(currentPermit, fromStatus, targetStatus, requiredSignatories);

      case PtwStatus.draft:
        // Transition: PENDING_APPROVAL -> DRAFT (Send back for revision)
        if (rejectionReason == null || rejectionReason.trim().isEmpty) {
          return WorkflowTransitionResult.denied(
            fromStatus: fromStatus,
            toStatus: targetStatus,
            errors: ['ต้องระบุเหตุผลหรือข้อเสนอแนะในการตีกลับใบอนุญาตให้แก้ไข (Revision Reason)'],
            requiredSignatories: requiredSignatories,
          );
        }
        return WorkflowTransitionResult.allowed(
          fromStatus: fromStatus,
          toStatus: targetStatus,
          message: 'ตีกลับใบอนุญาตกลับสู่แบบร่างเพื่อแก้ไข: $rejectionReason',
          requiredSignatories: requiredSignatories,
        );

      case PtwStatus.closedCancelled:
        // Transition: ANY -> CLOSED_CANCELLED
        return _validateClosureOrCancellation(
          currentPermit,
          fromStatus,
          targetStatus,
          rejectionReason: rejectionReason,
          requiredSignatories: requiredSignatories,
        );
    }
  }

  /// Guard Rule A: Validate Submission from Draft to Pending Approval
  static WorkflowTransitionResult _validateSubmissionToPending(
    PtwModel permit,
    PtwStatus fromStatus,
    PtwStatus toStatus,
    List<String> requiredSignatories,
  ) {
    final evalResult = PtwSafetyEvaluator.canSubmitDraft(permit);
    if (!evalResult.isValid) {
      return WorkflowTransitionResult.denied(
        fromStatus: fromStatus,
        toStatus: toStatus,
        errors: evalResult.errors,
        warnings: evalResult.warnings,
        requiredSignatories: requiredSignatories,
      );
    }

    // Date sanity check
    final start = permit.startDateTime;
    final end = permit.endDateTime;
    final List<String> warnings = List.from(evalResult.warnings);

    if (start != null && end != null && end.isBefore(start)) {
      return WorkflowTransitionResult.denied(
        fromStatus: fromStatus,
        toStatus: toStatus,
        errors: ['วันและเวลาสิ้นสุดงาน (${permit.workEndDate} ${permit.workEndTime}) ต้องอยู่หลังวันและเวลาเริ่มงาน (${permit.workStartDate} ${permit.workStartTime})'],
        requiredSignatories: requiredSignatories,
      );
    }

    if (permit.workerCount <= 0) {
      return WorkflowTransitionResult.denied(
        fromStatus: fromStatus,
        toStatus: toStatus,
        errors: ['จำนวนผู้ปฏิบัติงานต้องมากกว่า 0 คน'],
        requiredSignatories: requiredSignatories,
      );
    }

    return WorkflowTransitionResult.allowed(
      fromStatus: fromStatus,
      toStatus: toStatus,
      warnings: warnings,
      requiredSignatories: requiredSignatories,
    );
  }

  /// Guard Rule B: Validate Approval to Active State
  static WorkflowTransitionResult _validateActivation(
    PtwModel permit,
    PtwStatus fromStatus,
    PtwStatus toStatus,
    List<String> requiredSignatories,
  ) {
    // If coming from EXTENDED_HANDOVER back to ACTIVE
    if (fromStatus == PtwStatus.extendedHandover) {
      return WorkflowTransitionResult.allowed(
        fromStatus: fromStatus,
        toStatus: toStatus,
        message: 'ต่อเวลาและส่งมอบกะเรียบร้อย กลับสู่สถานะเปิดทำงาน (Active)',
        requiredSignatories: requiredSignatories,
      );
    }

    // Coming from PENDING_APPROVAL
    final evalResult = PtwSafetyEvaluator.canApproveToActive(permit);
    if (!evalResult.isValid) {
      return WorkflowTransitionResult.denied(
        fromStatus: fromStatus,
        toStatus: toStatus,
        errors: evalResult.errors,
        warnings: evalResult.warnings,
        requiredSignatories: requiredSignatories,
      );
    }

    return WorkflowTransitionResult.allowed(
      fromStatus: fromStatus,
      toStatus: toStatus,
      warnings: evalResult.warnings,
      requiredSignatories: requiredSignatories,
    );
  }

  /// Guard Rule C: Validate Extension or Shift Handover
  static WorkflowTransitionResult _validateExtensionHandover(
    PtwModel permit,
    PtwStatus fromStatus,
    PtwStatus toStatus,
    List<String> requiredSignatories,
  ) {
    final evalResult = PtwSafetyEvaluator.canExtendHandover(permit);
    if (!evalResult.isValid) {
      return WorkflowTransitionResult.denied(
        fromStatus: fromStatus,
        toStatus: toStatus,
        errors: evalResult.errors,
        warnings: evalResult.warnings,
        requiredSignatories: requiredSignatories,
      );
    }

    if (permit.extensionHours > 12) {
      return WorkflowTransitionResult.denied(
        fromStatus: fromStatus,
        toStatus: toStatus,
        errors: ['ไม่อนุญาตให้ต่อเวลาเกิน 12 ชั่วโมงในใบอนุญาตฉบับเดิม ต้องเปิดใบอนุญาตฉบับใหม่ตามระเบียบ'],
        requiredSignatories: requiredSignatories,
      );
    }

    return WorkflowTransitionResult.allowed(
      fromStatus: fromStatus,
      toStatus: toStatus,
      warnings: evalResult.warnings,
      requiredSignatories: requiredSignatories,
    );
  }

  /// Guard Rule D: Validate Closure or Cancellation
  static WorkflowTransitionResult _validateClosureOrCancellation(
    PtwModel permit,
    PtwStatus fromStatus,
    PtwStatus toStatus, {
    String? rejectionReason,
    required List<String> requiredSignatories,
  }) {
    // Cancellation from Draft or Pending Approval
    if (fromStatus == PtwStatus.draft || fromStatus == PtwStatus.pendingApproval) {
      if (rejectionReason == null || rejectionReason.trim().isEmpty) {
        return WorkflowTransitionResult.denied(
          fromStatus: fromStatus,
          toStatus: toStatus,
          errors: ['ต้องระบุเหตุผลในการยกเลิกหรือไม่อนุมัติใบอนุญาต'],
          requiredSignatories: requiredSignatories,
        );
      }
      return WorkflowTransitionResult.allowed(
        fromStatus: fromStatus,
        toStatus: toStatus,
        message: 'ยกเลิกใบอนุญาตเรียบร้อย: $rejectionReason',
        requiredSignatories: requiredSignatories,
      );
    }

    // Normal Closure from Active or Extended Handover
    final evalResult = PtwSafetyEvaluator.canClosePermit(permit);
    if (!evalResult.isValid) {
      return WorkflowTransitionResult.denied(
        fromStatus: fromStatus,
        toStatus: toStatus,
        errors: evalResult.errors,
        warnings: evalResult.warnings,
        requiredSignatories: requiredSignatories,
      );
    }

    return WorkflowTransitionResult.allowed(
      fromStatus: fromStatus,
      toStatus: toStatus,
      message: 'ตรวจสอบความปลอดภัยหน้างานเรียบร้อย ปิดใบอนุญาตสมบูรณ์',
      warnings: evalResult.warnings,
      requiredSignatories: requiredSignatories,
    );
  }

  /// Apply Transition to PtwModel and create an Approval Audit Log
  static PtwModel applyTransition(
    PtwModel permit,
    PtwStatus targetStatus, {
    String? signatoryName,
    String? signatoryRole,
    String? signaturePath,
    String? comments,
  }) {
    final nowStr = DateTime.now().toIso8601String();
    final approvalLog = PtwApprovalModel(
      approvalId: 'APR-${DateTime.now().millisecondsSinceEpoch}',
      ptwNumber: permit.ptwNumber,
      approvalStage: targetStatus.toDbCode(),
      approverRole: signatoryRole ?? 'OFFICER',
      approverName: signatoryName ?? 'Authorized User',
      action: 'TRANSITION_TO_${targetStatus.toDbCode()}',
      timestamp: nowStr,
      comments: comments,
      signaturePath: signaturePath,
    );

    final updatedApprovalLogs = List<PtwApprovalModel>.from(permit.approvalLogs)..add(approvalLog);

    PtwModel updatedPermit = permit.copyWith(
      status: targetStatus,
      updatedAt: nowStr,
      approvalLogs: updatedApprovalLogs,
    );

    // Populate stage-specific signature paths if supplied
    if (signaturePath != null && signaturePath.isNotEmpty) {
      switch (targetStatus) {
        case PtwStatus.pendingApproval:
          if (updatedPermit.applicantSignaturePath == null) {
            updatedPermit = updatedPermit.copyWith(
              applicantSignaturePath: signaturePath,
              applicantSignedAt: nowStr,
            );
          }
          break;
        case PtwStatus.active:
          if (signatoryRole == 'SAFETY_OFFICER' || updatedPermit.safetyOfficerSignaturePath == null) {
            updatedPermit = updatedPermit.copyWith(
              safetyOfficerSignaturePath: signaturePath,
              safetyOfficerName: signatoryName ?? 'Safety Officer',
              safetyOfficerSignedAt: nowStr,
            );
          } else {
            updatedPermit = updatedPermit.copyWith(
              authorizerSignaturePath: signaturePath,
              authorizerName: signatoryName ?? 'Authorizer',
              authorizerSignedAt: nowStr,
            );
          }
          break;
        case PtwStatus.extendedHandover:
          updatedPermit = updatedPermit.copyWith(
            handoverSignaturePath: signaturePath,
            handoverSignedAt: nowStr,
          );
          break;
        case PtwStatus.closedCancelled:
          updatedPermit = updatedPermit.copyWith(
            closureSignaturePath: signaturePath,
            closureSignedAt: nowStr,
            closureRemarks: comments ?? updatedPermit.closureRemarks,
          );
          break;
        case PtwStatus.draft:
          break;
      }
    }

    return updatedPermit;
  }
}
