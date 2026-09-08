import 'package:flutter/material.dart';
import '../../domain/enums/high_risk_type.dart';

/// Model representing a statutory article or provision from Thai Safety Legislation
class PtwStatutoryArticle {
  final String articleNumber; // e.g. "มาตรา ๑๔", "ข้อ ๗"
  final String title;
  final String content;
  final String practicalApplication; // การนำไปใช้ปฏิบัติจริงหน้างาน
  final String? penaltyNotice; // โทษปรับ / จำคุก ตามกฎหมาย

  const PtwStatutoryArticle({
    required this.articleNumber,
    required this.title,
    required this.content,
    required this.practicalApplication,
    this.penaltyNotice,
  });
}

/// Model representing an authoritative Royal Gazette Safety Regulation
class PtwLegalGazetteItem {
  final String lawId;
  final String titleTh;
  final String titleEn;
  final String gazetteBookVolume; // e.g. "เล่ม ๑๒๘ ตอนที่ ๔ ก"
  final String announcementDate; // วันที่ประกาศราชกิจจานุเบกษา
  final String effectiveDate; // วันที่มีผลใช้บังคับ
  final HighRiskType? primaryRiskType;
  final String category; // 'ACT', 'MINISTERIAL_REGULATION', 'DEPARTMENT_NOTIFICATION'
  final String summaryTh;
  final List<PtwStatutoryArticle> keyArticles;
  final List<String> mandatoryChecklistHighlights;
  final IconData icon;
  final Color themeColor;

  const PtwLegalGazetteItem({
    required this.lawId,
    required this.titleTh,
    required this.titleEn,
    required this.gazetteBookVolume,
    required this.announcementDate,
    required this.effectiveDate,
    this.primaryRiskType,
    required this.category,
    required this.summaryTh,
    required this.keyArticles,
    required this.mandatoryChecklistHighlights,
    required this.icon,
    required this.themeColor,
  });
}

/// Static Master Repository for Thai Safety Legislation & Royal Gazette Regulations
class PtwLegalGazetteData {
  static const List<PtwLegalGazetteItem> regulations = [
    // 1. พ.ร.บ. ความปลอดภัยฯ ๒๕๕๔
    PtwLegalGazetteItem(
      lawId: 'LAW-OSH-ACT-2554',
      titleTh: 'พระราชบัญญัติ ความปลอดภัย อาชีวอนามัย และสภาพแวดล้อมในการทำงาน พ.ศ. ๒๕๕๔',
      titleEn: 'Occupational Safety, Health and Environment Act B.E. 2554 (2011)',
      gazetteBookVolume: 'เล่ม ๑๒๘ ตอนที่ ๔ ก หน้า ๑',
      announcementDate: '๑๗ มกราคม ๒๕๕๔',
      effectiveDate: '๑๖ กรกฎาคม ๒๕๕๔',
      category: 'ACT',
      summaryTh: 'กฎหมายแม่บทด้านความปลอดภัยในการทำงาน กำหนดหน้าที่นายจ้าง ลูกจ้าง ผู้รับเหมา การแจ้งอันตราย การฝึกอบรมก่อนเริ่มงานความเสี่ยงสูง และการจัดทำแผนบริหารจัดการความปลอดภัย',
      icon: Icons.gavel_rounded,
      themeColor: Color(0xFF1E3A8A),
      keyArticles: [
        PtwStatutoryArticle(
          articleNumber: 'มาตรา ๘',
          title: 'หน้าที่นายจ้างในการบริหารจัดการความปลอดภัย',
          content: 'ให้นายจ้างมีหน้าที่จัดและดูแลสถานประกอบกิจการและลูกจ้างให้มีสภาพการทำงานและสภาพแวดล้อมในการทำงานที่ปลอดภัยและถูกสุขลักษณะ รวมทั้งส่งเสริมและสนับสนุนการปฏิบัติงานของลูกจ้างมิให้ลูกจ้างได้รับอันตรายต่อชีวิต ร่างกาย จิตใจ หรือสุขภาพอนามัย',
          practicalApplication: 'ต้องมีระบบใบอนุญาตทำงาน (PTW) เพื่อควบคุมงานความเสี่ยงสูงทุกประเภทก่อนเริ่มงาน',
          penaltyNotice: 'ฝ่าฝืนมีโทษจำคุกไม่เกิน ๑ ปี หรือปรับไม่เกิน ๔๐๐,๐๐๐ บาท หรือทั้งจำทั้งปรับ (ม.๕๓)',
        ),
        PtwStatutoryArticle(
          articleNumber: 'มาตรา ๑๔',
          title: 'การแจ้งอันตรายและคู่มือความปลอดภัยแก่ลูกจ้าง',
          content: 'นายจ้างต้องแจ้งให้ลูกจ้างทราบถึงอันตรายที่อาจจะเกิดขึ้นจากการทำงาน และแจกคู่มือปฏิบัติงานให้ลูกจ้างทุกคนก่อนเข้าทำงาน เปลี่ยนงาน หรือเปลี่ยนสถานที่ทำงาน',
          practicalApplication: 'ต้องแนบเอกสาร JSA/Risk Assessment และอธิบายขั้นตอนความปลอดภัยใน Tool Box Talk หน้างาน',
        ),
        PtwStatutoryArticle(
          articleNumber: 'มาตรา ๑๖',
          title: 'การฝึกอบรมความปลอดภัยก่อนเริ่มงาน',
          content: 'ให้นายจ้างจัดให้ผู้บริหาร หัวหน้างาน และลูกจ้างทุกคนได้รับการฝึกอบรมความปลอดภัย อาชีวอนามัย และสภาพแวดล้อมในการทำงาน เพื่อให้บริหารจัดการและปฏิบัติงานได้อย่างปลอดภัย',
          practicalApplication: 'ผู้ปฏิบัติงานในที่อับอากาศ งานบนที่สูง งานไฟฟ้า ต้องผ่านการอบรมตามหลักสูตรที่กฎหมายกำหนด',
        ),
        PtwStatutoryArticle(
          articleNumber: 'มาตรา ๒๒',
          title: 'การจัดหาอุปกรณ์คุ้มครองความปลอดภัยส่วนบุคคล (PPE)',
          content: 'ให้นายจ้างจัดและดูแลให้ลูกจ้างสวมใส่อุปกรณ์คุ้มครองความปลอดภัยส่วนบุคคลที่ได้มาตรฐานตามที่อธิบดีประกาศกำหนด และลูกจ้างมีหน้าที่ต้องสวมใส่และดูแลรักษาตลอดเวลาปฏิบัติงาน',
          practicalApplication: 'บังคับระบุรายการ PPE ในใบ PTW และตรวจสอบสภาพก่อนอนุญาตเปิดงาน',
        ),
        PtwStatutoryArticle(
          articleNumber: 'มาตรา ๒๓',
          title: 'การกำกับดูแลความปลอดภัยของผู้รับเหมา (Contractor Safety)',
          content: 'ในกรณีที่นายจ้างให้ผู้รับเหมาเข้ามาทำงานในสถานประกอบกิจการ ให้นายจ้างมีหน้าที่ควบคุมดูแลให้ผู้รับเหมาและลูกจ้างของผู้รับเหมาปฏิบัติตามมาตรฐานความปลอดภัยเช่นเดียวกับลูกจ้างของตน',
          practicalApplication: 'ผู้รับเหมาช่วงต้องยื่นขอ PTW และผ่านการตรวจประเมิน JSA ก่อนเข้าพื้นที่ทำงานทุกครั้ง',
        ),
      ],
      mandatoryChecklistHighlights: [
        'มีระบบขออนุญาตทำงาน (PTW) สำหรับงานอันตราย',
        'แจ้งเตือนอันตรายและชี้แจง JSA หน้างานก่อนเริ่มงาน',
        'ตรวจสอบใบผ่านการฝึกอบรมของผู้ปฏิบัติงาน',
        'จัดหา PPE ที่ได้มาตรฐาน มอก./EN/ANSI ครบถ้วน',
        'ควบคุมผู้รับเหมาให้ปฏิบัติตามระเบียบความปลอดภัย 100%',
      ],
    ),

    // 2. กฎกระทรวงที่อับอากาศ ๒๕๖๒
    PtwLegalGazetteItem(
      lawId: 'LAW-CONFINED-SPACE-2562',
      titleTh: 'กฎกระทรวง กำหนดมาตรฐานในการบริหาร จัดการ และดำเนินการด้านความปลอดภัย อาชีวอนามัย และสภาพแวดล้อมในการทำงานในสถานที่อับอากาศ พ.ศ. ๒๕๖๒',
      titleEn: 'Ministerial Regulation on Occupational Safety, Health and Environment in Confined Spaces B.E. 2562 (2019)',
      gazetteBookVolume: 'เล่ม ๑๓๖ ตอนที่ ๑๐๐ ก หน้า ๒๕',
      announcementDate: '๑๒ กันยายน ๒๕๖๒',
      effectiveDate: '๑๒ ธันวาคม ๒๕๖๒',
      primaryRiskType: HighRiskType.confinedSpace,
      category: 'MINISTERIAL_REGULATION',
      summaryTh: 'กำหนดมาตรฐานความปลอดภัยในสถานที่อับอากาศ เกณฑ์บรรยากาศอันตราย (O2, LEL, CO, H2S) การตรวจวัดก๊าซก่อนและระหว่างทำงาน ทะเบียนผู้มีหน้าที่ 4 ฝ่าย และอุปกรณ์กู้ภัยฉุกเฉิน',
      icon: Icons.sensor_door_rounded,
      themeColor: Color(0xFF8B5CF6),
      keyArticles: [
        PtwStatutoryArticle(
          articleNumber: 'ข้อ ๔ & ๕',
          title: 'หนังสืออนุญาตทำงานในที่อับอากาศและปิดประกาศ',
          content: 'ห้ามมิให้นายจ้างให้ลูกจ้างหรือบุคคลใดเข้าไปในสถานที่อับอากาศ เว้นแต่จะได้รับหนังสืออนุญาตจากผู้อนุญาต และต้องปิดประกาศหนังสืออนุญาตไว้ที่บริเวณทางเข้าสถานที่อับอากาศให้เห็นได้ชัดเจนตลอดเวลาทำงาน',
          practicalApplication: 'ต้องออกใบ PTW ที่อับอากาศและพิมพ์หรือแสดง QR Code ปิดหน้าทางเข้าถัง/บ่อ',
          penaltyNotice: 'ฝ่าฝืนมีโทษปรับไม่เกิน ๔๐๐,๐๐๐ บาท หรือจำคุกไม่เกิน ๑ ปี ตาม พ.ร.บ. ๒๕๕๔',
        ),
        PtwStatutoryArticle(
          articleNumber: 'ข้อ ๗',
          title: 'เกณฑ์มาตรฐานบรรยากาศอันตราย (Hazardous Atmosphere Thresholds)',
          content: 'บรรยากาศอันตราย หมายถึง: (๑) ออกซิเจนต่ำกว่า 19.5% หรือเกินกว่า 23.5% โดยปริมาตร (๒) ก๊าซ ไอ หรือละอองที่ติดไฟหรือระเบิดได้ เกินกว่า 10% ของค่า LEL (๓) สารเคมีอันตรายเกินขีดจำกัดความเข้มข้นสารเคมี (CO >= 25 ppm, H2S >= 10 ppm)',
          practicalApplication: 'ตรวจวัดก๊าซ 4 ชนิด (O2, LEL, CO, H2S) ก่อนลงทำงานและตรวจวัดต่อเนื่องทุก 1-2 ชั่วโมง',
        ),
        PtwStatutoryArticle(
          articleNumber: 'ข้อ ๙-๑๒',
          title: 'ผู้มีหน้าที่ 4 ฝ่ายในสถานที่อับอากาศ',
          content: 'นายจ้างต้องแต่งตั้งและจัดให้มีผู้มีหน้าที่ 4 ฝ่าย ได้แก่: 1. ผู้อนุญาต (ข้อ ๙) 2. ผู้ควบคุมงาน (ข้อ ๑๐) 3. ผู้ช่วยเหลือ (ข้อ ๑๑) 4. ผู้ปฏิบัติงาน (ข้อ ๑๒) โดยทุกคนต้องผ่านการฝึกอบรมหลักสูตรความปลอดภัยในที่อับอากาศตามที่อธิบดีกำหนด',
          practicalApplication: 'บันทึกรายชื่อและเลขที่ใบรับรองผ่านการอบรมของผู้มีหน้าที่ทั้ง 4 ฝ่ายในระบบ PTW',
        ),
        PtwStatutoryArticle(
          articleNumber: 'ข้อ ๑๗ & ๑๘',
          title: 'แผนฉุกเฉินและอุปกรณ์กู้ภัย',
          content: 'นายจ้างต้องจัดทำแผนปฏิบัติการกรณีฉุกเฉินและการกู้ภัย พร้อมทั้งจัดเตรียมอุปกรณ์ช่วยเหลือและกู้ภัยที่เหมาะสม เช่น ขาหยั่งสามขา (Tripod), รอกกู้ภัย (Winch), ชุดสายรัดตัว (Full Body Harness), และเครื่องช่วยหายใจ (SCBA/Airline)',
          practicalApplication: 'ตรวจสอบความพร้อมของอุปกรณ์กู้ภัยหน้าทางเข้าก่อนอนุญาตเปิดงานทุกครั้ง',
        ),
      ],
      mandatoryChecklistHighlights: [
        'ปิดประกาศหนังสืออนุญาต (PTW) บริเวณทางเข้าสถานที่อับอากาศ',
        'ตรวจวัดบรรยากาศ O2 (19.5-23.5%), LEL (<10%), CO (<25ppm), H2S (<10ppm)',
        'ระบายอากาศแบบบังคับ (Mechanical Ventilation) อย่างต่อเนื่อง',
        'ผู้มีหน้าที่ 4 ฝ่ายครบถ้วนและมีใบประกาศรับรองไม่หมดอายุ',
        'ติดตั้งขาหยั่งกู้ภัย Tripod, รอก Winch, Full Body Harness หน้างาน',
      ],
    ),

    // 3. กฎกระทรวงอัคคีภัย ๒๕๕๕
    PtwLegalGazetteItem(
      lawId: 'LAW-FIRE-PREVENTION-2555',
      titleTh: 'กฎกระทรวง กำหนดมาตรฐานในการบริหาร จัดการ และดำเนินการด้านความปลอดภัย อาชีวอนามัย และสภาพแวดล้อมในการทำงานเกี่ยวกับการป้องกันและระงับอัคคีภัย พ.ศ. ๒๕๕๕',
      titleEn: 'Ministerial Regulation on Fire Prevention and Suppression B.E. 2555 (2012)',
      gazetteBookVolume: 'เล่ม ๑๓๐ ตอนที่ ๒ ก หน้า ๑',
      announcementDate: '๙ มกราคม ๒๕๕๖',
      effectiveDate: '๙ เมษายน ๒๕๕๖',
      primaryRiskType: HighRiskType.hotWork,
      category: 'MINISTERIAL_REGULATION',
      summaryTh: 'ควบคุมการทำงานที่ก่อให้เกิดประกายไฟหรือความร้อน (Hot Work) การเคลื่อนย้ายสารไวไฟในรัศมี 11 เมตร การติดตั้งผ้ากันสะเก็ดไฟ ถังดับเพลิงประจำจุด และการเฝ้าระวังไฟหลังเลิกงานไม่น้อยกว่า 30 นาที',
      icon: Icons.local_fire_department_rounded,
      themeColor: Color(0xFFEA580C),
      keyArticles: [
        PtwStatutoryArticle(
          articleNumber: 'หมวด ๒ ข้อ ๑๑-๑๔',
          title: 'การป้องกันอัคคีภัยจากงานเชื่อม ตัด หรือใช้ความร้อน (Hot Work)',
          content: 'การทำงานที่มีการใช้ความร้อน เปลวไฟ ประกายไฟ หรือการเชื่อมตัดโลหะ นายจ้างต้องจัดให้มีการตรวจสอบและเคลื่อนย้ายสารไวไฟ วัตถุติดไฟ หรือสารเคมีออกจากบริเวณปฏิบัติงานในระยะปลอดภัย (อย่างน้อย ๑๑ เมตร) หรือจัดให้มีวัสดุป้องกันสะเก็ดไฟที่ได้มาตรฐาน',
          practicalApplication: 'เคลียร์พื้นที่ 11 เมตร คลุมผ้า Fire Blanket และปิดฝาท่อระบายน้ำ',
        ),
        PtwStatutoryArticle(
          articleNumber: 'หมวด ๒ ข้อ ๑๕',
          title: 'การจัดเตรียมเครื่องดับเพลิงและผู้เฝ้าระวังไฟ (Fire Watcher)',
          content: 'ต้องจัดให้มีเครื่องดับเพลิงแบบยกหิ้วชนิดที่เหมาะสมกับประเภทเชื้อเพลิงในสภาพพร้อมใช้งานวางไว้ใกล้จุดปฏิบัติงาน และจัดให้มีผู้เฝ้าระวังไฟประจำจุดเพื่อคอยเฝ้าระวังตลอดระยะเวลาปฏิบัติงาน',
          practicalApplication: 'ระบุชื่อผู้เฝ้าระวังไฟและหมายเลขถังดับเพลิงที่ผ่านการตรวจสอบในใบ PTW',
        ),
        PtwStatutoryArticle(
          articleNumber: 'หมวด ๒ ข้อ ๑๖',
          title: 'การตรวจสอบความปลอดภัยหลังเลิกงานไม่น้อยกว่า 30 นาที',
          content: 'เมื่อเสร็จสิ้นการทำงานที่ก่อให้เกิดความร้อนหรือประกายไฟ ต้องจัดให้ผู้เฝ้าระวังไฟหรือผู้มีหน้าที่รับผิดชอบ ตรวจตราพื้นที่ปฏิบัติงานและบริเวณโดยรอบอย่างต่อเนื่องเป็นเวลาไม่น้อยกว่าสามสิบนาที เพื่อป้องกันการคุขึ้นใหม่ของไฟ',
          practicalApplication: 'ใช้ตัวนับเวลา 30 นาที (Fire Watch Timer) และตรวจสอบความเย็นของพื้นที่ก่อนลงนามปิดงาน',
        ),
      ],
      mandatoryChecklistHighlights: [
        'เคลื่อนย้ายหรือคลุมวัสดุติดไฟในรัศมีอย่างน้อย 11 เมตร (35 ฟุต)',
        'ปิดฝาท่อระบายน้ำและช่องเปิดพื้นป้องกันสะเก็ดไฟตกลงไป',
        'ติดตั้งผ้ากันสะเก็ดไฟ (Fire Blanket) รอบจุดเชื่อมตัด',
        'จัดวางเครื่องดับเพลิงชนิดพร้อมใช้งานในระยะไม่เกิน 10 เมตร',
        'เฝ้าระวังไฟและตรวจความปลอดภัยหลังเสร็จงานต่อเนื่องไม่น้อยกว่า 30 นาที',
      ],
    ),

    // 4. กฎกระทรวงไฟฟ้า ๒๕๕๘
    PtwLegalGazetteItem(
      lawId: 'LAW-ELECTRICAL-SAFETY-2558',
      titleTh: 'กฎกระทรวง กำหนดมาตรฐานในการบริหาร จัดการ และดำเนินการด้านความปลอดภัย อาชีวอนามัย และสภาพแวดล้อมในการทำงานเกี่ยวกับไฟฟ้า พ.ศ. ๒๕๕๘',
      titleEn: 'Ministerial Regulation on Electrical Safety B.E. 2558 (2015)',
      gazetteBookVolume: 'เล่ม ๑๓๒ ตอนที่ ๑๑๓ ก หน้า ๑',
      announcementDate: '๓๐ พฤศจิกายน ๒๕๕๘',
      effectiveDate: '๒๘ กุมภาพันธ์ ๒๕๕๙',
      primaryRiskType: HighRiskType.electricalLoto,
      category: 'MINISTERIAL_REGULATION',
      summaryTh: 'กำหนดมาตรฐานความปลอดภัยในการปฏิบัติงานเกี่ยวกับระบบไฟฟ้า การตัดแยกระบบไฟฟ้า Lockout / Tagout (LOTO) การทดสอบพลังงานตกค้างเป็นศูนย์ (Zero Energy Verification) และการใส่อุปกรณ์คุ้มครองความปลอดภัยส่วนบุคคล',
      icon: Icons.bolt_rounded,
      themeColor: Color(0xFFEAB308),
      keyArticles: [
        PtwStatutoryArticle(
          articleNumber: 'หมวด ๒ ข้อ ๗ & ๘',
          title: 'การตัดกระแสไฟฟ้าและการใส่กุญแจล็อก (Lockout / Tagout)',
          content: 'การซ่อมแซม บำรุงรักษา หรือติดตั้งระบบไฟฟ้า นายจ้างต้องจัดให้มีการปลดวงจรไฟฟ้า ตัดแยกแหล่งจ่ายพลังงาน พร้อมทั้งใส่กุญแจล็อก (Lockout) และแขวนป้ายเตือนอันตราย (Tagout) ไว้ที่อุปกรณ์ตัดวงจร',
          practicalApplication: 'บันทึกจุดตัดแยก รหัสตู้เบรกเกอร์ และหมายเลขแม่กุญแจ LOTO ทุกจุดในระบบ PTW',
        ),
        PtwStatutoryArticle(
          articleNumber: 'หมวด ๒ ข้อ ๙',
          title: 'การตรวจสอบและทดสอบกระแสไฟฟ้าตกค้าง (Zero Energy Verification)',
          content: 'ก่อนเริ่มปฏิบัติงาน นายจ้างต้องจัดให้มีผู้ควบคุมงานหรือช่างไฟฟ้าที่มีคุณสมบัติ ตรวจสอบและทดสอบด้วยเครื่องมือวัดว่าไม่มีกระแสไฟฟ้าหรือแรงดันไฟฟ้าตกค้างอยู่ในวงจร',
          practicalApplication: 'ใช้โวลต์มิเตอร์วัดแรงดัน 0V และลงนามรับรอง Zero Energy ก่อนเปิดงาน',
        ),
        PtwStatutoryArticle(
          articleNumber: 'หมวด ๔ ข้อ ๒๓',
          title: 'อุปกรณ์คุ้มครองความปลอดภัยส่วนบุคคลด้านไฟฟ้า (Electrical PPE)',
          content: 'นายจ้างต้องจัดให้ลูกจ้างสวมใส่อุปกรณ์คุ้มครองความปลอดภัยส่วนบุคคลที่มีคุณสมบัติทนแรงดันไฟฟ้า เช่น ถุงมือยางกันไฟฟ้า รองเท้าพื้นฉนวนไฟฟ้า แผ่นฉนวนกันไฟฟ้า และกระบังหน้าป้องกันการระเบิดจากประกายไฟ (Arc Flash Shield)',
          practicalApplication: 'ระบุประเภทชั้นพิกัดแรงดันไฟฟ้าของถุงมือและรองเท้าฉนวนในใบอนุญาต',
        ),
      ],
      mandatoryChecklistHighlights: [
        'ปลดสับสวิตช์ตัดวงจรไฟฟ้าแหล่งจ่ายพลังงานครบทุกจุด',
        'คล้องกุญแจนิรภัย Safety Padlock และติดป้ายเตือนอันตราย LOTO Tag',
        'ทดสอบแรงดันไฟฟ้าตกค้างด้วยเครื่องวัด (Zero Energy Test = 0V)',
        'สวมใส่ PPE ฉนวนไฟฟ้า: ถุงมือยางกันไฟ, รองเท้าฉนวน, Arc Flash Shield',
        'ปลดล็อกคืนสภาพ (De-isolation) อย่างเป็นระบบเมื่อปิดงานเสร็จสิ้น',
      ],
    ),

    // 5. กฎกระทรวงงานบนที่สูงและงานดินขุด ๒๕๖๔
    PtwLegalGazetteItem(
      lawId: 'LAW-HEIGHT-EXCAVATION-2564',
      titleTh: 'กฎกระทรวง กำหนดมาตรฐานในการบริหาร จัดการ และดำเนินการด้านความปลอดภัย อาชีวอนามัย และสภาพแวดล้อมในการทำงานเกี่ยวกับนั่งร้าน งานบนที่สูง และงานดินขุด พ.ศ. ๒๕๖๔',
      titleEn: 'Ministerial Regulation on Safety in Scaffolding, Working at Height, and Excavation B.E. 2564 (2021)',
      gazetteBookVolume: 'เล่ม ๑๓๘ ตอนที่ ๑๕ ก หน้า ๑',
      announcementDate: '๒ มีนาคม ๒๕๖๔',
      effectiveDate: '๓๑ พฤษภาคม ๒๕๖๔',
      primaryRiskType: HighRiskType.workingAtHeight,
      category: 'MINISTERIAL_REGULATION',
      summaryTh: 'ควบคุมการทำงานบนที่สูงตั้งแต่ 2 เมตรขึ้นไป การใช้เข็มขัดนิรภัยแบบเต็มตัว (Full Body Harness) จุดยึดเหนี่ยว Lifeline ทนแรงดึง 22.2 kN การตรวจสอบนั่งร้านมีป้าย Scafftag และงานขุดดินลึกเกิน 1.5 เมตรต้องมีค้ำยัน Shoring',
      icon: Icons.height_rounded,
      themeColor: Color(0xFF0284C7),
      keyArticles: [
        PtwStatutoryArticle(
          articleNumber: 'หมวด ๒ ข้อ ๑๗-๒๐',
          title: 'การทำงานบนที่สูงตั้งแต่ 2 เมตรขึ้นไปและการป้องกันการตก',
          content: 'การทำงานในที่ที่มีความสูงตั้งแต่ ๒ เมตรขึ้นไปจากระดับพื้นดินหรือพื้นอาคาร นายจ้างต้องจัดให้มีราวกั้นตก ตาข่ายนิรภัย หรือจัดให้ลูกจ้างสวมใส่เข็มขัดนิรภัยแบบเต็มตัว (Full Body Harness) พร้อมสายช่วยชีวิต (Lanyard) ที่มีอุปกรณ์ดูดซับแรงกระแทก (Shock Absorber)',
          practicalApplication: 'งานสูงเกิน 2 เมตรต้องขอ PTW ตรวจสอบจุดยึดเหนี่ยว Lifeline และสวมใส่ Harness 100%',
        ),
        PtwStatutoryArticle(
          articleNumber: 'หมวด ๒ ข้อ ๒๑',
          title: 'มาตรฐานจุดยึดเหนี่ยว (Anchor Point) และ Lifeline',
          content: 'จุดยึดเหนี่ยวหรือสายช่วยชีวิตต้องมีความมั่นคงแข็งแรง สามารถรับน้ำหนักหรือแรงดึงกระชากได้ไม่น้อยกว่า ๒๒.๒ กิโลนิวตัน (๕,๐๐๐ ปอนด์) ต่อผู้ปฏิบัติงานหนึ่งคน',
          practicalApplication: 'วิศวกรหรือ จป. ต้องตรวจสอบความแข็งแรงของ Anchor Point ก่อนอนุญาต',
        ),
        PtwStatutoryArticle(
          articleNumber: 'หมวด ๑ ข้อ ๕-๑๑',
          title: 'การตรวจสอบและรับรองความปลอดภัยนั่งร้าน (Scaffolding Tag)',
          content: 'นั่งร้านต้องได้รับการประกอบ ติดตั้ง และตรวจสอบโดยผู้มีความรู้ความชำนาญ มีป้ายแสดงสถานะความปลอดภัย (Scafftag เขียว/แดง) มีแผ่นปูทางเดินเต็ม ราวกันตก และแผ่นกันของตก (Toeboard)',
          practicalApplication: 'ตรวจสอบป้าย Scafftag เขียวก่อนขึ้นทำงานบนนั่งร้านทุกครั้ง',
        ),
        PtwStatutoryArticle(
          articleNumber: 'หมวด ๓ ข้อ ๒๖-๓๐',
          title: 'งานขุดเจาะดินลึกตั้งแต่ 1.5 เมตรขึ้นไป (Excavation Safety)',
          content: 'การขุดดินที่มีความลึกตั้งแต่ ๑.๕๐ เมตรขึ้นไป นายจ้างต้องจัดให้มีระบบค้ำยันดิน (Shoring) หรือทำความลาดเอียงของตลิ่งดิน (Sloping) เพื่อป้องกันดินพังทลาย และตรวจสอบแนวสาธารณูปโภคใต้ดินก่อนเริ่มขุด',
          practicalApplication: 'งานขุดลึก > 1.5m ต้องระบุแบบค้ำยัน Shoring และสำรวจแนวท่อใต้ดินในใบ PTW',
        ),
      ],
      mandatoryChecklistHighlights: [
        'สวมใส่ Full Body Harness พร้อม Double Lanyard & Shock Absorber สำหรับงานสูง > 2 เมตร',
        'จุดยึดเหนี่ยว Anchor Point / Lifeline แข็งแรงรับแรงดึง >= 22.2 kN (5,000 lbs)',
        'ตรวจสอบนั่งร้านมีป้ายเขียว (Scafftag Green), ปูพื้นเต็ม, ราวกั้นตก, แผ่นกันตก',
        'กั้นแนวเขตเตือนอันตรายด้านล่าง (Barricade Drop Zone) และผูกเชือกคล้องเครื่องมือ',
        'งานขุดดินลึก > 1.5 เมตร มีการติดตั้งค้ำยัน (Shoring) หรือลาดเอียง (Sloping) ป้องกันดินถล่ม',
      ],
    ),
  ];

  /// Find regulations matching keyword search across titles, summaries, and articles
  static List<PtwLegalGazetteItem> search(String query) {
    if (query.trim().isEmpty) return regulations;
    final q = query.trim().toLowerCase();
    return regulations.where((law) {
      final matchesTitle = law.titleTh.toLowerCase().contains(q) || law.titleEn.toLowerCase().contains(q);
      final matchesSummary = law.summaryTh.toLowerCase().contains(q);
      final matchesLawId = law.lawId.toLowerCase().contains(q);
      final matchesArticle = law.keyArticles.any(
        (a) =>
            a.articleNumber.toLowerCase().contains(q) ||
            a.title.toLowerCase().contains(q) ||
            a.content.toLowerCase().contains(q) ||
            a.practicalApplication.toLowerCase().contains(q),
      );
      return matchesTitle || matchesSummary || matchesLawId || matchesArticle;
    }).toList();
  }
}
