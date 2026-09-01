import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../domain/models/environment_standard_model.dart';
import '../domain/models/environment_session_model.dart';
import '../domain/models/environment_point_model.dart';
import '../domain/models/environment_capa_model.dart';
import '../domain/models/environment_kpi_summary.dart';
import '../domain/models/subcontractor_model.dart';

/// Multi-Sheet Excel (.xlsx) Export Service for Environmental Monitoring Report.
/// Generates authoritative statutory workbooks containing:
/// - Sheet 1: "สรุปภาพรวม (Summary)" - Executive overview, session details, and KPI compliance breakdown
/// - Sheet 2: "ผลการตรวจวัด (Measurements)" - Complete sampling points (Light, Noise, Heat WBGT) with standards and evaluation
/// - Sheet 3: "แผน CAPA" - Corrective & Preventive Action plans and Hearing Conservation Program enrollments
/// - Sheet 4: "ผู้รับจ้างตรวจวัด (Subcontractor)" - Service provider credentials (Section 9/11) and calibration certificates
class EnvironmentExcelExporter {
  /// Builds the complete multi-sheet Excel workbook and returns the raw bytes.
  static List<int>? exportToExcelBytes({
    required EnvironmentSessionModel session,
    required List<EnvironmentPointModel> points,
    required List<EnvironmentCapaModel> capas,
    required EnvironmentKpiSummary kpi,
    String? companyAddress,
  }) {
    final excel = Excel.createExcel();

    final orgName = session.workplaceName.isNotEmpty
        ? session.workplaceName
        : 'บริษัท โรงงานอุตสาหกรรมตัวอย่าง จำกัด (มหาชน)';
    final orgPlant = session.locationPlant.isNotEmpty ? session.locationPlant : 'โรงงานหลัก';
    final periodStr = 'ประจำปี พ.ศ. ${session.sessionYearBe} (รอบตรวจวัด ${session.sessionId})';
    final measDate = session.measurementDate.isNotEmpty
        ? session.measurementDate
        : DateTime.now().toIso8601String().substring(0, 10);
    final exportDate = DateTime.now().toIso8601String().substring(0, 10);

    // ========================================================================
    // SHEET 1: สรุปภาพรวม (Summary)
    // ========================================================================
    const sheet1Name = 'สรุปภาพรวม (Summary)';
    final sheet1 = excel[sheet1Name];
    excel.setDefaultSheet(sheet1Name);

    // Title banner
    sheet1.appendRow([
      TextCellValue('แบบรายงานผลการตรวจวัดและวิเคราะห์สภาวะการทำงานเกี่ยวกับความร้อน แสงสว่าง หรือเสียง (แบบ สสค.)'),
    ]);
    sheet1.appendRow([
      TextCellValue('สถานประกอบการ: $orgName ($orgPlant) | รอบการตรวจวัด: $periodStr | วันที่ตรวจวัด: $measDate | วันที่ส่งออกข้อมูล: $exportDate'),
    ]);
    sheet1.appendRow([
      TextCellValue('ผู้ให้บริการตรวจวัด: ${session.subcontractorCompanyName} (${session.subcontractorType.labelTh} เลขทะเบียน ${session.subcontractorRegNumber}) | ผู้ตรวจวัด: ${session.surveyorName} | ผู้รับรอง: ${session.certifierName}'),
    ]);
    sheet1.appendRow([
      TextCellValue('ดัชนีความสอดคล้องรวม: ${kpi.compliancePercentage}% | ผ่านเกณฑ์: ${kpi.passedPoints}/${kpi.totalPoints} จุด | เฝ้าระวัง Action Level: ${kpi.actionLevelPoints} จุด | เกินเกณฑ์: ${kpi.failedPoints} จุด'),
    ]);
    sheet1.appendRow([TextCellValue('')]); // Blank spacing row

    // KPI Summary Table
    sheet1.appendRow([
      TextCellValue('ปัจจัยสภาพแวดล้อม (Factor Type)'),
      TextCellValue('จำนวนจุดตรวจวัดทั้งหมด (Total Points)'),
      TextCellValue('ผ่านเกณฑ์มาตรฐาน (Passed)'),
      TextCellValue('เฝ้าระวัง Action Level / HCP'),
      TextCellValue('เกินเกณฑ์มาตรฐาน (Exceeded)'),
      TextCellValue('ร้อยละความสอดคล้อง (% Compliance)'),
      TextCellValue('สถานะการประเมินภาพรวม (Status Summary)'),
    ]);

    sheet1.appendRow([
      TextCellValue('แสงสว่าง (Lighting - Lux)'),
      IntCellValue(kpi.lightPoints),
      IntCellValue(kpi.lightPassed),
      IntCellValue(0),
      IntCellValue(kpi.lightFailed),
      DoubleCellValue(kpi.lightCompliancePercentage),
      TextCellValue(kpi.lightCompliancePercentage >= 100.0 ? 'สอดคล้องครบถ้วน' : 'มีจุดแสงสว่างไม่เพียงพอ'),
    ]);

    sheet1.appendRow([
      TextCellValue('เสียง (Noise - dBA/dB)'),
      IntCellValue(kpi.noisePoints),
      IntCellValue(kpi.noiseNormal),
      IntCellValue(kpi.noiseActionLevel),
      IntCellValue(kpi.noiseExceeded),
      DoubleCellValue(kpi.noiseCompliancePercentage),
      TextCellValue(kpi.noiseCompliancePercentage >= 100.0 && kpi.noiseActionLevel == 0 ? 'สอดคล้องครบถ้วน' : 'มีจุดต้องเฝ้าระวัง/ทำโครงการ HCP'),
    ]);

    sheet1.appendRow([
      TextCellValue('ความร้อน (Heat Stress - WBGT)'),
      IntCellValue(kpi.heatPoints),
      IntCellValue(kpi.heatPassed),
      IntCellValue(0),
      IntCellValue(kpi.heatFailed),
      DoubleCellValue(kpi.heatCompliancePercentage),
      TextCellValue(kpi.heatCompliancePercentage >= 100.0 ? 'สอดคล้องครบถ้วน' : 'มีจุดความร้อนเกินมาตรฐาน'),
    ]);

    sheet1.appendRow([
      TextCellValue('รวมสภาพแวดล้อมทั้งหมด (TOTAL SUMMARY)'),
      IntCellValue(kpi.totalPoints),
      IntCellValue(kpi.passedPoints),
      IntCellValue(kpi.actionLevelPoints),
      IntCellValue(kpi.failedPoints),
      DoubleCellValue(kpi.compliancePercentage),
      TextCellValue(kpi.compliancePercentage >= 90.0 ? 'ผ่านเกณฑ์ระดับดีเยี่ยม' : 'ต้องเร่งรัดมาตรการปรับปรุง CAPA'),
    ]);

    sheet1.appendRow([TextCellValue('')]); // Blank spacing row

    // Statutory Deadlines Notice
    sheet1.appendRow([
      TextCellValue('กำหนดเวลาตามกฎหมาย (Statutory Deadlines)'),
      TextCellValue('วันที่ตรวจวัด: $measDate'),
      TextCellValue('กำหนดปิดประกาศ ณ สถานประกอบการ (๑๕ วัน): ${session.postingDeadline ?? EnvironmentSessionModel.calculatePostingDeadline(measDate)}'),
      TextCellValue('กำหนดยื่นรายงานต่ออธิบดีกรมฯ (๓๐ วัน): ${session.submissionDeadline ?? EnvironmentSessionModel.calculateSubmissionDeadline(measDate)}'),
    ]);

    // ========================================================================
    // SHEET 2: ผลการตรวจวัด (Measurements)
    // ========================================================================
    const sheet2Name = 'ผลการตรวจวัด (Measurements)';
    final sheet2 = excel[sheet2Name];

    sheet2.appendRow([
      TextCellValue('ตารางบันทึกผลการตรวจวัดและประเมินสภาวะการทำงานรายจุด (Environmental Sampling & Measurement Points)'),
    ]);
    sheet2.appendRow([
      TextCellValue('สถานประกอบการ: $orgName | รหัสรอบ: ${session.sessionId} | วันที่ตรวจวัด: $measDate | จำนวนจุดทั้งหมด: ${points.length} จุด'),
    ]);
    sheet2.appendRow([TextCellValue('')]); // Spacing

    // Table Header Row
    sheet2.appendRow([
      TextCellValue('ลำดับ (No.)'),
      TextCellValue('รหัสจุด (Point ID)'),
      TextCellValue('ปัจจัยตรวจวัด (Factor Type)'),
      TextCellValue('แผนก / ฝ่าย (Department)'),
      TextCellValue('พื้นที่ / ตำแหน่งจุดตรวจวัด (Location Name)'),
      TextCellValue('ลักษณะงาน / เครื่องจักร (Task / Machine)'),
      TextCellValue('แสงสว่างที่วัดได้ (Measured Lux)'),
      TextCellValue('เกณฑ์แสงสว่างมาตรฐาน (Standard Min Lux)'),
      TextCellValue('แสงสว่างรอบจุดทำงาน (Surrounding Lux)'),
      TextCellValue('ประเภทการวัดเสียง (Noise Type)'),
      TextCellValue('ระดับเสียงที่วัดได้ (Measured dBA / Peak dB)'),
      TextCellValue('ระยะเวลาสัมผัสเสียง ชม. (Exposure Hours)'),
      TextCellValue('ร้อยละปริมาณเสียงสะสม (% Noise Dose)'),
      TextCellValue('เกณฑ์มาตรฐานเสียง (Noise Limit)'),
      TextCellValue('สภาพแสงแดดความร้อน (Heat Solar Exposure)'),
      TextCellValue('อุณหภูมิ NWB (°C)'),
      TextCellValue('อุณหภูมิ GT (°C)'),
      TextCellValue('อุณหภูมิ DB (°C)'),
      TextCellValue('ค่า WBGT ที่คำนวณได้ (°C)'),
      TextCellValue('ลักษณะภาระงานความร้อน (Heat Workload)'),
      TextCellValue('เกณฑ์มาตรฐาน WBGT (°C)'),
      TextCellValue('ผลการประเมินตามกฎหมาย (Evaluation Status)'),
      TextCellValue('ต้องเข้าโครงการอนุรักษ์การได้ยิน (Requires HCP)'),
      TextCellValue('ต้องจัดทำแผน CAPA (Requires CAPA)'),
      TextCellValue('หมายเหตุเพิ่มเติม (Notes)'),
    ]);

    for (int i = 0; i < points.length; i++) {
      final pt = points[i];

      String factorTh = pt.factorType.labelTh;
      String statusTh = pt.evaluationStatus.labelTh;

      String solarTh = '-';
      if (pt.heatSolarExposure != null) {
        solarTh = pt.heatSolarExposure == HeatSolarExposure.outdoorWithSolar ? 'กลางแจ้ง' : 'ในร่ม';
      }

      sheet2.appendRow([
        IntCellValue(i + 1),
        TextCellValue(pt.pointId),
        TextCellValue(factorTh),
        TextCellValue(pt.department),
        TextCellValue(pt.locationName),
        TextCellValue(pt.taskOrMachineName ?? pt.lightTaskDescription ?? '-'),
        pt.lightMeasuredLux != null ? DoubleCellValue(pt.lightMeasuredLux!) : TextCellValue('-'),
        pt.lightStandardMinLux != null ? DoubleCellValue(pt.lightStandardMinLux!) : TextCellValue('-'),
        pt.lightSurroundingLux != null ? DoubleCellValue(pt.lightSurroundingLux!) : TextCellValue('-'),
        TextCellValue(pt.noiseMeasurementType?.labelTh ?? '-'),
        pt.noiseMeasuredDba != null
            ? DoubleCellValue(pt.noiseMeasuredDba!)
            : (pt.noisePeakDb != null ? DoubleCellValue(pt.noisePeakDb!) : TextCellValue('-')),
        pt.noiseExposureDurationHours != null ? DoubleCellValue(pt.noiseExposureDurationHours!) : TextCellValue('-'),
        pt.noiseDosePercent != null ? DoubleCellValue(pt.noiseDosePercent!) : TextCellValue('-'),
        pt.factorType == EnvironmentFactorType.noise
            ? TextCellValue(pt.noiseMeasurementType == NoiseMeasurementType.peakSoundLevel
                ? '<= ${pt.noisePeakLimit} dB'
                : '<= ${pt.noiseStandardTwaLimit} dBA')
            : TextCellValue('-'),
        TextCellValue(solarTh),
        pt.heatNwbCelsius != null ? DoubleCellValue(pt.heatNwbCelsius!) : TextCellValue('-'),
        pt.heatGtCelsius != null ? DoubleCellValue(pt.heatGtCelsius!) : TextCellValue('-'),
        pt.heatDbCelsius != null ? DoubleCellValue(pt.heatDbCelsius!) : TextCellValue('-'),
        pt.heatCalculatedWbgt != null ? DoubleCellValue(pt.heatCalculatedWbgt!) : TextCellValue('-'),
        TextCellValue(pt.heatWorkloadType?.labelTh ?? '-'),
        pt.heatStandardLimitWbgt != null ? DoubleCellValue(pt.heatStandardLimitWbgt!) : TextCellValue('-'),
        TextCellValue(statusTh),
        TextCellValue(pt.requiresHearingConservation ? 'ใช่ (>= 85 dBA)' : 'ไม่ใช่'),
        TextCellValue(pt.requiresCapa ? 'ใช่ (ต้องปรับปรุง)' : 'ไม่ใช่'),
        TextCellValue(pt.notes ?? '-'),
      ]);
    }

    // ========================================================================
    // SHEET 3: แผน CAPA
    // ========================================================================
    const sheet3Name = 'แผน CAPA';
    final sheet3 = excel[sheet3Name];

    sheet3.appendRow([
      TextCellValue('แบบรายงานแผนการปรับปรุงแก้ไขสภาวะแวดล้อมในการทำงาน (Environmental CAPA Action Plan)'),
    ]);
    sheet3.appendRow([
      TextCellValue('สถานประกอบการ: $orgName | รหัสรอบ: ${session.sessionId} | แผนงานทั้งหมด: ${capas.length} รายการ | เสร็จสิ้น: ${kpi.capaCompletedCount} | รอดำเนินการ: ${kpi.capaPendingCount} | เกินกำหนด: ${kpi.capaOverdueCount}'),
    ]);
    sheet3.appendRow([TextCellValue('')]); // Spacing

    sheet3.appendRow([
      TextCellValue('ลำดับ (No.)'),
      TextCellValue('รหัส CAPA (CAPA ID)'),
      TextCellValue('รหัสจุดตรวจวัด (Point ID)'),
      TextCellValue('ปัจจัยสิ่งแวดล้อม (Factor Type)'),
      TextCellValue('หัวข้อแผนงานปรับปรุง (Action Title)'),
      TextCellValue('สภาพปัญหาความไม่สอดคล้อง (Hazard Description)'),
      TextCellValue('สาเหตุรากเหง้า (Root Cause)'),
      TextCellValue('มาตรการทางวิศวกรรม (Engineering Control)'),
      TextCellValue('มาตรการบริหารจัดการ (Administrative Control)'),
      TextCellValue('การใช้อุปกรณ์ PPE (PPE Control)'),
      TextCellValue('ผู้รับผิดชอบหลัก (Person In Charge - PIC)'),
      TextCellValue('แผนก/ฝ่ายผู้รับผิดชอบ (Department)'),
      TextCellValue('กำหนดแล้วเสร็จ (Target Date)'),
      TextCellValue('วันที่แล้วเสร็จจริง (Completed Date)'),
      TextCellValue('สถานะการดำเนินงาน (Status)'),
      TextCellValue('โครงการอนุรักษ์การได้ยิน (HCP Enrolled)'),
      TextCellValue('หลักฐานการปิดงาน (Evidence File)'),
      TextCellValue('หมายเหตุเพิ่มเติม (Remarks)'),
    ]);

    if (capas.isEmpty) {
      sheet3.appendRow([
        IntCellValue(1),
        TextCellValue('-'),
        TextCellValue('-'),
        TextCellValue('-'),
        TextCellValue('ผลการตรวจวัดสอดคล้องตามเกณฑ์มาตรฐานทุกจุด (ไม่มีรายการที่ต้องเปิดแผน CAPA ในรอบนี้)'),
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
        TextCellValue('ไม่อยู่ในเกณฑ์'),
        TextCellValue('-'),
        TextCellValue('-'),
      ]);
    } else {
      for (int i = 0; i < capas.length; i++) {
        final c = capas[i];
        sheet3.appendRow([
          IntCellValue(i + 1),
          TextCellValue(c.capaId),
          TextCellValue(c.pointId ?? '-'),
          TextCellValue(c.factorType.labelTh),
          TextCellValue(c.actionTitle),
          TextCellValue(c.hazardDescription),
          TextCellValue(c.rootCause),
          TextCellValue(c.engineeringControl ?? '-'),
          TextCellValue(c.administrativeControl ?? '-'),
          TextCellValue(c.ppeControl ?? '-'),
          TextCellValue(c.picName),
          TextCellValue(c.picDepartment ?? '-'),
          TextCellValue(c.targetDate),
          TextCellValue(c.completedDate ?? '-'),
          TextCellValue(c.statusLabelTh),
          TextCellValue(c.hearingProgramEnrolled ? 'เข้าโครงการ HCP' : 'ไม่ใช่'),
          TextCellValue(c.evidenceFilePath ?? '-'),
          TextCellValue(c.notes ?? '-'),
        ]);
      }
    }

    // ========================================================================
    // SHEET 4: ผู้รับจ้างตรวจวัด (Subcontractor)
    // ========================================================================
    const sheet4Name = 'ผู้รับจ้างตรวจวัด (Subcontractor)';
    final sheet4 = excel[sheet4Name];

    sheet4.appendRow([
      TextCellValue('ข้อมูลผู้ให้บริการตรวจวัดและรับรองผลสภาวะการทำงานตามกฎหมาย (ม.๙ นบ. / ม.๑๑ บ.)'),
    ]);
    sheet4.appendRow([
      TextCellValue('สถานประกอบการผู้ว่าจ้าง: $orgName | รหัสรอบตรวจวัด: ${session.sessionId} | วันที่ตรวจวัด: $measDate'),
    ]);
    sheet4.appendRow([TextCellValue('')]); // Spacing

    sheet4.appendRow([
      TextCellValue('หัวข้อข้อมูล (Data Field)'),
      TextCellValue('รายละเอียด (Details)'),
      TextCellValue('ข้อกำหนดตามกฎหมาย (Statutory Requirement)'),
    ]);

    sheet4.appendRow([
      TextCellValue('ชื่อบริษัท / ผู้ให้บริการตรวจวัด'),
      TextCellValue(session.subcontractorCompanyName),
      TextCellValue('นิติบุคคล ม.๑๑ หรือบุคคลธรรมดา ม.๙'),
    ]);

    sheet4.appendRow([
      TextCellValue('ประเภทการขึ้นทะเบียน'),
      TextCellValue(session.subcontractorType.labelTh),
      TextCellValue('ม.๙ (นบ.) หรือ ม.๑๑ (บ.) หรือ จป.วิชาชีพประจำ'),
    ]);

    sheet4.appendRow([
      TextCellValue('เลขทะเบียน / เลขที่ใบอนุญาต'),
      TextCellValue(session.subcontractorRegNumber),
      TextCellValue('ต้องขึ้นทะเบียนกับกรมสวัสดิการและคุ้มครองแรงงาน'),
    ]);

    sheet4.appendRow([
      TextCellValue('ชื่อผู้ทำการตรวจวัด (Surveyor)'),
      TextCellValue(session.surveyorName),
      TextCellValue('เจ้าหน้าที่ผู้ผ่านการฝึกอบรมหรือมีคุณสมบัติตามกฎหมาย'),
    ]);

    sheet4.appendRow([
      TextCellValue('เลขที่ใบอนุญาต/วุฒิบัตรผู้ตรวจวัด'),
      TextCellValue(session.surveyorLicenseNo ?? '-'),
      TextCellValue('เอกสารรับรองคุณวุฒิผู้ตรวจวัด'),
    ]);

    sheet4.appendRow([
      TextCellValue('ชื่อผู้รับรองรายงาน (Certifier)'),
      TextCellValue(session.certifierName),
      TextCellValue('ผู้ขึ้นทะเบียน ม.๙ หรือผู้ควบคุม ม.๑๑'),
    ]);

    sheet4.appendRow([
      TextCellValue('เลขทะเบียนผู้รับรองรายงาน'),
      TextCellValue(session.certifierRegNo ?? session.subcontractorRegNumber),
      TextCellValue('เลขทะเบียน นบ. หรือ บ. ที่ยังไม่หมดอายุ'),
    ]);

    sheet4.appendRow([
      TextCellValue('ใบรับรองการสอบเทียบเครื่องมือ (Calibration Certs)'),
      TextCellValue('${session.calibrationCertPaths.length} ฉบับ (${session.calibrationCertPaths.join(", ")})'),
      TextCellValue('เครื่องมือวัดต้องผ่านการสอบเทียบตามมาตรฐาน ISO/IEC 17025 มีอายุไม่เกิน ๑ ปี'),
    ]);

    sheet4.appendRow([
      TextCellValue('เล่มรายงานฉบับสมบูรณ์ (PDF Report)'),
      TextCellValue(session.pdfReportPath ?? 'ไม่มีการแนบไฟล์'),
      TextCellValue('รายงานผลตามแบบอธิบดีประกาศกำหนด'),
    ]);

    sheet4.appendRow([
      TextCellValue('สถานะรอบการตรวจวัด'),
      TextCellValue(session.status.labelTh),
      TextCellValue('ปิดประกาศผลใน ๑๕ วัน และส่งรายงานต่อกรมฯ ใน ๓๐ วัน'),
    ]);

    // Delete default Sheet1 if generated automatically
    if (excel.tables.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    return excel.save();
  }

  /// Exports the multi-sheet Excel file directly to the app's export documents directory
  /// and returns the absolute file path.
  static Future<String?> exportToExcelFile({
    required EnvironmentSessionModel session,
    required List<EnvironmentPointModel> points,
    required List<EnvironmentCapaModel> capas,
    required EnvironmentKpiSummary kpi,
    String? companyAddress,
  }) async {
    final fileBytes = exportToExcelBytes(
      session: session,
      points: points,
      capas: capas,
      kpi: kpi,
      companyAddress: companyAddress,
    );

    if (fileBytes == null) return null;

    final appDocDir = await getApplicationDocumentsDirectory();
    final exportDir = Directory(p.join(appDocDir.path, 'SafetySuperapp', 'exports'));
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }

    final filename = 'SAFAPP_Environmental_Report_${session.sessionId}_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    final targetPath = p.join(exportDir.path, filename);
    final file = File(targetPath);
    await file.writeAsBytes(fileBytes);

    return targetPath;
  }
}
