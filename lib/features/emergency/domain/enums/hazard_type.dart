import 'package:flutter/material.dart';

enum HazardType {
  fire(
    code: 'FIRE',
    titleTh: 'อัคคีภัย (Fire Emergency)',
    shortTitle: 'อัคคีภัย',
    icon: Icons.local_fire_department,
    color: Color(0xFFDC2626), // Deep Red
    legalBasis: 'กฎกระทรวงการป้องกันและระงับอัคคีภัย พ.ศ. ๒๕๕๕ ข้อ ๔ & ข้อ ๓๐',
    standardDoc: 'เล่ม ๑๒๙ ตอนที่ ๑๓๐ ก / แบบ สปร. ๔',
  ),
  chemicalSpill(
    code: 'CHEMICAL_SPILL',
    titleTh: 'สารเคมีรั่วไหล (Chemical Spill / HAZMAT)',
    shortTitle: 'สารเคมีรั่วไหล',
    icon: Icons.science,
    color: Color(0xFF7C3AED), // Purple
    legalBasis: 'กฎกระทรวงสารเคมีอันตราย พ.ศ. ๒๕๕๖ ข้อ ๒๙-๓๐ & NFPA 472',
    standardDoc: 'ERG 2024 / SDS Section 6 Accidental Release Measures',
  ),
  flood(
    code: 'FLOOD',
    titleTh: 'อุทกภัยและน้ำท่วม (Flood Emergency)',
    shortTitle: 'น้ำท่วม',
    icon: Icons.flood,
    color: Color(0xFF0284C7), // Blue
    legalBasis: 'พ.ร.บ. ป้องกันและบรรเทาสาธารณภัย พ.ศ. ๒๕๕๐ & แผน ปภ. ชาติ',
    standardDoc: 'มาตรการตัดระบบไฟฟ้าก๊าซ / ยกของขึ้นที่สูง / แผนอพยพ',
  ),
  earthquake(
    code: 'EARTHQUAKE',
    titleTh: 'แผ่นดินไหวและอาคารถล่ม (Earthquake)',
    shortTitle: 'แผ่นดินไหว',
    icon: Icons.vibration,
    color: Color(0xFFD97706), // Amber
    legalBasis: 'กฎกระทรวงกำหนดการรับน้ำหนัก ต้านทานแรงสั่นสะเทือนฯ พ.ศ. ๒๕๖๔',
    standardDoc: 'Drop, Cover, Hold On / การตรวจสอบโครงสร้างอาคารหลังแผ่นดินไหว',
  ),
  electrical(
    code: 'ELECTRICAL',
    titleTh: 'ภัยจากระบบไฟฟ้า (Electrical Emergency & Safety)',
    shortTitle: 'ไฟฟ้า',
    icon: Icons.bolt,
    color: Color(0xFFEAB308), // Electrical Amber/Yellow
    legalBasis: 'กฎกระทรวงกำหนดมาตรฐานการบริหารจัดการเกี่ยวกับไฟฟ้า พ.ศ. ๒๕๕๘ ข้อ ๑๒',
    standardDoc: 'แบบ ๕๖๒๘๙ / วสท. ๐๒๒๐๑๓-๕๙ / การตัดวงจรไฟฟ้า & ปฐมพยาบาล CPR/AED',
  ),
  custom(
    code: 'CUSTOM',
    titleTh: 'ภัยฉุกเฉินเฉพาะองค์กร (Custom Emergency)',
    shortTitle: 'ภัยเฉพาะองค์กร',
    icon: Icons.warning_amber_rounded,
    color: Color(0xFF4B5563), // Slate Gray
    legalBasis: 'มาตรฐานระบบบริหารความต่อเนื่องทางธุรกิจ ISO 22301 / OSHMS',
    standardDoc: 'การประเมินความเสี่ยงเฉพาะพื้นที่ของสถานประกอบการ',
  );

  final String code;
  final String titleTh;
  final String shortTitle;
  final IconData icon;
  final Color color;
  final String legalBasis;
  final String standardDoc;

  const HazardType({
    required this.code,
    required this.titleTh,
    required this.shortTitle,
    required this.icon,
    required this.color,
    required this.legalBasis,
    required this.standardDoc,
  });

  static HazardType fromCode(String? code) {
    if (code == null) return HazardType.fire;
    return HazardType.values.firstWhere(
      (e) => e.code == code.toUpperCase(),
      orElse: () => HazardType.fire,
    );
  }
}
