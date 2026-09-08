import '../../domain/enums/high_risk_type.dart';
import '../models/ptw_checklist_model.dart';

/// Authoritative Master Checklist & Statutory Standards Data for High-Risk PTW
class PtwStatutoryMasterData {
  /// Standard checklist items partitioned by high-risk work type
  static List<PtwChecklistModel> getStandardChecklistForRiskType(HighRiskType riskType, {String? ptwNumber}) {
    switch (riskType) {
      case HighRiskType.hotWork:
        return _hotWorkChecklist(ptwNumber);
      case HighRiskType.confinedSpace:
        return _confinedSpaceChecklist(ptwNumber);
      case HighRiskType.workingAtHeight:
        return _workingAtHeightChecklist(ptwNumber);
      case HighRiskType.electricalLoto:
        return _electricalLotoChecklist(ptwNumber);
      case HighRiskType.excavationLifting:
        return _excavationLiftingChecklist(ptwNumber);
    }
  }

  // 1. Hot Work Statutory Checklist (กฎกระทรวงอัคคีภัย ๒๕๕๕)
  static List<PtwChecklistModel> _hotWorkChecklist(String? ptwNumber) => [
        PtwChecklistModel(
          ptwNumber: ptwNumber,
          itemId: 'CHK-HOT-01',
          riskType: HighRiskType.hotWork,
          checkCategory: 'ENVIRONMENT',
          questionTh: 'เคลื่อนย้ายหรือปกคลุมสารไวไฟ/วัสดุติดไฟในรัศมีอย่างน้อย 11 เมตร (35 ฟุต)',
          questionEn: 'Combustible materials within 11 meters cleared or shielded',
          isMandatory: true,
        ),
        PtwChecklistModel(
          ptwNumber: ptwNumber,
          itemId: 'CHK-HOT-02',
          riskType: HighRiskType.hotWork,
          checkCategory: 'ENVIRONMENT',
          questionTh: 'ปิดฝาท่อระบายน้ำ ท่อก๊าซ และช่องเปิดพื้นเพื่อป้องกันสะเก็ดไฟตกลงไป',
          questionEn: 'Sewers, floor drains, and openings covered with fire-resistant covers',
          isMandatory: true,
        ),
        PtwChecklistModel(
          ptwNumber: ptwNumber,
          itemId: 'CHK-HOT-03',
          riskType: HighRiskType.hotWork,
          checkCategory: 'EQUIPMENT',
          questionTh: 'ติดตั้งผ้ากันสะเก็ดไฟ (Fire Blanket) กั้นโดยรอบพื้นที่ประกายไฟ',
          questionEn: 'Fire blanket containment erected around welding/cutting area',
          isMandatory: true,
        ),
        PtwChecklistModel(
          ptwNumber: ptwNumber,
          itemId: 'CHK-HOT-04',
          riskType: HighRiskType.hotWork,
          checkCategory: 'EQUIPMENT',
          questionTh: 'จัดเตรียมถังดับเพลิงชนิดพร้อมใช้งานวางใกล้จุดงานไม่เกิน 10 เมตร',
          questionEn: 'Portable fire extinguisher inspected and stationed within 10 meters',
          isMandatory: true,
        ),
        PtwChecklistModel(
          ptwNumber: ptwNumber,
          itemId: 'CHK-HOT-05',
          riskType: HighRiskType.hotWork,
          checkCategory: 'PERSONNEL',
          questionTh: 'แต่งตั้งผู้เฝ้าระวังไฟ (Fire Watcher) ประจำจุดตลอดเวลาการทำงาน',
          questionEn: 'Designated Fire Watcher assigned and stationed during all hot work',
          isMandatory: true,
        ),
        PtwChecklistModel(
          ptwNumber: ptwNumber,
          itemId: 'CHK-HOT-06',
          riskType: HighRiskType.hotWork,
          checkCategory: 'POST_WORK',
          questionTh: 'เฝ้าระวังและตรวจตราความปลอดภัยหลังงานเสร็จสิ้นไม่น้อยกว่า 30 นาที',
          questionEn: 'Post-work fire watch maintained for at least 30 minutes after completion',
          isMandatory: true,
        ),
      ];

  // 2. Confined Space Statutory Checklist (กฎกระทรวงอับอากาศ ๒๕๖๒)
  static List<PtwChecklistModel> _confinedSpaceChecklist(String? ptwNumber) => [
        PtwChecklistModel(
          ptwNumber: ptwNumber,
          itemId: 'CHK-CONF-01',
          riskType: HighRiskType.confinedSpace,
          checkCategory: 'ISOLATION',
          questionTh: 'ตัดแยกพลังงาน ท่อสารเคมี และล็อกกุญแจ LOTO ทุกจุดที่เชื่อมต่อกับที่อับอากาศ',
          questionEn: 'All pipelines, valves, and electrical feeds locked out / blinded',
          isMandatory: true,
        ),
        PtwChecklistModel(
          ptwNumber: ptwNumber,
          itemId: 'CHK-CONF-02',
          riskType: HighRiskType.confinedSpace,
          checkCategory: 'VENTILATION',
          questionTh: 'ทำการระบายอากาศแบบบังคับ (Mechanical Ventilation) ต่อเนื่องก่อนและระหว่างทำงาน',
          questionEn: 'Continuous forced mechanical ventilation provided before and during entry',
          isMandatory: true,
        ),
        PtwChecklistModel(
          ptwNumber: ptwNumber,
          itemId: 'CHK-CONF-03',
          riskType: HighRiskType.confinedSpace,
          checkCategory: 'ATMOSPHERE',
          questionTh: 'ตรวจวัดบรรยากาศก่อนเข้าทำงาน: O2 (19.5-23.5%), LEL (<10%), CO (<25ppm), H2S (<10ppm)',
          questionEn: 'Pre-entry gas test passed: O2, LEL, CO, H2S within legal limits',
          isMandatory: true,
        ),
        PtwChecklistModel(
          ptwNumber: ptwNumber,
          itemId: 'CHK-CONF-04',
          riskType: HighRiskType.confinedSpace,
          checkCategory: 'PERSONNEL',
          questionTh: 'ผู้มีหน้าที่ 4 ฝ่าย (ผู้อนุญาต, ผู้ควบคุมงาน, ผู้ช่วยเหลือ, ผู้ปฏิบัติงาน) ผ่านการอบรมตามกฎหมาย',
          questionEn: '4 statutory roles (Authorizer, Supervisor, Attendant, Entrant) certified',
          isMandatory: true,
        ),
        PtwChecklistModel(
          ptwNumber: ptwNumber,
          itemId: 'CHK-CONF-05',
          riskType: HighRiskType.confinedSpace,
          checkCategory: 'EMERGENCY',
          questionTh: 'จัดเตรียมอุปกรณ์กู้ภัยฉุกเฉิน (Tripod, Winch, Full Body Harness, SCBA) หน้าทางเข้า',
          questionEn: 'Emergency rescue equipment (Tripod, Winch, Harness, SCBA) ready at entrance',
          isMandatory: true,
        ),
        PtwChecklistModel(
          ptwNumber: ptwNumber,
          itemId: 'CHK-CONF-06',
          riskType: HighRiskType.confinedSpace,
          checkCategory: 'COMMUNICATION',
          questionTh: 'มีระบบสื่อสารระหว่างผู้ช่วยเหลือหน้าทางเข้าและผู้ปฏิบัติงานภายในตลอดเวลา',
          questionEn: 'Two-way communication maintained between attendant and entrants',
          isMandatory: true,
        ),
      ];

  // 3. Working at Height Statutory Checklist (กฎกระทรวงงานบนที่สูง ๒๕๖๔)
  static List<PtwChecklistModel> _workingAtHeightChecklist(String? ptwNumber) => [
        PtwChecklistModel(
          ptwNumber: ptwNumber,
          itemId: 'CHK-HGT-01',
          riskType: HighRiskType.workingAtHeight,
          checkCategory: 'PPE',
          questionTh: 'สวมใส่ชุดเข็มขัดนิรภัยแบบเต็มตัว (Full Body Harness) พร้อมสายช่วยชีวิต (Lanyard) แบบสองตะขอ',
          questionEn: 'Full Body Harness with double lanyards and shock absorber worn',
          isMandatory: true,
        ),
        PtwChecklistModel(
          ptwNumber: ptwNumber,
          itemId: 'CHK-HGT-02',
          riskType: HighRiskType.workingAtHeight,
          checkCategory: 'ANCHORAGE',
          questionTh: 'จุดยึดเหนี่ยว (Anchor Point) หรือ Lifeline มีความมั่นคงแข็งแรงรับแรงดึงได้ไม่น้อยกว่า 22.2 kN',
          questionEn: 'Anchor point / lifeline verified capable of sustaining >= 22.2 kN (5,000 lbs)',
          isMandatory: true,
        ),
        PtwChecklistModel(
          ptwNumber: ptwNumber,
          itemId: 'CHK-HGT-03',
          riskType: HighRiskType.workingAtHeight,
          checkCategory: 'SCAFFOLDING',
          questionTh: 'ตรวจสอบนั่งร้านมีป้ายเขียว (Scafftag Green), ปูแผ่นทางเดินเต็ม, มีราวกั้นตก (Guardrail) และแผ่นกันตก (Toeboard)',
          questionEn: 'Scaffolding inspected (Green Tagged), fully planked, top/mid rails, and toeboards',
          isMandatory: true,
        ),
        PtwChecklistModel(
          ptwNumber: ptwNumber,
          itemId: 'CHK-HGT-04',
          riskType: HighRiskType.workingAtHeight,
          checkCategory: 'FALLING_OBJECTS',
          questionTh: 'กั้นแนวเขตเตือนอันตรายด้านล่าง (Barricade) และใช้เชือกคล้องเครื่องมือป้องกันสิ่งของตก',
          questionEn: 'Barricade drop zone below and tool lanyards attached to prevent dropped objects',
          isMandatory: true,
        ),
        PtwChecklistModel(
          ptwNumber: ptwNumber,
          itemId: 'CHK-HGT-05',
          riskType: HighRiskType.workingAtHeight,
          checkCategory: 'WEATHER',
          questionTh: 'ตรวจสอบสภาพอากาศ ไม่มีฝนตก ลมกรรโชกแรง หรือฟ้าคะนอง',
          questionEn: 'Weather condition safe: no heavy rain, strong winds, or thunderstorms',
          isMandatory: true,
        ),
      ];

  // 4. Electrical & LOTO Statutory Checklist (กฎกระทรวงไฟฟ้า ๒๕๕๘)
  static List<PtwChecklistModel> _electricalLotoChecklist(String? ptwNumber) => [
        PtwChecklistModel(
          ptwNumber: ptwNumber,
          itemId: 'CHK-ELEC-01',
          riskType: HighRiskType.electricalLoto,
          checkCategory: 'ISOLATION',
          questionTh: 'สับเบรกเกอร์หรือปิดวาล์วตัดแยกแหล่งจ่ายพลังงานครบทุกจุด',
          questionEn: 'All power supply breakers / isolation valves disconnected',
          isMandatory: true,
        ),
        PtwChecklistModel(
          ptwNumber: ptwNumber,
          itemId: 'CHK-ELEC-02',
          riskType: HighRiskType.electricalLoto,
          checkCategory: 'LOTO',
          questionTh: 'คล้องกุญแจล็อกนิรภัย (Safety Padlock) และติดป้ายเตือนอันตราย (LOTO Tag) ทุกจุดตัดแยก',
          questionEn: 'Safety padlocks and danger warning tags installed at each lockout point',
          isMandatory: true,
        ),
        PtwChecklistModel(
          ptwNumber: ptwNumber,
          itemId: 'CHK-ELEC-03',
          riskType: HighRiskType.electricalLoto,
          checkCategory: 'ZERO_ENERGY',
          questionTh: 'ทดสอบวัดแรงดันไฟฟ้า/พลังงานตกค้างเป็นศูนย์ (Zero Energy Verification: 0V, 0 bar)',
          questionEn: 'Zero energy verified with calibrated voltmeter (0V) or pressure gauge release',
          isMandatory: true,
        ),
        PtwChecklistModel(
          ptwNumber: ptwNumber,
          itemId: 'CHK-ELEC-04',
          riskType: HighRiskType.electricalLoto,
          checkCategory: 'PPE',
          questionTh: 'สวมใส่อุปกรณ์คุ้มครองความปลอดภัยส่วนบุคคลด้านไฟฟ้า (ถุงมือยางกันไฟฟ้า, แว่นตากันประกายไฟ, ชุด Arc Flash)',
          questionEn: 'Electrical PPE worn: Insulated gloves, dielectric shoes, Arc Flash shield',
          isMandatory: true,
        ),
      ];

  // 5. Excavation & Lifting Statutory Checklist (กฎกระทรวงงานดินขุดและปั้นจั่น ๒๕๖๔)
  static List<PtwChecklistModel> _excavationLiftingChecklist(String? ptwNumber) => [
        PtwChecklistModel(
          ptwNumber: ptwNumber,
          itemId: 'CHK-EXC-01',
          riskType: HighRiskType.excavationLifting,
          checkCategory: 'UTILITIES',
          questionTh: 'ตรวจสอบแบบแนวท่อใต้ดิน สายไฟใต้ดิน หรือท่อก๊าซก่อนเริ่มขุดเจาะ',
          questionEn: 'Underground cables, gas lines, and utilities surveyed and marked',
          isMandatory: true,
        ),
        PtwChecklistModel(
          ptwNumber: ptwNumber,
          itemId: 'CHK-EXC-02',
          riskType: HighRiskType.excavationLifting,
          checkCategory: 'SHORING',
          questionTh: 'กรณีขุดลึกเกิน 1.5 เมตร มีการติดตั้งค้ำยัน (Shoring) หรือทำลาดเอียง (Sloping) ป้องกันดินถล่ม',
          questionEn: 'Excavation >= 1.5m protected by protective shoring, shielding, or sloping',
          isMandatory: true,
        ),
        PtwChecklistModel(
          ptwNumber: ptwNumber,
          itemId: 'CHK-EXC-03',
          riskType: HighRiskType.excavationLifting,
          checkCategory: 'CRANE',
          questionTh: 'ปั้นจั่น/เครนผ่านการตรวจทดสอบประจำปี (แบบ ปจ.๑/ปจ.๒) และผู้ควบคุมผ่านการอบรม',
          questionEn: 'Crane inspected (Por.Jor. certificate valid) and certified crane operator',
          isMandatory: true,
        ),
        PtwChecklistModel(
          ptwNumber: ptwNumber,
          itemId: 'CHK-EXC-04',
          riskType: HighRiskType.excavationLifting,
          checkCategory: 'RIGGING',
          questionTh: 'อุปกรณ์ช่วยยก (สลิง, สะเก็น, สายพานผ้า) มีป้ายบอกพิกัดน้ำหนักปลอดภัย (SWL) และไม่มีรอยชำรุด',
          questionEn: 'Lifting gears (slings, shackles, webbings) tagged with SWL and defect-free',
          isMandatory: true,
        ),
      ];
}
