import 'package:flutter/material.dart';

/// บทบาทหน้าที่ในคณะกรรมการ คปอ. ตามกฎกระทรวง จป./คปอ. พ.ศ. ๒๕๖๕
enum CpoMemberRole {
  /// ประธาน คปอ. (นายจ้างหรือผู้แทนนายจ้างระดับบริหาร)
  chair,

  /// กรรมการผู้แทนนายจ้างระดับบังคับบัญชา
  employerRep,

  /// กรรมการผู้แทนลูกจ้าง (มาจากการเลือกตั้งของลูกจ้าง)
  employeeRep,

  /// กรรมการและเลขานุการ คปอ. (จป.วิชาชีพ หรือ จป.เทคนิคขั้นสูง)
  secretary;

  String toDbCode() {
    switch (this) {
      case CpoMemberRole.chair:
        return 'CHAIR';
      case CpoMemberRole.employerRep:
        return 'EMPLOYER_REP';
      case CpoMemberRole.employeeRep:
        return 'EMPLOYEE_REP';
      case CpoMemberRole.secretary:
        return 'SECRETARY';
    }
  }

  static CpoMemberRole fromDbCode(String? code) {
    switch (code) {
      case 'CHAIR':
        return CpoMemberRole.chair;
      case 'EMPLOYER_REP':
        return CpoMemberRole.employerRep;
      case 'EMPLOYEE_REP':
        return CpoMemberRole.employeeRep;
      case 'SECRETARY':
      default:
        return CpoMemberRole.secretary;
    }
  }

  String get labelTh {
    switch (this) {
      case CpoMemberRole.chair:
        return 'ประธาน คปอ.';
      case CpoMemberRole.employerRep:
        return 'ผู้แทนนายจ้างระดับบังคับบัญชา';
      case CpoMemberRole.employeeRep:
        return 'ผู้แทนลูกจ้าง (จากการเลือกตั้ง)';
      case CpoMemberRole.secretary:
        return 'เลขานุการ คปอ. (จป.วิชาชีพ)';
    }
  }

  String get thaiLabel => labelTh;

  String get fullTitleTh {
    switch (this) {
      case CpoMemberRole.chair:
        return 'ประธานกรรมการ (นายจ้างหรือผู้แทนนายจ้างระดับบริหาร)';
      case CpoMemberRole.employerRep:
        return 'กรรมการ (ผู้แทนนายจ้างระดับบังคับบัญชา)';
      case CpoMemberRole.employeeRep:
        return 'กรรมการ (ผู้แทนลูกจ้างซึ่งมาจากการเลือกตั้ง)';
      case CpoMemberRole.secretary:
        return 'กรรมการและเลขานุการ (จป.วิชาชีพ)';
    }
  }

  Color get badgeColor {
    switch (this) {
      case CpoMemberRole.chair:
        return const Color(0xFF1E3A8A); // Blue 900
      case CpoMemberRole.employerRep:
        return const Color(0xFF0284C7); // Sky 600
      case CpoMemberRole.employeeRep:
        return const Color(0xFF16A34A); // Green 600
      case CpoMemberRole.secretary:
        return const Color(0xFF7C3AED); // Purple 600
    }
  }

  IconData get icon {
    switch (this) {
      case CpoMemberRole.chair:
        return Icons.gavel;
      case CpoMemberRole.employerRep:
        return Icons.business_center;
      case CpoMemberRole.employeeRep:
        return Icons.groups;
      case CpoMemberRole.secretary:
        return Icons.assignment_ind;
    }
  }
}
