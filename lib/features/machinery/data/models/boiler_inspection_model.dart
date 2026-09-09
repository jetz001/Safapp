class BoilerInspectionModel {
  final int? id;
  final String boilerName;
  final String boilerTag;
  final String boilerType; // STEAM_BOILER, THERMAL_OIL, HOT_WATER, PRESSURE_VESSEL
  final double? capacityTonHr;
  final String locationBuilding;
  final String? locationArea;
  final double maxAllowableWorkingPressureBar;
  final double? hydroTestPressureBar;
  final String hydroTestResult; // PASS, FAIL
  final String safetyValveTestResult; // PASS, FAIL
  final double? safetyValvePopPressureBar;
  final String waterTreatmentStatus; // PASS, FAIL
  final String burnerControlStatus; // PASS, FAIL
  final String engineerName;
  final String engineerLicenseNo;
  final String? contractorCompany;
  final DateTime inspectionDate;
  final DateTime expiryDate;
  final String overallResult; // PASS, FAIL
  final String? defectsFound;
  final String? correctiveActions;
  final String? reportPdfPath;
  final String? engineerLicensePdfPath;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  BoilerInspectionModel({
    this.id,
    required this.boilerName,
    required this.boilerTag,
    required this.boilerType,
    this.capacityTonHr,
    required this.locationBuilding,
    this.locationArea,
    required this.maxAllowableWorkingPressureBar,
    this.hydroTestPressureBar,
    this.hydroTestResult = 'PASS',
    this.safetyValveTestResult = 'PASS',
    this.safetyValvePopPressureBar,
    this.waterTreatmentStatus = 'PASS',
    this.burnerControlStatus = 'PASS',
    required this.engineerName,
    required this.engineerLicenseNo,
    this.contractorCompany,
    required this.inspectionDate,
    required this.expiryDate,
    this.overallResult = 'PASS',
    this.defectsFound,
    this.correctiveActions,
    this.reportPdfPath,
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

  String get boilerTypeTh {
    switch (boilerType) {
      case 'STEAM_BOILER':
        return 'หม้อน้ำไอน้ำ (Steam Boiler)';
      case 'THERMAL_OIL':
        return 'หม้อต้มน้ำมันนำความร้อน (Thermal Oil Heater)';
      case 'HOT_WATER':
        return 'หม้อต้มน้ำร้อน (Hot Water Boiler)';
      case 'PRESSURE_VESSEL':
        return 'ภาชนะรับแรงดัน (Pressure Vessel / Air Receiver)';
      default:
        return boilerType;
    }
  }

  String get overallResultTh => overallResult == 'PASS' ? 'ผ่านเกณฑ์มาตรฐาน' : 'มีข้อบกพร่องต้องปรับปรุง';

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'boiler_name': boilerName,
      'boiler_tag': boilerTag,
      'boiler_type': boilerType,
      'capacity_ton_hr': capacityTonHr,
      'location_building': locationBuilding,
      'location_area': locationArea,
      'max_allowable_working_pressure_bar': maxAllowableWorkingPressureBar,
      'hydro_test_pressure_bar': hydroTestPressureBar,
      'hydro_test_result': hydroTestResult,
      'safety_valve_test_result': safetyValveTestResult,
      'safety_valve_pop_pressure_bar': safetyValvePopPressureBar,
      'water_treatment_status': waterTreatmentStatus,
      'burner_control_status': burnerControlStatus,
      'engineer_name': engineerName,
      'engineer_license_no': engineerLicenseNo,
      'contractor_company': contractorCompany,
      'inspection_date': inspectionDate.toIso8601String().substring(0, 10),
      'expiry_date': expiryDate.toIso8601String().substring(0, 10),
      'overall_result': overallResult,
      'defects_found': defectsFound,
      'corrective_actions': correctiveActions,
      'report_pdf_path': reportPdfPath,
      'engineer_license_pdf_path': engineerLicensePdfPath,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  factory BoilerInspectionModel.fromMap(Map<String, dynamic> map) {
    return BoilerInspectionModel(
      id: map['id'] as int?,
      boilerName: map['boiler_name'] as String? ?? '',
      boilerTag: map['boiler_tag'] as String? ?? '',
      boilerType: map['boiler_type'] as String? ?? 'STEAM_BOILER',
      capacityTonHr: (map['capacity_ton_hr'] as num?)?.toDouble(),
      locationBuilding: map['location_building'] as String? ?? '',
      locationArea: map['location_area'] as String?,
      maxAllowableWorkingPressureBar: (map['max_allowable_working_pressure_bar'] as num?)?.toDouble() ?? 0.0,
      hydroTestPressureBar: (map['hydro_test_pressure_bar'] as num?)?.toDouble(),
      hydroTestResult: map['hydro_test_result'] as String? ?? 'PASS',
      safetyValveTestResult: map['safety_valve_test_result'] as String? ?? 'PASS',
      safetyValvePopPressureBar: (map['safety_valve_pop_pressure_bar'] as num?)?.toDouble(),
      waterTreatmentStatus: map['water_treatment_status'] as String? ?? 'PASS',
      burnerControlStatus: map['burner_control_status'] as String? ?? 'PASS',
      engineerName: map['engineer_name'] as String? ?? '',
      engineerLicenseNo: map['engineer_license_no'] as String? ?? '',
      contractorCompany: map['contractor_company'] as String?,
      inspectionDate: DateTime.tryParse(map['inspection_date'] as String? ?? '') ?? DateTime.now(),
      expiryDate: DateTime.tryParse(map['expiry_date'] as String? ?? '') ?? DateTime.now(),
      overallResult: map['overall_result'] as String? ?? 'PASS',
      defectsFound: map['defects_found'] as String?,
      correctiveActions: map['corrective_actions'] as String?,
      reportPdfPath: map['report_pdf_path'] as String?,
      engineerLicensePdfPath: map['engineer_license_pdf_path'] as String?,
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at'] as String) : null,
      updatedAt: map['updated_at'] != null ? DateTime.tryParse(map['updated_at'] as String) : null,
    );
  }

  BoilerInspectionModel copyWith({
    int? id,
    String? boilerName,
    String? boilerTag,
    String? boilerType,
    double? capacityTonHr,
    String? locationBuilding,
    String? locationArea,
    double? maxAllowableWorkingPressureBar,
    double? hydroTestPressureBar,
    String? hydroTestResult,
    String? safetyValveTestResult,
    double? safetyValvePopPressureBar,
    String? waterTreatmentStatus,
    String? burnerControlStatus,
    String? engineerName,
    String? engineerLicenseNo,
    String? contractorCompany,
    DateTime? inspectionDate,
    DateTime? expiryDate,
    String? overallResult,
    String? defectsFound,
    String? correctiveActions,
    String? reportPdfPath,
    String? engineerLicensePdfPath,
  }) {
    return BoilerInspectionModel(
      id: id ?? this.id,
      boilerName: boilerName ?? this.boilerName,
      boilerTag: boilerTag ?? this.boilerTag,
      boilerType: boilerType ?? this.boilerType,
      capacityTonHr: capacityTonHr ?? this.capacityTonHr,
      locationBuilding: locationBuilding ?? this.locationBuilding,
      locationArea: locationArea ?? this.locationArea,
      maxAllowableWorkingPressureBar: maxAllowableWorkingPressureBar ?? this.maxAllowableWorkingPressureBar,
      hydroTestPressureBar: hydroTestPressureBar ?? this.hydroTestPressureBar,
      hydroTestResult: hydroTestResult ?? this.hydroTestResult,
      safetyValveTestResult: safetyValveTestResult ?? this.safetyValveTestResult,
      safetyValvePopPressureBar: safetyValvePopPressureBar ?? this.safetyValvePopPressureBar,
      waterTreatmentStatus: waterTreatmentStatus ?? this.waterTreatmentStatus,
      burnerControlStatus: burnerControlStatus ?? this.burnerControlStatus,
      engineerName: engineerName ?? this.engineerName,
      engineerLicenseNo: engineerLicenseNo ?? this.engineerLicenseNo,
      contractorCompany: contractorCompany ?? this.contractorCompany,
      inspectionDate: inspectionDate ?? this.inspectionDate,
      expiryDate: expiryDate ?? this.expiryDate,
      overallResult: overallResult ?? this.overallResult,
      defectsFound: defectsFound ?? this.defectsFound,
      correctiveActions: correctiveActions ?? this.correctiveActions,
      reportPdfPath: reportPdfPath ?? this.reportPdfPath,
      engineerLicensePdfPath: engineerLicensePdfPath ?? this.engineerLicensePdfPath,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
