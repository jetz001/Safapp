/// Centralized App Route Indices for Safapp
/// Categorized into 5 logical OSH (Occupational Safety and Health) workflow groups
class AppRoutes {
  // ── กลุ่มที่ ๑: ภาพรวม & สถิติ (Overview & Control) ───────────────────────
  static const int home = 0;           // หน้าแรก / Portal Hub
  static const int dashboard = 1;      // แดชบอร์ดสถิติผู้บริหาร
  static const int smsSetup = 2;       // ข้อมูลองค์กร & ตั้งค่า SMS

  // ── กลุ่มที่ ๒: การควบคุมความเสี่ยงหน้างาน (Risk & Site Operations) ────────
  static const int jsa = 3;            // JSA & ประเมินความเสี่ยง ปอ.๑/๒
  static const int ptw = 4;            // PTW ใบอนุญาตทำงานเสี่ยงสูง
  static const int audit = 5;          // Audit & Safety Inspection
  static const int nearMiss = 6;       // รายงานอุบัติเหตุ & Near Miss

  // ── กลุ่มที่ ๓: บุคลากร สุขอนามัย & ผู้รับเหมา (People & Health) ───────────
  static const int employee = 7;       // ทะเบียนพนักงาน & ฝึกอบรม
  static const int cpo = 8;            // คณะกรรมการ คปอ.
  static const int contractor = 9;     // จัดการผู้รับเหมา
  static const int health = 10;        // อาชีวอนามัย & ตรวจสุขภาพ
  static const int ppe = 11;           // อุปกรณ์ PPE & มาตรฐาน ASL

  // ── กลุ่มที่ ๔: เทคนิควิศวกรรม & สิ่งแวดล้อม (Engineering & Environment) ──
  static const int machinery = 12;     // เครื่องจักร ปั้นจั่น ปจ.๑ & หม้อน้ำ
  static const int electrical = 13;    // ระบบไฟฟ้า ๕๖๒๘๙ & LOTO
  static const int chemicals = 14;     // บัญชีสารเคมีอันตราย & SDS
  static const int environment = 15;   // สิ่งแวดล้อม แสง เสียง ความร้อน
  static const int emergency = 16;     // แผนฉุกเฉิน & ซ้อมหนีไฟ

  // ── กลุ่มที่ ๕: การกำกับดูแล นโยบาย & ตั้งค่า (Governance & System) ────────
  static const int legal = 17;         // ทะเบียนกฎหมายความปลอดภัย
  static const int manuals = 18;       // คู่มือความปลอดภัย & SOPs
  static const int settings = 19;      // ตั้งค่าระบบ
}
