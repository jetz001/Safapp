import 'dart:io';
import 'package:flutter/material.dart';
import 'package:excel/excel.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../data/models/drill_session_model.dart';
import '../data/models/emergency_plan_model.dart';

class EmergencyExcelExporter {
  static Future<String> _getExportDirectory() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final exportDir = Directory(p.join(appDocDir.path, 'SafetySuperapp', 'exports', 'emergency'));
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }
    return exportDir.path;
  }

  /// ส่งออกสมุดบันทึกประวัติการฝึกซ้อมดับเพลิงและอพยพหนีไฟ
  static Future<String> exportDrillHistory(List<DrillSessionModel> drills, BuildContext? context) async {
    final excel = Excel.createExcel();
    const sheetName = 'ประวัติการฝึกซ้อมอพยพหนีไฟ';
    excel.rename('Sheet1', sheetName);
    final sheet = excel[sheetName];

    // Header Row
    sheet.appendRow([
      TextCellValue('ลำดับ'),
      TextCellValue('ปี พ.ศ./ค.ศ.'),
      TextCellValue('วันที่ฝึกซ้อม'),
      TextCellValue('เวลาที่ซ้อม'),
      TextCellValue('หัวข้อการฝึกซ้อม'),
      TextCellValue('ประเภทภัย'),
      TextCellValue('ผู้ดำเนินการฝึกซ้อม'),
      TextCellValue('เลขที่หนังสือเห็นชอบ/ทะเบียน'),
      TextCellValue('ลูกจ้างในพื้นที่ (คน)'),
      TextCellValue('ผู้เข้าร่วมซ้อม (คน)'),
      TextCellValue('ชาย (คน)'),
      TextCellValue('หญิง (คน)'),
      TextCellValue('อัตราเข้าร่วม (%)'),
      TextCellValue('เวลาเข้าดับเพลิงขั้นต้น (วินาที)'),
      TextCellValue('เวลาอพยพถึงจุดรวมพล (วินาที)'),
      TextCellValue('สถานะการนับยอดพนักงาน'),
      TextCellValue('สถานการณ์ผู้บาดเจ็บ'),
      TextCellValue('สถานะการส่งแบบ สปร. ๔'),
      TextCellValue('กำหนดส่ง สปร. ๔ (๓๐ วัน)'),
      TextCellValue('วันที่จัดส่งจริง'),
    ]);

    for (int i = 0; i < drills.length; i++) {
      final d = drills[i];
      final rate = d.participationRatePercent > 0
          ? d.participationRatePercent
          : (d.totalWorkersOnSite > 0 ? (d.participatedCount / d.totalWorkersOnSite) * 100.0 : 100.0);

      sheet.appendRow([
        IntCellValue(i + 1),
        IntCellValue(d.drillYear),
        TextCellValue(d.drillDate),
        TextCellValue('${d.startTime} - ${d.endTime}'),
        TextCellValue(d.drillTitle),
        TextCellValue(d.hazardType.shortTitle),
        TextCellValue(d.organizerType.label),
        TextCellValue(d.approvalCertNo),
        IntCellValue(d.totalWorkersOnSite),
        IntCellValue(d.participatedCount),
        IntCellValue(d.maleParticipants),
        IntCellValue(d.femaleParticipants),
        DoubleCellValue(double.parse(rate.toStringAsFixed(1))),
        IntCellValue(d.initialAttackTimeSec),
        IntCellValue(d.evacuationTimeSec),
        TextCellValue(d.headcountStatus.label),
        IntCellValue(d.simulatedInjuriesCount),
        TextCellValue(d.spr4SubmissionStatus.label),
        TextCellValue(d.submissionDeadline),
        TextCellValue(d.submittedDate ?? '-'),
      ]);
    }

    final bytes = excel.encode();
    if (bytes == null) throw Exception('Failed to generate Excel file');

    final dir = await _getExportDirectory();
    final fileName = 'Emergency_Drill_Register_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    final filePath = p.join(dir, fileName);
    final file = File(filePath);
    await file.writeAsBytes(bytes);

    if (context != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ส่งออกไฟล์ Excel สำเร็จ: $fileName'),
          backgroundColor: const Color(0xFF059669),
        ),
      );
    }

    return filePath;
  }

  /// ส่งออกรายการเช็คลิสต์ตรวจตราและจุดรวมพลของแผนฉุกเฉิน
  static Future<String> exportPlanDetails(EmergencyPlanModel plan, BuildContext? context) async {
    final excel = Excel.createExcel();

    // Sheet 1: การตรวจตรา
    const sheet1 = 'จุดตรวจตราความปลอดภัย';
    excel.rename('Sheet1', sheet1);
    final s1 = excel[sheet1];
    s1.appendRow([
      TextCellValue('ลำดับ'),
      TextCellValue('หมวดหมู่อุปกรณ์/จุดเสี่ยง'),
      TextCellValue('พื้นที่รับผิดชอบ'),
      TextCellValue('ความถี่'),
      TextCellValue('ผู้รับผิดชอบการตรวจ'),
    ]);
    for (int i = 0; i < plan.inspectionPlan.items.length; i++) {
      final it = plan.inspectionPlan.items[i];
      s1.appendRow([
        IntCellValue(i + 1),
        TextCellValue(it.category),
        TextCellValue(it.area),
        TextCellValue(it.frequency),
        TextCellValue(it.inspectorRole),
      ]);
    }

    // Sheet 2: จุดรวมพลและผู้นำทาง
    final s2 = excel['จุดรวมพลและผู้นำทาง'];
    s2.appendRow([
      TextCellValue('จุดรวมพล'),
      TextCellValue('ที่ตั้ง/ลักษณะพื้นที่'),
      TextCellValue('แผนกที่รับผิดชอบ'),
      TextCellValue('ความจุ (คน)'),
    ]);
    for (final p in plan.evacuationPlan.assemblyPoints) {
      s2.appendRow([
        TextCellValue(p.pointName),
        TextCellValue(p.location),
        TextCellValue(p.assignedDepartments),
        IntCellValue(p.capacity),
      ]);
    }

    final bytes = excel.encode();
    if (bytes == null) throw Exception('Failed to generate Excel file');

    final dir = await _getExportDirectory();
    final fileName = 'Plan_${plan.hazardType.code}_Details_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    final filePath = p.join(dir, fileName);
    final file = File(filePath);
    await file.writeAsBytes(bytes);

    if (context != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ส่งออกไฟล์ Excel แผนฉุกเฉินสำเร็จ: $fileName'),
          backgroundColor: const Color(0xFF059669),
        ),
      );
    }

    return filePath;
  }
}
