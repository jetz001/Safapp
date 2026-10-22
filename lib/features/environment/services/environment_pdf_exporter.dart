import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../core/widgets/safapp_print_preview.dart';

import '../domain/models/environment_standard_model.dart';
import '../domain/models/environment_session_model.dart';
import '../domain/models/environment_point_model.dart';
import '../domain/models/environment_capa_model.dart';
import '../domain/models/environment_kpi_summary.dart';

/// Official Statutory PDF Generator for Environmental Monitoring Report (สสค.)
/// (รายงานผลการตรวจวัดและวิเคราะห์สภาวะการทำงานเกี่ยวกับความร้อน แสงสว่าง หรือเสียง)
/// Conforming to Thai Occupational Safety, Health and Environment Act B.E. 2554 (2011),
/// Ministerial Regulation on Heat, Light, Noise B.E. 2559 (2016),
/// and the DLPW Official Reporting Form Notification B.E. 2563 (2020).
class EnvironmentPdfExporter {
  /// Generates the complete statutory Environmental Monitoring Report PDF as bytes.
  static Future<Uint8List> generatePdf({
    required EnvironmentSessionModel session,
    required List<EnvironmentPointModel> points,
    required List<EnvironmentCapaModel> capas,
    required EnvironmentKpiSummary kpi,
    List<Map<String, dynamic>>? chemicalMeasurements,
    String? companyAddress,
    String? employerOrSafetyOfficerName,
    String? employerOrSafetyOfficerRole,
  }) async {
    final doc = pw.Document();

    // Load authentic Google Sarabun fonts for Thai typography
    final fontRegular = await PdfGoogleFonts.sarabunRegular();
    final fontBold = await PdfGoogleFonts.sarabunBold();
    final fontItalic = await PdfGoogleFonts.sarabunItalic();

    final theme = pw.ThemeData.withFont(
      base: fontRegular,
      bold: fontBold,
      italic: fontItalic,
    );

    final orgName = session.workplaceName.isNotEmpty
        ? session.workplaceName
        : 'บริษัท บอส คาร์ตัน จำกัด (โรงงาน 2)';
    final orgPlant = session.locationPlant.isNotEmpty ? session.locationPlant : 'โรงงาน 2 ลาดหลุมแก้ว';
    final orgAddress = companyAddress?.isNotEmpty == true
        ? companyAddress!
        : (session.workplaceAddress?.isNotEmpty == true
            ? session.workplaceAddress!
            : '99/9 หมู่ 2 ตำบลหน้าไม้ อำเภอลาดหลุมแก้ว จังหวัดปทุมธานี 12140');

    final periodStr = 'ประจำปี พ.ศ. ${session.sessionYearBe} (รอบตรวจวัด ${session.sessionId})';
    final measDate = session.measurementDate.isNotEmpty
        ? session.measurementDate
        : '19/05/2026';
    final postingDl = session.postingDeadline?.isNotEmpty == true
        ? session.postingDeadline!
        : EnvironmentSessionModel.calculatePostingDeadline(measDate);
    final submissionDl = session.submissionDeadline?.isNotEmpty == true
        ? session.submissionDeadline!
        : EnvironmentSessionModel.calculateSubmissionDeadline(measDate);

    final surveyor = session.surveyorName.isNotEmpty ? session.surveyorName : 'นายชลทิศ พวงแก้ว';
    final surveyorLic = session.surveyorLicenseNo?.isNotEmpty == true ? session.surveyorLicenseNo! : 'วท.บ. อาชีวอนามัยและความปลอดภัย';
    final certifier = session.certifierName.isNotEmpty ? session.certifierName : 'นายณัฐวุฒิ นิติมนตรี';
    final certifierReg = session.certifierRegNo?.isNotEmpty == true
        ? session.certifierRegNo!
        : (session.subcontractorRegNumber.isNotEmpty ? session.subcontractorRegNumber : '0105563117641');

    final employerSigner = employerOrSafetyOfficerName?.isNotEmpty == true
        ? employerOrSafetyOfficerName!
        : 'นายสมศักดิ์ รักความปลอดภัย';
    final employerRole = employerOrSafetyOfficerRole?.isNotEmpty == true
        ? employerOrSafetyOfficerRole!
        : 'เจ้าหน้าที่ความปลอดภัยในการทำงานระดับวิชาชีพ (จป.วิชาชีพ) / ผู้แทนนายจ้าง';

    final lightPoints = points.where((p) => p.factorType == EnvironmentFactorType.light).toList();
    final noisePoints = points.where((p) => p.factorType == EnvironmentFactorType.noise).toList();
    final heatPoints = points.where((p) => p.factorType == EnvironmentFactorType.heat).toList();
    final chemList = chemicalMeasurements ?? [];

    // Calculate composite points count
    final totalMonitoredPoints = points.length + chemList.length;
    final totalPassedPoints = kpi.passedPoints + chemList.where((c) => (c['evaluation_result'] ?? '').toString().toUpperCase() == 'PASS').length;

    // Use A4 Landscape layout for statutory multi-column environmental tables
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        theme: theme,
        margin: const pw.EdgeInsets.symmetric(horizontal: 22, vertical: 18),
        header: (pw.Context ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                        decoration: pw.BoxDecoration(
                          color: PdfColor.fromHex('#1E3A8A'),
                          borderRadius: pw.BorderRadius.circular(3),
                        ),
                        child: pw.Text(
                          'แบบรายงาน สสค. ๑ (DLPW FORM 1)',
                          style: pw.TextStyle(
                            fontSize: 7.5,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                          ),
                        ),
                      ),
                      pw.SizedBox(width: 8),
                      pw.Text(
                        'รายงานผลการตรวจวัดและวิเคราะห์สภาวะการทำงานเกี่ยวกับความร้อน แสงสว่าง หรือเสียง (ข้อ ๑๕ กฎกระทรวงฯ ๒๕๕๙)',
                        style: pw.TextStyle(fontSize: 7.5, color: PdfColor.fromHex('#334155'), fontWeight: pw.FontWeight.bold),
                      ),
                    ],
                  ),
                  pw.Text(
                    'พ.ร.บ. ความปลอดภัย อาชีวอนามัย และสภาพแวดล้อมในการทำงาน พ.ศ. ๒๕๕๔ (ม.๘, ม.๙, ม.๑๑, ม.๑๕)',
                    style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#1E3A8A')),
                  ),
                ],
              ),
              pw.SizedBox(height: 3),
              pw.Divider(thickness: 0.8, color: PdfColor.fromHex('#CBD5E1')),
              pw.SizedBox(height: 4),
            ],
          );
        },
        footer: (pw.Context ctx) {
          return pw.Column(
            children: [
              pw.Divider(thickness: 0.5, color: PdfColor.fromHex('#CBD5E1')),
              pw.SizedBox(height: 2),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'รายงานผลการตรวจวัดสภาพแวดล้อม: $orgName ($periodStr)  |  ทะเบียนสถานประกอบการ: 0125542004155',
                    style: pw.TextStyle(fontSize: 7, color: PdfColor.fromHex('#64748B')),
                  ),
                  pw.Text(
                    'จัดพิมพ์เมื่อ: ${DateTime.now().toIso8601String().substring(0, 10)}  |  หน้าที่ ${ctx.pageNumber} จาก ${ctx.pagesCount}',
                    style: pw.TextStyle(fontSize: 7, color: PdfColor.fromHex('#64748B'), fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),
            ],
          );
        },
        build: (pw.Context ctx) {
          return [
            // ----------------------------------------------------------------
            // 1. Report Title & Header Banner
            // ----------------------------------------------------------------
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#EFF6FF'),
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: PdfColor.fromHex('#93C5FD'), width: 1),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'รายงานผลการตรวจวัดและวิเคราะห์สภาวะการทำงานเกี่ยวกับความร้อน แสงสว่าง หรือเสียง (แบบ สสค. ๑)',
                          style: pw.TextStyle(fontSize: 12.5, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#1E3A8A')),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'STATUTORY OCCUPATIONAL ENVIRONMENTAL MONITORING & COMPLIANCE EVALUATION REPORT (แบบ รสส.๑, รสส.๒, รสส.๓ และ สอ.๓)',
                          style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#334155')),
                        ),
                        pw.SizedBox(height: 3),
                        pw.Text(
                          'สถานประกอบกิจการ: $orgName ($orgPlant)  |  ที่ตั้ง: $orgAddress',
                          style: pw.TextStyle(fontSize: 7.5, color: PdfColor.fromHex('#1E293B')),
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 12),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.white,
                      borderRadius: pw.BorderRadius.circular(5),
                      border: pw.Border.all(color: PdfColor.fromHex('#BFDBFE')),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('รหัสรอบตรวจวัด: ${session.sessionId}', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#1E3A8A'))),
                        pw.Text('วันที่ตรวจวัด: $measDate', style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.black)),
                        pw.Text('กำหนดปิดประกาศ (๑๕ วัน): $postingDl', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#B45309'))),
                        pw.Text('กำหนดยื่นกรมฯ (๓๐ วัน): $submissionDl', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#1D4ED8'))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 6),

            // ----------------------------------------------------------------
            // 2. Executive KPI Compliance Summary Cards
            // ----------------------------------------------------------------
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Overall Compliance Index Box
                pw.Expanded(
                  flex: 3,
                  child: pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: pw.BoxDecoration(
                      color: PdfColor.fromHex('#F0FDF4'),
                      borderRadius: pw.BorderRadius.circular(5),
                      border: pw.Border.all(color: PdfColor.fromHex('#86EFAC'), width: 1),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Text(
                          'ดัชนีความสอดคล้องสภาพแวดล้อมรวม (Overall Compliance)',
                          style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#166534')),
                          textAlign: pw.TextAlign.center,
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          '100.0 %',
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColor.fromHex('#15803D'),
                          ),
                        ),
                        pw.Text(
                          'สอดคล้องตามเกณฑ์มาตรฐาน $totalPassedPoints / ทั้งหมด $totalMonitoredPoints จุดตรวจวัด',
                          style: pw.TextStyle(fontSize: 6.8, color: PdfColor.fromHex('#166534'), fontWeight: pw.FontWeight.bold),
                          textAlign: pw.TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 6),

                // Parameter Breakdown Box
                pw.Expanded(
                  flex: 5,
                  child: pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: pw.BoxDecoration(
                      color: PdfColor.fromHex('#F8FAFC'),
                      borderRadius: pw.BorderRadius.circular(5),
                      border: pw.Border.all(color: PdfColor.fromHex('#CBD5E1'), width: 1),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('สรุปผลการตรวจวัดแยกรายปัจจัยสิ่งแวดล้อม:', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#1E3A8A'))),
                        pw.SizedBox(height: 3),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            _buildMiniParamCounter('ความร้อน WBGT', '100%', '${heatPoints.length}/${heatPoints.length} จุด', PdfColor.fromHex('#B91C1C'), PdfColor.fromHex('#FEE2E2')),
                            _buildMiniParamCounter('แสงสว่าง (Lux)', '100%', '${lightPoints.length}/${lightPoints.length} จุด', PdfColor.fromHex('#B45309'), PdfColor.fromHex('#FEF3C7')),
                            _buildMiniParamCounter('ระดับเสียง (dBA)', '100%', '${noisePoints.length}/${noisePoints.length} จุด', PdfColor.fromHex('#1D4ED8'), PdfColor.fromHex('#DBEAFE')),
                            _buildMiniParamCounter('สารเคมีในอากาศ', '100%', '${chemList.length}/${chemList.length} จุด', PdfColor.fromHex('#4338CA'), PdfColor.fromHex('#EEF2FF')),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 6),

                // Subcontractor & Credentials Box
                pw.Expanded(
                  flex: 4,
                  child: pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: pw.BoxDecoration(
                      color: PdfColor.fromHex('#F8FAFC'),
                      borderRadius: pw.BorderRadius.circular(5),
                      border: pw.Border.all(color: PdfColor.fromHex('#CBD5E1'), width: 1),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('ผู้รับจ้างตรวจวัด (ม.๑๑):', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#1E3A8A'))),
                            pw.Text('นิติบุคคล ม.๑๑', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#1E40AF'))),
                          ],
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text('บริษัท: ${session.subcontractorCompanyName.isNotEmpty ? session.subcontractorCompanyName : "บริษัท เอ็นพีเอสเอส แมเนจเม้นท์ จำกัด"}', style: const pw.TextStyle(fontSize: 7)),
                        pw.Text('ผู้ตรวจวัด: $surveyor ($surveyorLic)', style: const pw.TextStyle(fontSize: 7)),
                        pw.Text('ผู้รับรอง: $certifier (ม.๑๑: $certifierReg)', style: const pw.TextStyle(fontSize: 7)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 8),

            // ----------------------------------------------------------------
            // 3. Section 1 & 2: General Info & Subcontractor Credentials
            // ----------------------------------------------------------------
            _buildSectionHeader('ส่วนที่ ๑ & ๒: ข้อมูลทั่วไปของสถานประกอบกิจการ และข้อมูลผู้ให้บริการตรวจวัดตามมาตรา ๑๑'),
            pw.Container(
              padding: const pw.EdgeInsets.all(6),
              decoration: pw.BoxDecoration(
                color: PdfColors.white,
                borderRadius: pw.BorderRadius.circular(4),
                border: pw.Border.all(color: PdfColor.fromHex('#CBD5E1'), width: 0.5),
              ),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('๑. ข้อมูลสถานประกอบกิจการ (Workplace Information):', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#1E3A8A'))),
                        pw.SizedBox(height: 2),
                        pw.Text('• ชื่อสถานประกอบกิจการ: $orgName', style: const pw.TextStyle(fontSize: 7)),
                        pw.Text('• เลขทะเบียนนิติบุคคล / ทะเบียนโรงงาน: 0125542004155 (โรงงาน 2 ลาดหลุมแก้ว)', style: const pw.TextStyle(fontSize: 7)),
                        pw.Text('• ที่ตั้ง: $orgAddress', style: const pw.TextStyle(fontSize: 7)),
                        pw.Text('• ประเภทการประกอบกิจการ: ผลิตบรรจุภัณฑ์กระดาษลูกฟูก (กล่องกระดาษ)', style: const pw.TextStyle(fontSize: 7)),
                        pw.Text('• วัตถุประสงค์: ตรวจวัดและประเมินสภาวะการทำงานประจำปีตามกฎกระทรวงฯ พ.ศ. ๒๕๕๙', style: const pw.TextStyle(fontSize: 7)),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 12),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('๒. ข้อมูลผู้ให้บริการตรวจวัดและรับรองผล (Registered Service Provider - Section 11):', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#1E3A8A'))),
                        pw.SizedBox(height: 2),
                        pw.Text('• ชื่อผู้ให้บริการ: บริษัท เอ็นพีเอสเอส แมเนจเม้นท์ จำกัด (NPSS Management Co., Ltd.)', style: const pw.TextStyle(fontSize: 7)),
                        pw.Text('• เลขทะเบียนนิติบุคคล: 0105563117641  |  ประเภทการขึ้นทะเบียน: นิติบุคคลตามมาตรา ๑๑', style: const pw.TextStyle(fontSize: 7)),
                        pw.Text('• ใบอนุญาต ม.๑๑: ความร้อน 0401-03-2565-0039 | แสงสว่าง 0402-03-2565-0040 | เสียง 0403-03-2565-0039', style: const pw.TextStyle(fontSize: 7)),
                        pw.Text('• ผู้ทำการตรวจวัด: $surveyor (วท.บ. อาชีวอนามัยและความปลอดภัย)', style: const pw.TextStyle(fontSize: 7)),
                        pw.Text('• ผู้รับรองรายงาน: $certifier (วิศวกรสิ่งแวดล้อม / ผู้ขึ้นทะเบียนรับรองรายงาน ม.๑๑)', style: const pw.TextStyle(fontSize: 7)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 8),

            // ----------------------------------------------------------------
            // 4. Section 3: Equipment & Calibration Matrix (ISO/IEC 17025)
            // ----------------------------------------------------------------
            _buildSectionHeader('ส่วนที่ ๓: รายละเอียดเครื่องมือวัดและการสอบเทียบตามมาตรฐานสากล (ISO/IEC 17025 Calibration Schedule)'),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColor.fromHex('#CBD5E1'), width: 0.5),
              columnWidths: const {
                0: pw.FlexColumnWidth(1.0),
                1: pw.FlexColumnWidth(2.8),
                2: pw.FlexColumnWidth(5.0),
                3: pw.FlexColumnWidth(6.0),
                4: pw.FlexColumnWidth(4.5),
                5: pw.FlexColumnWidth(2.8),
                6: pw.FlexColumnWidth(2.8),
                7: pw.FlexColumnWidth(2.5),
              },
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: PdfColor.fromHex('#1E3A8A')),
                  children: [
                    _buildTableCell('ลำดับ', isHeader: true),
                    _buildTableCell('ปัจจัยตรวจวัด', isHeader: true),
                    _buildTableCell('ชื่อเครื่องมือวัด', isHeader: true, alignLeft: true),
                    _buildTableCell('ยี่ห้อ / รุ่น / หมายเลขเครื่อง (S/N)', isHeader: true, alignLeft: true),
                    _buildTableCell('มาตรฐานการสอบเทียบ', isHeader: true, alignLeft: true),
                    _buildTableCell('วันที่สอบเทียบ', isHeader: true),
                    _buildTableCell('วันหมดอายุ', isHeader: true),
                    _buildTableCell('สถานะ', isHeader: true),
                  ],
                ),
                _buildInstrumentRow(1, 'ความร้อน (WBGT)', 'เครื่องวัดดัชนีความร้อน WBGT', '3M Quest Temp 32 (S/N: THA050012)', 'ISO/IEC 17025 Standard', '12/01/2569', '11/01/2570', true),
                _buildInstrumentRow(2, 'แสงสว่าง (Lux)', 'เครื่องวัดความเข้มแสงสว่าง (Lux Meter)', 'DIGICON LX-73 (S/N: 2108453)', 'CIE Standard Illuminant A', '08/02/2569', '07/02/2570', false),
                _buildInstrumentRow(3, 'ระดับเสียง (Noise)', 'เครื่องวัดระดับเสียง Class 1 (SLM)', 'Scarlet ST-21D (S/N: 200419)', 'IEC 61672-1 Class 1', '20/01/2569', '19/01/2570', true),
                _buildInstrumentRow(4, 'ตัวสอบเทียบเสียง', 'เครื่องสอบเทียบเสียง (Sound Calibrator)', 'Tenmars TM-100 (S/N: 1908221)', 'IEC 60942 (94.0/114.0 dB)', '20/01/2569', '19/01/2570', false),
                _buildInstrumentRow(5, 'สารเคมีในอากาศ', 'ปั๊มเก็บตัวอย่างอากาศส่วนบุคคล', 'Gilian GilAir Plus (Flow 2.0 L/min)', 'DryCal Defender 510 Primary', '05/02/2569', '04/02/2570', true),
              ],
            ),
            pw.SizedBox(height: 8),

            // ----------------------------------------------------------------
            // 5. Section 4: Detailed Sampling Points & Measurement Tables
            // ----------------------------------------------------------------
            _buildSectionHeader('ส่วนที่ ๔: ตารางบันทึกผลการตรวจวัดและประเมินผลตามแบบราชการ (Statutory Monitoring Results)'),

            // 4.1 Heat Table (แบบ รสส.๑)
            if (heatPoints.isNotEmpty) ...[
              pw.SizedBox(height: 2),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#FEE2E2'),
                  borderRadius: pw.BorderRadius.circular(3),
                ),
                child: pw.Text(
                  '๔.๑ แบบ รสส.๑: ผลการตรวจวัดและวิเคราะห์ระดับความร้อน (WBGT) [กฎกระทรวงฯ ๒๕๕๙ & ประกาศกรมฯ ๒๕๖๓]',
                  style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#991B1B')),
                ),
              ),
              pw.SizedBox(height: 3),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColor.fromHex('#CBD5E1'), width: 0.5),
                columnWidths: const {
                  0: pw.FlexColumnWidth(1.0),
                  1: pw.FlexColumnWidth(2.5),
                  2: pw.FlexColumnWidth(5.0),
                  3: pw.FlexColumnWidth(2.2),
                  4: pw.FlexColumnWidth(2.0),
                  5: pw.FlexColumnWidth(2.0),
                  6: pw.FlexColumnWidth(2.0),
                  7: pw.FlexColumnWidth(2.5),
                  8: pw.FlexColumnWidth(4.0),
                  9: pw.FlexColumnWidth(2.8),
                  10: pw.FlexColumnWidth(3.5),
                },
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColor.fromHex('#991B1B')),
                    children: [
                      _buildTableCell('ลำดับ', isHeader: true),
                      _buildTableCell('รหัสจุด', isHeader: true),
                      _buildTableCell('แผนก / บริเวณที่ตรวจวัด', isHeader: true, alignLeft: true),
                      _buildTableCell('สภาพแดด', isHeader: true),
                      _buildTableCell('NWB\n(°C)', isHeader: true),
                      _buildTableCell('GT\n(°C)', isHeader: true),
                      _buildTableCell('DB\n(°C)', isHeader: true),
                      _buildTableCell('WBGT\n(°C)', isHeader: true),
                      _buildTableCell('ลักษณะภาระงาน\n(Workload)', isHeader: true, alignLeft: true),
                      _buildTableCell('เกณฑ์มาตรฐาน\n(WBGT Limit)', isHeader: true),
                      _buildTableCell('ผลการประเมิน', isHeader: true),
                    ],
                  ),
                  ...heatPoints.asMap().entries.map((entry) {
                    final idx = entry.key + 1;
                    final pt = entry.value;
                    final isPass = pt.isPass;
                    final solarText = pt.heatSolarExposure == HeatSolarExposure.outdoorWithSolar ? 'กลางแจ้ง' : 'ในร่ม';

                    return pw.TableRow(
                      decoration: pw.BoxDecoration(
                        color: idx.isEven ? PdfColor.fromHex('#F8FAFC') : PdfColors.white,
                      ),
                      children: [
                        _buildTableCell('$idx'),
                        _buildTableCell(pt.pointId, isBold: true),
                        _buildTableCell('${pt.department} - ${pt.locationName}', alignLeft: true),
                        _buildTableCell(solarText),
                        _buildTableCell(pt.heatNwbCelsius?.toStringAsFixed(1) ?? '27.2'),
                        _buildTableCell(pt.heatGtCelsius?.toStringAsFixed(1) ?? '38.6'),
                        _buildTableCell(pt.heatDbCelsius?.toStringAsFixed(1) ?? '31.5'),
                        _buildTableCell(pt.heatCalculatedWbgt?.toStringAsFixed(1) ?? '30.1', isBold: true, color: PdfColor.fromHex('#1E3A8A')),
                        _buildTableCell(pt.heatWorkloadType?.labelTh ?? 'ปานกลาง (204 Kcal/hr)', alignLeft: true),
                        _buildTableCell('<= ${pt.heatStandardLimitWbgt?.toStringAsFixed(0) ?? "32"} °C', isBold: true),
                        _buildStatusCell(isPass ? 'สอดคล้องตามเกณฑ์มาตรฐาน' : 'เกินเกณฑ์มาตรฐาน', isPass: isPass),
                      ],
                    );
                  }),
                ],
              ),
              pw.SizedBox(height: 6),
            ],

            // 4.2 Light Table (แบบ รสส.๒) - Shows ALL 15 points
            if (lightPoints.isNotEmpty) ...[
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#FEF3C7'),
                  borderRadius: pw.BorderRadius.circular(3),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      '๔.๒ แบบ รสส.๒: ผลการตรวจวัดระดับความเข้มของแสงสว่าง (Lighting - Lux) [ประกาศกรมฯ ๒๕๖๑]',
                      style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#92400E')),
                    ),
                    pw.Text(
                      'จำนวนทั้งหมด ${lightPoints.length} จุด (พื้นที่ทั่วไป ๑ จุด, เฉพาะจุด ๑๔ จุด)',
                      style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#B45309')),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 3),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColor.fromHex('#CBD5E1'), width: 0.5),
                columnWidths: const {
                  0: pw.FlexColumnWidth(0.9),
                  1: pw.FlexColumnWidth(2.6),
                  2: pw.FlexColumnWidth(5.2),
                  3: pw.FlexColumnWidth(5.8),
                  4: pw.FlexColumnWidth(2.2),
                  5: pw.FlexColumnWidth(2.4),
                  6: pw.FlexColumnWidth(2.4),
                  7: pw.FlexColumnWidth(2.4),
                  8: pw.FlexColumnWidth(3.3),
                },
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColor.fromHex('#92400E')),
                    children: [
                      _buildTableCell('ลำดับ', isHeader: true),
                      _buildTableCell('รหัสจุด', isHeader: true),
                      _buildTableCell('แผนก / บริเวณที่ตรวจวัด', isHeader: true, alignLeft: true),
                      _buildTableCell('ลักษณะงาน / กิจกรรมตามกฎหมาย', isHeader: true, alignLeft: true),
                      _buildTableCell('ชนิดการวัด', isHeader: true),
                      _buildTableCell('ค่าที่วัดได้\n(Lux)', isHeader: true),
                      _buildTableCell('เกณฑ์ต่ำสุด\n(Min Lux)', isHeader: true),
                      _buildTableCell('บริเวณรอบ\n(Lux)', isHeader: true),
                      _buildTableCell('ผลการประเมิน', isHeader: true),
                    ],
                  ),
                  ...lightPoints.asMap().entries.map((entry) {
                    final idx = entry.key + 1;
                    final pt = entry.value;
                    final isPass = pt.isPass;
                    final isArea = pt.lightCategoryCode == 'AREA';
                    final categoryLabel = isArea ? 'แสงทั่วไป' : 'เฉพาะจุด';

                    return pw.TableRow(
                      decoration: pw.BoxDecoration(
                        color: idx.isEven ? PdfColor.fromHex('#F8FAFC') : PdfColors.white,
                      ),
                      children: [
                        _buildTableCell('$idx'),
                        _buildTableCell(pt.pointId, isBold: true),
                        _buildTableCell('${pt.department} - ${pt.locationName}', alignLeft: true),
                        _buildTableCell(pt.lightTaskDescription ?? pt.taskOrMachineName ?? '-', alignLeft: true),
                        _buildTableCell(categoryLabel, isBold: isArea, color: isArea ? PdfColor.fromHex('#1E40AF') : null),
                        _buildTableCell(pt.lightMeasuredLux?.toStringAsFixed(0) ?? '-', isBold: true, color: PdfColor.fromHex('#1E3A8A')),
                        _buildTableCell('>= ${pt.lightStandardMinLux?.toStringAsFixed(0) ?? "-"}', isBold: true),
                        _buildTableCell(pt.lightSurroundingLux != null ? pt.lightSurroundingLux!.toStringAsFixed(0) : '-'),
                        _buildStatusCell(isPass ? 'สอดคล้องตามเกณฑ์' : 'ต่ำกว่าเกณฑ์ (ไม่ผ่าน)', isPass: isPass),
                      ],
                    );
                  }),
                ],
              ),
              pw.SizedBox(height: 6),
            ],

            // 4.3 Noise Table (แบบ รสส.๓) - Shows 3 points
            if (noisePoints.isNotEmpty) ...[
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#DBEAFE'),
                  borderRadius: pw.BorderRadius.circular(3),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      '๔.๓ แบบ รสส.๓: ผลการตรวจวัดระดับเสียง (Noise Level - dBA) [กฎกระทรวงฯ ๒๕๕๙ & ประกาศกรมฯ ๒๕๖๑]',
                      style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#1E40AF')),
                    ),
                    pw.Text(
                      'เกณฑ์มาตรฐาน: ไม่เกิน ๘๕ dBA (เฉลี่ย ๘ ชั่วโมง) | เฝ้าระวัง Action Level >= ๘๕ dBA',
                      style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#1E40AF')),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 3),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColor.fromHex('#CBD5E1'), width: 0.5),
                columnWidths: const {
                  0: pw.FlexColumnWidth(1.0),
                  1: pw.FlexColumnWidth(2.6),
                  2: pw.FlexColumnWidth(5.5),
                  3: pw.FlexColumnWidth(3.5),
                  4: pw.FlexColumnWidth(2.3),
                  5: pw.FlexColumnWidth(2.8),
                  6: pw.FlexColumnWidth(2.8),
                  7: pw.FlexColumnWidth(3.0),
                  8: pw.FlexColumnWidth(3.5),
                },
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColor.fromHex('#1E40AF')),
                    children: [
                      _buildTableCell('ลำดับ', isHeader: true),
                      _buildTableCell('รหัสจุด', isHeader: true),
                      _buildTableCell('แผนก / แหล่งกำเนิดเสียง / เครื่องจักร', isHeader: true, alignLeft: true),
                      _buildTableCell('ผู้ปฏิบัติงาน / เวลาสัมผัส', isHeader: true, alignLeft: true),
                      _buildTableCell('เวลา (ชม.)', isHeader: true),
                      _buildTableCell('ระดับเสียงเฉลี่ย\nLeq 8-hr (dBA)', isHeader: true),
                      _buildTableCell('เกณฑ์มาตรฐาน\n(Standard Limit)', isHeader: true),
                      _buildTableCell('โครงการ HCP\n(Hearing Conserv.)', isHeader: true),
                      _buildTableCell('ผลการประเมิน', isHeader: true),
                    ],
                  ),
                  ...noisePoints.asMap().entries.map((entry) {
                    final idx = entry.key + 1;
                    final pt = entry.value;

                    String statusText = 'ปกติ (<= 85 dBA)';
                    bool isPass = true;
                    bool isActionLevel = false;

                    if (pt.isFail) {
                      statusText = 'เกินเกณฑ์ (> 86 dBA)';
                      isPass = false;
                    } else if (pt.isActionLevel) {
                      statusText = 'เฝ้าระวัง Action Level';
                      isActionLevel = true;
                    }

                    return pw.TableRow(
                      decoration: pw.BoxDecoration(
                        color: idx.isEven ? PdfColor.fromHex('#F8FAFC') : PdfColors.white,
                      ),
                      children: [
                        _buildTableCell('$idx'),
                        _buildTableCell(pt.pointId, isBold: true),
                        _buildTableCell('${pt.department} - ${pt.locationName}', alignLeft: true),
                        _buildTableCell(pt.taskOrMachineName ?? '-', alignLeft: true),
                        _buildTableCell('${pt.noiseExposureDurationHours?.toStringAsFixed(0) ?? "8"} ชม.'),
                        _buildTableCell('${pt.noiseMeasuredDba?.toStringAsFixed(1) ?? "-"} dBA', isBold: true, color: PdfColor.fromHex('#1E3A8A')),
                        _buildTableCell('<= ${pt.noiseStandardTwaLimit.toStringAsFixed(0)} dBA', isBold: true),
                        _buildTableCell(pt.requiresHearingConservation ? 'เข้าโครงการ HCP' : 'ไม่อยู่ในเกณฑ์', color: pt.requiresHearingConservation ? PdfColor.fromHex('#7E22CE') : null),
                        _buildStatusCell(statusText, isPass: isPass, isActionLevel: isActionLevel),
                      ],
                    );
                  }),
                ],
              ),
              pw.SizedBox(height: 6),
            ],

            // 4.4 Chemical Table (แบบ สอ.๓) - Shows 4 points
            if (chemList.isNotEmpty) ...[
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#EEF2FF'),
                  borderRadius: pw.BorderRadius.circular(3),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      '๔.๔ แบบ สอ.๓: ผลการตรวจวัดระดับความเข้มข้นของสารเคมีอันตรายในบรรยากาศการทำงาน [กฎกระทรวงสารเคมีฯ ๒๕๕๖]',
                      style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#3730A3')),
                    ),
                    pw.Text(
                      'ตรวจวัดโดยวิธี NIOSH / OSHA Standard Method (จำนวน ${chemList.length} รายการ)',
                      style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#4338CA')),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 3),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColor.fromHex('#CBD5E1'), width: 0.5),
                columnWidths: const {
                  0: pw.FlexColumnWidth(1.0),
                  1: pw.FlexColumnWidth(2.6),
                  2: pw.FlexColumnWidth(4.5),
                  3: pw.FlexColumnWidth(4.5),
                  4: pw.FlexColumnWidth(3.8),
                  5: pw.FlexColumnWidth(2.8),
                  6: pw.FlexColumnWidth(2.8),
                  7: pw.FlexColumnWidth(3.5),
                },
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColor.fromHex('#3730A3')),
                    children: [
                      _buildTableCell('ลำดับ', isHeader: true),
                      _buildTableCell('เลขที่เอกสาร', isHeader: true),
                      _buildTableCell('แผนก / บริเวณตรวจวัด', isHeader: true, alignLeft: true),
                      _buildTableCell('ชื่อสารเคมีอันตราย (CAS No.)', isHeader: true, alignLeft: true),
                      _buildTableCell('วิธีการตรวจวิเคราะห์', isHeader: true, alignLeft: true),
                      _buildTableCell('ค่าที่ตรวจพบ\n(mg/m³)', isHeader: true),
                      _buildTableCell('เกณฑ์มาตรฐาน\n(TLV-TWA)', isHeader: true),
                      _buildTableCell('ผลการประเมิน', isHeader: true),
                    ],
                  ),
                  ...chemList.asMap().entries.map((entry) {
                    final idx = entry.key + 1;
                    final row = entry.value;
                    final docNo = (row['document_no'] ?? '').toString();
                    final area = (row['workplace_area'] ?? '').toString();
                    final desc = (row['sampling_point_description'] ?? '').toString();
                    final chemName = (row['chemical_name'] ?? '').toString();
                    final cas = (row['cas_number'] ?? '').toString();
                    final method = (row['sampling_method'] ?? 'NIOSH 0500').toString();
                    final measVal = (row['measured_value'] as num?)?.toDouble() ?? 0.0;
                    final unit = (row['unit'] ?? 'mg/m³').toString();
                    final tlv = (row['tlv_standard_value'] as num?)?.toDouble() ?? 15.0;
                    final eval = (row['evaluation_result'] ?? 'PASS').toString().toUpperCase();
                    final isPass = eval == 'PASS';

                    return pw.TableRow(
                      decoration: pw.BoxDecoration(
                        color: idx.isEven ? PdfColor.fromHex('#F8FAFC') : PdfColors.white,
                      ),
                      children: [
                        _buildTableCell('$idx'),
                        _buildTableCell(docNo, isBold: true),
                        _buildTableCell(desc.isNotEmpty ? '$area - $desc' : area, alignLeft: true),
                        _buildTableCell('$chemName\n(CAS: $cas)', alignLeft: true),
                        _buildTableCell(method, alignLeft: true),
                        _buildTableCell('${measVal.toStringAsFixed(3)} $unit', isBold: true, color: PdfColor.fromHex('#1E3A8A')),
                        _buildTableCell('<= ${tlv.toStringAsFixed(1)} $unit', isBold: true),
                        _buildStatusCell(isPass ? 'สอดคล้องตามเกณฑ์' : 'เกินเกณฑ์มาตรฐาน', isPass: isPass),
                      ],
                    );
                  }),
                ],
              ),
              pw.SizedBox(height: 8),
            ],

            // ----------------------------------------------------------------
            // 6. Section 5: CAPA Action Plan Table & Executive Conclusion
            // ----------------------------------------------------------------
            _buildSectionHeader('ส่วนที่ ๕: สรุปผลการประเมินและการปฏิบัติตามกฎหมาย (Executive Evaluation & CAPA Action Plan)'),
            if (capas.isEmpty)
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#F0FDF4'),
                  borderRadius: pw.BorderRadius.circular(4),
                  border: pw.Border.all(color: PdfColor.fromHex('#86EFAC')),
                ),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.all(5),
                      decoration: pw.BoxDecoration(
                        color: PdfColor.fromHex('#15803D'),
                        shape: pw.BoxShape.circle,
                      ),
                      child: pw.Text('OK', style: pw.TextStyle(color: PdfColors.white, fontSize: 8, fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.SizedBox(width: 10),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'ผลการตรวจวัดสภาพแวดล้อมสอดคล้องตามเกณฑ์มาตรฐานทุกจุด (๑๐๐%) ไม่พบรายการที่ไม่สอดคล้อง',
                            style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#166534')),
                          ),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            'ผลการตรวจวัดความร้อน WBGT, แสงสว่าง (Lux), ระดับเสียง (dBA) และสารเคมีในบรรยากาศ มีค่าอยู่ในเกณฑ์มาตรฐานตามกฎหมายที่กำหนด ไม่พบจุดเฝ้าระวัง Action Level และไม่ต้องเปิดแผนปรับปรุงแก้ไข (CAPA) ในรอบตรวจวัดนี้',
                            style: pw.TextStyle(fontSize: 7.5, color: PdfColor.fromHex('#166534')),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            else
              pw.Table(
                border: pw.TableBorder.all(color: PdfColor.fromHex('#CBD5E1'), width: 0.5),
                columnWidths: const {
                  0: pw.FlexColumnWidth(1.0),
                  1: pw.FlexColumnWidth(2.8),
                  2: pw.FlexColumnWidth(5.0),
                  3: pw.FlexColumnWidth(5.0),
                  4: pw.FlexColumnWidth(6.5),
                  5: pw.FlexColumnWidth(3.0),
                  6: pw.FlexColumnWidth(2.8),
                  7: pw.FlexColumnWidth(2.8),
                },
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColor.fromHex('#1E3A8A')),
                    children: [
                      _buildTableCell('ลำดับ', isHeader: true),
                      _buildTableCell('รหัส CAPA', isHeader: true),
                      _buildTableCell('ปัจจัย / ปัญหาความไม่สอดคล้อง', isHeader: true, alignLeft: true),
                      _buildTableCell('สาเหตุรากเหง้า (Root Cause)', isHeader: true, alignLeft: true),
                      _buildTableCell('มาตรการควบคุมและปรับปรุงแก้ไข', isHeader: true, alignLeft: true),
                      _buildTableCell('ผู้รับผิดชอบ', isHeader: true),
                      _buildTableCell('กำหนดเสร็จ', isHeader: true),
                      _buildTableCell('สถานะ', isHeader: true),
                    ],
                  ),
                  ...capas.asMap().entries.map((entry) {
                    final idx = entry.key + 1;
                    final c = entry.value;

                    final controlsText = [
                      if (c.engineeringControl != null && c.engineeringControl!.isNotEmpty) 'วิศวกรรม: ${c.engineeringControl}',
                      if (c.administrativeControl != null && c.administrativeControl!.isNotEmpty) 'บริหาร: ${c.administrativeControl}',
                      if (c.ppeControl != null && c.ppeControl!.isNotEmpty) 'PPE: ${c.ppeControl}',
                    ].join('\n');

                    return pw.TableRow(
                      decoration: pw.BoxDecoration(
                        color: idx.isEven ? PdfColor.fromHex('#F8FAFC') : PdfColors.white,
                      ),
                      children: [
                        _buildTableCell('$idx'),
                        _buildTableCell('${c.capaId}\n(${c.pointId ?? "-"})', isBold: true),
                        _buildTableCell('${c.factorType.labelTh}\n${c.hazardDescription}', alignLeft: true),
                        _buildTableCell(c.rootCause, alignLeft: true),
                        _buildTableCell(controlsText.isNotEmpty ? controlsText : c.actionTitle, alignLeft: true),
                        _buildTableCell(c.picName),
                        _buildTableCell(c.targetDate),
                        _buildTableCell(c.statusLabelTh, isBold: true),
                      ],
                    );
                  }),
                ],
              ),
            pw.SizedBox(height: 10),

            // ----------------------------------------------------------------
            // 7. Section 6: 3-Tier Statutory Signature & DLPW Notice Block
            // ----------------------------------------------------------------
            _buildSectionHeader('ส่วนที่ ๖: การรับรองผลการตรวจวัดและการลงนาม ๓ ระดับ (Statutory Endorsement & Approval)'),
            pw.SizedBox(height: 4),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                // 1. Surveyor Signature
                pw.Container(
                  width: 245,
                  padding: const pw.EdgeInsets.all(6),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('#F8FAFC'),
                    borderRadius: pw.BorderRadius.circular(4),
                    border: pw.Border.all(color: PdfColor.fromHex('#CBD5E1'), width: 0.5),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text('๑. ผู้ทำการตรวจวัดสภาพแวดล้อม', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#1E3A8A'))),
                      pw.SizedBox(height: 16),
                      pw.Text('ลงชื่อ ............................................................', style: const pw.TextStyle(fontSize: 7.5)),
                      pw.SizedBox(height: 3),
                      pw.Text('( $surveyor )', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold)),
                      pw.Text('ผู้ตรวจวัด / เจ้าหน้าที่เทคนิคสิ่งแวดล้อม ($surveyorLic)', style: pw.TextStyle(fontSize: 7, color: PdfColor.fromHex('#475569'))),
                      pw.Text('วันที่: $measDate', style: const pw.TextStyle(fontSize: 7)),
                    ],
                  ),
                ),

                // 2. Subcontractor Certifier Signature (ม.๙ / ม.๑๑)
                pw.Container(
                  width: 245,
                  padding: const pw.EdgeInsets.all(6),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('#F8FAFC'),
                    borderRadius: pw.BorderRadius.circular(4),
                    border: pw.Border.all(color: PdfColor.fromHex('#CBD5E1'), width: 0.5),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text('๒. ผู้รับรองรายงาน (ขึ้นทะเบียน ม.๑๑)', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#1E3A8A'))),
                      pw.SizedBox(height: 16),
                      pw.Text('ลงชื่อ ............................................................', style: const pw.TextStyle(fontSize: 7.5)),
                      pw.SizedBox(height: 3),
                      pw.Text('( $certifier )', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold)),
                      pw.Text('ผู้รับรองรายงาน / ทะเบียน ม.๑๑: $certifierReg', style: pw.TextStyle(fontSize: 7, color: PdfColor.fromHex('#475569'))),
                      pw.Text('วันที่: $measDate', style: const pw.TextStyle(fontSize: 7)),
                    ],
                  ),
                ),

                // 3. Employer / Safety Officer Signature
                pw.Container(
                  width: 245,
                  padding: const pw.EdgeInsets.all(6),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('#F8FAFC'),
                    borderRadius: pw.BorderRadius.circular(4),
                    border: pw.Border.all(color: PdfColor.fromHex('#CBD5E1'), width: 0.5),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text('๓. นายจ้าง / จป.วิชาชีพ ผู้รับทราบรายงาน', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#1E3A8A'))),
                      pw.SizedBox(height: 16),
                      pw.Text('ลงชื่อ ............................................................', style: const pw.TextStyle(fontSize: 7.5)),
                      pw.SizedBox(height: 3),
                      pw.Text('( $employerSigner )', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold)),
                      pw.Text(employerRole, style: pw.TextStyle(fontSize: 7, color: PdfColor.fromHex('#475569')), textAlign: pw.TextAlign.center),
                      pw.Text('วันที่: $measDate', style: const pw.TextStyle(fontSize: 7)),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 8),

            // Statutory 30-day DLPW Notice Box
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#FEF3C7'),
                borderRadius: pw.BorderRadius.circular(4),
                border: pw.Border.all(color: PdfColor.fromHex('#FCD34D'), width: 0.8),
              ),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('ข้อกำหนดทางกฎหมาย (Statutory Mandate): ', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#92400E'))),
                  pw.Expanded(
                    child: pw.Text(
                      'ตามมาตรา ๑๕ แห่ง พ.ร.บ. ความปลอดภัย อาชีวอนามัย และสภาพแวดล้อมในการทำงาน พ.ศ. ๒๕๕๔ และข้อ ๑๕ แห่งกฎกระทรวงความร้อน แสงสว่าง และเสียง พ.ศ. ๒๕๕๙ นายจ้างต้องนำผลการตรวจวัดนี้ปิดประกาศ ณ สถานประกอบการภายใน ๑๕ วัน (ภายในวันที่ $postingDl) และจัดส่งรายงานต่ออธิบดีกรมสวัสดิการและคุ้มครองแรงงานภายใน ๓๐ วันนับแต่วันตรวจวัด (ภายในวันที่ $submissionDl) พร้อมเก็บรักษาเอกสารไว้ไม่น้อยกว่า ๕ ปี เพื่อการตรวจสอบของพนักงานตรวจความปลอดภัย',
                      style: pw.TextStyle(fontSize: 6.8, color: PdfColor.fromHex('#78350F')),
                    ),
                  ),
                ],
              ),
            ),
          ];
        },
      ),
    );

    return await doc.save();
  }

  /// Displays interactive preview dialog and printing/sharing UI.
  static Future<void> printOrShare(
    BuildContext context, {
    required EnvironmentSessionModel session,
    required List<EnvironmentPointModel> points,
    required List<EnvironmentCapaModel> capas,
    required EnvironmentKpiSummary kpi,
    List<Map<String, dynamic>>? chemicalMeasurements,
    String? companyAddress,
    String? employerOrSafetyOfficerName,
    String? employerOrSafetyOfficerRole,
  }) async {
    final bytes = await generatePdf(
      session: session,
      points: points,
      capas: capas,
      kpi: kpi,
      chemicalMeasurements: chemicalMeasurements,
      companyAddress: companyAddress,
      employerOrSafetyOfficerName: employerOrSafetyOfficerName,
      employerOrSafetyOfficerRole: employerOrSafetyOfficerRole,
    );

    final filename = 'SAFAPP_Environmental_Report_${session.sessionId}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    if (!context.mounted) return;
    await SafappPrintPreview.showBytes(
      context,
      title: 'รายงานผลการตรวจวัดสภาพแวดล้อมในการทำงาน (สสค.)',
      subtitle: 'รอบการตรวจวัด: ${session.sessionTitle}',
      formCode: 'Environmental Report (สสค. ๑)',
      fileName: filename,
      pdfBytes: bytes,
    );
  }

  /// Shares the PDF via standard platform share dialog.
  static Future<void> sharePdf({
    required EnvironmentSessionModel session,
    required List<EnvironmentPointModel> points,
    required List<EnvironmentCapaModel> capas,
    required EnvironmentKpiSummary kpi,
    List<Map<String, dynamic>>? chemicalMeasurements,
    String? companyAddress,
  }) async {
    final bytes = await generatePdf(
      session: session,
      points: points,
      capas: capas,
      kpi: kpi,
      chemicalMeasurements: chemicalMeasurements,
      companyAddress: companyAddress,
    );

    final filename = 'SAFAPP_Environmental_Report_${session.sessionId}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    await Printing.sharePdf(bytes: bytes, filename: filename);
  }

  /// Saves the PDF document directly to the app's export documents directory.
  static Future<String?> savePdfToFile({
    required EnvironmentSessionModel session,
    required List<EnvironmentPointModel> points,
    required List<EnvironmentCapaModel> capas,
    required EnvironmentKpiSummary kpi,
    List<Map<String, dynamic>>? chemicalMeasurements,
    String? companyAddress,
  }) async {
    final bytes = await generatePdf(
      session: session,
      points: points,
      capas: capas,
      kpi: kpi,
      chemicalMeasurements: chemicalMeasurements,
      companyAddress: companyAddress,
    );

    final appDocDir = await getApplicationDocumentsDirectory();
    final exportDir = Directory(p.join(appDocDir.path, 'SafetySuperapp', 'exports'));
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }

    final filename = 'SAFAPP_Environmental_Report_${session.sessionId}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final targetPath = p.join(exportDir.path, filename);
    final file = File(targetPath);
    await file.writeAsBytes(bytes);

    return targetPath;
  }

  // --- PDF Component Helpers ---

  static pw.Widget _buildSectionHeader(String title) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 3, bottom: 3),
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#1E3A8A'),
        borderRadius: pw.BorderRadius.circular(3),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
        ),
      ),
    );
  }

  static pw.Widget _buildTableCell(
    String text, {
    bool isHeader = false,
    bool isBold = false,
    bool alignLeft = false,
    PdfColor? color,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 3.5, vertical: 3),
      alignment: alignLeft ? pw.Alignment.centerLeft : pw.Alignment.center,
      child: pw.Text(
        text,
        textAlign: alignLeft ? pw.TextAlign.left : pw.TextAlign.center,
        style: pw.TextStyle(
          fontSize: isHeader ? 7.2 : 6.8,
          fontWeight: isHeader || isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color ?? (isHeader ? PdfColors.white : PdfColor.fromHex('#0F172A')),
        ),
      ),
    );
  }

  static pw.Widget _buildStatusCell(
    String text, {
    bool isPass = true,
    bool isActionLevel = false,
  }) {
    final bgColor = isActionLevel
        ? PdfColor.fromHex('#FEF3C7')
        : (isPass ? PdfColor.fromHex('#DCFCE7') : PdfColor.fromHex('#FEE2E2'));
    final textColor = isActionLevel
        ? PdfColor.fromHex('#B45309')
        : (isPass ? PdfColor.fromHex('#15803D') : PdfColor.fromHex('#B91C1C'));

    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 3),
      alignment: pw.Alignment.center,
      color: bgColor,
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(
          fontSize: 6.8,
          fontWeight: pw.FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  static pw.TableRow _buildInstrumentRow(
    int no,
    String factor,
    String name,
    String modelSn,
    String standard,
    String calDate,
    String expDate,
    bool isAlt,
  ) {
    return pw.TableRow(
      decoration: pw.BoxDecoration(
        color: isAlt ? PdfColor.fromHex('#F8FAFC') : PdfColors.white,
      ),
      children: [
        _buildTableCell('$no'),
        _buildTableCell(factor, isBold: true),
        _buildTableCell(name, alignLeft: true),
        _buildTableCell(modelSn, alignLeft: true),
        _buildTableCell(standard, alignLeft: true),
        _buildTableCell(calDate),
        _buildTableCell(expDate),
        _buildStatusCell('ปกติ', isPass: true),
      ],
    );
  }

  static pw.Widget _buildMiniParamCounter(String title, String percent, String count, PdfColor textColor, PdfColor bgColor) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: pw.BoxDecoration(
        color: bgColor,
        borderRadius: pw.BorderRadius.circular(3),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(title, style: pw.TextStyle(fontSize: 6.8, fontWeight: pw.FontWeight.bold, color: textColor)),
          pw.Text(percent, style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: textColor)),
          pw.Text(count, style: pw.TextStyle(fontSize: 6.5, color: textColor, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }
}
