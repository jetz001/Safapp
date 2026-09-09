import '../../domain/enums/hazard_type.dart';
import '../../domain/enums/emergency_enums.dart';

/// โมเดลบันทึกการฝึกซ้อมและรายงาน สปร. ๔ (ตามกฎกระทรวงอัคคีภัย ๒๕๕๕ ข้อ ๓๐)
class DrillSessionModel {
  final int? id;
  final int? planId;
  final HazardType hazardType;
  final String drillTitle;
  final String drillDate; // YYYY-MM-DD
  final String startTime;
  final String endTime;
  final int drillYear; // เช่น 2568 หรือ 2025
  final DrillOrganizerType organizerType;
  final String organizerName;
  final String approvalCertNo;
  final String approvalDate;
  final String scenarioDescription;
  final String incidentLocation;
  final String fireOrHazardSource;
  final int totalWorkersOnSite;
  final int participatedCount;
  final int maleParticipants;
  final int femaleParticipants;
  final double participationRatePercent;
  final int initialAttackTimeSec;
  final int evacuationTimeSec;
  final HeadcountStatus headcountStatus;
  final int simulatedInjuriesCount;
  final String problemsAndObstacles;
  final String improvementActions;
  final String evaluationSummary;
  final String evaluatorName;
  final String evaluatorPosition;
  final Spr4SubmissionStatus spr4SubmissionStatus;
  final String submissionDeadline; // ภายใน 30 วันนับแต่วันซ้อมเสร็จ
  final String? submittedDate;
  final String? officerReceiptNo;
  final String? vendorReportPath;
  final List<DrillAttachmentModel> attachments;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const DrillSessionModel({
    this.id,
    this.planId,
    this.hazardType = HazardType.fire,
    required this.drillTitle,
    required this.drillDate,
    this.startTime = '09:00',
    this.endTime = '12:00',
    required this.drillYear,
    this.organizerType = DrillOrganizerType.selfApproved,
    this.organizerName = '',
    this.approvalCertNo = '',
    this.approvalDate = '',
    this.scenarioDescription = '',
    this.incidentLocation = '',
    this.fireOrHazardSource = '',
    this.totalWorkersOnSite = 0,
    this.participatedCount = 0,
    this.maleParticipants = 0,
    this.femaleParticipants = 0,
    this.participationRatePercent = 0.0,
    this.initialAttackTimeSec = 0,
    this.evacuationTimeSec = 0,
    this.headcountStatus = HeadcountStatus.allAccounted,
    this.simulatedInjuriesCount = 0,
    this.problemsAndObstacles = '',
    this.improvementActions = '',
    this.evaluationSummary = '',
    this.evaluatorName = '',
    this.evaluatorPosition = '',
    this.spr4SubmissionStatus = Spr4SubmissionStatus.pending,
    required this.submissionDeadline,
    this.submittedDate,
    this.officerReceiptNo,
    this.vendorReportPath,
    this.attachments = const [],
    this.createdAt,
    this.updatedAt,
  });

  /// คำนวณวันสิ้นสุดกำหนดส่งรายงาน สปร. ๔ (๓๐ วันนับจากวันซ้อม)
  static String calculateDeadline(String drillDateStr) {
    try {
      final date = DateTime.parse(drillDateStr);
      final deadline = date.add(const Duration(days: 30));
      return "${deadline.year.toString().padLeft(4, '0')}-${deadline.month.toString().padLeft(2, '0')}-${deadline.day.toString().padLeft(2, '0')}";
    } catch (_) {
      return drillDateStr;
    }
  }

  DrillSessionModel copyWith({
    int? id,
    int? planId,
    HazardType? hazardType,
    String? drillTitle,
    String? drillDate,
    String? startTime,
    String? endTime,
    int? drillYear,
    DrillOrganizerType? organizerType,
    String? organizerName,
    String? approvalCertNo,
    String? approvalDate,
    String? scenarioDescription,
    String? incidentLocation,
    String? fireOrHazardSource,
    int? totalWorkersOnSite,
    int? participatedCount,
    int? maleParticipants,
    int? femaleParticipants,
    double? participationRatePercent,
    int? initialAttackTimeSec,
    int? evacuationTimeSec,
    HeadcountStatus? headcountStatus,
    int? simulatedInjuriesCount,
    String? problemsAndObstacles,
    String? improvementActions,
    String? evaluationSummary,
    String? evaluatorName,
    String? evaluatorPosition,
    Spr4SubmissionStatus? spr4SubmissionStatus,
    String? submissionDeadline,
    String? submittedDate,
    String? officerReceiptNo,
    String? vendorReportPath,
    List<DrillAttachmentModel>? attachments,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DrillSessionModel(
      id: id ?? this.id,
      planId: planId ?? this.planId,
      hazardType: hazardType ?? this.hazardType,
      drillTitle: drillTitle ?? this.drillTitle,
      drillDate: drillDate ?? this.drillDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      drillYear: drillYear ?? this.drillYear,
      organizerType: organizerType ?? this.organizerType,
      organizerName: organizerName ?? this.organizerName,
      approvalCertNo: approvalCertNo ?? this.approvalCertNo,
      approvalDate: approvalDate ?? this.approvalDate,
      scenarioDescription: scenarioDescription ?? this.scenarioDescription,
      incidentLocation: incidentLocation ?? this.incidentLocation,
      fireOrHazardSource: fireOrHazardSource ?? this.fireOrHazardSource,
      totalWorkersOnSite: totalWorkersOnSite ?? this.totalWorkersOnSite,
      participatedCount: participatedCount ?? this.participatedCount,
      maleParticipants: maleParticipants ?? this.maleParticipants,
      femaleParticipants: femaleParticipants ?? this.femaleParticipants,
      participationRatePercent: participationRatePercent ?? this.participationRatePercent,
      initialAttackTimeSec: initialAttackTimeSec ?? this.initialAttackTimeSec,
      evacuationTimeSec: evacuationTimeSec ?? this.evacuationTimeSec,
      headcountStatus: headcountStatus ?? this.headcountStatus,
      simulatedInjuriesCount: simulatedInjuriesCount ?? this.simulatedInjuriesCount,
      problemsAndObstacles: problemsAndObstacles ?? this.problemsAndObstacles,
      improvementActions: improvementActions ?? this.improvementActions,
      evaluationSummary: evaluationSummary ?? this.evaluationSummary,
      evaluatorName: evaluatorName ?? this.evaluatorName,
      evaluatorPosition: evaluatorPosition ?? this.evaluatorPosition,
      spr4SubmissionStatus: spr4SubmissionStatus ?? this.spr4SubmissionStatus,
      submissionDeadline: submissionDeadline ?? this.submissionDeadline,
      submittedDate: submittedDate ?? this.submittedDate,
      officerReceiptNo: officerReceiptNo ?? this.officerReceiptNo,
      vendorReportPath: vendorReportPath ?? this.vendorReportPath,
      attachments: attachments ?? this.attachments,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'plan_id': planId,
      'hazard_type': hazardType.code,
      'drill_title': drillTitle,
      'drill_date': drillDate,
      'start_time': startTime,
      'end_time': endTime,
      'drill_year': drillYear,
      'organizer_type': organizerType.code,
      'organizer_name': organizerName,
      'approval_cert_no': approvalCertNo,
      'approval_date': approvalDate,
      'scenario_description': scenarioDescription,
      'incident_location': incidentLocation,
      'fire_or_hazard_source': fireOrHazardSource,
      'total_workers_on_site': totalWorkersOnSite,
      'participated_count': participatedCount,
      'male_participants': maleParticipants,
      'female_participants': femaleParticipants,
      'participation_rate_percent': participationRatePercent,
      'initial_attack_time_sec': initialAttackTimeSec,
      'evacuation_time_sec': evacuationTimeSec,
      'headcount_status': headcountStatus.code,
      'simulated_injuries_count': simulatedInjuriesCount,
      'problems_and_obstacles': problemsAndObstacles,
      'improvement_actions': improvementActions,
      'evaluation_summary': evaluationSummary,
      'evaluator_name': evaluatorName,
      'evaluator_position': evaluatorPosition,
      'spr4_submission_status': spr4SubmissionStatus.code,
      'submission_deadline': submissionDeadline,
      'submitted_date': submittedDate,
      'officer_receipt_no': officerReceiptNo,
      'vendor_report_path': vendorReportPath,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory DrillSessionModel.fromMap(Map<String, dynamic> map, {List<DrillAttachmentModel> attachments = const []}) {
    return DrillSessionModel(
      id: map['id'] as int?,
      planId: map['plan_id'] as int?,
      hazardType: HazardType.fromCode(map['hazard_type'] as String?),
      drillTitle: map['drill_title'] as String? ?? 'การฝึกซ้อมอพยพประจำปี',
      drillDate: map['drill_date'] as String? ?? '',
      startTime: map['start_time'] as String? ?? '09:00',
      endTime: map['end_time'] as String? ?? '12:00',
      drillYear: map['drill_year'] as int? ?? DateTime.now().year,
      organizerType: DrillOrganizerType.fromCode(map['organizer_type'] as String?),
      organizerName: map['organizer_name'] as String? ?? '',
      approvalCertNo: map['approval_cert_no'] as String? ?? '',
      approvalDate: map['approval_date'] as String? ?? '',
      scenarioDescription: map['scenario_description'] as String? ?? '',
      incidentLocation: map['incident_location'] as String? ?? '',
      fireOrHazardSource: map['fire_or_hazard_source'] as String? ?? '',
      totalWorkersOnSite: map['total_workers_on_site'] as int? ?? 0,
      participatedCount: map['participated_count'] as int? ?? 0,
      maleParticipants: map['male_participants'] as int? ?? 0,
      femaleParticipants: map['female_participants'] as int? ?? 0,
      participationRatePercent: (map['participation_rate_percent'] as num?)?.toDouble() ?? 0.0,
      initialAttackTimeSec: map['initial_attack_time_sec'] as int? ?? 0,
      evacuationTimeSec: map['evacuation_time_sec'] as int? ?? 0,
      headcountStatus: HeadcountStatus.fromCode(map['headcount_status'] as String?),
      simulatedInjuriesCount: map['simulated_injuries_count'] as int? ?? 0,
      problemsAndObstacles: map['problems_and_obstacles'] as String? ?? '',
      improvementActions: map['improvement_actions'] as String? ?? '',
      evaluationSummary: map['evaluation_summary'] as String? ?? '',
      evaluatorName: map['evaluator_name'] as String? ?? '',
      evaluatorPosition: map['evaluator_position'] as String? ?? '',
      spr4SubmissionStatus: Spr4SubmissionStatus.fromCode(map['spr4_submission_status'] as String?),
      submissionDeadline: map['submission_deadline'] as String? ?? '',
      submittedDate: map['submitted_date'] as String?,
      officerReceiptNo: map['officer_receipt_no'] as String?,
      vendorReportPath: map['vendor_report_path'] as String?,
      attachments: attachments,
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at']) : null,
      updatedAt: map['updated_at'] != null ? DateTime.tryParse(map['updated_at']) : null,
    );
  }
}

/// โมเดลรูปถ่ายหรือหลักฐานแนบการฝึกซ้อม
class DrillAttachmentModel {
  final int? id;
  final int drillId;
  final String imagePath;
  final String? caption;
  final DrillAttachmentCategory category;
  final DateTime? createdAt;

  const DrillAttachmentModel({
    this.id,
    required this.drillId,
    required this.imagePath,
    this.caption,
    this.category = DrillAttachmentCategory.during,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'drill_id': drillId,
      'image_path': imagePath,
      'caption': caption,
      'category': category.code,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  factory DrillAttachmentModel.fromMap(Map<String, dynamic> map) {
    return DrillAttachmentModel(
      id: map['id'] as int?,
      drillId: map['drill_id'] as int? ?? 0,
      imagePath: map['image_path'] as String? ?? '',
      caption: map['caption'] as String?,
      category: DrillAttachmentCategory.fromCode(map['category'] as String?),
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at']) : null,
    );
  }
}
