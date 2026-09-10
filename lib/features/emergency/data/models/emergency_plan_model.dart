import 'dart:convert';
import '../../domain/enums/hazard_type.dart';
import '../../domain/enums/emergency_enums.dart';

/// โมเดลแผนฉุกเฉินระดับองค์กร (ERP Model)
/// รองรับ ๖ เสาหลักตามกฎกระทรวงอัคคีภัย ๒๕๕๕ ข้อ ๔ และปรับแต่งตามประเภทภัย (Multi-Hazard)
class EmergencyPlanModel {
  final int? id;
  final String planTitle;
  final HazardType hazardType;
  final BusinessType businessType;
  final String companyName;
  final String companyAddress;
  final int totalEmployees;
  final int maleCount;
  final int femaleCount;
  final String fireCommanderName;
  final String deputyCommanderName;
  final String commanderPhone;
  final String version;
  final String effectiveDate;
  final String reviewDate;
  final PlanStatus status;
  final InspectionSubPlan inspectionPlan;
  final TrainingSubPlan trainingPlan;
  final CampaignSubPlan campaignPlan;
  final SuppressionSubPlan suppressionPlan;
  final EvacuationSubPlan evacuationPlan;
  final ReliefSubPlan reliefPlan;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const EmergencyPlanModel({
    this.id,
    required this.planTitle,
    this.hazardType = HazardType.fire,
    this.businessType = BusinessType.factory,
    this.companyName = '',
    this.companyAddress = '',
    this.totalEmployees = 0,
    this.maleCount = 0,
    this.femaleCount = 0,
    this.fireCommanderName = '',
    this.deputyCommanderName = '',
    this.commanderPhone = '',
    this.version = '1.0',
    this.effectiveDate = '',
    this.reviewDate = '',
    this.status = PlanStatus.active,
    required this.inspectionPlan,
    required this.trainingPlan,
    required this.campaignPlan,
    required this.suppressionPlan,
    required this.evacuationPlan,
    required this.reliefPlan,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  EmergencyPlanModel copyWith({
    int? id,
    String? planTitle,
    HazardType? hazardType,
    BusinessType? businessType,
    String? companyName,
    String? companyAddress,
    int? totalEmployees,
    int? maleCount,
    int? femaleCount,
    String? fireCommanderName,
    String? deputyCommanderName,
    String? commanderPhone,
    String? version,
    String? effectiveDate,
    String? reviewDate,
    PlanStatus? status,
    InspectionSubPlan? inspectionPlan,
    TrainingSubPlan? trainingPlan,
    CampaignSubPlan? campaignPlan,
    SuppressionSubPlan? suppressionPlan,
    EvacuationSubPlan? evacuationPlan,
    ReliefSubPlan? reliefPlan,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EmergencyPlanModel(
      id: id ?? this.id,
      planTitle: planTitle ?? this.planTitle,
      hazardType: hazardType ?? this.hazardType,
      businessType: businessType ?? this.businessType,
      companyName: companyName ?? this.companyName,
      companyAddress: companyAddress ?? this.companyAddress,
      totalEmployees: totalEmployees ?? this.totalEmployees,
      maleCount: maleCount ?? this.maleCount,
      femaleCount: femaleCount ?? this.femaleCount,
      fireCommanderName: fireCommanderName ?? this.fireCommanderName,
      deputyCommanderName: deputyCommanderName ?? this.deputyCommanderName,
      commanderPhone: commanderPhone ?? this.commanderPhone,
      version: version ?? this.version,
      effectiveDate: effectiveDate ?? this.effectiveDate,
      reviewDate: reviewDate ?? this.reviewDate,
      status: status ?? this.status,
      inspectionPlan: inspectionPlan ?? this.inspectionPlan,
      trainingPlan: trainingPlan ?? this.trainingPlan,
      campaignPlan: campaignPlan ?? this.campaignPlan,
      suppressionPlan: suppressionPlan ?? this.suppressionPlan,
      evacuationPlan: evacuationPlan ?? this.evacuationPlan,
      reliefPlan: reliefPlan ?? this.reliefPlan,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'plan_title': planTitle,
      'hazard_type': hazardType.code,
      'business_type': businessType.code,
      'company_name': companyName,
      'company_address': companyAddress,
      'total_employees': totalEmployees,
      'male_count': maleCount,
      'female_count': femaleCount,
      'fire_commander_name': fireCommanderName,
      'deputy_commander_name': deputyCommanderName,
      'commander_phone': commanderPhone,
      'version': version,
      'effective_date': effectiveDate,
      'review_date': reviewDate,
      'status': status.code,
      'plan_1_inspection_json': jsonEncode(inspectionPlan.toMap()),
      'plan_2_training_json': jsonEncode(trainingPlan.toMap()),
      'plan_3_campaign_json': jsonEncode(campaignPlan.toMap()),
      'plan_4_suppression_json': jsonEncode(suppressionPlan.toMap()),
      'plan_5_evacuation_json': jsonEncode(evacuationPlan.toMap()),
      'plan_6_relief_json': jsonEncode(reliefPlan.toMap()),
      'notes': notes,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory EmergencyPlanModel.fromMap(Map<String, dynamic> map) {
    return EmergencyPlanModel(
      id: map['id'] as int?,
      planTitle: map['plan_title'] as String? ?? 'แผนฉุกเฉิน',
      hazardType: HazardType.fromCode(map['hazard_type'] as String?),
      businessType: BusinessType.fromCode(map['business_type'] as String?),
      companyName: map['company_name'] as String? ?? '',
      companyAddress: map['company_address'] as String? ?? '',
      totalEmployees: map['total_employees'] as int? ?? 0,
      maleCount: map['male_count'] as int? ?? 0,
      femaleCount: map['female_count'] as int? ?? 0,
      fireCommanderName: map['fire_commander_name'] as String? ?? '',
      deputyCommanderName: map['deputy_commander_name'] as String? ?? '',
      commanderPhone: map['commander_phone'] as String? ?? '',
      version: map['version'] as String? ?? '1.0',
      effectiveDate: map['effective_date'] as String? ?? '',
      reviewDate: map['review_date'] as String? ?? '',
      status: PlanStatus.fromCode(map['status'] as String?),
      inspectionPlan: InspectionSubPlan.fromRawJson(map['plan_1_inspection_json']),
      trainingPlan: TrainingSubPlan.fromRawJson(map['plan_2_training_json']),
      campaignPlan: CampaignSubPlan.fromRawJson(map['plan_3_campaign_json']),
      suppressionPlan: SuppressionSubPlan.fromRawJson(map['plan_4_suppression_json']),
      evacuationPlan: EvacuationSubPlan.fromRawJson(map['plan_5_evacuation_json']),
      reliefPlan: ReliefSubPlan.fromRawJson(map['plan_6_relief_json']),
      notes: map['notes'] as String?,
      createdAt: map['created_at'] != null ? DateTime.tryParse(map['created_at']) : null,
      updatedAt: map['updated_at'] != null ? DateTime.tryParse(map['updated_at']) : null,
    );
  }
}

/// ๑. แผนการตรวจตรา (Inspection Plan)
class InspectionSubPlan {
  final List<InspectionItem> items;
  final String frequencyDescription;
  final String reportingProcedure;

  const InspectionSubPlan({
    this.items = const [],
    this.frequencyDescription = 'ตรวจตราประจำเดือน / ประจำสัปดาห์จุดเสี่ยงสูง',
    this.reportingProcedure = 'บันทึกรายงานผ่านแบบฟอร์มตรวจสอบและส่งต่อ จป.วิชาชีพ ภายใน 24 ชม.',
  });

  Map<String, dynamic> toMap() => {
    'items': items.map((e) => e.toMap()).toList(),
    'frequencyDescription': frequencyDescription,
    'reportingProcedure': reportingProcedure,
  };

  factory InspectionSubPlan.fromMap(Map<String, dynamic> map) {
    final rawList = map['items'] as List<dynamic>? ?? [];
    return InspectionSubPlan(
      items: rawList.map((e) => InspectionItem.fromMap(e as Map<String, dynamic>)).toList(),
      frequencyDescription: map['frequencyDescription'] as String? ?? '',
      reportingProcedure: map['reportingProcedure'] as String? ?? '',
    );
  }

  InspectionSubPlan copyWith({
    List<InspectionItem>? items,
    String? frequencyDescription,
    String? reportingProcedure,
  }) {
    return InspectionSubPlan(
      items: items ?? this.items,
      frequencyDescription: frequencyDescription ?? this.frequencyDescription,
      reportingProcedure: reportingProcedure ?? this.reportingProcedure,
    );
  }

  factory InspectionSubPlan.fromRawJson(dynamic raw) {
    if (raw == null || raw is! String || raw.isEmpty) return const InspectionSubPlan();
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return InspectionSubPlan.fromMap(map);
    } catch (_) {
      return const InspectionSubPlan();
    }
  }
}

class InspectionItem {
  final String category; // เช่น 'เครื่องดับเพลิง', 'ระบบสัญญาณเตือน', 'เส้นทางหนีไฟ', 'สารเคมี', 'ตู้ MDB ไฟฟ้า'
  final String area;
  final String frequency; // 'DAILY', 'WEEKLY', 'MONTHLY'
  final String inspectorRole;

  const InspectionItem({
    required this.category,
    required this.area,
    required this.frequency,
    required this.inspectorRole,
  });

  Map<String, dynamic> toMap() => {
    'category': category,
    'area': area,
    'frequency': frequency,
    'inspectorRole': inspectorRole,
  };

  factory InspectionItem.fromMap(Map<String, dynamic> map) => InspectionItem(
    category: map['category'] as String? ?? '',
    area: map['area'] as String? ?? '',
    frequency: map['frequency'] as String? ?? 'MONTHLY',
    inspectorRole: map['inspectorRole'] as String? ?? '',
  );
}

/// ๒. แผนการอบรม (Training Plan)
class TrainingSubPlan {
  final double basicFireQuotaPercent; // กฎหมายกำหนด >= 40% (ข้อ ๒๗)
  final String annualDrillTargetMonth; // เช่น 'พฤศจิกายน ของทุกปี'
  final List<TrainingCourseItem> courses;

  const TrainingSubPlan({
    this.basicFireQuotaPercent = 40.0,
    this.annualDrillTargetMonth = 'พฤศจิกายน',
    this.courses = const [],
  });

  Map<String, dynamic> toMap() => {
    'basicFireQuotaPercent': basicFireQuotaPercent,
    'annualDrillTargetMonth': annualDrillTargetMonth,
    'courses': courses.map((e) => e.toMap()).toList(),
  };

  factory TrainingSubPlan.fromMap(Map<String, dynamic> map) {
    final rawList = map['courses'] as List<dynamic>? ?? [];
    return TrainingSubPlan(
      basicFireQuotaPercent: (map['basicFireQuotaPercent'] as num?)?.toDouble() ?? 40.0,
      annualDrillTargetMonth: map['annualDrillTargetMonth'] as String? ?? 'พฤศจิกายน',
      courses: rawList.map((e) => TrainingCourseItem.fromMap(e as Map<String, dynamic>)).toList(),
    );
  }

  TrainingSubPlan copyWith({
    double? basicFireQuotaPercent,
    String? annualDrillTargetMonth,
    List<TrainingCourseItem>? courses,
  }) {
    return TrainingSubPlan(
      basicFireQuotaPercent: basicFireQuotaPercent ?? this.basicFireQuotaPercent,
      annualDrillTargetMonth: annualDrillTargetMonth ?? this.annualDrillTargetMonth,
      courses: courses ?? this.courses,
    );
  }

  factory TrainingSubPlan.fromRawJson(dynamic raw) {
    if (raw == null || raw is! String || raw.isEmpty) return const TrainingSubPlan();
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return TrainingSubPlan.fromMap(map);
    } catch (_) {
      return const TrainingSubPlan();
    }
  }
}

class TrainingCourseItem {
  final String courseName;
  final String targetAudience;
  final String provider;
  final String frequency;

  const TrainingCourseItem({
    required this.courseName,
    required this.targetAudience,
    required this.provider,
    required this.frequency,
  });

  Map<String, dynamic> toMap() => {
    'courseName': courseName,
    'targetAudience': targetAudience,
    'provider': provider,
    'frequency': frequency,
  };

  factory TrainingCourseItem.fromMap(Map<String, dynamic> map) => TrainingCourseItem(
    courseName: map['courseName'] as String? ?? '',
    targetAudience: map['targetAudience'] as String? ?? '',
    provider: map['provider'] as String? ?? '',
    frequency: map['frequency'] as String? ?? '',
  );
}

/// ๓. แผนการรณรงค์ป้องกันอัคคีภัย/สาธารณภัย (Campaign Plan)
class CampaignSubPlan {
  final List<String> activities; // เช่น 'กิจกรรม 5ส สัปดาห์ความปลอดภัย', 'การจัดบอร์ดนิทรรศการ', 'โปสเตอร์ระวังจุดเสี่ยง'
  final String smokingControlPolicy;
  final String hotWorkSafetyReminder;

  const CampaignSubPlan({
    this.activities = const [],
    this.smokingControlPolicy = 'ห้ามสูบบุหรี่เด็ดขาด ยกเว้นจุดที่จัดไว้ภายนอกอาคาร',
    this.hotWorkSafetyReminder = 'งานที่เกิดประกายไฟต้องขอใบอนุญาต PTW ก่อนเริ่มงานทุกครั้ง',
  });

  Map<String, dynamic> toMap() => {
    'activities': activities,
    'smokingControlPolicy': smokingControlPolicy,
    'hotWorkSafetyReminder': hotWorkSafetyReminder,
  };

  factory CampaignSubPlan.fromMap(Map<String, dynamic> map) {
    final rawList = (map['activities'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
    return CampaignSubPlan(
      activities: rawList,
      smokingControlPolicy: map['smokingControlPolicy'] as String? ?? '',
      hotWorkSafetyReminder: map['hotWorkSafetyReminder'] as String? ?? '',
    );
  }

  CampaignSubPlan copyWith({
    List<String>? activities,
    String? smokingControlPolicy,
    String? hotWorkSafetyReminder,
  }) {
    return CampaignSubPlan(
      activities: activities ?? this.activities,
      smokingControlPolicy: smokingControlPolicy ?? this.smokingControlPolicy,
      hotWorkSafetyReminder: hotWorkSafetyReminder ?? this.hotWorkSafetyReminder,
    );
  }

  factory CampaignSubPlan.fromRawJson(dynamic raw) {
    if (raw == null || raw is! String || raw.isEmpty) return const CampaignSubPlan();
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return CampaignSubPlan.fromMap(map);
    } catch (_) {
      return const CampaignSubPlan();
    }
  }
}

/// ๔. แผนการดับเพลิง / ระงับเหตุ (Suppression & Incident Command Plan)
class SuppressionSubPlan {
  final String initialResponseProtocol;
  final String majorEmergencyProtocol;
  final List<EmergencyTeamRole> regularShiftTeam;
  final List<EmergencyTeamRole> offHoursTeam;

  const SuppressionSubPlan({
    this.initialResponseProtocol = 'ผู้พบเห็นร้องตะโกนแจ้งเหตุ ใช้อุปกรณ์ดับเพลิงขั้นต้นในระยะ 1 นาทีแรก หากคุมไม่ได้แจ้งศูนย์สื่อสารทันที',
    this.majorEmergencyProtocol = 'ผู้อำนวยการสั่งใช้แผนขั้นรุนแรง ตัดระบบไฟฟ้าหลัก สั่งอพยพ แจ้ง 199 หน่วยดับเพลิงเทศบาล/กู้ภัย',
    this.regularShiftTeam = const [],
    this.offHoursTeam = const [],
  });

  Map<String, dynamic> toMap() => {
    'initialResponseProtocol': initialResponseProtocol,
    'majorEmergencyProtocol': majorEmergencyProtocol,
    'regularShiftTeam': regularShiftTeam.map((e) => e.toMap()).toList(),
    'offHoursTeam': offHoursTeam.map((e) => e.toMap()).toList(),
  };

  factory SuppressionSubPlan.fromMap(Map<String, dynamic> map) {
    final regList = map['regularShiftTeam'] as List<dynamic>? ?? [];
    final offList = map['offHoursTeam'] as List<dynamic>? ?? [];
    return SuppressionSubPlan(
      initialResponseProtocol: map['initialResponseProtocol'] as String? ?? '',
      majorEmergencyProtocol: map['majorEmergencyProtocol'] as String? ?? '',
      regularShiftTeam: regList.map((e) => EmergencyTeamRole.fromMap(e as Map<String, dynamic>)).toList(),
      offHoursTeam: offList.map((e) => EmergencyTeamRole.fromMap(e as Map<String, dynamic>)).toList(),
    );
  }

  SuppressionSubPlan copyWith({
    String? initialResponseProtocol,
    String? majorEmergencyProtocol,
    List<EmergencyTeamRole>? regularShiftTeam,
    List<EmergencyTeamRole>? offHoursTeam,
  }) {
    return SuppressionSubPlan(
      initialResponseProtocol: initialResponseProtocol ?? this.initialResponseProtocol,
      majorEmergencyProtocol: majorEmergencyProtocol ?? this.majorEmergencyProtocol,
      regularShiftTeam: regularShiftTeam ?? this.regularShiftTeam,
      offHoursTeam: offHoursTeam ?? this.offHoursTeam,
    );
  }

  factory SuppressionSubPlan.fromRawJson(dynamic raw) {
    if (raw == null || raw is! String || raw.isEmpty) return const SuppressionSubPlan();
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return SuppressionSubPlan.fromMap(map);
    } catch (_) {
      return const SuppressionSubPlan();
    }
  }
}

class EmergencyTeamRole {
  final String roleTitle; // 'ผู้อำนวยการดับเพลิง', 'หัวหน้าชุดดับเพลิงขั้นต้น', 'เจ้าหน้าที่ควบคุมระบบไฟฟ้า', 'เจ้าหน้าที่ควบคุมปั๊มน้ำดับเพลิง'
  final String assignedPerson;
  final String contactNumber;
  final String keyDuties;

  const EmergencyTeamRole({
    required this.roleTitle,
    required this.assignedPerson,
    required this.contactNumber,
    required this.keyDuties,
  });

  Map<String, dynamic> toMap() => {
    'roleTitle': roleTitle,
    'assignedPerson': assignedPerson,
    'contactNumber': contactNumber,
    'keyDuties': keyDuties,
  };

  factory EmergencyTeamRole.fromMap(Map<String, dynamic> map) => EmergencyTeamRole(
    roleTitle: map['roleTitle'] as String? ?? '',
    assignedPerson: map['assignedPerson'] as String? ?? '',
    contactNumber: map['contactNumber'] as String? ?? '',
    keyDuties: map['keyDuties'] as String? ?? '',
  );
}

/// ๕. แผนอพยพหนีไฟ / อพยพภัยพิบัติ (Evacuation Plan)
class EvacuationSubPlan {
  final String alarmSoundSignal;
  final List<AssemblyPointItem> assemblyPoints;
  final List<EvacuationWarden> wardens;
  final List<EvacuationTeam> evacuationTeams;
  final String headcountMethod;

  const EvacuationSubPlan({
    this.alarmSoundSignal = 'สัญญาณไซเรนต่อเนื่องเกิน 30 วินาที หรือประกาศเสียงตามสายให้อพยพทันที',
    this.assemblyPoints = const [],
    this.wardens = const [],
    this.evacuationTeams = const [],
    this.headcountMethod = 'หัวหน้าแผนก/ผู้นำทางเช็คชื่อตามใบรายชื่อพนักงานประจำวัน แล้วรายงานต่อผู้อำนวยการอพยพ',
  });

  Map<String, dynamic> toMap() => {
    'alarmSoundSignal': alarmSoundSignal,
    'assemblyPoints': assemblyPoints.map((e) => e.toMap()).toList(),
    'wardens': wardens.map((e) => e.toMap()).toList(),
    'evacuationTeams': evacuationTeams.map((e) => e.toMap()).toList(),
    'headcountMethod': headcountMethod,
  };

  factory EvacuationSubPlan.fromMap(Map<String, dynamic> map) {
    final apList = map['assemblyPoints'] as List<dynamic>? ?? [];
    final wList = map['wardens'] as List<dynamic>? ?? [];
    final teamList = map['evacuationTeams'] as List<dynamic>? ?? [];

    final teams = teamList.isNotEmpty
        ? teamList.map((e) => EvacuationTeam.fromMap(e as Map<String, dynamic>)).toList()
        : wList.map((w) {
            final wMap = w is Map<String, dynamic> ? w : <String, dynamic>{};
            return EvacuationTeam(
              teamName: 'ทีมผู้นำทาง ${(wMap['areaFloor'] ?? '').toString()}',
              areaFloor: (wMap['areaFloor'] ?? '').toString(),
              leaderName: (wMap['wardenName'] ?? '').toString(),
              deputyLeaderName: (wMap['deputyWardenName'] ?? '').toString(),
              members: const [],
              assignedAssemblyPoint: 'จุดรวมพลหลัก',
              duties: 'นำทางพนักงานอพยพตามเส้นทางที่กำหนด',
            );
          }).toList();

    return EvacuationSubPlan(
      alarmSoundSignal: map['alarmSoundSignal'] as String? ?? '',
      assemblyPoints: apList.map((e) => AssemblyPointItem.fromMap(e as Map<String, dynamic>)).toList(),
      wardens: wList.map((e) => EvacuationWarden.fromMap(e as Map<String, dynamic>)).toList(),
      evacuationTeams: teams,
      headcountMethod: map['headcountMethod'] as String? ?? '',
    );
  }

  EvacuationSubPlan copyWith({
    String? alarmSoundSignal,
    List<AssemblyPointItem>? assemblyPoints,
    List<EvacuationWarden>? wardens,
    List<EvacuationTeam>? evacuationTeams,
    String? headcountMethod,
  }) {
    return EvacuationSubPlan(
      alarmSoundSignal: alarmSoundSignal ?? this.alarmSoundSignal,
      assemblyPoints: assemblyPoints ?? this.assemblyPoints,
      wardens: wardens ?? this.wardens,
      evacuationTeams: evacuationTeams ?? this.evacuationTeams,
      headcountMethod: headcountMethod ?? this.headcountMethod,
    );
  }

  factory EvacuationSubPlan.fromRawJson(dynamic raw) {
    if (raw == null || raw is! String || raw.isEmpty) return const EvacuationSubPlan();
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return EvacuationSubPlan.fromMap(map);
    } catch (_) {
      return const EvacuationSubPlan();
    }
  }
}

/// โครงสร้างทีมอพยพ / ผู้นำทางหนีไฟ (รองรับหลายทีม หลายพื้นที่ พร้อมรายชื่อสมาชิกในทีม)
class EvacuationTeam {
  final String teamName; // เช่น 'ทีมผู้นำทางหนีไฟ อาคารผลิต ชั้น 1', 'ทีมตรวจค้นผู้ติดค้าง'
  final String areaFloor; // เช่น 'อาคารผลิต ชั้น 1', 'คลังสินค้า โซน A'
  final String leaderName; // เช่น 'นายสมบูรณ์ มั่นคง (หัวหน้าทีม)'
  final String deputyLeaderName; // เช่น 'นายมานพ ชัยชนะ (รองหัวหน้าทีม)'
  final List<String> members; // เช่น ['นายสมชาย ดีเลิศ', 'นางสาววรรณา สดใส', 'นายกิตติ เก่งกล้า']
  final String assignedAssemblyPoint; // เช่น 'จุดรวมพลที่ ๑ (ลานจอดรถ)'
  final String duties; // เช่น 'นำทางพนักงานอพยพ ตรวจสอบห้องน้ำมุมอับ และรายงานยอด'

  const EvacuationTeam({
    required this.teamName,
    this.areaFloor = '',
    this.leaderName = '',
    this.deputyLeaderName = '',
    this.members = const [],
    this.assignedAssemblyPoint = '',
    this.duties = '',
  });

  Map<String, dynamic> toMap() => {
    'teamName': teamName,
    'areaFloor': areaFloor,
    'leaderName': leaderName,
    'deputyLeaderName': deputyLeaderName,
    'members': members,
    'assignedAssemblyPoint': assignedAssemblyPoint,
    'duties': duties,
  };

  factory EvacuationTeam.fromMap(Map<String, dynamic> map) {
    final rawMembers = map['members'] as List<dynamic>? ?? [];
    return EvacuationTeam(
      teamName: map['teamName'] as String? ?? '',
      areaFloor: map['areaFloor'] as String? ?? '',
      leaderName: map['leaderName'] as String? ?? '',
      deputyLeaderName: map['deputyLeaderName'] as String? ?? '',
      members: rawMembers.map((e) => e.toString()).toList(),
      assignedAssemblyPoint: map['assignedAssemblyPoint'] as String? ?? '',
      duties: map['duties'] as String? ?? '',
    );
  }
}

class AssemblyPointItem {
  final String pointName; // 'จุดรวมพลที่ ๑ (ลานจอดรถด้านหน้า)'
  final String location;
  final String assignedDepartments;
  final int capacity;

  const AssemblyPointItem({
    required this.pointName,
    required this.location,
    required this.assignedDepartments,
    this.capacity = 100,
  });

  Map<String, dynamic> toMap() => {
    'pointName': pointName,
    'location': location,
    'assignedDepartments': assignedDepartments,
    'capacity': capacity,
  };

  factory AssemblyPointItem.fromMap(Map<String, dynamic> map) => AssemblyPointItem(
    pointName: map['pointName'] as String? ?? '',
    location: map['location'] as String? ?? '',
    assignedDepartments: map['assignedDepartments'] as String? ?? '',
    capacity: map['capacity'] as int? ?? 100,
  );
}

class EvacuationWarden {
  final String areaFloor;
  final String wardenName;
  final String deputyWardenName;

  const EvacuationWarden({
    required this.areaFloor,
    required this.wardenName,
    required this.deputyWardenName,
  });

  Map<String, dynamic> toMap() => {
    'areaFloor': areaFloor,
    'wardenName': wardenName,
    'deputyWardenName': deputyWardenName,
  };

  factory EvacuationWarden.fromMap(Map<String, dynamic> map) => EvacuationWarden(
    areaFloor: map['areaFloor'] as String? ?? '',
    wardenName: map['wardenName'] as String? ?? '',
    deputyWardenName: map['deputyWardenName'] as String? ?? '',
  );
}

/// ๖. แผนบรรเทาทุกข์และฟื้นฟู (Relief & Recovery Plan)
class ReliefSubPlan {
  final List<EmergencyContactAgency> governmentContacts;
  final String searchAndRescueProtocol;
  final String damageAssessmentProtocol;
  final String businessContinuityProtocol;

  const ReliefSubPlan({
    this.governmentContacts = const [],
    this.searchAndRescueProtocol = 'ห้ามพนักงานกลับเข้าไปในอาคารเด็ดขาด มอบหมายทีมกู้ชีพค้นหาหรือเจ้าหน้าที่ดับเพลิงภายนอกเข้าค้นหาผู้สูญหาย',
    this.damageAssessmentProtocol = 'แต่งตั้งคณะกรรมการสำรวจความเสียหายร่วมกับวิศวกรโครงสร้างและประกันภัย ก่อนอนุญาตให้เข้าพื้นที่',
    this.businessContinuityProtocol = 'จัดตั้งศูนย์ประสานงานชั่วคราว ดำเนินการตามแผน BCP ฟื้นฟูระบบการผลิตและไอที',
  });

  Map<String, dynamic> toMap() => {
    'governmentContacts': governmentContacts.map((e) => e.toMap()).toList(),
    'searchAndRescueProtocol': searchAndRescueProtocol,
    'damageAssessmentProtocol': damageAssessmentProtocol,
    'businessContinuityProtocol': businessContinuityProtocol,
  };

  factory ReliefSubPlan.fromMap(Map<String, dynamic> map) {
    final gcList = map['governmentContacts'] as List<dynamic>? ?? [];
    return ReliefSubPlan(
      governmentContacts: gcList.map((e) => EmergencyContactAgency.fromMap(e as Map<String, dynamic>)).toList(),
      searchAndRescueProtocol: map['searchAndRescueProtocol'] as String? ?? '',
      damageAssessmentProtocol: map['damageAssessmentProtocol'] as String? ?? '',
      businessContinuityProtocol: map['businessContinuityProtocol'] as String? ?? '',
    );
  }

  ReliefSubPlan copyWith({
    List<EmergencyContactAgency>? governmentContacts,
    String? searchAndRescueProtocol,
    String? damageAssessmentProtocol,
    String? businessContinuityProtocol,
  }) {
    return ReliefSubPlan(
      governmentContacts: governmentContacts ?? this.governmentContacts,
      searchAndRescueProtocol: searchAndRescueProtocol ?? this.searchAndRescueProtocol,
      damageAssessmentProtocol: damageAssessmentProtocol ?? this.damageAssessmentProtocol,
      businessContinuityProtocol: businessContinuityProtocol ?? this.businessContinuityProtocol,
    );
  }

  factory ReliefSubPlan.fromRawJson(dynamic raw) {
    if (raw == null || raw is! String || raw.isEmpty) return const ReliefSubPlan();
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return ReliefSubPlan.fromMap(map);
    } catch (_) {
      return const ReliefSubPlan();
    }
  }
}

class EmergencyContactAgency {
  final String agencyName; // เช่น 'สถานีดับเพลิงในพื้นที่ (199)', 'โรงพยาบาลศูนย์', 'สถานีตำรวจ', 'การไฟฟ้าส่วนภูมิภาค'
  final String phoneNumber;
  final String contactPerson;

  const EmergencyContactAgency({
    required this.agencyName,
    required this.phoneNumber,
    this.contactPerson = '',
  });

  Map<String, dynamic> toMap() => {
    'agencyName': agencyName,
    'phoneNumber': phoneNumber,
    'contactPerson': contactPerson,
  };

  factory EmergencyContactAgency.fromMap(Map<String, dynamic> map) => EmergencyContactAgency(
    agencyName: map['agencyName'] as String? ?? '',
    phoneNumber: map['phoneNumber'] as String? ?? '',
    contactPerson: map['contactPerson'] as String? ?? '',
  );
}
