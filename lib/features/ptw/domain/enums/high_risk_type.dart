import 'package:flutter/material.dart';

/// 5 Core High-Risk Work Types under Thai OSH Ministerial Regulations
enum HighRiskType {
  hotWork, // งานประกายไฟ/ความร้อน (เชื่อม, ตัด, เจียร, พ่นทราย) - กฎกระทรวงอัคคีภัย ๒๕๕๕
  confinedSpace, // งานในที่อับอากาศ (ถัง, ไซโล, บ่อพัก, ท่อ, ห้องใต้ดิน) - กฎกระทรวงอับอากาศ ๒๕๖๒
  workingAtHeight, // งานบนที่สูง (เกิน 2 เมตร, นั่งร้าน, หลังคา, กระเช้า) - กฎกระทรวงงานบนที่สูง ๒๕๖๔
  electricalLoto, // งานไฟฟ้าและการตัดแยกพลังงาน (แรงดันสูง/ต่ำ, LOTO) - กฎกระทรวงไฟฟ้า ๒๕๕๘
  excavationLifting; // งานขุดเจาะและยกเคลื่อนย้าย (ขุดลึก > 1.5 ม., ปั้นจั่น, เครน) - กฎกระทรวงงานดินขุด ๒๕๖๔

  String toDbCode() {
    switch (this) {
      case HighRiskType.hotWork:
        return 'HOT_WORK';
      case HighRiskType.confinedSpace:
        return 'CONFINED_SPACE';
      case HighRiskType.workingAtHeight:
        return 'WORKING_AT_HEIGHT';
      case HighRiskType.electricalLoto:
        return 'ELECTRICAL_LOTO';
      case HighRiskType.excavationLifting:
        return 'EXCAVATION_LIFTING';
    }
  }

  static HighRiskType fromDbCode(String? code) {
    switch (code?.trim().toUpperCase()) {
      case 'HOT_WORK':
        return HighRiskType.hotWork;
      case 'CONFINED_SPACE':
        return HighRiskType.confinedSpace;
      case 'WORKING_AT_HEIGHT':
      case 'WORK_AT_HEIGHT':
      case 'HEIGHT':
        return HighRiskType.workingAtHeight;
      case 'ELECTRICAL_LOTO':
      case 'ELECTRICAL':
      case 'LOTO':
        return HighRiskType.electricalLoto;
      case 'EXCAVATION_LIFTING':
      case 'EXCAVATION':
      case 'LIFTING':
        return HighRiskType.excavationLifting;
      default:
        return HighRiskType.hotWork;
    }
  }

  String get labelTh {
    switch (this) {
      case HighRiskType.hotWork:
        return 'งานประกายไฟ/ความร้อน (Hot Work)';
      case HighRiskType.confinedSpace:
        return 'งานในที่อับอากาศ (Confined Space)';
      case HighRiskType.workingAtHeight:
        return 'งานบนที่สูง (Working at Height)';
      case HighRiskType.electricalLoto:
        return 'งานไฟฟ้าและตัดแยกพลังงาน (Electrical & LOTO)';
      case HighRiskType.excavationLifting:
        return 'งานขุดเจาะและยกย้าย (Excavation & Lifting)';
    }
  }

  String get shortLabelTh {
    switch (this) {
      case HighRiskType.hotWork:
        return 'Hot Work';
      case HighRiskType.confinedSpace:
        return 'ที่อับอากาศ';
      case HighRiskType.workingAtHeight:
        return 'งานบนที่สูง';
      case HighRiskType.electricalLoto:
        return 'ไฟฟ้า & LOTO';
      case HighRiskType.excavationLifting:
        return 'ขุดเจาะ/ยกย้าย';
    }
  }

  String get labelEn {
    switch (this) {
      case HighRiskType.hotWork:
        return 'Hot Work';
      case HighRiskType.confinedSpace:
        return 'Confined Space';
      case HighRiskType.workingAtHeight:
        return 'Working at Height';
      case HighRiskType.electricalLoto:
        return 'Electrical & LOTO';
      case HighRiskType.excavationLifting:
        return 'Excavation & Lifting';
    }
  }

  String get legalRefTh {
    switch (this) {
      case HighRiskType.hotWork:
        return 'กฎกระทรวงการป้องกันและระงับอัคคีภัย พ.ศ. ๒๕๕๕';
      case HighRiskType.confinedSpace:
        return 'กฎกระทรวงความปลอดภัยในสถานที่อับอากาศ พ.ศ. ๒๕๖๒';
      case HighRiskType.workingAtHeight:
        return 'กฎกระทรวงความปลอดภัยเกี่ยวกับนั่งร้านและงานบนที่สูง พ.ศ. ๒๕๖๔';
      case HighRiskType.electricalLoto:
        return 'กฎกระทรวงความปลอดภัยเกี่ยวกับระบบไฟฟ้า พ.ศ. ๒๕๕๘';
      case HighRiskType.excavationLifting:
        return 'กฎกระทรวงความปลอดภัยเกี่ยวกับงานดินขุดและเครื่องจักรปั้นจั่น พ.ศ. ๒๕๖๔';
    }
  }

  IconData get icon {
    switch (this) {
      case HighRiskType.hotWork:
        return Icons.local_fire_department;
      case HighRiskType.confinedSpace:
        return Icons.sensor_door;
      case HighRiskType.workingAtHeight:
        return Icons.height;
      case HighRiskType.electricalLoto:
        return Icons.bolt;
      case HighRiskType.excavationLifting:
        return Icons.construction;
    }
  }

  Color get color {
    switch (this) {
      case HighRiskType.hotWork:
        return const Color(0xFFEF4444); // Red
      case HighRiskType.confinedSpace:
        return const Color(0xFF8B5CF6); // Purple
      case HighRiskType.workingAtHeight:
        return const Color(0xFF3B82F6); // Blue
      case HighRiskType.electricalLoto:
        return const Color(0xFFF59E0B); // Amber
      case HighRiskType.excavationLifting:
        return const Color(0xFF10B981); // Emerald
    }
  }

  Color get backgroundColor {
    switch (this) {
      case HighRiskType.hotWork:
        return const Color(0xFFFEF2F2);
      case HighRiskType.confinedSpace:
        return const Color(0xFFF5F3FF);
      case HighRiskType.workingAtHeight:
        return const Color(0xFFEFF6FF);
      case HighRiskType.electricalLoto:
        return const Color(0xFFFFFBEB);
      case HighRiskType.excavationLifting:
        return const Color(0xFFECFDF5);
    }
  }
}
