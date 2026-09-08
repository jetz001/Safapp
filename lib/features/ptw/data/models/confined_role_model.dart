import 'dart:convert';
import '../../domain/enums/confined_role_type.dart';

/// 4-Role Registration for Confined Space Entry under Ministerial Regulation B.E. 2562
class ConfinedRoleModel {
  final int? id;
  final String roleAssignmentId; // e.g. "CFR-PTW-2026-001-01"
  final String ptwNumber; // Reference to PtwModel.ptwNumber
  final ConfinedRoleType roleType;
  final String personName;
  final String? nationalId;
  final String? employeeId;
  final String companyName; // บริษัทต้นสังกัด / ผู้รับเหมา
  final String certNumber; // เลขที่ใบประกาศผ่านการอบรมที่อับอากาศ
  final String certInstitute; // หน่วยงานที่จัดฝึกอบรม
  final String certIssueDate; // วันที่ออกใบรับรอง (YYYY-MM-DD)
  final String certExpiryDate; // วันหมดอายุใบรับรอง (YYYY-MM-DD)
  final String contactPhone;
  final bool isTrainedAndCertified;
  final String? signaturePath;
  final String? createdAt;

  const ConfinedRoleModel({
    this.id,
    required this.roleAssignmentId,
    required this.ptwNumber,
    required this.roleType,
    required this.personName,
    this.nationalId,
    this.employeeId,
    required this.companyName,
    required this.certNumber,
    required this.certInstitute,
    required this.certIssueDate,
    required this.certExpiryDate,
    required this.contactPhone,
    this.isTrainedAndCertified = true,
    this.signaturePath,
    this.createdAt,
  });

  /// Check if the training certificate is valid and not expired
  bool get isCertificateValid {
    if (!isTrainedAndCertified) return false;
    if (personName.trim().isEmpty) return false;
    if (certExpiryDate.isEmpty) return true;
    try {
      final exp = DateTime.parse(certExpiryDate);
      return DateTime.now().isBefore(exp.add(const Duration(days: 1)));
    } catch (_) {
      return true;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'role_assignment_id': roleAssignmentId,
      'ptw_number': ptwNumber,
      'role_type': roleType.toDbCode(),
      'person_name': personName,
      'national_id': nationalId,
      'employee_id': employeeId,
      'company_name': companyName,
      'cert_number': certNumber,
      'cert_institute': certInstitute,
      'cert_issue_date': certIssueDate,
      'cert_expiry_date': certExpiryDate,
      'contact_phone': contactPhone,
      'is_trained_and_certified': isTrainedAndCertified ? 1 : 0,
      'signature_path': signaturePath,
      'created_at': createdAt,
    };
  }

  factory ConfinedRoleModel.fromMap(Map<String, dynamic> map) {
    return ConfinedRoleModel(
      id: map['id'] as int?,
      roleAssignmentId: map['role_assignment_id']?.toString() ?? '',
      ptwNumber: map['ptw_number']?.toString() ?? '',
      roleType: ConfinedRoleType.fromDbCode(map['role_type']?.toString()),
      personName: map['person_name']?.toString() ?? '',
      nationalId: map['national_id']?.toString(),
      employeeId: map['employee_id']?.toString(),
      companyName: map['company_name']?.toString() ?? '',
      certNumber: map['cert_number']?.toString() ?? '',
      certInstitute: map['cert_institute']?.toString() ?? '',
      certIssueDate: map['cert_issue_date']?.toString() ?? '',
      certExpiryDate: map['cert_expiry_date']?.toString() ?? '',
      contactPhone: map['contact_phone']?.toString() ?? '',
      isTrainedAndCertified: (map['is_trained_and_certified'] == 1 || map['is_trained_and_certified'] == true),
      signaturePath: map['signature_path']?.toString(),
      createdAt: map['created_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => toMap();
  factory ConfinedRoleModel.fromJson(Map<String, dynamic> json) => ConfinedRoleModel.fromMap(json);

  ConfinedRoleModel copyWith({
    int? id,
    String? roleAssignmentId,
    String? ptwNumber,
    ConfinedRoleType? roleType,
    String? personName,
    String? nationalId,
    String? employeeId,
    String? companyName,
    String? certNumber,
    String? certInstitute,
    String? certIssueDate,
    String? certExpiryDate,
    String? contactPhone,
    bool? isTrainedAndCertified,
    String? signaturePath,
    String? createdAt,
  }) {
    return ConfinedRoleModel(
      id: id ?? this.id,
      roleAssignmentId: roleAssignmentId ?? this.roleAssignmentId,
      ptwNumber: ptwNumber ?? this.ptwNumber,
      roleType: roleType ?? this.roleType,
      personName: personName ?? this.personName,
      nationalId: nationalId ?? this.nationalId,
      employeeId: employeeId ?? this.employeeId,
      companyName: companyName ?? this.companyName,
      certNumber: certNumber ?? this.certNumber,
      certInstitute: certInstitute ?? this.certInstitute,
      certIssueDate: certIssueDate ?? this.certIssueDate,
      certExpiryDate: certExpiryDate ?? this.certExpiryDate,
      contactPhone: contactPhone ?? this.contactPhone,
      isTrainedAndCertified: isTrainedAndCertified ?? this.isTrainedAndCertified,
      signaturePath: signaturePath ?? this.signaturePath,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() => 'ConfinedRoleModel(roleAssignmentId: $roleAssignmentId, role: ${roleType.toDbCode()}, name: $personName, cert: $certNumber, valid: $isCertificateValid)';
}
