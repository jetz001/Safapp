/// Model representing a Royal Thai Government Gazette legal reference document
/// for the Environmental Monitoring Module.
class EnvironmentalGazetteItem {
  final String lawId;
  final String titleTh;
  final String titleEn;
  final String category;
  final String governingAuthority;
  final String gazetteVolume;
  final String gazettePart;
  final String gazettePage;
  final String publishedDate;
  final String effectiveDate;
  final String summaryTh;
  final List<String> keyArticles;
  final List<String> mandatoryForms;
  final String penaltySummary;
  final String? pdfAssetPath;

  const EnvironmentalGazetteItem({
    required this.lawId,
    required this.titleTh,
    required this.titleEn,
    required this.category,
    required this.governingAuthority,
    required this.gazetteVolume,
    required this.gazettePart,
    required this.gazettePage,
    required this.publishedDate,
    required this.effectiveDate,
    required this.summaryTh,
    required this.keyArticles,
    required this.mandatoryForms,
    required this.penaltySummary,
    this.pdfAssetPath,
  });
}

/// Master Data Catalog containing full statutory reference metadata
/// for Thai Environmental Safety Legislation.
class EnvironmentalGazetteData {
  EnvironmentalGazetteData._();

  static const List<EnvironmentalGazetteItem> gazetteList = [
    // 1. พ.ร.บ. ความปลอดภัยฯ ๒๕๕๔
    EnvironmentalGazetteItem(
      lawId: 'LAW-OSH-2554',
      titleTh: 'พระราชบัญญัติความปลอดภัย อาชีวอนามัย และสภาพแวดล้อมในการทำงาน พ.ศ. ๒๕๕๔',
      titleEn: 'Occupational Safety, Health and Environment Act B.E. 2554 (2011)',
      category: 'PRIMARY_ACT',
      governingAuthority: 'กรมสวัสดิการและคุ้มครองแรงงาน (DLPW), กระทรวงแรงงาน',
      gazetteVolume: 'เล่ม ๑๒๘',
      gazettePart: 'ตอนที่ ๔ ก',
      gazettePage: 'หน้า ๑-๒๒',
      publishedDate: '๑๗ มกราคม ๒๕๕๔',
      effectiveDate: '๑๖ กรกฎาคม ๒๕๕๔ (พ้น ๑๘๐ วันนับแต่วันประกาศ)',
      summaryTh:
          'กฎหมายแม่บทกำหนดให้นายจ้างมีหน้าที่บริหาร จัดการ และดำเนินการด้านความปลอดภัย อาชีวอนามัย และสภาพแวดล้อมในการทำงานตามมาตรฐานที่กำหนดในกฎกระทรวง (ม.๘) การขึ้นทะเบียนบุคคลธรรมดา (ม.๙) และใบอนุญาตสำหรับนิติบุคคลผู้ให้บริการตรวจวัด (ม.๑๑) การปิดประกาศผลตรวจวัดภายใน ๑๕ วันและส่งรายงานต่อกรมฯ ภายใน ๓๐ วัน (ม.๑๕) พร้อมกำหนดบทลงโทษทางอาญาและปรับรายวัน (ม.๕๓, ๕๕, ๕๖)',
      keyArticles: [
        'มาตรา ๘: นายจ้างต้องบริหารจัดการด้านความปลอดภัย อาชีวอนามัย และสภาพแวดล้อมในการทำงานให้เป็นไปตามมาตรฐานกฎกระทรวง',
        'มาตรา ๙: ผู้ให้บริการตรวจวัด ทดสอบ รับรอง ประเมินความเสี่ยง ประเภทบุคคลธรรมดา ต้องขึ้นทะเบียน (เลขทะเบียน นบ.)',
        'มาตรา ๑๑: นิติบุคคลผู้ให้บริการตรวจวัด ทดสอบ รับรอง ประเมินสภาพแวดล้อม ต้องได้รับใบอนุญาตจากอธิบดี (เลขที่ใบอนุญาต บ.)',
        'มาตรา ๑๕: นายจ้างต้องปิดประกาศผลการตรวจวัด ณ สถานประกอบการภายใน ๑๕ วัน และส่งรายงานให้อธิบดีภายใน ๓๐ วัน',
        'มาตรา ๓๒: พนักงานตรวจความปลอดภัยมีอำนาจสั่งให้นายจ้างจัดทำแผนการปรับปรุงสภาพแวดล้อม (CAPA)',
        'มาตรา ๕๓: ฝ่าฝืน ม.๘ มีโทษจำคุกไม่เกิน ๑ ปี หรือปรับไม่เกิน ๔๐๐,๐๐๐ บาท หรือทั้งจำทั้งปรับ',
        'มาตรา ๕๕: ฝ่าฝืน ม.๑๕ ไม่ปิดประกาศหรือไม่ส่งรายงาน ปรับไม่เกิน ๕๐,๐๐๐ บาท',
        'มาตรา ๕๖: จ้างหรือให้บริการตรวจวัดโดยไม่มีทะเบียน/ใบอนุญาต ม.๙/๑๑ มีโทษจำคุกไม่เกิน ๖ เดือน ปรับไม่เกิน ๒๐๐,๐๐๐ บาท',
      ],
      mandatoryForms: [
        'แบบขึ้นทะเบียนบุคคล ม.๙ (สปร.๑)',
        'แบบขอรับใบอนุญาต ม.๑๑ (สนร.๑)',
        'แบบรายงานผลการตรวจวัดและวิเคราะห์สภาวะการทำงาน',
      ],
      penaltySummary: 'จำคุกสูงสุด ๑ ปี หรือปรับสูงสุด ๔๐๐,๐๐๐ บาท หรือทั้งจำทั้งปรับ (ม.๕๓, ๕๕, ๕๖)',
    ),

    // 2. กฎกระทรวงความร้อน แสงสว่าง และเสียง ๒๕๕๙
    EnvironmentalGazetteItem(
      lawId: 'LAW-ENV-REG-2559',
      titleTh:
          'กฎกระทรวง กำหนดมาตรฐานในการบริหาร จัดการ และดำเนินการด้านความปลอดภัย อาชีวอนามัย และสภาพแวดล้อมในการทำงานเกี่ยวกับความร้อน แสงสว่าง และเสียง พ.ศ. ๒๕๕๙',
      titleEn:
          'Ministerial Regulation on the Standards for Administration, Management and Operation of Safety, Occupational Health and Workplace Environment in relation to Heat, Light and Noise B.E. 2559 (2016)',
      category: 'MINISTERIAL_REGULATION',
      governingAuthority: 'กระทรวงแรงงาน / กรมสวัสดิการและคุ้มครองแรงงาน',
      gazetteVolume: 'เล่ม ๑๓๓',
      gazettePart: 'ตอนที่ ๙๑ ก',
      gazettePage: 'หน้า ๔๘-๕๔',
      publishedDate: '๑๗ ตุลาคม ๒๕๕๙',
      effectiveDate: '๑๘ ตุลาคม ๒๕๕๙ (วันถัดจากวันประกาศ)',
      summaryTh:
          'กำหนดมาตรฐานระดับความร้อน WBGT ไม่เกิน ๓๔/๓๒/๓๐ °C ตามลักษณะงานเบา/ปานกลาง/หนัก ควบคุมความเข้มแสงสว่างไม่ต่ำกว่าเกณฑ์มาตรฐานอธิบดีประกาศ ควบคุมระดับเสียงเฉลี่ย 8 ชม. ไม่เกิน 86 dBA เสียงต่อเนื่องสูงสุดไม่เกิน 115 dBA เสียงกระแทกไม่เกิน 140 dB บังคับจัดทำโครงการอนุรักษ์การได้ยินเมื่อเสียง >= 85 dBA ตรวจวัดอย่างน้อยปีละ ๑ ครั้ง และส่งรายงานภายใน ๓๐ วัน พร้อมเก็บรักษาไม่น้อยกว่า ๕ ปี',
      keyArticles: [
        'ข้อ ๒-๓: มาตรฐานระดับความร้อน WBGT ในสถานประกอบการ: งานเบา <= 34°C, งานปานกลาง <= 32°C, งานหนัก <= 30°C',
        'ข้อ ๔-๖: มาตรฐานความเข้มของแสงสว่าง ณ จุดทำงานและบริเวณรอบข้าง ป้องกันแสงจ้าและเงาสะท้อน',
        'ข้อ ๗-๘: มาตรฐานระดับเสียง: เสียงเฉลี่ย 8 ชม. ไม่เกิน 86 dBA, เสียงต่อเนื่องสูงสุด < 115 dBA, เสียงกระทบ/กระแทก <= 140 dB',
        'ข้อ ๑๐: บริเวณที่มีเสียงเกินมาตรฐาน ต้องติดป้ายเตือนบังคับสวมใส่อุปกรณ์คุ้มครองความปลอดภัยส่วนบุคคล (PPE)',
        'ข้อ ๑๑: สถานประกอบการที่มีระดับเสียงเฉลี่ย 8 ชม. ตั้งแต่ 85 dBA ขึ้นไป ต้องจัดทำโครงการอนุรักษ์การได้ยิน (HCP)',
        'ข้อ ๑๒-๑๓: นายจ้างต้องจัดหา PPE ลดเสียง แว่นตากรองแสง ชุดกันร้อนที่ได้มาตรฐาน มอก./สากล โดยไม่คิดมูลค่า',
        'ข้อ ๑๔: นายจ้างต้องจัดให้มีการตรวจวัดและประเมินสภาวะการทำงานเกี่ยวกับความร้อน แสงสว่าง หรือเสียง อย่างน้อยปีละ ๑ ครั้ง',
        'ข้อ ๑๕: จัดทำรายงานผลตามแบบอธิบดีกำหนด ส่งสำเนารายงานต่อกรมฯ ภายใน ๓๐ วัน และเก็บรักษาไว้ไม่น้อยกว่า ๕ ปี',
      ],
      mandatoryForms: [
        'แบบรายงานผลการตรวจวัดและวิเคราะห์สภาวะการทำงานเกี่ยวกับความร้อน แสงสว่าง หรือเสียง (สสค.)',
        'เอกสารโครงการอนุรักษ์การได้ยิน (Hearing Conservation Program Plan)',
      ],
      penaltySummary: 'ตามมาตรา ๕๓ แห่ง พ.ร.บ. ความปลอดภัยฯ ๒๕๕๔ จำคุกไม่เกิน ๑ ปี หรือปรับไม่เกิน ๔๐๐,๐๐๐ บาท',
    ),

    // 3. ประกาศกรมฯ เรื่อง มาตรฐานความเข้มของแสงสว่าง ๒๕๖๑
    EnvironmentalGazetteItem(
      lawId: 'LAW-LIGHT-NOTIF-2561',
      titleTh: 'ประกาศกรมสวัสดิการและคุ้มครองแรงงาน เรื่อง มาตรฐานความเข้มของแสงสว่าง พ.ศ. ๒๕๖๑',
      titleEn: 'DLPW Notification on Standards for Lighting Intensity B.E. 2561 (2018)',
      category: 'DLPW_NOTIFICATION',
      governingAuthority: 'กรมสวัสดิการและคุ้มครองแรงงาน',
      gazetteVolume: 'เล่ม ๑๓๕',
      gazettePart: 'ตอนพิเศษ ๔๓ ง',
      gazettePage: 'หน้า ๑-๙',
      publishedDate: '๒๗ กุมภาพันธ์ ๒๕๖๑',
      effectiveDate: '๒๘ กุมภาพันธ์ ๒๕๖๑',
      summaryTh:
          'กำหนดมาตรฐานความเข้มแสงสว่างต่ำสุด (Minimum Lux) แยกตาม 3 หมวดหมู่หลัก: หมวด ๑ พื้นที่ทั่วไปและทางสัญจร (๒๐-๒๐๐ Lux), หมวด ๒ จุดทำงานสายตาเฉพาะจุด (๑๐๐-๑,๐๐๐ Lux) ตั้งแต่งานหยาบถึงงานละเอียดพิเศษ, หมวด ๓ บริเวณรอบจุดทำงาน (ไม่น้อยกว่า ๑ ใน ๓ ในรัศมี ๐.๕ เมตร และไม่น้อยกว่า ๑ ใน ๕ ในบริเวณถัดไป)',
      keyArticles: [
        'หมวด ๑: มาตรฐานความเข้มของแสงสว่างบริเวณพื้นที่ทั่วไปและทางสัญจร (ทางเดินภายนอก 20 Lux, ทางเดินในอาคาร 50 Lux, ทางสัญจรผลิต 100 Lux, คลังสินค้า 100-200 Lux)',
        'หมวด ๒: มาตรฐานความเข้มของแสงสว่างบริเวณที่ลูกจ้างทำงานเฉพาะจุด (งานหยาบ 100-200 Lux, งานปานกลาง/สำนักงาน 300 Lux, งานละเอียด 400 Lux, ตรวจสอบ QC 600 Lux, งานละเอียดพิเศษ 1,000 Lux)',
        'หมวด ๓: มาตรฐานความเข้มแสงสว่างบริเวณรอบจุดทำงาน (รัศมี ๐.๕ เมตร ไม่น้อยกว่า ๑/๓ ของจุดทำงาน, บริเวณถัดออกไป ไม่น้อยกว่า ๑/๕)',
      ],
      mandatoryForms: [
        'ตารางบันทึกผลการตรวจวัดความเข้มแสงสว่างรายจุด (Lighting Measurement Data Sheet)',
      ],
      penaltySummary: 'ปรับปรุงระบบไฟฟ้าแสงสว่างตามคำสั่งพนักงานตรวจความปลอดภัย (ม.๓๒) มิฉะนั้นมีโทษตาม ม.๕๓',
    ),

    // 4. ประกาศกรมฯ เรื่อง มาตรฐานระดับเสียง ๒๕๖๑
    EnvironmentalGazetteItem(
      lawId: 'LAW-NOISE-NOTIF-2561',
      titleTh:
          'ประกาศกรมสวัสดิการและคุ้มครองแรงงาน เรื่อง มาตรฐานระดับเสียงที่ยอมให้ลูกจ้างได้รับเฉลี่ยตลอดระยะเวลาการทำงานในแต่ละวัน พ.ศ. ๒๕๖๑',
      titleEn:
          'DLPW Notification on Noise Standards Permissible for Employees as Daily Time-Weighted Average B.E. 2561 (2018)',
      category: 'DLPW_NOTIFICATION',
      governingAuthority: 'กรมสวัสดิการและคุ้มครองแรงงาน',
      gazetteVolume: 'เล่ม ๑๓๕',
      gazettePart: 'ตอนพิเศษ ๒๗ ง',
      gazettePage: 'หน้า ๑๔-๑๕',
      publishedDate: '๖ กุมภาพันธ์ ๒๕๖๑',
      effectiveDate: '๗ กุมภาพันธ์ ๒๕๖๑',
      summaryTh:
          'กำหนดมาตรฐานระดับเสียงเฉลี่ยตลอดระยะเวลาการทำงาน ๘ ชั่วโมงต่อวัน ไม่เกิน 86 dBA พร้อมสูตรและตารางคำนวณระยะเวลาสัมผัสเสียงที่ยอมให้ (Exchange Rate 3 dB: T = 8 / 2^((L-86)/3)) เช่น 89 dBA ได้ไม่เกิน 4 ชม., 92 dBA ไม่เกิน 2 ชม., 95 dBA ไม่เกิน 1 ชม., และระดับเสียงสูงสุดต่อเนื่องไม่เกิน 115 dBA',
      keyArticles: [
        'ข้อ ๑: ระดับเสียงที่ยอมให้ลูกจ้างได้รับเฉลี่ยตลอดเวลาการทำงาน ๘ ชั่วโมง ต้องไม่เกิน ๘๖ เดซิเบลเอ (86 dBA)',
        'ข้อ ๒: กรณีเวลาทำงานแตกต่างจาก ๘ ชม. ให้คำนวณเทียบเท่าตามสูตรอัตราแลกเปลี่ยน 3 dB (3 dB Exchange Rate)',
        'ข้อ ๓: ตารางเทียบเวลาสัมผัสเสียง: 80 dBA (32 ชม.), 83 dBA (16 ชม.), 86 dBA (8 ชม.), 89 dBA (4 ชม.), 92 dBA (2 ชม.), 95 dBA (1 ชม.), 98 dBA (30 นาที), 101 dBA (15 นาที), 115 dBA (28.1 วินาที)',
      ],
      mandatoryForms: [
        'ตารางบันทึกผลการตรวจวัดระดับเสียงและคำนวณ Dose / Leq 8-hr (Noise Data Sheet)',
      ],
      penaltySummary: 'ปรับปรุงแหล่งกำเนิดเสียงหรือกั้นห้องแยกตาม ม.๓๒ มิฉะนั้นมีโทษตาม ม.๕๓',
    ),

    // 5. ประกาศกรมฯ เรื่อง การคำนวณและประเมินระดับความร้อน WBGT ๒๕๖๓
    EnvironmentalGazetteItem(
      lawId: 'LAW-HEAT-NOTIF-2563',
      titleTh: 'ประกาศกรมสวัสดิการและคุ้มครองแรงงาน เรื่อง หลักเกณฑ์และวิธีการตรวจวัดและคำนวณระดับความร้อน พ.ศ. ๒๕๖๓',
      titleEn:
          'DLPW Notification on Criteria and Methods for Measurement and Calculation of Heat Levels (WBGT) B.E. 2563 (2020)',
      category: 'DLPW_NOTIFICATION',
      governingAuthority: 'กรมสวัสดิการและคุ้มครองแรงงาน',
      gazetteVolume: 'เล่ม ๑๓๗',
      gazettePart: 'ตอนพิเศษ ๒๓๘ ง',
      gazettePage: 'หน้า ๑๙-๒๒',
      publishedDate: '๙ ตุลาคม ๒๕๖๓',
      effectiveDate: '๑๐ ตุลาคม ๒๕๖๓',
      summaryTh:
          'กำหนดหลักเกณฑ์การตรวจวัดอุณหภูมิกระเปาะเปียกธรรมชาติ (NWB), อุณหภูมิโกลบ (GT ขนาด 150 มม.), อุณหภูมิกระเปาะแห้ง (DB) พร้อมสูตรคำนวณ WBGT ในร่ม (0.7 NWB + 0.3 GT) และกลางแจ้ง (0.7 NWB + 0.2 GT + 0.1 DB) และเกณฑ์การประเมินอัตราการเผาผลาญพลังงานเพื่อจำแนกลักษณะงานเบา/ปานกลาง/หนัก',
      keyArticles: [
        'ข้อ ๑-๒: คำนิยามและคุณลักษณะเครื่องมือวัดอุณหภูมิ NWB, GT (ลูกทรงกลมทองแดงรมดำ 150 มม.), และ DB',
        'ข้อ ๓: สูตรคำนวณความร้อน WBGT ในร่มหรือไม่มีแสงแดด: WBGT = 0.7 NWB + 0.3 GT',
        'ข้อ ๔: สูตรคำนวณความร้อน WBGT กลางแจ้งหรือมีแสงแดดส่องถึง: WBGT = 0.7 NWB + 0.2 GT + 0.1 DB',
        'ข้อ ๕: การจำแนกภาระงานตามอัตราการเผาผลาญ: งานเบา (<= 200 kcal/hr), งานปานกลาง (200-350 kcal/hr), งานหนัก (> 350 kcal/hr)',
        'ข้อ ๖: การคำนวณค่าเฉลี่ยถ่วงน้ำหนักตามเวลา (Time-Weighted Average WBGT & Metabolic Rate) สำหรับงานที่มีหลายจุด',
      ],
      mandatoryForms: [
        'ตารางบันทึกผลการตรวจวัดระดับความร้อน WBGT และวิเคราะห์ภาระงาน (Heat Stress Data Sheet)',
      ],
      penaltySummary: 'ปรับปรุงการระบายอากาศ จัดหาน้ำดื่มและพื้นที่พักผ่อนตาม ม.๓๒ มิฉะนั้นมีโทษตาม ม.๕๓',
    ),

    // 6. ประกาศกรมฯ เรื่อง แบบรายงานผลการตรวจวัดและวิเคราะห์สภาวะการทำงาน ๒๕๖๓
    EnvironmentalGazetteItem(
      lawId: 'LAW-REPORT-NOTIF-2563',
      titleTh:
          'ประกาศกรมสวัสดิการและคุ้มครองแรงงาน เรื่อง แบบรายงานผลการตรวจวัดและวิเคราะห์สภาวะการทำงานเกี่ยวกับความร้อน แสงสว่าง หรือเสียง พ.ศ. ๒๕๖๓',
      titleEn:
          'DLPW Notification on the Official Reporting Form for Measurement and Analysis of Workplace Environment regarding Heat, Light, or Noise B.E. 2563 (2020)',
      category: 'DLPW_NOTIFICATION',
      governingAuthority: 'กรมสวัสดิการและคุ้มครองแรงงาน',
      gazetteVolume: 'เล่ม ๑๓๗',
      gazettePart: 'ตอนพิเศษ ๒๘๐ ง',
      gazettePage: 'หน้า ๑๑-๒๔',
      publishedDate: '๑ ธันวาคม ๒๕๖๓',
      effectiveDate: '๒ ธันวาคม ๒๕๖๓',
      summaryTh:
          'กำหนดแบบรายงานผลการตรวจวัดทางการ (สสค.) ครบทั้ง 6 ส่วน: ข้อมูลสถานประกอบการ, ข้อมูลผู้ตรวจวัดและรับรอง ม.๙/๑๑, บันทึกเครื่องมือวัดและใบสอบเทียบ ISO/IEC 17025, ตารางผลตรวจวัดแสง เสียง ความร้อน, สรุปผลและแผน CAPA, และลายมือชื่อรับรองตามกฎหมาย',
      keyArticles: [
        'ส่วนที่ ๑: ข้อมูลทั่วไปของสถานประกอบกิจการ (ชื่อ, เลข 13 หลัก, ประเภทกิจการ TSIC, ที่ตั้ง, จำนวนลูกจ้าง)',
        'ส่วนที่ ๒: ข้อมูลผู้ตรวจวัดและผู้รับรองผล (บุคคลธรรมดา ม.๙ หรือ นิติบุคคล ม.๑๑ พร้อมเลขทะเบียน)',
        'ส่วนที่ ๓: รายละเอียดเครื่องมือวัดและใบรับรองการสอบเทียบ (Calibration Certificate มีอายุไม่เกิน ๑ ปี)',
        'ส่วนที่ ๔: ตารางบันทึกผลการตรวจวัดรายจุด (แสงสว่าง Lux, เสียง Leq 8-hr/Peak, ความร้อน WBGT)',
        'ส่วนที่ ๕: สรุปผลการประเมินและการจัดทำแผนการปรับปรุงแก้ไข (CAPA Plan)',
        'ส่วนที่ ๖: การลงลายมือชื่อรับรองของผู้ตรวจวัด ผู้รับรองรายงาน และนายจ้าง/ผู้มีอำนาจลงนาม',
      ],
      mandatoryForms: [
        'แบบรายงานผลการตรวจวัดและวิเคราะห์สภาวะการทำงาน (แบบ สสค.) ฉบับสมบูรณ์',
      ],
      penaltySummary: 'การยื่นรายงานเท็จหรือไม่ยื่นภายใน ๓๐ วัน มีโทษปรับตาม ม.๕๕ ปรับไม่เกิน ๕๐,๐๐๐ บาท',
    ),
  ];

  /// Find Gazette item by law ID
  static EnvironmentalGazetteItem? findByLawId(String lawId) {
    try {
      return gazetteList.firstWhere((e) => e.lawId == lawId);
    } catch (_) {
      return null;
    }
  }

  /// Search gazette items by keyword
  static List<EnvironmentalGazetteItem> search(String keyword) {
    final q = keyword.trim().toLowerCase();
    if (q.isEmpty) return gazetteList;
    return gazetteList.where((item) {
      return item.lawId.toLowerCase().contains(q) ||
          item.titleTh.toLowerCase().contains(q) ||
          item.titleEn.toLowerCase().contains(q) ||
          item.summaryTh.toLowerCase().contains(q) ||
          item.penaltySummary.toLowerCase().contains(q) ||
          item.keyArticles.any((a) => a.toLowerCase().contains(q));
    }).toList();
  }
}
