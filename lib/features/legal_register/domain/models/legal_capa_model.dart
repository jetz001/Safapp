import 'package:flutter/material.dart';

/// Lifecycle status for Corrective and Preventive Action (CAPA) items.
enum LegalCapaStatus {
  pending('PENDING', 'รอดำเนินการ (Pending)', Color(0xFF6B7280), Color(0xFFF3F4F6), Icons.hourglass_empty_rounded),
  inProgress('IN_PROGRESS', 'กำลังดำเนินการ (In-Progress)', Color(0xFF3B82F6), Color(0xFFEFF6FF), Icons.directions_run_rounded),
  completed('COMPLETED', 'เสร็จสิ้นแล้ว (Completed)', Color(0xFF10B981), Color(0xFFECFDF5), Icons.task_alt_rounded),
  overdue('OVERDUE', 'เกินกำหนด (Overdue)', Color(0xFFDC2626), Color(0xFFFEF2F2), Icons.warning_amber_rounded);

  final String code;
  final String labelTh;
  final Color color;
  final Color bgColor;
  final IconData icon;

  const LegalCapaStatus(this.code, this.labelTh, this.color, this.bgColor, this.icon);

  static LegalCapaStatus fromCode(String code) {
    return LegalCapaStatus.values.firstWhere(
      (e) => e.code.toUpperCase() == code.toUpperCase(),
      orElse: () => LegalCapaStatus.pending,
    );
  }
}

/// CAPA Action Plan entity addressing non-compliance or in-progress legal items.
class LegalCapaModel {
  final int? id;
  final int assessmentId; // Foreign key to safety_legal_assessments(id)
  final String actionTitle;
  final String rootCause; // 5-Whys / Root cause analysis
  final String correctiveAction; // Action to fix current issue
  final String? preventiveAction; // Action to prevent recurrence
  final String picName; // Person In Charge
  final String? picDepartment;
  final String targetDate; // YYYY-MM-DD
  final String? completedDate; // YYYY-MM-DD
  final String status; // 'PENDING', 'IN_PROGRESS', 'COMPLETED', 'OVERDUE'
  final String? evidenceFilePath;
  final String? supervisorAcknowledgedDate;
  final String? notes;
  final String? createdAt;
  final String? updatedAt;

  // Optional display fields populated from joined assessment
  final String? requirementCode;
  final String? requirementTitle;
  final String? category;
  final String? lawTitle;

  const LegalCapaModel({
    this.id,
    required this.assessmentId,
    required this.actionTitle,
    required this.rootCause,
    required this.correctiveAction,
    this.preventiveAction,
    required this.picName,
    this.picDepartment,
    required this.targetDate,
    this.completedDate,
    this.status = 'PENDING',
    this.evidenceFilePath,
    this.supervisorAcknowledgedDate,
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.requirementCode,
    this.requirementTitle,
    this.category,
    this.lawTitle,
  });

  DateTime? get parsedTargetDate => DateTime.tryParse(targetDate);
  DateTime? get parsedCompletedDate => completedDate != null ? DateTime.tryParse(completedDate!) : null;

  bool get isCompleted => status.toUpperCase() == 'COMPLETED';

  bool get isOverdue {
    if (isCompleted) return false;
    final target = parsedTargetDate;
    if (target == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetNorm = DateTime(target.year, target.month, target.day);
    return targetNorm.isBefore(today);
  }

  int get daysRemaining {
    final target = parsedTargetDate;
    if (target == null) return 0;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetNorm = DateTime(target.year, target.month, target.day);
    return targetNorm.difference(today).inDays;
  }

  LegalCapaStatus get effectiveStatusEnum {
    if (isCompleted) return LegalCapaStatus.completed;
    if (isOverdue) return LegalCapaStatus.overdue;
    return LegalCapaStatus.fromCode(status);
  }

  String get effectiveStatusCode => effectiveStatusEnum.code;
  String get statusLabelTh => effectiveStatusEnum.labelTh;
  Color get statusColor => effectiveStatusEnum.color;
  Color get statusBgColor => effectiveStatusEnum.bgColor;
  IconData get statusIcon => effectiveStatusEnum.icon;

  LegalCapaModel copyWith({
    int? id,
    int? assessmentId,
    String? actionTitle,
    String? rootCause,
    String? correctiveAction,
    String? preventiveAction,
    String? picName,
    String? picDepartment,
    String? targetDate,
    String? completedDate,
    String? status,
    String? evidenceFilePath,
    String? supervisorAcknowledgedDate,
    String? notes,
    String? createdAt,
    String? updatedAt,
    String? requirementCode,
    String? requirementTitle,
    String? category,
    String? lawTitle,
  }) {
    return LegalCapaModel(
      id: id ?? this.id,
      assessmentId: assessmentId ?? this.assessmentId,
      actionTitle: actionTitle ?? this.actionTitle,
      rootCause: rootCause ?? this.rootCause,
      correctiveAction: correctiveAction ?? this.correctiveAction,
      preventiveAction: preventiveAction ?? this.preventiveAction,
      picName: picName ?? this.picName,
      picDepartment: picDepartment ?? this.picDepartment,
      targetDate: targetDate ?? this.targetDate,
      completedDate: completedDate ?? this.completedDate,
      status: status ?? this.status,
      evidenceFilePath: evidenceFilePath ?? this.evidenceFilePath,
      supervisorAcknowledgedDate: supervisorAcknowledgedDate ?? this.supervisorAcknowledgedDate,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      requirementCode: requirementCode ?? this.requirementCode,
      requirementTitle: requirementTitle ?? this.requirementTitle,
      category: category ?? this.category,
      lawTitle: lawTitle ?? this.lawTitle,
    );
  }

  /// SQLite database mapping
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'assessment_id': assessmentId,
      'action_title': actionTitle,
      'root_cause': rootCause,
      'corrective_action': correctiveAction,
      'preventive_action': preventiveAction,
      'pic_name': picName,
      'pic_department': picDepartment,
      'target_date': targetDate,
      'completed_date': completedDate,
      'status': status,
      'evidence_file_path': evidenceFilePath,
      'supervisor_acknowledged_date': supervisorAcknowledgedDate,
      'notes': notes,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory LegalCapaModel.fromMap(Map<String, dynamic> map) {
    return LegalCapaModel(
      id: map['id'] != null ? int.tryParse(map['id'].toString()) : null,
      assessmentId: int.tryParse((map['assessment_id'] ?? map['assessmentId'] ?? '0').toString()) ?? 0,
      actionTitle: (map['action_title'] ?? map['actionTitle'] ?? '').toString(),
      rootCause: (map['root_cause'] ?? map['rootCause'] ?? '').toString(),
      correctiveAction: (map['corrective_action'] ?? map['correctiveAction'] ?? '').toString(),
      preventiveAction: map['preventive_action']?.toString() ?? map['preventiveAction']?.toString(),
      picName: (map['pic_name'] ?? map['picName'] ?? '').toString(),
      picDepartment: map['pic_department']?.toString() ?? map['picDepartment']?.toString(),
      targetDate: (map['target_date'] ?? map['targetDate'] ?? '').toString(),
      completedDate: map['completed_date']?.toString() ?? map['completedDate']?.toString(),
      status: (map['status'] ?? 'PENDING').toString(),
      evidenceFilePath: map['evidence_file_path']?.toString() ?? map['evidenceFilePath']?.toString(),
      supervisorAcknowledgedDate: map['supervisor_acknowledged_date']?.toString() ?? map['supervisorAcknowledgedDate']?.toString(),
      notes: map['notes']?.toString(),
      createdAt: map['created_at']?.toString() ?? map['createdAt']?.toString(),
      updatedAt: map['updated_at']?.toString() ?? map['updatedAt']?.toString(),
      requirementCode: map['requirement_code']?.toString() ?? map['requirementCode']?.toString(),
      requirementTitle: map['requirement_title']?.toString() ?? map['requirementTitle']?.toString(),
      category: map['category']?.toString(),
      lawTitle: map['law_title']?.toString() ?? map['law_title_th']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => toMap();
  factory LegalCapaModel.fromJson(Map<String, dynamic> json) => LegalCapaModel.fromMap(json);
}
