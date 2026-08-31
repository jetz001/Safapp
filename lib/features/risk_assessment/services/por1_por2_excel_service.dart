import 'package:excel/excel.dart';
import '../domain/models/risk_assessment_models.dart';

class Por1Por2ExcelService {
  /// สร้างไฟล์ Excel (.xlsx) ที่ประกอบด้วยตาราง ปอ.๑ และ ปอ.๒
  static List<int>? exportToExcel({
    required CompanyProfile company,
    required RiskAssessmentSession session,
    required List<PorReportRowData> rows,
  }) {
    final excel = Excel.createExcel();

    // ----------------------------------------------------
    // Sheet 1: แบบ ปอ. ๑ (ผลการประเมินอันตราย)
    // ----------------------------------------------------
    final sheetPor1Name = 'แบบ ปอ.๑ (ผลการประเมินอันตราย)';
    final sheetPor1 = excel[sheetPor1Name];
    excel.setDefaultSheet(sheetPor1Name);

    // Title & Info
    sheetPor1.appendRow([
      TextCellValue('แบบรายงานผลการประเมินอันตรายและการศึกษาผลกระทบของสภาพแวดล้อมในการทำงานที่มีผลต่อลูกจ้าง (แบบ ปอ. ๑)'),
    ]);
    sheetPor1.appendRow([
      TextCellValue('สถานประกอบการ: ${company.companyName} | วันที่ประเมิน: ${session.assessmentDate} | วิธีชี้บ่ง: ${session.hazardIdMethod}'),
    ]);
    sheetPor1.appendRow([
      TextCellValue('ผู้ประเมิน: 1) ${session.assessor1Name ?? "-"} (${session.assessor1Position ?? "-"}) 2) ${session.assessor2Name ?? "-"} (${session.assessor2Position ?? "-"})'),
    ]);
    sheetPor1.appendRow([TextCellValue('')]); // Blank line

    // Header Table
    sheetPor1.appendRow([
      TextCellValue('ลำดับ'),
      TextCellValue('แผนก/ฝ่าย'),
      TextCellValue('พื้นที่/สถานีงาน'),
      TextCellValue('จำนวนลูกจ้าง (คน)'),
      TextCellValue('ขั้นตอนการทำงาน/เครื่องจักร'),
      TextCellValue('สิ่งและลักษณะอันตราย'),
      TextCellValue('ผลกระทบที่อาจเกิดขึ้น'),
      TextCellValue('มาตรการป้องกันเดิม'),
      TextCellValue('ข้อเสนอแนะ'),
      TextCellValue('โอกาส (L 1-3)'),
      TextCellValue('ความรุนแรง (S 1-3)'),
      TextCellValue('คะแนน (LxS)'),
      TextCellValue('ระดับอันตราย'),
      TextCellValue('ต้องจัดทำ ปอ.๒'),
    ]);

    // Data rows
    for (int i = 0; i < rows.length; i++) {
      final item = rows[i];
      final machineStr = (item.stepItem.relatedMachineryEquipment != null && item.stepItem.relatedMachineryEquipment!.isNotEmpty)
          ? ' [เครื่องจักร: ${item.stepItem.relatedMachineryEquipment}]'
          : '';

      sheetPor1.appendRow([
        IntCellValue(i + 1),
        TextCellValue(item.workstation.departmentName),
        TextCellValue(item.workstation.stationName),
        IntCellValue(item.workstation.employeeCount),
        TextCellValue('${item.stepItem.stepName}$machineStr'),
        TextCellValue(item.hazard.hazardItemTitle),
        TextCellValue(item.hazard.potentialConsequences),
        TextCellValue(item.hazard.existingControlMeasures ?? '-'),
        TextCellValue(item.hazard.recommendation ?? '-'),
        IntCellValue(item.hazard.likelihoodScore),
        IntCellValue(item.hazard.severityScore),
        IntCellValue(item.hazard.riskScore),
        TextCellValue(item.hazard.riskLevelThai),
        TextCellValue(item.hazard.requiresPor2 ? 'ใช่ (ต้องมี ปอ.๒)' : 'ไม่ต้อง'),
      ]);
    }

    // ----------------------------------------------------
    // Sheet 2: แบบ ปอ. ๒ (แผนควบคุมและลดอันตราย)
    // ----------------------------------------------------
    final sheetPor2Name = 'แบบ ปอ.๒ (แผนควบคุมและลดอันตราย)';
    final sheetPor2 = excel[sheetPor2Name];

    sheetPor2.appendRow([
      TextCellValue('แบบรายงานแผนดำเนินงานด้านความปลอดภัย อาชีวอนามัย และสภาพแวดล้อมในการทำงาน (แบบ ปอ. ๒)'),
    ]);
    sheetPor2.appendRow([
      TextCellValue('สถานประกอบการ: ${company.companyName} | วันที่ทบทวนแผน: ${session.assessmentDate}'),
    ]);
    sheetPor2.appendRow([TextCellValue('')]); // Blank line

    sheetPor2.appendRow([
      TextCellValue('ลำดับ'),
      TextCellValue('แผนก/ฝ่าย'),
      TextCellValue('พื้นที่/สถานีงาน'),
      TextCellValue('ขั้นตอนการทำงาน'),
      TextCellValue('ระดับอันตราย'),
      TextCellValue('แผนดำเนินงานเพื่อลด/ควบคุมอันตราย (มาตรการ/กิจกรรม/หลักเกณฑ์)'),
      TextCellValue('วันที่เริ่ม'),
      TextCellValue('วันที่สิ้นสุด'),
      TextCellValue('ผู้รับผิดชอบ'),
      TextCellValue('ผู้ตรวจติดตาม'),
      TextCellValue('สถานะการดำเนินงาน'),
    ]);

    final por2Rows = rows.where((r) => r.hazard.requiresPor2).toList();
    for (int i = 0; i < por2Rows.length; i++) {
      final item = por2Rows[i];
      final plan = item.plan;
      sheetPor2.appendRow([
        IntCellValue(i + 1),
        TextCellValue(item.workstation.departmentName),
        TextCellValue(item.workstation.stationName),
        TextCellValue(item.stepItem.stepName),
        TextCellValue('${item.hazard.riskLevelThai} (คะแนน ${item.hazard.riskScore})'),
        TextCellValue(plan?.controlPlanDescription ?? item.hazard.recommendation ?? '-'),
        TextCellValue(plan?.startDate ?? '-'),
        TextCellValue(plan?.endDate ?? '-'),
        TextCellValue(plan?.responsiblePerson ?? '-'),
        TextCellValue(plan?.supervisorMonitor ?? '-'),
        TextCellValue(plan?.status ?? 'PLANNED'),
      ]);
    }

    // Remove default Sheet1 if present and unused
    if (excel.tables.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    return excel.encode();
  }
}
