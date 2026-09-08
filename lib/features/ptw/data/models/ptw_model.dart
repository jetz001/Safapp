import 'dart:convert';
import '../../domain/enums/high_risk_type.dart';
import '../../domain/enums/ptw_status.dart';
import '../../domain/enums/confined_role_type.dart';
import 'gas_test_log_model.dart';
import 'confined_role_model.dart';
import 'fire_watch_model.dart';
import 'loto_isolation_model.dart';
import 'ptw_checklist_model.dart';
import 'ptw_approval_model.dart';

/// Comprehensive Master Permit to Work (PTW) Model
/// Covering 5 High-Risk Operations under Thai OSH Legislation
class PtwModel {
  final int? id;
  final String ptwNumber; // e.g. "PTW-20260901-001"
  final String workTitle; // ชื่องานที่ขออนุญาต
  final String workDescription; // รายละเอียดงาน
  final HighRiskType primaryRiskType; // ประเภทความเสี่ยงหลัก
  final List<HighRiskType> secondaryRiskTypes; // ความเสี่ยงร่วม
  final PtwStatus status;
  final String plantArea; // โรงงาน / อาคาร / แผนก
  final String specificLocation; // ตำแหน่งเฉพาะเจาะจง
  final String requestDate; // วันที่ยื่นคำขอ (YYYY-MM-DD)
  final String workStartDate; // วันที่เริ่มปฏิบัติงาน (YYYY-MM-DD)
  final String workStartTime; // เวลาเริ่ม (HH:mm)
  final String workEndDate; // วันที่สิ้นสุด (YYYY-MM-DD)
  final String workEndTime; // เวลาสิ้นสุด (HH:mm)
  final int extensionHours; // จำนวนชั่วโมงที่ขอต่อเวลา
  final String? extensionReason; // เหตุผลการขอต่อเวลา

  // Applicant & Contractor Information
  final String applicantType; // 'INTERNAL_EMPLOYEE' or 'CONTRACTOR'
  final String applicantName; // ผู้ขออนุญาต
  final String applicantDepartment; // แผนก / บริษัทผู้รับเหมา
  final String applicantPhone;
  final int workerCount; // จำนวนผู้ปฏิบัติงานทั้งหมด
  final List<String> workerNames; // รายชื่อผู้ปฏิบัติงาน

  // Safety Controls & Risk Assessment
  final String? jsaReferenceNo; // เลขที่เอกสาร JSA/Risk Assessment ที่เกี่ยวข้อง
  final String emergencyRescuePlan; // สรุปแผนฉุกเฉินและเบอร์ติดต่อกู้ภัย
  final String requiredPpeList; // รายการ PPE ที่ต้องสวมใส่
  final String specialPrecautions; // มาตรการควบคุมพิเศษเฉพาะหน้างาน

  // Digital Signatures (4 Parties + Closure)
  final String? applicantSignaturePath; // 1. ผู้ขออนุญาต
  final String? applicantSignedAt;
  final String? safetyOfficerSignaturePath; // 2. จป.วิชาชีพ ผู้ตรวจสอบ
  final String? safetyOfficerName;
  final String? safetyOfficerSignedAt;
  final String? authorizerSignaturePath; // 3. ผู้อนุญาตตามกฎหมาย
  final String? authorizerName;
  final String? authorizerSignedAt;
  final String? handoverSignaturePath; // 4. ผู้รับมอบงาน / ส่งต่อกะ
  final String? handoverSignedAt;
  final String? closureSignaturePath; // 5. ผู้ตรวจสอบปิดงาน
  final String? closureSignedAt;
  final String? closureRemarks;

  // Embedded Child Datasets (Populated or stored in relational tables)
  final List<GasTestLogModel> gasTestLogs;
  final List<ConfinedRoleModel> confinedRoles;
  final FireWatchModel? fireWatch;
  final List<LotoIsolationModel> lotoIsolations;
  final List<PtwChecklistModel> checklistItems;
  final List<PtwApprovalModel> approvalLogs;
  final List<String> sitePhotoPaths;

  final String? qrCodeData;
  final String? officialPdfPath;
  final String? createdAt;
  final String? updatedAt;

  const PtwModel({
    this.id,
    required this.ptwNumber,
    required this.workTitle,
    required this.workDescription,
    required this.primaryRiskType,
    this.secondaryRiskTypes = const [],
    this.status = PtwStatus.draft,
    required this.plantArea,
    required this.specificLocation,
    required this.requestDate,
    required this.workStartDate,
    required this.workStartTime,
    required this.workEndDate,
    required this.workEndTime,
    this.extensionHours = 0,
    this.extensionReason,
    this.applicantType = 'INTERNAL_EMPLOYEE',
    required this.applicantName,
    required this.applicantDepartment,
    required this.applicantPhone,
    this.workerCount = 1,
    this.workerNames = const [],
    this.jsaReferenceNo,
    required this.emergencyRescuePlan,
    required this.requiredPpeList,
    this.specialPrecautions = '',
    this.applicantSignaturePath,
    this.applicantSignedAt,
    this.safetyOfficerSignaturePath,
    this.safetyOfficerName,
    this.safetyOfficerSignedAt,
    this.authorizerSignaturePath,
    this.authorizerName,
    this.authorizerSignedAt,
    this.handoverSignaturePath,
    this.handoverSignedAt,
    this.closureSignaturePath,
    this.closureSignedAt,
    this.closureRemarks,
    this.gasTestLogs = const [],
    this.confinedRoles = const [],
    this.fireWatch,
    this.lotoIsolations = const [],
    this.checklistItems = const [],
    this.approvalLogs = const [],
    this.sitePhotoPaths = const [],
    this.qrCodeData,
    this.officialPdfPath,
    this.createdAt,
    this.updatedAt,
  });

  /// Check if permit involves Confined Space
  bool get isConfinedSpaceWork =>
      primaryRiskType == HighRiskType.confinedSpace ||
      secondaryRiskTypes.contains(HighRiskType.confinedSpace);

  /// Check if permit involves Hot Work
  bool get isHotWork =>
      primaryRiskType == HighRiskType.hotWork ||
      secondaryRiskTypes.contains(HighRiskType.hotWork);

  /// Check if permit involves Electrical / LOTO
  bool get isElectricalLotoWork =>
      primaryRiskType == HighRiskType.electricalLoto ||
      secondaryRiskTypes.contains(HighRiskType.electricalLoto);

  /// Check if permit involves Working at Height
  bool get isHeightWork =>
      primaryRiskType == HighRiskType.workingAtHeight ||
      secondaryRiskTypes.contains(HighRiskType.workingAtHeight);

  /// Check if permit involves Excavation / Lifting
  bool get isExcavationLiftingWork =>
      primaryRiskType == HighRiskType.excavationLifting ||
      secondaryRiskTypes.contains(HighRiskType.excavationLifting);

  /// Parsed DateTime for start of work
  DateTime? get startDateTime {
    try {
      final cleanDate = workStartDate.trim();
      final cleanTime = workStartTime.trim();
      return DateTime.parse('${cleanDate}T$cleanTime:00');
    } catch (_) {
      try {
        return DateTime.parse('$workStartDate $workStartTime:00');
      } catch (_) {
        return null;
      }
    }
  }

  /// Parsed DateTime for scheduled end of work
  DateTime? get endDateTime {
    try {
      final cleanDate = workEndDate.trim();
      final cleanTime = workEndTime.trim();
      return DateTime.parse('${cleanDate}T$cleanTime:00');
    } catch (_) {
      try {
        return DateTime.parse('$workEndDate $workEndTime:00');
      } catch (_) {
        return null;
      }
    }
  }

  /// Parsed DateTime for end of work including approved extension hours
  DateTime? get extendedEndDateTime {
    final baseEnd = endDateTime;
    if (baseEnd == null) return null;
    return baseEnd.add(Duration(hours: extensionHours));
  }

  /// True if permit has exceeded allowed work time window
  bool get isOverdue {
    if (status != PtwStatus.active && status != PtwStatus.extendedHandover) {
      return false;
    }
    final exp = extendedEndDateTime;
    if (exp == null) return false;
    return DateTime.now().isAfter(exp);
  }

  /// True if all mandatory checklist items have been verified compliant ('YES')
  bool get isChecklistComplete {
    if (checklistItems.isEmpty) return false;
    final mandatoryItems = checklistItems.where((c) => c.isMandatory).toList();
    if (mandatoryItems.isEmpty) return true;
    return mandatoryItems.every((c) => c.result == 'YES');
  }

  /// True if confined space 4 statutory roles are fully registered with valid certs
  bool get isConfinedSpaceCompliant {
    if (!isConfinedSpaceWork) return true;
    final hasAuth = confinedRoles.any((r) => r.roleType == ConfinedRoleType.authorizer && r.isCertificateValid);
    final hasSup = confinedRoles.any((r) => r.roleType == ConfinedRoleType.supervisor && r.isCertificateValid);
    final hasAtt = confinedRoles.any((r) => r.roleType == ConfinedRoleType.attendant && r.isCertificateValid);
    final hasEnt = confinedRoles.any((r) => r.roleType == ConfinedRoleType.entrant && r.isCertificateValid);
    return hasAuth && hasSup && hasAtt && hasEnt;
  }

  /// True if a valid and safe pre-entry gas test exists
  bool get isPreEntryGasTestSafe {
    if (!isConfinedSpaceWork) return true;
    final preEntryLogs = gasTestLogs.where((g) => g.testStage == 'PRE_ENTRY').toList();
    if (preEntryLogs.isEmpty) return false;
    return preEntryLogs.last.isSafe;
  }

  bool get hasValidGasTest => isPreEntryGasTestSafe;

  /// True if all LOTO isolation points have been verified zero-energy
  bool get isLotoVerified {
    if (!isElectricalLotoWork) return true;
    if (lotoIsolations.isEmpty) return false;
    return lotoIsolations.every((l) => l.isZeroEnergyVerified);
  }

  /// True if all LOTO isolation points have been de-isolated at closure
  bool get isLotoDeIsolated {
    if (!isElectricalLotoWork) return true;
    if (lotoIsolations.isEmpty) return true;
    return lotoIsolations.every((l) => l.isDeIsolated);
  }

  /// True if fire watch meets the statutory 30-minute rule
  bool get isFireWatchCompliant {
    if (!isHotWork) return true;
    if (fireWatch == null) return false;
    return fireWatch!.isCompliantWith30MinRule;
  }

  /// Formatted Thai time window string
  String get formattedTimeWindowTh {
    return '$workStartDate ($workStartTime น.) - $workEndDate ($workEndTime น.)';
  }

  Map<String, dynamic> toMap() {
    final secondaryCodes = secondaryRiskTypes.map((t) => t.toDbCode()).toList();
    return {
      if (id != null) 'id': id,
      'ptw_number': ptwNumber,
      'work_title': workTitle,
      'work_description': workDescription,
      'primary_risk_type': primaryRiskType.toDbCode(),
      'secondary_risk_types': jsonEncode(secondaryCodes),
      'status': status.toDbCode(),
      'plant_area': plantArea,
      'specific_location': specificLocation,
      'request_date': requestDate,
      'work_start_date': workStartDate,
      'work_start_time': workStartTime,
      'work_end_date': workEndDate,
      'work_end_time': workEndTime,
      'extension_hours': extensionHours,
      'extension_reason': extensionReason,
      'applicant_type': applicantType,
      'applicant_name': applicantName,
      'applicant_department': applicantDepartment,
      'applicant_phone': applicantPhone,
      'worker_count': workerCount,
      'worker_names': jsonEncode(workerNames),
      'jsa_reference_no': jsaReferenceNo,
      'emergency_rescue_plan': emergencyRescuePlan,
      'required_ppe_list': requiredPpeList,
      'special_precautions': specialPrecautions,
      'applicant_signature_path': applicantSignaturePath,
      'applicant_signed_at': applicantSignedAt,
      'safety_officer_signature_path': safetyOfficerSignaturePath,
      'safety_officer_name': safetyOfficerName,
      'safety_officer_signed_at': safetyOfficerSignedAt,
      'authorizer_signature_path': authorizerSignaturePath,
      'authorizer_name': authorizerName,
      'authorizer_signed_at': authorizerSignedAt,
      'handover_signature_path': handoverSignaturePath,
      'handover_signed_at': handoverSignedAt,
      'closure_signature_path': closureSignaturePath,
      'closure_signed_at': closureSignedAt,
      'closure_remarks': closureRemarks,
      'site_photo_paths': jsonEncode(sitePhotoPaths),
      'qr_code_data': qrCodeData,
      'official_pdf_path': officialPdfPath,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory PtwModel.fromMap(
    Map<String, dynamic> map, {
    List<GasTestLogModel> gasLogs = const [],
    List<ConfinedRoleModel> roles = const [],
    FireWatchModel? fireWatchData,
    List<LotoIsolationModel> lotoItems = const [],
    List<PtwChecklistModel> checklists = const [],
    List<PtwApprovalModel> approvals = const [],
  }) {
    List<HighRiskType> secondaryList = [];
    if (map['secondary_risk_types'] != null && map['secondary_risk_types'].toString().isNotEmpty) {
      try {
        final decoded = jsonDecode(map['secondary_risk_types'].toString());
        if (decoded is List) {
          secondaryList = decoded.map((e) => HighRiskType.fromDbCode(e.toString())).toList();
        }
      } catch (_) {}
    }

    List<String> workerList = [];
    if (map['worker_names'] != null && map['worker_names'].toString().isNotEmpty) {
      try {
        final decoded = jsonDecode(map['worker_names'].toString());
        if (decoded is List) {
          workerList = decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {}
    }

    List<String> photosList = [];
    if (map['site_photo_paths'] != null && map['site_photo_paths'].toString().isNotEmpty) {
      try {
        final decoded = jsonDecode(map['site_photo_paths'].toString());
        if (decoded is List) {
          photosList = decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {}
    }

    return PtwModel(
      id: map['id'] as int?,
      ptwNumber: map['ptw_number']?.toString() ?? '',
      workTitle: map['work_title']?.toString() ?? '',
      workDescription: map['work_description']?.toString() ?? '',
      primaryRiskType: HighRiskType.fromDbCode(map['primary_risk_type']?.toString()),
      secondaryRiskTypes: secondaryList,
      status: PtwStatus.fromDbCode(map['status']?.toString()),
      plantArea: map['plant_area']?.toString() ?? '',
      specificLocation: map['specific_location']?.toString() ?? '',
      requestDate: map['request_date']?.toString() ?? '',
      workStartDate: map['work_start_date']?.toString() ?? '',
      workStartTime: map['work_start_time']?.toString() ?? '',
      workEndDate: map['work_end_date']?.toString() ?? '',
      workEndTime: map['work_end_time']?.toString() ?? '',
      extensionHours: (map['extension_hours'] as num?)?.toInt() ?? 0,
      extensionReason: map['extension_reason']?.toString(),
      applicantType: map['applicant_type']?.toString() ?? 'INTERNAL_EMPLOYEE',
      applicantName: map['applicant_name']?.toString() ?? '',
      applicantDepartment: map['applicant_department']?.toString() ?? '',
      applicantPhone: map['applicant_phone']?.toString() ?? '',
      workerCount: (map['worker_count'] as num?)?.toInt() ?? 1,
      workerNames: workerList,
      jsaReferenceNo: map['jsa_reference_no']?.toString(),
      emergencyRescuePlan: map['emergency_rescue_plan']?.toString() ?? '',
      requiredPpeList: map['required_ppe_list']?.toString() ?? '',
      specialPrecautions: map['special_precautions']?.toString() ?? '',
      applicantSignaturePath: map['applicant_signature_path']?.toString(),
      applicantSignedAt: map['applicant_signed_at']?.toString(),
      safetyOfficerSignaturePath: map['safety_officer_signature_path']?.toString(),
      safetyOfficerName: map['safety_officer_name']?.toString(),
      safetyOfficerSignedAt: map['safety_officer_signed_at']?.toString(),
      authorizerSignaturePath: map['authorizer_signature_path']?.toString(),
      authorizerName: map['authorizer_name']?.toString(),
      authorizerSignedAt: map['authorizer_signed_at']?.toString(),
      handoverSignaturePath: map['handover_signature_path']?.toString(),
      handoverSignedAt: map['handover_signed_at']?.toString(),
      closureSignaturePath: map['closure_signature_path']?.toString(),
      closureSignedAt: map['closure_signed_at']?.toString(),
      closureRemarks: map['closure_remarks']?.toString(),
      gasTestLogs: gasLogs,
      confinedRoles: roles,
      fireWatch: fireWatchData,
      lotoIsolations: lotoItems,
      checklistItems: checklists,
      approvalLogs: approvals,
      sitePhotoPaths: photosList,
      qrCodeData: map['qr_code_data']?.toString(),
      officialPdfPath: map['official_pdf_path']?.toString(),
      createdAt: map['created_at']?.toString(),
      updatedAt: map['updated_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    final map = toMap();
    map['gas_test_logs'] = gasTestLogs.map((e) => e.toJson()).toList();
    map['confined_roles'] = confinedRoles.map((e) => e.toJson()).toList();
    if (fireWatch != null) map['fire_watch'] = fireWatch!.toJson();
    map['loto_isolations'] = lotoIsolations.map((e) => e.toJson()).toList();
    map['checklist_items'] = checklistItems.map((e) => e.toJson()).toList();
    map['approval_logs'] = approvalLogs.map((e) => e.toJson()).toList();
    return map;
  }

  factory PtwModel.fromJson(Map<String, dynamic> json) {
    List<GasTestLogModel> gasLogs = [];
    if (json['gas_test_logs'] is List) {
      gasLogs = (json['gas_test_logs'] as List)
          .map((e) => GasTestLogModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    List<ConfinedRoleModel> roles = [];
    if (json['confined_roles'] is List) {
      roles = (json['confined_roles'] as List)
          .map((e) => ConfinedRoleModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    FireWatchModel? fireWatchData;
    if (json['fire_watch'] is Map) {
      fireWatchData = FireWatchModel.fromJson(Map<String, dynamic>.from(json['fire_watch']));
    }

    List<LotoIsolationModel> lotoItems = [];
    if (json['loto_isolations'] is List) {
      lotoItems = (json['loto_isolations'] as List)
          .map((e) => LotoIsolationModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    List<PtwChecklistModel> checklists = [];
    if (json['checklist_items'] is List) {
      checklists = (json['checklist_items'] as List)
          .map((e) => PtwChecklistModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    List<PtwApprovalModel> approvals = [];
    if (json['approval_logs'] is List) {
      approvals = (json['approval_logs'] as List)
          .map((e) => PtwApprovalModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    return PtwModel.fromMap(
      json,
      gasLogs: gasLogs,
      roles: roles,
      fireWatchData: fireWatchData,
      lotoItems: lotoItems,
      checklists: checklists,
      approvals: approvals,
    );
  }

  PtwModel copyWith({
    int? id,
    String? ptwNumber,
    String? workTitle,
    String? workDescription,
    HighRiskType? primaryRiskType,
    List<HighRiskType>? secondaryRiskTypes,
    PtwStatus? status,
    String? plantArea,
    String? specificLocation,
    String? requestDate,
    String? workStartDate,
    String? workStartTime,
    String? workEndDate,
    String? workEndTime,
    int? extensionHours,
    String? extensionReason,
    String? applicantType,
    String? applicantName,
    String? applicantDepartment,
    String? applicantPhone,
    int? workerCount,
    List<String>? workerNames,
    String? jsaReferenceNo,
    String? emergencyRescuePlan,
    String? requiredPpeList,
    String? specialPrecautions,
    String? applicantSignaturePath,
    String? applicantSignedAt,
    String? safetyOfficerSignaturePath,
    String? safetyOfficerName,
    String? safetyOfficerSignedAt,
    String? authorizerSignaturePath,
    String? authorizerName,
    String? authorizerSignedAt,
    String? handoverSignaturePath,
    String? handoverSignedAt,
    String? closureSignaturePath,
    String? closureSignedAt,
    String? closureRemarks,
    List<GasTestLogModel>? gasTestLogs,
    List<ConfinedRoleModel>? confinedRoles,
    FireWatchModel? fireWatch,
    List<LotoIsolationModel>? lotoIsolations,
    List<PtwChecklistModel>? checklistItems,
    List<PtwApprovalModel>? approvalLogs,
    List<String>? sitePhotoPaths,
    String? qrCodeData,
    String? officialPdfPath,
    String? createdAt,
    String? updatedAt,
  }) {
    return PtwModel(
      id: id ?? this.id,
      ptwNumber: ptwNumber ?? this.ptwNumber,
      workTitle: workTitle ?? this.workTitle,
      workDescription: workDescription ?? this.workDescription,
      primaryRiskType: primaryRiskType ?? this.primaryRiskType,
      secondaryRiskTypes: secondaryRiskTypes ?? this.secondaryRiskTypes,
      status: status ?? this.status,
      plantArea: plantArea ?? this.plantArea,
      specificLocation: specificLocation ?? this.specificLocation,
      requestDate: requestDate ?? this.requestDate,
      workStartDate: workStartDate ?? this.workStartDate,
      workStartTime: workStartTime ?? this.workStartTime,
      workEndDate: workEndDate ?? this.workEndDate,
      workEndTime: workEndTime ?? this.workEndTime,
      extensionHours: extensionHours ?? this.extensionHours,
      extensionReason: extensionReason ?? this.extensionReason,
      applicantType: applicantType ?? this.applicantType,
      applicantName: applicantName ?? this.applicantName,
      applicantDepartment: applicantDepartment ?? this.applicantDepartment,
      applicantPhone: applicantPhone ?? this.applicantPhone,
      workerCount: workerCount ?? this.workerCount,
      workerNames: workerNames ?? this.workerNames,
      jsaReferenceNo: jsaReferenceNo ?? this.jsaReferenceNo,
      emergencyRescuePlan: emergencyRescuePlan ?? this.emergencyRescuePlan,
      requiredPpeList: requiredPpeList ?? this.requiredPpeList,
      specialPrecautions: specialPrecautions ?? this.specialPrecautions,
      applicantSignaturePath: applicantSignaturePath ?? this.applicantSignaturePath,
      applicantSignedAt: applicantSignedAt ?? this.applicantSignedAt,
      safetyOfficerSignaturePath: safetyOfficerSignaturePath ?? this.safetyOfficerSignaturePath,
      safetyOfficerName: safetyOfficerName ?? this.safetyOfficerName,
      safetyOfficerSignedAt: safetyOfficerSignedAt ?? this.safetyOfficerSignedAt,
      authorizerSignaturePath: authorizerSignaturePath ?? this.authorizerSignaturePath,
      authorizerName: authorizerName ?? this.authorizerName,
      authorizerSignedAt: authorizerSignedAt ?? this.authorizerSignedAt,
      handoverSignaturePath: handoverSignaturePath ?? this.handoverSignaturePath,
      handoverSignedAt: handoverSignedAt ?? this.handoverSignedAt,
      closureSignaturePath: closureSignaturePath ?? this.closureSignaturePath,
      closureSignedAt: closureSignedAt ?? this.closureSignedAt,
      closureRemarks: closureRemarks ?? this.closureRemarks,
      gasTestLogs: gasTestLogs ?? this.gasTestLogs,
      confinedRoles: confinedRoles ?? this.confinedRoles,
      fireWatch: fireWatch ?? this.fireWatch,
      lotoIsolations: lotoIsolations ?? this.lotoIsolations,
      checklistItems: checklistItems ?? this.checklistItems,
      approvalLogs: approvalLogs ?? this.approvalLogs,
      sitePhotoPaths: sitePhotoPaths ?? this.sitePhotoPaths,
      qrCodeData: qrCodeData ?? this.qrCodeData,
      officialPdfPath: officialPdfPath ?? this.officialPdfPath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() => 'PtwModel(ptwNumber: $ptwNumber, title: $workTitle, risk: ${primaryRiskType.toDbCode()}, status: ${status.toDbCode()})';
}
