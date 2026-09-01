import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../domain/models/environment_standard_model.dart';
import '../domain/models/environment_session_model.dart';
import '../domain/models/environment_point_model.dart';
import '../domain/models/environment_capa_model.dart';
import '../domain/models/environment_kpi_summary.dart';
import '../domain/models/subcontractor_model.dart';

/// Official Statutory PDF Generator for Environmental Monitoring Report (สสค.)
/// (รายงานผลการตรวจวัดและวิเคราะห์สภาวะการทำงานเกี่ยวกับความร้อน แสงสว่าง หรือเสียง)
/// Conforming to Thai Occupational Safety, Health and Environment Act B.E. 2554 (2011),
/// Ministerial Regulation on Heat, Light, Noise B.E. 2559 (2016),
/// and the DLPW Official Reporting Form Notification B.E. 2563 (2020).
class EnvironmentPdfExporter {
  /// Generates the complete 6-section statutory Environmental Monitoring Report PDF as bytes.
  static Future<Uint8List> generatePdf({
    required EnvironmentSessionModel session,
    required List<EnvironmentPointModel> points,
    required List<EnvironmentCapaModel> capas,
    required EnvironmentKpiSummary kpi,
    String? companyAddress,
    String? employerOrSafetyOfficerName,
    String? employerOrSafetyOfficerRole,
  }) async {
    final doc = pw.Document();

    // Load authentic Google Sarabun fonts for Thai rendering
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
        : 'บริษัท โรงงานอุตสาหกรรมตัวอย่าง จำกัด (มหาชน)';
    final orgPlant = session.locationPlant.isNotEmpty ? session.locationPlant : 'โรงงานหลัก';
    final orgAddress = companyAddress?.isNotEmpty == true
        ? companyAddress!
        : (session.workplaceAddress?.isNotEmpty == true
            ? session.workplaceAddress!
            : '123/45 นิคมอุตสาหกรรม ตำบลคลองหนึ่ง อำเภอคลองหลวง จังหวัดปทุมธานี 12120');

    final periodStr = 'ประจำปี พ.ศ. ${session.sessionYearBe} (รอบตรวจวัด ${session.sessionId})';
    final measDate = session.measurementDate.isNotEmpty
        ? session.measurementDate
        : DateTime.now().toIso8601String().substring(0, 10);
    final postingDl = session.postingDeadline?.isNotEmpty == true
        ? session.postingDeadline!
        : EnvironmentSessionModel.calculatePostingDeadline(measDate);
    final submissionDl = session.submissionDeadline?.isNotEmpty == true
        ? session.submissionDeadline!
        : EnvironmentSessionModel.calculateSubmissionDeadline(measDate);

    final surveyor = session.surveyorName.isNotEmpty ? session.surveyorName : 'นายช่างตรวจวัด สิ่งแวดล้อม';
    final surveyorLic = session.surveyorLicenseNo?.isNotEmpty == true ? session.surveyorLicenseNo! : '-';
    final certifier = session.certifierName.isNotEmpty ? session.certifierName : 'นายวิศวกร ผู้รับรองรายงาน';
    final certifierReg = session.certifierRegNo?.isNotEmpty == true ? session.certifierRegNo! : session.subcontractorRegNumber;

    final employerSigner = employerOrSafetyOfficerName?.isNotEmpty == true
        ? employerOrSafetyOfficerName!
        : 'นายสมศักดิ์ รักความปลอดภัย';
    final employerRole = employerOrSafetyOfficerRole?.isNotEmpty == true
        ? employerOrSafetyOfficerRole!
        : 'เจ้าหน้าที่ความปลอดภัยในการทำงานระดับวิชาชีพ (จป.วิชาชีพ) / ผู้แทนนายจ้าง';

    final lightPoints = points.where((p) => p.factorType == EnvironmentFactorType.light).toList();
    final noisePoints = points.where((p) => p.factorType == EnvironmentFactorType.noise).toList();
    final heatPoints = points.where((p) => p.factorType == EnvironmentFactorType.heat).toList();

    // Use A4 Landscape layout for statutory multi-column environmental tables
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        theme: theme,
        margin: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 20),
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
                        padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.blue900,
                          borderRadius: pw.BorderRadius.circular(3),
                        ),
                        child: pw.Text(
                          'แบบรายงาน สสค. (DLPW FORM)',
                          style: pw.TextStyle(
                            fontSize: 7.5,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                          ),
                        ),
                      ),
                      pw.SizedBox(width: 8),
                      pw.Text(
                        'รายงานผลการตรวจวัดและวิเคราะห์สภาวะการทำงานเกี่ยวกับความร้อน แสงสว่าง หรือเสียง (กฎกระทรวงฯ ๒๕๕๙ & ประกาศกรมฯ ๒๕๖๓)',
                        style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                  pw.Text(
                    'พ.ร.บ. ความปลอดภัยฯ ๒๕๕๔ (ม.๘, ม.๙, ม.๑๑, ม.๑๕)',
                    style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                  ),
                ],
              ),
              pw.SizedBox(height: 3),
              pw.Divider(thickness: 0.5, color: PdfColors.grey400),
              pw.SizedBox(height: 4),
            ],
          );
        },
        footer: (pw.Context ctx) {
          return pw.Column(
            children: [
              pw.Divider(thickness: 0.5, color: PdfColors.grey400),
              pw.SizedBox(height: 2),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'รายงานผลการตรวจวัดสภาพแวดล้อม: $orgName ($periodStr)',
                    style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600),
                  ),
                  pw.Text(
                    'จัดพิมพ์: ${DateTime.now().toIso8601String().substring(0, 10)}  |  หน้าที่ ${ctx.pageNumber} จาก ${ctx.pagesCount}',
                    style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600),
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
                color: PdfColors.blue50,
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: PdfColors.blue300, width: 1),
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
                          'รายงานผลการตรวจวัดและวิเคราะห์สภาวะการทำงานเกี่ยวกับความร้อน แสงสว่าง หรือเสียง',
                          style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'OFFICIAL STATUTORY ENVIRONMENTAL MONITORING & COMPLIANCE EVALUATION REPORT',
                          style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'สถานประกอบกิจการ: $orgName ($orgPlant)  |  ที่ตั้ง: $orgAddress',
                          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey800),
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 12),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(6),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.white,
                      borderRadius: pw.BorderRadius.circular(4),
                      border: pw.Border.all(color: PdfColors.blue200),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('รหัสรอบ: ${session.sessionId}', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                        pw.Text('วันที่ตรวจวัด: $measDate', style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey800)),
                        pw.Text('กำหนดปิดประกาศ (๑๕ วัน): $postingDl', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700)),
                        pw.Text('กำหนดยื่นกรมฯ (๓๐ วัน): $submissionDl', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 8),

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
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      color: kpi.compliancePercentage >= 90
                          ? PdfColors.green50
                          : kpi.compliancePercentage >= 75
                              ? PdfColors.amber50
                              : PdfColors.red50,
                      borderRadius: pw.BorderRadius.circular(5),
                      border: pw.Border.all(
                        color: kpi.compliancePercentage >= 90
                            ? PdfColors.green300
                            : kpi.compliancePercentage >= 75
                                ? PdfColors.amber300
                                : PdfColors.red300,
                        width: 1,
                      ),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Text(
                          'ดัชนีความสอดคล้องสภาพแวดล้อมรวม',
                          style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800),
                          textAlign: pw.TextAlign.center,
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          '${kpi.compliancePercentage.toStringAsFixed(1)} %',
                          style: pw.TextStyle(
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                            color: kpi.compliancePercentage >= 90
                                ? PdfColors.green900
                                : kpi.compliancePercentage >= 75
                                    ? PdfColors.amber900
                                    : PdfColors.red900,
                          ),
                        ),
                        pw.Text(
                          'ผ่านเกณฑ์ ${kpi.passedPoints} / ทั้งหมด ${kpi.totalPoints} จุด',
                          style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700),
                          textAlign: pw.TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 8),

                // Parameter Breakdown Box
                pw.Expanded(
                  flex: 4,
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(6),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey100,
                      borderRadius: pw.BorderRadius.circular(5),
                      border: pw.Border.all(color: PdfColors.grey300, width: 1),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('สรุปผลแยกรายปัจจัยสิ่งแวดล้อม:', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                        pw.SizedBox(height: 3),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            _buildMiniParamCounter('แสงสว่าง (Light)', '${kpi.lightCompliancePercentage}%', '${kpi.lightPassed}/${kpi.lightPoints} จุด', PdfColors.amber900, PdfColors.amber50),
                            _buildMiniParamCounter('เสียง (Noise)', '${kpi.noiseCompliancePercentage}%', '${kpi.noiseNormal}/${kpi.noisePoints} จุด', PdfColors.blue900, PdfColors.blue50),
                            _buildMiniParamCounter('ความร้อน (WBGT)', '${kpi.heatCompliancePercentage}%', '${kpi.heatPassed}/${kpi.heatPoints} จุด', PdfColors.red900, PdfColors.red50),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 8),

                // Subcontractor & CAPA Status Box
                pw.Expanded(
                  flex: 5,
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(6),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey50,
                      borderRadius: pw.BorderRadius.circular(5),
                      border: pw.Border.all(color: PdfColors.grey300, width: 1),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('ข้อมูลผู้รับจ้างตรวจวัด (ม.๙ / ม.๑๑):', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                            pw.Text(session.subcontractorType.labelTh, style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                          ],
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text('บริษัท: ${session.subcontractorCompanyName} (เลขทะเบียน: ${session.subcontractorRegNumber})', style: const pw.TextStyle(fontSize: 7.5)),
                        pw.Text('ผู้ตรวจวัด: $surveyor  |  ผู้รับรอง: $certifier', style: const pw.TextStyle(fontSize: 7.5)),
                        pw.SizedBox(height: 2),
                        pw.Text('โครงการอนุรักษ์การได้ยิน (HCP): ${kpi.hcpRequiredCount} จุด  |  แผน CAPA: ${capas.length} แผน', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: PdfColors.purple900)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 10),

            // ----------------------------------------------------------------
            // 3. Section 1 & 2: General Info & Subcontractor Credentials
            // ----------------------------------------------------------------
            _buildSectionHeader('ส่วนที่ ๑ & ๒: ข้อมูลทั่วไปของสถานประกอบกิจการและผู้ตรวจวัด/รับรองผล'),
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                color: PdfColors.white,
                borderRadius: pw.BorderRadius.circular(4),
                border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
              ),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('๑. ข้อมูลสถานประกอบกิจการ (Workplace Information):', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 2),
                        pw.Text('• ชื่อสถานประกอบกิจการ: $orgName', style: const pw.TextStyle(fontSize: 7.5)),
                        pw.Text('• อาคาร/โรงงาน/พื้นที่: $orgPlant', style: const pw.TextStyle(fontSize: 7.5)),
                        pw.Text('• ที่ตั้ง: $orgAddress', style: const pw.TextStyle(fontSize: 7.5)),
                        pw.Text('• วัตถุประสงค์การตรวจวัด: ${session.objective.isNotEmpty ? session.objective : "ตรวจวัดและประเมินสภาวะการทำงานประจำปีตามกฎหมาย"}', style: const pw.TextStyle(fontSize: 7.5)),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 16),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('๒. ข้อมูลผู้ให้บริการตรวจวัดและรับรองผล (Service Provider):', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 2),
                        pw.Text('• ประเภทการขึ้นทะเบียน: ${session.subcontractorType.labelTh}', style: const pw.TextStyle(fontSize: 7.5)),
                        pw.Text('• ชื่อบริษัท/ผู้ให้บริการ: ${session.subcontractorCompanyName}', style: const pw.TextStyle(fontSize: 7.5)),
                        pw.Text('• เลขทะเบียน/ใบอนุญาต: ${session.subcontractorRegNumber}', style: const pw.TextStyle(fontSize: 7.5)),
                        pw.Text('• ผู้ทำการตรวจวัด: $surveyor (เลขที่/ตำแหน่ง: $surveyorLic)', style: const pw.TextStyle(fontSize: 7.5)),
                        pw.Text('• ผู้รับรองรายงาน: $certifier (เลขทะเบียน: $certifierReg)', style: const pw.TextStyle(fontSize: 7.5)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 10),

            // ----------------------------------------------------------------
            // 4. Section 3: Equipment & Calibration Info
            // ----------------------------------------------------------------
            _buildSectionHeader('ส่วนที่ ๓: รายละเอียดเครื่องมือวัดและการสอบเทียบตามมาตรฐานสากล (ISO/IEC 17025)'),
            pw.Container(
              padding: const pw.EdgeInsets.all(6),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey50,
                borderRadius: pw.BorderRadius.circular(4),
                border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'เครื่องมือวัดที่ใช้: Sound Level Meter (Type 1/2), Lux Meter (CIE Standard), Heat Stress WBGT Meter (150mm Globe)',
                    style: const pw.TextStyle(fontSize: 7.5),
                  ),
                  pw.Text(
                    'ใบรับรองการสอบเทียบ: ${session.calibrationCertPaths.length} ฉบับ (แนบท้ายรายงาน)',
                    style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 10),

            // ----------------------------------------------------------------
            // 5. Section 4: Detailed Sampling Points & Measurement Tables
            // ----------------------------------------------------------------
            _buildSectionHeader('ส่วนที่ ๔: ตารางบันทึกผลการตรวจวัดและประเมินผลรายจุด (Measurement Points & Evaluation)'),

            // 5.1 Lighting Table
            if (lightPoints.isNotEmpty) ...[
              pw.SizedBox(height: 4),
              pw.Text(
                '๔.๑ ผลการตรวจวัดความเข้มของแสงสว่าง (Lighting Measurement - Lux) [ประกาศกรมฯ ๒๕๖๑]',
                style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
              ),
              pw.SizedBox(height: 3),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.blue100),
                    children: [
                      _buildTableCell('ลำดับ', isHeader: true, flex: 1),
                      _buildTableCell('รหัสจุด (Point ID)', isHeader: true, flex: 3),
                      _buildTableCell('แผนก / บริเวณ (Department & Location)', isHeader: true, flex: 6, alignLeft: true),
                      _buildTableCell('ลักษณะงาน / หมวดหมู่ตามกฎหมาย', isHeader: true, flex: 6, alignLeft: true),
                      _buildTableCell('ค่าที่วัดได้\n(Lux)', isHeader: true, flex: 3),
                      _buildTableCell('เกณฑ์ต่ำสุด\n(Min Lux)', isHeader: true, flex: 3),
                      _buildTableCell('บริเวณรอบ\n(Lux)', isHeader: true, flex: 3),
                      _buildTableCell('ผลการประเมินตามกฎหมาย', isHeader: true, flex: 4),
                    ],
                  ),
                  ...lightPoints.asMap().entries.map((entry) {
                    final idx = entry.key + 1;
                    final pt = entry.value;
                    final isPass = pt.isPass;
                    final statusText = isPass ? 'ผ่านเกณฑ์มาตรฐาน' : 'ต่ำกว่าเกณฑ์ (ไม่ผ่าน)';
                    final statusColor = isPass ? PdfColors.green900 : PdfColors.red900;
                    final statusBg = isPass ? PdfColors.green50 : PdfColors.red50;

                    return pw.TableRow(
                      decoration: pw.BoxDecoration(
                        color: idx.isEven ? PdfColors.grey50 : PdfColors.white,
                      ),
                      children: [
                        _buildTableCell('$idx', flex: 1),
                        _buildTableCell(pt.pointId, flex: 3, isBold: true),
                        _buildTableCell('${pt.department} - ${pt.locationName}', flex: 6, alignLeft: true),
                        _buildTableCell(pt.lightTaskDescription ?? pt.taskOrMachineName ?? '-', flex: 6, alignLeft: true),
                        _buildTableCell('${pt.lightMeasuredLux?.toStringAsFixed(1) ?? "-"}', flex: 3, isBold: true),
                        _buildTableCell('${pt.lightStandardMinLux?.toStringAsFixed(0) ?? "-"}', flex: 3),
                        _buildTableCell('${pt.lightSurroundingLux?.toStringAsFixed(1) ?? "-"}', flex: 3),
                        pw.Container(
                          padding: const pw.EdgeInsets.all(3.5),
                          color: statusBg,
                          alignment: pw.Alignment.center,
                          child: pw.Text(
                            statusText,
                            textAlign: pw.TextAlign.center,
                            style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: statusColor),
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
              pw.SizedBox(height: 8),
            ],

            // 5.2 Noise Table
            if (noisePoints.isNotEmpty) ...[
              pw.SizedBox(height: 4),
              pw.Text(
                '๔.๒ ผลการตรวจวัดระดับเสียง (Noise Measurement - dBA/dB) [กฎกระทรวงฯ ๒๕๕๙ & ประกาศกรมฯ ๒๕๖๑]',
                style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
              ),
              pw.SizedBox(height: 3),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.blue100),
                    children: [
                      _buildTableCell('ลำดับ', isHeader: true, flex: 1),
                      _buildTableCell('รหัสจุด (Point ID)', isHeader: true, flex: 3),
                      _buildTableCell('แผนก / แหล่งกำเนิดเสียง / เครื่องจักร', isHeader: true, flex: 6, alignLeft: true),
                      _buildTableCell('ประเภทการวัด', isHeader: true, flex: 4),
                      _buildTableCell('ค่าที่วัดได้\n(dBA/Peak dB)', isHeader: true, flex: 3),
                      _buildTableCell('เกณฑ์มาตรฐาน\n(8-hr / Peak)', isHeader: true, flex: 3),
                      _buildTableCell('เฝ้าระวัง Action Level\n(>= 85 dBA)', isHeader: true, flex: 4),
                      _buildTableCell('ผลการประเมินตามกฎหมาย', isHeader: true, flex: 4),
                    ],
                  ),
                  ...noisePoints.asMap().entries.map((entry) {
                    final idx = entry.key + 1;
                    final pt = entry.value;

                    String statusText = 'ปกติ (<= 85 dBA)';
                    PdfColor statusColor = PdfColors.green900;
                    PdfColor statusBg = PdfColors.green50;

                    if (pt.isFail) {
                      statusText = 'เกินเกณฑ์มาตรฐาน (> 86 dBA)';
                      statusColor = PdfColors.red900;
                      statusBg = PdfColors.red50;
                    } else if (pt.isActionLevel) {
                      statusText = 'เฝ้าระวัง Action Level (85-86 dBA)';
                      statusColor = PdfColors.amber900;
                      statusBg = PdfColors.amber50;
                    }

                    final hcpText = pt.requiresHearingConservation ? 'เข้าโครงการ HCP' : 'ไม่อยู่ในเกณฑ์';
                    final hcpColor = pt.requiresHearingConservation ? PdfColors.purple900 : PdfColors.grey700;

                    final measVal = pt.noiseMeasurementType == NoiseMeasurementType.peakSoundLevel
                        ? '${pt.noisePeakDb?.toStringAsFixed(1) ?? "-"} dB'
                        : '${pt.noiseMeasuredDba?.toStringAsFixed(1) ?? "-"} dBA';
                    final stdLimit = pt.noiseMeasurementType == NoiseMeasurementType.peakSoundLevel
                        ? '<= ${pt.noisePeakLimit.toStringAsFixed(0)} dB'
                        : '<= ${pt.noiseStandardTwaLimit.toStringAsFixed(0)} dBA';

                    return pw.TableRow(
                      decoration: pw.BoxDecoration(
                        color: idx.isEven ? PdfColors.grey50 : PdfColors.white,
                      ),
                      children: [
                        _buildTableCell('$idx', flex: 1),
                        _buildTableCell(pt.pointId, flex: 3, isBold: true),
                        _buildTableCell('${pt.department} - ${pt.locationName} (${pt.taskOrMachineName ?? "-"})', flex: 6, alignLeft: true),
                        _buildTableCell(pt.noiseMeasurementType?.labelTh ?? 'Leq 8-hr TWA', flex: 4),
                        _buildTableCell(measVal, flex: 3, isBold: true),
                        _buildTableCell(stdLimit, flex: 3),
                        _buildTableCell(hcpText, flex: 4, color: hcpColor, isBold: pt.requiresHearingConservation),
                        pw.Container(
                          padding: const pw.EdgeInsets.all(3.5),
                          color: statusBg,
                          alignment: pw.Alignment.center,
                          child: pw.Text(
                            statusText,
                            textAlign: pw.TextAlign.center,
                            style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: statusColor),
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
              pw.SizedBox(height: 8),
            ],

            // 5.3 Heat Table
            if (heatPoints.isNotEmpty) ...[
              pw.SizedBox(height: 4),
              pw.Text(
                '๔.๓ ผลการตรวจวัดและประเมินระดับความร้อน (Heat Stress - WBGT) [กฎกระทรวงฯ ๒๕๕๙ & ประกาศกรมฯ ๒๕๖๓]',
                style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
              ),
              pw.SizedBox(height: 3),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.blue100),
                    children: [
                      _buildTableCell('ลำดับ', isHeader: true, flex: 1),
                      _buildTableCell('รหัสจุด (Point ID)', isHeader: true, flex: 3),
                      _buildTableCell('แผนก / พื้นที่ปฏิบัติงาน', isHeader: true, flex: 5, alignLeft: true),
                      _buildTableCell('สภาพแดด', isHeader: true, flex: 3),
                      _buildTableCell('NWB\n(°C)', isHeader: true, flex: 2),
                      _buildTableCell('GT\n(°C)', isHeader: true, flex: 2),
                      _buildTableCell('DB\n(°C)', isHeader: true, flex: 2),
                      _buildTableCell('WBGT ที่คำนวณ\n(°C)', isHeader: true, flex: 3),
                      _buildTableCell('ลักษณะภาระงาน\n(Workload)', isHeader: true, flex: 3),
                      _buildTableCell('เกณฑ์มาตรฐาน\n(WBGT Limit)', isHeader: true, flex: 3),
                      _buildTableCell('ผลการประเมินตามกฎหมาย', isHeader: true, flex: 4),
                    ],
                  ),
                  ...heatPoints.asMap().entries.map((entry) {
                    final idx = entry.key + 1;
                    final pt = entry.value;
                    final isPass = pt.isPass;
                    final statusText = isPass ? 'ผ่านเกณฑ์มาตรฐาน' : 'เกินเกณฑ์ (ไม่ผ่าน)';
                    final statusColor = isPass ? PdfColors.green900 : PdfColors.red900;
                    final statusBg = isPass ? PdfColors.green50 : PdfColors.red50;

                    final solarText = pt.heatSolarExposure == HeatSolarExposure.outdoorWithSolar ? 'กลางแจ้ง' : 'ในร่ม';

                    return pw.TableRow(
                      decoration: pw.BoxDecoration(
                        color: idx.isEven ? PdfColors.grey50 : PdfColors.white,
                      ),
                      children: [
                        _buildTableCell('$idx', flex: 1),
                        _buildTableCell(pt.pointId, flex: 3, isBold: true),
                        _buildTableCell('${pt.department} - ${pt.locationName}', flex: 5, alignLeft: true),
                        _buildTableCell(solarText, flex: 3),
                        _buildTableCell('${pt.heatNwbCelsius?.toStringAsFixed(1) ?? "-"}', flex: 2),
                        _buildTableCell('${pt.heatGtCelsius?.toStringAsFixed(1) ?? "-"}', flex: 2),
                        _buildTableCell('${pt.heatDbCelsius?.toStringAsFixed(1) ?? "-"}', flex: 2),
                        _buildTableCell('${pt.heatCalculatedWbgt?.toStringAsFixed(2) ?? "-"}', flex: 3, isBold: true),
                        _buildTableCell(pt.heatWorkloadType?.labelTh ?? '-', flex: 3),
                        _buildTableCell('<= ${pt.heatStandardLimitWbgt?.toStringAsFixed(0) ?? "-"} °C', flex: 3),
                        pw.Container(
                          padding: const pw.EdgeInsets.all(3.5),
                          color: statusBg,
                          alignment: pw.Alignment.center,
                          child: pw.Text(
                            statusText,
                            textAlign: pw.TextAlign.center,
                            style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: statusColor),
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
              pw.SizedBox(height: 8),
            ],
            pw.SizedBox(height: 10),

            // ----------------------------------------------------------------
            // 6. Section 5: CAPA Action Plan Table
            // ----------------------------------------------------------------
            _buildSectionHeader('ส่วนที่ ๕: แผนการปรับปรุงแก้ไขสภาวะแวดล้อมในการทำงาน (CAPA Action Plan)'),
            if (capas.isEmpty)
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: PdfColors.green50,
                  borderRadius: pw.BorderRadius.circular(4),
                  border: pw.Border.all(color: PdfColors.green300),
                ),
                child: pw.Center(
                  child: pw.Text(
                    '✓ ผลการตรวจวัดสภาพแวดล้อมสอดคล้องตามเกณฑ์มาตรฐานทุกจุด ไม่มีรายการที่ต้องเปิดแผนปรับปรุงแก้ไข (CAPA) ในรอบนี้',
                    style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.green900),
                  ),
                ),
              )
            else
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.blue100),
                    children: [
                      _buildTableCell('ลำดับ', isHeader: true, flex: 1),
                      _buildTableCell('รหัส CAPA / จุดตรวจวัด', isHeader: true, flex: 3),
                      _buildTableCell('ปัจจัย / สภาพปัญหาความไม่สอดคล้อง', isHeader: true, flex: 5, alignLeft: true),
                      _buildTableCell('สาเหตุรากเหง้า (Root Cause)', isHeader: true, flex: 5, alignLeft: true),
                      _buildTableCell('มาตรการแก้ไข (Engineering / Admin / PPE Controls)', isHeader: true, flex: 7, alignLeft: true),
                      _buildTableCell('ผู้รับผิดชอบ\n(PIC)', isHeader: true, flex: 3),
                      _buildTableCell('กำหนดเสร็จ\n(Target Date)', isHeader: true, flex: 3),
                      _buildTableCell('สถานะแผนงาน', isHeader: true, flex: 3),
                    ],
                  ),
                  ...capas.asMap().entries.map((entry) {
                    final idx = entry.key + 1;
                    final c = entry.value;

                    final statusLabel = c.statusLabelTh;
                    final statusColor = c.isCompleted
                        ? PdfColors.green800
                        : c.isOverdue
                            ? PdfColors.red800
                            : c.status.toUpperCase() == 'IN_PROGRESS'
                                ? PdfColors.blue800
                                : PdfColors.grey800;

                    final controlsText = [
                      if (c.engineeringControl != null && c.engineeringControl!.isNotEmpty) 'วิศวกรรม: ${c.engineeringControl}',
                      if (c.administrativeControl != null && c.administrativeControl!.isNotEmpty) 'บริหารจัดการ: ${c.administrativeControl}',
                      if (c.ppeControl != null && c.ppeControl!.isNotEmpty) 'PPE: ${c.ppeControl}',
                    ].join('\n');

                    return pw.TableRow(
                      decoration: pw.BoxDecoration(
                        color: idx.isEven ? PdfColors.grey50 : PdfColors.white,
                      ),
                      children: [
                        _buildTableCell('$idx', flex: 1),
                        _buildTableCell('${c.capaId}\n(${c.pointId ?? "-"})', flex: 3, isBold: true),
                        _buildTableCell('${c.factorType.labelTh}\n${c.hazardDescription}', flex: 5, alignLeft: true),
                        _buildTableCell(c.rootCause, flex: 5, alignLeft: true),
                        _buildTableCell(controlsText.isNotEmpty ? controlsText : c.actionTitle, flex: 7, alignLeft: true),
                        _buildTableCell('${c.picName}${c.picDepartment != null ? "\n(${c.picDepartment})" : ""}', flex: 3),
                        _buildTableCell(c.targetDate, flex: 3),
                        _buildTableCell(statusLabel, flex: 3, color: statusColor, isBold: true),
                      ],
                    );
                  }),
                ],
              ),
            pw.SizedBox(height: 14),

            // ----------------------------------------------------------------
            // 7. Section 6: 3-Tier Statutory Signature & DLPW Notice Block
            // ----------------------------------------------------------------
            _buildSectionHeader('ส่วนที่ ๖: การรับรองผลการตรวจวัดและการลงนาม ๓ ระดับ (Statutory Endorsement & Approval)'),
            pw.SizedBox(height: 6),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                // 1. Surveyor Signature
                pw.Container(
                  width: 235,
                  padding: const pw.EdgeInsets.all(6),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey50,
                    borderRadius: pw.BorderRadius.circular(4),
                    border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text('ผู้ทำการตรวจวัดสภาพแวดล้อม', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                      pw.SizedBox(height: 18),
                      pw.Text('ลงชื่อ ............................................................', style: const pw.TextStyle(fontSize: 8)),
                      pw.SizedBox(height: 3),
                      pw.Text('( $surveyor )', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                      pw.Text('ผู้ตรวจวัด / เจ้าหน้าที่เทคนิคสิ่งแวดล้อม', style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700)),
                      pw.Text('วันที่: ....... / ....... / .......', style: const pw.TextStyle(fontSize: 7.5)),
                    ],
                  ),
                ),

                // 2. Subcontractor Certifier Signature (ม.๙ / ม.๑๑)
                pw.Container(
                  width: 235,
                  padding: const pw.EdgeInsets.all(6),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey50,
                    borderRadius: pw.BorderRadius.circular(4),
                    border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text('ผู้รับรองรายงาน (ม.๙ นบ. / ม.๑๑ บ.)', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                      pw.SizedBox(height: 18),
                      pw.Text('ลงชื่อ ............................................................', style: const pw.TextStyle(fontSize: 8)),
                      pw.SizedBox(height: 3),
                      pw.Text('( $certifier )', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                      pw.Text('เลขทะเบียน/ใบอนุญาต: $certifierReg', style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700)),
                      pw.Text('วันที่: ....... / ....... / .......', style: const pw.TextStyle(fontSize: 7.5)),
                    ],
                  ),
                ),

                // 3. Employer / Safety Officer Signature
                pw.Container(
                  width: 235,
                  padding: const pw.EdgeInsets.all(6),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey50,
                    borderRadius: pw.BorderRadius.circular(4),
                    border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text('นายจ้าง / ผู้แทนนายจ้าง / จป.วิชาชีพ', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                      pw.SizedBox(height: 18),
                      pw.Text('ลงชื่อ ............................................................', style: const pw.TextStyle(fontSize: 8)),
                      pw.SizedBox(height: 3),
                      pw.Text('( $employerSigner )', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                      pw.Text(employerRole, style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700), textAlign: pw.TextAlign.center),
                      pw.Text('วันที่: ....... / ....... / .......', style: const pw.TextStyle(fontSize: 7.5)),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 10),

            // Statutory 30-day DLPW Notice Box
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(6),
              decoration: pw.BoxDecoration(
                color: PdfColors.amber50,
                borderRadius: pw.BorderRadius.circular(4),
                border: pw.Border.all(color: PdfColors.amber300, width: 0.5),
              ),
              child: pw.Text(
                'หมายเหตุทางกฎหมาย (Statutory Notice): ตามมาตรา ๑๕ แห่ง พ.ร.บ. ความปลอดภัย อาชีวอนามัย และสภาพแวดล้อมในการทำงาน พ.ศ. ๒๕๕๔ และข้อ ๑๕ แห่งกฎกระทรวงความร้อน แสงสว่าง และเสียง พ.ศ. ๒๕๕๙ นายจ้างต้องนำผลการตรวจวัดและวิเคราะห์สภาวะการทำงานปิดประกาศไว้ ณ สถานประกอบการภายใน ๑๕ วัน (ภายในวันที่ $postingDl) และจัดส่งสำเนารายงานนี้ต่ออธิบดีกรมสวัสดิการและคุ้มครองแรงงานภายใน ๓๐ วันนับแต่วันตรวจวัดเสร็จสิ้น (ภายในวันที่ $submissionDl) พร้อมเก็บรักษาเอกสารไว้ไม่น้อยกว่า ๕ ปี',
                style: pw.TextStyle(fontSize: 6.8, color: PdfColors.brown900),
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
    String? companyAddress,
    String? employerOrSafetyOfficerName,
    String? employerOrSafetyOfficerRole,
  }) async {
    final bytes = await generatePdf(
      session: session,
      points: points,
      capas: capas,
      kpi: kpi,
      companyAddress: companyAddress,
      employerOrSafetyOfficerName: employerOrSafetyOfficerName,
      employerOrSafetyOfficerRole: employerOrSafetyOfficerRole,
    );

    final filename = 'SAFAPP_Environmental_Report_${session.sessionId}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => bytes,
      name: filename,
    );
  }

  /// Shares the PDF via standard platform share dialog.
  static Future<void> sharePdf({
    required EnvironmentSessionModel session,
    required List<EnvironmentPointModel> points,
    required List<EnvironmentCapaModel> capas,
    required EnvironmentKpiSummary kpi,
    String? companyAddress,
  }) async {
    final bytes = await generatePdf(
      session: session,
      points: points,
      capas: capas,
      kpi: kpi,
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
    String? companyAddress,
  }) async {
    final bytes = await generatePdf(
      session: session,
      points: points,
      capas: capas,
      kpi: kpi,
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
      margin: const pw.EdgeInsets.only(top: 4, bottom: 4),
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue900,
        borderRadius: pw.BorderRadius.circular(3),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 8.5,
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
    int flex = 1,
    PdfColor? color,
  }) {
    return pw.Expanded(
      flex: flex,
      child: pw.Container(
        padding: const pw.EdgeInsets.all(3.5),
        alignment: alignLeft ? pw.Alignment.centerLeft : pw.Alignment.center,
        child: pw.Text(
          text,
          textAlign: alignLeft ? pw.TextAlign.left : pw.TextAlign.center,
          style: pw.TextStyle(
            fontSize: isHeader ? 7.5 : 7,
            fontWeight: isHeader || isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: color ?? (isHeader ? PdfColors.blue900 : PdfColors.black),
          ),
        ),
      ),
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
          pw.Text(title, style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: textColor)),
          pw.Text(percent, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: textColor)),
          pw.Text(count, style: const pw.TextStyle(fontSize: 6.5, color: PdfColors.grey700)),
        ],
      ),
    );
  }
}
