import 'dart:convert';
import 'package:flutter/material.dart';
import 'legal_master_item_model.dart';

/// Compliance evaluation status for facility legal register assessment.
enum LegalComplianceStatus {
  compliant('COMPLIANT', 'สอดคล้อง (Compliant)', Color(0xFF10B981), Color(0xFFECFDF5), Icons.check_circle_rounded),
  nonCompliant('NON_COMPLIANT', 'ไม่สอดคล้อง (Non-Compliant)', Color(0xFFEF4444), Color(0xFFFEF2F2), Icons.cancel_rounded),
  inProgress('IN_PROGRESS', 'อยู่ระหว่างดำเนินการ (In-Progress)', Color(0xFFF59E0B), Color(0xFFFFFBEB), Icons.pending_actions_rounded),
  notApplicable('NOT_APPLICABLE', 'ไม่เกี่ยวข้อง (Not Applicable)', Color(0xFF6B7280), Color(0xFFF3F4F6), Icons.do_not_disturb_on_rounded);

  final String code;
  final String labelTh;
  final Color color;
  final Color bgColor;
  final IconData icon;

  const LegalComplianceStatus(this.code, this.labelTh, this.color, this.bgColor, this.icon);

  static LegalComplianceStatus fromCode(String code) {
    return LegalComplianceStatus.values.firstWhere(
      (e) => e.code.toUpperCase() == code.toUpperCase(),
      orElse: () => LegalComplianceStatus.notApplicable,
    );
  }
}

/// Facility-specific Compliance Assessment Record for a statutory legal requirement.
class LegalComplianceAssessmentModel {
  final int? id;
  final String masterItemId; // e.g. 'ITEM-OSH-001'
  final String requirementCode; // e.g. 'ITEM-OSH-001'
  final String requirementTitle;
  final String requirementDetails;
  final String category; // 'OSH_ACT', 'SAFETY_OFFICER', etc.
  final String lawId; // 'LAW-OSH-2554'
  final String lawTitleTh;
  final String articleNo;
  final bool isApplicable;
  final String complianceStatus; // 'COMPLIANT', 'NON_COMPLIANT', 'IN_PROGRESS', 'NOT_APPLICABLE'
  final String? actualPractice;
  final String evaluatedDate; // YYYY-MM-DD
  final String? nextReviewDate; // YYYY-MM-DD
  final String evaluatorName;
  final String? evaluatorRole;
  final String? department;
  final List<String> evidenceFilePaths;
  final String riskLevel; // 'HIGH', 'MEDIUM', 'LOW'
  final String? penaltySummary;
  final String? notes;
  final String? createdAt;
  final String? updatedAt;

  const LegalComplianceAssessmentModel({
    this.id,
    required this.masterItemId,
    required this.requirementCode,
    required this.requirementTitle,
    required this.requirementDetails,
    required this.category,
    required this.lawId,
    required this.lawTitleTh,
    required this.articleNo,
    this.isApplicable = true,
    this.complianceStatus = 'NOT_APPLICABLE',
    this.actualPractice,
    required this.evaluatedDate,
    this.nextReviewDate,
    required this.evaluatorName,
    this.evaluatorRole,
    this.department,
    this.evidenceFilePaths = const [],
    this.riskLevel = 'MEDIUM',
    this.penaltySummary,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  LegalComplianceStatus get statusEnum => LegalComplianceStatus.fromCode(complianceStatus);
  LegalRiskLevel get riskLevelEnum => LegalRiskLevel.fromCode(riskLevel);
  LegalCategoryEnum get categoryEnum => LegalCategoryEnum.fromCode(category);

  String get statusLabelTh => statusEnum.labelTh;
  Color get statusColor => statusEnum.color;
  Color get statusBgColor => statusEnum.bgColor;
  IconData get statusIcon => statusEnum.icon;

  int get riskWeight => riskLevelEnum.weight;
  Color get riskColor => riskLevelEnum.color;
  Color get riskBgColor => riskLevelEnum.bgColor;
  String get categoryLabelTh => categoryEnum.titleTh;

  bool get isCompliant => isApplicable && complianceStatus.toUpperCase() == 'COMPLIANT';
  bool get isNonCompliant => isApplicable && complianceStatus.toUpperCase() == 'NON_COMPLIANT';
  bool get isInProgress => isApplicable && complianceStatus.toUpperCase() == 'IN_PROGRESS';
  bool get isNotApplicable => !isApplicable || complianceStatus.toUpperCase() == 'NOT_APPLICABLE';
  bool get requiresCapa => (isNonCompliant || isInProgress);
  bool get hasEvidence => evidenceFilePaths.isNotEmpty;

  LegalComplianceAssessmentModel copyWith({
    int? id,
    String? masterItemId,
    String? requirementCode,
    String? requirementTitle,
    String? requirementDetails,
    String? category,
    String? lawId,
    String? lawTitleTh,
    String? articleNo,
    bool? isApplicable,
    String? complianceStatus,
    String? actualPractice,
    String? evaluatedDate,
    String? nextReviewDate,
    String? evaluatorName,
    String? evaluatorRole,
    String? department,
    List<String>? evidenceFilePaths,
    String? riskLevel,
    String? penaltySummary,
    String? notes,
    String? createdAt,
    String? updatedAt,
  }) {
    return LegalComplianceAssessmentModel(
      id: id ?? this.id,
      masterItemId: masterItemId ?? this.masterItemId,
      requirementCode: requirementCode ?? this.requirementCode,
      requirementTitle: requirementTitle ?? this.requirementTitle,
      requirementDetails: requirementDetails ?? this.requirementDetails,
      category: category ?? this.category,
      lawId: lawId ?? this.lawId,
      lawTitleTh: lawTitleTh ?? this.lawTitleTh,
      articleNo: articleNo ?? this.articleNo,
      isApplicable: isApplicable ?? this.isApplicable,
      complianceStatus: complianceStatus ?? this.complianceStatus,
      actualPractice: actualPractice ?? this.actualPractice,
      evaluatedDate: evaluatedDate ?? this.evaluatedDate,
      nextReviewDate: nextReviewDate ?? this.nextReviewDate,
      evaluatorName: evaluatorName ?? this.evaluatorName,
      evaluatorRole: evaluatorRole ?? this.evaluatorRole,
      department: department ?? this.department,
      evidenceFilePaths: evidenceFilePaths ?? this.evidenceFilePaths,
      riskLevel: riskLevel ?? this.riskLevel,
      penaltySummary: penaltySummary ?? this.penaltySummary,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// SQLite database mapping
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'master_item_id': masterItemId,
      'requirement_code': requirementCode,
      'requirement_title': requirementTitle,
      'requirement_details': requirementDetails,
      'category': category,
      'law_id': lawId,
      'law_title_th': lawTitleTh,
      'article_no': articleNo,
      'is_applicable': isApplicable ? 1 : 0,
      'compliance_status': complianceStatus,
      'actual_practice': actualPractice,
      'evaluated_date': evaluatedDate,
      'next_review_date': nextReviewDate,
      'evaluator_name': evaluatorName,
      'evaluator_role': evaluatorRole,
      'department': department,
      'evidence_file_paths': jsonEncode(evidenceFilePaths),
      'risk_level': riskLevel,
      'penalty_summary': penaltySummary,
      'notes': notes,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory LegalComplianceAssessmentModel.fromMap(Map<String, dynamic> map) {
    List<String> parsedFiles = [];
    if (map['evidence_file_paths'] != null) {
      try {
        final decoded = jsonDecode(map['evidence_file_paths'].toString());
        if (decoded is List) {
          parsedFiles = decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {
        if (map['evidence_file_paths'] is List) {
          parsedFiles = (map['evidence_file_paths'] as List).map((e) => e.toString()).toList();
        } else {
          final str = map['evidence_file_paths'].toString();
          if (str.isNotEmpty) {
            parsedFiles = str.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
          }
        }
      }
    }

    final rawApplicable = map['is_applicable'] ?? map['isApplicable'];
    final bool isApp = rawApplicable == 1 || rawApplicable == true || rawApplicable == '1';

    return LegalComplianceAssessmentModel(
      id: map['id'] != null ? int.tryParse(map['id'].toString()) : null,
      masterItemId: (map['master_item_id'] ?? map['masterItemId'] ?? map['requirement_code'] ?? '').toString(),
      requirementCode: (map['requirement_code'] ?? map['requirementCode'] ?? '').toString(),
      requirementTitle: (map['requirement_title'] ?? map['requirementTitle'] ?? '').toString(),
      requirementDetails: (map['requirement_details'] ?? map['requirementDetails'] ?? '').toString(),
      category: (map['category'] ?? 'OSH_ACT').toString(),
      lawId: (map['law_id'] ?? map['lawId'] ?? '').toString(),
      lawTitleTh: (map['law_title_th'] ?? map['lawTitleTh'] ?? '').toString(),
      articleNo: (map['article_no'] ?? map['articleNo'] ?? '').toString(),
      isApplicable: isApp,
      complianceStatus: (map['compliance_status'] ?? map['complianceStatus'] ?? 'NOT_APPLICABLE').toString(),
      actualPractice: map['actual_practice']?.toString() ?? map['actualPractice']?.toString(),
      evaluatedDate: (map['evaluated_date'] ?? map['evaluatedDate'] ?? DateTime.now().toIso8601String().substring(0, 10)).toString(),
      nextReviewDate: map['next_review_date']?.toString() ?? map['nextReviewDate']?.toString(),
      evaluatorName: (map['evaluator_name'] ?? map['evaluatorName'] ?? 'จป.วิชาชีพ').toString(),
      evaluatorRole: map['evaluator_role']?.toString() ?? map['evaluatorRole']?.toString(),
      department: map['department']?.toString(),
      evidenceFilePaths: parsedFiles,
      riskLevel: (map['risk_level'] ?? map['riskLevel'] ?? 'MEDIUM').toString(),
      penaltySummary: map['penalty_summary']?.toString() ?? map['penaltySummary']?.toString(),
      notes: map['notes']?.toString(),
      createdAt: map['created_at']?.toString() ?? map['createdAt']?.toString(),
      updatedAt: map['updated_at']?.toString() ?? map['updatedAt']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => toMap();
  factory LegalComplianceAssessmentModel.fromJson(Map<String, dynamic> json) => LegalComplianceAssessmentModel.fromMap(json);
}
