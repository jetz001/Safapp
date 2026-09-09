import '../../domain/enums/hazard_type.dart';
import '../../domain/enums/emergency_enums.dart';
import '../models/emergency_plan_model.dart';

class EmergencyPresetsData {
  /// ดึง Preset Template ตามประเภทธุรกิจและประเภทภัย
  static EmergencyPlanModel getPreset({
    required HazardType hazardType,
    required BusinessType businessType,
    String companyName = 'บริษัท ตัวอย่างอุตสาหกรรม จำกัด',
    String companyAddress = '๑๒๓ หมู่ ๔ นิคมอุตสาหกรรมบางปู ต.แพรกษา อ.เมือง จ.สมุทรปราการ',
    int totalEmployees = 120,
    int maleCount = 70,
    int femaleCount = 50,
  }) {
    switch (hazardType) {
      case HazardType.fire:
        return _getFirePreset(
          businessType: businessType,
          companyName: companyName,
          companyAddress: companyAddress,
          totalEmployees: totalEmployees,
          maleCount: maleCount,
          femaleCount: femaleCount,
        );
      case HazardType.chemicalSpill:
        return _getChemicalPreset(
          businessType: businessType,
          companyName: companyName,
          companyAddress: companyAddress,
          totalEmployees: totalEmployees,
          maleCount: maleCount,
          femaleCount: femaleCount,
        );
      case HazardType.flood:
        return _getFloodPreset(
          businessType: businessType,
          companyName: companyName,
          companyAddress: companyAddress,
          totalEmployees: totalEmployees,
          maleCount: maleCount,
          femaleCount: femaleCount,
        );
      case HazardType.earthquake:
        return _getEarthquakePreset(
          businessType: businessType,
          companyName: companyName,
          companyAddress: companyAddress,
          totalEmployees: totalEmployees,
          maleCount: maleCount,
          femaleCount: femaleCount,
        );
      case HazardType.electrical:
        return _getElectricalPreset(
          businessType: businessType,
          companyName: companyName,
          companyAddress: companyAddress,
          totalEmployees: totalEmployees,
          maleCount: maleCount,
          femaleCount: femaleCount,
        );
      case HazardType.custom:
        return _getCustomPreset(
          businessType: businessType,
          companyName: companyName,
          companyAddress: companyAddress,
          totalEmployees: totalEmployees,
          maleCount: maleCount,
          femaleCount: femaleCount,
        );
    }
  }

  static EmergencyPlanModel _getFirePreset({
    required BusinessType businessType,
    required String companyName,
    required String companyAddress,
    required int totalEmployees,
    required int maleCount,
    required int femaleCount,
  }) {
    return EmergencyPlanModel(
      planTitle: 'แผนป้องกันและระงับอัคคีภัยประจำปี (ตามกฎกระทรวงฯ พ.ศ. ๒๕๕๕ ข้อ ๔)',
      hazardType: HazardType.fire,
      businessType: businessType,
      companyName: companyName,
      companyAddress: companyAddress,
      totalEmployees: totalEmployees,
      maleCount: maleCount,
      femaleCount: femaleCount,
      fireCommanderName: 'นายสมศักดิ์ มั่นคง (ผู้จัดการโรงงาน)',
      deputyCommanderName: 'นายประเสริฐ ปลอดภัย (หัวหน้าฝ่ายผลิต)',
      commanderPhone: '081-234-5678',
      version: '2025.1',
      effectiveDate: '2025-01-01',
      reviewDate: '2025-12-31',
      status: PlanStatus.active,
      inspectionPlan: InspectionSubPlan(
        items: [
          InspectionItem(category: 'เครื่องดับเพลิงมือถือ (Portable Extinguishers)', area: 'ทุกอาคารผลิต คลังสินค้า และสำนักงาน', frequency: 'MONTHLY', inspectorRole: 'เจ้าหน้าที่ความปลอดภัย (จป.เทคนิค/วิชาชีพ)'),
          InspectionItem(category: 'ระบบสัญญาณเตือนเพลิงไหม้ (Fire Alarm & Smoke Detector)', area: 'แผงควบคุมหลัก FCP และจุดตรวจจับทุกโซน', frequency: 'MONTHLY', inspectorRole: 'ช่างไฟฟ้าซ่อมบำรุง'),
          InspectionItem(category: 'ปั๊มน้ำดับเพลิง (Fire Pump) และระบบสปริงเกลอร์', area: 'ห้องเครื่องสูบน้ำดับเพลิง', frequency: 'WEEKLY', inspectorRole: 'วิศวกรซ่อมบำรุง'),
          InspectionItem(category: 'เส้นทางหนีไฟ ประตูหนีไฟ และไฟฉุกเฉิน (Emergency Light)', area: 'ทางเดินและบันไดหนีไฟทุกจุด', frequency: 'MONTHLY', inspectorRole: 'ตัวแทน คปอ.'),
          InspectionItem(category: 'ตู้ควบคุมไฟฟ้าหลัก (MDB) และอุปกรณ์ไฟฟ้า', area: 'ห้องควบคุมระบบไฟฟ้าโรงงาน', frequency: 'MONTHLY', inspectorRole: 'ช่างไฟฟ้าที่มีใบอนุญาต'),
        ],
        frequencyDescription: 'ตรวจเช็คเครื่องดับเพลิงและระบบแจ้งเหตุรายเดือน, เดินทดสอบเครื่องสูบน้ำดับเพลิงรายสัปดาห์',
        reportingProcedure: 'บันทึกรายงานผ่านแบบฟอร์มตรวจสอบ ส่งต่อ จป.วิชาชีพ และติดสติ๊กเกอร์ระบุวันที่ตรวจ ณ ตัวถังดับเพลิง',
      ),
      trainingPlan: TrainingSubPlan(
        basicFireQuotaPercent: 40.0,
        annualDrillTargetMonth: 'พฤศจิกายน',
        courses: [
          TrainingCourseItem(courseName: 'การฝึกอบรมการดับเพลิงขั้นต้น (กฎหมายกำหนด >= 40% ของลูกจ้างทุกแผนก)', targetAudience: 'พนักงานใหม่และพนักงานประจำแผนกทุกส่วน', provider: 'หน่วยงานฝึกอบรมที่ขึ้นทะเบียนตามมาตรา ๑๑', frequency: 'ปีละ ๑ ครั้ง หรือทุกครั้งที่มีพนักงานใหม่เข้าทำงาน'),
          TrainingCourseItem(courseName: 'การฝึกซ้อมดับเพลิงและฝึกซ้อมอพยพหนีไฟประจำปี (กฎกระทรวงฯ ข้อ ๓๐)', targetAudience: 'พนักงานทุกคนทุกระดับ ผู้รับเหมา และผู้มาติดต่อ', provider: 'นายจ้างจัดฝึกซ้อมร่วมกับหน่วยงานภายนอก/เทศบาล', frequency: 'อย่างน้อยปีละ ๑ ครั้ง'),
          TrainingCourseItem(courseName: 'การปฐมพยาบาลเบื้องต้นและการช่วยชีวิตขั้นพื้นฐาน (First Aid & CPR/AED)', targetAudience: 'ทีมปฐมพยาบาล และตัวแทน คปอ.', provider: 'สภากาชาดไทย หรือ รพ. เครือข่าย', frequency: 'ปีละ ๑ ครั้ง'),
        ],
      ),
      campaignPlan: CampaignSubPlan(
        activities: [
          'จัดกิจกรรมสัปดาห์ความปลอดภัยและบิ๊กคลีนนิ่งเดย์ (5ส เพื่อลดแหล่งสะสมเชื้อเพลิง)',
          'รณรงค์พื้นที่เขตห้ามสูบบุหรี่เด็ดขาดในโรงงาน และกวดขันจุดสูบบุหรี่ภายนอก',
          'เผยแพร่วิดีโอสาธิตการใช้ถังดับเพลิงชนิดผงเคมีแห้ง/CO2 ทางไลน์กลุ่มพนักงานและจอประชาสัมพันธ์',
          'ติดป้ายเตือนอันตรายและเบอร์โทรฉุกเฉิน 199 ณ ทุกจุดเข้าออก',
        ],
        smokingControlPolicy: 'กำหนดเขตสูบบุหรี่เฉพาะจุดภายนอกอาคาร ห่างจากคลังสินค้าและสารเคมีไม่น้อยกว่า ๑๕ เมตร ฝ่าฝืนมีโทษทางวินัย',
        hotWorkSafetyReminder: 'งานตัดเชื่อม เจียร หรือประกายไฟ ต้องขอใบอนุญาต PTW Hot Work และมีผู้เฝ้าระวังไฟ (Fire Watch) อย่างน้อย 30 นาทีหลังเลิกงาน',
      ),
      suppressionPlan: SuppressionSubPlan(
        initialResponseProtocol: 'พนักงานที่พบเหตุตะโกนบอกเพื่อนร่วมงาน "ไฟไหม้!" ดึงสัญญาณแจ้งเหตุ Fire Alarm แล้วนำถังดับเพลิงใกล้ที่สุดเข้าฉีดสกัดเปลวเพลิงที่ฐานไฟ หากเพลิงลุกลามเกิน ๑ นาที ให้ถอยออกจากพื้นที่ทันที',
        majorEmergencyProtocol: 'ผู้อำนวยการดับเพลิงสั่งเปิดใช้แผนขั้นรุนแรง: 1) สั่งกดสัญญาณอพยพ 2) สั่งทีมควบคุมไฟฟ้าตัดกระแสไฟโซนเกิดเหตุ 3) ติดต่อ 199 และสถานีดับเพลิงในพื้นที่ 4) เคลียร์เส้นทางให้รถดับเพลิงเข้าพื้นที่',
        regularShiftTeam: [
          EmergencyTeamRole(roleTitle: 'ผู้อำนวยการดับเพลิง (Incident Commander)', assignedPerson: 'นายสมศักดิ์ มั่นคง', contactNumber: '081-234-5678', keyDuties: 'สั่งการเปิดใช้แผนระงับเหตุ สั่งอพยพ และประสานงานหน่วยงานราชการภายนอก'),
          EmergencyTeamRole(roleTitle: 'หัวหน้าชุดผจญเพลิงขั้นต้น', assignedPerson: 'นายวิชัย กล้าหาญ', contactNumber: '089-987-6543', keyDuties: 'นำทีมเข้าดับเพลิงขั้นต้นด้วยถังดับเพลิงและสายส่งน้ำดับเพลิงประจำโรงงาน'),
          EmergencyTeamRole(roleTitle: 'ผู้ควบคุมระบบไฟฟ้าและพลังงาน', assignedPerson: 'นายช่างไฟ มีสติ', contactNumber: '086-555-1234', keyDuties: 'ตัดกระแสไฟฟ้าเฉพาะโซนเกิดเหตุ และควบคุมระบบไฟฉุกเฉินให้ทำงานต่อเนื่อง'),
          EmergencyTeamRole(roleTitle: 'ผู้ควบคุมเครื่องสูบน้ำดับเพลิง (Fire Pump)', assignedPerson: 'นายประสิทธิ์ พร้อมรบ', contactNumber: '084-222-3344', keyDuties: 'ตรวจสอบแรงดันน้ำดับเพลิง เดินเครื่องสูบน้ำสำรอง และตรวจเช็ควาล์วจ่ายน้ำ'),
          EmergencyTeamRole(roleTitle: 'ผู้ประสานงานและสื่อสารฉุกเฉิน', assignedPerson: 'น.ส.ดาริกา แจ้งข่าว', contactNumber: '082-111-9988', keyDuties: 'โทรแจ้ง 199, หน่วยกู้ชีพ, ประชาสัมพันธ์เสียงตามสาย และรายงานผู้บริหาร'),
        ],
        offHoursTeam: [
          EmergencyTeamRole(roleTitle: 'ผู้บัญชาการเหตุนอกเวลา (Duty Commander)', assignedPerson: 'หัวหน้ากะ / เจ้าหน้าที่รักษาความปลอดภัยอาวุโส', contactNumber: '02-789-0123 ต่อ 101', keyDuties: 'ประเมินสถานการณ์ สั่งอพยพพนักงานกะดึก และโทรแจ้งผู้อำนวยการดับเพลิงและ 199 ทันที'),
          EmergencyTeamRole(roleTitle: 'รปภ. ประจำป้อมหน้า', assignedPerson: 'เจ้าหน้าที่ รปภ. เวรผลัด', contactNumber: '02-789-0123 ต่อ 100', keyDuties: 'เปิดประตูโรงงาน เคลียร์ช่องทางจราจรนำรถดับเพลิงเข้าจุดเกิดเหตุ'),
        ],
      ),
      evacuationPlan: EvacuationSubPlan(
        alarmSoundSignal: 'สัญญาณเตือนภัยดังต่อเนื่องเกิน ๓๐ วินาที ให้ทุกคนหยุดปฏิบัติงานทันที และอพยพตามป้ายทางออกหนีไฟ',
        assemblyPoints: [
          AssemblyPointItem(pointName: 'จุดรวมพลที่ ๑ (ลานจอดรถหน้าอาคารสำนักงานใหญ่)', location: 'ทิศเหนือ ห่างจากตัวอาคาร ๒๐ เมตร', assignedDepartments: 'ฝ่ายบริหาร, บัญชี, บุคคล, จัดซื้อ, ไอที', capacity: 80),
          AssemblyPointItem(pointName: 'จุดรวมพลที่ ๒ (สนามหญ้าข้างโรงอาหาร)', location: 'ทิศตะวันออก ลมพัดผ่านสะดวก ปลอดภัยจากเปลวเพลิง', assignedDepartments: 'ฝ่ายผลิต 1-2, คลังสินค้า, ซ่อมบำรุง, ควบคุมคุณภาพ', capacity: 150),
        ],
        wardens: [
          EvacuationWarden(areaFloor: 'อาคารสำนักงาน ชั้น 1-2', wardenName: 'น.ส.กานดา เรียบร้อย', deputyWardenName: 'นายธีระ นำทาง'),
          EvacuationWarden(areaFloor: 'โรงงานผลิต สายการผลิต A & B', wardenName: 'นายสนอง สั่งการ', deputyWardenName: 'นายพิทักษ์ ดูแล'),
          EvacuationWarden(areaFloor: 'คลังสินค้าและจุดกระจายสินค้า', wardenName: 'นายวินัย นับยอด', deputyWardenName: 'นายสุเทพ ช่วยเหลือ'),
        ],
        evacuationTeams: [
          EvacuationTeam(
            teamName: 'ทีมผู้นำทางหนีไฟ อาคารสำนักงานใหญ่',
            areaFloor: 'อาคารสำนักงาน ชั้น 1-2',
            leaderName: 'น.ส.กานดา เรียบร้อย (หัวหน้าทีม)',
            deputyLeaderName: 'นายธีระ นำทาง (รองหัวหน้า)',
            members: ['นายวิชาญ ใจมั่น', 'น.ส.รัตนา เกษมสุข', 'นายคมสันต์ มุ่งมั่น'],
            assignedAssemblyPoint: 'จุดรวมพลที่ ๑ (ลานจอดรถหน้าอาคารสำนักงานใหญ่)',
            duties: 'นำทางพนักงานและผู้มาติดต่ออพยพตามบันไดหนีไฟ ตรวจห้องน้ำและห้องประชุม',
          ),
          EvacuationTeam(
            teamName: 'ทีมผู้นำทางหนีไฟ อาคารโรงงานผลิต A-B',
            areaFloor: 'โรงงานผลิต สายการผลิต A & B',
            leaderName: 'นายสนอง สั่งการ (หัวหน้าทีม)',
            deputyLeaderName: 'นายพิทักษ์ ดูแล (รองหัวหน้า)',
            members: ['นายสมควร ขยันยิ่ง', 'นายเดชา แข็งขัน', 'น.ส.มาลี ดอกรัก', 'นายกิตติ เก่งกล้า'],
            assignedAssemblyPoint: 'จุดรวมพลที่ ๒ (สนามหญ้าข้างโรงอาหาร)',
            duties: 'ควบคุมการอพยพพนักงานฝ่ายผลิตตามทางหนีไฟหลัก ป้องกันการวิ่งและเบียดเสียด',
          ),
          EvacuationTeam(
            teamName: 'ทีมผู้นำทางหนีไฟ คลังสินค้าและกระจายสินค้า',
            areaFloor: 'คลังสินค้าและ Loading Dock',
            leaderName: 'นายวินัย นับยอด (หัวหน้าทีม)',
            deputyLeaderName: 'นายสุเทพ ช่วยเหลือ (รองหัวหน้า)',
            members: ['นายฉัตรชัย พาหนะ', 'นายอำนาจ คลังดี', 'นายประยุทธ สินค้า'],
            assignedAssemblyPoint: 'จุดรวมพลที่ ๒ (สนามหญ้าข้างโรงอาหาร)',
            duties: 'เปิดประตู Roll Shutter ทางออกฉุกเฉิน นำคนงานขับโฟล์คลิฟท์อพยพ',
          ),
          EvacuationTeam(
            teamName: 'ทีมตรวจค้นผู้ติดค้างและช่วยเหลือ (Search & Rescue Team)',
            areaFloor: 'ทุกอาคารและจุดอับ',
            leaderName: 'นายธวัช ปลอดภัย (หัวหน้าทีม)',
            deputyLeaderName: 'นายชลิต ใจกล้า (รองหัวหน้า)',
            members: ['นายเอกชัย รวดเร็ว', 'นายบรรจง ทันเหตุ'],
            assignedAssemblyPoint: 'จุดรวมพลที่ ๑',
            duties: 'ตรวจสอบห้องน้ำ ห้องเปลี่ยนเสื้อผ้า ห้องพักพนักงาน เพื่อยืนยันไม่มีผู้ตกค้าง',
          ),
        ],
        headcountMethod: 'ผู้นำทางหนีไฟนำพนักงานเข้าแถวตามแผนก เช็คชื่อตามยอดพนักงานจริง หากพบผู้สูญหายให้รีบแจ้งผู้อำนวยการอพยพทันที ห้ามพนักงานกลับเข้าไปค้นหากันเอง',
      ),
      reliefPlan: ReliefSubPlan(
        governmentContacts: [
          EmergencyContactAgency(agencyName: 'สถานีดับเพลิงและกู้ภัยในพื้นที่ (ศูนย์รวมข่าว 199)', phoneNumber: '199 หรือ 02-395-0111', contactPerson: 'หัวหน้าสถานีดับเพลิงเทศบาล'),
          EmergencyContactAgency(agencyName: 'โรงพยาบาลสมุทรปราการ (ศูนย์กู้ชีพนเรนทร 1669)', phoneNumber: '1669 หรือ 02-701-8132', contactPerson: 'ห้องฉุกเฉิน ER'),
          EmergencyContactAgency(agencyName: 'สถานีตำรวจภูธรพื้นที่', phoneNumber: '191 หรือ 02-387-0010', contactPerson: 'สารวัตรเวรสอบสวน'),
          EmergencyContactAgency(agencyName: 'การไฟฟ้านครหลวง/ส่วนภูมิภาค (กรณีตัดไฟฉุกเฉิน)', phoneNumber: '1130 หรือ 1129', contactPerson: 'ศูนย์บริการข้อมูลไฟฟ้า'),
          EmergencyContactAgency(agencyName: 'สำนักงานสวัสดิการและคุ้มครองแรงงานจังหวัด (ยื่น สปร. ๔)', phoneNumber: '02-395-5678', contactPerson: 'กลุ่มงานมาตรฐานความปลอดภัย'),
        ],
        searchAndRescueProtocol: 'เฉพาะทีมผจญเพลิงภายนอกหรือทีม ERT ที่มีเครื่องช่วยหายใจ SCBA เท่านั้นที่ได้รับอนุญาตให้เข้าค้นหาผู้สูญหายหลังเพลิงสงบ',
        damageAssessmentProtocol: 'แต่งตั้งคณะทำงานร่วมระหว่าง จป.วิชาชีพ วิศวกรโครงสร้าง และบริษัทประกันวินาศภัย เข้าประเมินความเสียหายก่อนเปิดเดินเครื่องจักร',
        businessContinuityProtocol: 'เปิดศูนย์บัญชาการวิกฤต (Crisis Command Center) สำรองข้อมูลระบบคลาวด์ และประสานงานคลังสินค้าพันธมิตรจัดส่งสินค้าทดแทน',
      ),
    );
  }

  static EmergencyPlanModel _getChemicalPreset({
    required BusinessType businessType,
    required String companyName,
    required String companyAddress,
    required int totalEmployees,
    required int maleCount,
    required int femaleCount,
  }) {
    return EmergencyPlanModel(
      planTitle: 'แผนตอบโต้เหตุฉุกเฉินสารเคมีรั่วไหลและวัตถุอันตราย (HAZMAT ERP)',
      hazardType: HazardType.chemicalSpill,
      businessType: businessType,
      companyName: companyName,
      companyAddress: companyAddress,
      totalEmployees: totalEmployees,
      maleCount: maleCount,
      femaleCount: femaleCount,
      fireCommanderName: 'ดร.ชาญวิทย์ เชี่ยวสาร (ผู้จัดการฝ่ายเคมีและความปลอดภัย)',
      deputyCommanderName: 'นายอนุชา พิทักษ์ (หัวหน้าทีมตอบโต้สารเคมี ERT)',
      commanderPhone: '089-111-2233',
      version: '2025.1',
      effectiveDate: '2025-01-01',
      reviewDate: '2025-12-31',
      status: PlanStatus.active,
      inspectionPlan: InspectionSubPlan(
        items: [
          InspectionItem(category: 'ชุด Spill Kit (ทรายดูดซับ, บูมกั้น, แผ่นซับสารเคมี)', area: 'พื้นที่จัดเก็บสารเคมีและจุดขนถ่ายทุกจุด', frequency: 'WEEKLY', inspectorRole: 'เจ้าหน้าที่ควบคุมสารเคมีอันตราย'),
          InspectionItem(category: 'ฝักบัวและอ่างล้างตาฉุกเฉิน (Emergency Eyewash & Shower)', area: 'ห้องผสมสารเคมีและห้องแล็บ', frequency: 'WEEKLY', inspectorRole: 'ตัวแทน คปอ.'),
          InspectionItem(category: 'อุปกรณ์ PPE ป้องกันสารเคมี (ชุด Level B/C, หน้ากากไส้กรอง)', area: 'ตู้เก็บอุปกรณ์ฉุกเฉิน ERT', frequency: 'MONTHLY', inspectorRole: 'จป.วิชาชีพ'),
          InspectionItem(category: 'บ่อกักเก็บสารเคมีสำรอง (Bund / Containment Dike)', area: 'คลังเก็บถังสารเคมี 200 ลิตร', frequency: 'MONTHLY', inspectorRole: 'วิศวกรซ่อมบำรุง'),
        ],
        frequencyDescription: 'ตรวจสอบชุด Spill Kit และที่ล้างตาฉุกเฉินทุกสัปดาห์, ตรวจบ่อกักกันสารเคมีทุกเดือน',
        reportingProcedure: 'บันทึกผ่านระบบ Safety Inspection App หากอุปกรณ์ไม่พร้อมใช้งานต้องทดแทนภายใน 24 ชั่วโมง',
      ),
      trainingPlan: TrainingSubPlan(
        basicFireQuotaPercent: 40.0,
        annualDrillTargetMonth: 'สิงหาคม',
        courses: [
          TrainingCourseItem(courseName: 'หลักสูตรการปฏิบัติงานกับสารเคมีอันตรายอย่างปลอดภัยและ SDS (กฎกระทรวงฯ ๒๕๕๖)', targetAudience: 'ผู้ปฏิบัติงานสัมผัสสารเคมีทุกคน', provider: 'วิทยากรที่ขึ้นทะเบียนกรมโรงงานฯ', frequency: 'ปีละ ๑ ครั้ง'),
          TrainingCourseItem(courseName: 'การระงับเหตุสารเคมีรั่วไหลขั้นต้นด้วย Spill Kit', targetAudience: 'พนักงานฝ่ายผลิตและคลังสินค้า', provider: 'จป.วิชาชีพ', frequency: 'ปีละ ๑ ครั้ง'),
          TrainingCourseItem(courseName: 'การฝึกซ้อมแผนระงับเหตุสารเคมีรั่วไหลและอพยพเหนือลม (ERG)', targetAudience: 'พนักงานทุกคนในโซนสารเคมีและทีม ERT', provider: 'สถานประกอบการจัดร่วมกับหน่วยตอบโต้สารเคมี', frequency: 'ปีละ ๑ ครั้ง'),
        ],
      ),
      campaignPlan: CampaignSubPlan(
        activities: [
          'ติดป้ายสัญลักษณ์ GHS และข้อมูลสรุป SDS หน้าห้องเก็บสารเคมีทุกชนิด',
          'แจกเอกสารแนะนำระยะอพยพเหนือลมและจุดรวมพลปลอดภัยจากไอระเหย',
          'ซ้อมสวมใส่หน้ากากป้องกันสารเคมีและชุด PPE ในช่วง Safe Talk ประจำเดือน',
        ],
        smokingControlPolicy: 'ห้ามสูบบุหรี่และห้ามก่อประกายไฟในรัศมี ๓๐ เมตร จากคลังสารเคมีไวไฟ',
        hotWorkSafetyReminder: 'ห้ามทำงาน Hot Work ในห้องเก็บสารเคมีเว้นแต่ระบายไอระเหยจน LEL = 0% และได้รับอนุมัติ PTW',
      ),
      suppressionPlan: SuppressionSubPlan(
        initialResponseProtocol: 'หากรั่วไหลปริมาณเล็กน้อย (< 20 ลิตร): สวม PPE ดึงชุด Spill Kit ใช้บูมกั้นล้อมรอบ เทสารดูดซับ กวาดใส่ถุงขยะอันตราย หากรั่วไหลรุนแรงหรือมีแก๊สพิษ: ให้ถอยหนีเหนือลมและกดสัญญาณเตือนทันที',
        majorEmergencyProtocol: 'ผู้อำนวยการสั่งใช้แผนฉุกเฉินสารเคมี: อพยพพนักงานไปจุดรวมพลเหนือลม (Upwind), สั่งทีม ERT สวมชุด SCBA เข้าปิดวาล์วหลัก, ประสานศูนย์กักกันสารเคมีและแจ้งสายด่วน 1650 กรมควบคุมมลพิษ',
        regularShiftTeam: [
          EmergencyTeamRole(roleTitle: 'ผู้อำนวยการระงับเหตุสารเคมี (HAZMAT Commander)', assignedPerson: 'ดร.ชาญวิทย์ เชี่ยวสาร', contactNumber: '089-111-2233', keyDuties: 'เปิดดู SDS ประเมินระยะปลอดภัย ERG สั่งอพยพเหนือลม และควบคุมสถานการณ์'),
          EmergencyTeamRole(roleTitle: 'หัวหน้าทีม ERT เข้าเผชิญเหตุ', assignedPerson: 'นายอนุชา พิทักษ์', contactNumber: '087-654-3210', keyDuties: 'นำทีม 2 นาย สวม SCBA เข้าปิดวาล์วและวางแนวดูดซับสารเคมี'),
          EmergencyTeamRole(roleTitle: 'เจ้าหน้าที่ตรวจวัดไอระเหยสารเคมี', assignedPerson: 'น.ส.วิไลลักษณ์ ตรวจวัด', contactNumber: '086-789-0123', keyDuties: 'ใช้เครื่อง Gas Detector ตรวจวัดค่าไอระเหยและทิศทางลม (Wind Direction)'),
        ],
        offHoursTeam: [
          EmergencyTeamRole(roleTitle: 'หัวหน้าเวรนอกเวลา', assignedPerson: 'หัวหน้าแผนกผลิตกะดึก', contactNumber: '081-999-8888', keyDuties: 'สั่งหยุดสายการผลิต สั่งพนักงานอพยพเหนือลม และโทรประสาน จป. ทันที'),
        ],
      ),
      evacuationPlan: EvacuationSubPlan(
        alarmSoundSignal: 'สัญญาณเตือนภัยเสียงหวูดเป็นจังหวะ ๓ ครั้งติดต่อกัน บ่งชี้ให้อพยพในทิศทางเหนือลมเท่านั้น',
        assemblyPoints: [
          AssemblyPointItem(pointName: 'จุดรวมพลเหนือลมที่ ๑ (ทิศตะวันออกเฉียงเหนือ)', location: 'ลานกว้างด้านหน้าประตู ๑ (สังเกตถุงลมบอกทิศทาง Wind Sock)', assignedDepartments: 'ทุกแผนก', capacity: 150),
        ],
        wardens: [
          EvacuationWarden(areaFloor: 'โซนผสมสารเคมีและคลังสินค้า', wardenName: 'นายพิทักษ์ ปลอดภัย', deputyWardenName: 'นายระวัง รอบคอบ'),
        ],
        evacuationTeams: [
          EvacuationTeam(
            teamName: 'ทีมผู้นำทางหนีไฟและอพยพเหนือลม โซนสารเคมี',
            areaFloor: 'โซนผสมสารเคมีและคลังสินค้า',
            leaderName: 'นายพิทักษ์ ปลอดภัย (หัวหน้าทีม)',
            deputyLeaderName: 'นายระวัง รอบคอบ (รองหัวหน้า)',
            members: ['นายสมคิด ยึดมั่น', 'น.ส.นภา แจ้งเตือน', 'นายศิลา รอบรู้'],
            assignedAssemblyPoint: 'จุดรวมพลเหนือลมที่ ๑ (ทิศตะวันออกเฉียงเหนือ)',
            duties: 'สังเกต Wind Sock นำพนักงานอพยพขวางหรือเหนือทิศทางลม ห้ามเดินตามควัน/ไอระเหย',
          ),
          EvacuationTeam(
            teamName: 'ทีมปฐมพยาบาลและล้างตัวสารเคมี (Decontamination Team)',
            areaFloor: 'จุดล้างตัวฉุกเฉิน Emergency Shower & Eyewash',
            leaderName: 'น.ส.พยาบาล ใจการุณ (หัวหน้าทีม)',
            deputyLeaderName: 'นายช่วยเหลือ ปลอดภัย (รองหัวหน้า)',
            members: ['น.ส.อารี มีเมตตา', 'นายพิทักษ์ ชีวิน'],
            assignedAssemblyPoint: 'จุดรวมพลเหนือลมที่ ๑',
            duties: 'ช่วยเหลือผู้ถูกสารเคมีชำระล้างอย่างน้อย 15 นาที และประสานส่งต่อโรงพยาบาล',
          ),
        ],
        headcountMethod: 'ตรวจเช็คยอดพนักงาน ณ จุดรวมพลเหนือลม สังเกตอาการผิดปกติ เช่น ระคายเคืองตา หายใจติดขัด เพื่อส่งหน่วยพยาบาลทันที',
      ),
      reliefPlan: ReliefSubPlan(
        governmentContacts: [
          EmergencyContactAgency(agencyName: 'สายด่วนกรมควบคุมมลพิษ (อุบัติภัยสารเคมี)', phoneNumber: '1650', contactPerson: 'ศูนย์ปฏิบัติการฉุกเฉินสารเคมี'),
          EmergencyContactAgency(agencyName: 'สถานีดับเพลิงและกู้ภัยเคมี (199)', phoneNumber: '199', contactPerson: 'ทีมระงับเหตุสารเคมี'),
          EmergencyContactAgency(agencyName: 'ศูนย์พิษวิทยารามาธิบดี (ข้อมูลการรักษาพิษ)', phoneNumber: '1367', contactPerson: 'แพทย์เวรพิษวิทยา'),
          EmergencyContactAgency(agencyName: 'กรมโรงงานอุตสาหกรรม (กองบริหารจัดการวัตถุอันตราย)', phoneNumber: '02-202-4000', contactPerson: 'สายด่วนอุบัติภัยโรงงาน'),
        ],
        searchAndRescueProtocol: 'ทีมกู้ภัยต้องสวมชุด Level B ขึ้นไปในการเข้ากู้ชีพผู้หมดสติจากไอสารเคมี',
        damageAssessmentProtocol: 'เก็บตัวอย่างอากาศและน้ำเสียส่งตรวจวิเคราะห์มาตรฐานก่อนปล่อยระบายลงสู่ระบบบำบัดน้ำเสีย',
        businessContinuityProtocol: 'กำจัดกากสารเคมีที่ปนเปื้อนผ่านบริษัทรับบำบัดที่ถูกต้องตามกฎหมาย และฟื้นฟูพื้นที่',
      ),
    );
  }

  static EmergencyPlanModel _getFloodPreset({
    required BusinessType businessType,
    required String companyName,
    required String companyAddress,
    required int totalEmployees,
    required int maleCount,
    required int femaleCount,
  }) {
    return EmergencyPlanModel(
      planTitle: 'แผนเตรียมความพร้อมและป้องกันอุทกภัย (Flood Emergency Response Plan)',
      hazardType: HazardType.flood,
      businessType: businessType,
      companyName: companyName,
      companyAddress: companyAddress,
      totalEmployees: totalEmployees,
      maleCount: maleCount,
      femaleCount: femaleCount,
      fireCommanderName: 'นายวารินทร์ กั้นน้ำ (ผู้จัดการฝ่ายวิศวกรรม)',
      deputyCommanderName: 'นายชลธาร เฝ้าระวัง (หัวหน้างานอาคารสถานที่)',
      commanderPhone: '083-456-7890',
      version: '2025.1',
      effectiveDate: '2025-01-01',
      reviewDate: '2025-12-31',
      status: PlanStatus.active,
      inspectionPlan: InspectionSubPlan(
        items: [
          InspectionItem(category: 'เขื่อนกั้นน้ำ/แนวกระสอบทราย/แผง Flood Barrier', area: 'ประตูทางเข้าออกและรอบรั้วโรงงาน', frequency: 'WEEKLY', inspectorRole: 'ทีมงานอาคารสถานที่'),
          InspectionItem(category: 'เครื่องสูบน้ำระบายน้ำท่วมและน้ำมันเชื้อเพลิงสำรอง', area: 'สถานีสูบน้ำประจำโรงงาน', frequency: 'WEEKLY', inspectorRole: 'ช่างซ่อมบำรุง'),
          InspectionItem(category: 'ท่อระบายน้ำ รางระบายน้ำรอบพื้นที่', area: 'รอบอาคารและแนวถนน', frequency: 'MONTHLY', inspectorRole: 'เจ้าหน้าที่สิ่งแวดล้อม'),
        ],
        frequencyDescription: 'เฝ้าระวังระดับน้ำทุกวันช่วงฤดูฝน ตรวจสอบปั๊มสูบน้ำและกระสอบทรายทุกสัปดาห์',
        reportingProcedure: 'รายงานระดับน้ำและระดับความพร้อมต่อผู้บริหารผ่านไลน์กลุ่มทุกเช้า',
      ),
      trainingPlan: TrainingSubPlan(
        basicFireQuotaPercent: 40.0,
        annualDrillTargetMonth: 'กันยายน',
        courses: [
          TrainingCourseItem(courseName: 'การฝึกซ้อมยกย้ายเครื่องจักรและทรัพย์สินขึ้นที่สูง', targetAudience: 'ทีมซ่อมบำรุงและฝ่ายคลังสินค้า', provider: 'วิศวกรโรงงาน', frequency: 'ปีละ ๑ ครั้ง ก่อนฤดูน้ำหลาก'),
          TrainingCourseItem(courseName: 'ความปลอดภัยจากไฟฟ้าดูดในภาวะน้ำท่วม (Electrical Safety during Flood)', targetAudience: 'พนักงานทุกคน', provider: 'จป.วิชาชีพ', frequency: 'ปีละ ๑ ครั้ง'),
        ],
      ),
      campaignPlan: CampaignSubPlan(
        activities: [
          'จัดเตรียมจุดจอดรถและเส้นทางเดินทางสำรองกรณีน้ำท่วมถนนหน้าโรงงาน',
          'รณรงค์เคลียร์ขยะอุดตันท่อระบายน้ำและปิดฝาบ่อพักน้ำให้มิดชิด',
        ],
        smokingControlPolicy: 'ดูแลจุดสูบบุหรี่ไม่ให้ถูกน้ำท่วมขัง',
        hotWorkSafetyReminder: 'ระมัดระวังความชื้นและน้ำท่วมขังขณะใช้อุปกรณ์ไฟฟ้า',
      ),
      suppressionPlan: SuppressionSubPlan(
        initialResponseProtocol: 'เมื่อระดับน้ำแตะระดับเตือนภัยระดับ ๑: ยกอุปกรณ์ขึ้นชั้น 2 สั่งเดินเครื่องสูบน้ำ และตั้งแผงกั้นน้ำทันที',
        majorEmergencyProtocol: 'ระดับน้ำแตะระดับ ๓ (วิกฤต): ผู้อำนวยการสั่งตัดกระแสไฟฟ้าหลัก อพยพพนักงานออกจากพื้นที่โรงงานโดยใช้รถยกสูงหรือเรือยาง',
        regularShiftTeam: [
          EmergencyTeamRole(roleTitle: 'ผู้อำนวยการป้องกันน้ำท่วม', assignedPerson: 'นายวารินทร์ กั้นน้ำ', contactNumber: '083-456-7890', keyDuties: 'ติดตามประกาศเตือนภัยจากกรมอุตุนิยมวิทยา สั่งการยกของขึ้นที่สูง และสั่งหยุดงาน'),
          EmergencyTeamRole(roleTitle: 'ผู้ควบคุมระบบตัดไฟฟ้ากรณีน้ำท่วม', assignedPerson: 'นายช่างไฟ มั่นใจ', contactNumber: '081-111-3333', keyDuties: 'ตัดไฟเบรกเกอร์ชั้น 1 ทันทีที่น้ำเริ่มเข้าอาคาร'),
        ],
        offHoursTeam: [],
      ),
      evacuationPlan: EvacuationSubPlan(
        alarmSoundSignal: 'ประกาศเสียงตามสายให้เดินทางกลับบ้านก่อนน้ำท่วมสูง หรืออพยพขึ้นชั้น 2 ของอาคารสำนักงาน',
        assemblyPoints: [
          AssemblyPointItem(pointName: 'จุดรวมพลชั้น ๒ อาคารสำนักงานใหญ่', location: 'ห้องประชุมใหญ่ ชั้น 2', assignedDepartments: 'ทุกคนที่ยังอยู่ในพื้นที่', capacity: 200),
        ],
        wardens: [],
        evacuationTeams: [
          EvacuationTeam(
            teamName: 'ทีมเคลื่อนย้ายและอพยพผู้ประสบภัยน้ำท่วม',
            areaFloor: 'พื้นที่ลุ่มต่ำ ชั้น 1',
            leaderName: 'นายช่วย พ้นน้ำ (หัวหน้าทีม)',
            deputyLeaderName: 'นายชูชีพ ปลอดภัย (รองหัวหน้า)',
            members: ['นายว่ายน้ำ คล่อง', 'นายเรือ พร้อม'],
            assignedAssemblyPoint: 'จุดรวมพลชั้น ๒ อาคารสำนักงานใหญ่',
            duties: 'นำพนักงานขึ้นที่สูง ตัดกระแสไฟฟ้าโซนน้ำท่วม และช่วยลำเลียงผู้ป่วย/ผู้บาดเจ็บ',
          ),
        ],
        headcountMethod: 'นับยอดพนักงานและตรวจสอบความปลอดภัยในการเดินทางกลับที่พักของพนักงานทุกคน',
      ),
      reliefPlan: ReliefSubPlan(
        governmentContacts: [
          EmergencyContactAgency(agencyName: 'กรมป้องกันและบรรเทาสาธารณภัย (สายด่วนนิรภัย 1784)', phoneNumber: '1784', contactPerson: 'ศูนย์เตือนภัย ปภ.'),
          EmergencyContactAgency(agencyName: 'สายด่วนกรมชลประทาน', phoneNumber: '1460', contactPerson: 'ศูนย์ประมวลวิเคราะห์สถานการณ์น้ำ'),
        ],
        searchAndRescueProtocol: 'ประสานงานเรือกู้ภัย ปภ. เข้าช่วยเหลือพนักงานที่ติดค้าง',
        damageAssessmentProtocol: 'ตรวจสอบระบบไฟฟ้า เครื่องจักร และทำความสะอาดคราบโคลนหลังน้ำลด',
        businessContinuityProtocol: 'เปิดแผน Work From Home และกระจายงานผลิตไปยังสาขาที่ไม่ถูกน้ำท่วม',
      ),
    );
  }

  static EmergencyPlanModel _getEarthquakePreset({
    required BusinessType businessType,
    required String companyName,
    required String companyAddress,
    required int totalEmployees,
    required int maleCount,
    required int femaleCount,
  }) {
    return EmergencyPlanModel(
      planTitle: 'แผนเผชิญเหตุแผ่นดินไหวและอาคารถล่ม (Earthquake Response Plan)',
      hazardType: HazardType.earthquake,
      businessType: businessType,
      companyName: companyName,
      companyAddress: companyAddress,
      totalEmployees: totalEmployees,
      maleCount: maleCount,
      femaleCount: femaleCount,
      fireCommanderName: 'นายธรณี มั่นคง (ผู้จัดการอาคาร)',
      deputyCommanderName: 'นายโครงสร้าง แข็งแรง (วิศวกรโยธา)',
      commanderPhone: '085-678-9012',
      version: '2025.1',
      effectiveDate: '2025-01-01',
      reviewDate: '2025-12-31',
      status: PlanStatus.active,
      inspectionPlan: InspectionSubPlan(
        items: [
          InspectionItem(category: 'โครงสร้างเสา คาน ผนัง และรอยร้าวอาคาร', area: 'ทุกชั้นของอาคาร', frequency: 'MONTHLY', inspectorRole: 'วิศวกรโยธา/ผู้ตรวจสอบอาคาร'),
          InspectionItem(category: 'การยึดติดของชั้นวางสินค้า (Rack) และตู้เอกสารสูง', area: 'คลังสินค้าและสำนักงาน', frequency: 'MONTHLY', inspectorRole: 'จป.วิชาชีพ'),
        ],
        frequencyDescription: 'ตรวจสอบความมั่นคงของโครงสร้างอาคารและจุดยึดโยงสิ่งของแขวนลอยรายเดือน',
        reportingProcedure: 'บันทึกรายงานความสมบูรณ์ของโครงสร้างอาคาร',
      ),
      trainingPlan: TrainingSubPlan(
        basicFireQuotaPercent: 40.0,
        annualDrillTargetMonth: 'มีนาคม',
        courses: [
          TrainingCourseItem(courseName: 'หลักสูตร "หมอบ กำบัง ยึดเกาะ" (Drop, Cover, Hold On)', targetAudience: 'พนักงานทุกคน', provider: 'จป.วิชาชีพ', frequency: 'ปีละ ๑ ครั้ง'),
          TrainingCourseItem(courseName: 'การเอาชีวิตรอดและการอพยพจากอาคารสูงเมื่อเกิดแผ่นดินไหว', targetAudience: 'พนักงานบนอาคารสำนักงาน', provider: 'วิทยากร ปภ.', frequency: 'ปีละ ๑ ครั้ง'),
        ],
      ),
      campaignPlan: CampaignSubPlan(
        activities: [
          'ติดสติกเกอร์คำแนะนำ "หมอบใต้โต๊ะ กำบัง ยึดแน่น" ตามโต๊ะทำงานทุกโต๊ะ',
          'รณรงค์อย่าวางสิ่งของหนักไว้บนที่สูงหรือหลังตู้',
        ],
        smokingControlPolicy: 'ห้ามสูบบุหรี่ขณะเกิดแผ่นดินไหวเพื่อป้องกันก๊าซรั่วระเบิด',
        hotWorkSafetyReminder: 'หยุดงาน Hot Work ทันทีที่รู้สึกถึงแรงสั่นสะเทือน',
      ),
      suppressionPlan: SuppressionSubPlan(
        initialResponseProtocol: 'ขณะแผ่นดินไหว: หมอบ กำบัง ยึดเกาะ อย่าวิ่งออกนอกอาคารทันที ระวังสิ่งของร่วงหล่น ห้ามใช้ลิฟต์เด็ดขาด',
        majorEmergencyProtocol: 'เมื่อการสั่นสะเทือนสงบ: ปิดวาล์วก๊าซ ตัดกระแสไฟ อพยพทุกคนออกทางบันไดหนีไฟไปยังลานโล่งแจ้ง ตรวจสอบรอยแตกร้าวของอาคารก่อนอนุญาตให้กลับเข้าพื้นที่',
        regularShiftTeam: [
          EmergencyTeamRole(roleTitle: 'ผู้อำนวยการเหตุฉุกเฉินแผ่นดินไหว', assignedPerson: 'นายธรณี มั่นคง', contactNumber: '085-678-9012', keyDuties: 'สั่งการอพยพเมื่อแรงสั่นสะเทือนสงบ และประสานวิศวกรตรวจอาคาร'),
        ],
        offHoursTeam: [],
      ),
      evacuationPlan: EvacuationSubPlan(
        alarmSoundSignal: 'สัญญาณเตือนภัยหรือคำสั่งอพยพหลังแรงสั่นสะเทือนระงับ',
        assemblyPoints: [
          AssemblyPointItem(pointName: 'ลานกว้างโล่งแจ้งกลางแจ้ง (ห่างจากสายไฟและตัวอาคาร)', location: 'สนามฟุตบอลหรือลานจอดรถโล่ง', assignedDepartments: 'ทุกคนในอาคาร', capacity: 300),
        ],
        wardens: [],
        evacuationTeams: [
          EvacuationTeam(
            teamName: 'ทีมผู้นำทางอพยพอาคารสูง (Earthquake Wardens)',
            areaFloor: 'อาคารทุกชั้น',
            leaderName: 'นายนำทาง รวดเร็ว (หัวหน้าทีม)',
            deputyLeaderName: 'นายระวัง กระจก (รองหัวหน้า)',
            members: ['นายสติ มั่นคง', 'น.ส.รอบคอบ ช่วยเหลือ'],
            assignedAssemblyPoint: 'ลานกว้างโล่งแจ้งกลางแจ้ง (ห่างจากสายไฟและตัวอาคาร)',
            duties: 'นำทางพนักงานลงบันไดหนีไฟ ห้ามใช้ลิฟต์เด็ดขาด คอยเตือนระวังเศษกระจกตกใส่',
          ),
        ],
        headcountMethod: 'นับยอดพนักงาน ตรวจเช็คผู้ได้รับบาดเจ็บจากเศษกระจกหรือสิ่งของตกใส่',
      ),
      reliefPlan: ReliefSubPlan(
        governmentContacts: [
          EmergencyContactAgency(agencyName: 'กองเฝ้าระวังแผ่นดินไหว กรมอุตุนิยมวิทยา', phoneNumber: '02-399-4547', contactPerson: 'สายด่วนแผ่นดินไหว'),
          EmergencyContactAgency(agencyName: 'ศูนย์เอราวัณ / กู้ชีพ 1669', phoneNumber: '1669', contactPerson: 'ศูนย์ส่งต่อผู้ป่วย'),
        ],
        searchAndRescueProtocol: 'ประสานทีม USAR กู้ภัยอาคารถล่มเข้าตรวจสอบผู้ติดค้าง',
        damageAssessmentProtocol: 'วิศวกรโครงสร้างประเมินอาคารปลอดภัย (ติดป้ายเขียว/เหลือง/แดง)',
        businessContinuityProtocol: 'แผนกู้คืนระบบและประเมินความพร้อมก่อนเปิดอาคาร',
      ),
    );
  }

  static EmergencyPlanModel _getElectricalPreset({
    required BusinessType businessType,
    required String companyName,
    required String companyAddress,
    required int totalEmployees,
    required int maleCount,
    required int femaleCount,
  }) {
    return EmergencyPlanModel(
      planTitle: 'แผนตอบโต้ภาวะฉุกเฉินและระงับอุบัติภัยจากระบบไฟฟ้า (Electrical Emergency Response Plan)',
      hazardType: HazardType.electrical,
      businessType: businessType,
      companyName: companyName,
      companyAddress: companyAddress,
      totalEmployees: totalEmployees,
      maleCount: maleCount,
      femaleCount: femaleCount,
      fireCommanderName: 'ผู้จัดการฝ่ายวิศวกรรมและซ่อมบำรุง',
      deputyCommanderName: 'หัวหน้างานไฟฟ้าอาวุโส / จป.วิชาชีพ',
      commanderPhone: '081-999-8888',
      version: '2025.1',
      effectiveDate: '2025-01-01',
      reviewDate: '2025-12-31',
      status: PlanStatus.active,
      inspectionPlan: const InspectionSubPlan(
        items: [
          InspectionItem(
            category: 'ตู้สวิตช์บอร์ดหลัก (MDB) และตู้ควบคุมย่อย (DB/PB)',
            area: 'ห้องควบคุมระบบไฟฟ้าหลัก และทุกอาคารผลิต',
            frequency: 'MONTHLY',
            inspectorRole: 'ช่างไฟฟ้าซ่อมบำรุงประจำโรงงาน',
          ),
          InspectionItem(
            category: 'การตรวจสอบและรับรองระบบไฟฟ้าประจำปี (แบบ ๕๖๒๘๙)',
            area: 'ระบบไฟฟ้าและบริภัณฑ์ไฟฟ้าทั่วทั้งสถานประกอบกิจการ',
            frequency: 'ANNUALLY',
            inspectorRole: 'วิศวกรไฟฟ้า กว. / นิติบุคคลขึ้นทะเบียน ม.๑๑',
          ),
          InspectionItem(
            category: 'การตรวจวัดค่าความต้านทานการต่อลงดิน (Grounding <= 5 โอห์ม)',
            area: 'หลักดินหม้อแปลง, ล่อฟ้า, และตู้ MDB',
            frequency: 'ANNUALLY',
            inspectorRole: 'วิศวกรผู้ทดสอบระบบไฟฟ้า',
          ),
          InspectionItem(
            category: 'การตรวจวัดความร้อนอินฟราเรด (Thermo-scan)',
            area: 'จุดต่อสาย ขั้วต่อเบรกเกอร์ บัสบาร์ในตู้ MDB ทุกตู้',
            frequency: 'ANNUALLY',
            inspectorRole: 'หน่วยงานผู้เชี่ยวชาญเทอร์โมสแกน',
          ),
          InspectionItem(
            category: 'หม้อแปลงไฟฟ้า สารดูดความชื้น และระดับน้ำมัน',
            area: 'ลานหม้อแปลงไฟฟ้าแรงสูง',
            frequency: 'MONTHLY',
            inspectorRole: 'ช่างไฟฟ้าและวิศวกรซ่อมบำรุง',
          ),
        ],
        frequencyDescription: 'ตรวจเช็คประจำเดือนโดยช่างไฟฟ้า และตรวจรับรองประจำปีตามกฎกระทรวงฯ ข้อ ๑๒',
        reportingProcedure: 'บันทึกผลลงใน แบบ ๕๖๒๘๙ พร้อมแนบรายงาน Thermo-scan และสำเนาใบ กว. เก็บไว้ให้พนักงานตรวจความปลอดภัยตรวจสอบ',
      ),
      trainingPlan: const TrainingSubPlan(
        basicFireQuotaPercent: 100.0,
        annualDrillTargetMonth: 'สิงหาคม',
        courses: [
          TrainingCourseItem(
            courseName: 'ความปลอดภัยในการทำงานเกี่ยวกับไฟฟ้าสำหรับผู้ปฏิบัติงานและลูกจ้างทั่วไป',
            targetAudience: 'พนักงานผู้ปฏิบัติงานเกี่ยวกับไฟฟ้าและลูกจ้างทุกคน',
            provider: 'หน่วยงานฝึกอบรมที่ขึ้นทะเบียนตามมาตรา ๑๑ / จป.วิชาชีพ',
            frequency: 'ปีละ ๑ ครั้ง',
          ),
          TrainingCourseItem(
            courseName: 'การปฐมพยาบาลช่วยชีวิต CPR และการใช้เครื่อง AED สำหรับผู้ประสบภัยไฟฟ้าดูด',
            targetAudience: 'ทีมปฐมพยาบาล ช่างไฟฟ้า และตัวแทนฝ่ายผลิต',
            provider: 'สภากาชาดไทย หรือ รพ. เครือข่าย',
            frequency: 'ปีละ ๑ ครั้ง',
          ),
          TrainingCourseItem(
            courseName: 'ขั้นตอนการตัดแยกแหล่งพลังงานไฟฟ้า Lockout / Tagout (LOTO)',
            targetAudience: 'ช่างซ่อมบำรุง ช่างไฟฟ้า และผู้ควบคุมเครื่องจักร',
            provider: 'วิศวกรไฟฟ้าโรงงาน / ผู้เชี่ยวชาญ LOTO',
            frequency: 'ปีละ ๑ ครั้ง',
          ),
        ],
      ),
      campaignPlan: const CampaignSubPlan(
        activities: [
          'รณรงค์ 4 ขั้นตอนช่วยคนถูกไฟฟ้าดูด: "อย่าแตะตัวโดยตรง - ตัดกระแสไฟ - ใช้ฉนวนเขี่ยออก - โทร 1669 / ทำ CPR"',
          'ติดป้ายเตือนอันตรายไฟฟ้าแรงสูง ป้ายผังตู้ไฟฟ้า และป้ายพื้นที่หวงห้ามห้องหม้อแปลง/MDB',
          'เผยแพร่ Safety Alert กรณีสายไฟชำรุด เต้าเสียบชำรุด และการห้ามใช้อุปกรณ์ดัดแปลง',
        ],
        smokingControlPolicy: 'ห้ามสูบบุหรี่หรือทำให้เกิดประกายไฟในห้องควบคุมไฟฟ้า MDB และบริเวณสถานีหม้อแปลงเด็ดขาด',
        hotWorkSafetyReminder: 'งานตัดเชื่อมหรือใกล้แนวสายไฟฟ้าแรงสูง ต้องตรวจสอบระยะห่างปลอดภัยและดับกระแสไฟก่อนเริ่มงาน',
      ),
      suppressionPlan: const SuppressionSubPlan(
        initialResponseProtocol: 'ระดับ ๑ (บุคคลถูกไฟฟ้าดูด): สับสวิตช์ตัดกระแสไฟทันที หรือใช้ไม้ยึดฉนวน (Rescue Hook) ดึงผู้ป่วยออก ห้ามแตะตัวโดยตรง โทร 1669 ประเมินสติ/หายใจ และเริ่ม CPR/AED ทันที',
        majorEmergencyProtocol: 'ระดับ ๒-๓ (ไฟฟ้าลัดวงจร/ไฟไหม้ตู้ MDB/หม้อแปลง): ปลดเบรกเกอร์ประธาน (Main CB) ทันที ใช้ถังดับเพลิงคลาส C ห้ามใช้น้ำเด็ดขาดหากยังไม่ยืนยันการตัดไฟสมบูรณ์ สับสวิตช์เครื่องกำเนิดไฟฟ้าสำรอง และประสาน กฟน./กฟภ. 199',
        regularShiftTeam: [
          EmergencyTeamRole(
            roleTitle: 'ผู้บัญชาการเหตุฉุกเฉินระบบไฟฟ้า',
            assignedPerson: 'ผู้จัดการฝ่ายวิศวกรรมและซ่อมบำรุง',
            contactNumber: '081-999-8888',
            keyDuties: 'สั่งการตัดกระแสไฟหลัก ควบคุมการอพยพ และประสานการไฟฟ้า',
          ),
          EmergencyTeamRole(
            roleTitle: 'ทีมช่างไฟฟ้าตัดตอนวงจร (Isolation)',
            assignedPerson: 'วิศวกรไฟฟ้าอาวุโส / ช่างไฟฟ้าเวร',
            contactNumber: '081-111-2222',
            keyDuties: 'ปลด Main CB ยืนยัน Zero Energy และควบคุม Generator สำรอง',
          ),
          EmergencyTeamRole(
            roleTitle: 'ทีมปฐมพยาบาลและกู้ชีพ CPR/AED',
            assignedPerson: 'พยาบาลวิชาชีพ / ทีมปฐมพยาบาล',
            contactNumber: '081-333-4444',
            keyDuties: 'ปฏิบัติการ CPR และใช้เครื่อง AED ช่วยเหลือผู้ถูกไฟดูด',
          ),
        ],
        offHoursTeam: [
          EmergencyTeamRole(
            roleTitle: 'ผู้ควบคุมเหตุนอกเวลา (Duty Engineer)',
            assignedPerson: 'หัวหน้ากะ / ช่างไฟฟ้าเวรนอกเวลา',
            contactNumber: '02-999-0000 ต่อ 101',
            keyDuties: 'ตัดไฟตู้ MDB ฉุกเฉิน และโทรแจ้ง 199 / 1129 ทันที',
          ),
        ],
      ),
      evacuationPlan: const EvacuationSubPlan(
        alarmSoundSignal: 'เสียงไซเรนฉุกเฉินสัญญาณขาดช่วง 3 ครั้งต่อเนื่อง พร้อมประกาศเสียงตามสาย',
        assemblyPoints: [
          AssemblyPointItem(
            pointName: 'จุดรวมพลหลัก ลานอเนกประสงค์กลางแจ้ง',
            location: 'ลานกลางแจ้ง ห่างจากเสาไฟฟ้าแรงสูงและหม้อแปลงอย่างน้อย 30 เมตร',
            assignedDepartments: 'ทุกแผนกและผู้รับเหมา',
            capacity: 200,
          ),
        ],
        wardens: [
          EvacuationWarden(areaFloor: 'อาคารผลิต', wardenName: 'หัวหน้างานความปลอดภัย', deputyWardenName: 'นายชูชัย ประจำทางออก'),
          EvacuationWarden(areaFloor: 'อาคารสำนักงาน', wardenName: 'จป.วิชาชีพ', deputyWardenName: 'นางกาญจนา ตรวจนับยอด'),
        ],
        evacuationTeams: [
          EvacuationTeam(
            teamName: 'ทีมช่างไฟฟ้าตัดกระแสไฟฉุกเฉิน (Isolation Team)',
            areaFloor: 'ห้องควบคุมระบบไฟฟ้าหลัก (MDB Room) และสถานีหม้อแปลง',
            leaderName: 'นายศักดิ์ดา วิศวกรระบบ (โทร 081-111-2222)',
            deputyLeaderName: 'นายสมคิด สวิตช์บอร์ด',
            members: ['นายประวิทย์ เครื่องกำเนิดไฟฟ้า', 'นายวิชัย ตัดตอนวงจร'],
            assignedAssemblyPoint: 'จุดรวมพลหลัก',
            duties: 'ตรวจสอบการปลดวงจรไฟฟ้าหลัก (Main Circuit Breaker) และควบคุมเครื่องกำเนิดไฟฟ้าสำรอง',
          ),
          EvacuationTeam(
            teamName: 'ทีมปฐมพยาบาลกู้ชีพฉุกเฉิน (First Aid & AED Team)',
            areaFloor: 'หน่วยพยาบาลและจุดรวมพล',
            leaderName: 'พยาบาลวิชาชีพ / นายแพทย์ประจำโรงงาน (โทร 081-333-4444)',
            deputyLeaderName: 'นางสาววราภรณ์ CPR',
            members: ['นายมนัส จัดการเครื่อง AED', 'นางสายใจ ปฐมพยาบาล'],
            assignedAssemblyPoint: 'จุดรวมพลหลัก (เต็นท์พยาบาล)',
            duties: 'ปฏิบัติการ CPR และใช้เครื่อง AED สำหรับผู้ประสบภัยไฟฟ้าดูด ประสานนำส่งโรงพยาบาล',
          ),
          EvacuationTeam(
            teamName: 'ทีมกวดขันอพยพประจำพื้นที่ (Floor Wardens)',
            areaFloor: 'อาคารผลิตและอาคารสำนักงาน',
            leaderName: 'หัวหน้างานความปลอดภัย (โทร 081-555-6666)',
            deputyLeaderName: 'นายชูชัย ประจำทางออก',
            members: ['นางกาญจนา ตรวจนับยอด', 'นายวิโรจน์ ลาดตระเวน'],
            assignedAssemblyPoint: 'จุดรวมพลหลัก',
            duties: 'นำพนักงานเดินเท้าตามเส้นทางไฟฉุกเฉิน ไม่ให้เข้าใกล้จุดที่อาจมีไฟฟ้ารั่ว',
          ),
        ],
        headcountMethod: 'นับยอดพนักงาน ณ จุดรวมพลด้วยรายชื่อดิจิทัลและแบบฟอร์มนับยอด',
      ),
      reliefPlan: const ReliefSubPlan(
        governmentContacts: [
          EmergencyContactAgency(agencyName: 'การไฟฟ้าส่วนภูมิภาค / นครหลวง', phoneNumber: '1129 / 1130', contactPerson: 'ศูนย์รับแจ้งกระแสไฟฟ้าขัดข้อง'),
          EmergencyContactAgency(agencyName: 'ศูนย์ส่งต่อผู้ป่วยฉุกเฉิน / กู้ชีพ 1669', phoneNumber: '1669', contactPerson: 'ศูนย์วิทยุเอราวัณ/นเรนทร'),
          EmergencyContactAgency(agencyName: 'สถานีดับเพลิงและกู้ภัยท้องที่', phoneNumber: '199', contactPerson: 'ศูนย์วิทยุพระราม'),
        ],
        searchAndRescueProtocol: 'ทีมกู้ภัยเข้าค้นหาผู้ประสบภัยได้เมื่อวิศวกรไฟฟ้ายืนยันสภาพปลอดกระแสไฟฟ้า (Zero Energy & Grounded) แล้วเท่านั้น',
        damageAssessmentProtocol: 'วิศวกรไฟฟ้าตรวจสอบความเสียหายของ MDB และทดสอบค่าความต้านทานฉนวน (Megger Test) ก่อนพิจารณาจ่ายกระแสไฟคืน',
        businessContinuityProtocol: 'เดินเครื่องกำเนิดไฟฟ้าฉุกเฉิน (Emergency Generator) เลี้ยงระบบระบายอากาศ เซิร์ฟเวอร์ และไฟฉุกเฉิน',
      ),
    );
  }

  static EmergencyPlanModel _getCustomPreset({
    required BusinessType businessType,
    required String companyName,
    required String companyAddress,
    required int totalEmployees,
    required int maleCount,
    required int femaleCount,
  }) {
    return EmergencyPlanModel(
      planTitle: 'แผนตอบโต้ภาวะฉุกเฉินเฉพาะองค์กร (Custom Emergency Plan)',
      hazardType: HazardType.custom,
      businessType: businessType,
      companyName: companyName,
      companyAddress: companyAddress,
      totalEmployees: totalEmployees,
      maleCount: maleCount,
      femaleCount: femaleCount,
      fireCommanderName: 'ผู้จัดการฝ่ายความปลอดภัย',
      deputyCommanderName: 'ผู้ช่วยผู้จัดการ',
      commanderPhone: '081-000-0000',
      version: '2025.1',
      effectiveDate: '2025-01-01',
      reviewDate: '2025-12-31',
      status: PlanStatus.draft,
      inspectionPlan: const InspectionSubPlan(),
      trainingPlan: const TrainingSubPlan(),
      campaignPlan: const CampaignSubPlan(),
      suppressionPlan: const SuppressionSubPlan(),
      evacuationPlan: const EvacuationSubPlan(),
      reliefPlan: const ReliefSubPlan(),
    );
  }
}
