import 'package:flutter/material.dart';

enum CpoElectionStatus {
  draft,
  nominating,
  voting,
  tallying,
  completed,
  cancelled;

  String toDbCode() {
    switch (this) {
      case CpoElectionStatus.draft:
        return 'DRAFT';
      case CpoElectionStatus.nominating:
        return 'NOMINATING';
      case CpoElectionStatus.voting:
        return 'VOTING';
      case CpoElectionStatus.tallying:
        return 'TALLYING';
      case CpoElectionStatus.completed:
        return 'COMPLETED';
      case CpoElectionStatus.cancelled:
        return 'CANCELLED';
    }
  }

  static CpoElectionStatus fromDbCode(String? code) {
    switch (code) {
      case 'DRAFT':
        return CpoElectionStatus.draft;
      case 'NOMINATING':
        return CpoElectionStatus.nominating;
      case 'VOTING':
        return CpoElectionStatus.voting;
      case 'TALLYING':
        return CpoElectionStatus.tallying;
      case 'COMPLETED':
        return CpoElectionStatus.completed;
      case 'CANCELLED':
      default:
        return CpoElectionStatus.cancelled;
    }
  }

  String get labelTh {
    switch (this) {
      case CpoElectionStatus.draft:
        return 'เตรียมการจัดตั้ง กกต.';
      case CpoElectionStatus.nominating:
        return 'เปิดรับสมัครผู้แทนลูกจ้าง';
      case CpoElectionStatus.voting:
        return 'เปิดคูหาลงคะแนนเสียง';
      case CpoElectionStatus.tallying:
        return 'นับคะแนน & ตรวจสอบผล';
      case CpoElectionStatus.completed:
        return 'ประกาศผลสำเร็จ';
      case CpoElectionStatus.cancelled:
        return 'ยกเลิกการเลือกตั้ง';
    }
  }

  String get thaiLabel => labelTh;

  Color get color {
    switch (this) {
      case CpoElectionStatus.draft:
        return Colors.blueGrey;
      case CpoElectionStatus.nominating:
        return const Color(0xFF0284C7);
      case CpoElectionStatus.voting:
        return const Color(0xFFD97706);
      case CpoElectionStatus.tallying:
        return const Color(0xFF7C3AED);
      case CpoElectionStatus.completed:
        return const Color(0xFF16A34A);
      case CpoElectionStatus.cancelled:
        return Colors.red;
    }
  }
}
