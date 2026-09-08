enum PpeTransactionType {
  stockIn('IN', 'รับเข้าคลัง', 0xFF16A34A),
  stockOut('OUT', 'เบิกจ่าย', 0xFFDC2626),
  adjust('ADJUST', 'ปรับปรุงสต็อก', 0xFFD97706),
  returned('RETURN', 'ส่งคืนอุปกรณ์', 0xFF2563EB);

  final String code;
  final String labelTh;
  final int colorValue;

  const PpeTransactionType(this.code, this.labelTh, this.colorValue);

  static PpeTransactionType fromCode(String? code) {
    return PpeTransactionType.values.firstWhere(
      (e) => e.code.toUpperCase() == code?.trim().toUpperCase(),
      orElse: () => PpeTransactionType.stockOut,
    );
  }
}

class PpeTransaction {
  final int? id;
  final String transactionNo;
  final int ppeId;
  final String ppeCode;
  final String ppeName;
  final PpeTransactionType transactionType;
  final int quantity;
  final int balanceAfter;
  final String transactionDate;
  final String? recipientType; // EMPLOYEE, CONTRACTOR, DEPARTMENT, GENERAL
  final String? recipientId; // รหัสพนักงาน หรือ ทะเบียน
  final String? recipientName; // ชื่อผู้รับเบิก
  final String? department;
  final String? cpoMeetingRef; // อ้างอิงมติ คปอ.
  final String? ptwRef; // อ้างอิงใบ PTW
  final int? supplierId; // ผู้จำหน่าย (กรณีรับเข้า)
  final String? supplierName;
  final String? notes;
  final String? recordedBy;
  final String? createdAt;

  const PpeTransaction({
    this.id,
    required this.transactionNo,
    required this.ppeId,
    required this.ppeCode,
    required this.ppeName,
    required this.transactionType,
    required this.quantity,
    required this.balanceAfter,
    required this.transactionDate,
    this.recipientType,
    this.recipientId,
    this.recipientName,
    this.department,
    this.cpoMeetingRef,
    this.ptwRef,
    this.supplierId,
    this.supplierName,
    this.notes,
    this.recordedBy,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'transaction_no': transactionNo,
      'ppe_id': ppeId,
      'ppe_code': ppeCode,
      'ppe_name': ppeName,
      'transaction_type': transactionType.code,
      'quantity': quantity,
      'balance_after': balanceAfter,
      'transaction_date': transactionDate,
      'recipient_type': recipientType,
      'recipient_id': recipientId,
      'recipient_name': recipientName,
      'department': department,
      'cpo_meeting_ref': cpoMeetingRef,
      'ptw_ref': ptwRef,
      'supplier_id': supplierId,
      'supplier_name': supplierName,
      'notes': notes,
      'recorded_by': recordedBy,
      'created_at': createdAt ?? DateTime.now().toIso8601String(),
    };
  }

  factory PpeTransaction.fromMap(Map<String, dynamic> map) {
    return PpeTransaction(
      id: map['id'] as int?,
      transactionNo: map['transaction_no']?.toString() ?? '',
      ppeId: (map['ppe_id'] as num?)?.toInt() ?? 0,
      ppeCode: map['ppe_code']?.toString() ?? '',
      ppeName: map['ppe_name']?.toString() ?? '',
      transactionType: PpeTransactionType.fromCode(map['transaction_type']?.toString()),
      quantity: (map['quantity'] as num?)?.toInt() ?? 0,
      balanceAfter: (map['balance_after'] as num?)?.toInt() ?? 0,
      transactionDate: map['transaction_date']?.toString() ?? '',
      recipientType: map['recipient_type']?.toString(),
      recipientId: map['recipient_id']?.toString(),
      recipientName: map['recipient_name']?.toString(),
      department: map['department']?.toString(),
      cpoMeetingRef: map['cpo_meeting_ref']?.toString(),
      ptwRef: map['ptw_ref']?.toString(),
      supplierId: (map['supplier_id'] as num?)?.toInt(),
      supplierName: map['supplier_name']?.toString(),
      notes: map['notes']?.toString(),
      recordedBy: map['recorded_by']?.toString(),
      createdAt: map['created_at']?.toString(),
    );
  }
}
