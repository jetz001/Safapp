import 'dart:convert';

class EmployeeHealthRecord {
  final int? id;
  final int employeeId;
  final String checkupType; // PRE_EMPLOYMENT, ANNUAL, RISK_BASED, JOB_CHANGE, RETURN_TO_WORK
  final String checkupDate;
  final String hospitalName;
  final String? doctorName;
  final String? doctorLicenseNo;
  final String overallResult; // NORMAL, WATCH, ABNORMAL, PENDING

  // Vitals
  final double? weight;
  final double? height;
  final double? bmi;
  final int? bpSystolic;
  final int? bpDiastolic;
  final int? pulse;

  // General & Lab
  final String physicalExamResult; // NORMAL, ABNORMAL
  final String? physicalExamNotes;
  final String chestXrayResult; // NORMAL, ABNORMAL, NOT_TESTED
  final String audiogramResult; // NORMAL, ABNORMAL, NOT_TESTED
  final String spirometryResult; // NORMAL, ABNORMAL, NOT_TESTED
  final String visionTestResult; // NORMAL, ABNORMAL, NOT_TESTED
  final String bloodCbcResult; // NORMAL, ABNORMAL, NOT_TESTED
  final String bloodSugarResult; // NORMAL, ABNORMAL, NOT_TESTED
  final String liverFunctionResult; // NORMAL, ABNORMAL, NOT_TESTED
  final String kidneyFunctionResult; // NORMAL, ABNORMAL, NOT_TESTED
  final String urineExamResult; // NORMAL, ABNORMAL, NOT_TESTED
  final String drugScreeningResult; // NEGATIVE, POSITIVE, NOT_TESTED

  // Risk Factors (ตามประกาศกระทรวง)
  final List<String> riskFactorsTested;
  final Map<String, String> riskFactorResults; // e.g. {"Toluene": "NORMAL", "Noise": "ABNORMAL"}

  // Doctor Assessment
  final String? doctorOpinion;
  final String fitnessToWork; // FIT, FIT_WITH_RESTRICTION, UNFIT, PENDING
  final String? pdfFilePath; // Single employee medical report PDF
  final String? createdAt;
  final String? updatedAt;

  // From Joins
  final String? employeeCode;
  final String? employeeName;
  final String? department;
  final String? position;
  final String? nationalId;
  final String? photoPath;

  EmployeeHealthRecord({
    this.id,
    required this.employeeId,
    required this.checkupType,
    required this.checkupDate,
    required this.hospitalName,
    this.doctorName,
    this.doctorLicenseNo,
    this.overallResult = 'NORMAL',
    this.weight,
    this.height,
    this.bmi,
    this.bpSystolic,
    this.bpDiastolic,
    this.pulse,
    this.physicalExamResult = 'NORMAL',
    this.physicalExamNotes,
    this.chestXrayResult = 'NORMAL',
    this.audiogramResult = 'NOT_TESTED',
    this.spirometryResult = 'NOT_TESTED',
    this.visionTestResult = 'NORMAL',
    this.bloodCbcResult = 'NORMAL',
    this.bloodSugarResult = 'NORMAL',
    this.liverFunctionResult = 'NORMAL',
    this.kidneyFunctionResult = 'NORMAL',
    this.urineExamResult = 'NORMAL',
    this.drugScreeningResult = 'NEGATIVE',
    this.riskFactorsTested = const [],
    this.riskFactorResults = const {},
    this.doctorOpinion,
    this.fitnessToWork = 'FIT',
    this.pdfFilePath,
    this.createdAt,
    this.updatedAt,
    this.employeeCode,
    this.employeeName,
    this.department,
    this.position,
    this.nationalId,
    this.photoPath,
  });

  String get checkupTypeLabel {
    switch (checkupType) {
      case 'PRE_EMPLOYMENT':
        return 'ตรวจก่อนเข้างาน (Pre-employment)';
      case 'ANNUAL':
        return 'ตรวจสุขภาพประจำปี (Annual)';
      case 'RISK_BASED':
        return 'ตรวจตามปัจจัยเสี่ยง (Risk-based)';
      case 'JOB_CHANGE':
        return 'ตรวจเมื่อเปลี่ยนงาน (Job Change)';
      case 'RETURN_TO_WORK':
        return 'ตรวจก่อนกลับเข้าทำงาน (Return to Work)';
      default:
        return 'ตรวจสุขภาพทั่วไป';
    }
  }

  String get overallResultLabel {
    switch (overallResult) {
      case 'NORMAL':
        return '🟢 ปกติ (Normal)';
      case 'WATCH':
        return '🟡 เฝ้าระวัง (Watch)';
      case 'ABNORMAL':
        return '🔴 ผิดปกติ (Abnormal)';
      case 'PENDING':
      default:
        return '⚪ รอผลตรวจ (Pending)';
    }
  }

  String get overallResultPlainLabel {
    switch (overallResult) {
      case 'NORMAL':
        return 'ปกติ (Normal)';
      case 'WATCH':
        return 'เฝ้าระวัง (Watch)';
      case 'ABNORMAL':
        return 'ผิดปกติ (Abnormal)';
      case 'PENDING':
      default:
        return 'รอผลตรวจ (Pending)';
    }
  }

  String get fitnessLabel {
    switch (fitnessToWork) {
      case 'FIT':
        return 'พร้อมทำงาน (Fit for Duty)';
      case 'FIT_WITH_RESTRICTION':
        return 'พร้อมทำงานแบบมีเงื่อนไข (Fit with Restriction)';
      case 'UNFIT':
        return 'ไม่พร้อมทำงานชั่วคราว (Unfit)';
      case 'PENDING':
      default:
        return 'รอผลประเมิน (Pending)';
    }
  }

  String get bpReading {
    if (bpSystolic != null && bpDiastolic != null) {
      return '$bpSystolic/$bpDiastolic mmHg';
    }
    return '-';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'employee_id': employeeId,
      'checkup_type': checkupType,
      'checkup_date': checkupDate,
      'hospital_name': hospitalName,
      'doctor_name': doctorName,
      'doctor_license_no': doctorLicenseNo,
      'overall_result': overallResult,
      'weight': weight,
      'height': height,
      'bmi': bmi,
      'bp_systolic': bpSystolic,
      'bp_diastolic': bpDiastolic,
      'pulse': pulse,
      'physical_exam_result': physicalExamResult,
      'physical_exam_notes': physicalExamNotes,
      'chest_xray_result': chestXrayResult,
      'audiogram_result': audiogramResult,
      'spirometry_result': spirometryResult,
      'vision_test_result': visionTestResult,
      'blood_cbc_result': bloodCbcResult,
      'blood_sugar_result': bloodSugarResult,
      'liver_function_result': liverFunctionResult,
      'kidney_function_result': kidneyFunctionResult,
      'urine_exam_result': urineExamResult,
      'drug_screening_result': drugScreeningResult,
      'risk_factors_tested': jsonEncode(riskFactorsTested),
      'risk_factor_results': jsonEncode(riskFactorResults),
      'doctor_opinion': doctorOpinion,
      'fitness_to_work': fitnessToWork,
      'pdf_file_path': pdfFilePath,
    };
  }

  factory EmployeeHealthRecord.fromMap(Map<String, dynamic> map) {
    List<String> parseList(dynamic val) {
      if (val == null) return [];
      if (val is List) return val.map((e) => e.toString()).toList();
      if (val is String && val.isNotEmpty) {
        try {
          final decoded = jsonDecode(val) as List<dynamic>;
          return decoded.map((e) => e.toString()).toList();
        } catch (_) {}
      }
      return [];
    }

    Map<String, String> parseMap(dynamic val) {
      if (val == null) return {};
      if (val is Map) return Map<String, String>.from(val);
      if (val is String && val.isNotEmpty) {
        try {
          final decoded = jsonDecode(val) as Map<String, dynamic>;
          return decoded.map((k, v) => MapEntry(k, v.toString()));
        } catch (_) {}
      }
      return {};
    }

    return EmployeeHealthRecord(
      id: map['id'] as int?,
      employeeId: map['employee_id'] as int,
      checkupType: map['checkup_type'] as String? ?? 'ANNUAL',
      checkupDate: map['checkup_date'] as String? ?? '',
      hospitalName: map['hospital_name'] as String? ?? '',
      doctorName: map['doctor_name'] as String?,
      doctorLicenseNo: map['doctor_license_no'] as String?,
      overallResult: map['overall_result'] as String? ?? 'NORMAL',
      weight: (map['weight'] as num?)?.toDouble(),
      height: (map['height'] as num?)?.toDouble(),
      bmi: (map['bmi'] as num?)?.toDouble(),
      bpSystolic: map['bp_systolic'] as int?,
      bpDiastolic: map['bp_diastolic'] as int?,
      pulse: map['pulse'] as int?,
      physicalExamResult: map['physical_exam_result'] as String? ?? 'NORMAL',
      physicalExamNotes: map['physical_exam_notes'] as String?,
      chestXrayResult: map['chest_xray_result'] as String? ?? 'NORMAL',
      audiogramResult: map['audiogram_result'] as String? ?? 'NOT_TESTED',
      spirometryResult: map['spirometry_result'] as String? ?? 'NOT_TESTED',
      visionTestResult: map['vision_test_result'] as String? ?? 'NORMAL',
      bloodCbcResult: map['blood_cbc_result'] as String? ?? 'NORMAL',
      bloodSugarResult: map['blood_sugar_result'] as String? ?? 'NORMAL',
      liverFunctionResult: map['liver_function_result'] as String? ?? 'NORMAL',
      kidneyFunctionResult: map['kidney_function_result'] as String? ?? 'NORMAL',
      urineExamResult: map['urine_exam_result'] as String? ?? 'NORMAL',
      drugScreeningResult: map['drug_screening_result'] as String? ?? 'NEGATIVE',
      riskFactorsTested: parseList(map['risk_factors_tested']),
      riskFactorResults: parseMap(map['risk_factor_results']),
      doctorOpinion: map['doctor_opinion'] as String?,
      fitnessToWork: map['fitness_to_work'] as String? ?? 'FIT',
      pdfFilePath: map['pdf_file_path'] as String?,
      createdAt: map['created_at'] as String?,
      updatedAt: map['updated_at'] as String?,
      employeeCode: map['employee_code'] as String?,
      employeeName: map['full_name'] as String?,
      department: map['department'] as String?,
      position: map['position'] as String?,
      nationalId: map['national_id'] as String?,
      photoPath: map['photo_path'] as String?,
    );
  }

  EmployeeHealthRecord copyWith({
    int? id,
    int? employeeId,
    String? checkupType,
    String? checkupDate,
    String? hospitalName,
    String? doctorName,
    String? doctorLicenseNo,
    String? overallResult,
    double? weight,
    double? height,
    double? bmi,
    int? bpSystolic,
    int? bpDiastolic,
    int? pulse,
    String? physicalExamResult,
    String? physicalExamNotes,
    String? chestXrayResult,
    String? audiogramResult,
    String? spirometryResult,
    String? visionTestResult,
    String? bloodCbcResult,
    String? bloodSugarResult,
    String? liverFunctionResult,
    String? kidneyFunctionResult,
    String? urineExamResult,
    String? drugScreeningResult,
    List<String>? riskFactorsTested,
    Map<String, String>? riskFactorResults,
    String? doctorOpinion,
    String? fitnessToWork,
    String? pdfFilePath,
  }) {
    return EmployeeHealthRecord(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      checkupType: checkupType ?? this.checkupType,
      checkupDate: checkupDate ?? this.checkupDate,
      hospitalName: hospitalName ?? this.hospitalName,
      doctorName: doctorName ?? this.doctorName,
      doctorLicenseNo: doctorLicenseNo ?? this.doctorLicenseNo,
      overallResult: overallResult ?? this.overallResult,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      bmi: bmi ?? this.bmi,
      bpSystolic: bpSystolic ?? this.bpSystolic,
      bpDiastolic: bpDiastolic ?? this.bpDiastolic,
      pulse: pulse ?? this.pulse,
      physicalExamResult: physicalExamResult ?? this.physicalExamResult,
      physicalExamNotes: physicalExamNotes ?? this.physicalExamNotes,
      chestXrayResult: chestXrayResult ?? this.chestXrayResult,
      audiogramResult: audiogramResult ?? this.audiogramResult,
      spirometryResult: spirometryResult ?? this.spirometryResult,
      visionTestResult: visionTestResult ?? this.visionTestResult,
      bloodCbcResult: bloodCbcResult ?? this.bloodCbcResult,
      bloodSugarResult: bloodSugarResult ?? this.bloodSugarResult,
      liverFunctionResult: liverFunctionResult ?? this.liverFunctionResult,
      kidneyFunctionResult: kidneyFunctionResult ?? this.kidneyFunctionResult,
      urineExamResult: urineExamResult ?? this.urineExamResult,
      drugScreeningResult: drugScreeningResult ?? this.drugScreeningResult,
      riskFactorsTested: riskFactorsTested ?? this.riskFactorsTested,
      riskFactorResults: riskFactorResults ?? this.riskFactorResults,
      doctorOpinion: doctorOpinion ?? this.doctorOpinion,
      fitnessToWork: fitnessToWork ?? this.fitnessToWork,
      pdfFilePath: pdfFilePath ?? this.pdfFilePath,
      createdAt: createdAt,
      updatedAt: updatedAt,
      employeeCode: employeeCode ?? this.employeeCode,
      employeeName: employeeName ?? this.employeeName,
      department: department ?? this.department,
      position: position ?? this.position,
      nationalId: nationalId ?? this.nationalId,
      photoPath: photoPath ?? this.photoPath,
    );
  }
}

class CompanyHealthBulkReport {
  final int? id;
  final String reportYear;
  final String reportTitle;
  final String hospitalName;
  final String checkupDate;
  final int totalEmployeesTested;
  final int normalCount;
  final int abnormalCount;
  final int watchCount;
  final String? summaryNotes;
  final String pdfFilePath;
  final String? createdAt;

  CompanyHealthBulkReport({
    this.id,
    required this.reportYear,
    required this.reportTitle,
    required this.hospitalName,
    required this.checkupDate,
    this.totalEmployeesTested = 0,
    this.normalCount = 0,
    this.abnormalCount = 0,
    this.watchCount = 0,
    this.summaryNotes,
    required this.pdfFilePath,
    this.createdAt,
  });

  double get normalPercentage => totalEmployeesTested > 0 ? (normalCount / totalEmployeesTested) * 100 : 0.0;
  double get abnormalPercentage => totalEmployeesTested > 0 ? (abnormalCount / totalEmployeesTested) * 100 : 0.0;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'report_year': reportYear,
      'report_title': reportTitle,
      'hospital_name': hospitalName,
      'checkup_date': checkupDate,
      'total_employees_tested': totalEmployeesTested,
      'normal_count': normalCount,
      'abnormal_count': abnormalCount,
      'watch_count': watchCount,
      'summary_notes': summaryNotes,
      'pdf_file_path': pdfFilePath,
    };
  }

  factory CompanyHealthBulkReport.fromMap(Map<String, dynamic> map) {
    return CompanyHealthBulkReport(
      id: map['id'] as int?,
      reportYear: map['report_year'] as String? ?? '',
      reportTitle: map['report_title'] as String? ?? '',
      hospitalName: map['hospital_name'] as String? ?? '',
      checkupDate: map['checkup_date'] as String? ?? '',
      totalEmployeesTested: map['total_employees_tested'] as int? ?? 0,
      normalCount: map['normal_count'] as int? ?? 0,
      abnormalCount: map['abnormal_count'] as int? ?? 0,
      watchCount: map['watch_count'] as int? ?? 0,
      summaryNotes: map['summary_notes'] as String?,
      pdfFilePath: map['pdf_file_path'] as String? ?? '',
      createdAt: map['created_at'] as String?,
    );
  }
}

class MedicalSurveillanceFollowup {
  final int? id;
  final int healthRecordId;
  final int employeeId;
  final String abnormalSymptom;
  final String followupActionType; // REPEAT_TEST, MEDICAL_TREATMENT, JOB_TRANSFER, WORK_ENVIRONMENT_FIX, SPECIALIST_CONSULT
  final String actionDetails;
  final String? treatmentHospital;
  final String targetDate;
  final String? completedDate;
  final String status; // OPEN, IN_PROGRESS, RESOLVED
  final String? notes;
  final String? createdAt;

  // From Joins
  final String? employeeCode;
  final String? employeeName;
  final String? department;
  final String? checkupDate;

  MedicalSurveillanceFollowup({
    this.id,
    required this.healthRecordId,
    required this.employeeId,
    required this.abnormalSymptom,
    required this.followupActionType,
    required this.actionDetails,
    this.treatmentHospital,
    required this.targetDate,
    this.completedDate,
    this.status = 'OPEN',
    this.notes,
    this.createdAt,
    this.employeeCode,
    this.employeeName,
    this.department,
    this.checkupDate,
  });

  String get actionTypeLabel {
    switch (followupActionType) {
      case 'REPEAT_TEST':
        return '🔄 ส่งตรวจซ้ำ (Repeat Test)';
      case 'MEDICAL_TREATMENT':
        return '💊 ส่งรักษาพยาบาล (Medical Treatment)';
      case 'JOB_TRANSFER':
        return '🔁 ปรับเปลี่ยนหน้าที่งาน (Job Transfer)';
      case 'WORK_ENVIRONMENT_FIX':
        return '🛠️ ปรับปรุงสภาพแวดล้อม (Environment Fix)';
      case 'SPECIALIST_CONSULT':
      default:
        return '👨‍⚕️ ปรึกษาแพทย์เฉพาะทาง (Specialist Consult)';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'health_record_id': healthRecordId,
      'employee_id': employeeId,
      'abnormal_symptom': abnormalSymptom,
      'followup_action_type': followupActionType,
      'action_details': actionDetails,
      'treatment_hospital': treatmentHospital,
      'target_date': targetDate,
      'completed_date': completedDate,
      'status': status,
      'notes': notes,
    };
  }

  factory MedicalSurveillanceFollowup.fromMap(Map<String, dynamic> map) {
    return MedicalSurveillanceFollowup(
      id: map['id'] as int?,
      healthRecordId: map['health_record_id'] as int,
      employeeId: map['employee_id'] as int,
      abnormalSymptom: map['abnormal_symptom'] as String? ?? '',
      followupActionType: map['followup_action_type'] as String? ?? 'REPEAT_TEST',
      actionDetails: map['action_details'] as String? ?? '',
      treatmentHospital: map['treatment_hospital'] as String?,
      targetDate: map['target_date'] as String? ?? '',
      completedDate: map['completed_date'] as String?,
      status: map['status'] as String? ?? 'OPEN',
      notes: map['notes'] as String?,
      createdAt: map['created_at'] as String?,
      employeeCode: map['employee_code'] as String?,
      employeeName: map['full_name'] as String?,
      department: map['department'] as String?,
      checkupDate: map['checkup_date'] as String?,
    );
  }
}
