import 'package:flutter_test/flutter_test.dart';
import 'package:safety_superapp/features/risk_assessment/domain/models/risk_assessment_models.dart';
import 'package:safety_superapp/features/ptw/data/models/ptw_model.dart';
import 'package:safety_superapp/features/ptw/domain/enums/high_risk_type.dart';
import 'package:safety_superapp/features/ptw/domain/enums/ptw_status.dart';
import 'package:safety_superapp/features/near_miss_incident/domain/models/accident_models.dart';

void main() {
  group('Real Data & Statutory Profile Tests', () {
    test('CompanyProfile correctly validates authentic Thai industrial information', () {
      final profile = CompanyProfile(
        id: 1,
        companyName: 'บริษัท ไทยพัฒนาอุตสาหกรรมชิ้นส่วนยานยนต์ จำกัด (มหาชน)',
        employerName: 'นายสมชาย เจริญสุขวัฒนา (กรรมการผู้จัดการ)',
        taxId: '0107558000891',
        businessCategorySchedule: 2,
        businessCategoryNumber: 24,
        businessCategoryTitle: 'ลำดับที่ ๒๔. อุตสาหกรรมยานพาหนะ ชิ้นส่วนยานพาหนะ หรืออุปกรณ์เสริมสำหรับยานพาหนะ',
        employeeCount: 89,
        addressNumber: '88/9',
        moo: '4',
        soi: 'นิคมฯ ซอย 12',
        road: 'พัฒนา 1',
        subdistrict: 'แพรกษา',
        district: 'เมืองสมุทรปราการ',
        province: 'สมุทรปราการ',
        postalCode: '10280',
        phone: '02-709-1234',
        mobile: '081-890-5678',
        safetyOfficerName: 'นางสาวพัชราภรณ์ สุขสวัสดิ์',
        safetyOfficerLevel: 'จป.วิชาชีพ',
        safetyOfficerCertNo: 'ว.๕๖๒๘๙-๒๕๖๒',
        safetyOfficerPhone: '02-709-1234 ต่อ 105',
        safetyExpertName: 'นายวรวิทย์ สันติสุขไพศาล',
        safetyExpertLicenseNo: 'ผช.๑๒๓๔/๒๕๖๔',
        safetyPolicy: 'มุ่งมั่นสร้างความปลอดภัยในการทำงาน อุบัติเหตุต้องเป็นศูนย์ (Zero Accident Goal) พนักงานทุกคนมีส่วนร่วมและปฏิบัติตามมาตรฐานสากล',
        areaSqm: 12500.0,
      );

      expect(profile.companyName, contains('ไทยพัฒนาอุตสาหกรรม'));
      expect(profile.businessCategorySchedule, 2);
      expect(profile.businessCategoryNumber, 24);
      expect(profile.employeeCount, 89);
      expect(profile.safetyOfficerLevel, 'จป.วิชาชีพ');
      expect(profile.safetyPolicy, contains('Zero Accident Goal'));

      final map = profile.toMap();
      expect(map['company_name'], 'บริษัท ไทยพัฒนาอุตสาหกรรมชิ้นส่วนยานยนต์ จำกัด (มหาชน)');
      expect(map['business_category_number'], 24);

      final restored = CompanyProfile.fromMap(map);
      expect(restored.companyName, profile.companyName);
      expect(restored.employeeCount, 89);
    });

    test('PtwModel active permit correctly encapsulates Hot Work statutory data', () {
      const permit = PtwModel(
        id: 1,
        ptwNumber: 'PTW-2026-001',
        workTitle: 'งานเชื่อมตัดโครงสร้างเหล็กซ่อมบำรุงสายพานลำเลียง Main Conveyor Line A',
        workDescription: 'เชื่อมเสริมความแข็งแรงโครงสร้างเหล็กสายพานลำเลียงชิ้นส่วน',
        primaryRiskType: HighRiskType.hotWork,
        status: PtwStatus.active,
        applicantName: 'นายสมเกียรติ มั่นคง',
        applicantPhone: '089-123-4567',
        applicantDepartment: 'ฝ่ายซ่อมบำรุงเครื่องจักร',
        plantArea: 'อาคารโรงงาน 1 (Main Production Hall)',
        specificLocation: 'สายพานลำเลียง Line A บริเวณหน้าเตาชุบ',
        requestDate: '2026-09-09',
        workStartDate: '2026-09-09',
        workEndDate: '2026-09-09',
        workStartTime: '08:30',
        workEndTime: '17:00',
        workerCount: 3,
        workerNames: ['นายสมเกียรติ มั่นคง', 'นายประสิทธิ์ ระวังภัย', 'นายวิชัย ว่องไว'],
        emergencyRescuePlan: 'ใช้ถังดับเพลิงประจำจุด หากเพลิงลุกลามให้กด Fire Alarm และอพยพไปจุดรวมพล',
        requiredPpeList: 'หน้ากากเชื่อม, แว่นตานิรภัย, ถุงมือหนัง, รองเท้าหัวเหล็ก',
      );

      expect(permit.ptwNumber, 'PTW-2026-001');
      expect(permit.primaryRiskType, HighRiskType.hotWork);
      expect(permit.status, PtwStatus.active);
      expect(permit.workerCount, 3);
      expect(permit.workerNames.length, 3);
    });

    test('AccidentInvestigation correctly structures realistic Near Miss incident', () {
      final incident = AccidentInvestigation(
        id: 1,
        eventNo: 'NM-2026-001',
        eventType: 'NEAR_MISS',
        incidentTitle: 'สะเก็ดไฟจากการเจียรโครงเหล็กกระเด็นใกล้ถังทินเนอร์ (เกือบเกิดเพลิงไหม้)',
        incidentDate: '2026-09-07',
        incidentTime: '14:30',
        incidentLocation: 'โรงประกอบเชื่อม 2 (Fabrication Workshop 2)',
        injuredPersonName: 'นายอนุชา ขยันงาน',
        injuredPersonDepartment: 'ฝ่ายซ่อมบำรุงและโครงสร้าง',
        daysLost: 0,
        unsafeActs: const [
          'ทำงานก่อประกายไฟโดยไม่ตรวจสอบและเคลื่อนย้ายสารเคมีไวไฟในรัศมี 10 เมตร',
          'เปิดฝาถังสารเคมีไวไฟทิ้งไว้หลังเสร็จสิ้นการใช้งาน',
        ],
        unsafeConditions: const [
          'ไม่มีฉากกั้นสะเก็ดไฟ (Welding / Grinding Fire Blanket Screen)',
        ],
        managementErrors: const [
          'การตรวจสอบหน้างานก่อนเริ่มงานร้อน (Hot Work Pre-check) ยังไม่รัดกุม',
        ],
      );

      expect(incident.eventType, 'NEAR_MISS');
      expect(incident.daysLost, 0);
      expect(incident.unsafeActs.length, 2);
      expect(incident.unsafeConditions.length, 1);
      expect(incident.managementErrors.length, 1);
    });
  });
}
