class Employee {
  final int? id;
  final String employeeCode;
  final String fullName;
  final String? nationalId;
  final String department;
  final String position;
  final String safetyRole; // GENERAL, SUPERVISOR_SAFETY, EXECUTIVE_SAFETY, COMMITTEE_MEMBER, ERT_FIREFIGHTER, FIRST_AIDER
  final String? hireDate;
  final String? phone;
  final String? email;
  final String? photoPath;
  final String status; // ACTIVE, RESIGNED, SUSPENDED
  final String? createdAt;
  final String? updatedAt;

  // Computed from joins
  final double totalTrainingHours;
  final int validTrainingCount;
  final int expiredTrainingCount;

  Employee({
    this.id,
    required this.employeeCode,
    required this.fullName,
    this.nationalId,
    required this.department,
    required this.position,
    this.safetyRole = 'GENERAL',
    this.hireDate,
    this.phone,
    this.email,
    this.photoPath,
    this.status = 'ACTIVE',
    this.createdAt,
    this.updatedAt,
    this.totalTrainingHours = 0.0,
    this.validTrainingCount = 0,
    this.expiredTrainingCount = 0,
  });

  String get safetyRoleLabel {
    switch (safetyRole) {
      case 'SUPERVISOR_SAFETY':
        return 'จป.ระดับหัวหน้างาน';
      case 'EXECUTIVE_SAFETY':
        return 'จป.ระดับบริหาร';
      case 'COMMITTEE_MEMBER':
        return 'กรรมการ คปอ.';
      case 'ERT_FIREFIGHTER':
        return 'ทีมผจญเพลิง / ERT';
      case 'FIRST_AIDER':
        return 'ผู้ช่วยเหลือปฐมพยาบาล First Aid';
      case 'GENERAL':
      default:
        return 'พนักงานทั่วไป';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'employee_code': employeeCode,
      'full_name': fullName,
      'national_id': nationalId,
      'department': department,
      'position': position,
      'safety_role': safetyRole,
      'hire_date': hireDate,
      'phone': phone,
      'email': email,
      'photo_path': photoPath,
      'status': status,
    };
  }

  factory Employee.fromMap(Map<String, dynamic> map) {
    return Employee(
      id: map['id'] as int?,
      employeeCode: map['employee_code'] as String? ?? '',
      fullName: map['full_name'] as String? ?? '',
      nationalId: map['national_id'] as String?,
      department: map['department'] as String? ?? '',
      position: map['position'] as String? ?? '',
      safetyRole: map['safety_role'] as String? ?? 'GENERAL',
      hireDate: map['hire_date'] as String?,
      phone: map['phone'] as String?,
      email: map['email'] as String?,
      photoPath: map['photo_path'] as String?,
      status: map['status'] as String? ?? 'ACTIVE',
      createdAt: map['created_at'] as String?,
      updatedAt: map['updated_at'] as String?,
      totalTrainingHours: (map['total_hours'] as num?)?.toDouble() ?? 0.0,
      validTrainingCount: map['valid_count'] as int? ?? 0,
      expiredTrainingCount: map['expired_count'] as int? ?? 0,
    );
  }

  Employee copyWith({
    int? id,
    String? employeeCode,
    String? fullName,
    String? nationalId,
    String? department,
    String? position,
    String? safetyRole,
    String? hireDate,
    String? phone,
    String? email,
    String? photoPath,
    String? status,
    double? totalTrainingHours,
    int? validTrainingCount,
    int? expiredTrainingCount,
  }) {
    return Employee(
      id: id ?? this.id,
      employeeCode: employeeCode ?? this.employeeCode,
      fullName: fullName ?? this.fullName,
      nationalId: nationalId ?? this.nationalId,
      department: department ?? this.department,
      position: position ?? this.position,
      safetyRole: safetyRole ?? this.safetyRole,
      hireDate: hireDate ?? this.hireDate,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      photoPath: photoPath ?? this.photoPath,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt,
      totalTrainingHours: totalTrainingHours ?? this.totalTrainingHours,
      validTrainingCount: validTrainingCount ?? this.validTrainingCount,
      expiredTrainingCount: expiredTrainingCount ?? this.expiredTrainingCount,
    );
  }
}

class TrainingCourse {
  final int? id;
  final String courseCode;
  final String courseName;
  final String category; // LEGAL_MANDATORY, REFRESHER_ANNUAL, SPECIALIZED, GENERAL_SAFETY
  final double durationHours;
  final int validityYears; // 0 = No expiry
  final String? description;
  final bool isDefault;

  TrainingCourse({
    this.id,
    required this.courseCode,
    required this.courseName,
    required this.category,
    this.durationHours = 6.0,
    this.validityYears = 0,
    this.description,
    this.isDefault = false,
  });

  String get categoryLabel {
    switch (category) {
      case 'LEGAL_MANDATORY':
        return 'หลักสูตรตามกฎหมายบังคับ';
      case 'REFRESHER_ANNUAL':
        return 'หลักสูตรทบทวนประจำปี';
      case 'SPECIALIZED':
        return 'งานที่มีความเสี่ยงเฉพาะด้าน';
      case 'GENERAL_SAFETY':
      default:
        return 'ความปลอดภัยทั่วไป';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'course_code': courseCode,
      'course_name': courseName,
      'category': category,
      'duration_hours': durationHours,
      'validity_years': validityYears,
      'description': description,
      'is_default': isDefault ? 1 : 0,
    };
  }

  factory TrainingCourse.fromMap(Map<String, dynamic> map) {
    return TrainingCourse(
      id: map['id'] as int?,
      courseCode: map['course_code'] as String? ?? '',
      courseName: map['course_name'] as String? ?? '',
      category: map['category'] as String? ?? 'GENERAL_SAFETY',
      durationHours: (map['duration_hours'] as num?)?.toDouble() ?? 6.0,
      validityYears: map['validity_years'] as int? ?? 0,
      description: map['description'] as String?,
      isDefault: (map['is_default'] as int? ?? 0) == 1,
    );
  }
}

class TrainingRecord {
  final int? id;
  final int employeeId;
  final int courseId;
  final String trainingDate;
  final String? expiryDate;
  final String? organizerName;
  final String? trainerName;
  final String? certNumber;
  final String? certFilePath;
  final double? score;
  final bool passed;
  final String? notes;
  final String? createdAt;

  // Joined fields
  final String? employeeCode;
  final String? employeeName;
  final String? department;
  final String? position;
  final String? courseCode;
  final String? courseName;
  final String? courseCategory;
  final double durationHours;
  final int validityYears;

  TrainingRecord({
    this.id,
    required this.employeeId,
    required this.courseId,
    required this.trainingDate,
    this.expiryDate,
    this.organizerName,
    this.trainerName,
    this.certNumber,
    this.certFilePath,
    this.score,
    this.passed = true,
    this.notes,
    this.createdAt,
    this.employeeCode,
    this.employeeName,
    this.department,
    this.position,
    this.courseCode,
    this.courseName,
    this.courseCategory,
    this.durationHours = 6.0,
    this.validityYears = 0,
  });

  /// VALID, EXPIRING_SOON, EXPIRED, NO_EXPIRY
  String get status {
    if (expiryDate == null || expiryDate!.isEmpty) return 'NO_EXPIRY';
    try {
      final exp = DateTime.parse(expiryDate!);
      final now = DateTime.now();
      final diff = exp.difference(now).inDays;

      if (diff < 0) return 'EXPIRED';
      if (diff <= 30) return 'EXPIRING_SOON';
      return 'VALID';
    } catch (_) {
      return 'NO_EXPIRY';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'employee_id': employeeId,
      'course_id': courseId,
      'training_date': trainingDate,
      'expiry_date': expiryDate,
      'organizer_name': organizerName,
      'trainer_name': trainerName,
      'cert_number': certNumber,
      'cert_file_path': certFilePath,
      'score': score,
      'passed': passed ? 1 : 0,
      'notes': notes,
    };
  }

  factory TrainingRecord.fromMap(Map<String, dynamic> map) {
    return TrainingRecord(
      id: map['id'] as int?,
      employeeId: map['employee_id'] as int,
      courseId: map['course_id'] as int,
      trainingDate: map['training_date'] as String? ?? '',
      expiryDate: map['expiry_date'] as String?,
      organizerName: map['organizer_name'] as String?,
      trainerName: map['trainer_name'] as String?,
      certNumber: map['cert_number'] as String?,
      certFilePath: map['cert_file_path'] as String?,
      score: (map['score'] as num?)?.toDouble(),
      passed: (map['passed'] as int? ?? 1) == 1,
      notes: map['notes'] as String?,
      createdAt: map['created_at'] as String?,
      employeeCode: map['employee_code'] as String?,
      employeeName: map['full_name'] as String?,
      department: map['department'] as String?,
      position: map['position'] as String?,
      courseCode: map['course_code'] as String?,
      courseName: map['course_name'] as String?,
      courseCategory: map['category'] as String?,
      durationHours: (map['duration_hours'] as num?)?.toDouble() ?? 6.0,
      validityYears: map['validity_years'] as int? ?? 0,
    );
  }

  TrainingRecord copyWith({
    int? id,
    int? employeeId,
    int? courseId,
    String? trainingDate,
    String? expiryDate,
    String? organizerName,
    String? trainerName,
    String? certNumber,
    String? certFilePath,
    double? score,
    bool? passed,
    String? notes,
  }) {
    return TrainingRecord(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      courseId: courseId ?? this.courseId,
      trainingDate: trainingDate ?? this.trainingDate,
      expiryDate: expiryDate ?? this.expiryDate,
      organizerName: organizerName ?? this.organizerName,
      trainerName: trainerName ?? this.trainerName,
      certNumber: certNumber ?? this.certNumber,
      certFilePath: certFilePath ?? this.certFilePath,
      score: score ?? this.score,
      passed: passed ?? this.passed,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      employeeCode: employeeCode,
      employeeName: employeeName,
      department: department,
      position: position,
      courseCode: courseCode,
      courseName: courseName,
      courseCategory: courseCategory,
      durationHours: durationHours,
      validityYears: validityYears,
    );
  }
}

class SafetyCommitteeMember {
  final int? id;
  final String termYear;
  final int employeeId;
  final String committeePosition; // CHAIR_EMPLOYER_REP, EMPLOYER_REP, EMPLOYEE_REP, SECRETARY_SAFETY_OFFICER
  final String? appointedDate;
  final String? termEndDate;
  final String status;

  // Joined
  final String? employeeCode;
  final String? employeeName;
  final String? department;
  final String? position;
  final String? photoPath;

  SafetyCommitteeMember({
    this.id,
    required this.termYear,
    required this.employeeId,
    required this.committeePosition,
    this.appointedDate,
    this.termEndDate,
    this.status = 'ACTIVE',
    this.employeeCode,
    this.employeeName,
    this.department,
    this.position,
    this.photoPath,
  });

  String get positionLabel {
    switch (committeePosition) {
      case 'CHAIR_EMPLOYER_REP':
        return 'ประธาน คปอ. (ผู้แทนนายจ้างระดับบริหาร)';
      case 'EMPLOYER_REP':
        return 'กรรมการ (ผู้แทนนายจ้างระดับบังคับบัญชา)';
      case 'EMPLOYEE_REP':
        return 'กรรมการ (ผู้แทนลูกจ้างจากการเลือกตั้ง)';
      case 'SECRETARY_SAFETY_OFFICER':
      default:
        return 'เลขานุการ คปอ. (จป.วิชาชีพ)';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'term_year': termYear,
      'employee_id': employeeId,
      'committee_position': committeePosition,
      'appointed_date': appointedDate,
      'term_end_date': termEndDate,
      'status': status,
    };
  }

  factory SafetyCommitteeMember.fromMap(Map<String, dynamic> map) {
    return SafetyCommitteeMember(
      id: map['id'] as int?,
      termYear: map['term_year'] as String? ?? '',
      employeeId: map['employee_id'] as int,
      committeePosition: map['committee_position'] as String? ?? 'EMPLOYEE_REP',
      appointedDate: map['appointed_date'] as String?,
      termEndDate: map['term_end_date'] as String?,
      status: map['status'] as String? ?? 'ACTIVE',
      employeeCode: map['employee_code'] as String?,
      employeeName: map['full_name'] as String?,
      department: map['department'] as String?,
      position: map['position'] as String?,
      photoPath: map['photo_path'] as String?,
    );
  }
}
