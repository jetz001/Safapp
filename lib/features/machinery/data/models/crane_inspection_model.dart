class CraneInspectionModel {
  final int? id;
  final String craneName;
  final String craneTag;
  final String craneType; // OVERHEAD, GANTRY, JIB, TOWER, MOBILE
  final String inspectionForm; // PJ1, PJ2
  final String locationBuilding;
  final String? locationArea;
  final double safeWorkingLoadTon;
  final double? testWeightTon;
  final double? loadTestPercent;
  final int inspectionCycleMonths;
  final String wireRopeStatus;
  final String hookLatchStatus;
  final String limitSwitchStatus;
  final String brakeSystemStatus;
  final String structureStatus;
  final String engineerName;
  final String engineerLicenseNo;
  final String? contractorCompany;
  final DateTime inspectionDate;
  final DateTime expiryDate;
  final String overallResult; // PASS, FAIL
  final String? defectsFound;
  final String? correctiveActions;
  final String? vendorReportPdfPath;
  final String? loadTestCertPdfPath;
  final String? engineerLicensePdfPath;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  CraneInspectionModel({
    this.id,
    required this.craneName,
    required this.craneTag,
    required this.craneType,
    required this.inspectionForm,
    required this.locationBuilding,
    this.locationArea,
    required this.safeWorkingLoadTon,
    this.testWeightTon,
    this.loadTestPercent,
    this.inspectionCycleMonths = 12,
    this.wireRopeStatus = 'PASS',
    this.hookLatchStatus = 'PASS',
    this.limitSwitchStatus = 'PASS',
    this.brakeSystemStatus = 'PASS',
    this.structureStatus = 'PASS',
    required this.engineerName,
    required this.engineerLicenseNo,
    this.contractorCompany,
    required this.inspectionDate,
    required this.expiryDate,
    this.overallResult = 'PASS',
    this.defectsFound,
    this.correctiveActions,
    this.vendorReportPdfPath,
    this.loadTestCertPdfPath,
    this.engineerLicensePdfPath,
    this.createdAt,
    this.updatedAt,
  });

  int get daysUntilExpiry {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(expiryDate.year, expiryDate.month, expiryDate.day);
    return target.difference(today).inDays;
  }

  bool get isExpired => daysUntilExpiry < 0;

  String get slaStatus {
    if (daysUntilExpiry < 0) return 'OVERDUE';
    if (daysUntilExpiry <= 30) return 'WARNING';
    return 'COMPLIANT';
  }

  String get craneTypeTh {
    switch (craneType) {
      case 'OVERHEAD':
        return 'ปั้นจั่นเหนือศีรษะ (Overhead Crane)';
      case 'GANTRY':
        return 'ปั้นจั่นขาสูง (Gantry Crane)';
      case 'JIB':
        return 'ปั้นจั่นแบบหมุน / รอกไฟฟ้า (Jib Crane / Hoist)';
      case 'TOWER':
        return 'ปั้นจั่นหอสูง (Tower Crane)';
      case 'MOBILE':
        return 'ปั้นจั่นเคลื่อนที่ / รถเครน (Mobile Crane)';
      default:
        return craneType;
    }
  }

  String get inspectionFormTh {
    return inspectionForm == 'PJ2' ? 'แบบ ปจ.๒ (ปั้นจั่นเคลื่อนที่)' : 'แบบ ปจ.๑ (ปั้นจั่นอยู่กับที่)';
  }

  String get overallResultTh => overallResult == 'PASS' ? 'ผ่านเกณฑ์มาตรฐาน' : 'มีข้อบกพร่องต้องปรับปรุง';

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'crane_name': craneName,
      'crane_tag': craneTag,
      'crane_type': craneType,
      'inspection_form': inspectionForm,
      'location_building': locationBuilding,
      'location_area': locationArea,
      'safe_working_load_ton': safeWorkingLoadTon,
      'test_weight_ton': testWeightTon,
      'load_test_percent': loadTestPercent,
      'inspection_cycle_months': inspectionCycleMonths,
      'wire_rope_status': wireRopeStatus,
      'hook_latch_status': hookLatchStatus,
      'limit_switch_status': limitSwitchStatus,
      'brake_system_status': brakeSystemStatus,
      'structure_status': structureStatus,
      'engineer_name': engineerName,
      'engineer_license_no': engineerLicenseNo,
      'contractor_company': contractorCompany,
      'inspection_date': inspectionDate.toIso8601String().substring(0, 10),
      'expiry_date': expiryDate.toIso8601String().substring(0, 10),
      'overall_result': overallResult,
      'defects_found': defectsFound,
      'corrective_actions': correctiveActions,
      'vendor_report_pdf_path': vendorReportPdfPath,
      'load_test_cert_pdf_path': loadTestCertPdfPath,
      'engineer_license_pdf_path': engineerLicensePdfPath,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  factory CraneInspectionModel.fromMap(Map<String, dynamic> map) {
    return CraneInspectionModel(
      id: map['id'] as int?,
      craneName: map['crane_name'] as String? ?? '',
      craneTag: map['crane_tag'] as String? ?? '',
      craneType: map['crane_type'] as String? ?? 'OVERHEAD',
      inspectionForm: map['inspection_form'] as String? ?? 'PJ1',
      locationBuilding: map['location_building'] as String? ?? '',
      locationArea: map['location_area'] as String?,
      safeWorkingLoadTon: (map['safe_working_load_ton'] as num?)?.toDouble() ?? 0.0,
      testWeightTon: (map['test_weight_ton'] as num?)?.toDouble(),
      loadTestPercent: (map['load_test_percent'] as num?)?.toDouble(),
      inspectionCycleMonths: (map['inspection_cycle_months'] as int?) ?? 12,
      wireRopeStatus: map['wire_rope_status'] as String? ?? 'PASS',
      hookLatchStatus: map['hook_latch_status'] as String? ?? 'PASS',
      limitSwitchStatus: map['limit_switch_status'] as String? ?? 'PASS',
      brakeSystemStatus: map['brake_system_status'] as String? ?? 'PASS',
      structureStatus: map['structure_status'] as String? ?? 'PASS',
      engineerName: map['engineer_name'] as String? ?? '',
      engineerLicenseNo: map['engineer_license_no'] as String? ?? '',
      contractorCompany: map['contractor_company'] as String?,
      inspectionDate: DateTime.tryParse(map['inspection_date'] as String? ?? '') ?? DateTime.now(),
      expiryDate: DateTime.tryParse(map['expiry_date'] as String? ?? '') ?? DateTime.now(),
      overallResult: map['overall_result'] as String? ?? 'PASS',
      defectsFound: map['defects_found'] as String?,
      correctiveActions: map['corrective_actions'] as String?,
      vendorReportPdfPath: map['vendor_report_pdf_path'] as String?,
      loadTestCertPdfPath: map['load_test_cert_pdf_path'] as String?,
      engineerLicensePdfPath: map['engineer_license_pdf_path'] as String?,
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at'] as String) : null,
      updatedAt: map['updated_at'] != null ? DateTime.tryParse(map['updated_at'] as String) : null,
    );
  }

  CraneInspectionModel copyWith({
    int? id,
    String? craneName,
    String? craneTag,
    String? craneType,
    String? inspectionForm,
    String? locationBuilding,
    String? locationArea,
    double? safeWorkingLoadTon,
    double? testWeightTon,
    double? loadTestPercent,
    int? inspectionCycleMonths,
    String? wireRopeStatus,
    String? hookLatchStatus,
    String? limitSwitchStatus,
    String? brakeSystemStatus,
    String? structureStatus,
    String? engineerName,
    String? engineerLicenseNo,
    String? contractorCompany,
    DateTime? inspectionDate,
    DateTime? expiryDate,
    String? overallResult,
    String? defectsFound,
    String? correctiveActions,
    String? vendorReportPdfPath,
    String? loadTestCertPdfPath,
    String? engineerLicensePdfPath,
  }) {
    return CraneInspectionModel(
      id: id ?? this.id,
      craneName: craneName ?? this.craneName,
      craneTag: craneTag ?? this.craneTag,
      craneType: craneType ?? this.craneType,
      inspectionForm: inspectionForm ?? this.inspectionForm,
      locationBuilding: locationBuilding ?? this.locationBuilding,
      locationArea: locationArea ?? this.locationArea,
      safeWorkingLoadTon: safeWorkingLoadTon ?? this.safeWorkingLoadTon,
      testWeightTon: testWeightTon ?? this.testWeightTon,
      loadTestPercent: loadTestPercent ?? this.loadTestPercent,
      inspectionCycleMonths: inspectionCycleMonths ?? this.inspectionCycleMonths,
      wireRopeStatus: wireRopeStatus ?? this.wireRopeStatus,
      hookLatchStatus: hookLatchStatus ?? this.hookLatchStatus,
      limitSwitchStatus: limitSwitchStatus ?? this.limitSwitchStatus,
      brakeSystemStatus: brakeSystemStatus ?? this.brakeSystemStatus,
      structureStatus: structureStatus ?? this.structureStatus,
      engineerName: engineerName ?? this.engineerName,
      engineerLicenseNo: engineerLicenseNo ?? this.engineerLicenseNo,
      contractorCompany: contractorCompany ?? this.contractorCompany,
      inspectionDate: inspectionDate ?? this.inspectionDate,
      expiryDate: expiryDate ?? this.expiryDate,
      overallResult: overallResult ?? this.overallResult,
      defectsFound: defectsFound ?? this.defectsFound,
      correctiveActions: correctiveActions ?? this.correctiveActions,
      vendorReportPdfPath: vendorReportPdfPath ?? this.vendorReportPdfPath,
      loadTestCertPdfPath: loadTestCertPdfPath ?? this.loadTestCertPdfPath,
      engineerLicensePdfPath: engineerLicensePdfPath ?? this.engineerLicensePdfPath,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
