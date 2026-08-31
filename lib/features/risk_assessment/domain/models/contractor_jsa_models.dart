import 'dart:convert';

class ContractorJsaDocument {
  final int? id;
  final String contractorName;
  final String projectTitle;
  final String? workLocation;
  final String documentType;
  final String assessmentDate;
  final String? validUntilDate;
  final String? assessorName;
  final String? notes;
  final List<String> filePaths;
  final String status;
  final String? createdAt;
  final String? updatedAt;

  const ContractorJsaDocument({
    this.id,
    required this.contractorName,
    required this.projectTitle,
    this.workLocation,
    this.documentType = 'JSA ผู้รับเหมา',
    required this.assessmentDate,
    this.validUntilDate,
    this.assessorName,
    this.notes,
    required this.filePaths,
    this.status = 'ACTIVE',
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'contractor_name': contractorName,
      'project_title': projectTitle,
      'work_location': workLocation,
      'document_type': documentType,
      'assessment_date': assessmentDate,
      'valid_until_date': validUntilDate,
      'assessor_name': assessorName,
      'notes': notes,
      'file_paths': jsonEncode(filePaths),
      'status': status,
      'created_at': createdAt ?? DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  factory ContractorJsaDocument.fromMap(Map<String, dynamic> map) {
    List<String> parsedFiles = [];
    if (map['file_paths'] != null) {
      try {
        final decoded = jsonDecode(map['file_paths']);
        if (decoded is List) {
          parsedFiles = decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {
        if (map['file_paths'] is String && (map['file_paths'] as String).isNotEmpty) {
          parsedFiles = [(map['file_paths'] as String)];
        }
      }
    }

    return ContractorJsaDocument(
      id: map['id'] as int?,
      contractorName: map['contractor_name'] ?? '',
      projectTitle: map['project_title'] ?? '',
      workLocation: map['work_location'],
      documentType: map['document_type'] ?? 'JSA ผู้รับเหมา',
      assessmentDate: map['assessment_date'] ?? '',
      validUntilDate: map['valid_until_date'],
      assessorName: map['assessor_name'],
      notes: map['notes'],
      filePaths: parsedFiles,
      status: map['status'] ?? 'ACTIVE',
      createdAt: map['created_at'],
      updatedAt: map['updated_at'],
    );
  }

  ContractorJsaDocument copyWith({
    int? id,
    String? contractorName,
    String? projectTitle,
    String? workLocation,
    String? documentType,
    String? assessmentDate,
    String? validUntilDate,
    String? assessorName,
    String? notes,
    List<String>? filePaths,
    String? status,
    String? createdAt,
    String? updatedAt,
  }) {
    return ContractorJsaDocument(
      id: id ?? this.id,
      contractorName: contractorName ?? this.contractorName,
      projectTitle: projectTitle ?? this.projectTitle,
      workLocation: workLocation ?? this.workLocation,
      documentType: documentType ?? this.documentType,
      assessmentDate: assessmentDate ?? this.assessmentDate,
      validUntilDate: validUntilDate ?? this.validUntilDate,
      assessorName: assessorName ?? this.assessorName,
      notes: notes ?? this.notes,
      filePaths: filePaths ?? this.filePaths,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
