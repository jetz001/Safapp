import 'dart:convert';
import 'environment_standard_model.dart';

/// Status of an environmental CAPA action item.
enum EnvironmentCapaStatus {
  pending,
  inProgress,
  completed,
  overdue;

  String toDbCode() {
    switch (this) {
      case EnvironmentCapaStatus.pending:
        return 'PENDING';
      case EnvironmentCapaStatus.inProgress:
        return 'IN_PROGRESS';
      case EnvironmentCapaStatus.completed:
        return 'COMPLETED';
      case EnvironmentCapaStatus.overdue:
        return 'OVERDUE';
    }
  }

  static EnvironmentCapaStatus fromDbCode(String? code) {
    switch (code?.toUpperCase()) {
      case 'PENDING':
        return EnvironmentCapaStatus.pending;
      case 'IN_PROGRESS':
      case 'INPROGRESS':
        return EnvironmentCapaStatus.inProgress;
      case 'COMPLETED':
      case 'DONE':
        return EnvironmentCapaStatus.completed;
      case 'OVERDUE':
        return EnvironmentCapaStatus.overdue;
      default:
        return EnvironmentCapaStatus.pending;
    }
  }

  String get labelTh {
    switch (this) {
      case EnvironmentCapaStatus.pending:
        return 'รอดำเนินการ';
      case EnvironmentCapaStatus.inProgress:
        return 'กำลังดำเนินการ';
      case EnvironmentCapaStatus.completed:
        return 'เสร็จสิ้นแล้ว';
      case EnvironmentCapaStatus.overdue:
        return 'เกินกำหนด (Overdue)';
    }
  }
}

/// Model representing a Corrective & Preventive Action Plan (CAPA) or Hearing Conservation Program enrollment.
class EnvironmentCapaModel {
  final int? id;
  final String capaId; // e.g. 'CAPA-ENV-2026-001'
  final String? pointId; // FK to EnvironmentPointModel.pointId
  final String sessionId; // FK to EnvironmentSessionModel.sessionId
  final EnvironmentFactorType factorType;
  final String actionTitle;
  final String hazardDescription;
  final String rootCause;
  final String? engineeringControl;
  final String? administrativeControl;
  final String? ppeControl;
  final String picName; // Person in charge
  final String? picDepartment;
  final String targetDate; // YYYY-MM-DD
  final String? completedDate; // YYYY-MM-DD
  final String status; // 'PENDING', 'IN_PROGRESS', 'COMPLETED', 'OVERDUE'
  final bool hearingProgramEnrolled;
  final String? evidenceFilePath;
  final String? supervisorAcknowledgedDate;
  final String? notes;
  final String? createdAt;
  final String? updatedAt;

  const EnvironmentCapaModel({
    this.id,
    required this.capaId,
    this.pointId,
    required this.sessionId,
    required this.factorType,
    required this.actionTitle,
    required this.hazardDescription,
    required this.rootCause,
    this.engineeringControl,
    this.administrativeControl,
    this.ppeControl,
    required this.picName,
    this.picDepartment,
    required this.targetDate,
    this.completedDate,
    this.status = 'PENDING',
    this.hearingProgramEnrolled = false,
    this.evidenceFilePath,
    this.supervisorAcknowledgedDate,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  bool get isCompleted =>
      status.toUpperCase() == 'COMPLETED' || (completedDate != null && completedDate!.isNotEmpty);

  bool get isOverdue {
    if (isCompleted) return false;
    try {
      final target = DateTime.parse(targetDate);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      return target.isBefore(today);
    } catch (_) {
      return false;
    }
  }

  EnvironmentCapaStatus get effectiveStatusEnum {
    if (isCompleted) return EnvironmentCapaStatus.completed;
    if (isOverdue) return EnvironmentCapaStatus.overdue;
    return EnvironmentCapaStatus.fromDbCode(status);
  }

  int get daysRemaining {
    try {
      final target = DateTime.parse(targetDate);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      return target.difference(today).inDays;
    } catch (_) {
      return 0;
    }
  }

  String get statusLabelTh => effectiveStatusEnum.labelTh;

  EnvironmentCapaModel copyWith({
    int? id,
    String? capaId,
    String? pointId,
    String? sessionId,
    EnvironmentFactorType? factorType,
    String? actionTitle,
    String? hazardDescription,
    String? rootCause,
    String? engineeringControl,
    String? administrativeControl,
    String? ppeControl,
    String? picName,
    String? picDepartment,
    String? targetDate,
    String? completedDate,
    String? status,
    bool? hearingProgramEnrolled,
    String? evidenceFilePath,
    String? supervisorAcknowledgedDate,
    String? notes,
    String? createdAt,
    String? updatedAt,
  }) {
    return EnvironmentCapaModel(
      id: id ?? this.id,
      capaId: capaId ?? this.capaId,
      pointId: pointId ?? this.pointId,
      sessionId: sessionId ?? this.sessionId,
      factorType: factorType ?? this.factorType,
      actionTitle: actionTitle ?? this.actionTitle,
      hazardDescription: hazardDescription ?? this.hazardDescription,
      rootCause: rootCause ?? this.rootCause,
      engineeringControl: engineeringControl ?? this.engineeringControl,
      administrativeControl: administrativeControl ?? this.administrativeControl,
      ppeControl: ppeControl ?? this.ppeControl,
      picName: picName ?? this.picName,
      picDepartment: picDepartment ?? this.picDepartment,
      targetDate: targetDate ?? this.targetDate,
      completedDate: completedDate ?? this.completedDate,
      status: status ?? this.status,
      hearingProgramEnrolled: hearingProgramEnrolled ?? this.hearingProgramEnrolled,
      evidenceFilePath: evidenceFilePath ?? this.evidenceFilePath,
      supervisorAcknowledgedDate: supervisorAcknowledgedDate ?? this.supervisorAcknowledgedDate,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'capa_id': capaId,
      'point_id': pointId,
      'session_id': sessionId,
      'factor_type': factorType.toDbCode(),
      'action_title': actionTitle,
      'hazard_description': hazardDescription,
      'root_cause': rootCause,
      'engineering_control': engineeringControl,
      'administrative_control': administrativeControl,
      'ppe_control': ppeControl,
      'pic_name': picName,
      'pic_department': picDepartment,
      'target_date': targetDate,
      'completed_date': completedDate,
      'status': isOverdue ? 'OVERDUE' : status,
      'hearing_program_enrolled': hearingProgramEnrolled ? 1 : 0,
      'evidence_file_path': evidenceFilePath,
      'supervisor_acknowledged_date': supervisorAcknowledgedDate,
      'notes': notes,
      'created_at': createdAt ?? DateTime.now().toIso8601String(),
      'updated_at': updatedAt ?? DateTime.now().toIso8601String(),
    };
  }

  factory EnvironmentCapaModel.fromMap(Map<String, dynamic> map) {
    return EnvironmentCapaModel(
      id: map['id'] as int?,
      capaId: map['capa_id'] as String? ?? map['capaId'] as String? ?? '',
      pointId: map['point_id'] as String? ?? map['pointId'] as String?,
      sessionId: map['session_id'] as String? ?? map['sessionId'] as String? ?? '',
      factorType: EnvironmentFactorType.fromDbCode(
        map['factor_type'] as String? ?? map['factorType'] as String? ?? 'LIGHT',
      ),
      actionTitle: map['action_title'] as String? ?? map['actionTitle'] as String? ?? '',
      hazardDescription: map['hazard_description'] as String? ?? map['hazardDescription'] as String? ?? '',
      rootCause: map['root_cause'] as String? ?? map['rootCause'] as String? ?? '',
      engineeringControl: map['engineering_control'] as String? ?? map['engineeringControl'] as String?,
      administrativeControl: map['administrative_control'] as String? ?? map['administrativeControl'] as String?,
      ppeControl: map['ppe_control'] as String? ?? map['ppeControl'] as String?,
      picName: map['pic_name'] as String? ?? map['picName'] as String? ?? '',
      picDepartment: map['pic_department'] as String? ?? map['picDepartment'] as String?,
      targetDate: map['target_date'] as String? ?? map['targetDate'] as String? ?? '',
      completedDate: map['completed_date'] as String? ?? map['completedDate'] as String?,
      status: map['status'] as String? ?? 'PENDING',
      hearingProgramEnrolled: map['hearing_program_enrolled'] == 1 ||
          map['hearing_program_enrolled'] == true ||
          map['hearingProgramEnrolled'] == true,
      evidenceFilePath: map['evidence_file_path'] as String? ?? map['evidenceFilePath'] as String?,
      supervisorAcknowledgedDate: map['supervisor_acknowledged_date'] as String? ??
          map['supervisorAcknowledgedDate'] as String?,
      notes: map['notes'] as String?,
      createdAt: map['created_at'] as String? ?? map['createdAt'] as String?,
      updatedAt: map['updated_at'] as String? ?? map['updatedAt'] as String?,
    );
  }

  String toJson() => json.encode(toMap());

  factory EnvironmentCapaModel.fromJson(String source) =>
      EnvironmentCapaModel.fromMap(json.decode(source) as Map<String, dynamic>);
}
