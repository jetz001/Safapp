import 'package:flutter/material.dart';

enum ElectricalInspectionStatus {
  compliant(
    titleTh: 'ผ่านเกณฑ์สมบูรณ์',
    color: Color(0xFF16A34A), // Green
    icon: Icons.check_circle_rounded,
  ),
  warning(
    titleTh: 'ใกล้ครบกำหนด (ต้องต่ออายุ)',
    color: Color(0xFFEA580C), // Orange
    icon: Icons.warning_rounded,
  ),
  overdue(
    titleTh: 'เกินกำหนดตรวจสอบ (ผิดกฎหมาย)',
    color: Color(0xFFDC2626), // Red
    icon: Icons.error_rounded,
  );

  final String titleTh;
  final Color color;
  final IconData icon;

  const ElectricalInspectionStatus({
    required this.titleTh,
    required this.color,
    required this.icon,
  });
}

class ElectricalInspectionModel {
  final int? id;
  final String? companyName;
  final DateTime inspectionDate;
  final DateTime expiryDate;
  final String inspectorName;
  final String inspectorLicenseNo;
  final String? contractorCompany;
  final String inspectorType; // 'EXTERNAL_CONTRACTOR', 'INTERNAL_ENGINEER', 'GOVERNMENT'
  final String overallResult; // 'PASS', 'CONDITIONAL_PASS', 'FAIL'
  final String voltageSystem; // 'HIGH_VOLTAGE', 'LOW_VOLTAGE', 'HIGH_AND_LOW_VOLTAGE'
  final int transformerCount;
  final int mdbPanelCount;
  final double? groundingResistanceOhm;
  final String? defectsFound;
  final String? correctiveActions;
  final String? vendorReportPdfPath;
  final String? thermoscanReportPath;
  final String? engineerLicenseDocPath;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ElectricalInspectionModel({
    this.id,
    this.companyName,
    required this.inspectionDate,
    DateTime? expiryDate,
    required this.inspectorName,
    required this.inspectorLicenseNo,
    this.contractorCompany,
    this.inspectorType = 'EXTERNAL_CONTRACTOR',
    this.overallResult = 'PASS',
    this.voltageSystem = 'HIGH_AND_LOW_VOLTAGE',
    this.transformerCount = 0,
    this.mdbPanelCount = 0,
    this.groundingResistanceOhm,
    this.defectsFound,
    this.correctiveActions,
    this.vendorReportPdfPath,
    this.thermoscanReportPath,
    this.engineerLicenseDocPath,
    this.createdAt,
    this.updatedAt,
  }) : expiryDate = expiryDate ?? inspectionDate.add(const Duration(days: 365));

  int get daysRemaining {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(expiryDate.year, expiryDate.month, expiryDate.day);
    return target.difference(today).inDays;
  }

  bool get isOverdue => daysRemaining < 0;
  bool get isExpiringSoon => daysRemaining >= 0 && daysRemaining <= 60;

  ElectricalInspectionStatus get slaStatus {
    if (isOverdue) return ElectricalInspectionStatus.overdue;
    if (isExpiringSoon) return ElectricalInspectionStatus.warning;
    return ElectricalInspectionStatus.compliant;
  }

  String get overallResultTh {
    switch (overallResult) {
      case 'PASS':
        return 'ปลอดภัยใช้งานได้ (ผ่าน)';
      case 'CONDITIONAL_PASS':
        return 'ปลอดภัยแบบมีเงื่อนไข (ต้องแก้ไข)';
      case 'FAIL':
        return 'ไม่ปลอดภัย (ต้องซ่อมแซมด่วน)';
      default:
        return overallResult;
    }
  }

  String get voltageSystemTh {
    switch (voltageSystem) {
      case 'HIGH_VOLTAGE':
        return 'แรงดันสูง (High Voltage)';
      case 'LOW_VOLTAGE':
        return 'แรงดันต่ำ (Low Voltage)';
      case 'HIGH_AND_LOW_VOLTAGE':
        return 'แรงดันสูงและต่ำ (High & Low Voltage)';
      default:
        return voltageSystem;
    }
  }

  bool get isGroundingStandardPass {
    if (groundingResistanceOhm == null) return true;
    return groundingResistanceOhm! <= 5.0; // วสท. / กฎกระทรวงกำหนดไม่เกิน 5 โอห์ม
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'company_name': companyName,
      'inspection_date': inspectionDate.toIso8601String().substring(0, 10),
      'expiry_date': expiryDate.toIso8601String().substring(0, 10),
      'inspector_name': inspectorName,
      'inspector_license_no': inspectorLicenseNo,
      'contractor_company': contractorCompany,
      'inspector_type': inspectorType,
      'overall_result': overallResult,
      'voltage_system': voltageSystem,
      'transformer_count': transformerCount,
      'mdb_panel_count': mdbPanelCount,
      'grounding_resistance_ohm': groundingResistanceOhm,
      'defects_found': defectsFound,
      'corrective_actions': correctiveActions,
      'vendor_report_pdf_path': vendorReportPdfPath,
      'thermoscan_report_path': thermoscanReportPath,
      'engineer_license_doc_path': engineerLicenseDocPath,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  factory ElectricalInspectionModel.fromMap(Map<String, dynamic> map) {
    return ElectricalInspectionModel(
      id: map['id'] as int?,
      companyName: map['company_name'] as String?,
      inspectionDate: DateTime.parse(map['inspection_date'] as String),
      expiryDate: map['expiry_date'] != null
          ? DateTime.parse(map['expiry_date'] as String)
          : null,
      inspectorName: map['inspector_name'] as String? ?? '',
      inspectorLicenseNo: map['inspector_license_no'] as String? ?? '',
      contractorCompany: map['contractor_company'] as String?,
      inspectorType: map['inspector_type'] as String? ?? 'EXTERNAL_CONTRACTOR',
      overallResult: map['overall_result'] as String? ?? 'PASS',
      voltageSystem: map['voltage_system'] as String? ?? 'HIGH_AND_LOW_VOLTAGE',
      transformerCount: (map['transformer_count'] as num?)?.toInt() ?? 0,
      mdbPanelCount: (map['mdb_panel_count'] as num?)?.toInt() ?? 0,
      groundingResistanceOhm: (map['grounding_resistance_ohm'] as num?)?.toDouble(),
      defectsFound: map['defects_found'] as String?,
      correctiveActions: map['corrective_actions'] as String?,
      vendorReportPdfPath: map['vendor_report_pdf_path'] as String?,
      thermoscanReportPath: map['thermoscan_report_path'] as String?,
      engineerLicenseDocPath: map['engineer_license_doc_path'] as String?,
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at'] as String) : null,
      updatedAt: map['updated_at'] != null ? DateTime.tryParse(map['updated_at'] as String) : null,
    );
  }

  ElectricalInspectionModel copyWith({
    int? id,
    String? companyName,
    DateTime? inspectionDate,
    DateTime? expiryDate,
    String? inspectorName,
    String? inspectorLicenseNo,
    String? contractorCompany,
    String? inspectorType,
    String? overallResult,
    String? voltageSystem,
    int? transformerCount,
    int? mdbPanelCount,
    double? groundingResistanceOhm,
    String? defectsFound,
    String? correctiveActions,
    String? vendorReportPdfPath,
    String? thermoscanReportPath,
    String? engineerLicenseDocPath,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ElectricalInspectionModel(
      id: id ?? this.id,
      companyName: companyName ?? this.companyName,
      inspectionDate: inspectionDate ?? this.inspectionDate,
      expiryDate: expiryDate ?? this.expiryDate,
      inspectorName: inspectorName ?? this.inspectorName,
      inspectorLicenseNo: inspectorLicenseNo ?? this.inspectorLicenseNo,
      contractorCompany: contractorCompany ?? this.contractorCompany,
      inspectorType: inspectorType ?? this.inspectorType,
      overallResult: overallResult ?? this.overallResult,
      voltageSystem: voltageSystem ?? this.voltageSystem,
      transformerCount: transformerCount ?? this.transformerCount,
      mdbPanelCount: mdbPanelCount ?? this.mdbPanelCount,
      groundingResistanceOhm: groundingResistanceOhm ?? this.groundingResistanceOhm,
      defectsFound: defectsFound ?? this.defectsFound,
      correctiveActions: correctiveActions ?? this.correctiveActions,
      vendorReportPdfPath: vendorReportPdfPath ?? this.vendorReportPdfPath,
      thermoscanReportPath: thermoscanReportPath ?? this.thermoscanReportPath,
      engineerLicenseDocPath: engineerLicenseDocPath ?? this.engineerLicenseDocPath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}