import 'package:flutter/material.dart';

/// 4 Confined Space Statutory Duty Roles under Ministerial Regulation B.E. 2562 (ข้อ ๙-๑๒)
enum ConfinedRoleType {
  authorizer, // ผู้อนุญาต (ข้อ ๙)
  supervisor, // ผู้ควบคุมงาน (ข้อ ๑๐)
  attendant, // ผู้ช่วยเหลือ / ผู้เฝ้าระวังหน้าทางเข้าออก (ข้อ ๑๑)
  entrant; // ผู้ปฏิบัติงานในที่อับอากาศ (ข้อ ๑๒)

  String toDbCode() {
    switch (this) {
      case ConfinedRoleType.authorizer:
        return 'AUTHORIZER';
      case ConfinedRoleType.supervisor:
        return 'SUPERVISOR';
      case ConfinedRoleType.attendant:
        return 'ATTENDANT';
      case ConfinedRoleType.entrant:
        return 'ENTRANT';
    }
  }

  static ConfinedRoleType fromDbCode(String? code) {
    switch (code?.trim().toUpperCase()) {
      case 'AUTHORIZER':
        return ConfinedRoleType.authorizer;
      case 'SUPERVISOR':
        return ConfinedRoleType.supervisor;
      case 'ATTENDANT':
      case 'STANDBY':
        return ConfinedRoleType.attendant;
      case 'ENTRANT':
        return ConfinedRoleType.entrant;
      default:
        return ConfinedRoleType.entrant;
    }
  }

  String get labelTh {
    switch (this) {
      case ConfinedRoleType.authorizer:
        return 'ผู้อนุญาต (Authorizer)';
      case ConfinedRoleType.supervisor:
        return 'ผู้ควบคุมงาน (Supervisor)';
      case ConfinedRoleType.attendant:
        return 'ผู้ช่วยเหลือ/เฝ้าระวัง (Attendant)';
      case ConfinedRoleType.entrant:
        return 'ผู้ปฏิบัติงานในที่อับอากาศ (Entrant)';
    }
  }

  String get shortLabelTh {
    switch (this) {
      case ConfinedRoleType.authorizer:
        return 'ผู้อนุญาต';
      case ConfinedRoleType.supervisor:
        return 'ผู้ควบคุมงาน';
      case ConfinedRoleType.attendant:
        return 'ผู้ช่วยเหลือ';
      case ConfinedRoleType.entrant:
        return 'ผู้ปฏิบัติงาน';
    }
  }

  String get legalSectionTh {
    switch (this) {
      case ConfinedRoleType.authorizer:
        return 'กฎกระทรวงที่อับอากาศ ๒๕๖๒ ข้อ ๙';
      case ConfinedRoleType.supervisor:
        return 'กฎกระทรวงที่อับอากาศ ๒๕๖๒ ข้อ ๑๐';
      case ConfinedRoleType.attendant:
        return 'กฎกระทรวงที่อับอากาศ ๒๕๖๒ ข้อ ๑๑';
      case ConfinedRoleType.entrant:
        return 'กฎกระทรวงที่อับอากาศ ๒๕๖๒ ข้อ ๑๒';
    }
  }

  String get labelEn {
    switch (this) {
      case ConfinedRoleType.authorizer:
        return 'Authorizer';
      case ConfinedRoleType.supervisor:
        return 'Supervisor';
      case ConfinedRoleType.attendant:
        return 'Attendant / Standby';
      case ConfinedRoleType.entrant:
        return 'Entrant';
    }
  }

  IconData get icon {
    switch (this) {
      case ConfinedRoleType.authorizer:
        return Icons.verified_user;
      case ConfinedRoleType.supervisor:
        return Icons.manage_accounts;
      case ConfinedRoleType.attendant:
        return Icons.support_agent;
      case ConfinedRoleType.entrant:
        return Icons.person;
    }
  }
}
