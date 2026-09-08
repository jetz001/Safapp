import 'package:flutter/material.dart';

enum CpoActionStatus {
  pending,
  inProgress,
  completed,
  overdue,
  cancelled;

  String toDbCode() {
    switch (this) {
      case CpoActionStatus.pending:
        return 'PENDING';
      case CpoActionStatus.inProgress:
        return 'IN_PROGRESS';
      case CpoActionStatus.completed:
        return 'COMPLETED';
      case CpoActionStatus.overdue:
        return 'OVERDUE';
      case CpoActionStatus.cancelled:
        return 'CANCELLED';
    }
  }

  static CpoActionStatus fromDbCode(String? code) {
    switch (code) {
      case 'PENDING':
        return CpoActionStatus.pending;
      case 'IN_PROGRESS':
        return CpoActionStatus.inProgress;
      case 'COMPLETED':
        return CpoActionStatus.completed;
      case 'OVERDUE':
        return CpoActionStatus.overdue;
      case 'CANCELLED':
      default:
        return CpoActionStatus.cancelled;
    }
  }

  String get labelTh {
    switch (this) {
      case CpoActionStatus.pending:
        return 'รอดำเนินการ';
      case CpoActionStatus.inProgress:
        return 'กำลังดำเนินการ';
      case CpoActionStatus.completed:
        return 'ดำเนินการเสร็จสิ้น';
      case CpoActionStatus.overdue:
        return 'เกินกำหนดเวลา';
      case CpoActionStatus.cancelled:
        return 'ยกเลิกมติ';
    }
  }

  String get thaiLabel => labelTh;

  Color get color {
    switch (this) {
      case CpoActionStatus.pending:
        return const Color(0xFFEAB308); // Yellow
      case CpoActionStatus.inProgress:
        return const Color(0xFF0284C7); // Sky
      case CpoActionStatus.completed:
        return const Color(0xFF16A34A); // Green
      case CpoActionStatus.overdue:
        return const Color(0xFFDC2626); // Red
      case CpoActionStatus.cancelled:
        return Colors.grey;
    }
  }
}
