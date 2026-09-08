import 'package:flutter/material.dart';

enum CpoMeetingStatus {
  draft,
  scheduled,
  inProgress,
  completed,
  cancelled;

  String toDbCode() {
    switch (this) {
      case CpoMeetingStatus.draft:
        return 'DRAFT';
      case CpoMeetingStatus.scheduled:
        return 'SCHEDULED';
      case CpoMeetingStatus.inProgress:
        return 'IN_PROGRESS';
      case CpoMeetingStatus.completed:
        return 'COMPLETED';
      case CpoMeetingStatus.cancelled:
        return 'CANCELLED';
    }
  }

  static CpoMeetingStatus fromDbCode(String? code) {
    switch (code) {
      case 'DRAFT':
        return CpoMeetingStatus.draft;
      case 'SCHEDULED':
        return CpoMeetingStatus.scheduled;
      case 'IN_PROGRESS':
        return CpoMeetingStatus.inProgress;
      case 'COMPLETED':
        return CpoMeetingStatus.completed;
      case 'CANCELLED':
      default:
        return CpoMeetingStatus.cancelled;
    }
  }

  String get labelTh {
    switch (this) {
      case CpoMeetingStatus.draft:
        return 'ร่างวาระการประชุม';
      case CpoMeetingStatus.scheduled:
        return 'ส่งหนังสือเชิญประชุมแล้ว';
      case CpoMeetingStatus.inProgress:
        return 'กำลังดำเนินการประชุม';
      case CpoMeetingStatus.completed:
        return 'ประชุมเสร็จสิ้น & รับรองมติ';
      case CpoMeetingStatus.cancelled:
        return 'ยกเลิกการประชุม';
    }
  }

  String get thaiLabel => labelTh;

  Color get color {
    switch (this) {
      case CpoMeetingStatus.draft:
        return Colors.grey;
      case CpoMeetingStatus.scheduled:
        return const Color(0xFF0284C7);
      case CpoMeetingStatus.inProgress:
        return const Color(0xFFD97706);
      case CpoMeetingStatus.completed:
        return const Color(0xFF16A34A);
      case CpoMeetingStatus.cancelled:
        return Colors.red;
    }
  }
}
