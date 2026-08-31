import 'dart:convert';

class ContractorCompany {
  final int? id;
  final String companyName;
  final String? taxId;
  final String serviceType;
  final String? contactPerson;
  final String? phone;
  final String? email;
  final String? safetyOfficerName;
  final String? safetyOfficerPhone;
  final int safetyScore;
  final String status; // 'ACTIVE', 'SUSPENDED', 'BLACKLISTED'
  final String? notes;
  final String? createdAt;
  final String? updatedAt;

  // Transient / aggregated fields
  final int? workerCount;
  final int? violationCount;

  const ContractorCompany({
    this.id,
    required this.companyName,
    this.taxId,
    required this.serviceType,
    this.contactPerson,
    this.phone,
    this.email,
    this.safetyOfficerName,
    this.safetyOfficerPhone,
    this.safetyScore = 100,
    this.status = 'ACTIVE',
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.workerCount,
    this.violationCount,
  });

  String get safetyGrade {
    if (safetyScore >= 90) return 'Grade A (ดีเยี่ยม)';
    if (safetyScore >= 75) return 'Grade B (ดี)';
    if (safetyScore >= 60) return 'Grade C (พอใช้)';
    return 'Grade D (ต้องปรับปรุง)';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'company_name': companyName,
      'tax_id': taxId,
      'service_type': serviceType,
      'contact_person': contactPerson,
      'phone': phone,
      'email': email,
      'safety_officer_name': safetyOfficerName,
      'safety_officer_phone': safetyOfficerPhone,
      'safety_score': safetyScore,
      'status': status,
      'notes': notes,
      'created_at': createdAt ?? DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  factory ContractorCompany.fromMap(Map<String, dynamic> map) {
    return ContractorCompany(
      id: map['id'] as int?,
      companyName: map['company_name'] ?? '',
      taxId: map['tax_id'],
      serviceType: map['service_type'] ?? 'งานทั่วไป',
      contactPerson: map['contact_person'],
      phone: map['phone'],
      email: map['email'],
      safetyOfficerName: map['safety_officer_name'],
      safetyOfficerPhone: map['safety_officer_phone'],
      safetyScore: map['safety_score'] as int? ?? 100,
      status: map['status'] ?? 'ACTIVE',
      notes: map['notes'],
      createdAt: map['created_at'],
      updatedAt: map['updated_at'],
      workerCount: map['worker_count'] as int?,
      violationCount: map['violation_count'] as int?,
    );
  }

  ContractorCompany copyWith({
    int? id,
    String? companyName,
    String? taxId,
    String? serviceType,
    String? contactPerson,
    String? phone,
    String? email,
    String? safetyOfficerName,
    String? safetyOfficerPhone,
    int? safetyScore,
    String? status,
    String? notes,
    String? createdAt,
    String? updatedAt,
    int? workerCount,
    int? violationCount,
  }) {
    return ContractorCompany(
      id: id ?? this.id,
      companyName: companyName ?? this.companyName,
      taxId: taxId ?? this.taxId,
      serviceType: serviceType ?? this.serviceType,
      contactPerson: contactPerson ?? this.contactPerson,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      safetyOfficerName: safetyOfficerName ?? this.safetyOfficerName,
      safetyOfficerPhone: safetyOfficerPhone ?? this.safetyOfficerPhone,
      safetyScore: safetyScore ?? this.safetyScore,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      workerCount: workerCount ?? this.workerCount,
      violationCount: violationCount ?? this.violationCount,
    );
  }
}

class ContractorWorker {
  final int? id;
  final int contractorId;
  final String workerName;
  final String? nationalIdOrPassport;
  final String jobRole; // 'หัวหน้างาน', 'ช่างเชื่อม', 'งานบนที่สูง', 'ช่างไฟฟ้า', 'งานเครื่องกล', 'คนงานทั่วไป'
  final String? photoPath;
  final String? inductionDate;
  final String? inductionValidUntil;
  final String? certFilePath;
  final String status; // 'ACTIVE', 'INACTIVE'
  final String? notes;
  final String? createdAt;
  final String? updatedAt;

  // Joined fields
  final String? contractorName;

  const ContractorWorker({
    this.id,
    required this.contractorId,
    required this.workerName,
    this.nationalIdOrPassport,
    required this.jobRole,
    this.photoPath,
    this.inductionDate,
    this.inductionValidUntil,
    this.certFilePath,
    this.status = 'ACTIVE',
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.contractorName,
  });

  /// คำนวณสถานะความปลอดภัยและการเข้าทำงาน
  String get inductionStatus {
    if (inductionDate == null || inductionDate!.isEmpty) {
      return 'PENDING'; // ยังไม่อบรม
    }
    if (inductionValidUntil == null || inductionValidUntil!.isEmpty) {
      return 'VALID'; // ผ่านอบรม
    }
    final expiry = DateTime.tryParse(inductionValidUntil!);
    if (expiry == null) return 'VALID';

    final now = DateTime.now();
    if (now.isAfter(expiry)) {
      return 'EXPIRED'; // หมดอายุ
    }
    final diffDays = expiry.difference(now).inDays;
    if (diffDays <= 30) {
      return 'EXPIRING_SOON'; // ใกล้หมดอายุ
    }
    return 'VALID'; // ปกติ
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'contractor_id': contractorId,
      'worker_name': workerName,
      'national_id_or_passport': nationalIdOrPassport,
      'job_role': jobRole,
      'photo_path': photoPath,
      'induction_date': inductionDate,
      'induction_valid_until': inductionValidUntil,
      'cert_file_path': certFilePath,
      'status': status,
      'notes': notes,
      'created_at': createdAt ?? DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  factory ContractorWorker.fromMap(Map<String, dynamic> map) {
    return ContractorWorker(
      id: map['id'] as int?,
      contractorId: map['contractor_id'] as int? ?? 0,
      workerName: map['worker_name'] ?? '',
      nationalIdOrPassport: map['national_id_or_passport'],
      jobRole: map['job_role'] ?? 'คนงานทั่วไป',
      photoPath: map['photo_path'],
      inductionDate: map['induction_date'],
      inductionValidUntil: map['induction_valid_until'],
      certFilePath: map['cert_file_path'],
      status: map['status'] ?? 'ACTIVE',
      notes: map['notes'],
      createdAt: map['created_at'],
      updatedAt: map['updated_at'],
      contractorName: map['company_name'],
    );
  }

  ContractorWorker copyWith({
    int? id,
    int? contractorId,
    String? workerName,
    String? nationalIdOrPassport,
    String? jobRole,
    String? photoPath,
    String? inductionDate,
    String? inductionValidUntil,
    String? certFilePath,
    String? status,
    String? notes,
    String? createdAt,
    String? updatedAt,
    String? contractorName,
  }) {
    return ContractorWorker(
      id: id ?? this.id,
      contractorId: contractorId ?? this.contractorId,
      workerName: workerName ?? this.workerName,
      nationalIdOrPassport: nationalIdOrPassport ?? this.nationalIdOrPassport,
      jobRole: jobRole ?? this.jobRole,
      photoPath: photoPath ?? this.photoPath,
      inductionDate: inductionDate ?? this.inductionDate,
      inductionValidUntil: inductionValidUntil ?? this.inductionValidUntil,
      certFilePath: certFilePath ?? this.certFilePath,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      contractorName: contractorName ?? this.contractorName,
    );
  }
}

class ContractorViolation {
  final int? id;
  final int contractorId;
  final int? workerId;
  final String incidentDate;
  final String violationType; // 'ไม่สวมใส่อุปกรณ์ PPE', 'ฝ่าฝืนข้อกำหนดใบงาน PTW', 'การกระทำที่ไม่ปลอดภัย (Unsafe Act)', 'สภาพแวดล้อมไม่ปลอดภัย (Unsafe Condition)', 'อื่นๆ'
  final String severityLevel; // 'MINOR' (ตักเตือน), 'MODERATE' (ตัดคะแนน), 'SEVERE' (ระงับงานชั่วคราว)
  final String description;
  final String actionTaken;
  final int scoreDeducted;
  final String? inspectorName;
  final List<String> photoPaths;
  final String status; // 'OPEN', 'RESOLVED'
  final String? createdAt;

  // Joined fields
  final String? contractorName;
  final String? workerName;

  const ContractorViolation({
    this.id,
    required this.contractorId,
    this.workerId,
    required this.incidentDate,
    required this.violationType,
    this.severityLevel = 'MINOR',
    required this.description,
    required this.actionTaken,
    this.scoreDeducted = 0,
    this.inspectorName,
    this.photoPaths = const [],
    this.status = 'OPEN',
    this.createdAt,
    this.contractorName,
    this.workerName,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'contractor_id': contractorId,
      'worker_id': workerId,
      'incident_date': incidentDate,
      'violation_type': violationType,
      'severity_level': severityLevel,
      'description': description,
      'action_taken': actionTaken,
      'score_deducted': scoreDeducted,
      'inspector_name': inspectorName,
      'photo_paths': jsonEncode(photoPaths),
      'status': status,
      'created_at': createdAt ?? DateTime.now().toIso8601String(),
    };
  }

  factory ContractorViolation.fromMap(Map<String, dynamic> map) {
    List<String> parsedPhotos = [];
    if (map['photo_paths'] != null) {
      try {
        final decoded = jsonDecode(map['photo_paths']);
        if (decoded is List) {
          parsedPhotos = decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {
        if (map['photo_paths'] is String && (map['photo_paths'] as String).isNotEmpty) {
          parsedPhotos = [(map['photo_paths'] as String)];
        }
      }
    }

    return ContractorViolation(
      id: map['id'] as int?,
      contractorId: map['contractor_id'] as int? ?? 0,
      workerId: map['worker_id'] as int?,
      incidentDate: map['incident_date'] ?? '',
      violationType: map['violation_type'] ?? '',
      severityLevel: map['severity_level'] ?? 'MINOR',
      description: map['description'] ?? '',
      actionTaken: map['action_taken'] ?? '',
      scoreDeducted: map['score_deducted'] as int? ?? 0,
      inspectorName: map['inspector_name'],
      photoPaths: parsedPhotos,
      status: map['status'] ?? 'OPEN',
      createdAt: map['created_at'],
      contractorName: map['company_name'],
      workerName: map['worker_name'],
    );
  }
}
