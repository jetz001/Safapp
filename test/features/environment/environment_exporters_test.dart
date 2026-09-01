import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:excel/excel.dart';

import 'package:safety_superapp/features/environment/domain/models/environment_standard_model.dart';
import 'package:safety_superapp/features/environment/domain/models/environment_session_model.dart';
import 'package:safety_superapp/features/environment/domain/models/environment_point_model.dart';
import 'package:safety_superapp/features/environment/domain/models/environment_capa_model.dart';
import 'package:safety_superapp/features/environment/domain/models/environment_kpi_summary.dart';
import 'package:safety_superapp/features/environment/domain/models/subcontractor_model.dart';
import 'package:safety_superapp/features/environment/services/environment_pdf_exporter.dart';
import 'package:safety_superapp/features/environment/services/environment_excel_exporter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final sampleSession = const EnvironmentSessionModel(
    id: 1,
    sessionId: 'ENV-SESS-2026-001',
    sessionTitle: 'การตรวจวัดสภาพแวดล้อมประจำปี 2569',
    sessionYearBe: 2569,
    sessionYearAd: 2026,
    measurementDate: '2026-09-01',
    reportReceivedDate: '2026-09-05',
    postingDeadline: '2026-09-16',
    submissionDeadline: '2026-10-01',
    locationPlant: 'โรงงาน 1 (คลองหลวง)',
    workplaceName: 'บริษัท ทดสอบอุตสาหกรรม จำกัด',
    workplaceAddress: '123/45 นิคมอุตสาหกรรม จ.ปทุมธานี',
    objective: 'ตรวจวัดตาม พ.ร.บ. ความปลอดภัยฯ ๒๕๕๔ & กฎกระทรวงฯ ๒๕๕๙',
    subcontractorType: SubcontractorType.section11Juristic,
    subcontractorCompanyName: 'บริษัท ตรวจวัดสิ่งแวดล้อมไทย จำกัด',
    subcontractorRegNumber: 'บ. 0123-45/2565',
    surveyorName: 'นายสุรเชษฐ์ ตรวจวัด',
    surveyorLicenseNo: 'ENV-TECH-001',
    certifierName: 'ดร.สมชาย ผู้รับรอง',
    certifierRegNo: 'บ. 0123-45/2565',
    pdfReportPath: '/dummy/report.pdf',
    calibrationCertPaths: ['/dummy/sound_cal.pdf', '/dummy/lux_cal.pdf'],
    subcontractorLicensePath: '/dummy/license_m11.pdf',
    sitePhotoPaths: ['/dummy/site1.jpg'],
    status: EnvironmentSessionStatus.measured,
  );

  final samplePoints = [
    // 1. Light Point (Pass)
    const EnvironmentPointModel(
      pointId: 'PT-ENV-LIGHT-001',
      sessionId: 'ENV-SESS-2026-001',
      factorType: EnvironmentFactorType.light,
      department: 'ฝ่ายผลิต',
      locationName: 'โต๊ะประกอบ 1',
      taskOrMachineName: 'งานประกอบทั่วไป',
      evaluationStatus: EnvironmentEvaluationStatus.pass,
      lightCategoryCode: 'LIGHT-CAT2-04',
      lightTaskDescription: 'งานประกอบชิ้นส่วน',
      lightMeasuredLux: 350.0,
      lightStandardMinLux: 300.0,
      lightSurroundingLux: 200.0,
      lightIsCompliant: true,
    ),
    // 2. Light Point (Fail)
    const EnvironmentPointModel(
      pointId: 'PT-ENV-LIGHT-002',
      sessionId: 'ENV-SESS-2026-001',
      factorType: EnvironmentFactorType.light,
      department: 'คลังสินค้า',
      locationName: 'ทางเดินหลัก',
      taskOrMachineName: 'ทางสัญจร',
      evaluationStatus: EnvironmentEvaluationStatus.fail,
      lightCategoryCode: 'LIGHT-CAT1-02',
      lightTaskDescription: 'ทางสัญจรในอาคาร',
      lightMeasuredLux: 35.0,
      lightStandardMinLux: 50.0,
      lightIsCompliant: false,
    ),
    // 3. Noise Point (Pass)
    const EnvironmentPointModel(
      pointId: 'PT-ENV-NOISE-001',
      sessionId: 'ENV-SESS-2026-001',
      factorType: EnvironmentFactorType.noise,
      department: 'สำนักงาน',
      locationName: 'ห้องทำงานวิศวกร',
      taskOrMachineName: 'งานเอกสาร',
      evaluationStatus: EnvironmentEvaluationStatus.pass,
      noiseMeasurementType: NoiseMeasurementType.leq8hrTwa,
      noiseMeasuredDba: 68.0,
      noiseStandardTwaLimit: 86.0,
      noiseActionLevelThreshold: 85.0,
    ),
    // 4. Noise Point (Action Level - HCP Required)
    const EnvironmentPointModel(
      pointId: 'PT-ENV-NOISE-002',
      sessionId: 'ENV-SESS-2026-001',
      factorType: EnvironmentFactorType.noise,
      department: 'ฝ่ายผลิต',
      locationName: 'เครื่องปั๊มโลหะ 1',
      taskOrMachineName: 'ปั๊มขึ้นรูปชิ้นงาน',
      evaluationStatus: EnvironmentEvaluationStatus.actionLevel,
      noiseMeasurementType: NoiseMeasurementType.leq8hrTwa,
      noiseMeasuredDba: 85.5,
      noiseStandardTwaLimit: 86.0,
      noiseActionLevelThreshold: 85.0,
      noiseIsHcpRequired: true,
    ),
    // 5. Noise Point (Fail - Exceed Limit)
    const EnvironmentPointModel(
      pointId: 'PT-ENV-NOISE-003',
      sessionId: 'ENV-SESS-2026-001',
      factorType: EnvironmentFactorType.noise,
      department: 'ฝ่ายผลิต',
      locationName: 'เครื่องเจียรโลหะ',
      taskOrMachineName: 'เจียรแต่งผิว',
      evaluationStatus: EnvironmentEvaluationStatus.fail,
      noiseMeasurementType: NoiseMeasurementType.peakSoundLevel,
      noisePeakDb: 142.0,
      noisePeakLimit: 140.0,
    ),
    // 6. Heat Point (Pass)
    const EnvironmentPointModel(
      pointId: 'PT-ENV-HEAT-001',
      sessionId: 'ENV-SESS-2026-001',
      factorType: EnvironmentFactorType.heat,
      department: 'คลังสินค้า',
      locationName: 'พื้นที่เบิกจ่าย',
      evaluationStatus: EnvironmentEvaluationStatus.pass,
      heatSolarExposure: HeatSolarExposure.indoorNoSolar,
      heatNwbCelsius: 24.0,
      heatGtCelsius: 30.0,
      heatDbCelsius: 28.0,
      heatCalculatedWbgt: 25.8,
      heatWorkloadType: WorkloadLevel.light,
      heatStandardLimitWbgt: 34.0,
      heatIsCompliant: true,
    ),
    // 7. Heat Point (Fail)
    const EnvironmentPointModel(
      pointId: 'PT-ENV-HEAT-002',
      sessionId: 'ENV-SESS-2026-001',
      factorType: EnvironmentFactorType.heat,
      department: 'ฝ่ายหลอมโลหะ',
      locationName: 'หน้าเตาหลอม',
      evaluationStatus: EnvironmentEvaluationStatus.fail,
      heatSolarExposure: HeatSolarExposure.indoorNoSolar,
      heatNwbCelsius: 31.0,
      heatGtCelsius: 40.0,
      heatDbCelsius: 38.0,
      heatCalculatedWbgt: 33.7,
      heatWorkloadType: WorkloadLevel.heavy,
      heatStandardLimitWbgt: 30.0,
      heatIsCompliant: false,
    ),
  ];

  final sampleCapas = [
    const EnvironmentCapaModel(
      capaId: 'CAPA-ENV-2026-001',
      pointId: 'PT-ENV-LIGHT-002',
      sessionId: 'ENV-SESS-2026-001',
      factorType: EnvironmentFactorType.light,
      actionTitle: 'ติดตั้งหลอดไฟ LED เพิ่มเติมบริเวณทางเดินคลังสินค้า',
      hazardDescription: 'แสงสว่าง 35 Lux ต่ำกว่ามาตรฐาน 50 Lux',
      rootCause: 'หลอดไฟเดิมเสื่อมสภาพและตำแหน่งติดตั้งอยู่ห่างเกินไป',
      engineeringControl: 'เปลี่ยนเป็นหลอด LED 40W และเพิ่มตำแหน่งโคมไฟ 2 จุด',
      administrativeControl: 'จัดตารางทำความสะอาดโคมไฟทุก 3 เดือน',
      ppeControl: '-',
      picName: 'นายสมศักดิ์ ช่างไฟฟ้า',
      picDepartment: 'ฝ่ายซ่อมบำรุง',
      targetDate: '2026-09-30',
      status: 'IN_PROGRESS',
    ),
    const EnvironmentCapaModel(
      capaId: 'CAPA-ENV-2026-002',
      pointId: 'PT-ENV-NOISE-002',
      sessionId: 'ENV-SESS-2026-001',
      factorType: EnvironmentFactorType.noise,
      actionTitle: 'ขึ้นทะเบียนโครงการอนุรักษ์การได้ยินสำหรับผู้ควบคุมเครื่องปั๊ม',
      hazardDescription: 'ระดับเสียง 85.5 dBA อยู่ในระดับเฝ้าระวัง Action Level',
      rootCause: 'เสียงจากการทำงานของเครื่องปั๊มโลหะ',
      engineeringControl: 'ติดตั้งแผ่นซับเสียงรอบตัวเครื่อง',
      administrativeControl: 'อบรมโครงการอนุรักษ์การได้ยินและตรวจสมรรถภาพการได้ยินประจำปี',
      ppeControl: 'บังคับสวมใส่ที่อุดหู Earplugs NRR 25',
      picName: 'น.ส.ดาราวรรณ จป.วิชาชีพ',
      picDepartment: 'ฝ่ายความปลอดภัย',
      targetDate: '2026-09-20',
      status: 'PENDING',
      hearingProgramEnrolled: true,
    ),
  ];

  final sampleKpi = EnvironmentKpiSummary.calculate(
    points: samplePoints,
    capas: sampleCapas,
  );

  group('EnvironmentPdfExporter Tests', () {
    test('generatePdf produces valid non-empty PDF bytes', () async {
      final pdfBytes = await EnvironmentPdfExporter.generatePdf(
        session: sampleSession,
        points: samplePoints,
        capas: sampleCapas,
        kpi: sampleKpi,
      );

      expect(pdfBytes, isNotNull);
      expect(pdfBytes.length, greaterThan(1000));
      // PDF file magic header (%PDF-)
      final header = String.fromCharCodes(pdfBytes.sublist(0, 5));
      expect(header, equals('%PDF-'));
    });

    test('generatePdf handles empty points and capas without error', () async {
      final emptyKpi = EnvironmentKpiSummary.calculate(points: const [], capas: const []);
      final pdfBytes = await EnvironmentPdfExporter.generatePdf(
        session: sampleSession,
        points: const [],
        capas: const [],
        kpi: emptyKpi,
      );

      expect(pdfBytes, isNotNull);
      expect(pdfBytes.length, greaterThan(500));
    });
  });

  group('EnvironmentExcelExporter Tests', () {
    test('exportToExcelBytes creates workbook with all 4 statutory sheets', () {
      final excelBytes = EnvironmentExcelExporter.exportToExcelBytes(
        session: sampleSession,
        points: samplePoints,
        capas: sampleCapas,
        kpi: sampleKpi,
      );

      expect(excelBytes, isNotNull);
      expect(excelBytes!.length, greaterThan(500));

      // Decode bytes and check sheet names
      final excel = Excel.decodeBytes(excelBytes);
      expect(excel.tables.keys, contains('สรุปภาพรวม (Summary)'));
      expect(excel.tables.keys, contains('ผลการตรวจวัด (Measurements)'));
      expect(excel.tables.keys, contains('แผน CAPA'));
      expect(excel.tables.keys, contains('ผู้รับจ้างตรวจวัด (Subcontractor)'));

      // Check rows in measurements sheet
      final measSheet = excel.tables['ผลการตรวจวัด (Measurements)'];
      expect(measSheet, isNotNull);
      expect(measSheet!.maxRows, greaterThan(samplePoints.length));

      // Check summary sheet
      final summarySheet = excel.tables['สรุปภาพรวม (Summary)'];
      expect(summarySheet, isNotNull);
      expect(summarySheet!.maxRows, greaterThan(4));
    });

    test('exportToExcelBytes handles empty lists gracefully', () {
      final emptyKpi = EnvironmentKpiSummary.calculate(points: const [], capas: const []);
      final excelBytes = EnvironmentExcelExporter.exportToExcelBytes(
        session: sampleSession,
        points: const [],
        capas: const [],
        kpi: emptyKpi,
      );

      expect(excelBytes, isNotNull);
      final excel = Excel.decodeBytes(excelBytes!);
      expect(excel.tables.keys, contains('สรุปภาพรวม (Summary)'));
      expect(excel.tables.keys, contains('แผน CAPA'));
    });
  });
}
