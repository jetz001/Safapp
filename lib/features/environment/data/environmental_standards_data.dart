import '../domain/models/environment_standard_model.dart';

/// Master Data Catalog of statutory standards for workplace environmental factors
/// based on Thai Royal Gazette:
/// - Ministerial Regulation on Heat, Light, and Noise B.E. 2559 (2016)
/// - DLPW Notification on Lighting Intensity Standards B.E. 2561 (2018)
/// - DLPW Notification on Noise Exposure Standards B.E. 2561 (2018)
/// - DLPW Notification on Heat & WBGT Calculation B.E. 2563 (2020)
class EnvironmentalStandardsData {
  EnvironmentalStandardsData._();

  static const List<EnvironmentStandardModel> masterStandards = [
    // =========================================================================
    // 1. แสงสว่าง หมวด ๑: บริเวณพื้นที่ทั่วไปและทางสัญจร (Category 1: General Areas)
    // =========================================================================
    EnvironmentStandardModel(
      standardId: 'LIGHT-CAT1-01',
      factorType: EnvironmentFactorType.light,
      categoryCode: 'LIGHT_CAT1',
      categoryNameTh: 'พื้นที่ทั่วไปและทางสัญจร',
      categoryNameEn: 'General Areas & Circulation Paths',
      taskDescription: 'ทางเดินภายนอกอาคาร, ลานจอดรถ, บริเวณถ่ายเทสินค้าภายนอก',
      minLux: 20.0,
      maxLux: 50.0,
      surroundingLuxRatio: 0.333,
      referenceLawTitle: 'ประกาศกรมสวัสดิการและคุ้มครองแรงงาน เรื่อง มาตรฐานความเข้มของแสงสว่าง พ.ศ. ๒๕๖๑',
      referenceArticle: 'หมวด ๑ ข้อ ๑ (๑)',
      notes: 'วัด ณ ระดับพื้นผิวทางเดินภายนอกหรือลานกลางแจ้ง',
      sortOrder: 101,
    ),
    EnvironmentStandardModel(
      standardId: 'LIGHT-CAT1-02',
      factorType: EnvironmentFactorType.light,
      categoryCode: 'LIGHT_CAT1',
      categoryNameTh: 'พื้นที่ทั่วไปและทางสัญจร',
      categoryNameEn: 'General Areas & Circulation Paths',
      taskDescription: 'ทางเดินภายในอาคาร, ทางหนีไฟ, บันได, ลิฟต์, ทางสัญจรหลัก',
      minLux: 50.0,
      maxLux: 100.0,
      surroundingLuxRatio: 0.333,
      referenceLawTitle: 'ประกาศกรมสวัสดิการและคุ้มครองแรงงาน เรื่อง มาตรฐานความเข้มของแสงสว่าง พ.ศ. ๒๕๖๑',
      referenceArticle: 'หมวด ๑ ข้อ ๑ (๒)',
      notes: 'วัด ณ ระดับพื้นผิวทางเดินหรือขั้นบันได',
      sortOrder: 102,
    ),
    EnvironmentStandardModel(
      standardId: 'LIGHT-CAT1-03',
      factorType: EnvironmentFactorType.light,
      categoryCode: 'LIGHT_CAT1',
      categoryNameTh: 'พื้นที่ทั่วไปและทางสัญจร',
      categoryNameEn: 'General Areas & Circulation Paths',
      taskDescription: 'ทางสัญจรในพื้นที่ปฏิบัติงาน, ทางเดินในโรงงานและสายการผลิต',
      minLux: 100.0,
      maxLux: 200.0,
      surroundingLuxRatio: 0.333,
      referenceLawTitle: 'ประกาศกรมสวัสดิการและคุ้มครองแรงงาน เรื่อง มาตรฐานความเข้มของแสงสว่าง พ.ศ. ๒๕๖๑',
      referenceArticle: 'หมวด ๑ ข้อ ๑ (๓)',
      notes: 'วัด ณ ทางเดินที่มีการสัญจรของพนักงานหรือโฟล์คลิฟต์',
      sortOrder: 103,
    ),
    EnvironmentStandardModel(
      standardId: 'LIGHT-CAT1-04',
      factorType: EnvironmentFactorType.light,
      categoryCode: 'LIGHT_CAT1',
      categoryNameTh: 'พื้นที่ทั่วไปและทางสัญจร',
      categoryNameEn: 'General Areas & Circulation Paths',
      taskDescription: 'ห้องน้ำ, ห้องสุขา, ห้องแต่งตัว, ห้องรับประทานอาหาร, ห้องพักผ่อน',
      minLux: 100.0,
      maxLux: 200.0,
      surroundingLuxRatio: 0.333,
      referenceLawTitle: 'ประกาศกรมสวัสดิการและคุ้มครองแรงงาน เรื่อง มาตรฐานความเข้มของแสงสว่าง พ.ศ. ๒๕๖๑',
      referenceArticle: 'หมวด ๑ ข้อ ๑ (๔)',
      notes: 'วัด ณ ระดับพื้นผิว ๐.๗๕-๐.๘๕ เมตรจากพื้น',
      sortOrder: 104,
    ),
    EnvironmentStandardModel(
      standardId: 'LIGHT-CAT1-05',
      factorType: EnvironmentFactorType.light,
      categoryCode: 'LIGHT_CAT1',
      categoryNameTh: 'พื้นที่ทั่วไปและทางสัญจร',
      categoryNameEn: 'General Areas & Circulation Paths',
      taskDescription: 'คลังสินค้าทั่วไป, พื้นที่จัดเก็บสินค้าขนาดใหญ่, โกดังสินค้าแบบเทกอง',
      minLux: 100.0,
      maxLux: 200.0,
      surroundingLuxRatio: 0.333,
      referenceLawTitle: 'ประกาศกรมสวัสดิการและคุ้มครองแรงงาน เรื่อง มาตรฐานความเข้มของแสงสว่าง พ.ศ. ๒๕๖๑',
      referenceArticle: 'หมวด ๑ ข้อ ๑ (๕)',
      notes: 'พื้นที่เก็บของที่ไม่มีการหยิบสินค้าละเอียดต่อเนื่อง',
      sortOrder: 105,
    ),
    EnvironmentStandardModel(
      standardId: 'LIGHT-CAT1-06',
      factorType: EnvironmentFactorType.light,
      categoryCode: 'LIGHT_CAT1',
      categoryNameTh: 'พื้นที่ทั่วไปและทางสัญจร',
      categoryNameEn: 'General Areas & Circulation Paths',
      taskDescription: 'คลังสินค้าที่มีการอ่านฉลากหรือเบิกจ่ายสินค้า, ช่องทางเดินระหว่างชั้นวาง',
      minLux: 200.0,
      maxLux: 300.0,
      surroundingLuxRatio: 0.333,
      referenceLawTitle: 'ประกาศกรมสวัสดิการและคุ้มครองแรงงาน เรื่อง มาตรฐานความเข้มของแสงสว่าง พ.ศ. ๒๕๖๑',
      referenceArticle: 'หมวด ๑ ข้อ ๑ (๖)',
      notes: 'วัด ณ พื้นผิวของชั้นวางสินค้าหรือโต๊ะเบิกจ่าย',
      sortOrder: 106,
    ),

    // =========================================================================
    // 2. แสงสว่าง หมวด ๒: บริเวณที่ลูกจ้างทำงานโดยใช้สายตามองเฉพาะจุด (Category 2: Specific Tasks)
    // =========================================================================
    EnvironmentStandardModel(
      standardId: 'LIGHT-CAT2-01',
      factorType: EnvironmentFactorType.light,
      categoryCode: 'LIGHT_CAT2',
      categoryNameTh: 'จุดทำงานเฉพาะจุด (งานสายตาน้อยมาก)',
      categoryNameEn: 'Very Rough Visual Tasks',
      taskDescription: 'งานที่ใช้สายตาน้อยมาก เช่น งานคัดแยกวัตถุขนาดใหญ่, งานผสมคอนกรีต, งานโหลดวัสดุหยาบ',
      minLux: 100.0,
      maxLux: 150.0,
      surroundingLuxRatio: 0.333,
      referenceLawTitle: 'ประกาศกรมสวัสดิการและคุ้มครองแรงงาน เรื่อง มาตรฐานความเข้มของแสงสว่าง พ.ศ. ๒๕๖๑',
      referenceArticle: 'หมวด ๒ ข้อ ๒ (๑)',
      notes: 'วัด ณ จุดปฏิบัติงานจริง',
      sortOrder: 111,
    ),
    EnvironmentStandardModel(
      standardId: 'LIGHT-CAT2-02',
      factorType: EnvironmentFactorType.light,
      categoryCode: 'LIGHT_CAT2',
      categoryNameTh: 'จุดทำงานเฉพาะจุด (งานสายตาหยาบ)',
      categoryNameEn: 'Rough Visual Tasks',
      taskDescription: 'งานที่ใช้สายตาหยาบ เช่น งานปั๊มชิ้นงานขนาดใหญ่, งานเลื่อยไม้, งานโรงรีดเหล็ก, งานล้างภาชนะ',
      minLux: 200.0,
      maxLux: 300.0,
      surroundingLuxRatio: 0.333,
      referenceLawTitle: 'ประกาศกรมสวัสดิการและคุ้มครองแรงงาน เรื่อง มาตรฐานความเข้มของแสงสว่าง พ.ศ. ๒๕๖๑',
      referenceArticle: 'หมวด ๒ ข้อ ๒ (๒)',
      notes: 'วัด ณ ระนาบการมองเห็นของชิ้นงาน',
      sortOrder: 112,
    ),
    EnvironmentStandardModel(
      standardId: 'LIGHT-CAT2-03',
      factorType: EnvironmentFactorType.light,
      categoryCode: 'LIGHT_CAT2',
      categoryNameTh: 'จุดทำงานเฉพาะจุด (งานสายตาปานกลาง)',
      categoryNameEn: 'Medium Visual Tasks',
      taskDescription: 'งานที่ใช้สายตาปานกลาง เช่น งานกลึง ไส กัด เจาะ, ประกอบชิ้นส่วนยานยนต์, บรรจุภัณฑ์, งานทอผ้า',
      minLux: 300.0,
      maxLux: 400.0,
      surroundingLuxRatio: 0.333,
      referenceLawTitle: 'ประกาศกรมสวัสดิการและคุ้มครองแรงงาน เรื่อง มาตรฐานความเข้มของแสงสว่าง พ.ศ. ๒๕๖๑',
      referenceArticle: 'หมวด ๒ ข้อ ๒ (๓)',
      notes: 'วัด ณ พื้นผิวโต๊ะปฏิบัติงานหรือบริเวณจับยึดชิ้นงาน',
      sortOrder: 113,
    ),
    EnvironmentStandardModel(
      standardId: 'LIGHT-CAT2-04',
      factorType: EnvironmentFactorType.light,
      categoryCode: 'LIGHT_CAT2',
      categoryNameTh: 'จุดทำงานเฉพาะจุด (งานสำนักงาน/ธุรการ)',
      categoryNameEn: 'General Office & Administration',
      taskDescription: 'งานสำนักงานและธุรการทั่วไป, งานพิมพ์เอกสาร, บันทึกข้อมูลคอมพิวเตอร์, โต๊ะทำงานทั่วไป',
      minLux: 300.0,
      maxLux: 500.0,
      surroundingLuxRatio: 0.333,
      referenceLawTitle: 'ประกาศกรมสวัสดิการและคุ้มครองแรงงาน เรื่อง มาตรฐานความเข้มของแสงสว่าง พ.ศ. ๒๕๖๑',
      referenceArticle: 'หมวด ๒ ข้อ ๒ (๔)',
      notes: 'วัด ณ ระดับความสูงโต๊ะทำงาน (๐.๗๕ เมตร)',
      sortOrder: 114,
    ),
    EnvironmentStandardModel(
      standardId: 'LIGHT-CAT2-05',
      factorType: EnvironmentFactorType.light,
      categoryCode: 'LIGHT_CAT2',
      categoryNameTh: 'จุดทำงานเฉพาะจุด (งานสายตาละเอียด)',
      categoryNameEn: 'Fine / Detailed Visual Tasks',
      taskDescription: 'งานที่ใช้สายตาละเอียด เช่น งานเย็บผ้า, ประกอบชิ้นส่วนอิเล็กทรอนิกส์, งานเขียนแบบ (Drafting)',
      minLux: 400.0,
      maxLux: 600.0,
      surroundingLuxRatio: 0.333,
      referenceLawTitle: 'ประกาศกรมสวัสดิการและคุ้มครองแรงงาน เรื่อง มาตรฐานความเข้มของแสงสว่าง พ.ศ. ๒๕๖๑',
      referenceArticle: 'หมวด ๒ ข้อ ๒ (๕)',
      notes: 'วัด ณ ตำแหน่งหัวแร้ง/จุดประกอบแผงวงจร',
      sortOrder: 115,
    ),
    EnvironmentStandardModel(
      standardId: 'LIGHT-CAT2-06',
      factorType: EnvironmentFactorType.light,
      categoryCode: 'LIGHT_CAT2',
      categoryNameTh: 'จุดทำงานเฉพาะจุด (งานสายตาละเอียดสูง/QC)',
      categoryNameEn: 'Very Fine / QC Inspection Tasks',
      taskDescription: 'งานที่ใช้สายตาละเอียดสูง ตรวจสอบคุณภาพ (QC/QA), งานตรวจข้อบกพร่องของสี, งานห้องแล็บ',
      minLux: 600.0,
      maxLux: 800.0,
      surroundingLuxRatio: 0.333,
      referenceLawTitle: 'ประกาศกรมสวัสดิการและคุ้มครองแรงงาน เรื่อง มาตรฐานความเข้มของแสงสว่าง พ.ศ. ๒๕๖๑',
      referenceArticle: 'หมวด ๒ ข้อ ๒ (๖)',
      notes: 'วัด ณ โต๊ะส่องตรวจชิ้นงาน',
      sortOrder: 116,
    ),
    EnvironmentStandardModel(
      standardId: 'LIGHT-CAT2-07',
      factorType: EnvironmentFactorType.light,
      categoryCode: 'LIGHT_CAT2',
      categoryNameTh: 'จุดทำงานเฉพาะจุด (งานละเอียดเป็นพิเศษ)',
      categoryNameEn: 'Minute / Extra Fine Visual Tasks',
      taskDescription: 'งานที่ใช้สายตาละเอียดเป็นพิเศษ เช่น งานทำอัญมณี เพชรพลอย, ประกอบนาฬิกา, งานผลิตไมโครชิป',
      minLux: 1000.0,
      maxLux: 1500.0,
      surroundingLuxRatio: 0.333,
      referenceLawTitle: 'ประกาศกรมสวัสดิการและคุ้มครองแรงงาน เรื่อง มาตรฐานความเข้มของแสงสว่าง พ.ศ. ๒๕๖๑',
      referenceArticle: 'หมวด ๒ ข้อ ๒ (๗)',
      notes: 'ติดตั้งไฟส่องสว่างเฉพาะจุด (Task Light) ร่วมด้วย',
      sortOrder: 117,
    ),

    // =========================================================================
    // 3. เสียง (Noise Threshold Standards - DLPW 2561 & Reg 2559)
    // =========================================================================
    EnvironmentStandardModel(
      standardId: 'NOISE-TWA-8HR',
      factorType: EnvironmentFactorType.noise,
      categoryCode: 'NOISE_STD',
      categoryNameTh: 'เกณฑ์ระดับเสียงเฉลี่ย ๘ ชม. (8-hr TWA)',
      categoryNameEn: '8-Hour Time-Weighted Average Limit',
      taskDescription: 'ระดับเสียงเฉลี่ยตลอดระยะเวลาการทำงาน ๘ ชั่วโมงต่อวัน (Leq 8-hr)',
      noiseTwaLimitDba: 86.0,
      noiseActionLevelDba: 85.0,
      noiseCeilingLimitDba: 115.0,
      noisePeakLimitDb: 140.0,
      referenceLawTitle: 'ประกาศกรมสวัสดิการและคุ้มครองแรงงาน เรื่อง มาตรฐานระดับเสียง พ.ศ. ๒๕๖๑',
      referenceArticle: 'ข้อ ๑ และ กฎกระทรวงฯ ๒๕๕๙ ข้อ ๗-๘',
      notes: 'เสียงเฉลี่ย 8 ชม. ต้องไม่เกิน 86 dBA; ตั้งแต่ 85 dBA ขึ้นไปต้องจัดทำโครงการอนุรักษ์การได้ยิน (HCP)',
      sortOrder: 201,
    ),
    EnvironmentStandardModel(
      standardId: 'NOISE-ACTION-LEVEL',
      factorType: EnvironmentFactorType.noise,
      categoryCode: 'NOISE_STD',
      categoryNameTh: 'เกณฑ์เฝ้าระวังและอนุรักษ์การได้ยิน (Action Level)',
      categoryNameEn: 'Hearing Conservation Action Level',
      taskDescription: 'ระดับเสียงเฉลี่ย ๘ ชั่วโมง ตั้งแต่ ๘๕ dBA ขึ้นไป (Noise Dose >= 79.4%)',
      noiseTwaLimitDba: 86.0,
      noiseActionLevelDba: 85.0,
      noiseCeilingLimitDba: 115.0,
      noisePeakLimitDb: 140.0,
      referenceLawTitle: 'กฎกระทรวงความร้อน แสงสว่าง และเสียง พ.ศ. ๒๕๕๙',
      referenceArticle: 'ข้อ ๑๑ (โครงการอนุรักษ์การได้ยิน)',
      notes: 'บังคับจัดทำโครงการอนุรักษ์การได้ยิน แผนผังเสียง ตรวจการได้ยินประจำปี และแจกจ่าย PPE ลดเสียง',
      sortOrder: 202,
    ),
    EnvironmentStandardModel(
      standardId: 'NOISE-CEILING-CONTINUOUS',
      factorType: EnvironmentFactorType.noise,
      categoryCode: 'NOISE_STD',
      categoryNameTh: 'เพดานระดับเสียงดังต่อเนื่องสูงสุด (Continuous Ceiling)',
      categoryNameEn: 'Continuous Noise Ceiling Limit',
      taskDescription: 'ระดับเสียงดังต่อเนื่องสูงสุด ห้ามลูกจ้างได้รับเสียงเกินระดับนี้ในทุกกรณี ไม่ว่าเวลาใด',
      noiseTwaLimitDba: 86.0,
      noiseActionLevelDba: 85.0,
      noiseCeilingLimitDba: 115.0,
      noisePeakLimitDb: 140.0,
      referenceLawTitle: 'กฎกระทรวงความร้อน แสงสว่าง และเสียง พ.ศ. ๒๕๕๙',
      referenceArticle: 'ข้อ ๗ วรรคสอง',
      notes: 'ห้ามมีระดับเสียงต่อเนื่องเกิน 115 dBA โดยเด็ดขาด',
      sortOrder: 203,
    ),
    EnvironmentStandardModel(
      standardId: 'NOISE-PEAK-IMPACT',
      factorType: EnvironmentFactorType.noise,
      categoryCode: 'NOISE_STD',
      categoryNameTh: 'เพดานระดับเสียงกระทบหรือกระแทกสูงสุด (Peak Limit)',
      categoryNameEn: 'Impact / Peak Noise Limit',
      taskDescription: 'ระดับเสียงกระทบหรือเสียงกระแทกสูงสุด (Peak Sound Pressure Level)',
      noiseTwaLimitDba: 86.0,
      noiseActionLevelDba: 85.0,
      noiseCeilingLimitDba: 115.0,
      noisePeakLimitDb: 140.0,
      referenceLawTitle: 'กฎกระทรวงความร้อน แสงสว่าง และเสียง พ.ศ. ๒๕๕๙',
      referenceArticle: 'ข้อ ๗ วรรคสาม',
      notes: 'ห้ามมีระดับเสียงกระแทกเกิน 140 dB Peak',
      sortOrder: 204,
    ),

    // =========================================================================
    // 4. ความร้อน (Heat WBGT Standards - DLPW 2563 & Reg 2559)
    // =========================================================================
    EnvironmentStandardModel(
      standardId: 'HEAT-LIGHT-WORK',
      factorType: EnvironmentFactorType.heat,
      categoryCode: 'HEAT_STD',
      categoryNameTh: 'งานเบา (Light Work <= 200 kcal/hr)',
      categoryNameEn: 'Light Work Heat Limit',
      taskDescription: 'งานเบา: นั่งเขียนหนังสือ, พิมพ์ดีด/คอมพิวเตอร์, นั่งประกอบชิ้นงานเล็ก, ขับรถยนต์/โฟล์คลิฟต์',
      workLoadType: WorkloadLevel.light,
      metabolicRateKcalHr: 200.0,
      wbgtLimitCelsius: 34.0,
      referenceLawTitle: 'กฎกระทรวงความร้อน แสงสว่าง และเสียง พ.ศ. ๒๕๕๙ & ประกาศกรมฯ ๒๕๖๓',
      referenceArticle: 'กฎกระทรวง ข้อ ๒ (๑)',
      notes: 'ระดับความร้อน WBGT ต้องไม่เกิน ๓๔ องศาเซลเซียส',
      sortOrder: 301,
    ),
    EnvironmentStandardModel(
      standardId: 'HEAT-MODERATE-WORK',
      factorType: EnvironmentFactorType.heat,
      categoryCode: 'HEAT_STD',
      categoryNameTh: 'งานปานกลาง (Moderate Work 200-350 kcal/hr)',
      categoryNameEn: 'Moderate Work Heat Limit',
      taskDescription: 'งานปานกลาง: เดินตรวจงานสม่ำเสมอ, ยกของ 5-15 kg, ไสไม้ กลึง, ก่ออิฐฉาบปูน, ขัดพื้น, ประกอบรถยนต์',
      workLoadType: WorkloadLevel.moderate,
      metabolicRateKcalHr: 300.0,
      wbgtLimitCelsius: 32.0,
      referenceLawTitle: 'กฎกระทรวงความร้อน แสงสว่าง และเสียง พ.ศ. ๒๕๕๙ & ประกาศกรมฯ ๒๕๖๓',
      referenceArticle: 'กฎกระทรวง ข้อ ๒ (๒)',
      notes: 'ระดับความร้อน WBGT ต้องไม่เกิน ๓๒ องศาเซลเซียส',
      sortOrder: 302,
    ),
    EnvironmentStandardModel(
      standardId: 'HEAT-HEAVY-WORK',
      factorType: EnvironmentFactorType.heat,
      categoryCode: 'HEAT_STD',
      categoryNameTh: 'งานหนัก (Heavy Work > 350 kcal/hr)',
      categoryNameEn: 'Heavy Work Heat Limit',
      taskDescription: 'งานหนัก: แบกหามของหนัก > 15 kg, ขุดดิน/เจาะถนน, ใช้ค้อนปอนด์, โกยถ่านหิน, เลื่อยไม้ด้วยมือ, เทโลหะหลอม',
      workLoadType: WorkloadLevel.heavy,
      metabolicRateKcalHr: 450.0,
      wbgtLimitCelsius: 30.0,
      referenceLawTitle: 'กฎกระทรวงความร้อน แสงสว่าง และเสียง พ.ศ. ๒๕๕๙ & ประกาศกรมฯ ๒๕๖๓',
      referenceArticle: 'กฎกระทรวง ข้อ ๒ (๓)',
      notes: 'ระดับความร้อน WBGT ต้องไม่เกิน ๓๐ องศาเซลเซียส',
      sortOrder: 303,
    ),
  ];

  /// Find standard item by its exact ID (e.g. 'LIGHT-CAT2-04')
  static EnvironmentStandardModel? findById(String standardId) {
    try {
      return masterStandards.firstWhere((e) => e.standardId == standardId);
    } catch (_) {
      return null;
    }
  }

  /// Alias for findById
  static EnvironmentStandardModel? findStandardByCode(String code) => findById(code);

  /// Find standard items by factor type (Light, Noise, Heat)
  static List<EnvironmentStandardModel> findByFactorType(EnvironmentFactorType factorType) {
    return masterStandards.where((e) => e.factorType == factorType).toList();
  }

  /// Find standard items by category code
  static List<EnvironmentStandardModel> findByCategory(String categoryCode) {
    return masterStandards.where((e) => e.categoryCode == categoryCode).toList();
  }

  /// Search standard items by keyword and optional factor type filter
  static List<EnvironmentStandardModel> search(
    String keyword, {
    EnvironmentFactorType? factorType,
  }) {
    final q = keyword.trim().toLowerCase();
    return masterStandards.where((item) {
      if (factorType != null && item.factorType != factorType) {
        return false;
      }
      if (q.isEmpty) return true;

      return item.standardId.toLowerCase().contains(q) ||
          item.categoryNameTh.toLowerCase().contains(q) ||
          item.categoryNameEn.toLowerCase().contains(q) ||
          item.taskDescription.toLowerCase().contains(q) ||
          item.referenceArticle.toLowerCase().contains(q) ||
          (item.notes?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  /// All Lighting Standards
  static List<EnvironmentStandardModel> get lightingStandards =>
      findByFactorType(EnvironmentFactorType.light);

  /// All Noise Standards
  static List<EnvironmentStandardModel> get noiseStandards =>
      findByFactorType(EnvironmentFactorType.noise);

  /// All Heat Standards
  static List<EnvironmentStandardModel> get heatStandards =>
      findByFactorType(EnvironmentFactorType.heat);
}
