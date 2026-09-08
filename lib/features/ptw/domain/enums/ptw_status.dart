import 'package:flutter/material.dart';

/// 5-Stage Approval & Lifecycle Workflow Status for Permit to Work
enum PtwStatus {
  draft, // 1. ร่างคำขอ (ผู้ขอ/หัวหน้างาน/ผู้รับเหมา)
  pendingApproval, // 2. รอตรวจสอบ JSA และอนุมัติ (จป.วิชาชีพ / ผู้อนุญาต)
  active, // 3. เปิดงาน/กำลังปฏิบัติงาน (มีผลบังคับใช้ตามช่วงเวลา)
  extendedHandover, // 4. ต่อเวลา / ส่งมอบงานระหว่างกะ
  closedCancelled; // 5. ปิดงานสมบูรณ์ / ยกเลิก

  String toDbCode() {
    switch (this) {
      case PtwStatus.draft:
        return 'DRAFT';
      case PtwStatus.pendingApproval:
        return 'PENDING_APPROVAL';
      case PtwStatus.active:
        return 'ACTIVE';
      case PtwStatus.extendedHandover:
        return 'EXTENDED_HANDOVER';
      case PtwStatus.closedCancelled:
        return 'CLOSED_CANCELLED';
    }
  }

  static PtwStatus fromDbCode(String? code) {
    switch (code?.trim().toUpperCase()) {
      case 'DRAFT':
        return PtwStatus.draft;
      case 'PENDING_APPROVAL':
      case 'PENDING':
        return PtwStatus.pendingApproval;
      case 'ACTIVE':
      case 'APPROVED':
      case 'OPEN':
        return PtwStatus.active;
      case 'EXTENDED_HANDOVER':
      case 'EXTENDED':
      case 'HANDOVER':
        return PtwStatus.extendedHandover;
      case 'CLOSED_CANCELLED':
      case 'CLOSED':
      case 'CANCELLED':
        return PtwStatus.closedCancelled;
      default:
        return PtwStatus.draft;
    }
  }

  String get labelTh {
    switch (this) {
      case PtwStatus.draft:
        return 'ร่างคำขอ (Draft)';
      case PtwStatus.pendingApproval:
        return 'รออนุมัติ (Pending Approval)';
      case PtwStatus.active:
        return 'กำลังปฏิบัติงาน (Active)';
      case PtwStatus.extendedHandover:
        return 'ต่อเวลา/ส่งมอบกะ (Extended/Handover)';
      case PtwStatus.closedCancelled:
        return 'ปิดงาน/ยกเลิก (Closed/Cancelled)';
    }
  }

  String get shortLabelTh {
    switch (this) {
      case PtwStatus.draft:
        return 'แบบร่าง';
      case PtwStatus.pendingApproval:
        return 'รออนุมัติ';
      case PtwStatus.active:
        return 'เปิดทำงาน';
      case PtwStatus.extendedHandover:
        return 'ต่อเวลา/ส่งกะ';
      case PtwStatus.closedCancelled:
        return 'ปิดงาน';
    }
  }

  String get labelEn {
    switch (this) {
      case PtwStatus.draft:
        return 'Draft';
      case PtwStatus.pendingApproval:
        return 'Pending Approval';
      case PtwStatus.active:
        return 'Active';
      case PtwStatus.extendedHandover:
        return 'Extended / Handover';
      case PtwStatus.closedCancelled:
        return 'Closed / Cancelled';
    }
  }

  Color get badgeColor {
    switch (this) {
      case PtwStatus.draft:
        return const Color(0xFF6B7280); // Gray
      case PtwStatus.pendingApproval:
        return const Color(0xFFD97706); // Amber / Warm Orange
      case PtwStatus.active:
        return const Color(0xFF059669); // Emerald Green
      case PtwStatus.extendedHandover:
        return const Color(0xFF2563EB); // Blue
      case PtwStatus.closedCancelled:
        return const Color(0xFF4B5563); // Dark Gray / Slate
    }
  }

  Color get badgeBackgroundColor {
    switch (this) {
      case PtwStatus.draft:
        return const Color(0xFFF3F4F6);
      case PtwStatus.pendingApproval:
        return const Color(0xFFFEF3C7);
      case PtwStatus.active:
        return const Color(0xFFD1FAE5);
      case PtwStatus.extendedHandover:
        return const Color(0xFFDBEAFE);
      case PtwStatus.closedCancelled:
        return const Color(0xFFF3F4F6);
    }
  }

  IconData get icon {
    switch (this) {
      case PtwStatus.draft:
        return Icons.edit_note;
      case PtwStatus.pendingApproval:
        return Icons.pending_actions;
      case PtwStatus.active:
        return Icons.play_circle_fill;
      case PtwStatus.extendedHandover:
        return Icons.update;
      case PtwStatus.closedCancelled:
        return Icons.check_circle;
    }
  }
}
