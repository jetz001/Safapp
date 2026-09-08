import 'dart:convert';

/// Audit Log Model for PTW Approvals, Status Transitions, and Digital Sign-offs
class PtwApprovalModel {
  final int? id;
  final String approvalId; // e.g. "APR-PTW-2026-001-01"
  final String ptwNumber; // Reference to PtwModel.ptwNumber
  final String approvalStage; // 'SUBMIT_DRAFT', 'SAFETY_REVIEW', 'AUTHORIZER_APPROVAL', 'EXTENSION', 'CLOSURE', 'REJECTION', 'CANCELLATION'
  final String approverRole; // 'APPLICANT', 'SAFETY_OFFICER', 'AUTHORIZER', 'SUPERVISOR', 'CLOSER'
  final String approverName;
  final String? approverPosition;
  final String action; // 'SUBMIT', 'APPROVE', 'REJECT', 'EXTEND', 'CLOSE', 'CANCEL'
  final String timestamp; // ISO 8601 or YYYY-MM-DDTHH:mm:ss
  final String? comments;
  final String? signaturePath;
  final String? createdAt;

  const PtwApprovalModel({
    this.id,
    required this.approvalId,
    required this.ptwNumber,
    required this.approvalStage,
    required this.approverRole,
    required this.approverName,
    this.approverPosition,
    required this.action,
    required this.timestamp,
    this.comments,
    this.signaturePath,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'approval_id': approvalId,
      'ptw_number': ptwNumber,
      'approval_stage': approvalStage,
      'approver_role': approverRole,
      'approver_name': approverName,
      'approver_position': approverPosition,
      'action': action,
      'timestamp': timestamp,
      'comments': comments,
      'signature_path': signaturePath,
      'created_at': createdAt,
    };
  }

  factory PtwApprovalModel.fromMap(Map<String, dynamic> map) {
    return PtwApprovalModel(
      id: map['id'] as int?,
      approvalId: map['approval_id']?.toString() ?? '',
      ptwNumber: map['ptw_number']?.toString() ?? '',
      approvalStage: map['approval_stage']?.toString() ?? '',
      approverRole: map['approver_role']?.toString() ?? '',
      approverName: map['approver_name']?.toString() ?? '',
      approverPosition: map['approver_position']?.toString(),
      action: map['action']?.toString() ?? 'APPROVE',
      timestamp: map['timestamp']?.toString() ?? '',
      comments: map['comments']?.toString(),
      signaturePath: map['signature_path']?.toString(),
      createdAt: map['created_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => toMap();
  factory PtwApprovalModel.fromJson(Map<String, dynamic> json) => PtwApprovalModel.fromMap(json);

  PtwApprovalModel copyWith({
    int? id,
    String? approvalId,
    String? ptwNumber,
    String? approvalStage,
    String? approverRole,
    String? approverName,
    String? approverPosition,
    String? action,
    String? timestamp,
    String? comments,
    String? signaturePath,
    String? createdAt,
  }) {
    return PtwApprovalModel(
      id: id ?? this.id,
      approvalId: approvalId ?? this.approvalId,
      ptwNumber: ptwNumber ?? this.ptwNumber,
      approvalStage: approvalStage ?? this.approvalStage,
      approverRole: approverRole ?? this.approverRole,
      approverName: approverName ?? this.approverName,
      approverPosition: approverPosition ?? this.approverPosition,
      action: action ?? this.action,
      timestamp: timestamp ?? this.timestamp,
      comments: comments ?? this.comments,
      signaturePath: signaturePath ?? this.signaturePath,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() => 'PtwApprovalModel(approvalId: $approvalId, ptwNumber: $ptwNumber, action: $action, by: $approverName, time: $timestamp)';
}
