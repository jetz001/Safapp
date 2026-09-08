class CpoDistributionModel {
  final int? id;
  final int meetingId;
  final String distributionDate;
  final String distributionMethod; // NOTICE_BOARD, EMAIL, PRINT_COPY, SAFETY_TALK, INTRANET
  final String recipientGroup;
  final String senderName;
  final String? proofDocumentPath;
  final String? notes;
  final String? createdAt;

  const CpoDistributionModel({
    this.id,
    required this.meetingId,
    required this.distributionDate,
    required this.distributionMethod,
    required this.recipientGroup,
    required this.senderName,
    this.proofDocumentPath,
    this.notes,
    this.createdAt,
  });

  String get methodLabel {
    switch (distributionMethod) {
      case 'NOTICE_BOARD':
        return 'ปิดประกาศ ณ บอร์ดประชาสัมพันธ์';
      case 'EMAIL':
        return 'ส่งจดหมายอิเล็กทรอนิกส์ (Email แจ้งเวียน)';
      case 'PRINT_COPY':
        return 'ส่งมอบเอกสารฉบับพิมพ์รายแผนก';
      case 'SAFETY_TALK':
        return 'สื่อสารในการประชุม Safety Talk/Morning Talk';
      case 'INTRANET':
      default:
        return 'อัปโหลดระบบเครือข่ายภายใน (Intranet / Share Drive)';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'meeting_id': meetingId,
      'distribution_date': distributionDate,
      'distribution_method': distributionMethod,
      'recipient_group': recipientGroup,
      'sender_name': senderName,
      'proof_document_path': proofDocumentPath,
      'notes': notes,
      'created_at': createdAt,
    };
  }

  factory CpoDistributionModel.fromMap(Map<String, dynamic> map) {
    return CpoDistributionModel(
      id: map['id'] as int?,
      meetingId: (map['meeting_id'] as num?)?.toInt() ?? 0,
      distributionDate: map['distribution_date']?.toString() ?? '',
      distributionMethod: map['distribution_method']?.toString() ?? 'NOTICE_BOARD',
      recipientGroup: map['recipient_group']?.toString() ?? '',
      senderName: map['sender_name']?.toString() ?? '',
      proofDocumentPath: map['proof_document_path']?.toString(),
      notes: map['notes']?.toString(),
      createdAt: map['created_at']?.toString(),
    );
  }
}
