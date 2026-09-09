import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../../../core/database/database_helper.dart';
import '../models/factory_scope_model.dart';
import '../models/manual_chapter_model.dart';

class ManualRepository {
  final DatabaseHelper _dbHelper;

  ManualRepository([DatabaseHelper? dbHelper]) : _dbHelper = dbHelper ?? DatabaseHelper();

  Future<Database> get _db async => await _dbHelper.database;

  Future<FactoryScopeModel> getFactoryScope() async {
    final db = await _db;
    final res = await db.query('safety_factory_scope', where: 'id = 1', limit: 1);
    if (res.isNotEmpty) {
      return FactoryScopeModel.fromMap(res.first);
    }
    return const FactoryScopeModel();
  }

  Future<void> saveFactoryScope(FactoryScopeModel scope) async {
    final db = await _db;
    await db.insert(
      'safety_factory_scope',
      scope.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ========================================================
  // DYNAMIC ASSEMBLY: TIER 1 - MASTER SAFETY MANUAL
  // ========================================================
  List<ManualChapterModel> buildMasterChapters(
    FactoryScopeModel scope, {
    String companyName = 'สถานประกอบการ',
    String? safetyPolicy,
    String? safetyOfficerName,
  }) {
    List<ManualChapterModel> chapters = [];
    int chNum = 1;

    // บทที่ 1: บทนำและนโยบายความปลอดภัย
    chapters.add(ManualChapterModel(
      chapterNumber: chNum++,
      titleTh: 'บทนำและนโยบายความปลอดภัย อาชีวอนามัย และสภาพแวดล้อมในการทำงาน',
      titleEn: 'Introduction & OSH Policy',
      categoryKey: 'GENERAL',
      content: safetyPolicy != null && safetyPolicy.trim().isNotEmpty
          ? 'นโยบายความปลอดภัยของ $companyName:\n$safetyPolicy'
          : '$companyName ยึดมั่นในความปลอดภัยของพนักงานและผู้มีส่วนได้ส่วนเสียทุกคนเป็นอันดับแรก การดำเนินงานทั้งหมดต้องเป็นไปตามพระราชบัญญัติความปลอดภัย อาชีวอนามัย และสภาพแวดล้อมในการทำงาน พ.ศ. ๒๕๕๔ โดยมีเป้าหมายอุบัติเหตุเป็นศูนย์ (Zero Accident)',
      keyRules: [
        'ความปลอดภัยในการทำงานเป็นหน้าที่ของพนักงานทุกระดับ',
        'การฝ่าฝืนกฎความปลอดภัยถือเป็นการฝ่าฝืนวินัยการทำงานของบริษัท',
        'พนักงานทุกคนมีสิทธิสั่งหยุดงาน (Stop Work Authority) เมื่อพบสภาพงานที่ไม่ปลอดภัยร้ายแรง',
      ],
    ));

    // บทที่ 2: โครงสร้างการบริหารและหน้าที่ความรับผิดชอบ
    chapters.add(ManualChapterModel(
      chapterNumber: chNum++,
      titleTh: 'โครงสร้างการบริหารงานความปลอดภัยและบทบาทหน้าที่ (จป. และ คปอ.)',
      titleEn: 'Safety Governance, Roles & Responsibilities',
      categoryKey: 'GENERAL',
      content: 'การบริหารจัดการความปลอดภัยดำเนินงานตามกฎกระทรวงการจัดให้มีเจ้าหน้าที่ความปลอดภัยในการทำงาน พ.ศ. ๒๕๖๕ โดยมีคณะกรรมการความปลอดภัย อาชีวอนามัย และสภาพแวดล้อมในการทำงาน (คปอ.) ประจำสถานประกอบการ และ จป.วิชาชีพ (${safetyOfficerName ?? 'เจ้าหน้าที่ความปลอดภัยวิชาชีพ'}) ร่วมผลักดันการดำเนินงาน',
      keyRules: [
        'นายจ้าง: จัดสรรทรัพยากร อุปกรณ์ PPE และงบประมาณด้านความปลอดภัยอย่างเพียงพอ',
        'หัวหน้างาน: ควบคุมดูแลผู้ใต้บังคับบัญชาให้ปฏิบัติตามขั้นตอนการทำงานอย่างปลอดภัย (SOPs)',
        'ลูกจ้าง: สวมใส่อุปกรณ์ PPE รายงานสภาพการณ์อันตราย และเข้าร่วมการฝึกอบรมความปลอดภัย',
        'คปอ.: สำรวจความปลอดภัยประจำเดือนและเสนอแนะมาตรการปรับปรุงต่อนายจ้าง',
      ],
    ));

    // บทที่ 3: กฎความปลอดภัยทั่วไปและวินัยในสถานประกอบการ
    chapters.add(ManualChapterModel(
      chapterNumber: chNum++,
      titleTh: 'กฎระเบียบความปลอดภัยทั่วไปและวินัยในการทำงาน',
      titleEn: 'General Safety Rules & Workplace Discipline',
      categoryKey: 'GENERAL',
      content: 'พนักงาน ผู้รับเหมา และผู้มาติดต่อทุกคนต้องปฏิบัติตามกฎความปลอดภัยขั้นพื้นฐานอย่างเคร่งครัดตั้งแต่ก้าวเข้าสู่บริเวณโรงงาน',
      keyRules: [
        'ห้ามสูบบุหรี่หรือบุหรี่ไฟฟ้าเด็ดขาด ยกเว้นจุดสูบบุหรี่ที่กำหนด (Designated Smoking Area)',
        'ห้ามนำสุรา สารเสพติด หรืออาวุธเข้ามาในบริเวณสถานประกอบการโดยเด็ดขาด',
        'ห้ามวิ่ง เล่น หรือหยอกล้อในพื้นที่การผลิตและคลังสินค้า',
        'เดินเฉพาะทางเดินคน (Green Walkway) และใช้ความเร็วรถในโรงงานไม่เกิน 20 กม./ชม.',
        'ห้ามใช้โทรศัพท์มือถือขณะเดินในสายการผลิตหรือกำลังควบคุมเครื่องจักร',
      ],
    ));

    // บทที่ 4: อุปกรณ์คุ้มครองความปลอดภัยส่วนบุคคล (PPE)
    if (scope.hasPpe) {
      chapters.add(ManualChapterModel(
        chapterNumber: chNum++,
        titleTh: 'มาตรฐานการใช้อุปกรณ์คุ้มครองความปลอดภัยส่วนบุคคล (PPE)',
        titleEn: 'Personal Protective Equipment Standards',
        categoryKey: 'PPE',
        content: 'บริษัทจัดหาอุปกรณ์คุ้มครองความปลอดภัยส่วนบุคคลที่ได้มาตรฐาน มอก., ANSI หรือ EN ให้แก่พนักงานโดยไม่คิดมูลค่า โดยพนักงานมีหน้าที่สวมใส่ ตรวจสอบ และดูแลรักษาให้อยู่ในสภาพพร้อมใช้งาน',
        keyRules: [
          'หมวกนิรภัย (Safety Helmet): บังคับสวมใส่ในเขตพื้นที่ก่อสร้าง ช่างซ่อมบำรุง และเขตยกของ',
          'แว่นตานิรภัย (Safety Glasses): บังคับสวมใส่ในพื้นที่การผลิตที่มีเศษกระเด็นหรือฝุ่นละออง',
          'รองเท้าหัวเหล็ก (Safety Boots): บังคับสวมใส่ในพื้นที่โรงงาน คลังสินค้า และซ่อมบำรุง',
          'ที่อุดหู/ครอบหู (Hearing Protection): ต้องสวมใส่ในพื้นที่เสียงดังเกิน 85 เดซิเบลเอ (dBA)',
        ],
      ));
    }

    // บทที่ 5: ระบบใบอนุญาตทำงาน (Permit to Work - PTW)
    chapters.add(ManualChapterModel(
      chapterNumber: chNum++,
      titleTh: 'ระบบการขออนุญาตปฏิบัติงานที่มีความเสี่ยงสูง (Permit to Work - PTW)',
      titleEn: 'Permit to Work (PTW) System',
      categoryKey: 'GENERAL',
      content: 'งานที่มีความเสี่ยงสูงต้องได้รับการประเมินอันตราย (JSA) และได้รับใบอนุญาตทำงาน (PTW) ที่ได้รับการอนุมัติจากผู้มีอำนาจก่อนเริ่มลงมือปฏิบัติงานทุกครั้ง',
      keyRules: [
        'ต้องมีใบอนุญาต PTW ติดแสดงไว้ ณ จุดปฏิบัติงานตลอดระยะเวลาทำงาน',
        'จัดให้มีการประชุมชี้แจงความปลอดภัย (Toolbox Talk) ก่อนเริ่มงานทุกวัน',
        'เมื่อเงื่อนไขหน้างานเปลี่ยนไปหรือพบอันตรายเกินควบคุม ให้สั่งหยุดงานและปิดใบอนุญาตทันที',
      ],
    ));

    // บท: ระบบไฟฟ้า & LOTO (ตาม Scope)
    if (scope.hasElectricalLoto) {
      chapters.add(ManualChapterModel(
        chapterNumber: chNum++,
        titleTh: 'ความปลอดภัยเกี่ยวกับระบบไฟฟ้าและการตัดแยกพลังงาน (Lockout/Tagout - LOTO)',
        titleEn: 'Electrical Safety & Hazardous Energy Isolation (LOTO)',
        categoryKey: 'ELECTRICAL',
        content: 'การปฏิบัติงานเกี่ยวกับระบบไฟฟ้าต้องเป็นไปตามกฎกระทรวงความปลอดภัยเกี่ยวกับไฟฟ้า พ.ศ. ๒๕๕๘ โดยเฉพาะงานซ่อมบำรุงเครื่องจักรต้องตัดแยกพลังงานด้วยระบบ LOTO (6 ขั้นตอน: แจ้งเตือน -> หยุดเครื่อง -> ตัดแยก -> ล็อคแขวนป้าย -> ระบายพลังงานตกค้าง -> ตรวจวัดแรงดัน = 0V)',
        keyRules: [
          'กฎเหล็ก 1 คน 1 กุญแจ (One Person, One Lock) ห้ามใช้แม่กุญแจร่วมกัน',
          'ต้องใช้เครื่องวัดแรงดันไฟฟ้า (Multimeter) ยืนยัน Zero Energy (0.0 Volt) เสมอ',
          'ผู้ปฏิบัติงานระบบไฟฟ้าต้องเป็นผู้มีความรู้ความสามารถและได้รับหนังสือรับรองตามกฎหมาย',
        ],
      ));
    }

    // บท: เครื่องจักร ปั้นจั่น & อุปกรณ์ช่วยยก (ตาม Scope)
    if (scope.hasCrane) {
      chapters.add(ManualChapterModel(
        chapterNumber: chNum++,
        titleTh: 'ความปลอดภัยในการใช้งานปั้นจั่นและอุปกรณ์ช่วยยก (Cranes & Rigging)',
        titleEn: 'Cranes, Hoists & Lifting Gears Safety',
        categoryKey: 'CRANE',
        content: 'การใช้งานปั้นจั่นเหนือศีรษะ รอกไฟฟ้า และอุปกรณ์ช่วยยกต้องปฏิบัติตามกฎกระทรวงเครื่องจักร ปั้นจั่น และหม้อน้ำ พ.ศ. ๒๕๖๔ มีผลการทดสอบโหลดเทส 125% และตรวจรับรอง ปจ.๑ / ปจ.๒ ตามรอบเวลา',
        keyRules: [
          'ห้ามยกชิ้นงานหนักเกินพิกัดน้ำหนักปลอดภัย (Safe Working Load: SWL) เด็ดขาด',
          'ห้ามบุคคลเดินหรือยืนใต้แนวรัศมีชิ้นงานที่กำลังยก (No Walk Under Load)',
          'ลวดสลิง โซ่ยก และสะเก็น ต้องผ่านการตรวจสอบสภาพประจำวันก่อนเริ่มยกชิ้นงาน',
        ],
      ));
    }

    // บท: หม้อน้ำและภาชนะรับแรงดัน (ตาม Scope - ถ้าโรงงานไม่มีหม้อน้ำจะถูกตัดออก!)
    if (scope.hasBoiler) {
      chapters.add(ManualChapterModel(
        chapterNumber: chNum++,
        titleTh: 'ความปลอดภัยเกี่ยวกับหม้อน้ำไอน้ำและภาชนะรับแรงดัน (Boilers & Pressure Vessels)',
        titleEn: 'Boilers & Pressure Vessels Safety',
        categoryKey: 'BOILER',
        content: 'หม้อน้ำไอน้ำและถังรับแรงดันต้องได้รับการตรวจรับรองประจำปีโดยวิศวกรเครื่องกลที่ได้รับใบอนุญาต มีการทดสอบ Hydrostatic test (1.5x MAWP) และทดสอบลิ้นนิรภัย (Safety Valve) สม่ำเสมอ',
        keyRules: [
          'ห้ามปรับตั้งหรือดัดแปลงลิ้นนิรภัย (Safety Valve) ให้ปลดปล่อยแรงดันเกินพิกัด',
          'ผู้ควบคุมหม้อน้ำต้องผ่านการอบรมและได้รับหนังสือรับรองตามประกาศกรมโรงงานฯ',
          'บันทึกค่าแรงดัน อุณหภูมิ และระดับน้ำเลี้ยงในสมุดปูมประจำวันทุกชั่วโมง',
        ],
      ));
    }

    // บท: สารเคมีอันตราย (ตาม Scope)
    if (scope.hasChemical) {
      chapters.add(ManualChapterModel(
        chapterNumber: chNum++,
        titleTh: 'การจัดการสารเคมีอันตรายและเอกสารข้อมูลความปลอดภัย (Chemicals & SDS)',
        titleEn: 'Hazardous Chemicals & SDS Management',
        categoryKey: 'CHEMICAL',
        content: 'การจัดเก็บ การถ่ายเท และการใช้งานสารเคมีต้องเป็นไปตามกฎกระทรวงสารเคมีอันตราย พ.ศ. ๒๕๕๖ โดยภาชนะบรรจุทุกชิ้นต้องมีฉลากระบบ GHS ชัดเจน และมีเอกสาร SDS ภาษาไทยประจำจุดใช้งาน',
        keyRules: [
          'ต้องศึกษาเอกสาร SDS หัวข้อที่ 8 (PPE) ก่อนสัมผัสหรือถ่ายเทสารเคมี',
          'การถ่ายเทสารไวไฟต้องต่อสายดิน (Grounding & Bonding) ป้องกันประกายไฟสถิต',
          'ห้ามจัดเก็บสารเคมีที่ไม่เข้ากันไว้ในบริเวณเดียวกัน (Incompatible Chemicals)',
          'ประจำชุดดูดซับสารเคมีรั่วไหล (Spill Kit) และอ่างล้างตาฉุกเฉินในรัศมี 10 วินาที',
        ],
      ));
    }

    // บท: การทำงานในสถานที่อับอากาศ (ตาม Scope)
    if (scope.hasConfinedSpace) {
      chapters.add(ManualChapterModel(
        chapterNumber: chNum++,
        titleTh: 'ความปลอดภัยในการทำงานในสถานที่อับอากาศ (Confined Space Safety)',
        titleEn: 'Confined Space Entry Safety',
        categoryKey: 'CONFINED',
        content: 'การเข้าทำงานในสถานที่อับอากาศต้องปฏิบัติตามกฎกระทรวงที่อับอากาศ พ.ศ. ๒๕๖๒ มีการแต่งตั้ง 4 บทบาท (ผู้อนุญาต ผู้ควบคุม ผู้ช่วยเหลือ ผู้ปฏิบัติงาน) และตรวจวัดก๊าซก่อนเข้าพื้นที่',
        keyRules: [
          'ตรวจวัดก๊าซ 4 ชนิด: O2 (19.5-23.5%), LEL (<10%), CO (<25 ppm), H2S (<10 ppm)',
          'ติดตั้งพัดลมเป่าอากาศบริสุทธิ์ต่อเนื่องตลอดเวลาที่คนทำงานอยู่ภายใน',
          'ผู้ช่วยเหลือต้องประจำอยู่ที่ปากทางเข้าออกตลอดเวลา ห้ามละทิ้งหน้าที่เด็ดขาด',
        ],
      ));
    }

    // บท: การทำงานบนที่สูงและนั่งร้าน (ตาม Scope)
    if (scope.hasWorkingAtHeight) {
      chapters.add(ManualChapterModel(
        chapterNumber: chNum++,
        titleTh: 'ความปลอดภัยในการทำงานบนที่สูงและนั่งร้าน (Work at Height & Scaffolding)',
        titleEn: 'Work at Height & Fall Protection Safety',
        categoryKey: 'HEIGHTS',
        content: 'การปฏิบัติงานบนที่สูงตั้งแต่ 2.0 เมตรขึ้นไป ต้องปฏิบัติตามกฎกระทรวงนั่งร้านและที่สูง พ.ศ. ๒๕๖๔ มีระบบราวกั้นตก (Guardrail) หรือใช้อุปกรณ์ป้องกันการตกส่วนบุคคล (Full Body Harness)',
        keyRules: [
          'คล้องเกี่ยวจุดยึดเหนี่ยว 100% (100% Tie-off) ตลอดเวลาที่อยู่บนที่สูง',
          'นั่งร้านต้องมีแผ่นป้ายตรวจสอบสีเขียว (Green Tag) และตรวจสภาพทุก 7 วัน',
          'ห้ามทำงานบนที่สูงกลางแจ้งขณะฝนตกหนัก มีพายุ หรือลมแรง',
        ],
      ));
    }

    // บท: การรายงานอุบัติเหตุและการปฐมพยาบาล
    chapters.add(ManualChapterModel(
      chapterNumber: chNum++,
      titleTh: 'การรายงานอุบัติเหตุ เหตุการณ์เกือบเกิดอุบัติเหตุ และการปฐมพยาบาล',
      titleEn: 'Incident & Near-Miss Reporting & First Aid',
      categoryKey: 'GENERAL',
      content: 'เมื่อเกิดอุบัติเหตุหรือพบเหตุการณ์เกือบเกิดอุบัติเหตุ (Near-Miss) ผู้ปฏิบัติงานต้องแจ้งต่อหัวหน้างานทันที เพื่อเข้ารับการปฐมพยาบาลและสอบสวนหาสาเหตุรากเหง้าตามขั้นตอน',
      keyRules: [
        'รายงานอุบัติเหตุและเหตุเกือบเกิดทันที ไม่มีการตำหนิหรือลงโทษ (No Blame Culture)',
        'ห้องพยาบาลเปิดให้บริการพร้อมชุดปฐมพยาบาลและเครื่องกระตุกหัวใจอัตโนมัติ (AED)',
        'ดำเนินการสอบสวนอุบัติเหตุด้วยหลัก 5-Whys เพื่อออกมาตรการป้องกันการเกิดซ้ำ (CAPA)',
      ],
    ));

    // บท: แผนระงับเหตุฉุกเฉินและการอพยพหนีไฟ
    if (scope.hasEmergencyFire) {
      chapters.add(ManualChapterModel(
        chapterNumber: chNum++,
        titleTh: 'แผนเตรียมพร้อมเผชิญเหตุฉุกเฉินและการอพยพหนีไฟ (Emergency Response & Evacuation)',
        titleEn: 'Emergency Response & Fire Evacuation Plan',
        categoryKey: 'FIRE',
        content: 'สถานประกอบการจัดทำแผนระงับอัคคีภัยและการฝึกซ้อมดับเพลิงและอพยพหนีไฟประจำปีตามกฎกระทรวงป้องกันและระงับอัคคีภัย พ.ศ. ๒๕๕๕ โดยพนักงานทุกคนต้องทราบเส้นทางหนีไฟและจุดรวมพล',
        keyRules: [
          'เมื่อได้ยินสัญญาณเตือนภัยต่อเนื่อง ให้หยุดงานและเดินแถวอพยพสู่จุดรวมพลทันที',
          'ห้ามใช้ลิฟต์โดยสารในขณะเกิดเพลิงไหม้เด็ดขาด ให้ใช้บันไดหนีไฟเท่านั้น',
          'หัวหน้าทีมอพยพทำการเช็คยอดพนักงานที่จุดรวมพลและรายงานต่อผู้บัญชาการเหตุการณ์',
        ],
      ));
    }

    return chapters;
  }

  // ========================================================
  // DYNAMIC ASSEMBLY: TIER 2 - EMPLOYEE POCKET HANDBOOK
  // ========================================================
  Map<String, dynamic> buildEmployeeHandbookData(
    FactoryScopeModel scope, {
    String companyName = 'สถานประกอบการ',
  }) {
    List<Map<String, dynamic>> goldenRules = [
      {
        'num': 1,
        'title': 'สวมใส่ PPE ประจำตำแหน่ง 100%',
        'desc': 'หมวก แว่นตา ที่อุดหู ถุงมือ รองเท้าหัวเหล็ก ต้องสวมใส่ทุกครั้งที่เข้าพื้นที่ปฏิบัติงาน',
        'icon': 'shield',
      },
      {
        'num': 2,
        'title': 'เดินเฉพาะทางเดินคน (Green Walkway)',
        'desc': 'ห้ามลัดตัดผ่านโซนเครื่องจักร ระวังรถโฟล์คลิฟต์ และสังเกตป้ายเตือนเสมอ',
        'icon': 'directions_walk',
      },
      {
        'num': 3,
        'title': 'ห้ามใช้โทรศัพท์ขณะเดินหรือคุมเครื่อง',
        'desc': 'หยุดยืนในจุดที่ปลอดภัยก่อนใช้โทรศัพท์ ป้องกันการสะดุดล้มหรือถูกเฉี่ยวชน',
        'icon': 'phonelink_erase',
      },
    ];

    if (scope.hasElectricalLoto) {
      goldenRules.add({
        'num': goldenRules.length + 1,
        'title': 'ตัดแยกพลังงาน LOTO ก่อนซ่อมบำรุง',
        'desc': '1 คน 1 กุญแจ ห้ามแหย่มือเข้าเครื่องจักรที่ยังไม่ได้ล็อคตัดแยกพลังงานเด็ดขาด',
        'icon': 'lock',
      });
    }

    if (scope.hasCrane) {
      goldenRules.add({
        'num': goldenRules.length + 1,
        'title': 'ห้ามยืนใต้แนวชิ้นงานที่กำลังยก (No Walk Under Load)',
        'desc': 'เว้นระยะห่างจากรัศมีการยกของปั้นจั่น และสังเกตเสียงสัญญาณเตือน',
        'icon': 'precision_manufacturing',
      });
    }

    if (scope.hasBoiler) {
      goldenRules.add({
        'num': goldenRules.length + 1,
        'title': 'ตรวจสอบเกจวัดแรงดันหม้อน้ำสม่ำเสมอ',
        'desc': 'ห้ามปรับแต่งลิ้นนิรภัย และรายงานทันทีหากพบความดันหรืออุณหภูมิผิดปกติ',
        'icon': 'speed',
      });
    }

    if (scope.hasChemical) {
      goldenRules.add({
        'num': goldenRules.length + 1,
        'title': 'อ่านฉลาก SDS และต่อสายดินสารไวไฟ',
        'desc': 'สวมกระบังหน้าและถุงมือกันสารเคมี ห้ามเทสารเคมีลงขวดน้ำดื่มเด็ดขาด',
        'icon': 'science',
      });
    }

    if (scope.hasWorkingAtHeight) {
      goldenRules.add({
        'num': goldenRules.length + 1,
        'title': 'เกี่ยวคล้องสายรัดตัวนิรภัย 100% บนที่สูง',
        'desc': 'ทำงานสูงเกิน 2 เมตร ต้องสวม Full Body Harness เกี่ยวกับจุดยึดเหนี่ยวที่มั่นคง',
        'icon': 'stairs',
      });
    }

    if (scope.hasConfinedSpace) {
      goldenRules.add({
        'num': goldenRules.length + 1,
        'title': 'ห้ามเข้าที่อับอากาศโดยไม่มีใบอนุญาต',
        'desc': 'ต้องมีใบอนุญาต PTW ตรวจวัดก๊าซผ่านเกณฑ์ และมีผู้ช่วยเหลือเฝ้าปากทางเสมอ',
        'icon': 'door_front_door',
      });
    }

    goldenRules.add({
      'num': goldenRules.length + 1,
      'title': 'สิทธิหยุดงานเมื่อไม่ปลอดภัย (Stop Work Authority)',
      'desc': 'หากพบสภาพแวดล้อมที่อาจเกิดอันตรายร้ายแรง ท่านมีสิทธิสั่งหยุดงานทันทีโดยไม่มีความผิด',
      'icon': 'pan_tool',
    });

    goldenRules.add({
      'num': goldenRules.length + 1,
      'title': 'รายงานอุบัติเหตุและเหตุเกือบเกิดทันที',
      'desc': 'สแกน QR Code หรือแจ้งหัวหน้างานทันที เพื่อร่วมกันแก้ไขก่อนเกิดการบาดเจ็บจริง',
      'icon': 'report_problem',
    });

    return {
      'companyName': companyName,
      'goldenRules': goldenRules,
      'rightsAndDuties': [
        'สิทธิได้รับการดูแลความปลอดภัย สุขภาพ และอุปกรณ์ PPE ฟรีไม่มีค่าใช้จ่าย',
        'หน้าที่ปฏิบัติตามขั้นตอนการทำงาน (SOPs) และระเบียบวินัยความปลอดภัยอย่างเคร่งครัด',
        'สิทธิสั่งหยุดงานทันที (Stop Work Authority) เมื่อพบอันตรายร้ายแรง',
      ],
      'emergencyCall': 'สายด่วนฉุกเฉินภายใน: โทรแจ้ง จป.วิชาชีพ หรือห้องพยาบาล กด 199 หรือ 999',
    };
  }

  // ========================================================
  // DYNAMIC ASSEMBLY: TIER 3 - 1-PAGE SAFETY INDUCTION CARD
  // ========================================================
  Map<String, dynamic> buildInductionLeafletData(
    FactoryScopeModel scope, {
    String companyName = 'สถานประกอบการ',
  }) {
    List<String> doList = [
      'แลกบัตรและติดบัตรประจำตัว (Visitor / Contractor) ตลอดเวลาในโรงงาน',
      'เดินเฉพาะในช่องทางเดินคน (Green Walkway) และสังเกตรถโฟล์คลิฟต์',
      'สวมใส่อุปกรณ์ PPE บังคับ (หมวก แว่นตา รองเท้าหัวเหล็ก เสื้อสะท้อนแสง)',
      'ขอใบอนุญาตทำงาน (PTW) ก่อนเริ่มงานเสี่ยงสูงทุกประเภท',
      'แจ้งเหตุฉุกเฉินหรืออุบัติเหตุต่อเจ้าหน้าที่ความปลอดภัยทันที',
    ];

    List<String> dontList = [
      'ห้ามสัมผัส แหย่มือ หรือกดปุ่มเครื่องจักรใดๆ โดยไม่ได้รับอนุญาต',
      'ห้ามสูบบุหรี่หรือบุหรี่ไฟฟ้าเด็ดขาด ยกเว้นจุดสูบบุหรี่ที่จัดไว้ให้',
      'ห้ามนำเครื่องดื่มแอลกอฮอล์ สารเสพติด และอาวุธเข้ามาในบริเวณโรงงาน',
      'ห้ามใช้โทรศัพท์มือถือขณะเดินในพื้นที่การผลิตหรือข้ามถนนในโรงงาน',
    ];

    if (scope.hasCrane) {
      dontList.add('ห้ามเดินหรือยืนใต้แนวรัศมีชิ้นงานที่กำลังยกด้วยปั้นจั่น');
    }
    if (scope.hasElectricalLoto) {
      dontList.add('ห้ามปลดหรือทำลายแม่กุญแจตัดแยกพลังงาน LOTO ของผู้อื่น');
    }
    if (scope.hasChemical) {
      dontList.add('ห้ามถ่ายเทสารเคมีลงในภาชนะหรือขวดน้ำดื่มโดยไม่มีฉลาก');
    }

    return {
      'companyName': companyName,
      'title': 'ใบสรุปกฎความปลอดภัยประจำโรงงาน (SAFETY INDUCTION LEAFLET)',
      'doList': doList,
      'dontList': dontList,
      'evacuationInstructions': 'เมื่อได้ยินเสียงสัญญาณเตือนภัย ให้หยุดงานทันทีและเดินตามป้ายทางหนีไฟไปยัง "จุดรวมพลหลัก (Main Assembly Point) บริเวณลานจอดรถหน้าโรงงาน"',
      'hotline': 'ศูนย์ควบคุมเหตุฉุกเฉินและ จป.วิชาชีพ: โทร 02-XXX-XXXX ต่อ 999 (หรือเบอร์สั้น 199)',
    };
  }

  /// สร้างรายการบทสำหรับคู่มือฉบับพนักงาน (Tier 2 Employee Handbook)
  List<ManualChapterModel> buildEmployeeHandbookChapters(
    FactoryScopeModel scope, {
    String companyName = 'สถานประกอบการ',
  }) {
    final data = buildEmployeeHandbookData(scope, companyName: companyName);
    final List<Map<String, dynamic>> goldenRulesRaw = data['goldenRules'] as List<Map<String, dynamic>>;
    final List<String> rightsRaw = (data['rightsAndDuties'] as List).cast<String>();

    return [
      ManualChapterModel(
        chapterNumber: 1,
        titleTh: 'สิทธิและหน้าที่ของลูกจ้างตามกฎหมายความปลอดภัย',
        titleEn: 'Employee Rights & Statutory Duties (OSH Act B.E. 2554)',
        categoryKey: 'RIGHTS',
        content: 'ลูกจ้างทุกคนมีสิทธิได้รับการคุ้มครองความปลอดภัย สภาพแวดล้อมในการทำงานที่ได้มาตรฐาน และอุปกรณ์คุ้มครองความปลอดภัยส่วนบุคคล (PPE) โดยไม่เสียค่าใช้จ่ายใดๆ ทั้งสิ้น ตาม พ.ร.บ. ความปลอดภัยฯ ๒๕๕๔ มาตรา ๒๒',
        keyRules: rightsRaw,
      ),
      ManualChapterModel(
        chapterNumber: 2,
        titleTh: 'กฎทองความปลอดภัยประจำโรงงาน (Golden Safety Rules)',
        titleEn: 'Life-Saving Golden Safety Rules',
        categoryKey: 'GOLDEN_RULES',
        content: 'กฎความปลอดภัยขั้นวิกฤตที่ทุกคนต้องยึดถือปฏิบัติอย่างเคร่งครัด เพื่อป้องกันการบาดเจ็บรุนแรงและอุบัติเหตุถึงแก่ชีวิต',
        keyRules: goldenRulesRaw.map((r) => '${r['title']}: ${r['desc']}').toList(),
      ),
      ManualChapterModel(
        chapterNumber: 3,
        titleTh: 'ข้อห้ามเด็ดขาดและวินัยความปลอดภัย',
        titleEn: 'Strict Prohibitions & Disciplinary Measures',
        categoryKey: 'DISCIPLINE',
        content: 'การกระทำที่เป็นอันตรายร้ายแรงต่อตนเองและผู้อื่น บริษัทมีมาตรการลงโทษทางวินัยตั้งแต่ตักเตือนจนถึงเลิกจ้างโดยไม่จ่ายค่าชดเชย',
        keyRules: [
          'ห้ามนำสุรา สารเสพติด และอาวุธเข้ามาในบริเวณสถานประกอบกิจการเด็ดขาด',
          'ห้ามสูบบุหรี่นอกเขตจุดสูบบุหรี่ที่กำหนด (ฝ่าฝืนมีโทษทางวินัยและกฎหมาย)',
          'ห้ามดัดแปลง ถอด หรือปลดล็อกอุปกรณ์นิรภัยของเครื่องจักรทุกชนิด',
          'ห้ามปิดบังหรือละเลยการรายงานอุบัติเหตุและเหตุการณ์เกือบเกิด (Near-Miss)',
        ],
      ),
      ManualChapterModel(
        chapterNumber: 4,
        titleTh: 'การรายงานอุบัติเหตุและหมายเลขติดต่อฉุกเฉิน',
        titleEn: 'Emergency Hotlines & Incident Reporting',
        categoryKey: 'EMERGENCY',
        content: 'หากพบเห็นเพลิงไหม้ สารเคมีหก หรือมีผู้ได้รับบาดเจ็บ ให้ตั้งสติและปฏิบัติตามแผนเผชิญเหตุทันที',
        keyRules: [
          data['emergencyCall'] as String? ?? 'แจ้งศูนย์ควบคุมเหตุฉุกเฉินทันที',
          'เมื่อได้ยินเสียงสัญญาณเตือนภัยอพยพ ให้หยุดเครื่องจักรและเดินไปยังจุดรวมพลทันที',
          'พนักงานมีสิทธิใช้ Stop Work Authority สั่งหยุดงานได้ทันทีหากพบอันตรายร้ายแรง',
        ],
      ),
    ];
  }

  /// สร้างโมเดลใบสรุป 1 หน้าสำหรับปฐมนิเทศพนักงานใหม่และผู้รับเหมา (Tier 3 Induction Leaflet)
  ManualChapterModel buildSafetyInductionLeaflet(
    FactoryScopeModel scope, {
    String companyName = 'สถานประกอบการ',
  }) {
    final data = buildInductionLeafletData(scope, companyName: companyName);
    final List<String> doList = (data['doList'] as List).cast<String>();
    final List<String> dontList = (data['dontList'] as List).cast<String>();

    List<String> combinedRules = [];
    for (final item in doList) {
      combinedRules.add('✓ [ข้อควรปฏิบัติ] $item');
    }
    for (final item in dontList) {
      combinedRules.add('✗ [ข้อห้ามเด็ดขาด] $item');
    }

    return ManualChapterModel(
      chapterNumber: 1,
      titleTh: 'ใบสรุปกฎระเบียบความปลอดภัยสำหรับพนักงานใหม่และผู้รับเหมา',
      titleEn: 'Safety Induction Summary & Tear-off Sign-off Slip',
      categoryKey: 'INDUCTION',
      content: 'ยินดีต้อนรับสู่ $companyName! ความปลอดภัยของท่านและเพื่อนร่วมงานเป็นสิ่งสำคัญที่สุด เอกสารฉบับนี้สรุปกฎระเบียบสำคัญที่ต้องทราบทันทีก่อนเริ่มปฏิบัติงานในพื้นที่ หากมีข้อสงสัยหรือไม่แน่ใจในความปลอดภัย ให้สอบถาม จป. หรือหัวหน้างานทันที',
      keyRules: combinedRules,
    );
  }
}
