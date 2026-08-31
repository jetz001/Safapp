/// ข้อมูลสถานประกอบกิจการและผู้ชำนาญการ ม.๓๓
class CompanyProfile {
  final int? id;
  final String companyName;
  final String? employerName;
  final String? taxId;
  final int businessCategorySchedule; // 1 = บัญชี ๑, 2 = บัญชี ๒
  final int? businessCategoryNumber;
  final String? businessCategoryTitle;
  final int employeeCount;
  final String? addressNumber;
  final String? moo;
  final String? soi;
  final String? road;
  final String? subdistrict;
  final String? district;
  final String? province;
  final String? postalCode;
  final String? phone;
  final String? fax;
  final String? mobile;
  final String? safetyExpertName;
  final String? safetyExpertLicenseNo;
  final String? safetyExpertValidFrom;
  final String? safetyExpertValidTo;
  final String? safetyExpertSignaturePath;
  final String? employerSignaturePath;
  final String? safetyPolicy;
  final double? areaSqm;
  final String? logoPath;
  final String? safetyOfficerName;
  final String? safetyOfficerLevel;
  final String? safetyOfficerCertNo;
  final String? safetyOfficerPhone;

  CompanyProfile({
    this.id,
    required this.companyName,
    this.employerName,
    this.taxId,
    this.businessCategorySchedule = 2,
    this.businessCategoryNumber,
    this.businessCategoryTitle,
    this.employeeCount = 0,
    this.addressNumber,
    this.moo,
    this.soi,
    this.road,
    this.subdistrict,
    this.district,
    this.province,
    this.postalCode,
    this.phone,
    this.fax,
    this.mobile,
    this.safetyExpertName,
    this.safetyExpertLicenseNo,
    this.safetyExpertValidFrom,
    this.safetyExpertValidTo,
    this.safetyExpertSignaturePath,
    this.employerSignaturePath,
    this.safetyPolicy,
    this.areaSqm,
    this.logoPath,
    this.safetyOfficerName,
    this.safetyOfficerLevel,
    this.safetyOfficerCertNo,
    this.safetyOfficerPhone,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'company_name': companyName,
      'employer_name': employerName,
      'tax_id': taxId,
      'business_category_schedule': businessCategorySchedule,
      'business_category_number': businessCategoryNumber,
      'business_category_title': businessCategoryTitle,
      'employee_count': employeeCount,
      'address_number': addressNumber,
      'moo': moo,
      'soi': soi,
      'road': road,
      'subdistrict': subdistrict,
      'district': district,
      'province': province,
      'postal_code': postalCode,
      'phone': phone,
      'fax': fax,
      'mobile': mobile,
      'safety_expert_name': safetyExpertName,
      'safety_expert_license_no': safetyExpertLicenseNo,
      'safety_expert_valid_from': safetyExpertValidFrom,
      'safety_expert_valid_to': safetyExpertValidTo,
      'safety_expert_signature_path': safetyExpertSignaturePath,
      'employer_signature_path': employerSignaturePath,
      'safety_policy': safetyPolicy,
      'area_sqm': areaSqm,
      'logo_path': logoPath,
      'safety_officer_name': safetyOfficerName,
      'safety_officer_level': safetyOfficerLevel,
      'safety_officer_cert_no': safetyOfficerCertNo,
      'safety_officer_phone': safetyOfficerPhone,
    };
  }

  factory CompanyProfile.fromMap(Map<String, dynamic> map) {
    return CompanyProfile(
      id: map['id'] as int?,
      companyName: (map['company_name'] as String?) ?? '',
      employerName: map['employer_name'] as String?,
      taxId: map['tax_id'] as String?,
      businessCategorySchedule: (map['business_category_schedule'] as int?) ?? 2,
      businessCategoryNumber: map['business_category_number'] as int?,
      businessCategoryTitle: map['business_category_title'] as String?,
      employeeCount: (map['employee_count'] as int?) ?? 0,
      addressNumber: map['address_number'] as String?,
      moo: map['moo'] as String?,
      soi: map['soi'] as String?,
      road: map['road'] as String?,
      subdistrict: map['subdistrict'] as String?,
      district: map['district'] as String?,
      province: map['province'] as String?,
      postalCode: map['postal_code'] as String?,
      phone: map['phone'] as String?,
      fax: map['fax'] as String?,
      mobile: map['mobile'] as String?,
      safetyExpertName: map['safety_expert_name'] as String?,
      safetyExpertLicenseNo: map['safety_expert_license_no'] as String?,
      safetyExpertValidFrom: map['safety_expert_valid_from'] as String?,
      safetyExpertValidTo: map['safety_expert_valid_to'] as String?,
      safetyExpertSignaturePath: map['safety_expert_signature_path'] as String?,
      employerSignaturePath: map['employer_signature_path'] as String?,
      safetyPolicy: map['safety_policy'] as String?,
      areaSqm: (map['area_sqm'] as num?)?.toDouble(),
      logoPath: map['logo_path'] as String?,
      safetyOfficerName: map['safety_officer_name'] as String?,
      safetyOfficerLevel: map['safety_officer_level'] as String?,
      safetyOfficerCertNo: map['safety_officer_cert_no'] as String?,
      safetyOfficerPhone: map['safety_officer_phone'] as String?,
    );
  }

  String get fullAddress {
    final parts = <String>[];
    if (addressNumber != null && addressNumber!.isNotEmpty) parts.add('เลขที่ $addressNumber');
    if (moo != null && moo!.isNotEmpty) parts.add('หมู่ $moo');
    if (soi != null && soi!.isNotEmpty) parts.add('ซอย$soi');
    if (road != null && road!.isNotEmpty) parts.add('ถนน$road');
    if (subdistrict != null && subdistrict!.isNotEmpty) parts.add('ตำบล/แขวง $subdistrict');
    if (district != null && district!.isNotEmpty) parts.add('อำเภอ/เขต $district');
    if (province != null && province!.isNotEmpty) parts.add('จังหวัด $province');
    if (postalCode != null && postalCode!.isNotEmpty) parts.add(postalCode!);
    return parts.join(' ');
  }
}

/// ชุดการประเมินอันตราย (Session)
class RiskAssessmentSession {
  final int? id;
  final String sessionTitle;
  final String assessmentType; // 'PERIODIC' (รอบ 3 ปี) หรือ 'MOC' (รอบปรับปรุงเปลี่ยนแปลง 30 วัน)
  final String assessmentDate; // YYYY-MM-DD
  final String? nextReviewDate; // YYYY-MM-DD
  final String hazardIdMethod;
  final String? hazardIdMethodOther;
  final String? hazardIdStandardApproved;
  final String? assessor1Name;
  final String? assessor1Position;
  final String? assessor2Name;
  final String? assessor2Position;
  final String? expertOpinion;
  final String status; // 'DRAFT', 'ENDORSED', 'SUBMITTED'
  final String? createdAt;
  final String? updatedAt;

  RiskAssessmentSession({
    this.id,
    required this.sessionTitle,
    this.assessmentType = 'PERIODIC',
    required this.assessmentDate,
    this.nextReviewDate,
    this.hazardIdMethod = 'การวิเคราะห์งานเพื่อความปลอดภัย (Job Safety Analysis : JSA)',
    this.hazardIdMethodOther,
    this.hazardIdStandardApproved,
    this.assessor1Name,
    this.assessor1Position,
    this.assessor2Name,
    this.assessor2Position,
    this.expertOpinion,
    this.status = 'DRAFT',
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'session_title': sessionTitle,
      'assessment_type': assessmentType,
      'assessment_date': assessmentDate,
      'next_review_date': nextReviewDate,
      'hazard_id_method': hazardIdMethod,
      'hazard_id_method_other': hazardIdMethodOther,
      'hazard_id_standard_approved': hazardIdStandardApproved,
      'assessor_1_name': assessor1Name,
      'assessor_1_position': assessor1Position,
      'assessor_2_name': assessor2Name,
      'assessor_2_position': assessor2Position,
      'expert_opinion': expertOpinion,
      'status': status,
    };
  }

  factory RiskAssessmentSession.fromMap(Map<String, dynamic> map) {
    return RiskAssessmentSession(
      id: map['id'] as int?,
      sessionTitle: (map['session_title'] as String?) ?? '',
      assessmentType: (map['assessment_type'] as String?) ?? 'PERIODIC',
      assessmentDate: (map['assessment_date'] as String?) ?? '',
      nextReviewDate: map['next_review_date'] as String?,
      hazardIdMethod: (map['hazard_id_method'] as String?) ?? 'การวิเคราะห์งานเพื่อความปลอดภัย (Job Safety Analysis : JSA)',
      hazardIdMethodOther: map['hazard_id_method_other'] as String?,
      hazardIdStandardApproved: map['hazard_id_standard_approved'] as String?,
      assessor1Name: map['assessor_1_name'] as String?,
      assessor1Position: map['assessor_1_position'] as String?,
      assessor2Name: map['assessor_2_name'] as String?,
      assessor2Position: map['assessor_2_position'] as String?,
      expertOpinion: map['expert_opinion'] as String?,
      status: (map['status'] as String?) ?? 'DRAFT',
      createdAt: map['created_at'] as String?,
      updatedAt: map['updated_at'] as String?,
    );
  }
}

/// สถานีงาน / กระบวนการ / พื้นที่ปฏิบัติงาน
class WorkStation {
  final int? id;
  final int sessionId;
  final String departmentName;
  final String stationName;
  final int employeeCount;
  final String? description;
  final int sortOrder;

  WorkStation({
    this.id,
    required this.sessionId,
    required this.departmentName,
    required this.stationName,
    this.employeeCount = 1,
    this.description,
    this.sortOrder = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'session_id': sessionId,
      'department_name': departmentName,
      'station_name': stationName,
      'employee_count': employeeCount,
      'description': description,
      'sort_order': sortOrder,
    };
  }

  factory WorkStation.fromMap(Map<String, dynamic> map) {
    return WorkStation(
      id: map['id'] as int?,
      sessionId: (map['session_id'] as int?) ?? 0,
      departmentName: (map['department_name'] as String?) ?? '',
      stationName: (map['station_name'] as String?) ?? '',
      employeeCount: (map['employee_count'] as int?) ?? 1,
      description: map['description'] as String?,
      sortOrder: (map['sort_order'] as int?) ?? 0,
    );
  }
}

/// ขั้นตอนการทำงาน / เครื่องจักร / อุปกรณ์
class WorkStepItem {
  final int? id;
  final int workstationId;
  final int stepNumber;
  final String stepName;
  final String? relatedMachineryEquipment;
  final String? description;
  final int sortOrder;

  WorkStepItem({
    this.id,
    required this.workstationId,
    this.stepNumber = 1,
    required this.stepName,
    this.relatedMachineryEquipment,
    this.description,
    this.sortOrder = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'workstation_id': workstationId,
      'step_number': stepNumber,
      'step_name': stepName,
      'related_machinery_equipment': relatedMachineryEquipment,
      'description': description,
      'sort_order': sortOrder,
    };
  }

  factory WorkStepItem.fromMap(Map<String, dynamic> map) {
    return WorkStepItem(
      id: map['id'] as int?,
      workstationId: (map['workstation_id'] as int?) ?? 0,
      stepNumber: (map['step_number'] as int?) ?? 1,
      stepName: (map['step_name'] as String?) ?? '',
      relatedMachineryEquipment: map['related_machinery_equipment'] as String?,
      description: map['description'] as String?,
      sortOrder: (map['sort_order'] as int?) ?? 0,
    );
  }
}

/// รายการชี้บ่งอันตรายและการประเมินความเสี่ยง (แบบ ปอ. ๑)
class HazardEvaluationPor1 {
  final int? id;
  final int stepId;
  final String hazardItemTitle; // สิ่งและลักษณะอันตราย
  final String potentialConsequences; // ผลกระทบที่อาจเกิดขึ้น
  final String? existingControlMeasures; // มาตรการป้องกันและควบคุมอันตราย
  final String? recommendation; // ข้อเสนอแนะ
  final int likelihoodScore; // 1-3
  final int severityScore; // 1-3
  final int riskScore; // L x S
  final String riskLevel; // VERY_LOW, LOW, MEDIUM, HIGH, VERY_HIGH
  final String riskLevelThai; // ต่ำมาก, ต่ำ, ปานกลาง, สูง, สูงมาก
  final bool requiresPor2;
  final String? createdAt;

  HazardEvaluationPor1({
    this.id,
    required this.stepId,
    required this.hazardItemTitle,
    required this.potentialConsequences,
    this.existingControlMeasures,
    this.recommendation,
    required this.likelihoodScore,
    required this.severityScore,
    required this.riskScore,
    required this.riskLevel,
    required this.riskLevelThai,
    required this.requiresPor2,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'step_id': stepId,
      'hazard_item_title': hazardItemTitle,
      'potential_consequences': potentialConsequences,
      'existing_control_measures': existingControlMeasures,
      'recommendation': recommendation,
      'likelihood_score': likelihoodScore,
      'severity_score': severityScore,
      'risk_score': riskScore,
      'risk_level': riskLevel,
      'risk_level_thai': riskLevelThai,
      'requires_por2': requiresPor2 ? 1 : 0,
    };
  }

  factory HazardEvaluationPor1.fromMap(Map<String, dynamic> map) {
    return HazardEvaluationPor1(
      id: map['id'] as int?,
      stepId: (map['step_id'] as int?) ?? 0,
      hazardItemTitle: (map['hazard_item_title'] as String?) ?? '',
      potentialConsequences: (map['potential_consequences'] as String?) ?? '',
      existingControlMeasures: map['existing_control_measures'] as String?,
      recommendation: map['recommendation'] as String?,
      likelihoodScore: (map['likelihood_score'] as int?) ?? 1,
      severityScore: (map['severity_score'] as int?) ?? 1,
      riskScore: (map['risk_score'] as int?) ?? 1,
      riskLevel: (map['risk_level'] as String?) ?? 'VERY_LOW',
      riskLevelThai: (map['risk_level_thai'] as String?) ?? 'ระดับต่ำมาก',
      requiresPor2: (map['requires_por2'] as int?) == 1,
      createdAt: map['created_at'] as String?,
    );
  }
}

/// แผนดำเนินงานด้านความปลอดภัยและแผนควบคุมดูแลลูกจ้าง (แบบ ปอ. ๒)
class RiskControlPlanPor2 {
  final int? id;
  final int hazardId;
  final String controlPlanDescription; // มาตรการ/กิจกรรม/ขั้นตอน/หลักเกณฑ์หรือมาตรฐานที่ใช้ควบคุม
  final String? startDate; // ตั้งแต่วันที่
  final String? endDate; // ถึงวันที่
  final String responsiblePerson; // ผู้รับผิดชอบ
  final String supervisorMonitor; // ผู้ตรวจติดตาม
  final int? actionTrackerId;
  final String status; // 'PLANNED', 'IN_PROGRESS', 'COMPLETED'
  final String? createdAt;

  RiskControlPlanPor2({
    this.id,
    required this.hazardId,
    required this.controlPlanDescription,
    this.startDate,
    this.endDate,
    required this.responsiblePerson,
    required this.supervisorMonitor,
    this.actionTrackerId,
    this.status = 'PLANNED',
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'hazard_id': hazardId,
      'control_plan_description': controlPlanDescription,
      'start_date': startDate,
      'end_date': endDate,
      'responsible_person': responsiblePerson,
      'supervisor_monitor': supervisorMonitor,
      'action_tracker_id': actionTrackerId,
      'status': status,
    };
  }

  factory RiskControlPlanPor2.fromMap(Map<String, dynamic> map) {
    return RiskControlPlanPor2(
      id: map['id'] as int?,
      hazardId: (map['hazard_id'] as int?) ?? 0,
      controlPlanDescription: (map['control_plan_description'] as String?) ?? '',
      startDate: map['start_date'] as String?,
      endDate: map['end_date'] as String?,
      responsiblePerson: (map['responsible_person'] as String?) ?? '',
      supervisorMonitor: (map['supervisor_monitor'] as String?) ?? '',
      actionTrackerId: map['action_tracker_id'] as int?,
      status: (map['status'] as String?) ?? 'PLANNED',
      createdAt: map['created_at'] as String?,
    );
  }
}

/// รวมข้อมูลแบบ Flat สำหรับ Render ตาราง ปอ. ๑ และ ปอ. ๒
class PorReportRowData {
  final WorkStation workstation;
  final WorkStepItem stepItem;
  final HazardEvaluationPor1 hazard;
  final RiskControlPlanPor2? plan;

  PorReportRowData({
    required this.workstation,
    required this.stepItem,
    required this.hazard,
    this.plan,
  });
}
