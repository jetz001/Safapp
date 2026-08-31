import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../domain/models/legal_master_item_model.dart';
import '../domain/models/legal_compliance_assessment_model.dart';
import '../domain/models/legal_capa_model.dart';
import '../domain/models/legal_compliance_stats_model.dart';

/// Multi-Sheet Excel (.xlsx) Export Service for SAFAPP Legal Register & Compliance Evaluation.
/// Generates authoritative audit workbooks containing:
/// - Sheet 1: "Legal Register & Assessment" (ทะเบียนและการประเมินความสอดคล้อง)
/// - Sheet 2: "CAPA Action Plan" (แผนการปรับปรุงแก้ไขและป้องกัน)
/// - Sheet 3: "Category KPI Summary" (สรุปสถิติความสอดคล้อง ๘ หมวดหมู่)
class LegalComplianceExcelService {
  /// Builds the complete multi-sheet Excel workbook and returns the raw bytes.
  static List<int>? exportToExcelBytes({
    required List<LegalMasterItemModel> masterItems,
    required List<LegalComplianceAssessmentModel> assessments,
    required List<LegalCapaModel> capas,
    required LegalComplianceStatsModel stats,
    String? companyName,
    String? companyAddress,
    String? companyTaxId,
    String? assessmentPeriod,
    String? leadAssessorName,
  }) {
    final excel = Excel.createExcel();

    final orgName = companyName?.isNotEmpty == true
        ? companyName!
        : 'บริษัท โรงงานอุตสาหกรรมตัวอย่าง จำกัด (มหาชน)';
    final period = assessmentPeriod?.isNotEmpty == true
        ? assessmentPeriod!
        : 'ประจำปี ${DateTime.now().year + 543}';
    final exportDate = DateTime.now().toIso8601String().substring(0, 10);
    final assessor = leadAssessorName?.isNotEmpty == true
        ? leadAssessorName!
        : 'เจ้าหน้าที่ความปลอดภัยในการทำงานระดับวิชาชีพ (จป.วิชาชีพ)';

    // Map master items by itemId for quick reference
    final Map<String, LegalMasterItemModel> masterMap = {
      for (final m in masterItems) m.itemId: m,
    };

    // ========================================================================
    // SHEET 1: Legal Register & Assessment (ทะเบียนและการประเมินความสอดคล้อง)
    // ========================================================================
    const sheet1Name = 'Legal Register & Assessment';
    final sheet1 = excel[sheet1Name];
    excel.setDefaultSheet(sheet1Name);

    // Title banner
    sheet1.appendRow([
      TextCellValue('แบบรายงานทะเบียนและการประเมินความสอดคล้องตามกฎหมายความปลอดภัย อาชีวอนามัย และสภาพแวดล้อมในการทำงาน'),
    ]);
    sheet1.appendRow([
      TextCellValue('สถานประกอบการ: $orgName | รอบการประเมิน: $period | วันที่ส่งออก: $exportDate | ผู้ประเมินหลัก: $assessor'),
    ]);
    sheet1.appendRow([
      TextCellValue('ดัชนีความสอดคล้องพื้นฐาน (CI): ${stats.basicCompliancePercent}% | ดัชนีถ่วงน้ำหนักความเสี่ยง (WCI): ${stats.riskWeightedCompliancePercent}% | สอดคล้อง: ${stats.compliantCount}/${stats.applicableItems} ข้อ | ไม่สอดคล้อง: ${stats.nonCompliantCount} ข้อ'),
    ]);
    sheet1.appendRow([TextCellValue('')]); // Blank spacing row

    // Table Header Row
    sheet1.appendRow([
      TextCellValue('ลำดับ (No.)'),
      TextCellValue('รหัสข้อกำหนด (Item Code)'),
      TextCellValue('รหัสหมวดหมู่ (Category Code)'),
      TextCellValue('หมวดหมู่กฎหมาย (Law Category)'),
      TextCellValue('กฎหมายราชกิจจานุเบกษาอ้างอิง (Statutory Law)'),
      TextCellValue('มาตรา / ข้อ (Article No.)'),
      TextCellValue('หัวข้อข้อกำหนด (Requirement Title)'),
      TextCellValue('รายละเอียดสาระสำคัญ (Requirement Details)'),
      TextCellValue('เกณฑ์การพิจารณาความสอดคล้อง (Compliance Criteria)'),
      TextCellValue('ระดับความเสี่ยง (Risk Level)'),
      TextCellValue('น้ำหนักความเสี่ยง (Weight)'),
      TextCellValue('การบังคับใช้ (Applicability)'),
      TextCellValue('สถานะความสอดคล้อง (Compliance Status)'),
      TextCellValue('การปฏิบัติจริงของสถานประกอบการ (Actual Practice / Implementation)'),
      TextCellValue('ประเภทหลักฐานที่กำหนด (Required Evidence Type)'),
      TextCellValue('เอกสารแนบหลักฐาน (Attached Evidence Files)'),
      TextCellValue('ผู้ประเมิน (Assessor Name)'),
      TextCellValue('ตำแหน่ง/บทบาท (Assessor Role)'),
      TextCellValue('แผนก/ฝ่าย (Department)'),
      TextCellValue('วันที่ประเมิน (Evaluation Date)'),
      TextCellValue('รอบการทบทวนถัดไป (Next Review Date)'),
      TextCellValue('บทกำหนดโทษ (Penalty Summary)'),
    ]);

    // Populate data rows for Sheet 1
    for (int i = 0; i < assessments.length; i++) {
      final a = assessments[i];
      final master = masterMap[a.masterItemId];

      sheet1.appendRow([
        IntCellValue(i + 1),
        TextCellValue(a.requirementCode),
        TextCellValue(a.category),
        TextCellValue(a.categoryLabelTh),
        TextCellValue(a.lawTitleTh),
        TextCellValue(a.articleNo),
        TextCellValue(a.requirementTitle),
        TextCellValue(a.requirementDetails),
        TextCellValue(master?.complianceCriteria ?? '-'),
        TextCellValue(a.riskLevelEnum.labelTh),
        IntCellValue(a.riskWeight),
        TextCellValue(a.isApplicable ? 'เกี่ยวข้อง (Yes)' : 'ไม่เกี่ยวข้อง (No)'),
        TextCellValue(a.statusLabelTh),
        TextCellValue(
          a.actualPractice?.isNotEmpty == true
              ? a.actualPractice!
              : (a.isNotApplicable ? 'ไม่มีกิจกรรมหรือกระบวนการที่เกี่ยวข้อง' : '-'),
        ),
        TextCellValue(master?.evidenceTypeLabelTh ?? '-'),
        TextCellValue(
          a.evidenceFilePaths.isNotEmpty
              ? a.evidenceFilePaths.join('; ')
              : (master?.officialFormName != null ? 'แบบฟอร์มราชการ: ${master!.officialFormName}' : '-'),
        ),
        TextCellValue(a.evaluatorName),
        TextCellValue(a.evaluatorRole ?? '-'),
        TextCellValue(a.department ?? '-'),
        TextCellValue(a.evaluatedDate),
        TextCellValue(a.nextReviewDate ?? '-'),
        TextCellValue(a.penaltySummary ?? master?.penaltySummary ?? '-'),
      ]);
    }

    // ========================================================================
    // SHEET 2: CAPA Action Plan (แผนการปรับปรุงแก้ไขและติดตามผล)
    // ========================================================================
    const sheet2Name = 'CAPA Action Plan';
    final sheet2 = excel[sheet2Name];

    sheet2.appendRow([
      TextCellValue('แบบรายงานแผนปฏิบัติการแก้ไขและป้องกันข้อกฎหมายที่ไม่สอดคล้อง (Safety Legal CAPA Action Plan)'),
    ]);
    sheet2.appendRow([
      TextCellValue('สถานประกอบการ: $orgName | แผนงานทั้งหมด: ${capas.length} รายการ | เสร็จสิ้น: ${stats.completedCapaCount} | รอดำเนินการ: ${stats.pendingCapaCount} | กำลังทำ: ${stats.inProgressCapaCount} | เกินกำหนด: ${stats.overdueCapaCount}'),
    ]);
    sheet2.appendRow([TextCellValue('')]); // Blank spacing row

    sheet2.appendRow([
      TextCellValue('ลำดับ (No.)'),
      TextCellValue('รหัส CAPA (CAPA ID)'),
      TextCellValue('รหัสข้อกำหนดกฎหมาย (Requirement Code)'),
      TextCellValue('หัวข้อข้อกำหนดกฎหมาย (Requirement Title)'),
      TextCellValue('หมวดหมู่กฎหมาย (Law Category)'),
      TextCellValue('กฎหมายอ้างอิง (Statutory Law)'),
      TextCellValue('หัวข้อแผนงานแก้ไข (Action Title)'),
      TextCellValue('สาเหตุรากเหง้า (Root Cause Analysis - 5 Whys)'),
      TextCellValue('มาตรการแก้ไขปัญหา (Corrective Action)'),
      TextCellValue('มาตรการป้องกันการเกิดซ้ำ (Preventive Action)'),
      TextCellValue('ผู้รับผิดชอบหลัก (Person In Charge - PIC)'),
      TextCellValue('แผนก/ฝ่ายผู้รับผิดชอบ (PIC Department)'),
      TextCellValue('กำหนดแล้วเสร็จ (Target Date)'),
      TextCellValue('วันที่แล้วเสร็จจริง (Actual Completed Date)'),
      TextCellValue('สถานะการดำเนินงาน (CAPA Status)'),
      TextCellValue('สถานะเกินกำหนด (Is Overdue)'),
      TextCellValue('วันที่หัวหน้างานรับรอง (Supervisor Sign-off Date)'),
      TextCellValue('ไฟล์หลักฐานการปิดงาน (Closure Evidence File)'),
      TextCellValue('หมายเหตุเพิ่มเติม (Notes / Remarks)'),
    ]);

    if (capas.isEmpty) {
      sheet2.appendRow([
        IntCellValue(1),
        TextCellValue('-'),
        TextCellValue('-'),
        TextCellValue('สถานประกอบการมีผลการประเมินสอดคล้องครบถ้วนทุกข้อกำหนด (ไม่มีรายการที่ต้องเปิดแผน CAPA ในรอบนี้)'),
        TextCellValue('-'),
        TextCellValue('-'),
        TextCellValue('-'),
        TextCellValue('-'),
        TextCellValue('-'),
        TextCellValue('-'),
        TextCellValue('-'),
        TextCellValue('-'),
        TextCellValue('-'),
        TextCellValue('-'),
        TextCellValue('เสร็จสมบูรณ์ / สอดคล้อง'),
        TextCellValue('ปกติ'),
        TextCellValue('-'),
        TextCellValue('-'),
        TextCellValue('-'),
      ]);
    } else {
      for (int i = 0; i < capas.length; i++) {
        final c = capas[i];
        sheet2.appendRow([
          IntCellValue(i + 1),
          TextCellValue(c.id != null ? 'CAPA-${c.id}' : 'CAPA-${i + 1}'),
          TextCellValue(c.requirementCode ?? '-'),
          TextCellValue(c.requirementTitle ?? '-'),
          TextCellValue(c.category ?? '-'),
          TextCellValue(c.lawTitle ?? '-'),
          TextCellValue(c.actionTitle),
          TextCellValue(c.rootCause),
          TextCellValue(c.correctiveAction),
          TextCellValue(c.preventiveAction ?? '-'),
          TextCellValue(c.picName),
          TextCellValue(c.picDepartment ?? '-'),
          TextCellValue(c.targetDate),
          TextCellValue(c.completedDate ?? '-'),
          TextCellValue(c.statusLabelTh),
          TextCellValue(c.isOverdue ? 'เกินกำหนด (Overdue)' : (c.isCompleted ? 'เสร็จสมบูรณ์' : 'อยู่ในกำหนด')),
          TextCellValue(c.supervisorAcknowledgedDate ?? '-'),
          TextCellValue(c.evidenceFilePath ?? '-'),
          TextCellValue(c.notes ?? '-'),
        ]);
      }
    }

    // ========================================================================
    // SHEET 3: Category KPI Summary (สรุปสถิติ ๘ หมวดหมู่ราชกิจจานุเบกษา)
    // ========================================================================
    const sheet3Name = 'Category KPI Summary';
    final sheet3 = excel[sheet3Name];

    sheet3.appendRow([
      TextCellValue('สรุปดัชนีและสถิติความสอดคล้องตามกฎหมายความปลอดภัย ๘ หมวดหมู่ราชกิจจานุเบกษา (Category KPI Summary)'),
    ]);
    sheet3.appendRow([
      TextCellValue('สถานประกอบการ: $orgName | วันที่ประเมิน: ${stats.evaluatedDate ?? exportDate} | % สอดคล้องพื้นฐาน: ${stats.basicCompliancePercent}% | % ถ่วงน้ำหนัก: ${stats.riskWeightedCompliancePercent}%'),
    ]);
    sheet3.appendRow([TextCellValue('')]); // Blank spacing row

    sheet3.appendRow([
      TextCellValue('ลำดับ (No.)'),
      TextCellValue('รหัสหมวดหมู่ (Category Code)'),
      TextCellValue('ชื่อหมวดหมู่กฎหมายความปลอดภัย (Law Category Title Thai)'),
      TextCellValue('ชื่อหมวดหมู่ภาษาอังกฤษ (Category Title En)'),
      TextCellValue('จำนวนข้อทั้งหมด (Total Master Items)'),
      TextCellValue('ข้อที่ต้องปฏิบัติตาม (Applicable Items)'),
      TextCellValue('สอดคล้อง (Compliant)'),
      TextCellValue('ไม่สอดคล้อง (Non-Compliant)'),
      TextCellValue('อยู่ระหว่างดำเนินการ (In-Progress)'),
      TextCellValue('ไม่เกี่ยวข้อง (Not Applicable)'),
      TextCellValue('ข้อไม่สอดคล้องระดับเสี่ยงสูง (High Risk Non-Compliant)'),
      TextCellValue('ร้อยละความสอดคล้องพื้นฐาน (% Basic Compliance CI)'),
      TextCellValue('ร้อยละความสอดคล้องถ่วงน้ำหนัก (% Risk-Weighted WCI)'),
      TextCellValue('ระดับผลการประเมินหมวด (Category Evaluation Rating)'),
    ]);

    for (int i = 0; i < stats.categoryBreakdown.length; i++) {
      final cat = stats.categoryBreakdown[i];
      final ratingText = cat.basicCompliancePercent >= 100.0
          ? 'สอดคล้องครบถ้วน (100%)'
          : cat.nonCompliantCount > 0
              ? 'มีข้อไม่สอดคล้อง (ต้องมี CAPA)'
              : 'อยู่ระหว่างปรับปรุง (In-Progress)';

      sheet3.appendRow([
        IntCellValue(i + 1),
        TextCellValue(cat.category),
        TextCellValue(cat.categoryTitleTh),
        TextCellValue(cat.categoryEnum.titleEn),
        IntCellValue(cat.totalItems),
        IntCellValue(cat.applicableItems),
        IntCellValue(cat.compliantCount),
        IntCellValue(cat.nonCompliantCount),
        IntCellValue(cat.inProgressCount),
        IntCellValue(cat.notApplicableCount),
        IntCellValue(cat.highRiskNonCompliantCount),
        DoubleCellValue(cat.basicCompliancePercent),
        DoubleCellValue(cat.riskWeightedCompliancePercent),
        TextCellValue(ratingText),
      ]);
    }

    // Overall Total / Average Row
    sheet3.appendRow([
      TextCellValue('รวมทั้งสิ้น (TOTAL SUMMARY)'),
      TextCellValue('ALL'),
      TextCellValue('สรุปภาพรวม ๘ หมวดหมู่กฎหมายราชกิจจานุเบกษา'),
      TextCellValue('All 8 Royal Gazette Safety Regulations'),
      IntCellValue(stats.totalItems),
      IntCellValue(stats.applicableItems),
      IntCellValue(stats.compliantCount),
      IntCellValue(stats.nonCompliantCount),
      IntCellValue(stats.inProgressCount),
      IntCellValue(stats.notApplicableCount),
      IntCellValue(stats.highRiskNonCompliantCount),
      DoubleCellValue(stats.basicCompliancePercent),
      DoubleCellValue(stats.riskWeightedCompliancePercent),
      TextCellValue(stats.basicCompliancePercent >= 90.0 ? 'ผ่านเกณฑ์ระดับดีเยี่ยม' : 'ต้องเร่งรัดปิดแผน CAPA'),
    ]);

    // Clean up default Sheet1 if generated automatically and not used
    if (excel.tables.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    return excel.save();
  }

  /// Exports the multi-sheet Excel file directly to the app's export documents directory
  /// and returns the absolute file path.
  static Future<String?> exportToExcelFile({
    required List<LegalMasterItemModel> masterItems,
    required List<LegalComplianceAssessmentModel> assessments,
    required List<LegalCapaModel> capas,
    required LegalComplianceStatsModel stats,
    String? companyName,
    String? companyAddress,
    String? companyTaxId,
    String? assessmentPeriod,
    String? leadAssessorName,
  }) async {
    final fileBytes = exportToExcelBytes(
      masterItems: masterItems,
      assessments: assessments,
      capas: capas,
      stats: stats,
      companyName: companyName,
      companyAddress: companyAddress,
      companyTaxId: companyTaxId,
      assessmentPeriod: assessmentPeriod,
      leadAssessorName: leadAssessorName,
    );

    if (fileBytes == null) return null;

    final appDocDir = await getApplicationDocumentsDirectory();
    final exportDir = Directory(p.join(appDocDir.path, 'SafetySuperapp', 'exports'));
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }

    final filename = 'SAFAPP_Legal_Compliance_Report_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    final targetPath = p.join(exportDir.path, filename);
    final file = File(targetPath);
    await file.writeAsBytes(fileBytes);

    return targetPath;
  }
}
