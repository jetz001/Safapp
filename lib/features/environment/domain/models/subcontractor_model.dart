import 'dart:convert';

/// Subcontractor and service provider classification under Thai OSH Act B.E. 2554.
enum SubcontractorType {
  section9Individual,
  section11Juristic,
  internalJpo;

  String toDbCode() {
    switch (this) {
      case SubcontractorType.section9Individual:
        return 'SECTION_9_INDIVIDUAL';
      case SubcontractorType.section11Juristic:
        return 'SECTION_11_JURISTIC';
      case SubcontractorType.internalJpo:
        return 'INTERNAL_JPO';
    }
  }

  static SubcontractorType fromDbCode(String? code) {
    switch (code?.toUpperCase()) {
      case 'SECTION_9_INDIVIDUAL':
      case 'M9_INDIVIDUAL':
      case 'SECTION_9':
        return SubcontractorType.section9Individual;
      case 'SECTION_11_JURISTIC':
      case 'M11_JURISTIC':
      case 'SECTION_11':
        return SubcontractorType.section11Juristic;
      case 'INTERNAL_JPO':
      case 'JPO':
        return SubcontractorType.internalJpo;
      default:
        return SubcontractorType.section11Juristic;
    }
  }

  String get labelTh {
    switch (this) {
      case SubcontractorType.section9Individual:
        return 'บุคคลธรรมดาขึ้นทะเบียน (ม.๙ นบ.)';
      case SubcontractorType.section11Juristic:
        return 'นิติบุคคลได้รับใบอนุญาต (ม.๑๑ บ.)';
      case SubcontractorType.internalJpo:
        return 'จป.วิชาชีพ ประจำสถานประกอบการ';
    }
  }

  String get expectedPrefix {
    switch (this) {
      case SubcontractorType.section9Individual:
        return 'นบ.';
      case SubcontractorType.section11Juristic:
        return 'บ.';
      case SubcontractorType.internalJpo:
        return 'จป.ว';
    }
  }
}

/// Model representing a Measurement Service Provider / Subcontractor (ม.๙ / ม.๑๑).
class SubcontractorModel {
  final int? id;
  final String subcontractorId;
  final SubcontractorType subcontractorType;
  final String companyName;
  final String registrationNumber; // e.g. 'นบ. 0123-45/2566' or 'บ. 0045-12/2565'
  final String? contactPerson;
  final String? contactPhone;
  final String? contactEmail;
  final String? address;
  final String? licenseIssueDate;
  final String? licenseExpireDate;
  final String surveyorName; // ผู้ทำการตรวจวัด
  final String? surveyorLicenseNo;
  final String certifierName; // ผู้รับรองรายงาน
  final String? certifierRegNo;
  final String? licenseDocPath;
  final List<String> calibrationCertPaths;
  final bool isVerified;
  final String? notes;

  const SubcontractorModel({
    this.id,
    required this.subcontractorId,
    required this.subcontractorType,
    required this.companyName,
    required this.registrationNumber,
    this.contactPerson,
    this.contactPhone,
    this.contactEmail,
    this.address,
    this.licenseIssueDate,
    this.licenseExpireDate,
    required this.surveyorName,
    this.surveyorLicenseNo,
    required this.certifierName,
    this.certifierRegNo,
    this.licenseDocPath,
    this.calibrationCertPaths = const [],
    this.isVerified = true,
    this.notes,
  });

  /// Check if license registration format matches the required statutory prefix
  bool get hasValidRegistrationPrefix {
    final cleaned = registrationNumber.trim();
    if (subcontractorType == SubcontractorType.section9Individual) {
      return cleaned.startsWith('นบ.') || cleaned.startsWith('นบ');
    } else if (subcontractorType == SubcontractorType.section11Juristic) {
      return cleaned.startsWith('บ.') || cleaned.startsWith('บ ');
    }
    return true;
  }

  /// Check if the subcontractor license is currently expired
  bool get isExpired {
    if (licenseExpireDate == null || licenseExpireDate!.isEmpty) return false;
    try {
      final exp = DateTime.parse(licenseExpireDate!);
      return exp.isBefore(DateTime.now());
    } catch (_) {
      return false;
    }
  }

  /// Days remaining until license expiration
  int? get daysUntilExpiration {
    if (licenseExpireDate == null || licenseExpireDate!.isEmpty) return null;
    try {
      final exp = DateTime.parse(licenseExpireDate!);
      return exp.difference(DateTime.now()).inDays;
    } catch (_) {
      return null;
    }
  }

  SubcontractorModel copyWith({
    int? id,
    String? subcontractorId,
    SubcontractorType? subcontractorType,
    String? companyName,
    String? registrationNumber,
    String? contactPerson,
    String? contactPhone,
    String? contactEmail,
    String? address,
    String? licenseIssueDate,
    String? licenseExpireDate,
    String? surveyorName,
    String? surveyorLicenseNo,
    String? certifierName,
    String? certifierRegNo,
    String? licenseDocPath,
    List<String>? calibrationCertPaths,
    bool? isVerified,
    String? notes,
  }) {
    return SubcontractorModel(
      id: id ?? this.id,
      subcontractorId: subcontractorId ?? this.subcontractorId,
      subcontractorType: subcontractorType ?? this.subcontractorType,
      companyName: companyName ?? this.companyName,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      contactPerson: contactPerson ?? this.contactPerson,
      contactPhone: contactPhone ?? this.contactPhone,
      contactEmail: contactEmail ?? this.contactEmail,
      address: address ?? this.address,
      licenseIssueDate: licenseIssueDate ?? this.licenseIssueDate,
      licenseExpireDate: licenseExpireDate ?? this.licenseExpireDate,
      surveyorName: surveyorName ?? this.surveyorName,
      surveyorLicenseNo: surveyorLicenseNo ?? this.surveyorLicenseNo,
      certifierName: certifierName ?? this.certifierName,
      certifierRegNo: certifierRegNo ?? this.certifierRegNo,
      licenseDocPath: licenseDocPath ?? this.licenseDocPath,
      calibrationCertPaths: calibrationCertPaths ?? this.calibrationCertPaths,
      isVerified: isVerified ?? this.isVerified,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'subcontractor_id': subcontractorId,
      'subcontractor_type': subcontractorType.toDbCode(),
      'company_name': companyName,
      'registration_number': registrationNumber,
      'contact_person': contactPerson,
      'contact_phone': contactPhone,
      'contact_email': contactEmail,
      'address': address,
      'license_issue_date': licenseIssueDate,
      'license_expire_date': licenseExpireDate,
      'surveyor_name': surveyorName,
      'surveyor_license_no': surveyorLicenseNo,
      'certifier_name': certifierName,
      'certifier_reg_no': certifierRegNo,
      'license_doc_path': licenseDocPath,
      'calibration_cert_paths': json.encode(calibrationCertPaths),
      'is_verified': isVerified ? 1 : 0,
      'notes': notes,
    };
  }

  factory SubcontractorModel.fromMap(Map<String, dynamic> map) {
    List<String> certPaths = [];
    final rawCerts = map['calibration_cert_paths'] ?? map['calibrationCertPaths'];
    if (rawCerts is String && rawCerts.isNotEmpty) {
      try {
        final decoded = json.decode(rawCerts);
        if (decoded is List) {
          certPaths = decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {
        certPaths = [rawCerts];
      }
    } else if (rawCerts is List) {
      certPaths = rawCerts.map((e) => e.toString()).toList();
    }

    return SubcontractorModel(
      id: map['id'] as int?,
      subcontractorId: map['subcontractor_id'] as String? ?? map['subcontractorId'] as String? ?? '',
      subcontractorType: SubcontractorType.fromDbCode(
        map['subcontractor_type'] as String? ?? map['subcontractorType'] as String?,
      ),
      companyName: map['company_name'] as String? ?? map['companyName'] as String? ?? '',
      registrationNumber: map['registration_number'] as String? ?? map['registrationNumber'] as String? ?? '',
      contactPerson: map['contact_person'] as String? ?? map['contactPerson'] as String?,
      contactPhone: map['contact_phone'] as String? ?? map['contactPhone'] as String?,
      contactEmail: map['contact_email'] as String? ?? map['contactEmail'] as String?,
      address: map['address'] as String?,
      licenseIssueDate: map['license_issue_date'] as String? ?? map['licenseIssueDate'] as String?,
      licenseExpireDate: map['license_expire_date'] as String? ?? map['licenseExpireDate'] as String?,
      surveyorName: map['surveyor_name'] as String? ?? map['surveyorName'] as String? ?? '',
      surveyorLicenseNo: map['surveyor_license_no'] as String? ?? map['surveyorLicenseNo'] as String?,
      certifierName: map['certifier_name'] as String? ?? map['certifierName'] as String? ?? '',
      certifierRegNo: map['certifier_reg_no'] as String? ?? map['certifierRegNo'] as String?,
      licenseDocPath: map['license_doc_path'] as String? ?? map['licenseDocPath'] as String?,
      calibrationCertPaths: certPaths,
      isVerified: map['is_verified'] == 1 || map['is_verified'] == true || map['isVerified'] == true,
      notes: map['notes'] as String?,
    );
  }

  String toJson() => json.encode(toMap());

  factory SubcontractorModel.fromJson(String source) =>
      SubcontractorModel.fromMap(json.decode(source) as Map<String, dynamic>);
}
