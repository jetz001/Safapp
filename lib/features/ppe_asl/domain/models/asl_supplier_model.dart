enum AslStatus {
  approved('APPROVED', 'ผ่านการรับรอง (Approved)', 0xFF16A34A),
  conditional('CONDITIONAL', 'รับรองแบบมีเงื่อนไข', 0xFFD97706),
  underReview('UNDER_REVIEW', 'อยู่ระหว่างประเมิน', 0xFF2563EB),
  rejected('REJECTED', 'ไม่ผ่านการรับรอง', 0xFFDC2626);

  final String code;
  final String labelTh;
  final int colorValue;

  const AslStatus(this.code, this.labelTh, this.colorValue);

  static AslStatus fromCode(String? code) {
    return AslStatus.values.firstWhere(
      (e) => e.code.toUpperCase() == code?.trim().toUpperCase(),
      orElse: () => AslStatus.approved,
    );
  }
}

class AslSupplier {
  final int? id;
  final String code;
  final String companyName;
  final String? taxId;
  final String? contactPerson;
  final String? phone;
  final String? email;
  final String? address;
  final String suppliedCategories; // e.g. "ศีรษะ, สายตา, มือ"
  final String? standardCertificates; // e.g. "ISO 9001:2015, มอก., CE"
  final double rating; // 1.0 - 5.0
  final AslStatus evaluationStatus;
  final String? approvedDate;
  final String? validUntil;
  final String? notes;
  final String status; // ACTIVE, INACTIVE
  final String? createdAt;
  final String? updatedAt;

  const AslSupplier({
    this.id,
    required this.code,
    required this.companyName,
    this.taxId,
    this.contactPerson,
    this.phone,
    this.email,
    this.address,
    required this.suppliedCategories,
    this.standardCertificates,
    this.rating = 5.0,
    this.evaluationStatus = AslStatus.approved,
    this.approvedDate,
    this.validUntil,
    this.notes,
    this.status = 'ACTIVE',
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code,
      'company_name': companyName,
      'tax_id': taxId,
      'contact_person': contactPerson,
      'phone': phone,
      'email': email,
      'address': address,
      'supplied_categories': suppliedCategories,
      'standard_certificates': standardCertificates,
      'rating': rating,
      'evaluation_status': evaluationStatus.code,
      'approved_date': approvedDate,
      'valid_until': validUntil,
      'notes': notes,
      'status': status,
      'created_at': createdAt ?? DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  factory AslSupplier.fromMap(Map<String, dynamic> map) {
    return AslSupplier(
      id: map['id'] as int?,
      code: map['code']?.toString() ?? '',
      companyName: map['company_name']?.toString() ?? '',
      taxId: map['tax_id']?.toString(),
      contactPerson: map['contact_person']?.toString(),
      phone: map['phone']?.toString(),
      email: map['email']?.toString(),
      address: map['address']?.toString(),
      suppliedCategories: map['supplied_categories']?.toString() ?? '',
      standardCertificates: map['standard_certificates']?.toString(),
      rating: (map['rating'] as num?)?.toDouble() ?? 5.0,
      evaluationStatus: AslStatus.fromCode(map['evaluation_status']?.toString()),
      approvedDate: map['approved_date']?.toString(),
      validUntil: map['valid_until']?.toString(),
      notes: map['notes']?.toString(),
      status: map['status']?.toString() ?? 'ACTIVE',
      createdAt: map['created_at']?.toString(),
      updatedAt: map['updated_at']?.toString(),
    );
  }

  AslSupplier copyWith({
    int? id,
    String? code,
    String? companyName,
    String? taxId,
    String? contactPerson,
    String? phone,
    String? email,
    String? address,
    String? suppliedCategories,
    String? standardCertificates,
    double? rating,
    AslStatus? evaluationStatus,
    String? approvedDate,
    String? validUntil,
    String? notes,
    String? status,
    String? createdAt,
    String? updatedAt,
  }) {
    return AslSupplier(
      id: id ?? this.id,
      code: code ?? this.code,
      companyName: companyName ?? this.companyName,
      taxId: taxId ?? this.taxId,
      contactPerson: contactPerson ?? this.contactPerson,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      suppliedCategories: suppliedCategories ?? this.suppliedCategories,
      standardCertificates: standardCertificates ?? this.standardCertificates,
      rating: rating ?? this.rating,
      evaluationStatus: evaluationStatus ?? this.evaluationStatus,
      approvedDate: approvedDate ?? this.approvedDate,
      validUntil: validUntil ?? this.validUntil,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
