import 'dart:convert';
import '../../domain/enums/high_risk_type.dart';

/// Safety Checklist Item for High-Risk PTW Verification
class PtwChecklistModel {
  final int? id;
  final String? ptwNumber; // Reference to PtwModel.ptwNumber
  final String itemId; // e.g. "CHK-HOT-01", "CHK-CONF-02"
  final HighRiskType riskType;
  final String checkCategory; // e.g. "PPE", "EQUIPMENT", "ENVIRONMENT", "EMERGENCY", "ISOLATION"
  final String questionTh;
  final String questionEn;
  final bool isMandatory; // ข้อบังคับตามกฎหมาย (ต้อง 'YES' จึงจะอนุญาตได้)
  final String result; // 'YES', 'NO', 'NA'
  final String? remarks;
  final String? checkedBy;
  final String? checkedAt;

  const PtwChecklistModel({
    this.id,
    this.ptwNumber,
    required this.itemId,
    required this.riskType,
    required this.checkCategory,
    required this.questionTh,
    required this.questionEn,
    this.isMandatory = true,
    this.result = 'NA',
    this.remarks,
    this.checkedBy,
    this.checkedAt,
  });

  /// True if item is compliant (YES, or NA when not mandatory)
  bool get isCompliant => result == 'YES' || (result == 'NA' && !isMandatory);

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      if (ptwNumber != null) 'ptw_number': ptwNumber,
      'item_id': itemId,
      'risk_type': riskType.toDbCode(),
      'check_category': checkCategory,
      'question_th': questionTh,
      'question_en': questionEn,
      'is_mandatory': isMandatory ? 1 : 0,
      'result': result,
      'remarks': remarks,
      'checked_by': checkedBy,
      'checked_at': checkedAt,
    };
  }

  factory PtwChecklistModel.fromMap(Map<String, dynamic> map) {
    return PtwChecklistModel(
      id: map['id'] as int?,
      ptwNumber: map['ptw_number']?.toString(),
      itemId: map['item_id']?.toString() ?? '',
      riskType: HighRiskType.fromDbCode(map['risk_type']?.toString()),
      checkCategory: map['check_category']?.toString() ?? '',
      questionTh: map['question_th']?.toString() ?? '',
      questionEn: map['question_en']?.toString() ?? '',
      isMandatory: (map['is_mandatory'] == 1 || map['is_mandatory'] == true),
      result: map['result']?.toString() ?? 'NA',
      remarks: map['remarks']?.toString(),
      checkedBy: map['checked_by']?.toString(),
      checkedAt: map['checked_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => toMap();
  factory PtwChecklistModel.fromJson(Map<String, dynamic> json) => PtwChecklistModel.fromMap(json);

  PtwChecklistModel copyWith({
    int? id,
    String? ptwNumber,
    String? itemId,
    HighRiskType? riskType,
    String? checkCategory,
    String? questionTh,
    String? questionEn,
    bool? isMandatory,
    String? result,
    String? remarks,
    String? checkedBy,
    String? checkedAt,
  }) {
    return PtwChecklistModel(
      id: id ?? this.id,
      ptwNumber: ptwNumber ?? this.ptwNumber,
      itemId: itemId ?? this.itemId,
      riskType: riskType ?? this.riskType,
      checkCategory: checkCategory ?? this.checkCategory,
      questionTh: questionTh ?? this.questionTh,
      questionEn: questionEn ?? this.questionEn,
      isMandatory: isMandatory ?? this.isMandatory,
      result: result ?? this.result,
      remarks: remarks ?? this.remarks,
      checkedBy: checkedBy ?? this.checkedBy,
      checkedAt: checkedAt ?? this.checkedAt,
    );
  }

  @override
  String toString() => 'PtwChecklistModel(itemId: $itemId, category: $checkCategory, mandatory: $isMandatory, result: $result)';
}
