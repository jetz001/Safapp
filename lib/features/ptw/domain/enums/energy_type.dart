import 'package:flutter/material.dart';

/// Energy Isolation Types for Lockout/Tagout (LOTO) under Thai Electrical Safety Regulation B.E. 2558
enum EnergyType {
  electrical, // ไฟฟ้า (High/Low Voltage, Breaker, Switchgear)
  pneumatic, // ลม/ก๊าซอัดความดัน (Pneumatic / Compressed Gas)
  hydraulic, // น้ำมันไฮดรอลิก (Hydraulic Fluid)
  chemical, // สารเคมี/ของเหลวในท่อ (Chemical / Hazardous Fluid)
  mechanical, // พลังงานกล/สปริง/ความโน้มถ่วง (Mechanical / Gravity / Kinetic)
  thermal, // ความร้อน/ไอน้ำ/ความเย็น (Thermal / Steam / Cryogenic)
  other; // แหล่งพลังงานอื่นๆ (Other)

  String toDbCode() {
    switch (this) {
      case EnergyType.electrical:
        return 'ELECTRICAL';
      case EnergyType.pneumatic:
        return 'PNEUMATIC';
      case EnergyType.hydraulic:
        return 'HYDRAULIC';
      case EnergyType.chemical:
        return 'CHEMICAL';
      case EnergyType.mechanical:
        return 'MECHANICAL';
      case EnergyType.thermal:
        return 'THERMAL';
      case EnergyType.other:
        return 'OTHER';
    }
  }

  static EnergyType fromDbCode(String? code) {
    switch (code?.trim().toUpperCase()) {
      case 'ELECTRICAL':
        return EnergyType.electrical;
      case 'PNEUMATIC':
        return EnergyType.pneumatic;
      case 'HYDRAULIC':
        return EnergyType.hydraulic;
      case 'CHEMICAL':
      case 'CHEMICAL_FLUID':
        return EnergyType.chemical;
      case 'MECHANICAL':
        return EnergyType.mechanical;
      case 'THERMAL':
        return EnergyType.thermal;
      case 'OTHER':
        return EnergyType.other;
      default:
        return EnergyType.electrical;
    }
  }

  String get labelTh {
    switch (this) {
      case EnergyType.electrical:
        return 'ไฟฟ้า (Electrical)';
      case EnergyType.pneumatic:
        return 'ลม/ก๊าซอัดความดัน (Pneumatic)';
      case EnergyType.hydraulic:
        return 'ไฮดรอลิก (Hydraulic)';
      case EnergyType.chemical:
        return 'สารเคมี/ท่อส่งของเหลว (Chemical/Fluid)';
      case EnergyType.mechanical:
        return 'กลไก/สปริง/แรงโน้มถ่วง (Mechanical)';
      case EnergyType.thermal:
        return 'ความร้อน/ไอน้ำ (Thermal/Steam)';
      case EnergyType.other:
        return 'พลังงานอื่นๆ (Other)';
    }
  }

  String get labelEn {
    switch (this) {
      case EnergyType.electrical:
        return 'Electrical';
      case EnergyType.pneumatic:
        return 'Pneumatic';
      case EnergyType.hydraulic:
        return 'Hydraulic';
      case EnergyType.chemical:
        return 'Chemical / Fluid';
      case EnergyType.mechanical:
        return 'Mechanical';
      case EnergyType.thermal:
        return 'Thermal / Steam';
      case EnergyType.other:
        return 'Other';
    }
  }

  IconData get icon {
    switch (this) {
      case EnergyType.electrical:
        return Icons.bolt;
      case EnergyType.pneumatic:
        return Icons.air;
      case EnergyType.hydraulic:
        return Icons.water_drop;
      case EnergyType.chemical:
        return Icons.science;
      case EnergyType.mechanical:
        return Icons.settings;
      case EnergyType.thermal:
        return Icons.whatshot;
      case EnergyType.other:
        return Icons.power;
    }
  }
}
