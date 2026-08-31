import 'dart:convert';

class AccidentTimelineItem {
  final String time;
  final String action;

  AccidentTimelineItem({required this.time, required this.action});

  Map<String, dynamic> toMap() => {'time': time, 'action': action};
  factory AccidentTimelineItem.fromMap(Map<String, dynamic> map) {
    return AccidentTimelineItem(
      time: map['time'] as String? ?? '',
      action: map['action'] as String? ?? '',
    );
  }
}

class AccidentInvestigation {
  final int? id;
  final String eventNo;
  final String eventType; // NEAR_MISS, FIRST_AID, LOST_TIME, DISABILITY, FATALITY
  final String incidentTitle;
  final String incidentDate;
  final String incidentTime;
  final String incidentLocation;

  // Injured Person Info
  final int? employeeId;
  final String employeeType; // EMPLOYEE, CONTRACTOR, THIRD_PARTY
  final String? injuredPersonName;
  final String? injuredPersonNationalId;
  final String? injuredPersonPosition;
  final String? injuredPersonDepartment;
  final int? injuredPersonAge;
  final double? injuredPersonWage;
  final String? injuryNature; // แผลฉีกขาด, กระดูกหัก, ไฟไหม้/น้ำร้อนลวก, สารเคมี, สัมผัสไฟฟ้า, สูญเสียอวัยวะ
  final String? injuredBodyPart; // ศีรษะ, ตา, มือ/นิ้วมือ, แขน, ขา/เท้า, ลำตัว/หลัง

  // Hospital & Loss Info
  final String? hospitalName;
  final String? hospitalSentDate;
  final int daysLost;
  final double medicalExpense;
  final double propertyDamageCost;

  // Equipment & Process
  final String? machineInvolved;
  final String? chemicalInvolved;
  final String? workProcessInvolved;

  // Investigation & 5W1H
  final String? description5w1h;
  final List<AccidentTimelineItem> timelineEvents;
  final String? witnessNames;
  final List<String> photoPaths;

  // Causation Analysis (3 Factors)
  final List<String> unsafeActs;
  final List<String> unsafeConditions;
  final List<String> managementErrors;
  final String? rootCauseSummary;
  final List<String> applicableLaws;

  // Sign-off
  final String? inspectorName;
  final String? inspectorPosition;
  final String? employerAcknowledgedDate;
  final String status; // DRAFT, INVESTIGATING, CAPA_PENDING, CLOSED
  final String? createdAt;
  final String? updatedAt;

  // Computed from joins
  final int capaCount;
  final int completedCapaCount;

  AccidentInvestigation({
    this.id,
    required this.eventNo,
    required this.eventType,
    required this.incidentTitle,
    required this.incidentDate,
    required this.incidentTime,
    required this.incidentLocation,
    this.employeeId,
    this.employeeType = 'EMPLOYEE',
    this.injuredPersonName,
    this.injuredPersonNationalId,
    this.injuredPersonPosition,
    this.injuredPersonDepartment,
    this.injuredPersonAge,
    this.injuredPersonWage,
    this.injuryNature,
    this.injuredBodyPart,
    this.hospitalName,
    this.hospitalSentDate,
    this.daysLost = 0,
    this.medicalExpense = 0.0,
    this.propertyDamageCost = 0.0,
    this.machineInvolved,
    this.chemicalInvolved,
    this.workProcessInvolved,
    this.description5w1h,
    this.timelineEvents = const [],
    this.witnessNames,
    this.photoPaths = const [],
    this.unsafeActs = const [],
    this.unsafeConditions = const [],
    this.managementErrors = const [],
    this.rootCauseSummary,
    this.applicableLaws = const [],
    this.inspectorName,
    this.inspectorPosition,
    this.employerAcknowledgedDate,
    this.status = 'INVESTIGATING',
    this.createdAt,
    this.updatedAt,
    this.capaCount = 0,
    this.completedCapaCount = 0,
  });

  String get eventTypeLabel {
    switch (eventType) {
      case 'FATALITY':
        return 'เสียชีวิต (Fatality)';
      case 'DISABILITY':
        return 'สูญเสียอวัยวะ / ทุพพลภาพ (Disability)';
      case 'LOST_TIME':
        return 'หยุดงาน (Lost Time Injury - LTI)';
      case 'FIRST_AID':
        return 'ปฐมพยาบาล (First Aid / Non-LTI)';
      case 'NEAR_MISS':
      default:
        return 'เหตุการณ์เกือบเกิดอุบัติเหตุ (Near Miss)';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'event_no': eventNo,
      'event_type': eventType,
      'incident_title': incidentTitle,
      'incident_date': incidentDate,
      'incident_time': incidentTime,
      'incident_location': incidentLocation,
      'employee_id': employeeId,
      'employee_type': employeeType,
      'injured_person_name': injuredPersonName,
      'injured_person_national_id': injuredPersonNationalId,
      'injured_person_position': injuredPersonPosition,
      'injured_person_department': injuredPersonDepartment,
      'injured_person_age': injuredPersonAge,
      'injured_person_wage': injuredPersonWage,
      'injury_nature': injuryNature,
      'injured_body_part': injuredBodyPart,
      'hospital_name': hospitalName,
      'hospital_sent_date': hospitalSentDate,
      'days_lost': daysLost,
      'medical_expense': medicalExpense,
      'property_damage_cost': propertyDamageCost,
      'machine_involved': machineInvolved,
      'chemical_involved': chemicalInvolved,
      'work_process_involved': workProcessInvolved,
      'description_5w1h': description5w1h,
      'timeline_events': jsonEncode(timelineEvents.map((e) => e.toMap()).toList()),
      'witness_names': witnessNames,
      'photo_paths': jsonEncode(photoPaths),
      'unsafe_acts': jsonEncode(unsafeActs),
      'unsafe_conditions': jsonEncode(unsafeConditions),
      'management_errors': jsonEncode(managementErrors),
      'root_cause_summary': rootCauseSummary,
      'applicable_laws': jsonEncode(applicableLaws),
      'inspector_name': inspectorName,
      'inspector_position': inspectorPosition,
      'employer_acknowledged_date': employerAcknowledgedDate,
      'status': status,
    };
  }

  factory AccidentInvestigation.fromMap(Map<String, dynamic> map) {
    List<AccidentTimelineItem> parsedTimeline = [];
    if (map['timeline_events'] != null && map['timeline_events'] is String && (map['timeline_events'] as String).isNotEmpty) {
      try {
        final decoded = jsonDecode(map['timeline_events'] as String) as List<dynamic>;
        parsedTimeline = decoded.map((e) => AccidentTimelineItem.fromMap(e as Map<String, dynamic>)).toList();
      } catch (_) {}
    }

    List<String> parseJsonList(dynamic val) {
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

    return AccidentInvestigation(
      id: map['id'] as int?,
      eventNo: map['event_no'] as String? ?? '',
      eventType: map['event_type'] as String? ?? 'NEAR_MISS',
      incidentTitle: map['incident_title'] as String? ?? '',
      incidentDate: map['incident_date'] as String? ?? '',
      incidentTime: map['incident_time'] as String? ?? '',
      incidentLocation: map['incident_location'] as String? ?? '',
      employeeId: map['employee_id'] as int?,
      employeeType: map['employee_type'] as String? ?? 'EMPLOYEE',
      injuredPersonName: map['injured_person_name'] as String?,
      injuredPersonNationalId: map['injured_person_national_id'] as String?,
      injuredPersonPosition: map['injured_person_position'] as String?,
      injuredPersonDepartment: map['injured_person_department'] as String?,
      injuredPersonAge: map['injured_person_age'] as int?,
      injuredPersonWage: (map['injured_person_wage'] as num?)?.toDouble(),
      injuryNature: map['injury_nature'] as String?,
      injuredBodyPart: map['injured_body_part'] as String?,
      hospitalName: map['hospital_name'] as String?,
      hospitalSentDate: map['hospital_sent_date'] as String?,
      daysLost: map['days_lost'] as int? ?? 0,
      medicalExpense: (map['medical_expense'] as num?)?.toDouble() ?? 0.0,
      propertyDamageCost: (map['property_damage_cost'] as num?)?.toDouble() ?? 0.0,
      machineInvolved: map['machine_involved'] as String?,
      chemicalInvolved: map['chemical_involved'] as String?,
      workProcessInvolved: map['work_process_involved'] as String?,
      description5w1h: map['description_5w1h'] as String?,
      timelineEvents: parsedTimeline,
      witnessNames: map['witness_names'] as String?,
      photoPaths: parseJsonList(map['photo_paths']),
      unsafeActs: parseJsonList(map['unsafe_acts']),
      unsafeConditions: parseJsonList(map['unsafe_conditions']),
      managementErrors: parseJsonList(map['management_errors']),
      rootCauseSummary: map['root_cause_summary'] as String?,
      applicableLaws: parseJsonList(map['applicable_laws']),
      inspectorName: map['inspector_name'] as String?,
      inspectorPosition: map['inspector_position'] as String?,
      employerAcknowledgedDate: map['employer_acknowledged_date'] as String?,
      status: map['status'] as String? ?? 'INVESTIGATING',
      createdAt: map['created_at'] as String?,
      updatedAt: map['updated_at'] as String?,
      capaCount: map['capa_count'] as int? ?? 0,
      completedCapaCount: map['completed_capa_count'] as int? ?? 0,
    );
  }

  AccidentInvestigation copyWith({
    int? id,
    String? eventNo,
    String? eventType,
    String? incidentTitle,
    String? incidentDate,
    String? incidentTime,
    String? incidentLocation,
    int? employeeId,
    String? employeeType,
    String? injuredPersonName,
    String? injuredPersonNationalId,
    String? injuredPersonPosition,
    String? injuredPersonDepartment,
    int? injuredPersonAge,
    double? injuredPersonWage,
    String? injuryNature,
    String? injuredBodyPart,
    String? hospitalName,
    String? hospitalSentDate,
    int? daysLost,
    double? medicalExpense,
    double? propertyDamageCost,
    String? machineInvolved,
    String? chemicalInvolved,
    String? workProcessInvolved,
    String? description5w1h,
    List<AccidentTimelineItem>? timelineEvents,
    String? witnessNames,
    List<String>? photoPaths,
    List<String>? unsafeActs,
    List<String>? unsafeConditions,
    List<String>? managementErrors,
    String? rootCauseSummary,
    List<String>? applicableLaws,
    String? inspectorName,
    String? inspectorPosition,
    String? employerAcknowledgedDate,
    String? status,
  }) {
    return AccidentInvestigation(
      id: id ?? this.id,
      eventNo: eventNo ?? this.eventNo,
      eventType: eventType ?? this.eventType,
      incidentTitle: incidentTitle ?? this.incidentTitle,
      incidentDate: incidentDate ?? this.incidentDate,
      incidentTime: incidentTime ?? this.incidentTime,
      incidentLocation: incidentLocation ?? this.incidentLocation,
      employeeId: employeeId ?? this.employeeId,
      employeeType: employeeType ?? this.employeeType,
      injuredPersonName: injuredPersonName ?? this.injuredPersonName,
      injuredPersonNationalId: injuredPersonNationalId ?? this.injuredPersonNationalId,
      injuredPersonPosition: injuredPersonPosition ?? this.injuredPersonPosition,
      injuredPersonDepartment: injuredPersonDepartment ?? this.injuredPersonDepartment,
      injuredPersonAge: injuredPersonAge ?? this.injuredPersonAge,
      injuredPersonWage: injuredPersonWage ?? this.injuredPersonWage,
      injuryNature: injuryNature ?? this.injuryNature,
      injuredBodyPart: injuredBodyPart ?? this.injuredBodyPart,
      hospitalName: hospitalName ?? this.hospitalName,
      hospitalSentDate: hospitalSentDate ?? this.hospitalSentDate,
      daysLost: daysLost ?? this.daysLost,
      medicalExpense: medicalExpense ?? this.medicalExpense,
      propertyDamageCost: propertyDamageCost ?? this.propertyDamageCost,
      machineInvolved: machineInvolved ?? this.machineInvolved,
      chemicalInvolved: chemicalInvolved ?? this.chemicalInvolved,
      workProcessInvolved: workProcessInvolved ?? this.workProcessInvolved,
      description5w1h: description5w1h ?? this.description5w1h,
      timelineEvents: timelineEvents ?? this.timelineEvents,
      witnessNames: witnessNames ?? this.witnessNames,
      photoPaths: photoPaths ?? this.photoPaths,
      unsafeActs: unsafeActs ?? this.unsafeActs,
      unsafeConditions: unsafeConditions ?? this.unsafeConditions,
      managementErrors: managementErrors ?? this.managementErrors,
      rootCauseSummary: rootCauseSummary ?? this.rootCauseSummary,
      applicableLaws: applicableLaws ?? this.applicableLaws,
      inspectorName: inspectorName ?? this.inspectorName,
      inspectorPosition: inspectorPosition ?? this.inspectorPosition,
      employerAcknowledgedDate: employerAcknowledgedDate ?? this.employerAcknowledgedDate,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt,
      capaCount: capaCount,
      completedCapaCount: completedCapaCount,
    );
  }
}

class AccidentCapaAction {
  final int? id;
  final int investigationId;
  final String controlHierarchy; // ENGINEERING, ADMINISTRATIVE, TRAINING, PPE
  final String actionDescription;
  final String responsiblePerson;
  final String targetDate;
  final String? completedDate;
  final String status; // OPEN, IN_PROGRESS, COMPLETED
  final String? evidencePhotoPath;
  final String? notes;
  final String? createdAt;

  AccidentCapaAction({
    this.id,
    required this.investigationId,
    required this.controlHierarchy,
    required this.actionDescription,
    required this.responsiblePerson,
    required this.targetDate,
    this.completedDate,
    this.status = 'OPEN',
    this.evidencePhotoPath,
    this.notes,
    this.createdAt,
  });

  String get hierarchyLabel {
    switch (controlHierarchy) {
      case 'ENGINEERING':
        return '🛠️ มาตรการด้านวิศวกรรม (Engineering Controls)';
      case 'ADMINISTRATIVE':
        return '📋 มาตรการด้านการบริหารจัดการ (Administrative Controls)';
      case 'TRAINING':
        return '🎓 มาตรการด้านการอบรม (Training Controls)';
      case 'PPE':
      default:
        return '🦺 อุปกรณ์คุ้มครองความปลอดภัยส่วนบุคคล (PPE)';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'investigation_id': investigationId,
      'control_hierarchy': controlHierarchy,
      'action_description': actionDescription,
      'responsible_person': responsiblePerson,
      'target_date': targetDate,
      'completed_date': completedDate,
      'status': status,
      'evidence_photo_path': evidencePhotoPath,
      'notes': notes,
    };
  }

  factory AccidentCapaAction.fromMap(Map<String, dynamic> map) {
    return AccidentCapaAction(
      id: map['id'] as int?,
      investigationId: map['investigation_id'] as int,
      controlHierarchy: map['control_hierarchy'] as String? ?? 'ADMINISTRATIVE',
      actionDescription: map['action_description'] as String? ?? '',
      responsiblePerson: map['responsible_person'] as String? ?? '',
      targetDate: map['target_date'] as String? ?? '',
      completedDate: map['completed_date'] as String?,
      status: map['status'] as String? ?? 'OPEN',
      evidencePhotoPath: map['evidence_photo_path'] as String?,
      notes: map['notes'] as String?,
      createdAt: map['created_at'] as String?,
    );
  }

  AccidentCapaAction copyWith({
    int? id,
    int? investigationId,
    String? controlHierarchy,
    String? actionDescription,
    String? responsiblePerson,
    String? targetDate,
    String? completedDate,
    String? status,
    String? evidencePhotoPath,
    String? notes,
  }) {
    return AccidentCapaAction(
      id: id ?? this.id,
      investigationId: investigationId ?? this.investigationId,
      controlHierarchy: controlHierarchy ?? this.controlHierarchy,
      actionDescription: actionDescription ?? this.actionDescription,
      responsiblePerson: responsiblePerson ?? this.responsiblePerson,
      targetDate: targetDate ?? this.targetDate,
      completedDate: completedDate ?? this.completedDate,
      status: status ?? this.status,
      evidencePhotoPath: evidencePhotoPath ?? this.evidencePhotoPath,
      notes: notes ?? this.notes,
      createdAt: createdAt,
    );
  }
}
