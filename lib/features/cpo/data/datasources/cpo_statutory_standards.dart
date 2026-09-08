/// มาตรฐานข้อกำหนดตามกฎกระทรวง จป./คปอ. พ.ศ. ๒๕๖๕ และคู่มือ กสร. ๑/๒๕๖๑
class CpoStatutoryStandards {
  /// คำนวณจำนวนโควตากรรมการ คปอ. ขั้นต่ำตามกฎหมาย
  static Map<String, int> calculateQuota(int employeeCount) {
    if (employeeCount < 50) {
      return {
        'total': 0,
        'chair': 0,
        'employer_rep': 0,
        'employee_rep': 0,
        'secretary': 0,
      };
    } else if (employeeCount >= 50 && employeeCount <= 99) {
      return {
        'total': 5,
        'chair': 1,
        'employer_rep': 1,
        'employee_rep': 2,
        'secretary': 1,
      };
    } else if (employeeCount >= 100 && employeeCount <= 499) {
      return {
        'total': 7,
        'chair': 1,
        'employer_rep': 2,
        'employee_rep': 3,
        'secretary': 1,
      };
    } else {
      // 500 คนขึ้นไป
      return {
        'total': 11,
        'chair': 1,
        'employer_rep': 4,
        'employee_rep': 5,
        'secretary': 1,
      };
    }
  }

  /// ๖ ระเบียบวาระมาตรฐานตามคู่มือการประชุม กสร. ๑/๒๕๖๑ หน้า ๓๒-๓๖
  static const List<Map<String, dynamic>> standardAgendas = [
    {
      'agenda_no': 1,
      'title': 'เรื่องที่ประธานแจ้งให้ที่ประชุมทราบ',
      'default_content': 'ประธานกล่าวเปิดการประชุมและแจ้งนโยบายหรือเรื่องสำคัญด้านความปลอดภัยแก่คณะกรรมการ คปอ.',
    },
    {
      'agenda_no': 2,
      'title': 'พิจารณารับรองรายงานการประชุมครั้งที่ผ่านมา',
      'default_content': 'คณะกรรมการร่วมกันตรวจทานและพิจารณารับรองรายงานการประชุม คปอ. ครั้งก่อนหน้า',
    },
    {
      'agenda_no': 3,
      'title': 'เรื่องสืบเนื่องจากการประชุมครั้งที่แล้ว (การติดตามงานที่คั่งค้าง)',
      'default_content': 'ติดตามความคืบหน้าของมาตรการแก้ไขและงานที่ได้รับมอบหมายตามมติที่ประชุมในครั้งที่ผ่านมา',
    },
    {
      'agenda_no': 4,
      'title': 'เรื่องเพื่อทราบ (สถิติอุบัติเหตุ, ใบอนุญาต PTW, การตรวจวัดสิ่งแวดล้อม)',
      'default_content': 'รายงานสถิติอุบัติเหตุประจำเดือน, เหตุการณ์เกือบเกิดอุบัติเหตุ (Near-Miss), สรุปใบอนุญาตทำงานเสี่ยงสูง (PTW), และผลการตรวจประเมินสภาพแวดล้อม',
    },
    {
      'agenda_no': 5,
      'title': 'เรื่องเพื่อพิจารณา (ข้อเสนอแนะด้านความปลอดภัยและการออกมติ)',
      'default_content': 'พิจารณาข้อเสนอแนะในการปรับปรุงสภาพการทำงาน, แผนฝึกอบรมความปลอดภัย, แผนซ้อมดับเพลิงและอพยพหนีไฟ, และลงมติกำหนดผู้รับผิดชอบ',
    },
    {
      'agenda_no': 6,
      'title': 'เรื่องอื่นๆ (ถ้ามี)',
      'default_content': 'ข้อหารือหรือเรื่องเร่งด่วนอื่นๆ นอกเหนือจากระเบียบวาระข้างต้น',
    },
  ];

  static List<Map<String, dynamic>> getStandard6Agendas() => standardAgendas;
}
