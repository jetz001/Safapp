import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../domain/models/audit_models.dart';

class SafetyAuditExcelExporter {
  static Future<String> _getExportDirectory() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final exportDir = Directory(p.join(appDocDir.path, 'SafetySuperapp', 'exports', 'audit'));
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }
    return exportDir.path;
  }

  static Future<String> exportAuditSessionToExcel({
    required AuditSession session,
    required List<AuditChecklistItem> items,
    required List<AuditFindingCapa> findings,
    String companyName = 'สถานประกอบกิจการ',
  }) async {
    final excel = Excel.createExcel();

    // Sheet 1: Checklist Items
    const sheet1Name = 'ผลการตรวจประเมิน SMS';
    excel.rename('Sheet1', sheet1Name);
    final sheet1 = excel[sheet1Name];

    // Header Metadata
    sheet1.appendRow([TextCellValue('รายงานผลการตรวจประเมินระบบการจัดการด้านความปลอดภัย (กฎกระทรวง พ.ศ. ๒๕๖๕)')]);
    sheet1.appendRow([TextCellValue('สถานประกอบการ: $companyName | เลขที่การตรวจ: ${session.auditNo} | วันที่: ${session.auditDate} | ผู้ตรวจ: ${session.leadAuditor}')]);
    sheet1.appendRow([TextCellValue('คะแนนความสอดคล้อง: ${session.compliancePercentage}% (Conform: ${session.conformCount}, Minor NC: ${session.minorNcCount}, Major NC: ${session.majorNcCount}, N/A: ${session.naCount})')]);
    sheet1.appendRow([TextCellValue('')]); // Blank line

    // Table Headers
    sheet1.appendRow([
      TextCellValue('ลำดับ'),
      TextCellValue('หมวดหมู่การตรวจ'),
      TextCellValue('ข้อกำหนด (Clause)'),
      TextCellValue('หัวข้อการตรวจประเมิน'),
      TextCellValue('รายละเอียดข้อกำหนด'),
      TextCellValue('กฎหมายอ้างอิง'),
      TextCellValue('ผลการตรวจ (Result)'),
      TextCellValue('หลักฐานในระบบ (Evidence)'),
      TextCellValue('บันทึกผู้ตรวจ (Auditor Notes)'),
      TextCellValue('ข้อเสนอแนะเพื่อการปรับปรุง'),
    ]);

    for (int i = 0; i < items.length; i++) {
      final it = items[i];
      String resTh = it.resultStatus;
      switch (it.resultStatus) {
        case 'CONFORM':
          resTh = 'สอดคล้อง (Conform)';
          break;
        case 'MINOR_NC':
          resTh = 'ข้อบกพร่องเล็กน้อย (Minor NC)';
          break;
        case 'MAJOR_NC':
          resTh = 'ข้อบกพร่องร้ายแรง (Major NC)';
          break;
        case 'NA':
          resTh = 'ไม่เกี่ยวข้อง (N/A)';
          break;
        case 'UNAUDITED':
          resTh = 'ยังไม่ตรวจ';
          break;
      }

      sheet1.appendRow([
        IntCellValue(i + 1),
        TextCellValue(it.categoryTitle),
        TextCellValue(it.clauseNo),
        TextCellValue(it.itemTitle),
        TextCellValue(it.requirementDescription),
        TextCellValue(it.legalReference),
        TextCellValue(resTh),
        TextCellValue(it.evidenceSummary ?? '-'),
        TextCellValue(it.auditorNotes ?? '-'),
        TextCellValue(it.suggestedAction ?? '-'),
      ]);
    }

    // Sheet 2: CAR / CAPA Findings
    if (findings.isNotEmpty) {
      final sheet2 = excel['รายการ CAR และ CAPA'];
      sheet2.appendRow([
        TextCellValue('ลำดับ'),
        TextCellValue('เลขที่ CAR'),
        TextCellValue('ระดับความรุนแรง'),
        TextCellValue('ข้อกำหนดที่เกี่ยวข้อง'),
        TextCellValue('รายละเอียดข้อบกพร่องที่พบ'),
        TextCellValue('การวิเคราะห์สาเหตุ (Root Cause)'),
        TextCellValue('มาตรการแก้ไขทันที (Corrective Action)'),
        TextCellValue('มาตรการป้องกันการเกิดซ้ำ (Preventive Action)'),
        TextCellValue('ผู้รับผิดชอบ'),
        TextCellValue('กำหนดแล้วเสร็จ (SLA)'),
        TextCellValue('สถานะ'),
        TextCellValue('วันที่ปิดประเด็น'),
        TextCellValue('ผู้ตรวจสอบการปิดประเด็น'),
      ]);

      for (int i = 0; i < findings.length; i++) {
        final f = findings[i];
        sheet2.appendRow([
          IntCellValue(i + 1),
          TextCellValue(f.findingNo),
          TextCellValue(f.findingType),
          TextCellValue(f.clauseRef),
          TextCellValue(f.problemDescription),
          TextCellValue(f.rootCause ?? '-'),
          TextCellValue(f.correctiveAction),
          TextCellValue(f.preventiveAction ?? '-'),
          TextCellValue(f.responsiblePerson),
          TextCellValue(f.dueDate),
          TextCellValue(f.status),
          TextCellValue(f.completedDate ?? '-'),
          TextCellValue(f.verifierName ?? '-'),
        ]);
      }
    }

    final bytes = excel.save();
    if (bytes == null) throw Exception('ไม่สามารถสร้างไฟล์ Excel ได้');

    final exportDir = await _getExportDirectory();
    final fileName = 'Audit_Report_${session.auditNo.replaceAll('-', '_')}_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    final filePath = p.join(exportDir, fileName);
    final file = File(filePath);
    await file.writeAsBytes(bytes);

    return filePath;
  }
}
