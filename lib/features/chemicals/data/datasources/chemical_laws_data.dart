import '../../domain/models/chemical_laws_model.dart';

/// Seed data of 7 Thai Royal Gazette occupational chemical safety regulations.
class ChemicalLawsData {
  static const List<ChemicalLawItem> laws = [
    ChemicalLawItem(
      id: 'LAW-001',
      titleTh: 'กฎกระทรวง กำหนดมาตรฐานในการบริหาร จัดการ และดำเนินการด้านความปลอดภัย อาชีวอนามัย และสภาพแวดล้อมในการทำงานเกี่ยวกับสารเคมีอันตราย พ.ศ. ๒๕๕๖',
      titleEn: 'Ministerial Regulation on the Standard for Administration, Management and Operation of Occupational Safety, Health and Environment in Relation to Hazardous Chemicals B.E. 2556 (2013)',
      issuingAuthority: 'กระทรวงแรงงาน (Ministry of Labour)',
      gazetteDate: '๒๙ พฤศจิกายน ๒๕๕๖',
      gazetteVolume: '๑๓๐',
      gazettePart: '๑๑๓ ก',
      category: 'MINISTERIAL_REG',
      sortOrder: 1,
      summary: 'กำหนดให้นายจ้างจัดทำบัญชีรายชื่อสารเคมีอันตรายและรายละเอียดข้อมูลความปลอดภัย (สอ.๑), ปิดป้ายและฉลากตามระบบ GHS, ตรวจวัดระดับความเข้มข้นสารเคมีในบรรยากาศการทำงาน (สอ.๓), จัดทำแผนฉุกเฉิน และจัดอบรมลูกจ้างก่อนเริ่มงาน',
      keyProvisions: [
        'หมวด ๑ ข้อมูลความปลอดภัย (ข้อ ๓-๖): ให้นายจ้างจัดทำบัญชีรายชื่อสารเคมีอันตรายและข้อมูลความปลอดภัยตามแบบ สอ.๑ แจ้งต่ออธิบดีภายใน ๗ วันนับแต่วันที่มีสารเคมีในครอบครอง และทบทวนทุก ๓-๕ ปี',
        'หมวด ๒ การปิดป้ายและฉลาก (ข้อ ๗-๑๑): ต้องปิดป้ายฉลากที่มีสัญลักษณ์ GHS, คำสัญญาณ (Danger/Warning), ข้อความแสดงความเป็นอันตราย และข้อควรระวัง',
        'หมวด ๓ การคุ้มครองความปลอดภัย (ข้อ ๑๒-๒๓): นายจ้างต้องควบคุมระดับความเข้มข้นของสารเคมีอันตรายในบรรยากาศการทำงานไม่ให้เกินขีดจำกัดตามที่อธิบดีประกาศกำหนด (TLV)',
        'หมวด ๔ การตรวจวัดและวิเคราะห์ (ข้อ ๒๔-๒๘): จัดให้มีการตรวจวัดและวิเคราะห์ระดับความเข้มข้นของสารเคมีอันตรายในบรรยากาศการทำงานอย่างน้อยปีละหนึ่งครั้ง ส่งรายงานตามแบบ สอ.๓ ภายใน ๑๕ วัน',
        'หมวด ๕ การควบคุมและการปฏิบัติการฉุกเฉิน (ข้อ ๒๙-๓๙): จัดให้มีระบบระบายอากาศ, อุปกรณ์คุ้มครองความปลอดภัยส่วนบุคคล (PPE), ฝักบัวและอ่างล้างตาฉุกเฉิน, และการซ้อมแผนระงับอุบัติภัย',
      ],
      pdfAssetPath: 'assets/laws/ministerial_regulation_chemical_2556.pdf',
      externalUrl: 'https://ratchakitcha.soc.go.th/documents/1990425.pdf',
    ),
    ChemicalLawItem(
      id: 'LAW-002',
      titleTh: 'ประกาศกรมสวัสดิการและคุ้มครองแรงงาน เรื่อง บัญชีรายชื่อสารเคมีอันตราย (๑,๕๑๖ รายการ)',
      titleEn: 'DLPW Notification: List of Regulated Hazardous Chemicals (1,516 Substances)',
      issuingAuthority: 'กรมสวัสดิการและคุ้มครองแรงงาน',
      gazetteDate: '๒๐ ธันวาคม ๒๕๕๖',
      gazetteVolume: '๑๓๐',
      gazettePart: '๑๘๕ ง (พิเศษ)',
      category: 'DLPW_NOTIF',
      sortOrder: 2,
      summary: 'ประกาศกำหนดรายชื่อสารเคมีอันตรายที่นายจ้างต้องจัดทำบัญชีรายชื่อ (สอ.๑), จัดทำ SDS, ปิดฉลาก GHS และรายงานการครอบครอง จำนวน ๑,๕๑๖ รายการ พร้อมระบุชื่อภาษาไทย ชื่อภาษาอังกฤษ และหมายเลข CAS Number',
      keyProvisions: [
        'กำหนดบัญชีสารเคมีอันตรายลำดับที่ ๑ ถึง ๑,๕๑๖ ที่อยู่ภายใต้การบังคับใช้ของกฎกระทรวงสารเคมีอันตราย พ.ศ. ๒๕๕๖',
        'สารเคมีที่มีอยู่ในบัญชีนี้ หากมีไว้ในครอบครองตั้งแต่ปริมาณที่กำหนด ต้องจัดทำแบบ สอ.๑ และปิดฉลากตามมาตรฐาน GHS',
        'ครอบคลุมสารเคมีอุตสาหกรรมทั่วไป ตัวทำละลาย โลหะหนัก กรด-ด่าง ก๊าซอัดความดัน และสารไวไฟสูง',
      ],
      pdfAssetPath: 'assets/laws/dlpw_1516_hazardous_chemicals.pdf',
      externalUrl: 'https://ratchakitcha.soc.go.th/documents/1991823.pdf',
    ),
    ChemicalLawItem(
      id: 'LAW-003',
      titleTh: 'ประกาศกรมสวัสดิการและคุ้มครองแรงงาน เรื่อง ขีดจำกัดความเข้มข้นของสารเคมีอันตราย (๓๒๔ รายการ)',
      titleEn: 'DLPW Notification: Occupational Exposure Limits (TLV) for Hazardous Chemicals (324 Substances)',
      issuingAuthority: 'กรมสวัสดิการและคุ้มครองแรงงาน',
      gazetteDate: '๓ สิงหาคม ๒๕๖๐',
      gazetteVolume: '๑๓๔',
      gazettePart: '๑๙๘ ง (พิเศษ)',
      category: 'DLPW_NOTIF',
      sortOrder: 3,
      summary: 'กำหนดเกณฑ์มาตรฐานขีดจำกัดความเข้มข้นสารเคมีในบรรยากาศการทำงาน ๓๒๔ รายการ ประกอบด้วยค่าเฉลี่ยตลอดเวลาการทำงานปกติ ๘ ชั่วโมง (TWA), ค่าความเข้มข้นระยะสั้น ๑๕ นาที (STEL), และค่าเพดานสูงสุด (Ceiling) ทั้งในหน่วย ppm และ mg/m³ พร้อมเครื่องหมาย Skin Notation',
      keyProvisions: [
        'ค่าเฉลี่ยตลอดระยะเวลาทำงานปกติ ๘ ชั่วโมง (Time-Weighted Average: TWA)',
        'ค่าขีดจำกัดความเข้มข้นระยะสั้น ๑๕ นาที (Short-Term Exposure Limit: STEL)',
        'ค่าขีดจำกัดสูงสุด ณ เวลาใดเวลาหนึ่ง (Ceiling Limit: C)',
        'สัญลักษณ์ "ผิวหนัง" (Skin Notation): เตือนความเสี่ยงการดูดซึมผ่านผิวหนัง',
        'กรณีสารเคมีผสม (Mixture): ให้นายจ้างประเมินผลรวมการสัมผัสตามสูตร Additivity Index (Em <= 1.0)',
      ],
      pdfAssetPath: 'assets/laws/dlpw_324_tlv_standards.pdf',
      externalUrl: 'https://ratchakitcha.soc.go.th/documents/2112450.pdf',
    ),
    ChemicalLawItem(
      id: 'LAW-004',
      titleTh: 'ประกาศกรมสวัสดิการและคุ้มครองแรงงาน เรื่อง แบบบัญชีรายชื่อสารเคมีอันตรายและรายละเอียดข้อมูลความปลอดภัยของสารเคมีอันตราย (แบบ สอ.๑)',
      titleEn: 'DLPW Notification: Form of Hazardous Chemical Inventory and Safety Data Sheet (Form Sor.Or.1 - 16 GHS Headings)',
      issuingAuthority: 'กรมสวัสดิการและคุ้มครองแรงงาน',
      gazetteDate: '๒๐ ธันวาคม ๒๕๕๖',
      gazetteVolume: '๑๓๐',
      gazettePart: '๑๘๕ ง (พิเศษ)',
      category: 'DLPW_NOTIF',
      sortOrder: 4,
      summary: 'กำหนดแบบฟอร์ม สอ.๑ สำหรับจัดทำรายละเอียดข้อมูลความปลอดภัยของสารเคมีอันตรายตามระบบสากล GHS ครบถ้วน ๑๖ หัวข้อ เพื่อใช้ในการแจ้งครอบครองและสื่อสารความปลอดภัยให้ลูกจ้าง',
      keyProvisions: [
        'กำหนดโครงสร้าง SDS ครบ ๑๖ หัวข้อตามมาตรฐานสหประชาชาติ (UN GHS Rev.8)',
        'หัวข้อ ๑: ข้อมูลเกี่ยวกับสารเคมีและผู้ผลิต/นำเข้า',
        'หัวข้อ ๒: การบ่งชี้ความเป็นอันตราย (รูปสัญลักษณ์, คำสัญญาณ, ข้อความอันตราย)',
        'หัวข้อ ๓-๑๖: ส่วนผสม, การปฐมพยาบาล, ผจญเพลิง, หกรั่วไหล, กายภาพ/เคมี, พิษวิทยา, สิ่งแวดล้อม, ขนส่ง และข้อมูลทางกฎหมาย',
        'นายจ้างต้องเก็บรักษาเอกสาร สอ.๑ ไว้ ณ สถานประกอบกิจการและพร้อมให้ลูกจ้างตรวจสอบได้ตลอดเวลา',
      ],
      pdfAssetPath: 'assets/laws/dlpw_form_sor1_sds.pdf',
      externalUrl: 'https://ratchakitcha.soc.go.th/documents/1991824.pdf',
    ),
    ChemicalLawItem(
      id: 'LAW-005',
      titleTh: 'ประกาศกรมสวัสดิการและคุ้มครองแรงงาน เรื่อง หลักเกณฑ์ วิธีการตรวจวัด และการวิเคราะห์ผลการตรวจวัดระดับความเข้มข้นของสารเคมีอันตราย (ฉบับที่ ๒) พ.ศ. ๒๕๖๕ (แบบ สอ.๓)',
      titleEn: 'DLPW Notification: Rules, Methods for Measurement and Analysis of Atmospheric Hazardous Chemical Concentration (No.2) B.E. 2565 (Form Sor.Or.3)',
      issuingAuthority: 'กรมสวัสดิการและคุ้มครองแรงงาน',
      gazetteDate: '๒๙ มีนาคม ๒๕๖๕',
      gazetteVolume: '๑๓๙',
      gazettePart: '๗๓ ง (พิเศษ)',
      category: 'DLPW_NOTIF',
      sortOrder: 5,
      summary: 'ปรับปรุงแบบรายงานผลการตรวจวัดและวิเคราะห์ระดับความเข้มข้นของสารเคมีอันตรายในบรรยากาศการทำงาน (แบบ สอ.๓) กำหนดให้ผู้ตรวจวัดต้องขึ้นทะเบียนเป็นนิติบุคคลตามมาตรา ๙ หรือบุคคลธรรมดาตามมาตรา ๑๑ แห่ง พ.ร.บ. ความปลอดภัยฯ ๒๕๕๔',
      keyProvisions: [
        'ปรับปรุงแบบฟอร์ม สอ.๓ ท้ายประกาศให้มีโครงสร้าง ๖ ส่วนที่ชัดเจน',
        'กำหนดให้ระบุเลขทะเบียนใบสำคัญของผู้ขึ้นทะเบียนตาม มาตรา ๙ (นิติบุคคล) หรือ มาตรา ๑๑ (บุคคลธรรมดา)',
        'บันทึกจุดตรวจวัด, สภาพแวดล้อม, วิธีเก็บตัวอย่าง (NIOSH/OSHA), วิธีวิเคราะห์ทางห้องปฏิบัติการ, และเปรียบเทียบกับค่ามาตรฐาน TLV',
        'ให้นายจ้างส่งรายงาน สอ.๓ ต่ออธิบดีหรือผู้ซึ่งอธิบดีมอบหมายภายใน ๑๕ วันนับแต่วันที่ได้รับผลการตรวจวัด',
      ],
      pdfAssetPath: 'assets/laws/dlpw_form_sor3_measurement_2565.pdf',
      externalUrl: 'https://ratchakitcha.soc.go.th/documents/2205781.pdf',
    ),
    ChemicalLawItem(
      id: 'LAW-006',
      titleTh: 'พระราชบัญญัติ ความปลอดภัย อาชีวอนามัย และสภาพแวดล้อมในการทำงาน พ.ศ. ๒๕๕๔',
      titleEn: 'Occupational Safety, Health and Environment Act B.E. 2554 (2011)',
      issuingAuthority: 'สภานิติบัญญัติแห่งชาติ (พระบาทสมเด็จพระปรมินทรมหาภูมิพลอดุลยเดช)',
      gazetteDate: '๑๗ มกราคม ๒๕๕๔',
      gazetteVolume: '๑๒๘',
      gazettePart: '๔ ก',
      category: 'ACT',
      sortOrder: 6,
      summary: 'กฎหมายแม่บทด้านความปลอดภัยในการทำงาน ให้อำนาจนายทะเบียนในการกำกับดูแล กำหนดหน้าที่ของนายจ้างและลูกจ้าง การขึ้นทะเบียนหน่วยงานตรวจวัด (มาตรา ๙), บุคคลผู้ให้บริการ (มาตรา ๑๑), และการฝึกอบรมความปลอดภัย (มาตรา ๑๖)',
      keyProvisions: [
        'มาตรา ๘: นายจ้างมีหน้าที่บริหาร จัดการ และดำเนินการด้านความปลอดภัย อาชีวอนามัยฯ ให้เป็นไปตามมาตรฐานที่กำหนดในกฎกระทรวง',
        'มาตรา ๙: การขึ้นทะเบียนนิติบุคคลผู้ให้บริการตรวจวัด ตรวจสอบ หรือรับรองสภาพแวดล้อมในการทำงาน',
        'มาตรา ๑๑: การขึ้นทะเบียนบุคคลธรรมดาผู้มีคุณสมบัติในการตรวจวัดและประเมินผล',
        'มาตรา ๑๖: นายจ้างต้องจัดให้ลูกจ้างได้รับการฝึกอบรมความปลอดภัยฯ ก่อนเข้าทำงานหรือเปลี่ยนงาน',
        'มาตรา ๓๓: การแต่งตั้งผู้เชี่ยวชาญด้านความปลอดภัยในการทำงานเพื่อรับรองการประเมินความเสี่ยง',
      ],
      pdfAssetPath: 'assets/laws/osh_act_2554.pdf',
      externalUrl: 'https://ratchakitcha.soc.go.th/documents/1898762.pdf',
    ),
    ChemicalLawItem(
      id: 'LAW-007',
      titleTh: 'ประกาศกระทรวงอุตสาหกรรม เรื่อง ระบบการจำแนกและการสื่อสารความเป็นอันตรายของวัตถุอันตราย (GHS) พ.ศ. ๒๕๕๕',
      titleEn: 'Ministry of Industry Notification: Hazard Classification and Communication System of Hazardous Substances (GHS) B.E. 2555 (2012)',
      issuingAuthority: 'กระทรวงอุตสาหกรรม (Ministry of Industry)',
      gazetteDate: '๑๒ มีนาคม ๒๕๕๕',
      gazetteVolume: '๑๒๙',
      gazettePart: '๕๐ ง (พิเศษ)',
      category: 'MIN_INDUSTRY',
      sortOrder: 7,
      summary: 'นำระบบสากล GHS (Globally Harmonized System of Classification and Labelling of Chemicals) มาบังคับใช้ในประเทศไทย ครอบคลุมการจำแนกความเป็นอันตรายทางกายภาพ สุขภาพ และสิ่งแวดล้อม, การจัดทำฉลากและรูปสัญลักษณ์ ๙ แบบ, และเอกสาร SDS',
      keyProvisions: [
        'กำหนดประเภทความเป็นอันตราย ๓ ด้าน: ด้านกายภาพ (Physical Hazards), ด้านสุขภาพ (Health Hazards), ด้านสิ่งแวดล้อม (Environmental Hazards)',
        'กำหนดรูปสัญลักษณ์อันตราย ๙ รูป (Pictograms: Flame, Flame over circle, Exploding bomb, Corrosion, Gas cylinder, Skull and crossbones, Exclamation mark, Health hazard, Environment)',
        'กำหนดคำสัญญาณ ๒ ระดับ: "อันตราย" (Danger) สำหรับความรุนแรงสูง, "ระวัง" (Warning) สำหรับความรุนแรงปานกลาง',
        'ข้อความแสดงความเป็นอันตราย (H-Statements) และข้อความแสดงข้อควรระวัง (P-Statements)',
      ],
      pdfAssetPath: 'assets/laws/min_industry_ghs_2555.pdf',
      externalUrl: 'https://ratchakitcha.soc.go.th/documents/1930214.pdf',
    ),
  ];

  static ChemicalLawItem? getById(String id) {
    try {
      return laws.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  static List<ChemicalLawItem> getByCategory(String category) {
    return laws.where((e) => e.category == category).toList();
  }

  static List<ChemicalLawItem> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return laws;
    return laws.where((e) {
      return e.titleTh.toLowerCase().contains(q) ||
          e.titleEn.toLowerCase().contains(q) ||
          e.summary.toLowerCase().contains(q) ||
          e.id.toLowerCase().contains(q);
    }).toList();
  }
}
