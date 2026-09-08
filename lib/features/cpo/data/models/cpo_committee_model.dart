import '../../domain/enums/cpo_member_role.dart';

class CpoTermModel {
  final int? id;
  final String termCode;
  final String termTitle;
  final String startDate;
  final String endDate;
  final int employeeCount;
  final int requiredQuota;
  final int employerRepCount;
  final int employeeRepCount;
  final int secretaryCount;
  final String? appointmentDocNo;
  final String? appointmentDate;
  final String status;
  final String? notes;
  final String? createdAt;
  final String? updatedAt;
  final List<CpoMemberModel> members;

  const CpoTermModel({
    this.id,
    required this.termCode,
    required this.termTitle,
    required this.startDate,
    required this.endDate,
    this.employeeCount = 0,
    this.requiredQuota = 5,
    this.employerRepCount = 2,
    this.employeeRepCount = 2,
    this.secretaryCount = 1,
    this.appointmentDocNo,
    this.appointmentDate,
    this.status = 'ACTIVE',
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.members = const [],
  });

  bool get isExpired {
    try {
      final end = DateTime.parse(endDate);
      return DateTime.now().isAfter(end);
    } catch (_) {
      return false;
    }
  }

  int get remainingDays {
    try {
      final end = DateTime.parse(endDate);
      return end.difference(DateTime.now()).inDays;
    } catch (_) {
      return 0;
    }
  }

  bool get isQuotaCompliant => members.length >= requiredQuota;
  bool get isActive => status == 'ACTIVE';

  CpoTermModel copyWith({
    int? id,
    String? termCode,
    String? termTitle,
    String? startDate,
    String? endDate,
    int? employeeCount,
    int? requiredQuota,
    int? employerRepCount,
    int? employeeRepCount,
    int? secretaryCount,
    String? appointmentDocNo,
    String? appointmentDate,
    String? status,
    String? notes,
    String? createdAt,
    String? updatedAt,
    List<CpoMemberModel>? members,
  }) {
    return CpoTermModel(
      id: id ?? this.id,
      termCode: termCode ?? this.termCode,
      termTitle: termTitle ?? this.termTitle,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      employeeCount: employeeCount ?? this.employeeCount,
      requiredQuota: requiredQuota ?? this.requiredQuota,
      employerRepCount: employerRepCount ?? this.employerRepCount,
      employeeRepCount: employeeRepCount ?? this.employeeRepCount,
      secretaryCount: secretaryCount ?? this.secretaryCount,
      appointmentDocNo: appointmentDocNo ?? this.appointmentDocNo,
      appointmentDate: appointmentDate ?? this.appointmentDate,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      members: members ?? this.members,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'term_code': termCode,
      'term_title': termTitle,
      'start_date': startDate,
      'end_date': endDate,
      'employee_count': employeeCount,
      'required_quota': requiredQuota,
      'employer_rep_count': employerRepCount,
      'employee_rep_count': employeeRepCount,
      'secretary_count': secretaryCount,
      'appointment_doc_no': appointmentDocNo,
      'appointment_date': appointmentDate,
      'status': status,
      'notes': notes,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory CpoTermModel.fromMap(Map<String, dynamic> map, {List<CpoMemberModel> members = const []}) {
    return CpoTermModel(
      id: map['id'] as int?,
      termCode: map['term_code']?.toString() ?? '',
      termTitle: map['term_title']?.toString() ?? '',
      startDate: map['start_date']?.toString() ?? '',
      endDate: map['end_date']?.toString() ?? '',
      employeeCount: (map['employee_count'] as num?)?.toInt() ?? 0,
      requiredQuota: (map['required_quota'] as num?)?.toInt() ?? 5,
      employerRepCount: (map['employer_rep_count'] as num?)?.toInt() ?? 2,
      employeeRepCount: (map['employee_rep_count'] as num?)?.toInt() ?? 2,
      secretaryCount: (map['secretary_count'] as num?)?.toInt() ?? 1,
      appointmentDocNo: map['appointment_doc_no']?.toString(),
      appointmentDate: map['appointment_date']?.toString(),
      status: map['status']?.toString() ?? 'ACTIVE',
      notes: map['notes']?.toString(),
      createdAt: map['created_at']?.toString(),
      updatedAt: map['updated_at']?.toString(),
      members: members,
    );
  }
}

class CpoMemberModel {
  final int? id;
  final int termId;
  final int? employeeId;
  final String fullName;
  final String? employeeCode;
  final String? department;
  final String? companyPosition;
  final CpoMemberRole cpoRole;
  final String appointmentType; // APPOINTED, ELECTED
  final int votesReceived;
  final String? phone;
  final String? email;
  final String status;
  final String? createdAt;

  const CpoMemberModel({
    this.id,
    required this.termId,
    this.employeeId,
    required this.fullName,
    this.employeeCode,
    this.department,
    this.companyPosition,
    required this.cpoRole,
    this.appointmentType = 'APPOINTED',
    this.votesReceived = 0,
    this.phone,
    this.email,
    this.status = 'ACTIVE',
    this.createdAt,
  });

  CpoMemberModel copyWith({
    int? id,
    int? termId,
    int? employeeId,
    String? fullName,
    String? employeeCode,
    String? department,
    String? companyPosition,
    CpoMemberRole? cpoRole,
    String? appointmentType,
    int? votesReceived,
    String? phone,
    String? email,
    String? status,
    String? createdAt,
  }) {
    return CpoMemberModel(
      id: id ?? this.id,
      termId: termId ?? this.termId,
      employeeId: employeeId ?? this.employeeId,
      fullName: fullName ?? this.fullName,
      employeeCode: employeeCode ?? this.employeeCode,
      department: department ?? this.department,
      companyPosition: companyPosition ?? this.companyPosition,
      cpoRole: cpoRole ?? this.cpoRole,
      appointmentType: appointmentType ?? this.appointmentType,
      votesReceived: votesReceived ?? this.votesReceived,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'term_id': termId,
      'employee_id': employeeId,
      'full_name': fullName,
      'employee_code': employeeCode,
      'department': department,
      'company_position': companyPosition,
      'cpo_role': cpoRole.toDbCode(),
      'appointment_type': appointmentType,
      'votes_received': votesReceived,
      'phone': phone,
      'email': email,
      'status': status,
      'created_at': createdAt,
    };
  }

  factory CpoMemberModel.fromMap(Map<String, dynamic> map) {
    return CpoMemberModel(
      id: map['id'] as int?,
      termId: (map['term_id'] as num?)?.toInt() ?? 0,
      employeeId: (map['employee_id'] as num?)?.toInt(),
      fullName: map['full_name']?.toString() ?? '',
      employeeCode: map['employee_code']?.toString(),
      department: map['department']?.toString(),
      companyPosition: map['company_position']?.toString(),
      cpoRole: CpoMemberRole.fromDbCode(map['cpo_role']?.toString()),
      appointmentType: map['appointment_type']?.toString() ?? 'APPOINTED',
      votesReceived: (map['votes_received'] as num?)?.toInt() ?? 0,
      phone: map['phone']?.toString(),
      email: map['email']?.toString(),
      status: map['status']?.toString() ?? 'ACTIVE',
      createdAt: map['created_at']?.toString(),
    );
  }
}
