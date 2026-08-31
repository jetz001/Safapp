import 'dart:convert';
import 'package:flutter/material.dart';

/// Categories for Thai Occupational Safety, Health, and Environment Legislation (8 Royal Gazette Laws).
enum LegalCategoryEnum {
  oshAct('OSH_ACT', 'พ.ร.บ. ความปลอดภัยฯ ๒๕๕๔', 'Occupational Safety Act 2011', Icons.shield_outlined, Color(0xFF1E3A8A)),
  safetyOfficer('SAFETY_OFFICER', 'จป. & คปอ. ๒๕๖๕', 'Safety Officer & Committee Reg. 2022', Icons.groups_rounded, Color(0xFF0D9488)),
  chemicalSafety('CHEMICAL_SAFETY', 'สารเคมีอันตราย ๒๕๕๖', 'Hazardous Chemicals Reg. 2013', Icons.science_rounded, Color(0xFFD97706)),
  fireSafety('FIRE_SAFETY', 'อัคคีภัย ๒๕๕๕', 'Fire Prevention & Control Reg. 2012', Icons.local_fire_department_rounded, Color(0xFFDC2626)),
  electricalSafety('ELECTRICAL_SAFETY', 'ไฟฟ้า ๒๕๕๘', 'Electrical Safety Reg. 2015', Icons.bolt_rounded, Color(0xFFEAB308)),
  machineryBoiler('MACHINERY_BOILER', 'เครื่องจักร ปั้นจั่น หม้อน้ำ ๒๕๖๔', 'Machinery, Cranes & Boilers Reg. 2021', Icons.precision_manufacturing_rounded, Color(0xFF4F46E5)),
  environmentPhysical('ENVIRONMENT_PHYSICAL', 'สภาพแวดล้อม (แสง เสียง ความร้อน) ๒๕๕๙', 'Physical Working Environment Reg. 2016', Icons.wb_sunny_rounded, Color(0xFF059669)),
  healthSurveillance('HEALTH_SURVEILLANCE', 'ตรวจสุขภาพตามปัจจัยเสี่ยง ๒๕๖๓', 'Health Surveillance for Risk Factors Reg. 2020', Icons.health_and_safety_rounded, Color(0xFF9333EA));

  final String code;
  final String titleTh;
  final String titleEn;
  final IconData icon;
  final Color primaryColor;

  const LegalCategoryEnum(this.code, this.titleTh, this.titleEn, this.icon, this.primaryColor);

  static LegalCategoryEnum fromCode(String code) {
    return LegalCategoryEnum.values.firstWhere(
      (e) => e.code.toUpperCase() == code.toUpperCase(),
      orElse: () => LegalCategoryEnum.oshAct,
    );
  }
}

/// Regulatory risk level assigned to statutory requirements.
enum LegalRiskLevel {
  high('HIGH', 'เสี่ยงสูง (High Risk)', 3, Color(0xFFDC2626), Color(0xFFFEF2F2)),
  medium('MEDIUM', 'เสี่ยงปานกลาง (Medium Risk)', 2, Color(0xFFD97706), Color(0xFFFFFBEB)),
  low('LOW', 'เสี่ยงต่ำ (Low Risk)', 1, Color(0xFF059669), Color(0xFFECFDF5));

  final String code;
  final String labelTh;
  final int weight;
  final Color color;
  final Color bgColor;

  const LegalRiskLevel(this.code, this.labelTh, this.weight, this.color, this.bgColor);

  static LegalRiskLevel fromCode(String code) {
    return LegalRiskLevel.values.firstWhere(
      (e) => e.code.toUpperCase() == code.toUpperCase(),
      orElse: () => LegalRiskLevel.medium,
    );
  }
}

/// Statutory evidence verification artifact types.
enum LegalEvidenceType {
  documentCertificate('DOCUMENT_CERTIFICATE', 'เอกสารรับรอง / หนังสือสำคัญ', Icons.description_rounded),
  trainingRecord('TRAINING_RECORD', 'บันทึกการฝึกอบรม / วุฒิบัตร', Icons.school_rounded),
  physicalPhoto('PHYSICAL_PHOTO', 'ภาพถ่ายสภาพหน้างานจริง', Icons.camera_alt_rounded),
  officialForm('OFFICIAL_FORM', 'แบบฟอร์มรายงานราชการ (สอ./จป./สปร./ปจ./บร.)', Icons.assignment_rounded),
  inspectionReport('INSPECTION_REPORT', 'รายงานการตรวจสภาพ / เช็กลิสต์', Icons.fact_check_rounded),
  measurementLog('MEASUREMENT_LOG', 'บันทึกผลการตรวจวัด / วิเคราะห์แล็บ', Icons.speed_rounded);

  final String code;
  final String labelTh;
  final IconData icon;

  const LegalEvidenceType(this.code, this.labelTh, this.icon);

  static LegalEvidenceType fromCode(String code) {
    return LegalEvidenceType.values.firstWhere(
      (e) => e.code.toUpperCase() == code.toUpperCase(),
      orElse: () => LegalEvidenceType.documentCertificate,
    );
  }
}

/// Royal Gazette citation publication reference.
class LegalGazetteReference {
  final String? volume;
  final String? part;
  final String? page;
  final String? publishedDate;
  final String? effectiveDate;

  const LegalGazetteReference({
    this.volume,
    this.part,
    this.page,
    this.publishedDate,
    this.effectiveDate,
  });

  String get formattedCitation {
    final parts = <String>[];
    if (volume != null && volume!.isNotEmpty) parts.add('เล่ม $volume');
    if (part != null && part!.isNotEmpty) parts.add('ตอนที่ $part');
    if (page != null && page!.isNotEmpty) parts.add('หน้า $page');
    if (publishedDate != null && publishedDate!.isNotEmpty) parts.add('(ประกาศ $publishedDate)');
    return parts.join(' ');
  }

  LegalGazetteReference copyWith({
    String? volume,
    String? part,
    String? page,
    String? publishedDate,
    String? effectiveDate,
  }) {
    return LegalGazetteReference(
      volume: volume ?? this.volume,
      part: part ?? this.part,
      page: page ?? this.page,
      publishedDate: publishedDate ?? this.publishedDate,
      effectiveDate: effectiveDate ?? this.effectiveDate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'volume': volume,
      'part': part,
      'page': page,
      'published_date': publishedDate,
      'effective_date': effectiveDate,
    };
  }

  factory LegalGazetteReference.fromMap(Map<String, dynamic> map) {
    return LegalGazetteReference(
      volume: map['volume']?.toString(),
      part: map['part']?.toString(),
      page: map['page']?.toString(),
      publishedDate: (map['published_date'] ?? map['publishedDate'])?.toString(),
      effectiveDate: (map['effective_date'] ?? map['effectiveDate'])?.toString(),
    );
  }

  Map<String, dynamic> toJson() => toMap();
  factory LegalGazetteReference.fromJson(Map<String, dynamic> json) => LegalGazetteReference.fromMap(json);
}

/// Master Statutory Legal Item representing an authoritative Thai safety regulation provision.
class LegalMasterItemModel {
  final int? id;
  final String itemId; // e.g. 'ITEM-OSH-001'
  final String lawId; // e.g. 'LAW-OSH-2554'
  final String lawNameTh;
  final String lawNameEn;
  final String category; // 'OSH_ACT', 'SAFETY_OFFICER', etc.
  final String governingAuthority; // 'กรมสวัสดิการและคุ้มครองแรงงาน (DLPW)'
  final LegalGazetteReference gazetteReference;
  final String articleNo; // e.g. 'มาตรา ๖ และ ๘'
  final String title;
  final String description;
  final String applicabilityCriteria;
  final String complianceCriteria;
  final String riskLevel; // 'HIGH', 'MEDIUM', 'LOW'
  final String requiredEvidenceType; // 'DOCUMENT_CERTIFICATE', etc.
  final String? officialFormName; // e.g. 'แบบ สปร. ๕', 'แบบ สอ.๑'
  final int retentionYears;
  final String penaltySummary;
  final String? pdfAssetPath;
  final int sortOrder;

  const LegalMasterItemModel({
    this.id,
    required this.itemId,
    required this.lawId,
    required this.lawNameTh,
    required this.lawNameEn,
    required this.category,
    required this.governingAuthority,
    required this.gazetteReference,
    required this.articleNo,
    required this.title,
    required this.description,
    required this.applicabilityCriteria,
    required this.complianceCriteria,
    required this.riskLevel,
    required this.requiredEvidenceType,
    this.officialFormName,
    this.retentionYears = 1,
    required this.penaltySummary,
    this.pdfAssetPath,
    this.sortOrder = 0,
  });

  LegalCategoryEnum get categoryEnum => LegalCategoryEnum.fromCode(category);
  LegalRiskLevel get riskLevelEnum => LegalRiskLevel.fromCode(riskLevel);
  LegalEvidenceType get evidenceTypeEnum => LegalEvidenceType.fromCode(requiredEvidenceType);

  String get categoryLabelTh => categoryEnum.titleTh;
  int get riskWeight => riskLevelEnum.weight;
  Color get riskColor => riskLevelEnum.color;
  Color get riskBgColor => riskLevelEnum.bgColor;
  String get riskLabelTh => riskLevelEnum.labelTh;
  String get evidenceTypeLabelTh => evidenceTypeEnum.labelTh;

  LegalMasterItemModel copyWith({
    int? id,
    String? itemId,
    String? lawId,
    String? lawNameTh,
    String? lawNameEn,
    String? category,
    String? governingAuthority,
    LegalGazetteReference? gazetteReference,
    String? articleNo,
    String? title,
    String? description,
    String? applicabilityCriteria,
    String? complianceCriteria,
    String? riskLevel,
    String? requiredEvidenceType,
    String? officialFormName,
    int? retentionYears,
    String? penaltySummary,
    String? pdfAssetPath,
    int? sortOrder,
  }) {
    return LegalMasterItemModel(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      lawId: lawId ?? this.lawId,
      lawNameTh: lawNameTh ?? this.lawNameTh,
      lawNameEn: lawNameEn ?? this.lawNameEn,
      category: category ?? this.category,
      governingAuthority: governingAuthority ?? this.governingAuthority,
      gazetteReference: gazetteReference ?? this.gazetteReference,
      articleNo: articleNo ?? this.articleNo,
      title: title ?? this.title,
      description: description ?? this.description,
      applicabilityCriteria: applicabilityCriteria ?? this.applicabilityCriteria,
      complianceCriteria: complianceCriteria ?? this.complianceCriteria,
      riskLevel: riskLevel ?? this.riskLevel,
      requiredEvidenceType: requiredEvidenceType ?? this.requiredEvidenceType,
      officialFormName: officialFormName ?? this.officialFormName,
      retentionYears: retentionYears ?? this.retentionYears,
      penaltySummary: penaltySummary ?? this.penaltySummary,
      pdfAssetPath: pdfAssetPath ?? this.pdfAssetPath,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  /// SQLite database mapping
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'item_id': itemId,
      'law_id': lawId,
      'law_name_th': lawNameTh,
      'law_name_en': lawNameEn,
      'category': category,
      'governing_authority': governingAuthority,
      'gazette_volume': gazetteReference.volume,
      'gazette_part': gazetteReference.part,
      'gazette_page': gazetteReference.page,
      'gazette_published_date': gazetteReference.publishedDate,
      'gazette_effective_date': gazetteReference.effectiveDate,
      'article_no': articleNo,
      'title': title,
      'description': description,
      'applicability_criteria': applicabilityCriteria,
      'compliance_criteria': complianceCriteria,
      'risk_level': riskLevel,
      'required_evidence_type': requiredEvidenceType,
      'official_form_name': officialFormName,
      'retention_years': retentionYears,
      'penalty_summary': penaltySummary,
      'pdf_asset_path': pdfAssetPath,
      'sort_order': sortOrder,
    };
  }

  factory LegalMasterItemModel.fromMap(Map<String, dynamic> map) {
    LegalGazetteReference gazetteRef;
    if (map['gazette_reference'] != null && map['gazette_reference'] is Map) {
      gazetteRef = LegalGazetteReference.fromMap(Map<String, dynamic>.from(map['gazette_reference'] as Map));
    } else {
      gazetteRef = LegalGazetteReference(
        volume: map['gazette_volume']?.toString(),
        part: map['gazette_part']?.toString(),
        page: map['gazette_page']?.toString(),
        publishedDate: map['gazette_published_date']?.toString(),
        effectiveDate: map['gazette_effective_date']?.toString(),
      );
    }

    return LegalMasterItemModel(
      id: map['id'] != null ? int.tryParse(map['id'].toString()) : null,
      itemId: (map['item_id'] ?? map['itemId'] ?? '').toString(),
      lawId: (map['law_id'] ?? map['lawId'] ?? '').toString(),
      lawNameTh: (map['law_name_th'] ?? map['lawNameTh'] ?? '').toString(),
      lawNameEn: (map['law_name_en'] ?? map['lawNameEn'] ?? '').toString(),
      category: (map['category'] ?? 'OSH_ACT').toString(),
      governingAuthority: (map['governing_authority'] ?? map['governingAuthority'] ?? 'DLPW').toString(),
      gazetteReference: gazetteRef,
      articleNo: (map['article_no'] ?? map['articleNo'] ?? '').toString(),
      title: (map['title'] ?? '').toString(),
      description: (map['description'] ?? '').toString(),
      applicabilityCriteria: (map['applicability_criteria'] ?? map['applicabilityCriteria'] ?? '').toString(),
      complianceCriteria: (map['compliance_criteria'] ?? map['complianceCriteria'] ?? '').toString(),
      riskLevel: (map['risk_level'] ?? map['riskLevel'] ?? 'MEDIUM').toString(),
      requiredEvidenceType: (map['required_evidence_type'] ?? map['requiredEvidenceType'] ?? 'DOCUMENT_CERTIFICATE').toString(),
      officialFormName: map['official_form_name']?.toString() ?? map['officialFormName']?.toString(),
      retentionYears: int.tryParse(map['retention_years']?.toString() ?? map['retentionYears']?.toString() ?? '1') ?? 1,
      penaltySummary: (map['penalty_summary'] ?? map['penaltySummary'] ?? '').toString(),
      pdfAssetPath: map['pdf_asset_path']?.toString() ?? map['pdfAssetPath']?.toString(),
      sortOrder: int.tryParse(map['sort_order']?.toString() ?? map['sortOrder']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() => toMap();
  factory LegalMasterItemModel.fromJson(Map<String, dynamic> json) => LegalMasterItemModel.fromMap(json);
}
