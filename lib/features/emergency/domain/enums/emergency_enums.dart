import 'package:flutter/material.dart';

enum PlanStatus {
  draft('DRAFT', 'ฉบับร่าง (Draft)', Colors.grey),
  active('ACTIVE', 'มีผลบังคับใช้ (Active)', Color(0xFF059669)),
  reviewNeeded('REVIEW_NEEDED', 'ถึงรอบทบทวน (Review Needed)', Color(0xFFD97706)),
  archived('ARCHIVED', 'ยกเลิก/จัดเก็บ (Archived)', Color(0xFF64748B));

  final String code;
  final String label;
  final Color color;

  const PlanStatus(this.code, this.label, this.color);

  static PlanStatus fromCode(String? code) {
    if (code == null) return PlanStatus.draft;
    return PlanStatus.values.firstWhere(
      (e) => e.code == code.toUpperCase(),
      orElse: () => PlanStatus.draft,
    );
  }
}

enum BusinessType {
  factory('FACTORY', 'โรงงานอุตสาหกรรม (Manufacturing Plant)', Icons.factory),
  warehouse('WAREHOUSE', 'คลังสินค้าและโลจิสติกส์ (Warehouse & Logistics)', Icons.warehouse),
  office('OFFICE', 'อาคารสำนักงานและพาณิชยกรรม (Commercial Office)', Icons.business),
  chemicalStorage('CHEMICAL_STORAGE', 'สถานที่เก็บรักษา/ใช้งานสารเคมี (Chemical Facility)', Icons.science),
  other('OTHER', 'สถานประกอบกิจการทั่วไป (Other Facilities)', Icons.domain);

  final String code;
  final String label;
  final IconData icon;

  const BusinessType(this.code, this.label, this.icon);

  static BusinessType fromCode(String? code) {
    if (code == null) return BusinessType.factory;
    return BusinessType.values.firstWhere(
      (e) => e.code == code.toUpperCase(),
      orElse: () => BusinessType.factory,
    );
  }
}

enum DrillOrganizerType {
  selfApproved('SELF_APPROVED', 'นายจ้างจัดฝึกซ้อมเอง (ได้รับความเห็นชอบล่วงหน้า ๓๐ วัน)'),
  certifiedTrainingBody('CERTIFIED_BODY', 'หน่วยงานฝึกอบรมที่ขึ้นทะเบียนตามกฎหมาย (มาตรา ๑๑)');

  final String code;
  final String label;

  const DrillOrganizerType(this.code, this.label);

  static DrillOrganizerType fromCode(String? code) {
    if (code == null) return DrillOrganizerType.selfApproved;
    return DrillOrganizerType.values.firstWhere(
      (e) => e.code == code.toUpperCase(),
      orElse: () => DrillOrganizerType.selfApproved,
    );
  }
}

enum HeadcountStatus {
  allAccounted('ALL_ACCOUNTED', 'ยอดพนักงานครบถ้วน 100% (ปลอดภัยทั้งหมด)', Color(0xFF059669)),
  missingFound('MISSING_FOUND', 'พบผู้สูญหาย/ช่วยเหลือสำเร็จ (Accounted after Search)', Color(0xFF2563EB)),
  injuriesSimulated('INJURIES_SIMULATED', 'มีสถานการณ์ผู้บาดเจ็บจำลอง (Casualties Handled)', Color(0xFFD97706));

  final String code;
  final String label;
  final Color color;

  const HeadcountStatus(this.code, this.label, this.color);

  static HeadcountStatus fromCode(String? code) {
    if (code == null) return HeadcountStatus.allAccounted;
    return HeadcountStatus.values.firstWhere(
      (e) => e.code == code.toUpperCase(),
      orElse: () => HeadcountStatus.allAccounted,
    );
  }
}

enum Spr4SubmissionStatus {
  pending('PENDING', 'รอจัดส่งรายงาน สปร. ๔ (ภายใน ๓๐ วัน)', Color(0xFFD97706)),
  submitted('SUBMITTED', 'ยื่นรายงาน สปร. ๔ เรียบร้อยแล้ว', Color(0xFF059669)),
  overdue('OVERDUE', 'เกินกำหนด ๓๐ วัน (Overdue)', Color(0xFFDC2626));

  final String code;
  final String label;
  final Color color;

  const Spr4SubmissionStatus(this.code, this.label, this.color);

  static Spr4SubmissionStatus fromCode(String? code) {
    if (code == null) return Spr4SubmissionStatus.pending;
    return Spr4SubmissionStatus.values.firstWhere(
      (e) => e.code == code.toUpperCase(),
      orElse: () => Spr4SubmissionStatus.pending,
    );
  }
}

enum DrillAttachmentCategory {
  before('BEFORE', 'ก่อนเริ่มการฝึกซ้อม (การเตรียมความพร้อม/บรรยายสรุป)'),
  during('DURING', 'ระหว่างการฝึกซ้อม (ดับเพลิงขั้นต้น/อพยพ/ค้นหา)'),
  assembly('ASSEMBLY', 'จุดรวมพล (การตรวจนับยอดพนักงาน/ปฐมพยาบาล)'),
  after('AFTER', 'หลังเสร็จสิ้นการฝึกซ้อม (การสรุปผล Debriefing)');

  final String code;
  final String label;

  const DrillAttachmentCategory(this.code, this.label);

  static DrillAttachmentCategory fromCode(String? code) {
    if (code == null) return DrillAttachmentCategory.during;
    return DrillAttachmentCategory.values.firstWhere(
      (e) => e.code == code.toUpperCase(),
      orElse: () => DrillAttachmentCategory.during,
    );
  }
}
